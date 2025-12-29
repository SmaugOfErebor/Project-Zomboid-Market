local cmdPrefix = "[PZ Market] "
print(cmdPrefix .. "Loading the Project Zomboid Market!")

--[[
Returns the currency balance for the specified player.
Ensures that the player has currency data.
]]
function GetBalance(player)
    local data = player:getModData()
    if not data.currency then
        data.currency = 0
    end
    return data.currency
end

--[[
Modifies the given player's currency balance by the specified amount.
]]
function ModifyBalance(player, amount)
    local data = player:getModData()
    if not data.currency then
        data.currency = 0
    end
    data.currency = data.currency + amount
end

--[[
Attempts to sell the specified item from the specified player's inventory.
Will fail if the item does not have a price defined in the dictionary in prices.lua.
]]
function SellItem(player, items)
    local totalPrice = 0

    -- Find all sellable items
    for i = 1, #items do
        local item = items[i]
        local itemType = item:getFullType()

        -- If there is a price definition for this item, it is a valid item to sell.
        local price = ItemPrices[itemType] or 0
        if price > 0 then
            totalPrice = totalPrice + price
            -- Remove the item from the backpack and imburse the player accordingly.
            item:getContainer():Remove(item)
            ModifyBalance(player, price)
        end
    end

    if totalPrice > 0 then
        print(cmdPrefix .. "Sold items for a total price of " .. totalPrice .. ".")
    end
end

--[[
Attempts to purchase the specified item for the specified player.
Will fail if the item does not have a price defined in the dictionary in prices.lua.
]]
function BuyItem(player, item)
    local itemType = item:getFullType()

    -- Ensure that there is a price definition for this item.
    local price = ItemPrices[itemType] or 0
    if price <= 0 then
        print(cmdPrefix .. itemType .. " cannot be purchased.")
        return
    end

    -- Ensure that the player actually has the required balance to make the purchase.
    local balance = GetBalance(player)
    if balance < price then
        print(cmdPrefix .. "You don't have enough money to purchase " .. itemType .. ". Price: " .. price)
        return
    end

    -- Add the item to the backpack and charge the player accordingly.
    local purchasedItem = player:getInventory():AddItem(itemType)
    item:getContainer():AddItem(purchasedItem)
    ModifyBalance(player, -price)

    print(cmdPrefix .. "Purchased " .. itemType .. " for " .. price)
end

--[[
Scans a player's backpack for how many rags, dirty rags, and all other item types.
Used to determine what action the player wants to perform with thge market system.
]]
function ScanBackpack(backpack)
    local inv = backpack:getInventory()
    local items = inv:getItems()

    local ragCount = 0
    local dirtyRagCount = 0
    local remainingItems = {}

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fullType = item:getFullType()

        if fullType == "Base.RippedSheets" then
            ragCount = ragCount + 1
        elseif fullType == "Base.RippedSheetsDirty" then
            dirtyRagCount = dirtyRagCount + 1
        else
            table.insert(remainingItems, item)
        end
    end

    return ragCount, dirtyRagCount, remainingItems
end

--[[
Register this function to run every time ten in-game minutes elapse.
]]
Events.EveryTenMinutes.Add(function()
    local players = getOnlinePlayers()
    if not players then
        return
    end

    -- Iterate over every online player
    for i = 0, players:size() - 1 do
        local player = players:get(i)

        local backpack = player:getClothingItem_Back()
        if backpack then
            local ragCount, dirtyRagCount, otherItems = ScanBackpack(backpack)

            if ragCount == 5 and dirtyRagCount == 5 and #otherItems == 0 then
                -- The player wants to query their balance
                local balance = GetBalance(player)
                print(cmdPrefix .. player:getDisplayName() .. " Balance: " .. balance)

            elseif ragCount == 6 and dirtyRagCount == 5 and #otherItems >= 1 then
                -- The player wants to sell an item
                SellItem(player, otherItems)

            elseif ragCount == 5 and dirtyRagCount == 6 and #otherItems == 1 then
                -- The player wants to buy an item (remember that lua arrays start at 1. vomit.emoji)
                BuyItem(player, otherItems[1])
            end
        end
    end
end)
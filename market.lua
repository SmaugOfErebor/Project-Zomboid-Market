local cmdPrefix = "[PZ Market] "
print(cmdPrefix .. "Loading the Project Zomboid Market!")

-- Returns the currency balance for the specified player.
-- Ensures that the player has currency data.
function GetBalance(player)
    local data = player:getModData()
    if not data.currency then
        data.currency = 0
    end
    return data.currency
end

-- Modifies the given player's currency balance by the specified amount.
function ModifyBalance(player, amount)
    local data = player:getModData()
    if not data.currency then
        data.currency = 0
    end
    data.currency = data.currency + amount
end

-- Attempts to sell the specified item from the specified player's inventory.
function SellItem(player, item)
    local itemType = item:getFullType()

    -- Ensure that there is a price definition for this item.
    local price = ItemPrices[itemType] or 0
    if price <= 0 then
        print(cmdPrefix .. itemType .. " cannot be sold.")
        return
    end

    -- Remove the item from the player's inventory and imburse the player accordingly.
    local backpack = item:getContainer()
    backpack:Remove(item)

    ModifyBalance(player, price)
    print(cmdPrefix .. "Sold " .. itemType .. " for " .. price .. ".")
end

-- Attempts to purchase the specified item for the specified player.
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

    -- Add the item to the player's backpack.
    local backpack = item:getContainer()
    local purchasedItem = player:getInventory():AddItem(itemType)
    backpack:AddItem(purchasedItem)

    -- Take the corresponding amount of currency from the player's balance.
    ModifyBalance(player, -price)
    print(cmdPrefix .. "Purchased " .. itemType .. " for " .. price)
end

-- Scans a player's backpack for how many rags, dirty rags, and all other item types.
function scanBackpack(backpack)
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
            local ragCount, dirtyRagCount, otherItems = scanBackpack(backpack)

            if ragCount == 5 and dirtyRagCount == 5 and #otherItems == 0 then
                -- The player wants to query their balance
                local balance = GetBalance(player)
                print(cmdPrefix .. player:getDisplayName() .. " Balance: " .. balance)

            elseif ragCount == 6 and dirtyRagCount == 5 and #otherItems == 1 then
                -- The player wants to sell an item (remember that lua arrays start at 1. vomit.emoji)
                SellItem(player, otherItems[1])
            
            elseif ragCount == 5 and dirtyRagCount == 6 and #otherItems == 1 then
                -- The player wants to buy an item (remember that lua arrays start at 1. vomit.emoji)
                BuyItem(player, otherItems[1])
            end
        end
    end
end)
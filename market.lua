print("[PZ Market] Loading the Project Zomboid Market!")

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
    -- Ensure that there is a price definition for this item.
    local price = ItemPrices[item:getType()] or 0
    if price <= 0 then
        player:sendChatMessage(item:getType() .. " cannot be sold.")
        return
    end

    -- Remove the item from the player's inventory and imburse the player accordingly.
    item:getContainer():Remove(item)
    ModifyBalance(player, price)
    player:sendChatMessage("Sold " .. item:getType() .. " for " .. price)
end

-- Attempts to purchase the specified item for the specified player.
function BuyItem(player, item)
    -- Ensure that there is a price definition for this item.
    local price = ItemPrices[item:getType()] or 0
    if price <= 0 then
        player:sendChatMessage(item:getType() .. " cannot be purchased.")
        return
    end

    -- Ensure that the player actually has the required balance to make the purchase.
    local balance = GetBalance(player)
    if balance < price then
        player:sendChatMessage("You don't have enough money to purchase " .. item:getType() .. ". Price: " .. price)
        return
    end

    -- Attempt to add the item to the player's inventory.
    local inventory = player:getInventory()
    local purchasedItem = inventory:AddItem(item:getType())
    if not purchasedItem then
        player:sendChatMessage("Failed to add " .. item:getType() .. " to your inventory. You will not be charged.")
        return
    end

    -- Take the corresponding amount of currency from the player's balance.
    ModifyBalance(player, -price)
    player:sendChatMessage("Purchased " .. item:getType() .. " for " .. price)
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

    print("[PZ Market] Scanning player inventories.")

    -- Iterate over every online player
    for i = 0, players:size() - 1 do
        local player = players:get(i)

        print("[PZ Market] Scanning " .. player:getDisplayName() .. "'s inventory.")

        local backpack = player:getClothingItem_Back()
        if backpack then
            print("[PZ Market] Player " .. player:getDisplayName() .. " is wearing a backpack.")
            local ragCount, dirtyRagCount, otherItems = scanBackpack(backpack)
            print("[PZ Market] Rag Count: " .. ragCount)
            print("[PZ Market] Dirty Rag Count: " .. dirtyRagCount)
            print("[PZ Market] Other Items Count: " .. #otherItems)

            if ragCount == 5 and dirtyRagCount == 5 and #otherItems == 0 then
                -- The player wants to query their balance
                print("[PZ Market] Player " .. player:getDisplayName() .. " wants to check their balance.")
                local balance = GetBalance(player)
                print("[PZ Market] " .. player:getDisplayName() .. " Balance: " .. balance)

            elseif ragCount == 6 and dirtyRagCount == 5 and #otherItems == 1 then
                -- The player wants to sell an item
                SellItem(player, otherItems:get(0))
            
            elseif ragCount == 5 and dirtyRagCount == 6 and #otherItems == 1 then
                -- The player wants to buy an item
                BuyItem(player, otherItems:get(0))
            end
        end
    end
end)
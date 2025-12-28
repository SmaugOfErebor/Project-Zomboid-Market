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

Events.EveryTenMinutes.Add(function()
    local players = getOnlinePlayers()
    if not players then
        return 
    end

    print("[PZ Market] Scanning player inventories.")

    -- Iterate over every online player
    for i = 0, players:size() - 1 do
        local player = players:get(i)

        local backpack = player:getClothingItem_Back()
        if backpack then
            local inv = backpack:getInventory()
            local items = inv:getItems()

            if items:size() == 2 then
                -- Check if the player wants to query their balance
                local totalRag = 0
                local totalRagDirty = 0
                for j = 0, 1 do
                    local item = items:get(j)
                    if item:getName():lower() == "rag" then
                        totalRag = item:getCount()
                    elseif item:getName():lower() == "rag (dirty)" then
                        totalRagDirty = item:getCount()
                    end
                end

                -- The player wants to query their balance
                if totalRag == 20 and totalRagDirty == 20 then
                    local balance = GetBalance(player)
                    print("[PZ Market] " .. player:getDisplayName() .. " Balance: " .. balance)
                    player:sendChatMessage("Balance: " .. tostring(balance)) 
                end

            elseif items:size() == 3 then
                -- Check if the player wants to sell or purchase an item
                local totalRag = 0
                local totalRagDirty = 0
                local thirdItem
                for j = 0, 2 do
                    local item = items:get(j)
                    if item:getName():lower() == "rag" then
                        totalRag = item:getCount()
                    elseif item:getName():lower() == "rag (dirty)" then
                        totalRagDirty = item:getCount()
                    else
                        thirdItem = item
                    end
                end

                if totalRag == 20 and totalRagDirty == 21 then
                    -- The player wants to sell an item
                    SellItem(player, thirdItem)

                elseif totalRag == 21 and totalRagDirty == 20 then
                    -- The player wants to buy an item
                    BuyItem(player, thirdItem)
                end
            end
        end
    end
end)
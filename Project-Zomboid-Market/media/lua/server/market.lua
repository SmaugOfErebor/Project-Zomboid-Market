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
    local data = GetBalance(player)
    data.currency = data.currency + amount
end

-- Attempts to sell the specified item from the specified player's inventory.
function SellItem(player, itemType)
    local inventory = player:getInventory()

    -- Ensure that the player has this item to sell.
    local item = inventory:FindAndReturn(itemType)
    if not item then
        player:sendChatMessage("You don't have that item.")
        return
    end

    -- Ensure that there is a price definition for this item.
    local price = ItemPrices[itemType] or 0
    if price <= 0 then
        player.sendChatMessage("That item cannot be sold.")
        return
    end

    -- Remove the item from the player's inventory and imburse the player accordingly.
    inventory:Remove(item)
    AddBalance(player, price)
    player:sendChatMessage("Sold " .. itemType .. " for " .. price)
end

-- Attempts to purchase the specified item for the specified player.
function BuyItem(player, itemType)
    -- Ensure that there is a price definition for this item.
    local price = ItemPrices[itemType] or 0
    if price <= 0 then
        player.sendChatMessage("That item cannot be purchased.")
        return
    end

    -- Ensure that the player actually has the required balance to make the purchase.
    local balance = GetBalance(player)
    if balance < price then
        player.sendChatMessage("You don't have enough money to purchase that item. Price: " .. price)
        return
    end

    -- Attempt to add the item to the player's inventory.
    local inventory = player:getInventory()
    local purchasedItem = inventory:AddItem(itemType)
    if not purchasedItem then
        player.sendChatMessage("Failed to add item to your inventory. You will not be charged.")
        return
    end

    -- Take the corresponding amount of currency from the player's balance.
    ModifyBalance(player, -price)
    player.sendChatMessage("Purchased " .. itemType " for " .. price)
end

Events.OnPlayerChat.Add(function(player, message)
    local args = {}

    for word in message:gmatch("%S+") do
        table.insert(args, word)
    end

    local cmd = args[1]

    -- The player wants to query their balance.
    if cmd == "/balance" then
        local balance = GetBalance(player)
        player:sendChatMessage("Balance: " .. balance)
        return false
    end

    -- The player wants to buy an item.
    if cmd == "/buy" and args[2] then
        if not args[2] then
            player:sendChatMessage("You must specify the item type to purchase.")
            return false
        end
        BuyItem(player, args[2])
        return false
    end

    -- The player wants to sell an item.
    if cmd == "/sell"then
        if not args[2] then
            player:sendChatMessage("You must specify the item type to sell.")
            return false
        end
        SellItem(player, args[2])
        return false
    end
end)
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
Trie to perform a sale operation for the given player.
To sell items, the player must have an item with an inventory that contains an item with an inventory equipped to the primary hand slot.
Example: Equip a duffel bag containing a backpack containing junk items to sell to the primary hand slot.
]]
function TrySell(player)
    -- Ensure that the player has an item equipped in the primary slot.
    local handItem = player:getPrimaryHandItem()
    if not handItem then
        return
    end

    -- Ensure that the equipped item has an inventory.
    if not handItem.getInventory then
        return
    end
    local inv = handItem:getInventory()
    if not inv then
        return
    end

    -- Only sell items from inside an inner inventory.
    local totalPrice = 0
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.getInventory then
            totalPrice = totalPrice + SellItems(player, item:getInventory():getItems())
        end
    end

    if totalPrice > 0 then
        print(cmdPrefix .. player:getDisplayName() .. " Sold items for a total of: " .. totalPrice .. " New balance: " .. GetBalance(player))
    end
end

--[[
Attempts to sell the given array of items.
Items without a price defined in the dictionary in prices.lua will not be sold.
]]
function SellItems(player, items)
    local totalPrice = 0

    -- Iterate backwards because the loop attempts to modify the collection.
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)

        if item then
            if item.getInventory then
                -- This item has an inventory, try to sell inner items first.
                totalPrice = totalPrice + SellItems(player, item:getInventory():getItems())
                -- If all inner items sold, try to sell the container item too.
                if item:getInventory():getItems():size() == 0 then
                    totalPrice = totalPrice + SellItem(player, item)
                end

            else
                -- If this item does not have an inventory, just try to sell it.
                totalPrice = totalPrice + SellItem(player, item)
            end
        end
    end

    return totalPrice
end

--[[
Attempts to sell the given item.
Items without a price defined in the dictionary in prices.lua will not be sold.
]]
function SellItem(player, item)
    if not CanSell(item) then
        return 0
    end

    -- If there is no price definition for this item, it cannot be sold.
    local price = ItemPrices[item:getFullType()] or 0
    if price <= 0 then
        return 0
    end

    -- Remove the item from the backpack and imburse the player accordingly.
    item:getContainer():Remove(item)
    ModifyBalance(player, price)

    return price
end

--[[
Returns whether this item is sellable.
This method will eventually be removed entirely once drainable items and items with condition can be sold.
]]
function CanSell(item)
    -- Skip drainable items.
    -- TODO: Come up with values for liquids and allow the selling of items containing liquids.
    if item:IsDrainable() then
        return false
    end

    -- Skip items with condition, which are not at full condition.
    -- TODO: Make this function imburse the player with a prorated amount of the item's value based on the remaining durability.
    if item.getCondition and item.getConditionMax and item:getCondition() ~= item:getConditionMax() then
        return false
    end

    return true
end

--[[
Trie to perform a purchase operation for the given player.
To purchase an item, the player must have an item with an inventory containing an item with an inventory containing a single item equipped to the secondary hand slot.
Example: Equip a duffel bag containing a backpack containing the item to purchase to the primary hand slot.
]]
function TryPurchase(player)
    -- Ensure that the player has an item equipped in the secondary slot.
    local handItem = player:getSecondaryHandItem()
    if not handItem then
        return
    end

    -- Ensure that the equipped item has an inventory.
    if not handItem.getInventory then
        return
    end

    local outerInv = handItem:getInventory()
    if not outerInv then
        return
    end

    -- Only purchase items from inside an inner inventory.
    local outerItems = outerInv:getItems()
    for i = 0, outerItems:size() - 1 do
        local outerItem = outerItems:get(i)
        if outerItem.getInventory then
            -- There must be only a single item in the inner inventory to know what is intended to be purchased.
            local innerItems = outerItem:getInventory():getItems()
            if innerItems:size() == 1 then
                Purchase(player, innerItems:get(0))
            end
        end
    end
end

--[[
Attempts to purchase the specified item for the specified player.
Items without a price defined in the dictionary in prices.lua will not be purchased.
]]
function Purchase(player, item)
    -- Ensure that there is a price definition for this item.
    local itemType = item:getFullType()
    local price = ItemPrices[itemType] or 0
    if price <= 0 then
        return
    end

    -- Ensure that the player actually has the required balance to make the purchase.
    local balance = GetBalance(player)
    if balance < price then
        return
    end

    -- Add the item to the backpack and charge the player accordingly.
    local purchasedItem = player:getInventory():AddItem(itemType)
    item:getContainer():AddItem(purchasedItem)
    ModifyBalance(player, -price)

    print(cmdPrefix ..player:getDisplayName() .. " Purchased " .. itemType .. " for:" .. price .. " New balance: " .. GetBalance(player))
end

--[[
Register this function to run every time one in-game minute elapses.
]]
Events.EveryOneMinute.Add(function()
    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        TrySell(player)
        TryPurchase(player)
    end
end)
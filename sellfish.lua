local function addSellFishButton()
    local btn = {
        active = true,
        buttonAction = "sellfish",
        buttonTemplate = "BaseEventButton",
        counter = 0,
        counterMax = 0,
        itemIdIcon = 3000,
        name = "SellFishButton",
        order = 0,
        rcssClass = "clash-event",
        text = "Sell Fish"
    }
    addSidebarButton(json.encode(btn))
end

addSellFishButton()

onPlayerActionCallback(function(world, player, data)
    if data.action == "sellfish" then
        world:sendPlayerMessage(player, "/sellfish")
        return true
    end
    return false
end)

print("(Loaded) Sell Fish button script")

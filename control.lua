
script.on_init(function(event)
global.generator = {}
global.fuel_selection = {}
end)

script.on_configuration_changed(function(event)
    if global.generator == nil then
        global.generator = {}
    end
    if global.fuel_selection == nil then
        global.fuel_selection = {}
    end
end)

-- Add a reference to global.generator when portable-gasolene-generator equipment is inserted

script.on_event(defines.events.on_equipment_inserted, function(event)
    local grid = event.grid
    if not (grid and grid.valid) then
        return
    end
    
    -- Check if the inserted equipment is a "portable-gasolene-generator"
    if event.equipment.type == "generator-equipment" and event.equipment.name == "portable-gasolene-generator" then
      -- Add a reference to global.generator using the equipment's unique_id
      global.generator[event.grid.unique_id] = grid
    end
  end)
  
  -- Check generator fuel every 60 ticks

script.on_nth_tick(60, function(event)
    -- Retrieve the generator entity from global.generator
    local grid = global.generator
    if not next(grid) then return end
    for gen, generators in pairs(grid) do
        local generator = generators.get_contents()
        if generator["portable-gasolene-generator"] ~= nil then
            local equipment = generators.equipment
            for g, gear in pairs(equipment) do
                if gear.name == "portable-gasolene-generator" then
                    if gear.burner.inventory.is_empty() == true then
                        --game.print("we`re all out of fuel capitain")
                        for p, player in pairs(game.players) do
                            if player.valid then
                                --game.print(player.index)
                                if global.fuel_selection[player.index] ~= nil then
                                    local player_inv = player.get_main_inventory()
                                    for f, fuel in pairs(global.fuel_selection[player.index]) do
                                        if player_inv.get_item_count(fuel) > 0 then
                                            --game.print("got fuel")
                                            local count = player_inv.remove({name = fuel, count = 10})
                                            gear.burner.inventory.insert({name = fuel, count = count})
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if gear.burner.burnt_result_inventory.is_full() == true then
                        for p, player in pairs(game.players) do
                            if player.valid then
                                local player_inv = player.get_main_inventory()
                                local count = gear.burner.burnt_result_inventory.remove({name = "empty-fuel-canister", count = 20})
                                log(count)
                                player_inv.insert({name = "empty-fuel-canister", count = count})
                            end
                        end
                    end
                end
            end
        end
    end
end)
  
script.on_event(defines.events.on_gui_opened, function(event)
    if event.gui_type ~= defines.gui_type.item then
        return
    end
    if event.item.type ~= "armor" then
        return
    end
    if game.players[event.player_index].gui.relative.fuel_selection ~= nil then
		game.players[event.player_index].gui.relative.fuel_selection.destroy()
	end
    local fuel_selector = game.players[event.player_index].gui.relative.add(
        {
            type = "frame",
            name = "fuel_selection",
            anchor = {
                gui = defines.relative_gui_type.armor_gui,
                position = defines.relative_gui_position.right
            },
            direction = "vertical",
            caption = "Fuel selection"
        }
    )
    fuel_selector.add(
        {
            type = "label",
            name = "test",
            caption = "select a fuel you bitch"
        }
    )
    local fuels = fuel_selector.add(
        {
            type = "flow",
            name = "fuels",
            direction = "vertical"
        }
    )
    fuels.add(
        {
            type = "choose-elem-button",
            name = "selection_1",
            elem_type = "item",
            elem_filters = 
                {
                    {
                        filter = "fuel-category", 
                        ["fuel-category"] = "jerry"
                    }
            }
        }
    )
    fuel_selector.add(
        {
            type = "switch",
            name = "selection_signal",
            switch_state = "right",
            left_label_caption = "nothing",
            right_label_caption = "anything"
        }
    )
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
    --game.print("button pushed")
    if global.fuel_selection[event.player_index] == nil then
        global.fuel_selection[event.player_index] = {}
    end
    table.insert(global.fuel_selection[event.player_index], event.element.elem_value)
    local num = tonumber(string.match(event.element.name, '%d+'))
    num = num + 1
    for s, string in pairs(event.element.parent.children_names) do
        if string == "selection_" .. num then
            return
        end
    end
        event.element.parent.add(
            {
                type = "choose-elem-button",
                name = "selection_" .. num,
                elem_type = "item",
                elem_filters = 
                    {
                        {
                            filter = "fuel-category", 
                            ["fuel-category"] = "jerry"
                        }
                    }
            }
        )
end)
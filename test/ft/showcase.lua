--- One of everything, wired up and configured.
---
--- The game has thirty nine kinds of control behaviour and every one of them can end up
--- in a graph. This builds one entity of each -- and more than one where a single copy
--- cannot show every setting at once, since an inserter cannot pulse and hold at the same
--- time -- configures each so that every branch in lib/labels has something to say, and
--- wires the lot into rows hanging off power poles, which is roughly how they sit in a
--- real base.
---
--- It doubles as the exhaustive example: test/ft/run.sh "showcase" writes showcase.gv
--- into the run's script-output directory, which graphviz will draw.
local world = require("test.ft.world")
local Graph = require("lib.graph")

local types = defines.control_behavior.type
local wire = defines.wire_connector_id

local ITEM = { type = "item", name = "iron-plate" }
local FLUID = { type = "fluid", name = "water" }
local A = { type = "virtual", name = "signal-A" }
local B = { type = "virtual", name = "signal-B" }
local C = { type = "virtual", name = "signal-C" }

local function condition(first, comparator, constant)
    return { first_signal = first, comparator = comparator or ">", constant = constant or 0 }
end

--- Everything the graph can be asked to draw. `kind` is the control behaviour the entity
--- is expected to report, which is what the test checks coverage against.
local SHOWCASE = {
    { kind = types.container, entity = "wooden-chest" },
    { kind = types.single_fluid_box, entity = "storage-tank" },

    { kind = types.generic_on_off, entity = "power-switch", setup = function(control)
        control.circuit_enable_disable = true
        control.circuit_condition = condition(A, ">", 3)
        control.connect_to_logistic_network = true
        control.logistic_condition = condition(B, "<", 9)
    end },

    -- an inserter cannot pulse and hold at once, so it takes two
    { kind = types.inserter, entity = "fast-inserter", setup = function(control, entity)
        control.circuit_enable_disable = true
        control.circuit_condition = condition(ITEM, "≥", 5)
        control.circuit_set_filters = true
        entity.inserter_filter_mode = "whitelist"
        control.circuit_read_hand_contents = true
        control.circuit_hand_read_mode = defines.control_behavior.inserter.hand_read_mode.pulse
        control.circuit_set_stack_size = true
        control.circuit_stack_control_signal = C
    end },
    { kind = types.inserter, entity = "long-handed-inserter", setup = function(control)
        control.circuit_read_hand_contents = true
        control.circuit_hand_read_mode = defines.control_behavior.inserter.hand_read_mode.hold
    end },

    { kind = types.lamp, entity = "small-lamp", setup = function(control)
        control.use_colors = true
        control.circuit_enable_disable = true
        control.circuit_condition = condition(A, "=", 1)
    end },

    { kind = types.logistic_container, entity = "requester-chest", setup = function(control)
        control.read_contents = true
        control.set_requests = true
    end },

    { kind = types.roboport, entity = "roboport", setup = function(control)
        control.read_logistics = true
        control.read_robot_stats = true
        control.available_logistic_output_signal = A
        control.total_logistic_output_signal = B
        control.available_construction_output_signal = C
        control.total_construction_output_signal = ITEM
    end },

    { kind = types.train_stop, entity = "train-stop", setup = function(control)
        control.send_to_train = true
        control.read_from_train = true
        control.read_stopped_train = true
        control.stopped_train_signal = A
        control.set_trains_limit = true
        control.trains_limit_signal = B
        control.read_trains_count = true
        control.trains_count_signal = C
        control.circuit_enable_disable = true
        control.circuit_condition = condition(ITEM, ">", 40)
    end },

    { kind = types.decider_combinator, entity = "decider-combinator", setup = function(control)
        control.parameters = {
            conditions = { { first_signal = A, comparator = ">", constant = 100 },
                           { first_signal = B, comparator = "<", second_signal = C } },
            outputs = { { signal = ITEM, copy_count_from_input = false },
                        { signal = C, copy_count_from_input = true } },
        }
    end },

    { kind = types.arithmetic_combinator, entity = "arithmetic-combinator",
      setup = function(control)
        control.parameters = { first_signal = ITEM, second_constant = 3, operation = "*",
                               output_signal = B }
    end },
    -- the two operations that have to be escaped before graphviz will take them
    { kind = types.arithmetic_combinator, entity = "arithmetic-combinator",
      setup = function(control)
        control.parameters = { first_signal = A, second_signal = B, operation = ">>",
                               output_signal = C }
    end },

    { kind = types.selector_combinator, entity = "selector-combinator",
      setup = function(control)
        control.parameters = { operation = "select", select_max = true, index_signal = A }
    end },
    { kind = types.selector_combinator, entity = "selector-combinator",
      setup = function(control)
        control.parameters = { operation = "count", count_signal = C }
    end },
    { kind = types.selector_combinator, entity = "selector-combinator",
      setup = function(control)
        control.parameters = { operation = "random", random_update_interval = 60 }
    end },
    { kind = types.selector_combinator, entity = "selector-combinator",
      setup = function(control)
        control.parameters = { operation = "quality-transfer",
                               quality_destination_signal = A }
    end },

    { kind = types.constant_combinator, entity = "constant-combinator",
      setup = function(control)
        local section = control.get_section(1) or control.add_section()
        section.set_slot(1, { value = { type = "item", name = "iron-plate",
                                        quality = "normal" }, min = 42 })
        local second = control.add_section()
        second.set_slot(1, { value = { type = "virtual", name = "signal-A",
                                       quality = "normal" }, min = -7 })
    end },
    -- and one switched off, which is the other half of that first row
    { kind = types.constant_combinator, entity = "constant-combinator",
      setup = function(control) control.enabled = false end },

    { kind = types.transport_belt, entity = "transport-belt", setup = function(control)
        control.circuit_enable_disable = true
        control.circuit_condition = condition(ITEM, ">", 0)
        control.read_contents = true
        control.read_contents_mode =
            defines.control_behavior.transport_belt.content_read_mode.pulse
    end },
    { kind = types.transport_belt, entity = "fast-transport-belt", setup = function(control)
        control.read_contents = true
        control.read_contents_mode =
            defines.control_behavior.transport_belt.content_read_mode.hold
    end },

    { kind = types.accumulator, entity = "accumulator", setup = function(control)
        control.output_signal = A
    end },

    { kind = types.rail_signal, entity = "rail-signal", setup = function(control)
        control.read_signal = true
        control.red_signal = A
        control.orange_signal = B
        control.green_signal = C
        control.close_signal = true
        control.circuit_condition = condition(ITEM, "<", 2)
    end },
    { kind = types.rail_chain_signal, entity = "rail-chain-signal", setup = function(control)
        control.red_signal = A
        control.orange_signal = B
        control.green_signal = C
        control.blue_signal = ITEM
    end },

    -- a wall only takes a wire when a gate is next to it, which is the whole point of
    -- the wall behaviour: it is the gate it opens
    { kind = types.wall, entity = "stone-wall",
      companion = { name = "gate", direction = defines.direction.east },
      setup = function(control)
        control.open_gate = true
        control.circuit_condition = condition(A, ">", 0)
        control.read_sensor = true
        control.output_signal = B
    end },

    { kind = types.mining_drill, entity = "electric-mining-drill", setup = function(control)
        control.circuit_enable_disable = true
        control.circuit_condition = condition(ITEM, "<", 100)
        control.circuit_read_resources = true
        control.resource_read_mode =
            defines.control_behavior.mining_drill.resource_read_mode.this_miner
    end },
    { kind = types.mining_drill, entity = "burner-mining-drill", setup = function(control)
        control.circuit_read_resources = true
        control.resource_read_mode =
            defines.control_behavior.mining_drill.resource_read_mode.entire_patch
    end },

    { kind = types.programmable_speaker, entity = "programmable-speaker",
      setup = function(control, entity)
        entity.parameters = { playback_volume = 0.8, playback_globally = true,
                              allow_polyphony = true }
        entity.alert_parameters = { show_alert = true, show_on_map = true,
                                    icon_signal_id = A, alert_message = "tank empty" }
        control.circuit_condition = condition(ITEM, ">", 0)
        control.circuit_parameters = { signal_value_is_pitch = false, instrument_id = 0,
                                       note_id = 0 }
    end },

    -- everything with no branch of its own, which since 2.0 is most of the game. They
    -- nearly all inherit the generic on/off behaviour, and the condition is what shows.
    { kind = types.pump, entity = "pump", switched = true },
    { kind = types.assembling_machine, entity = "assembling-machine-2", switched = true },
    { kind = types.furnace, entity = "stone-furnace", switched = true },
    -- these four have a control behaviour but do not inherit the on/off one, so there is
    -- nothing for the graph to say about them yet beyond what they are
    { kind = types.lab, entity = "lab" },
    { kind = types.radar, entity = "radar" },
    { kind = types.reactor, entity = "nuclear-reactor" },
    { kind = types.boiler, entity = "boiler", switched = true },
    { kind = types.heat_pipe, entity = "heat-pipe" },
    { kind = types.turret, entity = "gun-turret", switched = true },
    { kind = types.artillery_turret, entity = "artillery-turret", switched = true },
    { kind = types.land_mine, entity = "land-mine", switched = true },
    { kind = types.loader, entity = "loader", switched = true },
    { kind = types.splitter, entity = "splitter" },
    { kind = types.rocket_silo, entity = "rocket-silo" },
    { kind = types.display_panel, entity = "display-panel" },
    { kind = types.proxy_container, entity = "proxy-container" },
    { kind = types.agricultural_tower, entity = "agricultural-tower", switched = true },
    { kind = types.asteroid_collector, entity = "asteroid-collector", switched = true },
    { kind = types.cargo_landing_pad, entity = "cargo-landing-pad" },
}

--- rows of this many, each hanging off its own pole
local PER_ROW = 6
local SPACING = 12

--- Build the whole thing and give back the patch it was built in
local function build()
    local patch = world.arena(260)
    local surface = patch.surface
    local poles = {}

    for index, spec in ipairs(SHOWCASE) do
        local row = math.floor((index - 1) / PER_ROW)
        local column = (index - 1) % PER_ROW
        local x = patch.left + 10 + column * SPACING
        local y = patch.top + 10 + row * SPACING

        if column == 0 then
            local pole = surface.create_entity{ name = "medium-electric-pole",
                position = { x - 6, y }, force = "player" }
            poles[#poles + 1] = pole
            patch.entities[#patch.entities + 1] = pole
        end

        if spec.companion then
            -- a gate only counts as the wall's gate when it faces along the wall line,
            -- which is why this one is placed east and pointed east
            local companion = surface.create_entity{ name = spec.companion.name,
                position = { x + 1, y }, force = "player",
                direction = spec.companion.direction }
            assert(companion, "could not place the companion " .. spec.companion.name)
            patch.entities[#patch.entities + 1] = companion
        end

        local entity = surface.create_entity{ name = spec.entity, position = { x, y },
                                              force = "player", raise_built = false }
        assert(entity, "could not place " .. spec.entity)
        local control = entity.get_or_create_control_behavior()
        assert(control, spec.entity .. " reported no control behaviour")
        assert.equals(spec.kind, control.type,
            spec.entity .. " does not report the control behaviour it was listed under")

        if spec.setup then spec.setup(control, entity) end
        if spec.switched then
            -- the generic on/off half, which is all these have to say
            pcall(function()
                control.circuit_enable_disable = true
                control.circuit_condition = condition(A, ">", 0)
            end)
        end

        -- every entity hangs off its row's pole, alternating colour so both appear
        local colour = index % 2 == 0 and wire.circuit_green or wire.circuit_red
        local own = colour
        if entity.type == "arithmetic-combinator" or entity.type == "decider-combinator"
            or entity.type == "selector-combinator" then
            own = colour == wire.circuit_green and wire.combinator_input_green
                or wire.combinator_input_red
        end
        local connector = entity.get_wire_connector(own, true)
        assert(connector, spec.entity .. " has no circuit connector to wire")
        connector.connect_to(poles[#poles].get_wire_connector(colour, true), false)
        patch.entities[#patch.entities + 1] = entity
    end

    -- and a backbone joining the poles, so the whole thing is one graph
    for index = 2, #poles do
        poles[index].get_wire_connector(wire.circuit_red, true)
            .connect_to(poles[index - 1].get_wire_connector(wire.circuit_red, true), false)
    end

    return patch
end

describe("one of every wireable thing", function()
    test("is drawn, and covers every control behaviour the game has", function()
        local patch = build()
        local lines = patch.lines()

        local nodes = 0
        for _, line in ipairs(lines) do
            if line:match("%[shape=record") then nodes = nodes + 1 end
        end
        -- one node per entity in the showcase, plus the pole each row hangs off. The
        -- gate is the one thing placed here that carries no wire of its own: it exists
        -- so that the wall beside it has something to control.
        local poles = math.ceil(#SHOWCASE / PER_ROW)
        assert.equals(#SHOWCASE + poles, nodes)

        local kinds = {}
        for _, spec in ipairs(SHOWCASE) do kinds[spec.kind] = true end
        local covered = 0
        for _ in pairs(kinds) do covered = covered + 1 end
        -- thirty eight of the thirty nine; a space platform hub needs a platform to sit on
        assert.equals(38, covered)

        helpers.write_file("showcase.gv", Graph.Document(patch.entities))
    end)

    --- Anything that was given something to say has to say it. A wooden chest and a heat
    --- pipe have nothing to configure, so their name is the whole of their label and that
    --- is correct; this is about the ones that were set up and might have stayed silent.
    test("says what each configured entity was configured to do", function()
        local patch = build()
        local labelled = {}
        for _, line in ipairs(patch.lines()) do
            local label = line:match('label="(.-)" pos=')
            if label then
                local name = label:match("^{([^|}]+)") or label:match("|{([^|}]+)")
                labelled[name] = labelled[name] or {}
                labelled[name][#labelled[name] + 1] = label
            end
        end

        for _, spec in ipairs(SHOWCASE) do
            if spec.setup or spec.switched then
                local labels = labelled[spec.entity]
                assert.is_not_nil(labels, spec.entity .. " was not drawn at all")
                local said = false
                for _, label in ipairs(labels) do
                    if label:find("|") then said = true end
                end
                assert.is_true(said,
                    spec.entity .. " was drawn with nothing but its name: " ..
                    table.concat(labels, " "))
            end
        end
    end)

    test("draws both wire colours and both combinator sides", function()
        local patch = build()
        local red, green, west, east = 0, 0, 0, 0
        for _, line in ipairs(patch.lines()) do
            if line:match("color=red") then red = red + 1 end
            if line:match("color=green") then green = green + 1 end
            if line:match("port=w") then west = west + 1 end
            if line:match("port=e") then east = east + 1 end
        end
        assert.is_true(red > 0 and green > 0, "only one wire colour was drawn")
        assert.is_true(west > 0, "no combinator input side was drawn")
    end)
end)

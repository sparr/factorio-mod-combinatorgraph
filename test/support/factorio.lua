--- Stand-ins for the parts of the Factorio API that lib/ touches.
--- Only enough to exercise the decisions; anything about what the engine really reports
--- for a real combinator belongs in the integration tier instead.
local support = {}

--- Only identity matters for these, so the numbers are arbitrary but stable.
local function enum(names)
    local values = {}
    for index, name in ipairs(names) do values[name] = index end
    return values
end

--- Must run before requiring lib/graph, which reads defines.wire_connector_id at load
function support.install_defines()
    _G.defines = {
        control_behavior = {
            type = enum({ "accumulator", "arithmetic_combinator", "constant_combinator",
                          "container", "decider_combinator", "generic_on_off", "inserter",
                          "lamp", "logistic_container", "mining_drill",
                          "programmable_speaker", "rail_chain_signal", "rail_signal",
                          "roboport", "selector_combinator", "single_fluid_box", "train_stop",
                          "transport_belt",
                          "wall" }),
            inserter = { hand_read_mode = enum({ "pulse", "hold" }) },
            transport_belt = { content_read_mode = enum({ "pulse", "hold" }) },
            mining_drill = { resource_read_mode = enum({ "this_miner", "entire_patch" }) },
        },
        wire_connector_id = enum({ "circuit_red", "circuit_green",
                                   "combinator_input_red", "combinator_input_green",
                                   "combinator_output_red", "combinator_output_green",
                                   "pole_copper" }),
    }
end

--- A signal, as the API hands one back
function support.signal(name, type)
    return { name = name, type = type or "item" }
end

--- One entity, with whatever control behaviour the test wants it to report.
--- `wires` maps a wire_connector_id to a list of connectors on the far end, and is filled
--- in afterwards by `support.wire`.
function support.entity(fields)
    local entity = {
        name = fields.name,
        type = fields.type or fields.name,
        unit_number = fields.unit_number,
        position = fields.position or { x = 0, y = 0 },
        connectors = {},
    }
    local control = fields.control
    entity.get_or_create_control_behavior = function() return control end
    entity.get_wire_connectors = function() return entity.connectors end
    return entity
end

local function connector_of(entity, id)
    if not entity.connectors[id] then
        entity.connectors[id] = {
            wire_connector_id = id,
            owner = entity,
            connections = {},
            connection_count = 0,
        }
    end
    return entity.connectors[id]
end

--- Wire two connectors together, both ways, as the game does
function support.wire(a, id_a, b, id_b)
    local first, second = connector_of(a, id_a), connector_of(b, id_b)
    first.connections[#first.connections + 1] = { target = second }
    second.connections[#second.connections + 1] = { target = first }
    first.connection_count = #first.connections
    second.connection_count = #second.connections
end

return support

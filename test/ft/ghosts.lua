--- A ghost carries everything the entity it stands for was set up with: the same control
--- behaviour, readable, and its own wire connectors. So it is worth drawing as the thing
--- it is going to be rather than as the word "entity-ghost", which is what it used to say.
local world = require("test.ft.world")

local wire = defines.wire_connector_id

--- A ghost of `name`, configured as if it had been built
local function ghost(patch, name, x, configure)
    local entity = patch.surface.create_entity{
        name = "entity-ghost", inner_name = name,
        position = { patch.left + x, patch.top + 10 }, force = "player" }
    assert(entity, "could not place a ghost of " .. name)
    if configure then configure(entity.get_or_create_control_behavior(), entity) end
    patch.entities[#patch.entities + 1] = entity
    return entity
end

--- the label of the node whose first row is `first`
local function label_starting(patch, first)
    for _, line in ipairs(patch.lines()) do
        local label = line:match('label="(.-)" pos=')
        if label and (label:find("^{" .. first .. "|") or label:find("|{" .. first .. "|")) then
            return label
        end
    end
    return nil
end

describe("a ghost", function()
    test("is drawn as what it will become, under a row saying it is not there yet", function()
        local patch = world.arena(120)
        local lamp = ghost(patch, "small-lamp", 10, function(control)
            control.use_colors = true
            control.circuit_enable_disable = true
            control.circuit_condition = { first_signal = { type = "item",
                name = "iron-plate" }, comparator = "=", constant = 1 }
        end)
        local chest = patch.surface.create_entity{ name = "wooden-chest",
            position = { patch.left + 14, patch.top + 10 }, force = "player" }
        patch.entities[#patch.entities + 1] = chest
        lamp.get_wire_connector(wire.circuit_red, true)
            .connect_to(chest.get_wire_connector(wire.circuit_red, true), false)

        local label = label_starting(patch, "Ghost")
        assert.is_not_nil(label, "no ghost row was drawn")
        assert.equals('{Ghost|small-lamp|Use Colors|{iron-plate|\\=|1}}', label)
    end)

    test("keeps the settings it was given, exactly as a built one would", function()
        local patch = world.arena(120)
        local decider = ghost(patch, "decider-combinator", 10, function(control)
            control.parameters = {
                conditions = { { first_signal = { type = "virtual", name = "signal-A" },
                                 comparator = ">", constant = 7 } },
                outputs = { { signal = { type = "item", name = "iron-plate" } } },
            }
        end)
        local chest = patch.surface.create_entity{ name = "wooden-chest",
            position = { patch.left + 16, patch.top + 10 }, force = "player" }
        patch.entities[#patch.entities + 1] = chest
        decider.get_wire_connector(wire.combinator_output_red, true)
            .connect_to(chest.get_wire_connector(wire.circuit_red, true), false)

        local label = label_starting(patch, "Ghost")
        assert.is_not_nil(label:find("signal%-A"), label)
        assert.is_not_nil(label:find("iron%-plate"), label)
    end)

    --- a ghost's own type is entity-ghost; the sides it has are the sides of the thing it
    --- will become, and the edges have to land on them
    test("has the sides of the combinator it will become", function()
        local patch = world.arena(120)
        local decider = ghost(patch, "decider-combinator", 10)
        local chest = patch.surface.create_entity{ name = "wooden-chest",
            position = { patch.left + 16, patch.top + 10 }, force = "player" }
        patch.entities[#patch.entities + 1] = chest
        decider.get_wire_connector(wire.combinator_output_red, true)
            .connect_to(chest.get_wire_connector(wire.circuit_red, true), false)

        local edge
        for _, line in ipairs(patch.lines()) do
            edge = edge or line:match(" %-%- .*tailport=(%a)")
        end
        assert.equals("e", edge, "the ghost's output side was not drawn as its east port")
    end)

    test("of something with nothing to configure is still named", function()
        local patch = world.arena(120)
        local pole = ghost(patch, "medium-electric-pole", 10)
        local chest = patch.surface.create_entity{ name = "wooden-chest",
            position = { patch.left + 14, patch.top + 10 }, force = "player" }
        patch.entities[#patch.entities + 1] = chest
        pole.get_wire_connector(wire.circuit_red, true)
            .connect_to(chest.get_wire_connector(wire.circuit_red, true), false)
        assert.equals('{Ghost|medium-electric-pole}',
                      label_starting(patch, "Ghost"))
    end)
end)

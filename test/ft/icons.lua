--- The pictures, which the data stage wrote down because nothing at runtime can say where
--- an icon file lives.
local world = require("test.ft.world")
local Graph = require("lib.graph")

local wire = defines.wire_connector_id

local function two_wired(patch)
    local pump = patch.surface.create_entity{ name = "pump",
        position = { patch.left + 10, patch.top + 10 }, force = "player" }
    local control = pump.get_or_create_control_behavior()
    control.circuit_enable_disable = true
    control.circuit_condition = { first_signal = { type = "fluid", name = "water" },
                                  comparator = ">", constant = 0 }
    local chest = patch.surface.create_entity{ name = "wooden-chest",
        position = { patch.left + 14, patch.top + 10 }, force = "player" }
    pump.get_wire_connector(wire.circuit_red, true)
        .connect_to(chest.get_wire_connector(wire.circuit_red, true), false)
    return { pump, chest }
end

local function icons()
    local record = prototypes.mod_data["combinatorgraph-icons"]
    assert(record, "the data stage recorded no icons")
    return record.data.paths, record.data.sizes
end

describe("the recorded icons", function()
    test("cover what the game ships, by a path relative to its data directory", function()
        local paths, sizes = icons()
        assert.equals("base/graphics/icons/pump.png", paths["pump"])
        assert.equals("base/graphics/icons/decider-combinator.png",
                      paths["decider-combinator"])
        -- the file is wider than this: Factorio keeps an icon's mipmaps beside it, and
        -- the size is what says where to cut if the mipmaps are unwanted
        assert.equals(64, sizes["pump"])
    end)
end)

describe("the node style", function()
    test("is a record unless something asks otherwise", function()
        local patch = world.arena(120)
        local document = Graph.Document(two_wired(patch))
        assert.is_not_nil(document:find("shape=record"), document)
    end)

    test("is a table when asked for, pictures or not", function()
        local patch = world.arena(120)
        local document = Graph.Document(two_wired(patch), { html = true })
        assert.is_not_nil(document:find("shape=plaintext"), document)
        assert.is_not_nil(document:find("<TABLE"), document)
        assert.is_nil(document:find("<IMG"), document)
        -- the rows the record would have had are the table's rows
        assert.is_not_nil(document:find("<TD>pump</TD>"), document)
        assert.is_not_nil(document:find("<TD>water</TD>"), document)
    end)
end)

describe("a graph asked for pictures", function()
    test("draws its own table rather than a record, with the image beside the name", function()
        local patch = world.arena(120)
        local paths = icons()
        local document = Graph.Document(two_wired(patch),
                                        { html = true, icons = paths })

        assert.is_not_nil(document:find("shape=plaintext"), document)
        assert.is_nil(document:find("shape=record"), document)
        assert.is_not_nil(
            document:find('<TD><IMG SRC="base/graphics/icons/pump.png"/></TD><TD>pump</TD>'),
            document)
    end)

    test("is a plain record when it was not asked", function()
        local patch = world.arena(120)
        local document = Graph.Document(two_wired(patch))
        assert.is_not_nil(document:find("shape=record"), document)
        assert.is_nil(document:find("<IMG"), document)
    end)

    test("still draws an entity it has no picture for", function()
        local patch = world.arena(120)
        local document = Graph.Document(two_wired(patch), { html = true, icons = {} })
        assert.is_not_nil(document:find(">pump</TD>"), document)
        assert.is_nil(document:find("<IMG"), document)
    end)
end)

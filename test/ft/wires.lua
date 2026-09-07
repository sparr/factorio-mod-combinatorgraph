--- What the game really reports about wires, as opposed to what the stubs say it does.
local world = require("test.ft.world")

local wire = defines.wire_connector_id

describe("two chests on one wire", function()
    test("are joined once, by a wire of the colour they were joined with", function()
        local patch = world.patch()
        local a = patch.place("wooden-chest", 5, 5)
        local b = patch.place("wooden-chest", 8, 5)
        patch.wire(a, wire.circuit_red, b, wire.circuit_red)

        assert.same({
            'E1 [shape=record label="{wooden-chest}" pos="' ..
                (patch.left + 5) .. ',' .. (patch.top + 5) .. '"];',
            'E1:1 -- E2:1 [color=red headport=_ tailport=_];',
            'E2 [shape=record label="{wooden-chest}" pos="' ..
                (patch.left + 8) .. ',' .. (patch.top + 5) .. '"];',
        }, patch.lines())
    end)
end)

describe("a chest with nothing wired to it", function()
    test("is left out of the document", function()
        local patch = world.patch()
        patch.place("wooden-chest", 5, 5)
        assert.same({}, patch.lines())
    end)
end)

describe("two combinators", function()
    test("are joined output side to input side", function()
        local patch = world.patch()
        local a = patch.place("arithmetic-combinator", 5, 5)
        local b = patch.place("arithmetic-combinator", 9, 5)
        patch.wire(a, wire.combinator_output_red, b, wire.combinator_input_red)

        local lines = patch.lines()
        assert.equals('E1:2 -- E2:1 [color=red headport=w tailport=e];', lines[2])
    end)

    test("can be joined on both colours at once, and both are drawn", function()
        local patch = world.patch()
        local a = patch.place("arithmetic-combinator", 5, 5)
        local b = patch.place("arithmetic-combinator", 9, 5)
        patch.wire(a, wire.combinator_output_red, b, wire.combinator_input_red)
        patch.wire(a, wire.combinator_output_green, b, wire.combinator_input_green)

        local drawn = {}
        for _, line in ipairs(patch.lines()) do
            if line:match(" %-%- ") then drawn[#drawn + 1] = line end
        end
        table.sort(drawn)
        assert.same({
            'E1:2 -- E2:1 [color=green headport=w tailport=e];',
            'E1:2 -- E2:1 [color=red headport=w tailport=e];',
        }, drawn)
    end)
end)

--- Both ends of this one are the same entity, so the "seen it already" test cannot catch
--- it. It is the case that decides whether the dedup is right.
describe("a combinator wired to itself", function()
    test("is drawn exactly once", function()
        local patch = world.patch()
        local a = patch.place("arithmetic-combinator", 5, 5)
        patch.wire(a, wire.combinator_input_green, a, wire.combinator_output_green)

        assert.same({
            'E1 [shape=record label="<1>\\>|{arithmetic-combinator}|<2>\\>" pos="' ..
                (patch.left + 5) .. ',' .. (patch.top + 5) .. '"];',
            'E1:1 -- E1:2 [color=green headport=e tailport=w];',
        }, patch.lines())
    end)
end)

describe("a power pole", function()
    test("carries copper, which is not a circuit wire and is not drawn", function()
        local patch = world.patch()
        local a = patch.place("small-electric-pole", 5, 5)
        local b = patch.place("small-electric-pole", 8, 5)
        -- the poles wire themselves together with copper on placement
        assert.same({}, patch.lines())

        -- and a circuit wire between the same two poles is drawn
        patch.wire(a, wire.circuit_red, b, wire.circuit_red)
        assert.equals('E1:1 -- E2:1 [color=red headport=_ tailport=_];', patch.lines()[2])
    end)
end)

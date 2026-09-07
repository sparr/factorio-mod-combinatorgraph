local support = require("test.support.factorio")
support.install_defines()
local Graph = require("lib.graph")

local wire = defines.wire_connector_id
local types = defines.control_behavior.type

local function combinator(unit_number, x)
    return support.entity{ name = "arithmetic-combinator", type = "arithmetic-combinator",
                           unit_number = unit_number, position = { x = x, y = 0 },
                           control = { type = types.arithmetic_combinator,
                                       parameters = {} } }
end

local function chest(unit_number, x)
    return support.entity{ name = "wooden-chest", type = "container",
                           unit_number = unit_number, position = { x = x, y = 0 },
                           control = { type = types.container } }
end

--- the edge and node lines, without the two lines of preamble or the closing brace
local function body(document)
    local lines = {}
    for line in document:gmatch("[^\n]+") do lines[#lines + 1] = line end
    table.remove(lines, 1)
    table.remove(lines, 1)
    table.remove(lines)
    return lines
end

describe("WirePort", function()
    it("puts a combinator's input on the west and its output on the east", function()
        local ent = { type = "arithmetic-combinator" }
        assert.equals("w", Graph.WirePort(ent, 1))
        assert.equals("e", Graph.WirePort(ent, 2))
        assert.equals("e", Graph.WirePort({ type = "decider-combinator" }, 2))
    end)

    it("gives everything else one port", function()
        assert.equals("_", Graph.WirePort({ type = "container" }, 1))
    end)
end)

describe("the connector table", function()
    it("puts both combinator sides on the ports the labels use", function()
        assert.equals(1, Graph.connectors[wire.combinator_input_red].port)
        assert.equals(1, Graph.connectors[wire.combinator_input_green].port)
        assert.equals(2, Graph.connectors[wire.combinator_output_red].port)
        assert.equals(2, Graph.connectors[wire.combinator_output_green].port)
    end)

    it("puts a one sided entity on the input port", function()
        assert.equals(1, Graph.connectors[wire.circuit_red].port)
        assert.equals(1, Graph.connectors[wire.circuit_green].port)
    end)

    -- poles and power switches carry copper, which is not a circuit wire
    it("has nothing to say about copper", function()
        assert.is_nil(Graph.connectors[wire.pole_copper])
    end)
end)

describe("the document", function()
    it("leaves out an entity with nothing wired to it", function()
        local lone = chest(1, 0)
        assert.same({}, body(Graph.Document({ lone })))
    end)

    it("draws each wire once, from whichever end it reaches first", function()
        local a, b = chest(1, 0), chest(2, 3)
        support.wire(a, wire.circuit_red, b, wire.circuit_red)
        local lines = body(Graph.Document({ a, b }))
        assert.equals(3, #lines)
        assert.equals('1:1 -- 2:1 [color=red headport=_ tailport=_];', lines[2])
    end)

    it("colours a green wire green", function()
        local a, b = chest(1, 0), chest(2, 3)
        support.wire(a, wire.circuit_green, b, wire.circuit_green)
        assert.equals('1:1 -- 2:1 [color=green headport=_ tailport=_];',
                      body(Graph.Document({ a, b }))[2])
    end)

    it("takes a combinator's output side to the other's input side", function()
        local a, b = combinator(1, 0), combinator(2, 3)
        support.wire(a, wire.combinator_output_red, b, wire.combinator_input_red)
        assert.equals('1:2 -- 2:1 [color=red headport=w tailport=e];',
                      body(Graph.Document({ a, b }))[2])
    end)

    -- a combinator wired to itself is the case the "seen it already" test cannot catch,
    -- since both ends are the same entity: it is drawn once, from the output side
    it("draws a combinator wired to itself exactly once", function()
        local a = combinator(1, 0)
        support.wire(a, wire.combinator_input_green, a, wire.combinator_output_green)
        local lines = body(Graph.Document({ a }))
        assert.equals(2, #lines)
        assert.equals('1:1 -- 1:2 [color=green headport=e tailport=w];', lines[2])
    end)

    it("ignores a copper connector", function()
        local a, b = chest(1, 0), chest(2, 3)
        support.wire(a, wire.pole_copper, b, wire.pole_copper)
        assert.same({}, body(Graph.Document({ a, b })))
    end)

    it("wraps the whole thing in a graphviz document", function()
        local document = Graph.Document({})
        assert.equals("graph combinators {", document:match("^[^\n]+"))
        assert.equals("}", document:match("[^\n]+$"))
    end)

    it("puts each node where the entity is", function()
        local a, b = chest(1, -6), chest(2, 3)
        support.wire(a, wire.circuit_red, b, wire.circuit_red)
        assert.equals('1 [shape=record label="{wooden-chest}" pos="-6,0"];',
                      body(Graph.Document({ a, b }))[1])
    end)
end)

--- What the game really reports about a control behaviour. The unit tier says what the
--- labels do with each shape; this says the shapes are the ones the game hands over.
local world = require("test.ft.world")

local wire = defines.wire_connector_id

--- Place `name`, let `configure` set it up, wire it to a chest so it reaches the
--- document at all, and give back its node line.
---@param name string
---@param configure fun(control: any, entity: LuaEntity)?
local function label_of(name, configure)
    local patch = world.patch()
    local subject = patch.place(name, 5, 5)
    local chest = patch.place("wooden-chest", 10, 10)
    if configure then configure(subject.get_or_create_control_behavior(), subject) end
    patch.wire(subject, wire.circuit_red, chest, wire.circuit_red)
    for _, line in ipairs(patch.lines()) do
        if line:match("^E1 %[") then
            return line:match('label="(.*)" pos=')
        end
    end
    error("the subject never reached the document")
end

describe("a constant combinator", function()
    test("reports the signals in its logistic sections", function()
        assert.equals('{constant-combinator|On|{iron-plate|42}|{signal-A|7}}',
            label_of("constant-combinator", function(control)
                local section = control.get_section(1) or control.add_section()
                section.set_slot(1, { value = { type = "item", name = "iron-plate",
                                                quality = "normal" }, min = 42 })
                section.set_slot(2, { value = { type = "virtual", name = "signal-A",
                                                quality = "normal" }, min = 7 })
            end))
    end)

    --- A real combinator can hold more than one section, and the whole point of reading
    --- sections rather than a flat list is that all of them count.
    test("reports every one of its sections, not just the first", function()
        assert.equals('{constant-combinator|On|{iron-plate|1}|{copper-plate|2}}',
            label_of("constant-combinator", function(control)
                local first = control.get_section(1) or control.add_section()
                first.set_slot(1, { value = { type = "item", name = "iron-plate",
                                              quality = "normal" }, min = 1 })
                local second = control.add_section()
                second.set_slot(1, { value = { type = "item", name = "copper-plate",
                                               quality = "normal" }, min = 2 })
                assert.equals(2, control.sections_count)
            end))
    end)

    --- Issue #4: an empty one has no sections at all. Before 2.0 this was a flat list of
    --- parameters, and reading it as one is what took the mod down.
    test("survives being empty", function()
        assert.equals('{constant-combinator|On|}', label_of("constant-combinator"))
    end)
end)

describe("a decider combinator", function()
    test("reports every condition and every output", function()
        assert.equals(
            '<1>\\>|{decider-combinator|{signal-A|\\>|100}|{signal-B|\\<|2}' ..
            '|{signal-C|=|1}|{signal-D|=|input}}|<2>\\>',
            label_of("decider-combinator", function(control)
                control.parameters = {
                    conditions = {
                        { first_signal = { type = "virtual", name = "signal-A" },
                          comparator = ">", constant = 100 },
                        { first_signal = { type = "virtual", name = "signal-B" },
                          comparator = "<", constant = 2 },
                    },
                    outputs = {
                        { signal = { type = "virtual", name = "signal-C" },
                          copy_count_from_input = false },
                        { signal = { type = "virtual", name = "signal-D" },
                          copy_count_from_input = true },
                    },
                }
            end))
    end)
end)

describe("an arithmetic combinator", function()
    test("reports both sides of its operation", function()
        assert.equals('<1>\\>|{arithmetic-combinator|{iron-plate|*|3}|signal-B}|<2>\\>',
            label_of("arithmetic-combinator", function(control)
                control.parameters = {
                    first_signal = { type = "item", name = "iron-plate" },
                    second_constant = 3, operation = "*",
                    output_signal = { type = "virtual", name = "signal-B" },
                }
            end))
    end)
end)

describe("an inserter", function()
    test("reports its condition and its filter mode together", function()
        assert.equals('{inserter|{signal-C|\\<|5}|Set Filters (whitelist)}',
            label_of("inserter", function(control, entity)
                control.circuit_enable_disable = true
                control.circuit_condition = {
                    first_signal = { type = "virtual", name = "signal-C" },
                    comparator = "<", constant = 5 }
                control.circuit_set_filters = true
                entity.inserter_filter_mode = "whitelist"
            end))
    end)
end)

describe("a requester chest", function()
    --- One mode_of_operation became two switches in 2.0, and unlike the mode they are
    --- not exclusive, so this is a shape the old code could not have reported.
    test("reports reading and requesting at the same time", function()
        assert.equals('{requester-chest|Read Contents|Set Requests}',
            label_of("requester-chest", function(control)
                control.read_contents = true
                control.set_requests = true
            end))
    end)
end)

describe("a storage tank", function()
    -- its behaviour type was renamed single_fluid_box in 2.1
    test("is named and nothing more", function()
        assert.equals('{storage-tank}', label_of("storage-tank"))
    end)
end)

describe("a transport belt", function()
    test("reports its condition and its read mode", function()
        assert.equals('{transport-belt|{copper-plate|\\>|0}|Pulse}',
            label_of("transport-belt", function(control)
                control.circuit_enable_disable = true
                control.circuit_condition = {
                    first_signal = { type = "item", name = "copper-plate" },
                    comparator = ">", constant = 0 }
                control.read_contents = true
            end))
    end)
end)

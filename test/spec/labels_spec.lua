local support = require("test.support.factorio")
support.install_defines()
local Labels = require("lib.labels")

local types = defines.control_behavior.type

--- An entity whose control behaviour is whatever the test says it is
local function labelled(name, control, entity_type)
    return Labels.EntityLabel(support.entity{
        name = name, type = entity_type, control = control })
end

describe("SignalLabel", function()
    it("gives the signal's name", function()
        assert.equals("iron-plate", Labels.SignalLabel(support.signal("iron-plate")))
    end)

    it("gives nothing for no signal at all", function()
        assert.is_nil(Labels.SignalLabel(nil))
    end)

    -- an empty slot is a table with no name, not an absent one
    it("gives nothing for an empty slot", function()
        assert.is_nil(Labels.SignalLabel({}))
    end)
end)

describe("ConditionLabel", function()
    it("reads a signal against a constant", function()
        assert.equals('{signal-A|\\>|5}', Labels.ConditionLabel{
            first_signal = support.signal("signal-A"), comparator = ">", constant = 5 })
    end)

    it("reads a signal against another signal", function()
        assert.equals('{signal-A|\\=|signal-B}', Labels.ConditionLabel{
            first_signal = support.signal("signal-A"), comparator = "=",
            second_signal = support.signal("signal-B") })
    end)

    -- issue #2: a condition with no first signal can never be true, so it is left out
    it("gives nothing for a condition that can never fire", function()
        assert.is_nil(Labels.ConditionLabel{ comparator = ">", constant = 5 })
        assert.is_nil(Labels.ConditionLabel{ first_signal = {}, comparator = ">",
                                             constant = 5 })
    end)
end)

describe("a constant combinator", function()
    it("reads its signals out of its logistic sections", function()
        assert.equals('{constant-combinator|On|{iron-plate|42}|{signal-A|7}}',
            labelled("constant-combinator", {
                type = types.constant_combinator, enabled = true,
                sections = { { filters = {
                    { value = support.signal("iron-plate"), min = 42 },
                    { value = support.signal("signal-A", "virtual"), min = 7 },
                } } },
            }))
    end)

    it("reads across several sections", function()
        assert.equals('{constant-combinator|On|{a|1}|{b|2}}',
            labelled("constant-combinator", {
                type = types.constant_combinator, enabled = true,
                sections = {
                    { filters = { { value = support.signal("a"), min = 1 } } },
                    { filters = { { value = support.signal("b"), min = 2 } } },
                },
            }))
    end)

    -- issue #4: an empty one has no sections at all, which used to reach pairs as nil
    it("survives having no sections at all", function()
        assert.equals('{constant-combinator|Off|}',
            labelled("constant-combinator",
                     { type = types.constant_combinator, enabled = false }))
    end)

    it("skips an empty slot in a section", function()
        assert.equals('{constant-combinator|On|{a|1}}',
            labelled("constant-combinator", {
                type = types.constant_combinator, enabled = true,
                sections = { { filters = {
                    { value = support.signal("a"), min = 1 },
                    { value = nil, min = 9 },
                } } },
            }))
    end)
end)

describe("a decider combinator", function()
    it("reads every condition and every output", function()
        assert.equals(
            '<1>\\>|{decider-combinator|{signal-A|\\>|100}|{signal-B|\\<|2}' ..
            '|{signal-C|=|1}|{signal-D|=|input}}|<2>\\>',
            labelled("decider-combinator", {
                type = types.decider_combinator,
                parameters = {
                    conditions = {
                        { first_signal = support.signal("signal-A"), comparator = ">",
                          constant = 100 },
                        { first_signal = support.signal("signal-B"), comparator = "<",
                          constant = 2 },
                    },
                    outputs = {
                        { signal = support.signal("signal-C"), copy_count_from_input = false },
                        { signal = support.signal("signal-D"), copy_count_from_input = true },
                    },
                },
            }))
    end)

    it("survives holding neither", function()
        assert.equals('<1>\\>|{decider-combinator}|<2>\\>',
            labelled("decider-combinator",
                     { type = types.decider_combinator, parameters = {} }))
    end)
end)

describe("an inserter", function()
    it("reports both switches at once", function()
        local entity = support.entity{ name = "inserter" }
        entity.inserter_filter_mode = "whitelist"
        local control = {
            type = types.inserter, entity = entity,
            circuit_enable_disable = true,
            circuit_condition = { first_signal = support.signal("signal-A"),
                                  comparator = ">", constant = 0 },
            circuit_set_filters = true,
        }
        assert.equals('{inserter|{signal-A|\\>|0}|Set Filters (whitelist)}',
            labelled("inserter", control))
    end)

    it("reports neither when neither is on", function()
        assert.equals('{inserter}', labelled("inserter", { type = types.inserter }))
    end)
end)

describe("a logistic chest", function()
    -- one mode_of_operation became two switches, and both can be on at once, which the
    -- single mode could never express
    it("reports both switches at once", function()
        assert.equals('{logistic-chest|Read Contents|Set Requests}',
            labelled("logistic-chest", { type = types.logistic_container,
                                         read_contents = true, set_requests = true }))
    end)

    it("reports one on its own", function()
        assert.equals('{logistic-chest|Set Requests}',
            labelled("logistic-chest", { type = types.logistic_container,
                                         set_requests = true }))
    end)
end)

describe("a plain container or tank", function()
    it("says nothing beyond its name", function()
        assert.equals('{wooden-chest}',
            labelled("wooden-chest", { type = types.container }))
        -- storage_tank was renamed single_fluid_box in 2.1
        assert.equals('{storage-tank}',
            labelled("storage-tank", { type = types.single_fluid_box }))
    end)
end)

describe("an entity with no control behaviour at all", function()
    it("falls back to its type and name", function()
        assert.equals('{wall|stone-wall}',
            Labels.EntityLabel(support.entity{ name = "stone-wall", type = "wall" }))
    end)
end)

describe("an entity nothing here knows about", function()
    it("is labelled with its type", function()
        assert.equals('{some-modded-thing|assembling-machine}',
            labelled("some-modded-thing", { type = 9999 }, "assembling-machine"))
    end)
end)

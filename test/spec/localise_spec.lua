local Localise = require("lib.localise")

describe("a collector", function()
    it("gives back a placeholder rather than the name", function()
        local collector = Localise.collector()
        local placeholder = collector.add({ "item-name.iron-plate" })
        assert.is_string(placeholder)
        assert.equals(1, #collector.strings)
        assert.same({ "item-name.iron-plate" }, collector.strings[1])
    end)

    it("asks for the same name only once", function()
        local collector = Localise.collector()
        local first = collector.add({ "?", { "item-name.iron-plate" }, "iron-plate" })
        local second = collector.add({ "?", { "item-name.iron-plate" }, "iron-plate" })
        assert.equals(first, second)
        assert.equals(1, #collector.strings)
    end)

    it("tells two different names apart", function()
        local collector = Localise.collector()
        assert.are_not.equal(collector.add({ "item-name.iron-plate" }),
                             collector.add({ "item-name.copper-plate" }))
        assert.equals(2, #collector.strings)
    end)

    it("keeps the English an alternatives list ends with", function()
        local collector = Localise.collector()
        collector.add({ "?", { "item-name.iron-plate" }, "iron-plate" })
        assert.equals("iron-plate", collector.fallbacks[1])
    end)
end)

describe("rendering", function()
    it("puts the translations where the placeholders are", function()
        local collector = Localise.collector()
        local document = "a=" .. collector.add({ "one" }) ..
                         " b=" .. collector.add({ "two" })
        assert.equals("a=Iron plate b=Copper plate",
            Localise.render(document, { "Iron plate", "Copper plate" }))
    end)

    it("falls back to the English for a name that came back untranslated", function()
        local collector = Localise.collector()
        local document = collector.add({ "?", { "item-name.iron-plate" }, "iron-plate" })
        assert.equals("iron-plate",
            Localise.render(document, {}, collector.fallbacks))
    end)

    it("leaves a placeholder alone when there is nothing to put there", function()
        local collector = Localise.collector()
        local document = collector.add({ "one" })
        assert.is_true(Localise.pending(Localise.render(document, {})))
    end)

    it("says when a document has nothing left to fill in", function()
        assert.is_false(Localise.pending("nothing to see here"))
        local collector = Localise.collector()
        assert.is_true(Localise.pending(collector.add({ "one" })))
    end)

    -- a translated name is dropped in as text, so anything in it that a pattern would
    -- read as special has to survive
    it("survives a translation containing a percent sign", function()
        local collector = Localise.collector()
        local document = "x=" .. collector.add({ "one" })
        assert.equals("x=100% uptime", Localise.render(document, { "100% uptime" }))
    end)
end)

describe("naming a signal", function()
    it("looks in the section its type belongs to", function()
        assert.same({ "?", { "virtual-signal-name.signal-A" }, "signal-A" },
            Localise.signal({ type = "virtual", name = "signal-A" }))
        assert.same({ "?", { "fluid-name.water" }, "water" },
            Localise.signal({ type = "fluid", name = "water" }))
    end)

    it("treats a signal with no type as an item, which is what the game does", function()
        assert.same({ "?", { "item-name.iron-plate" }, "iron-plate" },
            Localise.signal({ name = "iron-plate" }))
    end)

    it("falls back to the internal name for a type it does not know", function()
        assert.same({ "?", { "item-name.mystery" }, "mystery" },
            Localise.signal({ type = "something-new", name = "mystery" }))
    end)
end)

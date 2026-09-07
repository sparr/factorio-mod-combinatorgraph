--- The localised half, against the real game: real prototype names, real settings, and
--- the real shape of what the game hands back.
local world = require("test.ft.world")
local Localise = require("lib.localise")

local wire = defines.wire_connector_id

describe("the settings", function()
    test("both exist and both ship switched off", function()
        local player_settings = settings.get_player_settings(game.players[1])
        assert.is_false(player_settings["combinatorgraph-show-ineffective"].value)
        assert.is_false(player_settings["combinatorgraph-localise"].value)
    end)
end)

describe("a document built with a localiser", function()
    local function documented()
        local patch = world.patch()
        local combinator = patch.place("constant-combinator", 5, 5)
        local chest = patch.place("wooden-chest", 8, 5)
        local control = combinator.get_or_create_control_behavior()
        local section = control.get_section(1) or control.add_section()
        section.set_slot(1, { value = { type = "item", name = "iron-plate",
                                        quality = "normal" }, min = 1 })
        patch.wire(combinator, wire.circuit_red, chest, wire.circuit_red)
        local collector = Localise.collector()
        return patch.document({ localiser = collector }), collector
    end

    test("holds no internal names, only placeholders", function()
        local document = documented()
        assert.is_true(Localise.pending(document))
        assert.is_nil(document:find("constant%-combinator"),
            "the entity's internal name is still in the document")
        assert.is_nil(document:find("iron%-plate"),
            "the signal's internal name is still in the document")
    end)

    test("asks for the names the graph actually shows", function()
        local _, collector = documented()
        local asked = {}
        for _, localised in ipairs(collector.strings) do
            asked[#asked + 1] = localised[2][1]
        end
        table.sort(asked)
        assert.same({ "combinatorgraph.on", "entity-name.constant-combinator",
                      "entity-name.wooden-chest", "item-name.iron-plate" }, asked)
    end)

    test("reads back the way it always did once the English is put in", function()
        local document, collector = documented()
        -- nothing translated, so every name falls back to the English it had before
        local rendered = Localise.render(document, {}, collector.fallbacks)
        assert.is_false(Localise.pending(rendered))
        assert.is_not_nil(rendered:find('{constant%-combinator|On|{iron%-plate|1}}'),
            "the fallback document does not read like the plain one:\n" .. rendered)
    end)

    test("reads in the player's language once the answers are in", function()
        local document, collector = documented()
        local translations = {}
        for index, localised in ipairs(collector.strings) do
            translations[index] = ({
                ["entity-name.constant-combinator"] = "Constant combinator",
                ["entity-name.wooden-chest"] = "Wooden chest",
                ["item-name.iron-plate"] = "Iron plate",
                ["combinatorgraph.on"] = "On",
            })[localised[2][1]]
        end
        local rendered = Localise.render(document, translations, collector.fallbacks)
        assert.is_not_nil(rendered:find('{Constant combinator|On|{Iron plate|1}}'),
            "the translated document does not read as expected:\n" .. rendered)
    end)
end)

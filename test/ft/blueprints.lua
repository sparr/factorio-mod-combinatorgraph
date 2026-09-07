--- Two real blueprints somebody published, rather than a handful of entities placed by
--- hand. A hand built circuit only ever contains what the person writing the test already
--- thought of; a real one contains whatever its author happened to build, which is how the
--- pump below came to be noticed.
---
--- Both come from the blueprint book for Nilaus's Factorio Master Class series, published
--- at https://factoriobin.com/post/Y52EhJ74 . They were 1.x blueprints, so each was
--- imported into a blueprint item -- which is what applies the prototype renames, stack
--- inserter to bulk inserter and logistic chest requester to requester chest -- and
--- exported again, and it is those 2.1 strings that are recorded here.
local world = require("test.ft.world")

--- A circuit controlled fluid train station: a train stop, five storage tanks, nine
--- pumps and four arithmetic combinators.
local FLUID_STATION = "0eNrlWUtu2zAQvUrAZUEFokTJn127zrK7wDBoibGJ6leKSmsEPkAP0ov1JB1KtmUnssUpirZpVqJG5OPMmw+H9hNZZY2stCoMmT8RlZRFTeb3T6RW60JkVlaIXJI5MVqowqtNWZEdJapI5VcyZzt6OtVsKzv1UWnTgIQe1nYzvLuTlcH5ysNEU2qxlp4RxaeTyeFuQYksjDJKduq1L9tl0eQrqUGP41aZXItkC3qCuuuN8eBhFanKGhaXhd0LAD0WUbKFZwibpErLpPvIrVbPsAM0duiMHaKxmTM2x2LPnKEjLPTEGTrGQrs7coKFdvfjFO1HZ+gZEtodmflIaHc+GDYh3b3IsPnoHnsMm47uGcOw2YhIdIZNR0SBYth8RBRWhk1IhnAlNiMZwpd9Slosb3+KDR0yt3s22G10jsuCoZOmT8hcpqrJPZnBAq0SryozeXUHH3YYguwTsWryaggiOCo5CBA4GjtF2hpibZ2OmcrHTI2uWxq5uhVpaYz26pilkxFL+XVDp26GYqN3hrRzLHZDf8TMyVUzQ4bUp8+ESwo55sJJSjkxF/a5cNJlXyxR7FmJogS6dqPLbLmSG/GoSm0XJEonjTJLWYhVJlMyN7qRlNSySJemXLYbkfmDyGqQainSpd21kunhUze/fTl+cm713xMgENp50elI7kqR3ng3d+pzo9KbDyITRQJKDZHRp/HZbWCoF97T3LE8RIKReSW1MI2W7rp/BN2HFOvrg9DKbHJpIJSSMl+pQoCmFzvqF0FwwWM96hI+py1SbT88KF0bd/2lSDb28lRLC2OxwA/2fme7zrLlo3PKO1haNqZq0ODDBMWunovPHDfOzG914wTtRv623DgdO0c7PvyXtQ1ViQ7iI0m/wtGj1FuzUcWadBVgT5FvX/JK6Najc/Lj2/cL0TBzrjYnMTt02/axYcWGo+oSi689rDhzZDr8i8WBB1gvxm/Mi+FIcYiHawN/faWBuzYi0z/ahvBorDx3XUfwP5RnHo8Z6+/J54PLxy5KbJiqfz5aF5R8AXXtb+H3gU8jCtfpaEHv7YPChbMdx3Y868bwoHAhsmNosBmFZpbZMUgp349jGlDojoLDGOT9eC+fwHxoENr5UytnrRxOv9NxaOfbOVZEoWa08gD2haRi3Ti0crYASxSkB5jW/xFBSSZWEmgjDxlcFw63CEqApLrlN4qDWcQDPov8YBL4u91PWIFHPw=="

--- A cargo loading station from Mash's book of rails, an LTN-like network built in
--- vanilla 2.0: https://forums.factorio.com/viewtopic.php?t=126084 . Sixteen wired chests,
--- sixteen wired inserters, five arithmetic combinators, a decider, a selector and a
--- wired train stop, among a hundred and eighty entities. Native 2.0, so unlike the two
--- above it needs no migrating.
local LTN_LOADING = "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"

--- The Kovarex enrichment setup: a decider and an arithmetic combinator driving bulk
--- inserters, with beacons, belts, a lamp and two kinds of chest around them.
local KOVAREX = "0eNrNWNtuozAQ/ZXIjyuzAgO5aXcfto/7CVWEHHAbq2CobbKNovz7DpAASUzjRJUWqQ8O2GfOjGfOTNmjdVqyQnKh0XKPeJwLhZbPe6T4q6Bp9UzQjKElipnQkr+UrwwdMOIiYR9o6R2wYeuaUcDpbSPGbYXMkzLWfMv1zslgnTLH753yjadKSQUvM4f4YW9vcFhhBAy55qxxoP6xi0SZrZkEpviCHUZFrmA7LAEcIJzge4jRrllUyJplDRRPevZVwVhyTrfZCPtExMUWDOdy1xzsfoF9pWn8hpZu5ZbxjXdYHeAPX5Ent8l7oyXv3yRPRss9uMk9HC338I6M98ZGftqST1jMEyadOM/WXFBAMGV/342ESxY3bz2oHHBdyzyN1mxDtxyOw5kjaATvkhqo9qb/C3x54VLp6JYAAa+CyprXEv1ClQ7lpS5KPaCjZ8dr1UoVi7ojEBBDPGZtPKjkepMxzeNPQ3JvRDrYi6DcjMK8ioJi1anqKNxs1Usc4kIgCgaRqe2ib+gUmBshNfo/b/1X5RpM1KBXTvuN08SEsLAv5dFVg+e25LnMhRNvmNKGMjh54IIDJpheEyzTN4cLxaRm8hNlcC/zJzDhdv3phSrtqCLl2ozr91CP2QDDRw7JB4+R5K8bjUwW/HMLGhJGFbnUzpqlpki0LWUoFJ2yq4ymqZPSrPikrQ7BhNYR9fqMrEoy5jIuuY6YoOuUQQ5qWTLcPm7L1KpKj1p1Ks/AvVCuH/X7I7RkNIk2tCloDT6rxrgxBJ1U90bEK//ds4QC33lRHXnLt1SyD4cJyWPQH6EdGAtjphQ67YreS5o2+SFyCZeFBmtzeKK0KdFgsEQDixKd2WYCeTgRBq8Fw/2nYOwYkuNsjk1ajZEhnGeZ8LPuYSU0pRa0MXLt8/y+qvSHRGVuAl88Bu5YoRP3PvRBPfSICb2LvWTvJYh1NcCYRXt6URj19i70+6q1djNJd7dfeuPVg7LSBc91Ib1XpkInxDbDw3uaB/Ht51Qyun/Mgrv1/2oiC6zvMvzS6iXhgz3VM/dCMj3Hu62AnlV+zB7TAc9KBubWU+H4cm9hXzjh6D4KuPafNMZH3rP+pDE+7sQ64/8zd5Cxv1C9le3nKfbwDPsrDCuCpzg4rmD+JrCcwWsYwLzVqqFROdd+1sQopSAV8OxPM2xOPDL5Xfs+eYLJSsNoNXlqxq5qzMZoC7JZhyOckkUYkGARumRG3MPhH3ulEA8="

--- Blueprints are built as ghosts, so each ghost is revived to leave the real entities a
--- player would have selected.
---@param patch table
---@param text string
---@return integer placed
local function stamp(patch, text)
    local inventory = game.create_inventory(1)
    inventory[1].set_stack{ name = "blueprint" }
    assert.equals(0, inventory[1].import_stack(text), "the blueprint string did not import")
    inventory[1].build_blueprint{ surface = patch.surface, force = "player",
                                  position = { patch.left + patch.size / 2,
                                               patch.top + patch.size / 2 } }
    inventory.destroy()

    for _, ghost in pairs(patch.surface.find_entities_filtered{
        area = patch.area, name = "entity-ghost" }) do
        ghost.revive{ raise_revive = false }
    end
    for _, entity in pairs(patch.surface.find_entities(patch.area)) do
        -- a module request on a beacon leaves a proxy behind, which is not something
        -- anybody selected and not something the graph has anything to say about
        if entity.type ~= "character" and entity.type ~= "item-request-proxy" then
            patch.entities[#patch.entities + 1] = entity
        end
    end
    return #patch.entities
end

--- The entity named by each node line, in the order the nodes appear
local function drawn(lines)
    local names = {}
    for _, line in ipairs(lines) do
        local label = line:match('label="(.-)" pos=')
        if label then
            names[#names + 1] = label:match("^{([^|}]+)") or label:match("|{([^|}]+)")
        end
    end
    return names
end

local function count(names)
    local counts = {}
    for _, name in ipairs(names) do counts[name] = (counts[name] or 0) + 1 end
    return counts
end

local function edges(lines)
    local n = 0
    for _, line in ipairs(lines) do if line:match(" %-%- ") then n = n + 1 end end
    return n
end

describe("a published fluid train station", function()
    test("draws the wired half of it and leaves the rest out", function()
        local patch = world.arena()
        assert.equals(47, stamp(patch, FLUID_STATION))
        local lines = patch.lines()
        local counts = count(drawn(lines))

        assert.same({ ["arithmetic-combinator"] = 4, ["storage-tank"] = 4, ["pump"] = 4 },
                    counts)
        assert.equals(12, edges(lines))

        -- the train stop, the rails, the poles and the signals are all standing there,
        -- and none of them has a wire on it, so none of them belongs in the graph
        local placed = count((function()
            local names = {}
            for _, entity in ipairs(patch.entities) do names[#names + 1] = entity.name end
            return names
        end)())
        assert.equals(1, placed["train-stop"])
        assert.equals(9, placed["pump"])
        assert.is_nil(counts["train-stop"])
        assert.is_nil(counts["legacy-straight-rail"])
    end)

    --- What a hand built fixture would not have thought to ask. Pumps have no branch of
    --- their own, and used to be drawn as their bare type with nothing else said, even
    --- though every one of these nine is switched by a condition.
    test("shows the condition a pump is switched by", function()
        local patch = world.arena()
        stamp(patch, FLUID_STATION)
        local found
        for _, line in ipairs(patch.lines()) do
            found = found or line:match('label="({pump|pump|[^"]*)"')
        end
        assert.is_not_nil(found, "no pump was drawn with a condition")
        assert.is_not_nil(found:find("signal%-everything"),
            "the pump's condition is missing: " .. tostring(found))
    end)

    test("gives every combinator in it the same operation", function()
        local patch = world.arena()
        stamp(patch, FLUID_STATION)
        local combinators = 0
        for _, line in ipairs(patch.lines()) do
            if line:match("arithmetic%-combinator") then
                combinators = combinators + 1
                assert.is_not_nil(line:find("{signal%-each|%*|%-1}|signal%-each"),
                    "not the operation the blueprint sets: " .. line)
            end
        end
        assert.equals(4, combinators)
    end)
end)

describe("a published Kovarex setup", function()
    test("draws the four wired entities out of the thirty two", function()
        local patch = world.arena()
        assert.equals(32, stamp(patch, KOVAREX))
        local lines = patch.lines()
        local counts = count(drawn(lines))

        assert.same({ ["decider-combinator"] = 1, ["arithmetic-combinator"] = 1,
                      ["bulk-inserter"] = 2 }, counts)
        -- beacons, belts, the lamp and both chests are there and unwired
        assert.equals(4, edges(lines))
    end)

    test("draws the decider wired back to itself exactly once", function()
        local patch = world.arena()
        stamp(patch, KOVAREX)
        local self_wires = 0
        for _, line in ipairs(patch.lines()) do
            local source, target = line:match("^(E%d+):%d+ %-%- (E%d+):%d+")
            if source and source == target then self_wires = self_wires + 1 end
        end
        assert.equals(1, self_wires)
    end)
end)

describe("a published LTN style loading station", function()
    test("draws every wired thing in it and none of the rest", function()
        local patch = world.arena()
        assert.equals(182, stamp(patch, LTN_LOADING))
        local lines = patch.lines()
        local counts = count(drawn(lines))

        assert.same({
            ["train-stop"] = 1,
            ["bulk-inserter"] = 16,
            ["steel-chest"] = 16,
            ["arithmetic-combinator"] = 5,
            ["decider-combinator"] = 1,
            ["selector-combinator"] = 1,
            ["electric-pole"] = 6,
        }, counts)

        -- belts, rails, splitters and the sixteen inserters on the far side of the
        -- station carry no wire, and none of them is in the graph
        assert.is_nil(counts["fast-transport-belt"])
        assert.is_nil(counts["straight-rail"])
        assert.is_nil(counts["fast-splitter"])
    end)

    test("says what the train stop is doing", function()
        local patch = world.arena()
        stamp(patch, LTN_LOADING)
        local label
        for _, line in ipairs(patch.lines()) do
            label = label or line:match('label="({train%-stop|[^"]*)"')
        end
        assert.is_not_nil(label, "the train stop was not drawn")
        assert.is_not_nil(label:find("Send to train"), label)
        assert.is_not_nil(label:find("Read trains count"), label)
        -- and the condition it is enabled by
        assert.is_not_nil(label:find("|{signal%-P|"), label)
    end)

    --- A selector combinator is new in 2.0 and had no handling at all: it was drawn as
    --- its own name twice over, with none of its settings and, because it was not counted
    --- as two sided, with its input and output edges pointing at a port it did not have.
    test("says what the selector combinator is set to", function()
        local patch = world.arena()
        stamp(patch, LTN_LOADING)
        local label
        for _, line in ipairs(patch.lines()) do
            label = label or line:match('label="(<1>[^"]*selector%-combinator[^"]*)"')
        end
        assert.is_not_nil(label, "the selector combinator was not drawn with two sides")
        assert.is_not_nil(label:find("Stack size"), label)
    end)

    --- The other half of being two sided: its edges have to land on the west and east
    --- ports the label declares, not on the single port a one sided entity has.
    test("wires the selector combinator to its own two sides", function()
        local patch = world.arena()
        stamp(patch, LTN_LOADING)
        local lines = patch.lines()
        local id
        for _, line in ipairs(lines) do
            id = id or line:match("^(E%d+) %[shape=record label=\"<1>[^\"]*selector%-")
        end
        assert.is_not_nil(id, "no selector combinator node")

        local edges_seen = 0
        for _, line in ipairs(lines) do
            local source, source_port, target, target_port =
                line:match("^(E%d+):(%d+) %-%- (E%d+):(%d+)")
            if source == id or target == id then
                edges_seen = edges_seen + 1
                local port = line:match(source == id and "tailport=(%a)" or "headport=(%a)")
                assert.is_true(port == "w" or port == "e",
                    "the selector combinator was wired to a one sided port: " .. line)
            end
        end
        assert.is_true(edges_seen > 0, "the selector combinator has no edges")
    end)

    test("takes a wire on a power pole seriously", function()
        local patch = world.arena()
        stamp(patch, LTN_LOADING)
        -- the poles carry the station's circuit network as well as its power, and the
        -- copper half of that must not appear
        local drawn_poles, copper = 0, 0
        for _, line in ipairs(patch.lines()) do
            if line:match('label="{electric%-pole') then drawn_poles = drawn_poles + 1 end
            if line:match("color=copper") then copper = copper + 1 end
        end
        assert.equals(6, drawn_poles)
        assert.equals(0, copper)
    end)
end)

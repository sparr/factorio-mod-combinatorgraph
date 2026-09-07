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

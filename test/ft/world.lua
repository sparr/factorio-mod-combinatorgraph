--- A patch of nauvis to build a circuit on, and the helpers every fixture needs.
---
--- Each test claims its own 30x30 patch so that nothing it leaves behind can reach the
--- next one, and so that the positions in the graph document are its own.
-- require has to happen while control.lua is being parsed, not inside a function
local Graph = require("lib.graph")

local world = {}

local PATCH = 30
local COLUMNS = 8

local prepared = false
local patch_index = -1

local function prepare()
    if prepared then return end
    local surface = game.surfaces["nauvis"]
    local span = COLUMNS * PATCH
    surface.request_to_generate_chunks({ x = span / 2, y = span / 2 },
                                       math.ceil(span / 32) + 1)
    surface.force_generate_chunk_requests()
    world.surface = surface
    prepared = true
end

--- A patch big enough for a published blueprint, which is far larger than anything the
--- other fixtures build. Laid out well clear of the ordinary grid rather than inside it,
--- so that widening one of these can never reach into a neighbour.
local ARENA = 120
local ARENA_TOP = 2000
local arena_index = -1

---@param size integer? defaults to 120 tiles square
function world.arena(size)
    prepare()
    size = size or ARENA
    arena_index = arena_index + 1
    local left = arena_index * size
    local top = ARENA_TOP
    local surface = world.surface
    surface.request_to_generate_chunks({ x = left + size / 2, y = top + size / 2 },
                                       math.ceil(size / 32) + 1)
    surface.force_generate_chunk_requests()
    return world.claim(left, top, size)
end

--- Claim the next patch. `place` puts an entity down and remembers it, so that the
--- fixture can hand the whole lot to the mod the way a selection would.
function world.patch()
    prepare()
    patch_index = patch_index + 1
    return world.claim((patch_index % COLUMNS) * PATCH,
                       math.floor(patch_index / COLUMNS) * PATCH, PATCH)
end

---@param left integer
---@param top integer
---@param size integer
function world.claim(left, top, size)
    local surface = world.surface

    local area = { { left, top }, { left + size, top + size } }
    for _, entity in pairs(surface.find_entities(area)) do
        if entity.valid and entity.type ~= "character" then entity.destroy() end
    end

    local patch = { surface = surface, left = left, top = top, size = size,
                    area = area, entities = {} }

    --- x and y are relative to the patch, so a fixture never says where it really is
    function patch.place(name, x, y)
        local entity = surface.create_entity{
            name = name, position = { left + x, top + y }, force = "player" }
        assert(entity, "could not place " .. name)
        patch.entities[#patch.entities + 1] = entity
        return entity
    end

    function patch.wire(a, id_a, b, id_b)
        a.get_wire_connector(id_a, true).connect_to(b.get_wire_connector(id_b, true), false)
    end

    --- The document the mod would have written for everything placed in this patch
    function patch.document(options)
        return Graph.Document(patch.entities, options)
    end

    --- The document's lines, with the preamble and the closing brace taken off, and every
    --- unit number replaced by the order it first appears. Unit numbers are a global
    --- counter shared with the rest of the run, so an assertion naming real ones would
    --- depend on how many fixtures ran first.
    function patch.lines(options)
        local lines = {}
        for line in patch.document(options):gmatch("[^\n]+") do lines[#lines + 1] = line end
        table.remove(lines, 1)
        table.remove(lines, 1)
        table.remove(lines)

        local seen, count = {}, 0
        for _, entity in ipairs(patch.entities) do
            if entity.valid and entity.unit_number and not seen[entity.unit_number] then
                count = count + 1
                seen[entity.unit_number] = "E" .. count
            end
        end
        --- Only the unit numbers are renamed, and only where a unit number can appear.
        --- A blanket pass over every number would renumber the ports and the positions
        --- too, and a position can easily be the same number as somebody's unit.
        local function rename(unit_number)
            return seen[tonumber(unit_number)] or unit_number
        end
        for index, line in ipairs(lines) do
            line = line:gsub("^(%d+) %[", function(node) return rename(node) .. " [" end)
            line = line:gsub("^(%d+):(%d+) %-%- (%d+):(%d+)",
                function(source, source_port, target, target_port)
                    return rename(source) .. ":" .. source_port .. " -- " ..
                           rename(target) .. ":" .. target_port
                end)
            lines[index] = line
        end
        return lines
    end

    return patch
end

return world

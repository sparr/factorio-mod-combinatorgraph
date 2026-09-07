--- Where each entity's icon lives on disk, recorded now so that the control stage can
--- read it. Nothing at runtime can say where an icon file is: the prototype exposes how
--- to draw an icon, not the file behind it. The data stage can see it, and a mod-data
--- prototype is the way to carry something from here to there.
---
--- Paths are stored relative to the game's data directory -- base/graphics/icons/pump.png
--- rather than __base__/graphics/icons/pump.png -- so that whoever renders the graph can
--- point graphviz at that directory and have every path resolve. A mod's icons resolve
--- the same way against the mods directory.
local paths, sizes = {}, {}

---@param path string a mod path such as __base__/graphics/icons/pump.png
---@return string? path relative to whichever directory that mod lives in
local function relative(path)
    if type(path) ~= "string" then return nil end
    local mod, rest = path:match("^__([^_]+.-)__/(.+)$")
    if not mod then return nil end
    return mod .. "/" .. rest
end

--- The first layer of a layered icon is the one that reads as the entity
---@return string? path, number? size
local function icon_of(prototype)
    if prototype.icon then return relative(prototype.icon), prototype.icon_size end
    if type(prototype.icons) == "table" and type(prototype.icons[1]) == "table"
        and prototype.icons[1].icon then
        return relative(prototype.icons[1].icon),
               prototype.icons[1].icon_size or prototype.icon_size
    end
    return nil
end

for _, prototypes in pairs(data.raw) do
    for name, prototype in pairs(prototypes) do
        if type(prototype) == "table" and prototype.type and not paths[name] then
            local path, size = icon_of(prototype)
            if path then
                paths[name] = path
                -- Factorio's icon files carry their mipmaps beside the icon: a 64 pixel
                -- icon lives in a 120 pixel wide file. Graphviz scales an image to fit
                -- but will not crop one, so the size is recorded here for whoever wants
                -- to cut the mipmaps off before rendering. 2.0 made icon_size optional
                -- and most prototypes leave it out, taking the default of 64.
                sizes[name] = size or 64
            end
        end
    end
end

data:extend{ {
    type = "mod-data",
    name = "combinatorgraph-icons",
    data = { paths = paths, sizes = sizes },
} }

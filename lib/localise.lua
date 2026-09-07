--- Collecting the names a document needs translated, and putting them back afterwards.
---
--- Translation is asynchronous: a request is answered on a later tick, through
--- on_string_translated, and only for a player who is connected. So the document cannot
--- simply be built out of localised strings. Instead it is built as ordinary text with a
--- placeholder where each name goes, and the placeholders are filled in once the answers
--- arrive.
local Localise = {}

--- Placeholders are wrapped in a byte that cannot occur in a prototype name or in
--- anything graphviz cares about, so nothing in the document can be mistaken for one.
local MARK = "\1"

--- A stable key for a localised string, so the same name is only ever requested once.
--- Two graphs of the same base tend to name the same handful of signals over and over.
---@param localised LocalisedString
---@return string
local function key_of(localised)
    if type(localised) ~= "table" then return tostring(localised) end
    local parts = {}
    for index, part in ipairs(localised) do parts[index] = key_of(part) end
    return "{" .. table.concat(parts, "\2") .. "}"
end

--- @return table collector `add` takes a localised string and gives back a placeholder
function Localise.collector()
    local self = { strings = {}, seen = {}, fallbacks = {} }

    --- The plain English an alternatives list ends with, kept so that a name the game
    --- declines to translate still reads as it did before any of this existed.
    local function fallback_of(localised)
        if type(localised) ~= "table" then return tostring(localised) end
        local last = localised[#localised]
        return type(last) == "string" and last or nil
    end

    ---@param localised LocalisedString
    ---@return string placeholder
    function self.add(localised)
        local key = key_of(localised)
        local index = self.seen[key]
        if not index then
            self.strings[#self.strings + 1] = localised
            index = #self.strings
            self.seen[key] = index
            self.fallbacks[index] = fallback_of(localised)
        end
        return MARK .. index .. MARK
    end

    return self
end

--- Put the translations where the placeholders are. Anything still missing is left as it
--- stands rather than blanked, so a half answered document is still readable.
---@param document string
---@param translations table<integer, string>
---@param fallbacks table<integer, string>?
---@return string
function Localise.render(document, translations, fallbacks)
    fallbacks = fallbacks or {}
    return (document:gsub(MARK .. "(%d+)" .. MARK, function(index)
        index = tonumber(index)
        return translations[index] or fallbacks[index] or (MARK .. index .. MARK)
    end))
end

--- Is there anything left to fill in?
---@param document string
function Localise.pending(document)
    return document:find(MARK .. "%d+" .. MARK) ~= nil
end

--- The locale section a signal's name lives in
local SIGNAL_SECTIONS = {
    item = "item-name",
    fluid = "fluid-name",
    virtual = "virtual-signal-name",
    entity = "entity-name",
    recipe = "recipe-name",
    quality = "quality-name",
    ["space-location"] = "space-location-name",
    ["asteroid-chunk"] = "asteroid-chunk-name",
}

--- A signal's name, as the game would print it, falling back to the internal name.
--- The "?" form takes the first alternative that resolves, so a signal whose section
--- guess is wrong still reads as it does today rather than as an error.
---@param signal SignalID
---@return LocalisedString
function Localise.signal(signal)
    local section = SIGNAL_SECTIONS[signal.type or "item"] or "item-name"
    return { "?", { section .. "." .. signal.name }, signal.name }
end

---@param entity_name string
---@return LocalisedString
function Localise.entity(entity_name)
    return { "?", { "entity-name." .. entity_name }, entity_name }
end

return Localise

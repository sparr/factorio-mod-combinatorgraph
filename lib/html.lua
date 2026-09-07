--- Turning a record label into an HTML-like one, so that it can carry a picture.
---
--- Graphviz's record shape cannot hold an image; its HTML-like labels can, in a table
--- cell. Rather than build every label twice, the record label is parsed back into the
--- rows and columns it describes and written out again as a table. The grammar is a
--- closed one -- this mod wrote the label in the first place -- so the parser only has to
--- handle what lib/labels emits: fields separated by |, groups in {}, ports in <>, and
--- backslash escaped punctuation.
local Html = {}

--- Record escapes come off, then the three characters HTML cares about go on
---@param text string
---@return string
local function escaped(text)
    local out = text:gsub("\\(.)", "%1")
    out = out:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    return (out:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- @return table node { items = { {text=, port=} | node } }, integer position
local function parse(text, position)
    local items = {}
    local buffer, port, filled = {}, nil, false

    local function take()
        if #buffer > 0 or port then
            items[#items + 1] = { text = escaped(table.concat(buffer)), port = port }
        elseif not filled then
            items[#items + 1] = { text = "" }
        end
        buffer, port, filled = {}, nil, false
    end

    while position <= #text do
        local character = text:sub(position, position)
        if character == "\\" then
            buffer[#buffer + 1] = text:sub(position, position + 1)
            position = position + 2
        elseif character == "{" then
            local child
            child, position = parse(text, position + 1)
            items[#items + 1] = child
            filled = true
        elseif character == "}" then
            take()
            return { items = items }, position + 1
        elseif character == "|" then
            take()
            position = position + 1
        elseif character == "<" then
            local name, after = text:match("^<([^>]*)>()", position)
            if name then
                port, position = name, after
            else
                buffer[#buffer + 1] = character
                position = position + 1
            end
        else
            buffer[#buffer + 1] = character
            position = position + 1
        end
    end
    take()
    return { items = items }, position
end

local TABLE = '<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="3">'

--- `state.icon` is dropped into the first piece of text there is that is not a port. Every
--- label this mod writes begins with the entity's name, but a combinator's begins with the
--- arrow marking its input side, and the picture does not belong there.
--- A cell holds text, a table or a picture -- never a picture and text together, which
--- graphviz rejects outright -- so the picture goes in a cell of its own beside the name,
--- and every other row spans both columns to line up with it.
local function emit(node, horizontal, state)
    local cells = {}
    local widened = false
    for _, item in ipairs(node.items) do
        local cell = { port = item.port }
        if item.items then
            cell.content = emit(item, not horizontal, state)
        elseif state.icon and item.text ~= "" and not item.port and state.skip == 0 then
            cell.image = state.icon
            cell.content = item.text
            state.icon = nil
            widened = true
        else
            if state.icon and item.text ~= "" and not item.port and state.skip > 0 then
                state.skip = state.skip - 1
            end
            cell.content = item.text
        end
        cells[#cells + 1] = cell
    end

    local function image_cell(cell)
        return '<TD><IMG SRC="' .. cell.image .. '"/></TD>'
    end
    local function text_cell(cell, span)
        return "<TD" .. (cell.port and (' PORT="' .. cell.port .. '"') or "") ..
               (span or "") .. ">" .. cell.content .. "</TD>"
    end

    local out = { TABLE }
    if horizontal then
        out[#out + 1] = "<TR>"
        for _, cell in ipairs(cells) do
            if cell.image then out[#out + 1] = image_cell(cell) end
            out[#out + 1] = text_cell(cell)
        end
        out[#out + 1] = "</TR>"
    else
        for _, cell in ipairs(cells) do
            out[#out + 1] = "<TR>"
            if cell.image then
                out[#out + 1] = image_cell(cell)
                out[#out + 1] = text_cell(cell)
            else
                out[#out + 1] = text_cell(cell, widened and ' COLSPAN="2"' or nil)
            end
            out[#out + 1] = "</TR>"
        end
    end
    out[#out + 1] = "</TABLE>"
    return table.concat(out)
end

--- @param record string a record label, as lib/labels writes them
--- @param icon string? a path graphviz can find, put beside the entity's name
--- @param skip integer? rows to pass over first. A ghost is drawn with a row saying so
---   above its name, and the picture belongs beside the name rather than beside that.
--- @return string an HTML-like label, without the angle brackets graphviz wants around it
function Html.from_record(record, icon, skip)
    local tree = parse(record, 1)
    -- a record is laid out left to right until a { turns it on its side
    return emit(tree, true, { icon = icon, skip = skip or 0 })
end

return Html

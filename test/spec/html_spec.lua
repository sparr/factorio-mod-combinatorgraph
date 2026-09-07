local Html = require("lib.html")

describe("turning a record label into an HTML one", function()
    it("lines the other rows up under the picture", function()
        local html = Html.from_record('{pump|{signal-A|\\>|0}}', "pump.png")
        assert.is_not_nil(html:find('COLSPAN="2"'), html)
    end)

    it("stacks a simple group into rows", function()
        local html = Html.from_record('{pump|{signal-A|\\>|0}}')
        -- the outer group becomes rows, the inner one becomes a row of cells
        assert.is_not_nil(html:find("<TR><TD>pump</TD></TR>"), html)
        assert.is_not_nil(html:find("<TD>signal%-A</TD>"), html)
        assert.is_not_nil(html:find("<TD>&gt;</TD>"), html)
    end)

    it("keeps the ports a combinator's edges land on", function()
        local html = Html.from_record('<1>\\>|{decider-combinator}|<2>\\>')
        assert.is_not_nil(html:find('<TD PORT="1">&gt;</TD>'), html)
        assert.is_not_nil(html:find('<TD PORT="2">&gt;</TD>'), html)
    end)

    it("escapes what HTML would otherwise read as markup", function()
        local html = Html.from_record('{a|\\<|\\>|&}')
        assert.is_not_nil(html:find("&lt;"), html)
        assert.is_not_nil(html:find("&gt;"), html)
        assert.is_not_nil(html:find("&amp;"), html)
        assert.is_nil(html:find("<TD><</TD>"), html)
    end)

    it("puts the image beside the name and nowhere else", function()
        local html = Html.from_record('{pump|{signal-A|\\>|0}}',
                                      "base/graphics/icons/pump.png")
        local _, images = html:gsub("<IMG", "")
        assert.equals(1, images)
        -- graphviz will not take a picture and text in one cell, so they are neighbours
        assert.is_not_nil(
            html:find('<TD><IMG SRC="base/graphics/icons/pump.png"/></TD><TD>pump</TD>'),
            html)
    end)

    it("leaves the label alone when there is no image for it", function()
        local html = Html.from_record('{pump}')
        assert.is_nil(html:find("<IMG"))
        assert.is_not_nil(html:find("<TD>pump</TD>"), html)
    end)

    -- the name is the first text there is, even on a combinator whose first cell is a port
    it("finds the name past a combinator's port cell", function()
        local html = Html.from_record('<1>\\>|{arithmetic-combinator|x}|<2>\\>', "a.png")
        assert.is_not_nil(
            html:find('<TD><IMG SRC="a.png"/></TD><TD>arithmetic%-combinator</TD>'), html)
        assert.is_nil(html:find('PORT="1"><IMG'), html)
    end)

    it("nests a group inside a group", function()
        local html = Html.from_record('{a|{b|{c|d}}}')
        -- the label itself, then one for each group inside it
        local _, tables = html:gsub("<TABLE", "")
        assert.equals(4, tables)
    end)
end)

describe("a ghost's picture", function()
    -- a ghost is drawn with a row saying so above its name, and the picture belongs
    -- beside the name rather than beside the word Ghost
    it("goes beside the name, not the row above it", function()
        local html = Html.from_record('{Ghost|small-lamp|{signal-A|\\>|0}}',
                                      "lamp.png", 1)
        assert.is_not_nil(
            html:find('<TD><IMG SRC="lamp.png"/></TD><TD>small%-lamp</TD>'), html)
        assert.is_nil(html:find('<IMG SRC="lamp.png"/></TD><TD>Ghost'), html)
    end)
end)

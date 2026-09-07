local Graph = require("lib.graph")

local function Write(event)
  if event.item == "combinatorgraph-tool" then
    -- 2.0 moved write_file off game and onto helpers
    helpers.write_file("combinatorgraph.gv", Graph.Document(event.entities))
  end
end

script.on_event(defines.events.on_player_selected_area, Write)
script.on_event(defines.events.on_player_alt_selected_area, Write)

--- cg-tests is never published, so this can never fire on a player's machine -- which
--- matters, because info.json keeps test/ out of the package.
if script.active_mods["factorio-test"] and script.active_mods["cg-tests"] then
  require("__factorio-test__/init")({
    "test.ft.wires",
    "test.ft.entities",
  }, {
    load_luassert = true,
    game_speed = 100,
  })
end

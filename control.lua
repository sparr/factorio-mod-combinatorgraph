local Graph = require("lib.graph")
local Localise = require("lib.localise")

local FILE = "combinatorgraph.gv"

--- What the player who swung the tool wants to see
---@param player_index uint
local function OptionsFor(player_index)
  local player_settings = settings.get_player_settings(player_index)
  local options = {
    ineffective = player_settings["combinatorgraph-show-ineffective"].value,
  }
  if player_settings["combinatorgraph-localise"].value then
    options.localiser = Localise.collector()
  end
  return options
end

local function Write(event)
  if event.item ~= "combinatorgraph-tool" then return end
  local options = OptionsFor(event.player_index)
  local document = Graph.Document(event.entities, options)

  -- nothing to look up: the document is finished as it stands
  if not options.localiser or #options.localiser.strings == 0 then
    helpers.write_file(FILE, document)
    return
  end

  -- Translation is answered on a later tick, and only for a player who is connected, so
  -- the document waits here with holes in it until the answers arrive.
  local player = game.get_player(event.player_index)
  if not player then return end
  local job = {
    document = document,
    fallbacks = options.localiser.fallbacks,
    translations = {},
    wanted = {},
    outstanding = 0,
  }
  for index, id in ipairs(player.request_translations(options.localiser.strings)) do
    job.wanted[id] = index
    job.outstanding = job.outstanding + 1
  end
  storage.waiting = storage.waiting or {}
  storage.waiting[event.player_index] = job
end

script.on_event(defines.events.on_player_selected_area, Write)
script.on_event(defines.events.on_player_alt_selected_area, Write)

script.on_event(defines.events.on_string_translated, function(event)
  local job = storage.waiting and storage.waiting[event.player_index]
  if not job then return end
  local index = job.wanted[event.id]
  if not index then return end

  job.wanted[event.id] = nil
  job.outstanding = job.outstanding - 1
  -- a name the game declines to translate keeps the English it always had, which the
  -- collector held on to for exactly this
  if event.translated then job.translations[index] = event.result end

  if job.outstanding == 0 then
    helpers.write_file(FILE,
      Localise.render(job.document, job.translations, job.fallbacks))
    storage.waiting[event.player_index] = nil
  end
end)

--- cg-tests is never published, so this can never fire on a player's machine -- which
--- matters, because info.json keeps test/ out of the package.
if script.active_mods["factorio-test"] and script.active_mods["cg-tests"] then
  require("__factorio-test__/init")({
    "test.ft.wires",
    "test.ft.entities",
    "test.ft.localise",
    "test.ft.blueprints",
    "test.ft.showcase",
  }, {
    load_luassert = true,
    game_speed = 100,
  })
end

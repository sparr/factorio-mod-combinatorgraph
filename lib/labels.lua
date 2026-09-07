--- Turning one entity's control behaviour into the text that goes inside its graph node.
---
--- Everything here takes a control behaviour, or an entity, and returns a graphviz record
--- label. Nothing here touches the world, which is what lets the unit tier drive it with
--- plain tables.
---
--- Capitalised because almost every function below keeps its own local `labels` list, and
--- a lowercase module would be shadowed by it.
local Localise = require("lib.localise")

--- The English the game uses for each selector combinator operation, kept as the fallback
--- for the locale keys above them
local SELECTOR_OPERATIONS = {
  ["select"] = "Select input",
  ["count"] = "Count inputs",
  ["random"] = "Random input",
  ["stack-size"] = "Stack size",
  ["rocket-capacity"] = "Rocket capacity",
  ["quality-filter"] = "Quality filter",
  ["quality-transfer"] = "Quality transfer",
  ["time"] = "Time",
}

local MODES = "gui-control-behavior-modes."
local GUIS = "gui-control-behavior-modes-guis."
local CG = "combinatorgraph."

local Labels = {}

--- What an empty slot is drawn as once the player has asked to see the settings that do
--- nothing. Issue #2: a condition with no signal is always false and an output with no
--- signal emits nothing, so by default neither is drawn -- which can be exactly the thing
--- somebody opened the graph to find.
Labels.NONE = "none"

---@param options table? { ineffective: boolean?, localiser: table? }
local function ineffective(options)
    return options ~= nil and options.ineffective == true
end

--- One of this mod's words, in the player's language when they have asked for it.
---
--- Almost everything the graph says has a key in the game's own locale already, under
--- gui-control-behavior-modes, so the graph reads the way the entity's own window does.
--- The handful with no equivalent live in this mod's locale instead. Either way the
--- English that used to be hard coded stays as the "?" fallback, so a key that turns out
--- to be wrong prints exactly what it printed before rather than an error.
---@param options table?
---@param key string
---@param english string
---@return string
local function word(options, key, english)
    if options == nil or options.localiser == nil then return english end
    return options.localiser.add({ "?", { key }, english })
end

--- A ghost stands in for the entity it will become, and carries everything that entity
--- was set up with: the same control behaviour, readable, and its own wire connectors. So
--- it is drawn as the thing it is going to be, with a row at the top saying it is not
--- there yet.
---@param ent LuaEntity
---@return string name, string entity_type, boolean is_ghost
local function identity(ent)
    if ent.name == "entity-ghost" then
        return ent.ghost_name, ent.ghost_type, true
    end
    return ent.name, ent.type, false
end

--- A ghost's own prototype is the ghost's, not the one it stands for
local function prototype_of(ent)
    if ent.name == "entity-ghost" then return ent.ghost_prototype end
    return ent.prototype
end

--- Fields that only a built entity has. A ghost knows what it will be configured as, but
--- not what it is doing, so asking it is an error rather than a nil.
---@return any?
local function built_only(ent, field)
    if ent.name == "entity-ghost" then return nil end
    local ok, value = pcall(function() return ent[field] end)
    if ok then return value end
    return nil
end

--- A signal's name, in the player's language when they have asked for it
---@param options table?
---@param signal SignalID
---@return string
local function signal_name(options, signal)
    if options == nil or options.localiser == nil then return signal.name end
    return options.localiser.add(Localise.signal(signal))
end

function Labels.SignalLabel(signal, options)
  -- TODO: disambiguate signals with the same name but different types
  if not (signal and signal.name) then return nil end
  return signal_name(options, signal)
end

-- 2.0 replaced the constant combinator's flat parameter list with logistic sections,
-- each holding filters whose signal is a value and whose count is a minimum. An empty
-- combinator has no sections at all, which is what used to be handed to pairs as nil.
function Labels.CCDataLabels(control, options)
  local labels = {}
  for _,section in pairs(control.sections or {}) do
    for _,filter in pairs(section.filters or {}) do
      if filter.value and filter.value.name then
        labels[#labels+1] = string.format("{%s|%d}",
          Labels.SignalLabel(filter.value, options),
          filter.min or 0
        )
      elseif ineffective(options) then
        labels[#labels+1] = string.format("{%s|%d}", Labels.NONE, filter.min or 0)
      end
    end
  end
  return labels
end

function Labels.ConditionLabel(condition, options)
  local first = Labels.SignalLabel(condition.first_signal, options)
  -- a constant of zero is a perfectly good operand, so this asks for nil rather than truth
  local second = condition.second_signal and Labels.SignalLabel(condition.second_signal, options)
    or condition.constant
  if first and second ~= nil then
    return string.format('{%s|\\%s|%s}', first, condition.comparator, second)
  end
  if ineffective(options) then
    return string.format('{%s|\\%s|%s}',
      first or Labels.NONE,
      condition.comparator or "?",
      second == nil and Labels.NONE or second
    )
  end
  return nil
end

function Labels.InserterLabel(control, options)
  local labels = {}
  -- the single mode_of_operation became two independent switches
  if control.circuit_enable_disable then
    local label = Labels.ConditionLabel(control.circuit_condition, options)
    if label then
      labels[#labels+1] = label
    end
  end
  if control.circuit_set_filters then
    labels[#labels+1] = word(options, MODES .. "set-filters", "Set Filters") ..
      " (" .. control.entity.inserter_filter_mode .. ")"
  end

  if control.circuit_read_hand_contents then
    if control.circuit_hand_read_mode == defines.control_behavior.inserter.hand_read_mode.pulse then
      labels[#labels+1] = word(options, GUIS .. "pulse-mode", "Pulse")
    elseif control.circuit_hand_read_mode == defines.control_behavior.inserter.hand_read_mode.hold then
      labels[#labels+1] = word(options, GUIS .. "hold-mode", "Hold")
    end
  end

  if control.circuit_set_stack_size and Labels.SignalLabel(control.circuit_stack_control_signal, options) then
    labels[#labels+1] = "{Set Stack Size|" .. Labels.SignalLabel(control.circuit_stack_control_signal, options) .. "}"
  end

  return table.concat(labels, '|')
end

function Labels.RoboportLabel(control, options)
  local labels = {}
  if control.read_logistics then
    labels[#labels+1] = word(options, MODES .. "read-logistic-network-contents",
      "Read Logistics")
  end
  if control.read_robot_stats then
    if Labels.SignalLabel(control.available_logistic_output_signal, options) then
      labels[#labels+1] = '{' .. word(options, CG .. "avail-log", "Avail Log") .. '|' .. Labels.SignalLabel(control.available_logistic_output_signal, options) .. '}'
    end
    if Labels.SignalLabel(control.total_logistic_output_signal, options) then
      labels[#labels+1] = '{' .. word(options, CG .. "total-log", "Total Log") .. '|' .. Labels.SignalLabel(control.total_logistic_output_signal, options) .. '}'
    end
    if Labels.SignalLabel(control.available_construction_output_signal, options) then
      labels[#labels+1] = '{' .. word(options, CG .. "avail-con", "Avail Con") .. '|' .. Labels.SignalLabel(control.available_construction_output_signal, options) .. '}'
    end
    if Labels.SignalLabel(control.total_construction_output_signal, options) then
      labels[#labels+1] = '{' .. word(options, CG .. "total-con", "Total Con") .. '|' .. Labels.SignalLabel(control.total_construction_output_signal, options) .. '}'
    end
  end
  return table.concat(labels, '|')
end

function Labels.RailSignalLabel(control, options)
  local labels = {}
  if control.read_signal then
    if Labels.SignalLabel(control.red_signal, options) then
      labels[#labels+1] = '{' .. word(options, CG .. "red-signal", "Red Signal") .. '|' .. Labels.SignalLabel(control.red_signal, options) .. '}'
    end
    if Labels.SignalLabel(control.orange_signal, options) then
      labels[#labels+1] = '{' .. word(options, CG .. "orange-signal", "Orange Signal") .. '|' .. Labels.SignalLabel(control.orange_signal, options) .. '}'
    end
    if Labels.SignalLabel(control.green_signal, options) then
      labels[#labels+1] = '{' .. word(options, CG .. "green-signal", "Green Signal") .. '|' .. Labels.SignalLabel(control.green_signal, options) .. '}'
    end
  end
  if control.close_signal and Labels.ConditionLabel(control.circuit_condition, options) then
    labels[#labels+1] = Labels.ConditionLabel(control.circuit_condition, options)
  end
  return table.concat(labels, '|')
end

function Labels.RailChainSignalLabel(control, options)
  local labels = {}
  if Labels.SignalLabel(control.red_signal, options) then
    labels[#labels+1] = '{' .. word(options, CG .. "red-signal", "Red Signal") .. '|' .. Labels.SignalLabel(control.red_signal, options) .. '}'
  end
  if Labels.SignalLabel(control.orange_signal, options) then
    labels[#labels+1] = '{' .. word(options, CG .. "orange-signal", "Orange Signal") .. '|' .. Labels.SignalLabel(control.orange_signal, options) .. '}'
  end
  if Labels.SignalLabel(control.green_signal, options) then
    labels[#labels+1] = '{' .. word(options, CG .. "green-signal", "Green Signal") .. '|' .. Labels.SignalLabel(control.green_signal, options) .. '}'
  end
  if Labels.SignalLabel(control.blue_signal, options) then
    labels[#labels+1] = '{' .. word(options, CG .. "blue-signal", "Blue Signal") .. '|' .. Labels.SignalLabel(control.blue_signal, options) .. '}'
  end
  return table.concat(labels, '|')
end

-- likewise here: one mode became two switches, and both can be on at once
function Labels.LogisticContainerLabel(control, options)
  local labels = {}
  if control.read_contents then
    labels[#labels+1] = word(options, MODES .. "read-contents", "Read Contents")
  end
  if control.set_requests then
    labels[#labels+1] = word(options, MODES .. "set-requests", "Set Requests")
  end
  return table.concat(labels, '|')
end

function Labels.EntityLabel(ent, options)
  local name, entity_type, is_ghost = identity(ent)
  local control = ent.get_or_create_control_behavior()
  local function named()
    return options and options.localiser
      and options.localiser.add(Localise.entity(name)) or name
  end
  local function ghost_row()
    return word(options, "entity-status.ghost", "Ghost")
  end
  --TODO: remote.call for mods to register custom output for modded entities's configs
  -- A power pole, a wall, anything with nothing to configure. Its name is enough to say
  -- what it is, and the type used to be printed above it: electric-pole over
  -- medium-electric-pole, which said nothing the row below it did not.
  if not control then
    if is_ghost then
      return string.format('{%s|%s}', ghost_row(), named())
    end
    return string.format('{%s}', named())
  end
  local labels = {}
  if is_ghost then labels[#labels+1] = ghost_row() end
  labels[#labels+1] = named()
  if control.type == defines.control_behavior.type.container or
    control.type == defines.control_behavior.type.single_fluid_box then
      -- nothing special
  elseif control.type == defines.control_behavior.type.generic_on_off then
    if control.circuit_enable_disable then
      local label = Labels.ConditionLabel(control.circuit_condition, options)
      if label then
        labels[#labels+1] = label
      end
    end
    if control.connect_to_logistic_network then
      local label = Labels.ConditionLabel(control.logistic_condition, options)
      if label then
        labels[#labels+1] = label
      end
    end
  elseif control.type == defines.control_behavior.type.inserter then
    local label = Labels.InserterLabel(control, options)
    if #label > 0 then
      labels[#labels+1] = label
    end
  elseif control.type == defines.control_behavior.type.lamp then
    if control.use_colors then
      labels[#labels+1] = word(options, MODES .. "use-colors", "Use Colors")
    end
    local label = Labels.ConditionLabel(control.circuit_condition, options)
    if label then
      labels[#labels+1] = label
    end
  elseif control.type == defines.control_behavior.type.logistic_container then
    labels[#labels+1] = Labels.LogisticContainerLabel(control, options)
  elseif control.type == defines.control_behavior.type.roboport then
    labels[#labels+1] = Labels.RoboportLabel(control, options)
  elseif control.type == defines.control_behavior.type.train_stop then
    if control.send_to_train then
      labels[#labels+1] = word(options, MODES .. "send-to-train", "Send to train")
    end
    if control.read_from_train then
      labels[#labels+1] = word(options, MODES .. "read-train-contents", "Read from train")
    end
    if control.read_stopped_train and Labels.SignalLabel(control.stopped_train_signal, options) then
      labels[#labels+1] = '{' .. word(options, MODES .. "read-stopped-train", "Read stopped train") .. '|' .. Labels.SignalLabel(control.stopped_train_signal, options) .. '}'
    end
    if control.set_trains_limit and Labels.SignalLabel(control.trains_limit_signal, options) then
      labels[#labels+1] = '{' .. word(options, MODES .. "set-trains-limit", "Set trains limit") .. '|' .. Labels.SignalLabel(control.trains_limit_signal, options) .. '}'
    end
    if control.read_trains_count and Labels.SignalLabel(control.trains_count_signal, options) then
      labels[#labels+1] = '{' .. word(options, MODES .. "read-trains-count", "Read trains count") .. '|' .. Labels.SignalLabel(control.trains_count_signal, options) .. '}'
    end
    if control.circuit_enable_disable then
      local label = Labels.ConditionLabel(control.circuit_condition, options)
      if label then
        labels[#labels+1] = label
      end
    end
  elseif control.type == defines.control_behavior.type.decider_combinator then
    for _,condition in pairs(control.parameters.conditions or {}) do
      local label = Labels.ConditionLabel(condition, options)
      if label then
        labels[#labels+1] = label
      end
    end
    for _,output in pairs(control.parameters.outputs or {}) do
      local label = Labels.SignalLabel(output.signal, options)
      if label or ineffective(options) then
        labels[#labels+1] = '{' .. (label or Labels.NONE) .. '|=|' ..
          (output.copy_count_from_input and 'input' or '1') .. '}'
      end
    end
    return '<1>\\>|{' .. table.concat(labels, '|') .. '}|<2>\\>'
  elseif control.type == defines.control_behavior.type.arithmetic_combinator then
    if Labels.SignalLabel(control.parameters.output_signal, options) or ineffective(options) then
      local op = control.parameters.operation
      if op == ">>" then op = "\\>\\>" end
      if op == "<<" then op = "\\<\\<" end
      labels[#labels+1] = '{' ..
        (Labels.SignalLabel(control.parameters.first_signal, options) or
         control.parameters.first_constant or Labels.NONE) ..
        '|' .. (op or "?") .. '|' ..
        (Labels.SignalLabel(control.parameters.second_signal, options) or
         control.parameters.second_constant or Labels.NONE) ..
        '}'
      labels[#labels+1] = Labels.SignalLabel(control.parameters.output_signal, options) or Labels.NONE
    end
    return '<1>\\>|{' .. table.concat(labels, '|') .. '}|<2>\\>'
  elseif control.type == defines.control_behavior.type.selector_combinator then
    -- new in 2.0, and every operation has its own name in the game's own locale
    local parameters = control.parameters
    local operation = parameters.operation or "select"
    labels[#labels+1] = word(options, "gui-selector." .. operation,
      SELECTOR_OPERATIONS[operation] or operation)
    if operation == "select" then
      local order = parameters.select_max
        and word(options, "gui-selector.select-max", "Sort descending")
        or word(options, "gui-selector.select-min", "Sort ascending")
      labels[#labels+1] = '{' .. order .. '|' ..
        word(options, "gui-selector.index", "Index") .. '|' ..
        (Labels.SignalLabel(parameters.index_signal, options)
         or parameters.index_constant or 0) .. '}'
    elseif operation == "count" then
      local label = Labels.SignalLabel(parameters.count_signal, options)
      if label or ineffective(options) then
        labels[#labels+1] = '{' ..
          word(options, "gui-selector.count-output", "Count output") .. '|' ..
          (label or Labels.NONE) .. '}'
      end
    elseif operation == "random" then
      labels[#labels+1] = '{' ..
        word(options, "gui-selector.random-interval", "Update interval") .. '|' ..
        (parameters.random_update_interval or 0) .. '}'
    end
    return '<1>\\>|{' .. table.concat(labels, '|') .. '}|<2>\\>'
  elseif control.type == defines.control_behavior.type.constant_combinator then
    labels[#labels+1] = control.enabled and word(options, CG .. "on", "On")
      or word(options, CG .. "off", "Off")
    -- an empty one has nothing to list, and an empty row is just a taller box
    local data = table.concat(Labels.CCDataLabels(control, options),"|")
    if #data > 0 then
      labels[#labels+1] = data
    end
  elseif control.type == defines.control_behavior.type.transport_belt then
    if control.circuit_enable_disable then
      local label = Labels.ConditionLabel(control.circuit_condition, options)
      if label then
        labels[#labels+1] = label
      end
    end
    if control.read_contents then
      labels[#labels+1] =
        control.read_contents_mode == defines.control_behavior.transport_belt.content_read_mode.pulse
        and word(options, GUIS .. "pulse-mode", "Pulse")
        or word(options, GUIS .. "hold-mode", "Hold")
    end
  elseif control.type == defines.control_behavior.type.accumulator then
    if Labels.SignalLabel(control.output_signal, options) then
      labels[#labels+1] = Labels.SignalLabel(control.output_signal, options)
    end
  elseif control.type == defines.control_behavior.type.rail_signal then
    local label = Labels.RailSignalLabel(control, options)
    if #label > 0 then
      labels[#labels+1] = label
    end
  elseif control.type == defines.control_behavior.type.rail_chain_signal then
    local label = Labels.RailChainSignalLabel(control, options)
    if #label > 0 then
      labels[#labels+1] = label
    end
  elseif control.type == defines.control_behavior.type.wall then
    if control.open_gate then
      local label = Labels.ConditionLabel(control.circuit_condition, options)
      if label then
        labels[#labels+1] = label
      end
    end
    if control.read_sensor then
      local label = Labels.SignalLabel(control.output_signal, options)
      if label then
        labels[#labels+1] = label
      end
    end
  elseif control.type == defines.control_behavior.type.mining_drill then
    if control.circuit_enable_disable then
      local label = Labels.ConditionLabel(control.circuit_condition, options)
      if label then
        labels[#labels+1] = label
      end
    end
    if control.circuit_read_resources then
      labels[#labels+1] =
        control.resource_read_mode == defines.control_behavior.mining_drill.resource_read_mode.this_miner
        and word(options, GUIS .. "this-miner", "This Miner")
        or word(options, GUIS .. "entire-patch", "Entire Patch")
    end
  elseif control.type == defines.control_behavior.type.programmable_speaker then
    -- the volume is a float, and the slider's 0.8 arrives as 0.80000001192093
    local speaker = built_only(ent, "parameters")
    if speaker then
    labels[#labels+1] = '{' .. word(options, CG .. "volume", "Volume") .. '|' ..
      string.format("%g", speaker.playback_volume) .. '}'
    if speaker.playback_globally or speaker.allow_polyphony then
      local labels2 = {}
      if speaker.playback_globally then
        labels2[#labels2+1] = 'Global'
      end
      if speaker.allow_polyphony then
        labels2[#labels2+1] = 'Polyphony'
      end
      labels[#labels+1] = '{' .. table.concat(labels2, '|') .. '}'
    end

    end
    local instruments = prototype_of(ent).instruments

    if control.circuit_parameters.signal_value_is_pitch then
      labels[#labels+1] = string.format('{%s|%s}',
        instruments[control.circuit_parameters.instrument_id+1] and instruments[control.circuit_parameters.instrument_id+1].name or control.circuit_parameters.instrument_id,
        Labels.SignalLabel(control.circuit_condition.first_signal, options)
      )
    else
      labels[#labels+1] = string.format('{%s|%s}',
        instruments[control.circuit_parameters.instrument_id+1] and instruments[control.circuit_parameters.instrument_id+1].name or control.circuit_parameters.instrument_id,
        instruments[control.circuit_parameters.instrument_id+1] and instruments[control.circuit_parameters.instrument_id+1].notes[control.circuit_parameters.note_id+1] or control.circuit_parameters.note_id
      )
      if Labels.ConditionLabel(control.circuit_condition, options) then
        labels[#labels+1] = Labels.ConditionLabel(control.circuit_condition, options)
      end
    end

    local alert = built_only(ent, "alert_parameters")
    if alert and alert.show_alert then
      labels[#labels+1] = string.format('{%s|%s|%s}',
        alert.show_on_map
          and (word(options, CG .. "alert", "Alert") .. "|" ..
               word(options, CG .. "on-map", "On Map"))
          or word(options, CG .. "alert", "Alert"),
        Labels.SignalLabel(alert.icon_signal_id, options),
        alert.alert_message
      )
    end
  else
    -- Everything else the game has a control behaviour for, which since 2.0 is most of
    -- it: pumps, turrets, assemblers, reactors, labs and the rest. They nearly all
    -- inherit the generic on/off behaviour, so the condition is worth showing even
    -- though there is nothing type specific to say. Asking a behaviour for a property it
    -- does not have is an error rather than a nil, so the question is asked carefully.
    -- The type is worth a row when it says something the name does not: an
    -- assembling-machine-2 is an assembling-machine. A pump is a pump, and printing that
    -- twice is just a taller box.
    if entity_type ~= name then
      labels[#labels+1] = entity_type
    end
    local switched, enabled = pcall(function() return control.circuit_enable_disable end)
    if switched and enabled then
      local ok, condition = pcall(function() return control.circuit_condition end)
      if ok and condition then
        local label = Labels.ConditionLabel(condition, options)
        if label then
          labels[#labels+1] = label
        end
      end
    end
  end
  return '{' .. table.concat(labels, '|') .. '}'
end
return Labels

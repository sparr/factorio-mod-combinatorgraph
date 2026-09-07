--- Turning one entity's control behaviour into the text that goes inside its graph node.
---
--- Everything here takes a control behaviour, or an entity, and returns a graphviz record
--- label. Nothing here touches the world, which is what lets the unit tier drive it with
--- plain tables.
---
--- Capitalised because almost every function below keeps its own local `labels` list, and
--- a lowercase module would be shadowed by it.
local Labels = {}

--- What an empty slot is drawn as once the player has asked to see the settings that do
--- nothing. Issue #2: a condition with no signal is always false and an output with no
--- signal emits nothing, so by default neither is drawn -- which can be exactly the thing
--- somebody opened the graph to find.
Labels.NONE = "none"

---@param options table? { ineffective: boolean? }
local function ineffective(options)
    return options ~= nil and options.ineffective == true
end

function Labels.SignalLabel(signal)
  -- TODO: disambiguate signals with the same name but different types
  return signal and signal.name or nil
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
          filter.value.name,
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
  local first = Labels.SignalLabel(condition.first_signal)
  -- a constant of zero is a perfectly good operand, so this asks for nil rather than truth
  local second = condition.second_signal and Labels.SignalLabel(condition.second_signal)
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
    labels[#labels+1] = "Set Filters (" .. control.entity.inserter_filter_mode .. ")"
  end

  if control.circuit_read_hand_contents then
    if control.circuit_hand_read_mode == defines.control_behavior.inserter.hand_read_mode.pulse then
      labels[#labels+1] = "Pulse"
    elseif control.circuit_hand_read_mode == defines.control_behavior.inserter.hand_read_mode.hold then
      labels[#labels+1] = "Hold"
    end
  end

  if control.circuit_set_stack_size and Labels.SignalLabel(control.circuit_stack_control_signal) then
    labels[#labels+1] = "{Set Stack Size|" .. Labels.SignalLabel(control.circuit_stack_control_signal) .. "}"
  end

  return table.concat(labels, '|')
end

function Labels.RoboportLabel(control, options)
  local labels = {}
  if control.read_logistics then
    labels[#labels+1] = "Read Logistics"
  end
  if control.read_robot_stats then
    if Labels.SignalLabel(control.available_logistic_output_signal) then
      labels[#labels+1] = '{Avail Log|' .. Labels.SignalLabel(control.available_logistic_output_signal) .. '}'
    end
    if Labels.SignalLabel(control.total_logistic_output_signal) then
      labels[#labels+1] = '{Total Log|' .. Labels.SignalLabel(control.total_logistic_output_signal) .. '}'
    end
    if Labels.SignalLabel(control.available_construction_output_signal) then
      labels[#labels+1] = '{Avail Con|' .. Labels.SignalLabel(control.available_construction_output_signal) .. '}'
    end
    if Labels.SignalLabel(control.total_construction_output_signal) then
      labels[#labels+1] = '{Total Con|' .. Labels.SignalLabel(control.total_construction_output_signal) .. '}'
    end
  end
  return table.concat(labels, '|')
end

function Labels.RailSignalLabel(control, options)
  local labels = {}
  if control.read_signal then
    if Labels.SignalLabel(control.red_signal) then
      labels[#labels+1] = '{Red Signal|' .. Labels.SignalLabel(control.red_signal) .. '}'
    end
    if Labels.SignalLabel(control.orange_signal) then
      labels[#labels+1] = '{Orange Signal|' .. Labels.SignalLabel(control.orange_signal) .. '}'
    end
    if Labels.SignalLabel(control.green_signal) then
      labels[#labels+1] = '{Green Signal|' .. Labels.SignalLabel(control.green_signal) .. '}'
    end
  end
  if control.close_signal and Labels.ConditionLabel(control.circuit_condition, options) then
    labels[#labels+1] = Labels.ConditionLabel(control.circuit_condition, options)
  end
  return table.concat(labels, '|')
end

function Labels.RailChainSignalLabel(control, options)
  local labels = {}
  if Labels.SignalLabel(control.red_signal) then
    labels[#labels+1] = '{Red Signal|' .. Labels.SignalLabel(control.red_signal) .. '}'
  end
  if Labels.SignalLabel(control.orange_signal) then
    labels[#labels+1] = '{Orange Signal|' .. Labels.SignalLabel(control.orange_signal) .. '}'
  end
  if Labels.SignalLabel(control.green_signal) then
    labels[#labels+1] = '{Green Signal|' .. Labels.SignalLabel(control.green_signal) .. '}'
  end
  if Labels.SignalLabel(control.blue_signal) then
    labels[#labels+1] = '{Blue Signal|' .. Labels.SignalLabel(control.blue_signal) .. '}'
  end
  return table.concat(labels, '|')
end

-- likewise here: one mode became two switches, and both can be on at once
function Labels.LogisticContainerLabel(control, options)
  local labels = {}
  if control.read_contents then
    labels[#labels+1] = "Read Contents"
  end
  if control.set_requests then
    labels[#labels+1] = "Set Requests"
  end
  return table.concat(labels, '|')
end

function Labels.EntityLabel(ent, options)
  local control = ent.get_or_create_control_behavior()
  --TODO: remote.call for mods to register custom output for modded entities's configs
  if not control then
    return string.format('{%s|%s}',
      ent.type,
      ent.name
    )
  end
  local labels = {ent.name}
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
      labels[#labels+1] = 'Use Colors'
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
      labels[#labels+1] = 'Send to train'
    end
    if control.read_from_train then
      labels[#labels+1] = 'Read from train'
    end
    if control.read_stopped_train and Labels.SignalLabel(control.stopped_train_signal) then
      labels[#labels+1] = '{Read stopped train|' .. Labels.SignalLabel(control.stopped_train_signal) .. '}'
    end
    if control.set_trains_limit and Labels.SignalLabel(control.trains_limit_signal) then
      labels[#labels+1] = '{Set trains limit|' .. Labels.SignalLabel(control.trains_limit_signal) .. '}'
    end
    if control.read_trains_count and Labels.SignalLabel(control.trains_count_signal) then
      labels[#labels+1] = '{Read trains count|' .. Labels.SignalLabel(control.trains_count_signal) .. '}'
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
      local label = Labels.SignalLabel(output.signal)
      if label or ineffective(options) then
        labels[#labels+1] = '{' .. (label or Labels.NONE) .. '|=|' ..
          (output.copy_count_from_input and 'input' or '1') .. '}'
      end
    end
    return '<1>\\>|{' .. table.concat(labels, '|') .. '}|<2>\\>'
  elseif control.type == defines.control_behavior.type.arithmetic_combinator then
    if Labels.SignalLabel(control.parameters.output_signal) or ineffective(options) then
      local op = control.parameters.operation
      if op == ">>" then op = "\\>\\>" end
      if op == "<<" then op = "\\<\\<" end
      labels[#labels+1] = '{' ..
        (Labels.SignalLabel(control.parameters.first_signal) or
         control.parameters.first_constant or Labels.NONE) ..
        '|' .. (op or "?") .. '|' ..
        (Labels.SignalLabel(control.parameters.second_signal) or
         control.parameters.second_constant or Labels.NONE) ..
        '}'
      labels[#labels+1] = Labels.SignalLabel(control.parameters.output_signal) or Labels.NONE
    end
    return '<1>\\>|{' .. table.concat(labels, '|') .. '}|<2>\\>'
  elseif control.type == defines.control_behavior.type.constant_combinator then
    labels[#labels+1] = control.enabled and "On" or "Off"
    labels[#labels+1] = table.concat(Labels.CCDataLabels(control, options),"|")
  elseif control.type == defines.control_behavior.type.transport_belt then
    if control.circuit_enable_disable then
      local label = Labels.ConditionLabel(control.circuit_condition, options)
      if label then
        labels[#labels+1] = label
      end
    end
    if control.read_contents then
      labels[#labels+1] = control.read_contents_mode == defines.control_behavior.transport_belt.content_read_mode.pulse and "Pulse" or "Hold"
    end
  elseif control.type == defines.control_behavior.type.accumulator then
    if Labels.SignalLabel(control.output_signal) then
      labels[#labels+1] = Labels.SignalLabel(control.output_signal)
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
      local label = Labels.SignalLabel(control.output_signal)
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
      labels[#labels+1] = control.resource_read_mode == defines.control_behavior.mining_drill.resource_read_mode.this_miner and "This Miner" or "Entire Patch"
    end
  elseif control.type == defines.control_behavior.type.programmable_speaker then
    labels[#labels+1] = '{Volume|' .. ent.parameters.playback_volume .. '}'
    if ent.parameters.playback_globally or ent.parameters.allow_polyphony then
      local labels2 = {}
      if ent.parameters.playback_globally then
        labels2[#labels2+1] = 'Global'
      end
      if ent.parameters.allow_polyphony then
        labels2[#labels2+1] = 'Polyphony'
      end
      labels[#labels+1] = '{' .. table.concat(labels2, '|') .. '}'
    end

    local instruments = ent.prototype.instruments

    if control.circuit_parameters.signal_value_is_pitch then
      labels[#labels+1] = string.format('{%s|%s}',
        instruments[control.circuit_parameters.instrument_id+1] and instruments[control.circuit_parameters.instrument_id+1].name or control.circuit_parameters.instrument_id,
        Labels.SignalLabel(control.circuit_condition.first_signal)
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

    if ent.alert_parameters and ent.alert_parameters.show_alert then
      labels[#labels+1] = string.format('{%s|%s|%s}',
        ent.alert_parameters.show_on_map and "Alert|On Map" or "Alert",
        Labels.SignalLabel(ent.alert_parameters.icon_signal_id),
        ent.alert_parameters.alert_message
      )
    end
  else
    labels[#labels+1] = ent.type
  end
  return '{' .. table.concat(labels, '|') .. '}'
end
return Labels

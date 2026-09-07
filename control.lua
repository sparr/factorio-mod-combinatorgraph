local function SignalLabel(signal)
  -- TODO: disambiguate signals with the same name but different types
  return signal and signal.name or nil
end

-- 2.0 replaced the constant combinator's flat parameter list with logistic sections,
-- each holding filters whose signal is a value and whose count is a minimum. An empty
-- combinator has no sections at all, which is what used to be handed to pairs as nil.
local function CCDataLabels(control)
  local labels = {}
  for _,section in pairs(control.sections or {}) do
    for _,filter in pairs(section.filters or {}) do
      if filter.value and filter.value.name then
        labels[#labels+1] = string.format("{%s|%d}",
          filter.value.name,
          filter.min or 0
        )
      end
    end
  end
  return labels
end

local function ConditionLabel(condition)
  if condition.first_signal and condition.first_signal.name and ((condition.second_signal and condition.second_signal.name) or condition.constant) then
    return string.format('{%s|\\%s|%s}',
      SignalLabel(condition.first_signal),
      condition.comparator,
      condition.second_signal and SignalLabel(condition.second_signal) or condition.constant
    )
  end
  return nil
end

local function InserterLabel(control)
  local labels = {}
  -- the single mode_of_operation became two independent switches
  if control.circuit_enable_disable then
    local label = ConditionLabel(control.circuit_condition)
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
    elseif control.circuit_hand_read_mode == defines.control_behavior.inserter.hand_read_mode.pulse then
      labels[#labels+1] = "Hold"
    end
  end

  if control.circuit_set_stack_size and SignalLabel(control.circuit_stack_control_signal) then
    labels[#labels+1] = "{Set Stack Size|" .. SignalLabel(control.circuit_stack_control_signal) .. "}"
  end

  return table.concat(labels, '|')
end

local function RoboportLabel(control)
  local labels = {}
  if control.read_logistics then
    labels[#labels+1] = "Read Logistics"
  end
  if control.read_robot_stats then
    if SignalLabel(control.available_logistic_output_signal) then
      labels[#labels+1] = '{Avail Log|' .. SignalLabel(control.available_logistic_output_signal) .. '}'
    end
    if SignalLabel(control.total_logistic_output_signal) then
      labels[#labels+1] = '{Total Log|' .. SignalLabel(control.total_logistic_output_signal) .. '}'
    end
    if SignalLabel(control.available_construction_output_signal) then
      labels[#labels+1] = '{Avail Con|' .. SignalLabel(control.available_construction_output_signal) .. '}'
    end
    if SignalLabel(control.total_construction_output_signal) then
      labels[#labels+1] = '{Total Con|' .. SignalLabel(control.total_construction_output_signal) .. '}'
    end
  end
  return table.concat(labels, '|')
end

local function RailSignalLabel(control)
  local labels = {}
  if control.read_signal then
    if SignalLabel(control.red_signal) then
      labels[#labels+1] = '{Red Signal|' .. SignalLabel(control.red_signal) .. '}'
    end
    if SignalLabel(control.orange_signal) then
      labels[#labels+1] = '{Orange Signal|' .. SignalLabel(control.orange_signal) .. '}'
    end
    if SignalLabel(control.green_signal) then
      labels[#labels+1] = '{Green Signal|' .. SignalLabel(control.green_signal) .. '}'
    end
  end
  if control.close_signal and ConditionLabel(control.circuit_condition) then
    labels[#labels+1] = ConditionLabel(control.circuit_condition)
  end
  return table.concat(labels, '|')
end

local function RailChainSignalLabel(control)
  local labels = {}
  if SignalLabel(control.red_signal) then
    labels[#labels+1] = '{Red Signal|' .. SignalLabel(control.red_signal) .. '}'
  end
  if SignalLabel(control.orange_signal) then
    labels[#labels+1] = '{Orange Signal|' .. SignalLabel(control.orange_signal) .. '}'
  end
  if SignalLabel(control.green_signal) then
    labels[#labels+1] = '{Green Signal|' .. SignalLabel(control.green_signal) .. '}'
  end
  if SignalLabel(control.blue_signal) then
    labels[#labels+1] = '{Blue Signal|' .. SignalLabel(control.blue_signal) .. '}'
  end
  return table.concat(labels, '|')
end

-- likewise here: one mode became two switches, and both can be on at once
local function LogisticContainerLabel(control)
  local labels = {}
  if control.read_contents then
    labels[#labels+1] = "Read Contents"
  end
  if control.set_requests then
    labels[#labels+1] = "Set Requests"
  end
  return table.concat(labels, '|')
end

local function EntityLabel(ent)
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
      local label = ConditionLabel(control.circuit_condition)
      if label then
        labels[#labels+1] = label
      end
    end
    if control.connect_to_logistic_network then
      local label = ConditionLabel(control.logistic_condition)
      if label then
        labels[#labels+1] = label
      end
    end
  elseif control.type == defines.control_behavior.type.inserter then
    local label = InserterLabel(control)
    if #label > 0 then
      labels[#labels+1] = label
    end
  elseif control.type == defines.control_behavior.type.lamp then
    if control.use_colors then
      labels[#labels+1] = 'Use Colors'
    end
    local label = ConditionLabel(control.circuit_condition)
    if label then
      labels[#labels+1] = label
    end
  elseif control.type == defines.control_behavior.type.logistic_container then
    labels[#labels+1] = LogisticContainerLabel(control)
  elseif control.type == defines.control_behavior.type.roboport then
    labels[#labels+1] = RoboportLabel(control)
  elseif control.type == defines.control_behavior.type.train_stop then
    if control.send_to_train then
      labels[#labels+1] = 'Send to train'
    end
    if control.read_from_train then
      labels[#labels+1] = 'Read from train'
    end
    if control.read_stopped_train and SignalLabel(control.stopped_train_signal) then
      labels[#labels+1] = '{Read stopped train|' .. SignalLabel(control.stopped_train_signal) .. '}'
    end
    if control.set_trains_limit and SignalLabel(control.trains_limit_signal) then
      labels[#labels+1] = '{Set trains limit|' .. SignalLabel(control.trains_limit_signal) .. '}'
    end
    if control.read_trains_count and SignalLabel(control.trains_count_signal) then
      labels[#labels+1] = '{Read trains count|' .. SignalLabel(control.trains_count_signal) .. '}'
    end
    if control.circuit_enable_disable then
      local label = ConditionLabel(control.circuit_condition)
      if label then
        labels[#labels+1] = label
      end
    end
  elseif control.type == defines.control_behavior.type.decider_combinator then
    for _,condition in pairs(control.parameters.conditions or {}) do
      local label = ConditionLabel(condition)
      if label then
        labels[#labels+1] = label
      end
    end
    for _,output in pairs(control.parameters.outputs or {}) do
      local label = SignalLabel(output.signal)
      if label then
        labels[#labels+1] = '{' .. label .. '|=|' .. (output.copy_count_from_input and 'input' or '1') .. '}'
      end
    end
    return '<1>\\>|{' .. table.concat(labels, '|') .. '}|<2>\\>'
  elseif control.type == defines.control_behavior.type.arithmetic_combinator then
    if SignalLabel(control.parameters.output_signal) then
      local op = control.parameters.operation
      if op == ">>" then op = "\\>\\>" end
      if op == "<<" then op = "\\<\\<" end
      labels[#labels+1] = '{' .. 
        (SignalLabel(control.parameters.first_signal) and SignalLabel(control.parameters.first_signal) or control.parameters.first_constant) .. 
        '|' .. op .. '|' .. 
        (SignalLabel(control.parameters.second_signal) and SignalLabel(control.parameters.second_signal) or control.parameters.second_constant) ..
        '}'
      labels[#labels+1] = SignalLabel(control.parameters.output_signal)
    end
    return '<1>\\>|{' .. table.concat(labels, '|') .. '}|<2>\\>'
  elseif control.type == defines.control_behavior.type.constant_combinator then
    labels[#labels+1] = control.enabled and "On" or "Off"
    labels[#labels+1] = table.concat(CCDataLabels(control),"|")
  elseif control.type == defines.control_behavior.type.transport_belt then
    if control.circuit_enable_disable then
      local label = ConditionLabel(control.circuit_condition)
      if label then
        labels[#labels+1] = label
      end
    end
    if control.read_contents then
      labels[#labels+1] = control.read_contents_mode == defines.control_behavior.transport_belt.content_read_mode.pulse and "Pulse" or "Hold"
    end
  elseif control.type == defines.control_behavior.type.accumulator then
    if SignalLabel(control.output_signal) then
      labels[#labels+1] = SignalLabel(control.output_signal)
    end
  elseif control.type == defines.control_behavior.type.rail_signal then
    local label = RailSignalLabel(control)
    if #label > 0 then
      labels[#labels+1] = label
    end
  elseif control.type == defines.control_behavior.type.rail_chain_signal then
    local label = RailChainSignalLabel(control)
    if #label > 0 then
      labels[#labels+1] = label
    end
  elseif control.type == defines.control_behavior.type.wall then
    if control.open_gate then
      local label = ConditionLabel(control.circuit_condition)
      if label then
        labels[#labels+1] = label
      end
    end
    if control.read_sensor then
      local label = SignalLabel(control.output_signal)
      if label then
        labels[#labels+1] = label
      end
    end
  elseif control.type == defines.control_behavior.type.mining_drill then
    if control.circuit_enable_disable then
      local label = ConditionLabel(control.circuit_condition)
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
        SignalLabel(control.circuit_condition.first_signal)
      )
    else
      labels[#labels+1] = string.format('{%s|%s}',
        instruments[control.circuit_parameters.instrument_id+1] and instruments[control.circuit_parameters.instrument_id+1].name or control.circuit_parameters.instrument_id,
        instruments[control.circuit_parameters.instrument_id+1] and instruments[control.circuit_parameters.instrument_id+1].notes[control.circuit_parameters.note_id+1] or control.circuit_parameters.note_id
      )
      if ConditionLabel(control.circuit_condition) then
        labels[#labels+1] = ConditionLabel(control.circuit_condition)
      end
    end

    if ent.alert_parameters and ent.alert_parameters.show_alert then
      labels[#labels+1] = string.format('{%s|%s|%s}',
        ent.alert_parameters.show_on_map and "Alert|On Map" or "Alert",
        SignalLabel(ent.alert_parameters.icon_signal_id),
        ent.alert_parameters.alert_message
      )
    end
  else
    labels[#labels+1] = ent.type
  end
  return '{' .. table.concat(labels, '|') .. '}'
end

-- 2.0 replaced circuit_connection_definitions with wire connectors: an entity has one
-- connector per wire colour per side, and each connector lists the connectors it reaches.
-- A combinator therefore has four rather than two, and which side a wire lands on is a
-- property of the connector rather than a circuit id carried on the connection.
--
-- port is the old circuit id: 1 for the input side, 2 for the output side, and 1 for
-- everything that only has one side. Copper connectors -- poles and power switches --
-- are not circuit wires and are left out entirely.
local connectors = {
  [defines.wire_connector_id.circuit_red]             = { port = 1, color = "red" },
  [defines.wire_connector_id.circuit_green]           = { port = 1, color = "green" },
  [defines.wire_connector_id.combinator_input_red]    = { port = 1, color = "red" },
  [defines.wire_connector_id.combinator_input_green]  = { port = 1, color = "green" },
  [defines.wire_connector_id.combinator_output_red]   = { port = 2, color = "red" },
  [defines.wire_connector_id.combinator_output_green] = { port = 2, color = "green" },
}

local function WirePort(ent,port)
  if ent.type == "arithmetic-combinator" or ent.type == "decider-combinator" then
    local ports={"w","e"}
    return ports[port]
  else
    return "_"
  end
end

--- The circuit connectors an entity actually has something plugged into
local function CircuitConnectors(ent)
  local found = {}
  for id,connector in pairs(ent.get_wire_connectors(false)) do
    if connectors[id] and connector.connection_count > 0 then
      found[#found+1] = { connector = connector, info = connectors[id] }
    end
  end
  return found
end

local function GraphCombinators(ents)
  local gv = {
    "graph combinators {",
    --'graph[overlap="portho" splines="spline" layout="fdp" sep=0.5];',
    'graph[overlap="portho" splines="spline" sep=0.5];',
  }
  local donelist = {}
  for _,ent in pairs(ents) do
    local wired = CircuitConnectors(ent)
    if #wired > 0 then
      gv[#gv+1] = string.format('%d [shape=record label="%s" pos="%d,%d"];',
        ent.unit_number,
        EntityLabel(ent),
        ent.position.x,
        ent.position.y
      )

      for _,source in pairs(wired) do
        for _,connection in pairs(source.connector.connections) do
          local target = connection.target
          local target_info = connectors[target.wire_connector_id]
          local target_ent = target_info and target.owner
          -- each wire is reached from both ends, so it is drawn from whichever end is
          -- seen first; the self connection is drawn once, from the output side
          if target_ent and not (
            donelist[target_ent.unit_number] or
            ent == target_ent and target_info.port == 1
            ) then
            gv[#gv+1] = string.format('%d:%d -- %d:%d [color=%s headport=%s tailport=%s];',
              ent.unit_number,source.info.port,
              target_ent.unit_number,target_info.port,
              source.info.color,
              WirePort(target_ent,target_info.port),
              WirePort(ent,source.info.port)
            )
          end
        end
      end
    end

    donelist[ent.unit_number] = true
  end
  gv[#gv+1] = "}"
  -- 2.0 moved write_file off game and onto helpers
  helpers.write_file("combinatorgraph.gv",table.concat(gv,"\n"))
end



script.on_event(defines.events.on_player_selected_area, function(event)
  if event.item == "combinatorgraph-tool" then
    GraphCombinators(event.entities)
  end
end)

script.on_event(defines.events.on_player_alt_selected_area, function(event)
  if event.item == "combinatorgraph-tool" then
    GraphCombinators(event.entities)
  end
end)

--- Walking the wires between the selected entities and building the graphviz document.
---
--- Writing the file is left to control.lua: this hands back the document as a string, so
--- that the tests can read what would have been written.
local Labels = require("lib.labels")

local Graph = {}

-- 2.0 replaced circuit_connection_definitions with wire connectors: an entity has one
-- connector per wire colour per side, and each connector lists the connectors it reaches.
-- A combinator therefore has four rather than two, and which side a wire lands on is a
-- property of the connector rather than a circuit id carried on the connection.
--
-- port is the old circuit id: 1 for the input side, 2 for the output side, and 1 for
-- everything that only has one side. Copper connectors -- poles and power switches --
-- are not circuit wires and are left out entirely.
Graph.connectors = {
  [defines.wire_connector_id.circuit_red]             = { port = 1, color = "red" },
  [defines.wire_connector_id.circuit_green]           = { port = 1, color = "green" },
  [defines.wire_connector_id.combinator_input_red]    = { port = 1, color = "red" },
  [defines.wire_connector_id.combinator_input_green]  = { port = 1, color = "green" },
  [defines.wire_connector_id.combinator_output_red]   = { port = 2, color = "red" },
  [defines.wire_connector_id.combinator_output_green] = { port = 2, color = "green" },
}

function Graph.WirePort(ent,port)
  if ent.type == "arithmetic-combinator" or ent.type == "decider-combinator" then
    local ports={"w","e"}
    return ports[port]
  else
    return "_"
  end
end

--- The circuit connectors an entity actually has something plugged into
function Graph.CircuitConnectors(ent)
  local found = {}
  for id,connector in pairs(ent.get_wire_connectors(false)) do
    if Graph.connectors[id] and connector.connection_count > 0 then
      found[#found+1] = { connector = connector, info = Graph.connectors[id] }
    end
  end
  return found
end

function Graph.Document(ents, options)
  local gv = {
    "graph combinators {",
    --'graph[overlap="portho" splines="spline" layout="fdp" sep=0.5];',
    'graph[overlap="portho" splines="spline" sep=0.5];',
  }
  local donelist = {}
  for _,ent in pairs(ents) do
    local wired = Graph.CircuitConnectors(ent)
    if #wired > 0 then
      gv[#gv+1] = string.format('%d [shape=record label="%s" pos="%d,%d"];',
        ent.unit_number,
        Labels.EntityLabel(ent, options),
        ent.position.x,
        ent.position.y
      )

      for _,source in pairs(wired) do
        for _,connection in pairs(source.connector.connections) do
          local target = connection.target
          local target_info = Graph.connectors[target.wire_connector_id]
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
              Graph.WirePort(target_ent,target_info.port),
              Graph.WirePort(ent,source.info.port)
            )
          end
        end
      end
    end

    donelist[ent.unit_number] = true
  end
  gv[#gv+1] = "}"
  return table.concat(gv,"\n")
end
return Graph

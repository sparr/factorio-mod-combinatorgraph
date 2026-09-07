
data:extend({
  {
    type = "selection-tool",
    name = "combinatorgraph-tool",
    icon = "__combinatorgraph__/combinatorgraph.png",
    icon_size = 32,
    stack_size = 1,
    subgroup = "terrain",
    order = "d[combinatorgraph-tool]-a[plain]",
    -- 2.0 moved the flat selection_mode/selection_color/selection_cursor_box_type
    -- fields into select and alt_select, both of which are required. 2.1 then stopped
    -- letting "blueprint" imply "any-entity", and this tool is only ever after entities,
    -- so it has to ask for them: without it the selection comes back empty.
    select =
    {
      border_color = {r = 0.2, g = 0.8, b = 0.2, a = 0.2},
      mode = {"blueprint", "any-entity"},
      -- it graphs wired entities and has never had anything to say about ground
      ignore_cannot_select_tiles = true,
      cursor_box_type = "copy",
    },
    alt_select =
    {
      border_color = {r = 0.2, g = 0.8, b = 0.2, a = 0.2},
      mode = {"blueprint", "any-entity"},
      -- it graphs wired entities and has never had anything to say about ground
      ignore_cannot_select_tiles = true,
      cursor_box_type = "copy",
    },
  },
  {
    type = "recipe",
    name = "combinatorgraph-tool",
    enabled = true,
    energy_required = 0.5,
    -- 2.0 wants named ingredients and a results list
    ingredients = {{type = "item", name = "electronic-circuit", amount = 1}},
    results = {{type = "item", name = "combinatorgraph-tool", amount = 1}},
  }
})

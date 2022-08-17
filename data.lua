PATH = "__combinatorgraph__"

data:extend({
  {
    type = "selection-tool",
    name = "combinatorgraph-tool",
    icon = PATH .. "/graphics/combinatorgraph.png",
    icon_size = 32,
    stack_size = 1,
    flags = { "hidden","spawnable","not-stackable","only-in-cursor" },
    subgroup = "other",
    order = "d[combinatorgraph-tool]-a[plain]",
    selection_color = {r = 0.2, g = 0.8, b = 0.2, a = 0.2},
    alt_selection_color = {r = 0.2, g = 0.8, b = 0.2, a = 0.2},
    selection_mode = {"blueprint"},
    alt_selection_mode = {"blueprint"},
    selection_cursor_box_type = "copy",
    alt_selection_cursor_box_type = "copy"
  },
  {
    type = "recipe",
    name = "combinatorgraph-tool",
    enabled = false,
    energy_required = 0.5,
    ingredients ={},
    result = "combinatorgraph-tool"
  },
  {
    type = "shortcut",
    name = "give-combinatorgraph-tool",
    order = "d[combinatorgraph-tool]-a[plain]",
    action = "spawn-item",
    associated_control_input = "give-combinatorgraph-tool",
    item_to_spawn = "combinatorgraph-tool",
    icon =
    {
      filename = PATH .. "/graphics/combinatorgraph.png",
      priority = "extra-high-no-scale",
      size = 32,
      mipmap_count = 2,
      flags = {"gui-icon"}
    },
    small_icon =
    {
      filename = PATH .. "/graphics/combinatorgraph-x24.png",
      priority = "extra-high-no-scale",
      size = 24,
      mipmap_count = 2,
      flags = {"gui-icon"}
    }
  }
})

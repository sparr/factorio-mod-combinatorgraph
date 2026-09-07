data:extend({
  {
    -- per player rather than global: it changes what one person's graph looks like, and
    -- costs nothing to change between one selection and the next
    type = "bool-setting",
    name = "combinatorgraph-show-ineffective",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "a",
  },
})

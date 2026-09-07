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
  {
    type = "bool-setting",
    name = "combinatorgraph-localise",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "b",
  },
  {
    -- record is graphviz's own compact node shape and is what this mod has always
    -- written. html draws each node as a table instead, which is the only kind of label
    -- that can hold a picture, so asking for pictures implies it.
    type = "string-setting",
    name = "combinatorgraph-label-format",
    setting_type = "runtime-per-user",
    default_value = "record",
    allowed_values = { "record", "html" },
    order = "c",
  },
  {
    type = "bool-setting",
    name = "combinatorgraph-icons",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "d",
  },
})

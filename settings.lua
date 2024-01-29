data:extend {
    {
        type = "bool-setting",
        name = "jq-use-extra-bonuses",
        setting_type = "startup",
        default_value = false,
        order = "a",
    },
    {
        type = "bool-setting",
        name = "jq-show-player-programming-recipes",
        setting_type = "startup",
        default_value = false,
        order = "b",
    },
    {
        type = "bool-setting",
        name = "jq-alt-overlay",
        setting_type = "startup",
        default_value = false,
        order = "c",
    },
    {
        type = "string-setting",
        name = "jq-quality-bonuses-import",
        setting_type = "startup",
        default_value = "",
        allow_blank = true,
        order = "d",
    },
    {
        type = "double-setting",
        name = "jq-recycling-efficiency",
        setting_type = "startup",
        default_value = 0.25,
        minimum_value = 0.0,
        maximum_value = 1.0,
        order = "e",
    },
    {
        type = "bool-setting",
        name = "jq-delevel-to-normal",
        setting_type = "startup",
        default_value = false,
        order = "f",
    },
    {
        type = "bool-setting",
        name = "jq-beacon-overlay",
        setting_type = "startup",
        default_value = true,
        order = "g",
    },
    {
        type = "string-setting",
        name = "jq-quality-no-quality-items",
        setting_type = "startup",
        default_value = "",
        allow_blank = true,
        order = "za",
    },
    {
        type = "string-setting",
        name = "jq-quality-no-quality-subgroups",
        setting_type = "startup",
        default_value = "",
        allow_blank = true,
        order = "zb",
    },
    {
        type = "string-setting",
        name = "jq-quality-no-quality-groups",
        setting_type = "startup",
        default_value = "",
        allow_blank = true,
        order = "zc",
    },
}

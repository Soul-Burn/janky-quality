data:extend {
    {
        type = "bool-setting",
        name = "jq-use-extra-bonuses",
        setting_type = "startup",
        default_value = true,
    },
    {
        type = "bool-setting",
        name = "jq-show-player-programming-recipes",
        setting_type = "startup",
        default_value = false,
    },
    {
        type = "bool-setting",
        name = "jq-alt-overlay",
        setting_type = "startup",
        default_value = false,
    },
    {
        type = "string-setting",
        name = "jq-quality-bonuses-import",
        setting_type = "startup",
        default_value = "",
        allow_blank = true,
    },
    {
        type = "double-setting",
        name = "jq-recycling-efficiency",
        setting_type = "startup",
        default_value = 0.25,
        minimum_value = 0.0,
        maximum_value = 1.0,
    },
}

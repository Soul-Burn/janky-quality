for _, force in pairs(game.forces) do
    force.technologies["jq_default_recipes"].researched = true
    force.reset_technology_effects()
end

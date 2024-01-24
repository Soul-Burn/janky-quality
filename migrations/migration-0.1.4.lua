for _, force in pairs(game.forces) do
    local technologies = force.technologies
    local max_level = 0
    for i, tech in pairs { "quality-module", "quality-module-2", "quality-module-3" } do
        if technologies[tech].researched then
            max_level = i
        end
    end
    for tech_name, technology in pairs(technologies) do
        if technology.researched then
            for i = 1, max_level do
                local tech_with_quality = technologies[tech_name .. "-with-quality-" .. i]
                if tech_with_quality then
                    tech_with_quality.researched = true
                end
            end
        end
    end
end

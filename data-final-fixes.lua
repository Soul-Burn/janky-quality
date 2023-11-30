local lib = require("__janky-quality__/lib/lib")

local imports = {
    "modules",
    "technologies",
}

for _, import in pairs(imports) do
    require(lib.p.prot .. import)
end

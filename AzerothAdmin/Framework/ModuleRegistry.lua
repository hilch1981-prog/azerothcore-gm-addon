AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

local function copyArray(source)
    local result = {}
    local i
    for i = 1, table.getn(source or {}) do
        result[i] = source[i]
    end
    return result
end

-- Registers module ownership and dependencies without changing the current
-- legacy load behavior. Each feature is migrated in its own later PR.
function addon:RegisterModule(name, definition)
    if type(name) ~= "string" or name == "" then
        return nil, "module name must be a non-empty string"
    end

    local existing = self.ModuleRegistry[name]
    if existing then return existing end

    definition = definition or {}
    local module = {
        name = name,
        status = definition.status or "legacy",
        dependencies = copyArray(definition.dependencies),
        runtimeFiles = copyArray(definition.runtimeFiles),
        dataFiles = copyArray(definition.dataFiles),
        tests = copyArray(definition.tests),
        futurePath = definition.futurePath,
    }

    self.ModuleRegistry[name] = module
    table.insert(self.ModuleOrder, name)
    return module
end

function addon:GetModule(name)
    return self.ModuleRegistry and self.ModuleRegistry[name] or nil
end

function addon:GetModuleNames()
    return copyArray(self.ModuleOrder)
end

function addon:ForEachModule(callback)
    if type(callback) ~= "function" then return end
    local i
    for i = 1, table.getn(self.ModuleOrder or {}) do
        local name = self.ModuleOrder[i]
        callback(self.ModuleRegistry[name], name)
    end
end

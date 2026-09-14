local A = AzerothAdminAC335
A.ModuleRegistry = A.ModuleRegistry or {}
A.ModuleOrder = A.ModuleOrder or {}

local function copyArray(source)
    local result = {}
    for i = 1, table.getn(source or {}) do result[i] = source[i] end
    return result
end

function A:RegisterModule(name, definition)
    if type(name) ~= "string" or name == "" then return nil, "invalid module name" end
    if self.ModuleRegistry[name] then return self.ModuleRegistry[name] end
    definition = definition or {}
    local module = {
        name = name,
        status = definition.status or "module-active-static-verified",
        dependencies = copyArray(definition.dependencies),
        runtimeFiles = copyArray(definition.runtimeFiles),
        dataFiles = copyArray(definition.dataFiles),
        tests = copyArray(definition.tests),
        notes = definition.notes,
    }
    self.ModuleRegistry[name] = module
    table.insert(self.ModuleOrder, name)
    return module
end

function A:GetModule(name) return self.ModuleRegistry[name] end
function A:GetModuleNames() return copyArray(self.ModuleOrder) end
function A:ForEachModule(callback)
    if type(callback) ~= "function" then return end
    for i = 1, table.getn(self.ModuleOrder) do
        local name=self.ModuleOrder[i]
        callback(self.ModuleRegistry[name], name)
    end
end

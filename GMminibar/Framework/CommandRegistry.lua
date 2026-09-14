local A = AzerothAdminAC335
A.Security = { PLAYER=0, MODERATOR=1, GAMEMASTER=2, ADMINISTRATOR=3, CONSOLE=4 }
A.OperatorSecurity = 3
A.CommandCatalog = A.CommandCatalog or {}
A.CommandOrder = A.CommandOrder or {}
A.Categories = A.Categories or {}
A.CategoryOrder = A.CategoryOrder or {}

function A:RegisterCategory(id, labelKey, order, icon, action)
    if not id or self.Categories[id] then return end
    self.Categories[id] = { id=id, labelKey=labelKey, order=order or 100, icon=icon, action=action }
    table.insert(self.CategoryOrder, id)
end

function A:RegisterCommand(definition)
    if type(definition) ~= "table" or not definition.id then return end
    if self.CommandCatalog[definition.id] then return end
    if type(definition.security) == "string" then
        definition.security = self.Security[definition.security] or self.Security.GAMEMASTER
    else
        definition.security = tonumber(definition.security) or self.Security.GAMEMASTER
    end
    if definition.source and definition.source ~= "addon" and not definition.sourcePath then
        definition.sourcePath = "src/server/scripts/Commands/" .. definition.source
    end
    if definition.verified == nil then definition.verified = definition.source ~= nil end
    definition.category = definition.category or "gm"
    self.CommandCatalog[definition.id] = definition
    table.insert(self.CommandOrder, definition.id)
end

function A:GetCommand(id) return self.CommandCatalog[id] end
function A:CanRunCommand(definition)
    if type(definition) == "string" then definition=self.CommandCatalog[definition] end
    if not definition then return false end
    return self:GetAccountSecurity() >= (tonumber(definition.security) or 0)
end
function A:QuoteArg(value)
    value=tostring(value or "")
    if string.find(value, '[%s"]') then return '"'..value:gsub('"','\\"')..'"' end
    return value
end
function A:BuildCommand(definition, suffix)
    local command=definition.command or ""
    suffix=self:Trim(suffix)
    if suffix ~= "" then command=command.." "..suffix end
    return command
end
function A:RunRegisteredCommand(id, suffix, bypassPrompt)
    local definition=self.CommandCatalog[id]
    if not definition then self:Print("Unknown command: "..tostring(id), true); return false end
    if not self:CanRunCommand(definition) then
        self:Print(self:L("SECURITY_DENIED", definition.security, self:GetAccountSecurity()), true)
        return false
    end
    if definition.action then
        local action=self[definition.action]
        if type(action) == "function" then return self:SafeCall(definition.action, action, self, definition) end
        self:Print("Missing action: "..tostring(definition.action), true); return false
    end
    if definition.promptKey and not bypassPrompt and self.ShowArgumentPrompt then
        self:ShowArgumentPrompt(definition)
        return true
    end
    if definition.dangerous and not bypassPrompt and self.ShowCommandConfirmation then
        self:ShowCommandConfirmation(definition, suffix)
        return true
    end
    return self:SendCommand(self:BuildCommand(definition, suffix))
end
function A:GetCategoryCommands(category)
    local out={}
    local showLifecycle = self:GetDB().showServerLifecycleCommands == true
    for _, id in ipairs(self.CommandOrder) do
        local definition=self.CommandCatalog[id]
        if definition and definition.category == category and (not definition.lifecycle or showLifecycle) then
            table.insert(out, definition)
        end
    end
    return out
end
function A:ToggleCommandFavorite(id)
    local favorites=self:GetDB().commandFavorites
    favorites[id]=not favorites[id]
    if self.RefreshToolbarQuickSlots then self:RefreshToolbarQuickSlots() end
    return favorites[id]
end
function A:IsCommandFavorite(id) return self:GetDB().commandFavorites[id] and true or false end

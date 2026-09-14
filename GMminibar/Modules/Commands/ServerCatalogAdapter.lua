local A = AzerothAdminAC335
local D = A.WorkbenchAdapter
local previousDefinitions, previousLabel, previousAllowed, previousPreview, previousExecute = D.Definitions, D.Label, D.Allowed, D.Preview, D.Execute
function D:Definitions()
    local out=previousDefinitions(self)
    for _, row in ipairs(A.ServerCommandIndex or {}) do
        local d={command="." .. row.name, label="." .. row.name, labelKey="RAW_COMMAND", serverIndex=true,
            security=row.security, help=row.help, hint=(row.help ~= "" and row.help or A:XL("SERVER_HELP")) .. "\n" .. A:XL(row.dbOnly and "DB_ONLY" or "SOURCE_COMMAND") .. " " .. row.source,
            source=row.source, permission=row.permission, dangerous=true, confirm=true}
        out[#out+1]={definition=d,key="server:" .. row.name,label=d.label,category=A:XL("SERVER_COMMANDS") .. " / " .. (row.name:match("^%S+") or row.name),group=A.WorkbenchCatalog:Group(d.command)}
    end
    return out
end
function D:Label(d) if d.serverIndex then return d.label end; return previousLabel(self,d) end
function D:Allowed(entry)
    if entry.definition.serverIndex then
        local sec=self:Security()
        -- Keep every command visible; server permissions remain authoritative.
        return not sec or not entry.definition.security or tonumber(sec)>=entry.definition.security
    end
    return previousAllowed(self,entry)
end
function D:Preview(entry,args,target)
    if entry.definition.serverIndex then return entry.definition.command .. (args~="" and (" " .. args) or "") end
    return previousPreview(self,entry,args,target)
end
function D:Execute(entry,args,target)
    if entry.definition.rc8Literal and not entry.definition.dangerous and self:Allowed(entry) then return A:SendCommand(self:Preview(entry,args,target)) end
    if entry.definition.serverIndex then self:Raw(self:Preview(entry,args,target)); return end
    return previousExecute(self,entry,args,target)
end

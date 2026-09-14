local A = AzerothAdminAC335
function A:FeatureText(moduleName, key)
    local composite=string.upper(tostring(moduleName or "")).."_"..tostring(key or "")
    local value=self:L(composite)
    if value == composite then return self:L(key) end
    return value
end

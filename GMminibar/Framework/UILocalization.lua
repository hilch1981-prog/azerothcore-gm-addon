local A = AzerothAdminAC335
A.localizedWidgets = A.localizedWidgets or {}
function A:RegisterLocalizedWidget(widget, key, setter)
    table.insert(self.localizedWidgets, { widget = widget, key = key, setter = setter })
end
function A:RefreshLocalizedUI()
    for _, entry in ipairs(self.localizedWidgets) do
        local widget=entry.widget
        if widget then
            if entry.setter then entry.setter(widget, self:L(entry.key))
            elseif widget.SetText then widget:SetText(self:L(entry.key)) end
        end
    end
    if self.RefreshMainWindow then self:RefreshMainWindow() end
end

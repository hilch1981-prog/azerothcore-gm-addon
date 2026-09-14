local A = AzerothAdminAC335
function A:ToggleFlight()
    local db=self:GetDB(); db.gmFlight=not db.gmFlight
    self:RunRegisteredCommand(db.gmFlight and "gm_fly_on" or "gm_fly_off",nil,true)
    if self.RefreshToolbarStates then self:RefreshToolbarStates() end
end
function A:ToggleGod()
    local db=self:GetDB(); db.godMode=not db.godMode
    self:RunRegisteredCommand(db.godMode and "cheat_god_on" or "cheat_god_off",nil,true)
    if self.RefreshToolbarStates then self:RefreshToolbarStates() end
end
function A:ToggleVisibility()
    local db=self:GetDB(); db.gmInvisible=not db.gmInvisible
    self:RunRegisteredCommand(db.gmInvisible and "gm_visible_off" or "gm_visible_on",nil,true)
    if self.RefreshToolbarStates then self:RefreshToolbarStates() end
end
function A:ToggleSpeed()
    if UnitExists('target') and not UnitIsUnit('target','player') then
        self:Print(self:T('이속은 자신에게 적용합니다. 대상을 해제하거나 자신을 선택해 주세요.'));return
    end
    local db=self:GetDB(); local requested=not db.speedBoosted
    if not self:RunRegisteredCommand(requested and "speed_3" or "speed_1",nil,true) then return false end
    db.speedBoosted=requested
    if self.RefreshToolbarStates then self:RefreshToolbarStates() end
    return true
end
function A:ToggleWaterwalk()
    local db=self:GetDB(); db.waterwalk=not db.waterwalk
    self:RunRegisteredCommand(db.waterwalk and "cheat_waterwalk_on" or "cheat_waterwalk_off",nil,true)
    if self.RefreshToolbarStates then self:RefreshToolbarStates() end
end

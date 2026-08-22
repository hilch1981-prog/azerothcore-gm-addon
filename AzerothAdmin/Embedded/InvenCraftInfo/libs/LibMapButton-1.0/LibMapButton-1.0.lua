local MAJOR_VERSION = "LibMapButton-1.0"
local MINOR_VERSION = 3

--[[
라이브러리: LibMapButton-1.0
설명: 미니맵 버튼 생성 라이브러리.
제작자: Inven - InTheBlue
사용법:
	local LMB = LibStub("LibMapButton-1.0")
	LMB:CreateButton(owner, name, icon, angle, db1, db2, db3, db4)
		미니맵 버튼 생성
		owner: 애드온
		name: 미니맵 버튼 이름
		icon: 아이콘
		angle: 기본 앵글값 (디폴트: 183)
		db1~4: BlueItemInfo.db.profile.minimap => db1 = "BlueItemInfo", db2 = "db", db3 = "profile", db4 = "minimap"
	LMB:SetTooltip(method or function)
		미니맵 툴팁 생성 함수 설정
	LMB:SetClick(method or function, button)
		클릭 함수 설정
]]

local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

if not BluePrint then function BluePrint() end end

local MinimapShapes = {
	["ROUND"] = { true, true, true, true },
	["SQUARE"] = { false, false, false, false },
	["CORNER-TOPLEFT"] = { true, false, false, false },
	["CORNER-TOPRIGHT"] = { false, false, true, false },
	["CORNER-BOTTOMLEFT"] = { false, true, false, false },
	["CORNER-BOTTOMRIGHT"] = { false, false, false, true },
	["SIDE-LEFT"] = { true, true, false, false },
	["SIDE-RIGHT"] = { false, false, true, true },
	["SIDE-TOP"] = { true, false, true, false },
	["SIDE-BOTTOM"] = { false, true, false, true },
	["TRICORNER-TOPLEFT"] = { true, true, true, false },
	["TRICORNER-TOPRIGHT"] = { true, false, true, true },
	["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
	["TRICORNER-BOTTOMRIGHT"] = { false, true, true, true },
}

local _G = _G
local type = _G.type
local deg = _G.math.deg
local atan2 = _G.math.atan2
local rad = _G.math.rad
local sin = _G.math.sin
local cos = _G.math.cos
local max = _G.math.max
local min = _G.math.min
local sqrt = _G.math.sqrt
local GetCursorPosition = _G.GetCursorPosition
local mx, my, mz, cx, cy, cz, y, rangle, x, y, q, dradius

lib.framelevel = lib.framelevel or 0
lib.buttons = lib.buttons or {}

local getDB = function(f, dv)
	if type(f) == "string" then
		f = _G[f]
	end
	if f.dataTable then
		if dv then
			if #f.dataTable == 4 then
				return _G[f.dataTable[1]][f.dataTable[2]][f.dataTable[3]][f.dataTable[4]][dv]
			elseif #f.dataTable == 3 then
				return _G[f.dataTable[1]][f.dataTable[2]][f.dataTable[3]][dv]
			elseif #f.dataTable == 2 then
				return _G[f.dataTable[1]][f.dataTable[2]][dv]
			elseif #f.dataTable == 1 then
				return _G[f.dataTable[1]][dv]
			end
		else
			if #f.dataTable == 4 then
				return _G[f.dataTable[1]][f.dataTable[2]][f.dataTable[3]][f.dataTable[4]]
			elseif #f.dataTable == 3 then
				return _G[f.dataTable[1]][f.dataTable[2]][f.dataTable[3]]
			elseif #f.dataTable == 2 then
				return _G[f.dataTable[1]][f.dataTable[2]]
			elseif #f.dataTable == 1 then
				return _G[f.dataTable[1]]
			end
		end
	end
end

local setDB = function(f, dv, value)
	if type(f) == "string" then
		f = _G[f]
	end
	if f.dataTable then
		if dv then
			if #f.dataTable == 4 then
				_G[f.dataTable[1]][f.dataTable[2]][f.dataTable[3]][f.dataTable[4]][dv] = value
			elseif #f.dataTable == 3 then
				_G[f.dataTable[1]][f.dataTable[2]][f.dataTable[3]][dv] = value
			elseif #f.dataTable == 2 then
				_G[f.dataTable[1]][f.dataTable[2]][dv] = value
			elseif #f.dataTable == 1 then
				_G[f.dataTable[1]][dv] = value
			end
		else
			if #f.dataTable == 4 then
				_G[f.dataTable[1]][f.dataTable[2]][f.dataTable[3]][f.dataTable[4]] = value
			elseif #f.dataTable == 3 then
				_G[f.dataTable[1]][f.dataTable[2]][f.dataTable[3]] = value
			elseif #f.dataTable == 2 then
				_G[f.dataTable[1]][f.dataTable[2]] = value
			elseif #f.dataTable == 1 then
				_G[f.dataTable[1]] = value
			end
		end
	end
end

local SetMinimapButtonPosition = function(self, angle, radius, rounding)
	if angle then
		setDB(self, "angle", angle)
	end
	if radius then
		setDB(self, "radius", angle)
	end
	if rounding then
		setDB(self, "rounding", angle)
	end
	self:UpdatePosition()
end

local UpdatePosition = function(self)
	GameTooltip:Hide()
	self.values.angle = getDB(self, "angle")
	self.values.radius = getDB(self, "radius")
	self.values.rounding = getDB(self, "rounding")
	rangle = rad(self.values.angle)
	x = cos(rangle)
	y = sin(rangle)
	q = 1
	if x < 0 then
		q = q + 1
	end
	if y > 0 then
		q = q + 2
	end
	if MinimapShapes[GetMinimapShape and GetMinimapShape() or "ROUND"][q] then
		x = x * self.values.radius
		y = y * self.values.radius
	else
		dradius = sqrt(2 * (self.values.radius) ^ 2) - self.values.rounding
		x = max(-self.values.radius, min(x * dradius, self.values.radius))
		y = max(-self.values.radius, min(y * dradius, self.values.radius))
	end
	self:SetPoint("CENTER", Minimap, "CENTER", x, y - 1)
end

local Toggle = function(self)
	if getDB(self, "show") then
		self:Show()
	else
		self:Hide()
	end
end

local OnMouseDown = function(self)
	self.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
end

local OnMouseUp = function(self)
	self.icon:SetTexCoord(0, 1, 0, 1)
end

local OnDragStart = function(self)
	if getDB(self, "dragable") then
		OnMouseUp(self)
		self.dragme = true
		self:LockHighlight()
		HideDropDownMenu(1)
		if LibStub("LibDropMenu-1.0", true) then
			LibStub("LibDropMenu-1.0"):CloseMenu(i)
		end
	end
end

local OnDragStop = function(self)
	OnMouseUp(self)
	self.dragme = nil
	self:UnlockHighlight()
end

local OnUpdate = function(self)
	if self.dragme then
		mx, my = Minimap:GetCenter()
		mz = MinimapCluster:GetScale()
		cx, cy = GetCursorPosition(UIParent)
		cz = UIParent:GetEffectiveScale()
		v = deg(atan2(cy / cz - my * mz, cx / cz - mx * mz))
		if v < 0 then
			v = v + 360
		elseif v > 360 then
			v = v - 360
		end
		self:SetMinimapButtonPosition(v)
	end
end

local OnEnter = function(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	if type(self.tooltipFunction) == "function" then
		self.tooltipFunction(self, GameTooltip)
	elseif self.tooltipFunction and self.owner[self.tooltipFunction] then
		self.owner[self.tooltipFunction](self, GameTooltip)
	end
	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local OnClick = function(self, button)
	if type(self.clickFunction) == "function" then
		self.clickFunction(self, button)
	elseif self.clickFunction and self.owner[self.clickFunction] then
		self.owner[self.clickFunction](self, button)
	end
end

function lib:CreateButton(owner, name, icon, angle, db1, db2, db3, db4)
	if self.buttons[owner] then return end
	local f = CreateFrame("Button", name, Minimap)
	if db1 and db2 and db3 and db4 then
		_G[db1] = _G[db1] or {}
		_G[db1][db2] = _G[db1][db2] or {}
		_G[db1][db2][db3] = _G[db1][db2][db3] or {}
		_G[db1][db2][db3][db4] = _G[db1][db2][db3][db4] or { show = true, dragable = true, angle = angle or 183, radius = 80, rounding = 10 }
		if not _G[db1][db2][db3][db4].angle or not _G[db1][db2][db3][db4].radius or not _G[db1][db2][db3][db4].rounding then
			_G[db1][db2][db3][db4] = { show = true, dragable = true, angle = angle or 183, radius = 80, rounding = 10 }
		end
		f.dataTable = { db1, db2, db3, db4 }
	elseif db1 and db2 and db3 then
		_G[db1] = _G[db1] or {}
		_G[db1][db2] = _G[db1][db2] or {}
		_G[db1][db2][db3] = _G[db1][db2][db3] or { show = true, dragable = true, angle = angle or 183, radius = 80, rounding = 10 }
		if not _G[db1][db2][db3].angle or not _G[db1][db2][db3].radius or not _G[db1][db2][db3].rounding then
			_G[db1][db2][db3] = { show = true, dragable = true, angle = angle or 183, radius = 80, rounding = 10 }
		end
		f.dataTable = { db1, db2, db3 }
	elseif db1 and db2 then
		_G[db1] = _G[db1] or {}
		_G[db1][db2] = _G[db1][db2] or { show = true, dragable = true, angle = angle or 183, radius = 80, rounding = 10 }
		if not _G[db1][db2].angle or not _G[db1][db2].radius or not _G[db1][db2].rounding then
			_G[db1][db2] = { show = true, dragable = true, angle = angle or 183, radius = 80, rounding = 10 }
		end
		f.dataTable = { db1, db2 }
	elseif db1 then
		_G[db1] = _G[db1] or { show = true, dragable = true, angle = angle or 183, radius = 80, rounding = 10 }
		if not _G[db1].angle or not _G[db1].radius or not _G[db1].rounding then
			_G[db1] = { show = true, dragable = true, angle = angle or 183, radius = 80, rounding = 10 }
		end
		f.dataTable = { db1 }
	end
	self.framelevel = self.framelevel + 1
	f.owner = owner
	f.values = {}
	f:SetFrameStrata("LOW")
	f:SetFrameLevel(self.framelevel)
	f:SetWidth(33)
	f:SetHeight(33)
	f:SetPoint("CENTER")
	f:EnableMouse(true)
	f:RegisterForClicks("AnyUp")
	f:RegisterForDrag("LeftButton", "RightButton")
	f:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	f:SetNormalTexture(icon)
	f.icon = f:GetNormalTexture()
	f.icon:SetWidth(18)
	f.icon:SetHeight(18)
	f.icon:ClearAllPoints()
	f.icon:SetPoint("CENTER", f, "CENTER", -1, 2)
	f.icon:SetTexCoord(0, 1, 0, 1)
	local t = f:CreateTexture(name.."Border", "OVERLAY")
	t:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	t:SetWidth(52)
	t:SetHeight(52)
	t:SetPoint("TOPLEFT", f, "TOPLEFT")
	f.SetMinimapButtonPosition = SetMinimapButtonPosition
	f.UpdatePosition = UpdatePosition
	f.Toggle = Toggle
	f:SetScript("OnDragStart", OnDragStart)
	f:SetScript("OnDragStop", OnDragStop)
	f:SetScript("OnUpdate", OnUpdate)
	f:SetScript("OnMouseDown", OnMouseDown)
	f:SetScript("OnMouseUp", OnMouseUp)
	f:UpdatePosition()
	f:Toggle()
	self.buttons[owner] = f
	if type(owner.OnClick) == "function" then
		self:SetClick(owner, "OnClick")
	end
	if type(owner.OnTooltip) == "function" then
		self:SetTooltip(owner, "OnTooltip")
	end
end

function lib:SetTooltip(owner, method)
	if self.buttons[owner] then
		self.buttons[owner].tooltipFunction = method
		self.buttons[owner]:SetScript("OnEnter", OnEnter)
		self.buttons[owner]:SetScript("OnLeave", OnLeave)
	end
end

function lib:SetClick(owner, method)
	if self.buttons[owner] then
		self.buttons[owner].clickFunction = method
		self.buttons[owner]:SetScript("OnClick", OnClick)
	end
end

function lib:GetButton(owner)
	return self.buttons[owner]
end
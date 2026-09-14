-- Deterministic Lua 5.1 test double, not a WoW renderer or a server.
MOCK = { frames = {}, sent = {}, hooks = {}, shift = false, selection = 1, quests = {}, objectives = {} }
local methods = {}
local function run(frame, event, ...)
    if frame.scripts[event] then frame.scripts[event](frame, ...) end
    for _, fn in ipairs(frame.hooks[event] or {}) do fn(frame, ...) end
end
local function new(kind, name, parent, template)
    local frame = setmetatable({ kind=kind, name=name, parent=parent, template=template, children={}, regions={}, scripts={}, hooks={}, events={}, points={}, shown=true, enabled=true, width=0, height=0, scale=1, level=1, text="" }, { __index=methods })
    if parent then parent.children[#parent.children+1]=frame end
    if name then _G[name]=frame end
    MOCK.frames[#MOCK.frames+1]=frame
    if template == "UIPanelButtonTemplate" then
        frame.fontString=new("FontString", nil, nil); frame.fontString.owner=frame
        frame.fontString:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.regions[#frame.regions+1]=frame.fontString
    end
    return frame
end
CreateFrame = new
function EnumerateFrames(previous)
    local nextIndex=1
    if previous then for i,f in ipairs(MOCK.frames) do if f==previous then nextIndex=i+1; break end end end
    for i=nextIndex,#MOCK.frames do local f=MOCK.frames[i]; if f.kind~="Texture" and f.kind~="FontString" then return f end end
end
function methods:GetName() return self.name end
function methods:SetID(id) self.id=id end
function methods:GetID() return self.id or 0 end
function methods:GetObjectType() return self.kind end
function methods:IsObjectType(kind) return self.kind==kind or (kind=="Button" and self.kind=="CheckButton") or (kind=="Frame" and self.kind~="Texture" and self.kind~="FontString") end
function methods:GetParent() return self.parent end
function methods:SetParent(parent)
    if self.parent then for i,f in ipairs(self.parent.children) do if f==self then table.remove(self.parent.children,i); break end end end
    self.parent=parent; if parent then parent.children[#parent.children+1]=self end
end
function methods:GetChildren() return unpack(self.children) end
function methods:GetRegions() return unpack(self.regions) end
function methods:CreateFontString(name, layer, template)
    local f=new("FontString", name, nil, template); f.owner=self; self.regions[#self.regions+1]=f; return f
end
function methods:CreateTexture(name, layer)
    local f=new("Texture", name, nil); f.owner=self; self.regions[#self.regions+1]=f; return f
end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetScale(v) self.scale=v end
function methods:GetScale() return self.scale end
function methods:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:SetFrameStrata(v) self.strata=v end
function methods:GetFrameStrata() return self.strata or "MEDIUM" end
function methods:SetFrameLevel(v) self.level=v end
function methods:GetFrameLevel() return self.level end
function methods:SetPoint(point,relative,relativePoint,x,y)
    if type(relative)=="number" then x,y=relative,relativePoint; relative=self.parent or self.owner; relativePoint=point end
    if type(relative)=="string" then relative=_G[relative] end
    if relative==nil then relative=self.parent or self.owner or UIParent end
    self.points[#self.points+1]={point,relative,relativePoint or point,x or 0,y or 0}
end
function methods:GetPoint(i) return unpack(self.points[i or 1] or {}) end
function methods:ClearAllPoints() self.points={} end
function methods:SetAllPoints(frame) self.allPoints=frame or self.parent or self.owner end
function methods:GetCenter() return self.mockX or 800,self.mockY or 500 end
function methods:GetLeft() return self.mockLeft or 50 end
function methods:GetRight() return self.mockRight or 700 end
function methods:EnableKeyboard(value) self.keyboardEnabled=value end
function methods:GetBottom() return self.mockBottom or 0 end
function methods:GetTop() return self.mockTop or 900 end
function methods:Show() if not self.shown then self.shown=true; run(self,"OnShow") end end
function methods:Hide() if self.shown then self.shown=false; run(self,"OnHide") end end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:SetScript(name, fn) self.scripts[name]=fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:HookScript(name, fn) self.hooks[name]=self.hooks[name] or {}; table.insert(self.hooks[name],fn) end
function methods:RegisterEvent(event) self.events[event]=true end
function methods:UnregisterEvent(event) self.events[event]=nil end
function methods:UnregisterAllEvents() self.events={} end
function methods:IsEventRegistered(event) return self.events[event] end
function methods:RegisterAllEvents() end
function methods:SetText(value) self.text=tostring(value or ""); if self.fontString then self.fontString.text=self.text end; if self.kind=="EditBox" then run(self,"OnTextChanged",false) end end
function methods:GetText() return self.text end
function methods:GetFontString() return self.fontString end
function methods:GetStringHeight() return math.max(14,math.ceil(#self.text/math.max(1,self.width/7))*14) end
function methods:GetStringWidth() return #self.text*7 end
function methods:SetFontObject(value) self.fontObject=value end
function methods:SetFont(path,size,flags) self.font={path,size,flags}; return true end
function methods:GetFont() return "Fonts\\FRIZQT__.TTF",12,"" end
function methods:SetTextColor(...) self.textColor={...} end
function methods:SetJustifyH(value) self.justifyH=value end
function methods:SetJustifyV(value) self.justifyV=value end
function methods:SetBackdrop(value) self.backdrop=value end
function methods:SetBackdropColor(...) self.color={...} end
function methods:SetBackdropBorderColor(...) self.borderColor={...} end
function methods:SetTexture(...) self.texture={...} end
function methods:GetTexture() return self.texture and self.texture[1] end
function methods:SetTexCoord(...) self.texCoord={...} end
for _, key in ipairs({"Normal","Pushed","Highlight","Disabled","Checked","DisabledChecked"}) do
    methods["Set"..key.."Texture"]=function(self,value) self[key.."Texture"]=new("Texture",nil,nil); self[key.."Texture"]:SetTexture(value) end
    methods["Get"..key.."Texture"]=function(self) return self[key.."Texture"] end
end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:IsEnabled() return self.enabled end
function methods:SetChecked(value) self.checked=value end
function methods:GetChecked() return self.checked end
function methods:SetFocus() self.focus=true; run(self,"OnEditFocusGained") end
function methods:ClearFocus() self.focus=false; run(self,"OnEditFocusLost") end
function methods:HasFocus() return self.focus and true or false end
function methods:SetScrollChild(value) self.scrollChild=value end
function methods:GetScrollChild() return self.scrollChild end
function methods:SetVerticalScroll(value) self.scroll=value end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetVerticalScrollRange() return 0 end
function methods:Click(mouse) if self.enabled then run(self,"OnClick",mouse or "LeftButton") end end
function methods:SetAttribute(key,value) self[key]=value end
function methods:GetAttribute(key) return self[key] end
function methods:SetOwner(value) self.tooltipOwner=value end
function methods:AddLine(value) self.text=self.text.."\n"..value end
function methods:AddMessage(value) end
for _,name in ipairs({"SetAutoFocus","SetTextInsets","SetMaxLetters","SetNumeric","SetMultiLine","SetHitRectInsets","SetClampedToScreen","EnableMouse","EnableMouseWheel","SetMovable","RegisterForDrag","RegisterForClicks","Raise","StartMoving","StopMovingOrSizing","SetVertexColor","SetBlendMode","SetAlpha","SetToplevel","SetFrameStrata","SetResizable","SetMinResize","SetMaxResize","SetNormalFontObject","SetHighlightFontObject","SetDisabledFontObject","SetButtonState","SetValueStep","SetMinMaxValues","HighlightText","SetShadowColor","SetShadowOffset","SetDrawLayer","SetFormattedText","SetSpacing","SetFading","SetUserPlaced"}) do
    if not methods[name] then methods[name]=function(self,...) self[name.."Value"]={...} end end
end
function methods:IsToplevel() return false end
function MOCK:Fire(event,...)
    local frames={unpack(self.frames)}
    for _,frame in ipairs(frames) do if frame.events[event] then run(frame,"OnEvent",event,...) end end
end
function MOCK:Tick(delta)
    local frames={unpack(self.frames)}
    for _,frame in ipairs(frames) do if frame:IsVisible() and frame.scripts.OnUpdate then run(frame,"OnUpdate",delta) end end
end
function MOCK:Input(frame,text) frame.text=text; run(frame,"OnTextChanged",true) end
function MOCK:ResetSent() self.sent={} end
UIParent=new("Frame","UIParent"); UIParent:SetSize(1920,1080)
GameTooltip=new("Frame","GameTooltip",UIParent); GameTooltip:Hide()
DEFAULT_CHAT_FRAME=new("Frame","DEFAULT_CHAT_FRAME",UIParent)
Minimap=new("Frame","Minimap",UIParent); Minimap:SetSize(140,140)
GameFontNormal="GameFontNormal"; GameFontNormalLarge="GameFontNormalLarge"; GameFontHighlightSmall="GameFontHighlightSmall"; ChatFontNormal="ChatFontNormal"
UISpecialFrames={}; SlashCmdList={}; StaticPopupDialogs={}; YES="Yes"; NO="No"; ACCEPT="Accept"; CANCEL="Cancel"; OKAY="OK"
function GetLocale() return "koKR" end
function GetTime() return 1 end
function GetBuildInfo() return "test", "12340", "", 30300 end
function UnitExists(unit) return unit=="player" or (unit=="target" and MOCK.target~=nil) end
function UnitName(unit) return unit=="player" and "TestGM" or MOCK.target end
function UnitIsPlayer(unit) return unit=="player" or MOCK.targetIsPlayer or false end
function UnitIsUnit(a,b) return a==b or (a=="target" and b=="player" and MOCK.target=="TestGM") end
function UnitLevel() return 80 end
function UnitClass() return "Mage","MAGE" end
function UnitFactionGroup() return "Alliance" end
function UnitIsDeadOrGhost() return false end
function UnitIsDead() return false end
function UnitIsGhost() return false end
function IsShiftKeyDown() return MOCK.shift end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end
function InCombatLockdown() return false end
function ReloadUI() MOCK.reloaded=true end
function SendChatMessage(text,channel,language,target) MOCK.sent[#MOCK.sent+1]={text,channel,target} end
function StaticPopup_Show(key,a,b,data) MOCK.popup={key=key,a=a,b=b,data=data}; return new("Frame",nil,UIParent) end
function StaticPopup_Hide(key) if MOCK.popup and MOCK.popup.key==key then MOCK.popup=nil end end
function GetQuestLogSelection() return MOCK.selection end
function GetQuestLogTitle(i)
    local q=MOCK.quests[i]; if not q then return nil end
    return q.title,q.level,q.tag,q.group,q.header,q.collapsed,q.complete,q.daily,q.id
end
function GetQuestLink(i) local q=MOCK.quests[i]; return q and "|Hquest:"..q.id..":80|h["..q.title.."]|h" end
function GetNumQuestLogEntries() return #MOCK.quests,#MOCK.quests end
function GetNumQuestLeaderBoards(i) return #(MOCK.objectives[i] or {}) end
function GetQuestLogLeaderBoard(i,q) local row=(MOCK.objectives[q] or {})[i]; if row then return row[1],row[2],row[3] end end
function SelectQuestLogEntry(i) MOCK.selection=i end
function QuestLog_SetSelection(i) SelectQuestLogEntry(i) end
function QuestLog_Update() end
function hooksecurefunc(owner,name,fn)
    if type(owner)=="string" then fn=name; name=owner; owner=_G end
    local original=owner[name]; assert(type(original)=="function",name)
    owner[name]=function(...) local result={original(...)}; fn(...); return unpack(result) end
    MOCK.hooks[name]=(MOCK.hooks[name] or 0)+1
end
function methods:GetNumPoints() return #self.points end
MOCK.bindings={W="MOVEFORWARD",SPACE="JUMP"}; MOCK.overrides={}
function GetBindingAction(key) return MOCK.bindings[key] or "" end
function SetOverrideBinding(owner,priority,key,action) MOCK.overrides[key]=action end
function ClearOverrideBindings(owner) MOCK.overrides={} end
function InCombatLockdown() return MOCK.combat or false end
function GetCurrentKeyBoardFocus() return MOCK.keyboardFocus end

function methods:UnlockHighlight() self.highlightLocked=false end
function methods:LockHighlight() self.highlightLocked=true end

function methods:SetPropagateKeyboardInput(v) self.propagates=v end
function SetOverrideBindingClick(owner,priority,key,name,button) MOCK.overrides[key]='CLICK '..name..':'..button end
function GetBindingKey(action) local keys={};for k,v in pairs(MOCK.bindings) do if v==action then keys[#keys+1]=k end end;return unpack(keys) end

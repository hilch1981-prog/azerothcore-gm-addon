from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]

def full_runtime(kind, prelude=None):
    folder=ROOT/"GMminibar"
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT/'tests/wow_mock.lua').read_text(encoding='utf-8'))
    lua.execute('''
        function getglobal(name) return _G[name] end
        time=os.time; date=os.date
        tinsert=table.insert; tremove=table.remove; wipe=function(t) for k in pairs(t) do t[k]=nil end; return t end
        strlower=string.lower; strupper=string.upper; strfind=string.find; strformat=string.format; strmatch=string.match; format=string.format; floor=math.floor; ceil=math.ceil
        strsub=string.sub; strlen=string.len; gsub=string.gsub; max=math.max; min=math.min
        function strsplit(delimiter,text) local out={}; for part in string.gmatch(text,"[^"..delimiter.."]+") do out[#out+1]=part end; return unpack(out) end
        function GetCVar(name) return "1" end
        function GetRealmName() return "Test Realm" end
        function IsLoggedIn() return true end
        function GetAddOnMetadata(name,key) return "Test" end
        function GetNumAddOns() return 0 end
        function GetSpellInfo(id) return "Spell "..tostring(id),"","Interface\\\\Icons\\\\INV_Misc_QuestionMark" end
        function GetItemInfo(id) return nil end
        function GetNumSkillLines() return 0 end
        function GetNumTradeSkills() return 0 end
        function GetNumCrafts() return 0 end
        function IsAddOnLoaded(name) return false end
        function GetInventorySlotInfo() return 1 end
        function GetItemCount() return 0 end
        function UnitGUID() return "0x0000000000000001" end
        function GetGuildInfo() return nil end
        function GetNumPartyMembers() return 0 end
        function GetNumRaidMembers() return 0 end
        function GetNumGroupMembers() return 0 end
        function GetNumQuestItemDrops() return 0 end
        function GetCurrentMapContinent() return 1 end
        function GetCurrentMapZone() return 1 end
        function GetMapContinents() return "Kalimdor","Eastern Kingdoms","Outland","Northrend","Pandaria" end
        function GetMapZones() return "Test Zone" end
        function GetScreenWidth() return 1920 end
        function GetScreenHeight() return 1080 end
        function GetMouseFocus() return UIParent end
        function GetCursorPosition() return 400,400 end
        function PlaySound() end
        function UnitRace() return "Human","Human" end
        function GetPlayerInfoByGUID() return "Mage","MAGE","Human","Human",2,"TestGM","TestRealm" end
        function GetQuestDifficultyColor() return {r=1,g=1,b=0} end
        function QuestLogPushQuest() end
        ITEM_QUALITY_COLORS={}
        for i=0,7 do ITEM_QUALITY_COLORS[i]={r=1,g=1,b=1,hex="|cffffffff"} end
        RAID_CLASS_COLORS={MAGE={r=1,g=1,b=1}}; NORMAL_FONT_COLOR={r=1,g=0.82,b=0}; HIGHLIGHT_FONT_COLOR={r=1,g=1,b=1}
        table.wipe=wipe
        WorldFrame=CreateFrame("Frame","WorldFrame",UIParent)
        GameTooltipTextLeft1=GameTooltip:CreateFontString("GameTooltipTextLeft1")
        ERR_SPELL_UNLEARNED_S="You have unlearned %s."; ERR_LEARN_RECIPE_S="You have learned %s."; ERR_LEARN_SPELL_S="You have learned a new spell: %s."; ERR_LEARN_ABILITY_S="You have learned a new ability: %s."
    ''')
    if prelude: lua.execute(prelude)
    entries=[s.strip() for s in (folder/(folder.name+'.toc')).read_text(encoding='utf-8-sig').splitlines() if s.strip() and not s.startswith('#')]
    def load_file(p):
        if p.suffix=='.xml':
            import xml.etree.ElementTree as ET
            tree=ET.parse(p)
            for element in tree.iter():
                name=element.attrib.get('file')
                if name: load_file(p.parent/name.replace('\\','/'))
        else:
            try:
                chunk=lua.eval('function(s,name) return assert(loadstring(s,name)) end')(p.read_bytes().removeprefix(b'\xef\xbb\xbf'),'@'+p.relative_to(folder).as_posix())
                chunk('AzerothAdmin',lua.table())
            except Exception as exc: raise RuntimeError(f'LOADING {p.relative_to(folder)}: {exc}') from exc
    for item in entries: load_file(folder/item.replace('\\','/'))
    # The recursive loader closes over itself and the complete Lua VM. Clear
    # its cell after loading so repeated tests release each VM immediately.
    del load_file
    lua.execute('MOCK:Fire("ADDON_LOADED","'+'GMminibar'+'"); MOCK:Fire("PLAYER_LOGIN")')
    lua.execute('A=' + 'AzerothAdminAC335')
    lua.execute('W=A.Workbench; D=A.WorkbenchAdapter; C=A.WorkbenchCatalog; B=A.QuestLogBridge')
    return lua

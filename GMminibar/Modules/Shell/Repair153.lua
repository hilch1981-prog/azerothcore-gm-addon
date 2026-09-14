local A=AzerothAdminAC335
function A:ToggleGMMode()
 local db=self:GetDB();local value=not db.gmMode
 local ok=self:SendCommand('.gm '..(value and 'on' or 'off'))
 if ok then db.gmMode=value;self:Print(self:L('GM_MODE_REQUESTED',value and 'ON' or 'OFF'))end
 self:RefreshToolbarStates();return ok
end
function A:IsUnsafeQuestTarget(target)
 if self.interface~=30300 or not target then return false end
 -- Crash #132 persisted after changing addons at this exact NPC position.
 -- Block the reported target until the client/world problem is diagnosed.
 if target.k=='c' and tonumber(target.e)==5413 then return true end
 return tonumber(target.m)==0 and target.x and target.y and math.abs(target.x+8427)<20 and math.abs(target.y-600.092)<20
end
local B,D=A.QuestLogBridge,A.WorkbenchAdapter
function B:FindCondition()
 self.partyMove=nil
 local quest=D:SelectedQuest();if not quest then return end
 if self.conditionQuest~=quest.id then self.conditionQuest=quest.id;self.conditionIndex=0 end
 local objectives=A:GetQuestObjectives(quest) or {};local destinations={}
 for _,obj in ipairs(objectives)do
  if obj.targets and #obj.targets>0 then
   for _,target in ipairs(obj.targets)do destinations[#destinations+1]={objective=obj,target=target}end
  elseif obj.type=='item' or obj.type=='drop' then
   local sources=A.GetQuestItemDropSources and A:GetQuestItemDropSources(obj) or {}
   for _,source in ipairs(sources)do destinations[#destinations+1]={objective=obj,source=source}end
  elseif obj.type=='dialogue' or obj.type=='interact' then
   destinations[#destinations+1]={finish=true}
  elseif A.QuestObjectiveCanMove and A:QuestObjectiveCanMove(obj) then destinations[#destinations+1]={objective=obj}end
 end
 if #destinations==0 then A:Print(A:L('QUEST_LOCATION_UNAVAILABLE'),true);return false end
 self.conditionIndex=(self.conditionIndex or 0)%#destinations+1;local dest=destinations[self.conditionIndex]
 A.questHelperSelectedQuestID=quest.id
 if dest.target then return A:GoToQuestTarget(dest.target,dest.objective.description or '')
 elseif dest.source then return A:SendCommand((dest.source.type=='object' and '.go gameobject id ' or '.go creature id ')..dest.source.id)
 elseif dest.finish then return D:QuestAction('finish',quest)
 else return B:ObjectiveAction('move',dest.objective)end
end

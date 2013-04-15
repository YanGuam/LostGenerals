--[[
  扩展包信息
	全称：“失落的三将”扩展武将测试之蜀III包
	名称：蜀III包（shu003）
	武将：共1名
		关平（血战、义志）
	版本号：20130224
]]--
module("extensions.shu003", package.seeall)
extension = sgs.Package("shu003")

sgs.LoadTranslationTable{
	["shu003"] = "蜀III包" ,
	
	["Shu003_Guanping"] = "关平",
	["&Shu003_Guanping"] = "关平",
	["#Shu003_Guanping"] = "将门长子",
	["designer:Shu003_Guanping"] = "待查",
	["cv:Shu003_Guanping"] = "无",
	["illustrator:Shu003_Guanping"] = "待查",
	
	["Shu003_Xuezhan"] = "血战" ,
	[":Shu003_Xuezhan"] = "出牌阶段，你使用【杀】可以额外指定攻击范围内X名角色，X为你已损失体力值。 " ,
	
	["Shu003_Yizhi"] = "义志" ,
	[":Shu003_Yizhi"] = "<b>觉醒技</b>，回合开始阶段，若你装备区有武器牌，须按此武器牌的攻击范围执行如下：攻击范围少于3，则你增加1点体力上限，回复1点体力，并永久失去技能\"血战\"及获得技能\"武裔\"（锁定技，你使用的红色【杀】无距离限制）；攻击范围不少于3，则你减少1点体力上限，并永久获得技能\"义从\"。" ,
	
	["Shu003_Wuyi"] = "武裔" ,
	[":Shu003_Wuyi"] = "<b>锁定技</b>，你使用的红色【杀】无距离限制" ,
}

Shu003_Guanping = sgs.General(extension, "Shu003_Guanping", "shu")

Shu003_Xuezhan = sgs.CreateTargetModSkill{
	name = "Shu003_Xuezhan" ,
	pattern = "Slash" ,
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return player:getLostHp()
		end
	end
}

Shu003_Wuyi = sgs.CreateTargetModSkill{
	name = "Shu003_Wuyi" ,
	--pattern = "Slash" ,
	distance_limit_func = function(self, from, card)
		if from:hasSkill(self:objectName()) then
			if card:isKindOf("Slash") or card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash") then
				if card:isRed() then return 1000 end
			end
		end 
		return 0
	end 
}

Shu003_Yizhi = sgs.CreateTriggerSkill{
	name = "Shu003_Yizhi" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.GameStart, sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:setTag("YizhiInvoked", sgs.QVariant(0))
			return
		end
		if player:getPhase() ~= sgs.Player_Start then return end
		if room:getTag("YiZhiInvoked"):toInt() ~= 0 then return end
		if not player:getWeapon() then return end
		local ar = player:getAttackRange()
		if ar < 3 then
			local maxhp = player:getMaxHp()
			maxhp = maxhp + 1
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
			local rs = sgs.RecoverStruct()
			rs.recover = 1
			rs.who = player
			rs.card = nil
			room:recover(player, rs)
			room:detachSkillFromPlayer(player, "Shu003_Xuezhan")
			room:acquireSkill(player, Shu003_Wuyi)
		else
			room:loseMaxHp(player)
			room:acquireSkill(player, "yicong")
		end
		room:setTag("YiZhiInvoked", sgs.QVariant(1))
	end,
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Shu003_Wuyi") then skills:append(Shu003_Wuyi) end
sgs.Sanguosha:addSkills(skills)


Shu003_Guanping:addSkill(Shu003_Xuezhan)
Shu003_Guanping:addSkill(Shu003_Yizhi)
--Shu003_Guanping:addSkill(Shu003_Wuyi)

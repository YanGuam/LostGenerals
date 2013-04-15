--[[
  扩展包信息
	全称：“失落的三将”扩展武将测试之魏I包
	名称：群III包（qun003）
	武将：共1名
		李儒（焚城、鸩酒）
	版本号：20130224
]]--
module("extensions.qun003", package.seeall)
extension = sgs.Package("qun003")

sgs.LoadTranslationTable{
	["qun003"] = "群III包" ,
	
	["Qun003_Liru"] = "李儒",
	["&Qun003_Liru"] = "李儒",
	["#Qun003_Liru"] = "毒之化身",
	["designer:Qun003_Liru"] = "待查",
	["cv:Qun003_Liru"] = "无",
	["illustrator:Qun003_Liru"] = "待查",
	
	["Qun003_Fencheng"] = "焚城" ,
	[":Qun003_Fencheng"] = "出牌阶段，你可以弃置一张手牌，对至多两名角色各依次造成1点火焰伤害，然后令该两名角色依次回复1点体力值，每阶段限一次。 " ,
	
	["Qun003_Zhenjiu"] = "鸩酒" ,
	[":Qun003_Zhenjiu"] = "你每受到一次伤害，可以令当前回合角色视为使用一张【酒】（不计入回合限制），然后直到回合结束时，若当前回合角色未再造成伤害，则其流失1点体力值。" ,
	["#Qun003_ZhenjiuLostHp"] = "鸩酒" ,
}

Qun003_Liru = sgs.General(extension, "Qun003_Liru", "qun", 3)
-- 出牌阶段，你可以弃置一张手牌，对至多两名角色各依次造成1点火焰伤害，然后令该两名角色依次回复1点体力值，每阶段限一次。 
Qun003_FenchengCard = sgs.CreateSkillCard{
	name = "Qun003_Fencheng" ,
	target_fixed = false ,
	will_throw = true ,
	filter = function(self, targets, to_select)
		return #targets < 2
	end ,
	on_use = function(self, room, source, targets)
		room:writeToConsole("FenchengInvoked")
		local thedamage = sgs.DamageStruct()
		thedamage.from = source
		thedamage.to = targets[1]
		thedamage.card = nil
		thedamage.damage = 1
		thedamage.nature = sgs.DamageStruct_Fire 
		room:damage(thedamage)
		if #targets == 2 then
			thedamage.to = targets[2]
			room:damage(thedamage)
		end
		local therecover = sgs.RecoverStruct()
		therecover.recover = 1
		therecover.who = source
		therecover.card = nil
		if(targets[1]:isAlive()) then
			room:recover(targets[1], therecover)
		end
		if #targets == 2 then
			if(targets[2]:isAlive()) then
				room:recover(targets[2], therecover)
			end
		end
	end
}
Qun003_Fencheng = sgs.CreateViewAsSkill{
	name = "Qun003_Fencheng" ,
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 1 then return false end
		return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = Qun003_FenchengCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end ,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#Qun003_Fencheng")
	end
}
--你每受到一次伤害，可以令当前回合角色视为使用一张【酒】（不计入回合限制），然后直到回合结束时，若当前回合角色未再造成伤害，则其流失1点体力值。
Qun003_Zhenjiu = sgs.CreateTriggerSkill{
	name = "Qun003_Zhenjiu" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.from then return end
		if not player:askForSkillInvoke(self:objectName()) then return end
		local alcohol = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		local carduse = sgs.CardUseStruct()
		carduse.card = alcohol
		carduse.from = damage.from
		room:useCard(carduse)
		room:setPlayerFlag(damage.from, "ZhenJiuInvoked")
	end
}
Qun003_ZhenjiuLoseHp = sgs.CreateTriggerSkill{
	name = "#Qun003_ZhenjiuLoseHp" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.Damage, sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			room:setPlayerFlag(player, "-ZhenJiuInvoked")
			return
		end
		if player:getPhase() ~= sgs.Player_Finish then return end
		room:loseHp(player)
	end, 
	can_trigger = function(self, target)
		return target:hasFlag("ZhenJiuInvoked")
	end
}

Qun003_Liru:addSkill(Qun003_Fencheng)
Qun003_Liru:addSkill(Qun003_Zhenjiu)
Qun003_Liru:addSkill(Qun003_ZhenjiuLoseHp)
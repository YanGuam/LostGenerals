--[[
	扩展包信息
	全称：“失落的三将”扩展武将测试之魏V包
	名称：魏V包（wei005）
	武将：共1名
		满宠（严法、协守、拜军）
	版本号：20130224
]]--
module("extensions.wei005", package.seeall)
extension = sgs.Package("wei005")
--[[满宠]]--
Wei005_Manchong = sgs.General(extension, "Wei005_Manchong", "wei", "3")
--[[技能暗将]]--
Wei005_SkillAnjiang = sgs.General(extension, "Wei005_SkillAnjiang", "god", "5", true, true, true)
--[[
	技能：严法（锁定技）
	描述：你使用的非延时类锦囊牌不可被体力值大于你的角色的牌所响应。
	状态：已完成，未验证
]]--
Wei005_Yanfa = sgs.CreateTriggerSkill{ 
	name = "Wei005_Yanfa", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.TargetConfirmed, sgs.CardFinished}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local use = data:toCardUse()
		local trick = use.card
		if trick and trick:isNDTrick() then
			local source = use.from
			if source and source:isAlive() then
				if source:hasSkill(self:objectName()) then
					local targets = use.to
					if event == sgs.TargetConfirmed then
						local flag = false
						if player:getHp() > source:getHp() then
							for _,target in sgs.qlist(targets) do
								if target:objectName() == player:objectName() then
									flag = true
									break
								end
							end
						end
						if flag then
							room:setPlayerFlag(player, "YanfaTarget")
							room:setPlayerCardLimitation(player, "use,response", ".|.|.|hand", true)
							room:setPlayerCardLimitation(player, "use,response", ".|.|.|equip", true)
						end
					elseif event == sgs.CardFinished then
						if player:hasFlag("YanfaTarget") then
							room:removePlayerCardLimitation(player, "use,response", ".|.|.|equip$1")
							room:removePlayerCardLimitation(player, "use,response", ".|.|.|hand$1")
							room:setPlayerFlag("-YanfaTarget")
						end
					end
				end
			end
		end
	end, 
	can_trigger = function(self, target) 
		return target
	end
}
--[[
	技能：协守
	描述：出牌阶段，你可以令一名有手牌的角色须交给你至少X张手牌，然后你交个其等量的牌。若该角色不如此做，你获得其一张牌，每阶段限制一次。（X为你已损失的体力值）
	状态：已完成，尚未验证
]]--
Wei005_XieshouDummyCard = sgs.CreateSkillCard{ 
	name = "Wei005_XieshouDummyCard", 
	target_fixed = true, 
	will_throw = false, 
}
Wei005_XieshouVS = sgs.CreateViewAsSkill{ 
	name = "Wei005_XieshouVS", 
	n = 999, 
	view_filter = function(self, selected, to_select) 
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards >= sgs.Self:getMark("XieshouCount") then
			local card = Wei005_XieshouDummyCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end, 
	enabled_at_play = function(self, player) 
		return false
	end, 
	enabled_at_response = function(self, player, pattern) 
		return pattern == "@@Wei005_Xieshou"
	end
}
Wei005_SkillAnjiang:addSkill(Wei005_XieshouVS)
Wei005_XieshouCard = sgs.CreateSkillCard{ 
	name = "Wei005_XieshouCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return not to_select:isKongcheng()
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		local lost = source:getLostHp()
		room:setPlayerMark(target, "XieshouCount", lost)
		room:attachSkillToPlayer(target, "Wei005_XieshouVS")
		local ai_data = sgs.QVariant()
		ai_data:setValue(source)
		local dummy = room:askForCard(target, "@@Wei005_Xieshou", "@Wei005_Xieshou", ai_data)
		room:detachSkillFromPlayer(target, "Wei005_XieshouVS")
		if dummy then
			local count = dummy:subcardsLength()
			local prompt = "@Xieshou-exchange"
			local card = room:askForExchange(source, self:objectName(), count, true, prompt, false)
			room:obtainCard(target, card, false)
		else
			local card = room:askForCardChosen(source, target, "he", self:objectName())
			room:obtainCard(source, card, false)
		end
		room:setPlayerMark(target, "XieshouCount", 0)
	end
}
Wei005_Xieshou = sgs.CreateViewAsSkill{ 
	name = "Wei005_Xieshou", 
	n = 0, 
	view_as = function(self, cards) 
		return Wei005_XieshouCard:clone()
	end, 
	enabled_at_play = function(self, player) 
		return not player:hasUsed("#Wei005_XieshouCard")
	end
}
--[[
	技能：拜军（觉醒技）
	描述：回合结束阶段开始时，若你在所有其他角色的攻击范围内，你须加1点体力上限并回复1点体力，然后失去技能“严法”。
	状态：已完成，未验证
]]--
Wei005_Baijun = sgs.CreateTriggerSkill{ 
	name = "Wei005_Baijun", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data) 
		local siblings = player:getSiblings()
		local flag = true
		for _,p in sgs.qlist(siblings) do
			if not p:inMyAttackRange(player) then
				flag = false
				break
			end
		end
		if flag then
			local maxhp = player:getMaxHp() + 1
			local room = player:getRoom()
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
			local recover = sgs.RecoverStruct()
			recover.who = player
			recover.recover = 1
			room:recover(player, recover)
			room:detachSkillFromPlayer(player, "Wei005_Yanfa")
			player:gainMark("@waked", 1)
		end
	end, 
	can_trigger = function(self, target) 
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Finish then
					return target:getMark("BaijunInvoked") == 0
				end
			end
		end
		return false
	end
}
--[[添加技能]]--
Wei005_Manchong:addSkill(Wei005_Yanfa)
Wei005_Manchong:addSkill(Wei005_Xieshou)
Wei005_Manchong:addSkill(Wei005_Baijun)
--[[翻译表]]--
sgs.LoadTranslationTable{
    ["wei005"] = "魏V包",
	
	["Wei005_Manchong"] = "满宠",
	["&Wei005_Manchong"] = "满宠",
	["#Wei005_Manchong"] = "文臣武将",
	["designer:Wei005_Manchong"] = "キ狐fツx狸ネ",
	["cv:Wei005_Manchong"] = "无",
	["illustrator:Wei005_Manchong"] = "待查",
	
	["Wei005_Yanfa"] = "严法",
	[":Wei005_Yanfa"] = "<b>锁定技</b>, 你使用的非延时类锦囊牌不可被体力值大于你的角色的牌所响应。",
	
	["Wei005_Xieshou"] = "协守",
	[":Wei005_Xieshou"] = "出牌阶段，你可以令一名有手牌的角色须交给你至少X张手牌，然后你交个其等量的牌。若该角色不如此做，你获得其一张牌，每阶段限制一次。（X为你已损失的体力值）",
	["Wei005_XieshouCard"] = "协守",
	["Wei005_XieshouVS"] = "协守",
	["Wei005_XieshouDummyCard"] = "协守",
	["@Wei005_Xieshou"] = "请交出至少X张手牌！",
	["~Wei005_Xieshou"] = "选择一些手牌->点击“确定”。",
	["@Xieshou-exchange"] = "请选择用于交换的牌（包括装备）。",
	
	["Wei005_Baijun"] = "拜军",
	[":Wei005_Baijun"] = "<b>觉醒技</b>, 回合结束阶段开始时，若你在所有其他角色的攻击范围内，你须加1点体力上限并回复1点体力，然后失去技能“严法”。",
}
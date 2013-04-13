--[[
	扩展包信息
	全称：“失落的三将”扩展武将测试之魏II包
	名称：魏II包（wei002）
	武将：共1名
		曹冲（重衡、继嗣）
	版本号：20130224
]]--
module("extensions.lost2013", package.seeall)
extension = sgs.Package("lost2013")
--[[曹冲]]--
Wei002_Caochong = sgs.General(extension, "Wei002_Caochong", "wei", "3")
--[[
	技能：重衡
	描述：出牌阶段，你可以将你的武将牌翻面，令一名角色弃置其所有牌并摸等量的牌，每阶段限一次。
]]--
Wei002_ChonghengCard = sgs.CreateSkillCard{ 
	name = "Wei002_ChonghengCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return #targets == 0
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		source:turnOver()
		local count = target:getCardCount(true)
		target:throwAllHandCardsAndEquips()
		room:drawCards(target, count, self:objectName())
	end
}
Wei002_Chongheng = sgs.CreateViewAsSkill{ 
	name = "Wei002_Chongheng", 
	n = 0, 
	view_as = function(self, cards) 
		return Wei002_ChonghengCard:clone()
	end, 
	enabled_at_play = function(self, player) 
		return not player:hasUsed("#Wei002_ChonghengCard")
	end
}
--[[
	技能：继嗣
	描述：每当你受到伤害时，你可以跟伤害来源交换武将牌状态；每当你的武将牌状态改变时，你可以摸一张牌。
	FAQ：武将牌状态有四种：横置、竖置、正面朝上、背面朝上。
]]--
Wei002_Jisi = sgs.CreateTriggerSkill{ 
	name = "Wei002_Jisi", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged, sgs.TurnedOver, sgs.ChainStateChanged}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local source = damage.from
			if source and source:isAlive() then
				if source:objectName() ~= player:objectName() then
					if player:askForSkillInvoke(self:objectName(), data) then
						local flipA = source:faceUp()
						local flipB = player:faceUp()
						local chainA = source:isChained()
						local chainB = player:isChained()
						player:setFaceUp(flipA)
						player:setChained(chainA)
						source:setFaceUp(flipB)
						source:setChained(chainB)
					end
				end
			end
		elseif event == sgs.TurnedOver or event == sgs.ChainStateChanged then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:drawCards(player, 1, self:objectName())
			end
		end
	end
}
--[[添加技能]]--
Wei002_Caochong:addSkill(Wei002_Chongheng)
Wei002_Caochong:addSkill(Wei002_Jisi)
--[[翻译表]]--
sgs.LoadTranslationTable{
    ["wei002"] = "魏II包",
	
	["Wei002_Caochong"] = "曹冲",
	["&Wei002_Caochong"] = "曹冲",
	["#Wei002_Caochong"] = "早夭的神童",
	["designer:Wei002_Caochong"] = "待查",
	["cv:Wei002_Caochong"] = "无",
	["illustrator:Wei002_Caochong"] = "待查",
	
	["Wei002_Chongheng"] = "重衡",
	[":Wei002_Chongheng"] = "出牌阶段，你可以将你的武将牌翻面，令一名角色弃置其所有牌并摸等量的牌，每阶段限一次。",
	["Wei002_ChonghengCard"] = "重衡",
	
	["Wei002_Jisi"] = "继嗣",
	[":Wei002_Jisi"] = "每当你受到伤害时，你可以跟伤害来源交换武将牌状态；每当你的武将牌状态改变时，你可以摸一张牌。",
}
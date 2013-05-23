--[[
	扩展包信息
	全称：“失落的三将”扩展武将测试之蜀II包
	名称：蜀II包（shu002）
	武将：共1名
		简雍（游说、善辩）
	版本号：20130224
]]--
module("extensions.shu002", package.seeall)
extension = sgs.Package("shu002")
--[[简雍]]--
Shu002_Jianyong = sgs.General(extension, "Shu002_Jianyong", "shu", "3")
--[[
	技能：游说
	描述：出牌阶段,你可以指定两名角色,然后令一名角色选择另一名角色装备区里的一张牌移动到自己相应位置,则另一名角色获得其一张手牌，每阶段限一次。
	状态：已完成
]]--
Shu002_YoushuiCard = sgs.CreateSkillCard{ 
	name = "Shu002_YoushuiCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return not to_select:isNude()
		elseif #targets == 1 then
			local first = targets[1]
			if not first:isKongcheng() then
				if to_select:hasEquip() then
					return true
				end
			end
			if first:hasEquip() then
				if not to_select:isKongcheng() then
					return true
				end
			end
		end
		return false
	end,
	feasible = function(self, targets) 
		return #targets == 2
	end,
	on_use = function(self, room, source, targets) 
		local equip_player = nil
		local handcard_player = nil
		if targets[1]:hasEquip() then --A有装备
			if targets[2]:hasEquip() then --B有装备
				if targets[1]:isKongcheng() then --A有装备且空城，B有装备
					equip_player = targets[1]
					handcard_player = targets[2]
				else --A有装备有手牌，B有装备
					if targets[2]:isKongcheng() then --A有装备有手牌，B有装备且空城
						equip_player = targets[2]
						handcard_player = targets[1]
					else --A有装备有手牌，B有装备有手牌
						local equip_players = sgs.SPlayerList()
						equip_players:append(targets[1])
						equip_players:append(targets[2])
						equip_player = room:askForPlayerChosen(source, equip_players, self:objectName())
						if equip_player:objectName() == targets[1]:objectName() then
							handcard_player = targets[2]
						else
							handcard_player = targets[1]
						end
					end
				end
			else --A有装备，B没有装备
				equip_player = targets[1]
				handcard_player = targets[2]
			end
		else --A没有装备
			equip_player = targets[2]
			handcard_player = targets[1]
		end
		local equip_id = room:askForCardChosen(handcard_player, equip_player, "e", self:objectName())
		local equip = sgs.Sanguosha:getCard(equip_id)
		local throw_id = nil
		if equip:isKindOf("Weapon") then
			throw_id = handcard_player:getWeapon()
		elseif equip:isKindOf("Armor") then
			throw_id = handcard_player:getArmor()
		elseif equip:isKindOf("DefensiveHorse") then
			throw_id = handcard_player:getDefensiveHorse()
		elseif equip:isKindOf("OffensiveHorse") then
			throw_id = handcard_player:getOffensiveHorse()
		end
		if throw_id then
			room:throwCard(throw_id, handcard_player)
		end
		room:moveCardTo(equip, handcard_player, sgs.Player_PlaceEquip)
		local handcard_id = room:askForCardChosen(equip_player, handcard_player, "h", self:objectName())
		room:obtainCard(equip_player, handcard_id, false)
	end
}
Shu002_Youshui = sgs.CreateViewAsSkill{ 
	name = "Shu002_Youshui", 
	n = 0, 
	view_as = function(self, cards) 
		return Shu002_YoushuiCard:clone()
	end, 
	enabled_at_play = function(self, player) 
		return not player:hasUsed("#Shu002_YoushuiCard")
	end
}
--[[
	技能：善辩
	描述：每当其他角色对你使用【杀】或非延时类锦囊时,你可以声明一种花色并展示其一张手牌,若此牌为你所述之花色,则此【杀】或非延时类锦囊对你无效。
	状态：已完成
]]--
Shu002_Shanbian = sgs.CreateTriggerSkill{ 
	name = "Shu002_Shanbian", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.TargetConfirmed, sgs.CardEffected}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Slash") or card:isNDTrick() then
				local source = use.from
				if source and source:objectName() ~= player:objectName() then
					if use.to:contains(player) then
						if not source:isKongcheng() then
							if player:askForSkillInvoke(self:objectName(), data) then
								local suit = room:askForSuit(player, self:objectName())
								local card_id = room:askForCardChosen(player, source, "h", self:objectName())
								local card = sgs.Sanguosha:getCard(card_id)
								room:showCard(source, card_id)
								if card:getSuit() == suit then
									room:setPlayerFlag(player, "ShanbianAvoid")
								end
							end
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local target = effect.to
			if target and target:objectName() == player:objectName() then
				if target:hasFlag("ShanbianAvoid") then
					room:setPlayerFlag(player, "-ShanbianAvoid")
					return true
				end
			end
		end
	end
}
--[[添加技能]]--
Shu002_Jianyong:addSkill(Shu002_Youshui)
Shu002_Jianyong:addSkill(Shu002_Shanbian)
--[[翻译表]]--
sgs.LoadTranslationTable{
    ["shu002"] = "蜀II包",
	
	["Shu002_Jianyong"] = "简雍",
	["#Shu002_Jianyong"] = "谈判专家",
	["designer:Shu002_Jianyong"] = "武威1984",
	["cv:Shu002_Jianyong"] = "无",
	["illustrator:Shu002_Jianyong"] = "待查",
	
	["Shu002_Youshui"] = "游说",
	[":Shu002_Youshui"] = "出牌阶段,你可以指定两名角色,然后令一名角色选择另一名角色装备区里的一张牌移动到自己相应位置,则另一名角色获得其一张手牌，每阶段限一次。",
	["Shu002_YoushuiCard"] = "游说",
	
	["Shu002_Shanbian"] = "善辩",
	[":Shu002_Shanbian"] = "每当其他角色对你使用【杀】或非延时类锦囊时,你可以声明一种花色并展示其一张手牌,若此牌为你所述之花色,则此【杀】或非延时类锦囊对你无效。",
}
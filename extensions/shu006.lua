--[[
  扩展包信息
	全称：“失落的三将”扩展武将测试之蜀VI包
	名称：蜀VI包（shu006）
	武将：共1名
		简雍（劝降、讽喻）
	版本号：20130224
]]--

module("extensions.shu006", package.seeall)
extension = sgs.Package("shu006")

sgs.LoadTranslationTable{
	["shu006"] = "蜀VI包" ,
	
	["Shu006_Jianyong"] = "简雍",
	["&Shu006_Jianyong"] = "简雍",
	["#Shu006_Jianyong"] = "狂放的辩士",
	["designer:Shu006_Jianyong"] = "待查",
	["cv:Shu006_Jianyong"] = "无",
	["illustrator:Shu006_Jianyong"] = "待查",
	
	["Shu006_Quanxiang"] = "劝降" ,
	[":Shu006_Quanxiang"] = "出牌阶段，你可以和一名其他角色拼点：若你赢，你将其任意一张牌置入一名其他角色的相应位置；若你没赢，该角色可以视为对你使用了一张【杀】" ,
	["viewasuseslash"] = "视为使用一张杀",
	["notviewas"] = "不杀",
	
	["Shu006_Fengyu"] = "讽喻" ,
	[":Shu006_Fengyu"] = "当你成为任意【杀】或非延时类锦囊的目标时，你可以弃置一张手牌，令一名其他角色也成为其额外的目标" ,
	
}

Shu006_Jianyong = sgs.General(extension, "Shu006_Jianyong", "shu", 3)
--劝降：出牌阶段，你可以和一名其他角色拼点：若你赢，你将其任意一张牌置入一名其他角色的相应位置；若你没赢，该角色可以视为对你使用了一张【杀】
Shu006_QuanxiangCard = sgs.CreateSkillCard{
	name = "Shu006_Quanxiang" ,
	targeet_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select)
		if #targets >= 1 then return false end
		return not to_select:isKongcheng()
	end ,
	on_use = function(self, room, source, targets)
		if #targets == 0 then return end
		local target = targets[1]
		local pindianResult
		if self:getSubcards():length() == 0 then
			pindianResult = source:pindian(target, self:objectName())
		else
			pindianResult = source:pindian(target, self:objectName(), sgs.Sanguosha:getCard(self:getSubcards():first()))
		end
		if pindianResult then
			if (target:getJudgingArea():length() > 0) or target:hasEquip() then
				local card_id = room:askForCardChosen(source, target, "ej", self:objectName())
				local card = sgs.Sanguosha:getCard(card_id)
				local place = room:getCardPlace(card_id)
				local equip_index = -1
				if place == sgs.Player_PlaceEquip then
					local equip = card:getRealCard():toEquipCard()
					equip_index = equip:location()
				end
				local tos = sgs.SPlayerList()
				local list = room:getAlivePlayers()
				for _,p in sgs.qlist(list) do
					if equip_index ~= -1 then
						if not p:getEquip(equip_index) then
							tos:append(p)
						end
					else
						if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
							tos:append(p)
						end
					end
				end
				if tos:isEmpty() then return end
				local to = room:askForPlayerChosen(source, tos, self:objectName())
				if to then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), "")
					room:moveCardTo(card, target, to, place, reason)
				end
			end
		else
			if room:askForChoice(target, self:objectName(), "viewasuseslash+notviewas", sgs.QVariant()) == "viewasuseslash" then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				local slashuse = sgs.CardUseStruct()
				local slashto = sgs.SPlayerList()
				slashuse.card = slash
				slashuse.from = target
				slashto:append(source)
				slashuse.to = slashto
				room:useCard(slashuse)
			end
		end
	end
}
Shu006_Quanxiang = sgs.CreateViewAsSkill{
	name = "Shu006_Quanxiang" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if #selected > 0 then return false end
		return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		local card = Shu006_QuanxiangCard:clone()
		if #cards ~= 0 then
			card:addSubcard(cards[1])
		end
		return card
	end ,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#Shu006_Quanxiang")
	end
}

--讽喻：当你成为任意【杀】或非延时类锦囊的目标时，你可以弃置一张手牌，令一名其他角色也成为其额外的目标
Shu006_Fengyu = sgs.CreateTriggerSkill{
	name = "Shu006_Fengyu" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local carduse = data:toCardUse()
		local card = carduse.card
		if not (card:isKindOf("Slash") or card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash") or card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("Dismantlement") or card:isKindOf("Snatch") or card:isKindOf("IronChain")) then
			return
		end
		for _, p in sgs.qlist(carduse.to) do
			if p:hasSkill(self:objectName()) then
				if p:askForSkillInvoke(self:objectName()) then
					local tarlist = sgs.SPlayerList()
					for _, q in sgs.qlist(room:getAlivePlayers()) do
						if not carduse.to:contains(q) then
							tarlist:append(q)
						end
					end
					local target = room:askForPlayerChosen(p, tarlist, self:objectName())
					carduse.to:append(target)
				end
			end
		end
		data:setValue(carduse)
	end, 
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

Shu006_Jianyong:addSkill(Shu006_Quanxiang)
Shu006_Jianyong:addSkill(Shu006_Fengyu)
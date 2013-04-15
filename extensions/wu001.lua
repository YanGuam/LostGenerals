--[[
  扩展包信息
	全称：“失落的三将”扩展武将测试之吴I包
	名称：吴I包（Wu001）
	武将：共1名
		潘璋马忠（擒杀）
	版本号：20130224
]]--
module("extensions.wu001", package.seeall)
extension = sgs.Package("wu001")
sgs.LoadTranslationTable{
	["wu001"] = "吴I包" ,
	
	["Wu001_Panma"] = "潘璋马忠",
	["&Wu001_Panma"] = "潘璋马忠",
	["#Wu001_Panma"] = "遇神杀神",
	["designer:Wu001_Panma"] = "待查",
	["cv:Wu001_Panma"] = "无",
	["illustrator:Wu001_Panma"] = "待查",
	
	["Wu001_Qinsha"] = "擒杀" ,
	[":Wu001_Qinsha"] = "当你成为【杀】的目标时，你可以获得【杀】的使用者一张牌，若此【杀】为黑色，则你使用【闪】抵消此【杀】后须交给【杀】的使用者一张牌。" ,
	
}
Wu001_Panma = sgs.General(extension, "Wu001_Panma", "wu")

Wu001_Qinsha = sgs.CreateTriggerSkill{
	name = "Wu001_Qinsha" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.TargetConfirming, sgs.SlashMissed, sgs.SlashHit} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			if not player:hasSkill(self:objectName()) then return end
			local carduse = data:toCardUse()
			if not (carduse.card:isKindOf("Slash")) then return end
			local source = carduse.from
			if source:isNude() then return end
			if not player:askForSkillInvoke(self:objectName()) then return end
			local cardId = room:askForCardChosen(player, source, "he", self:objectName())
			player:obtainCard(sgs.Sanguosha:getCard(cardId), false)
			if carduse.card:isBlack() then
				room:setTag("QinshaInvoked", sgs.QVariant(1))
			end
		elseif event == sgs.SlashHit then
			if data:toSlashEffect().to:hasSkill(self:objectName()) then
				room:setTag("QinshaInvoked", sgs.QVariant(0))
			end
		else
			local slasheffect = data:toSlashEffect()
			if not slasheffect.to:hasSkill(self:objectName()) then return end
			if room:getTag("QinshaInvoked"):toInt() ~= 1 then return end
			room:setTag("QinshaInvoked", sgs.QVariant(0))
			local excard = room:askForExchange(slasheffect.to, self:objectName(), 1, true)
			slasheffect.from:obtainCard(excard, false)
		end
	end ,
	can_trigger = function(self, target)
		return true
	end
}

Wu001_Panma:addSkill(Wu001_Qinsha)
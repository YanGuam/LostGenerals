module("extensions.mj3j", package.seeall)
extension = sgs.Package("mj3j")

sgs.LoadTranslationTable{

}

mj3j_Manchong = sgs.General(extension, "mj3j_Manchong", "wei", 4)

mj3j_Mingsen = sgs.CreateTriggerSkill{
	name = "mj3j_Mingsen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	priority = 2,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local slash = damage.card
		if slash and slash:isKindOf("Slash") then
			local source = damage.from
			if source and source:objectName() == player:objectName() then
				local DamagePreInvoke = damage.damage
				for z = 1, DamagePreInvoke, 1 do
					if player:askForSkillInvoke(self:objectName(), data) then
						if z == 1 then room:broadcastSkillInvoke(self:objectName()) end
						damage.damage = damage.damage - 1
						data:setValue(damage)
						local victim = damage.to
						local choice = room:askForChoice(player, self:objectName(), "discard+draw")
						if choice == "discard" then
							for i=1, 2, 1 do
								if not victim:isAllNude() then
									local id = room:askForCardChosen(player, victim, "hej", self:objectName())
									if id > 0 then
										room:throwCard(id, victim, player)
									else
										break
									end
								end
							end
						elseif choice == "draw" then
							room:drawCards(victim, 1, self:objectName())
							victim:turnOver()
						end
					end
				end
			end
		end
		if damage.damage ==0 then return true end
	end
}

mj3j_Manchong:addSkill(mj3j_Mingsen)

mj3j_Guohuai = sgs.General(extension, "mj3j_Guohuai", "wei", 4)

ztcl9233qibianjudge = function(from, to)
	local ochoices = {}
	if from:getSiblings():length() > 1 then
		ochoices = {"slash", "dismantlement", "snatch", "duel", "iron_chain", "fire_attack"}
	else
		ochoices = {"slash", "dismantlement", "snatch", "duel", "archery_attack", "savage_assault", "iron_chain", "fire_attack"}
	end
	local choices = {}
	for _,item in ipairs(ochoices) do
		local tempcard = sgs.Sanguosha:cloneCard(item, sgs.Card_NoSuit, 0)
		local tgts = sgs.PlayerList()
		if tempcard:isKindOf("Slash") then
			if sgs.Slash_IsAvailable(from) then
				if not from:isProhibited(to, tempcard) then
					table.insert(choices, item)
				end
			end
		elseif tempcard:targetFilter(tgts, to, from) then
			if not from:isProhibited(to, tempcard) then
				table.insert(choices, item)
			end
		end
	end
	return choices
end
ztcl9233qibianCard = sgs.CreateSkillCard{
	name = "ztcl9233qibianCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			local choices = ztcl9233qibianjudge(sgs.Self, to_select)
			return #choices > 0
		elseif #targets == 1 and targets[1]:getWeapon() and targets[1]:objectName() then
			local target = targets[1]
			if target:inMyAttackRange(to_select) then
				return target:canSlash(to_select, nil, true)
			end
		end
	end,
	on_use = function(self, room, source, targets)
		local target
		if #targets == 0 then
			target = source
		else
			target = targets[1]
		end
		local choices
		if #targets == 2 then
			choices = {"collateral"}
		elseif #targets == 1 then
			if target:objectName() ~= source:objectName() then
				choices = ztcl9233qibianjudge(source, target)
			end
		end
		
		choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
		
		local log=sgs.LogMessage()
		log.type = "#ztcl9233qibianbroad"
		log.from = source
		log.arg  = choice
		room:sendLog(log)
		room:broadcastSkillInvoke(self:objectName())

		local xcard = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)
		xcard:setSkillName("ztcl9233qibian")
		local use = sgs.CardUseStruct()
		use.card = xcard
		use.from = source
		if #targets == 2 then
			use.to:append(targets[2])
		end
		use.to:append(target)
		room:useCard(use)
	end
}
ztcl9233qibianVS = sgs.CreateViewAsSkill{
	name = "ztcl9233qibian",
	n = 0,
	xpattern = "",
	view_as = function(self, cards)
		if xpattern == "" then
			return ztcl9233qibianCard:clone()
		else
			local card = sgs.Sanguosha:cloneCard(xpattern, sgs.Card_NoSuit, 0)
			card:setSkillName("ztcl9233qibian")
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		xpattern = ""
		return not player:hasFlag("ztcl9233qibian_used")
	end,
	enabled_at_response = function(self, player, pattern)
		xpattern = pattern
		if not (player:hasFlag("ztcl9233qibian_used") or player:hasFlag("ztcl9233qibian_forbidden")) then
			if pattern == "slash" then
				if player:hasFlag("SlashAssignee")then
					return true
				end			
				local others = player:getSiblings()
				for _,p in sgs.qlist(others) do
					if p:hasFlag("SlashAssignee")then
						return true
					end
				end
			else
				return pattern == "nullification"
			end
		end
	end,
	enabled_at_nullification = function(self, player)
		return not (player:hasFlag("ztcl9233qibian_used") or player:hasFlag("ztcl9233qibian_forbidden"))
	end
}
ztcl9233qibian = sgs.CreateTriggerSkill{
	name = "ztcl9233qibian",
	view_as_skill = ztcl9233qibianVS,
	events = {sgs.CardUsed, sgs.CardEffect, sgs.EventPhaseStart},
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local alives = room:getAlivePlayers()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local card = use.card
			if card:getSkillName() == "ztcl9233qibian" then
				if card:isKindOf("Nullification") then
					for _,p in sgs.qlist(alives) do
						if p:hasFlag("ztcl9233qibian_target") then
							p:drawCards(1)
							room:setPlayerFlag(p, "-ztcl9233qibian_target")
						end
						if p:hasFlag("ztcl9233qibian_forbidden") then
							room:setPlayerFlag(p, "-ztcl9233qibian_forbidden")
						end
					end
					room:setPlayerFlag(use.from, "ztcl9233qibian_used")
					room:setPlayerFlag(use.from, "ztcl9233qibian_target")
					return
				else
					local targets = use.to
					for _,p in sgs.qlist(targets) do
						p:drawCards(1)
					end
				end
				room:setPlayerFlag(use.from, "ztcl9233qibian_used")
			elseif card:isKindOf("Nullification") then
				for _,p in sgs.qlist(alives) do
					if p:hasFlag("ztcl9233qibian_target") then
						room:setPlayerFlag(p, "-ztcl9233qibian_target")
					end
					if p:hasFlag("ztcl9233qibian_forbidden") then
						room:setPlayerFlag(p, "-ztcl9233qibian_forbidden")
					end
				end
				room:setPlayerFlag(use.from, "ztcl9233qibian_target")
			end
		elseif event == sgs.CardEffect then
			for _,p in sgs.qlist(alives) do
				if p:hasFlag("ztcl9233qibian_target") then
					room:setPlayerFlag(p, "-ztcl9233qibian_target")
				end
			end
			local effect = data:toCardEffect()
			local from = effect.from
			if from then
				room:setPlayerFlag(from, "ztcl9233qibian_target")
			end
			if effect.card:isKindOf("DelayedTrick") then
				for _,p in sgs.qlist(alives) do
					if not p:hasFlag("ztcl9233qibian_forbidden") then
						room:setPlayerFlag(p, "ztcl9233qibian_forbidden")
					end
				end
			end
		else
			for _,p in sgs.qlist(alives) do
				if p:hasFlag("ztcl9233qibian_used") then
					room:setPlayerFlag(p, "-ztcl9233qibian_used")
				end
			end
		end
	end
}

mj3j_Guohuai:addSkill(ztcl9233qibian)
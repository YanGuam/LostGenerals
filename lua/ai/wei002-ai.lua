--[[
	技能：重衡
	描述：出牌阶段，你可以将你的武将牌翻面，令一名角色弃置其所有牌并摸等量的牌，每阶段限一次。
]]--
local Wei002_Chongheng_skill = {}
Wei002_Chongheng_skill.name = "Wei002_Chongheng"
table.insert(sgs.ai_skills, Wei002_Chongheng_skill)
Wei002_Chongheng_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#Wei002_ChonghengCard") then
		local card_str = "#Wei002_ChonghengCard:.:"
		return sgs.Card_Parse(card_str)
	end
end
sgs.ai_skill_use_func["#Wei002_ChonghengCard"] = function(card, use, self)
	local canTurnedOver = not self.player:faceUp()
	if not canTurnedOver then
		canTurnedOver = self:hasSkills("jushou|nosjushou|kuiwei|cangni")
	end
	if #self.friends_noself > 0 then
		if not canTurnedOver then
			for _,friend in ipairs(self.friends_noself) do
				if self:hasSkills("fangzhu|jilve|jujian|pojun") then
					canTurnedOver = true
					break
				end
			end
		end
	end
	if canTurnOver or not self:isWeak() then
		local target = nil
		for _,friend in ipairs(self.friends) do
			if self:hasSkills("tuntian", friend) then
				target = friend
				break
			elseif self:hasSkills(sgs.lose_equip_skill, friend) then
				target = friend
				break
			end
		end
		if not target then
			for _,friend in ipairs(self.friends) do
				if not friend:isNude() then
					target = friend
					break
				end
			end
			if target then
				use.card = card
				if use.to then
					use.to:append(target)
				end
			end
		end
	end
end
--[[
	技能：继嗣
	描述：每当你受到伤害时，你可以跟伤害来源交换武将牌状态；每当你的武将牌状态改变时，你可以摸一张牌。
]]--
sgs.ai_skill_invoke["Wei002_Jisi"] = function(self, data)
	local damage = data:toDamage()
	local source = damage.from
	if source then
		if not self.player:faceUp() and source:faceUp() then
			return true
		end
		if self.player:isChained() and not source:isChained() then
			return true
		end
		return false
	end
	return true
end
module("extensions.wei004", package.seeall)
extension = sgs.Package("wei004")

sgs.LoadTranslationTable{
	["wei004"] = "魏IV包" ,
	
	["Wei004_Caochong"] = "曹冲" ,
	["&Wei004_Caochong"] = "曹冲",
	["#Wei004_Caochong"] = "怀仁的神童",
	["designer:Wei004_Caochong"] = "待查",
	["cv:Wei004_Caochong"] = "无",
	["illustrator:Wei004_Caochong"] = "待查",
	
	["Wei004_Zaohui"] = "早慧" ,
	[":Wei004_Zaohui"] = "若你在回合外受到伤害，你可在该回合结束后进行一个额外的回合。" ,
	["#Wei004_ZaohuiCount"] = "早慧" ,
	["#Wei004_Zaohui"] = "早慧" ,
	
	["Wei004_Nieyi"] = "啮衣" ,
	[":Wei004_Nieyi"] = "你攻击范围内的一名其他角色受到伤害后，你可对自己造成一点伤害或弃置装备区内的一张牌，令受到伤害的角色回复一点体力。" ,
	["nieyidamage"] = "对自己造成伤害" ,
	["nieyidiscardequip"] = "弃置装备区内的牌" ,
}

Wei004_Caochong = sgs.General(extension, "Wei004_Caochong", "wei" ,3)
--早慧：若你在回合外受到伤害，你可在该回合结束后进行一个额外的回合。
Wei004_ZaohuiCount = sgs.CreateTriggerSkill{
	name = "#Wei004_ZaohuiCount" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_NotActive then
			player:addMark("zaohui")
		end
	end
}
Wei004_Zaohui = sgs.CreateTriggerSkill{
	name = "Wei004_Zaohui" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local players = room:getAlivePlayers()
		for _, p in sgs.qlist(players) do
			if p:hasSkill(self:objectName()) then
				if p:getMark("zaohui") > 0 then
					if p:askForSkillInvoke(self:objectName()) then
						local qv = sgs.QVariant()
						qv:setValue(p)
						room:setTag("zaohuiinvoke", qv)
					end
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		if target then
			return target:getPhase() == sgs.Player_NotActive
		end
		return false
	end
}
Wei004_ZaohuiDo = sgs.CreateTriggerSkill{
	name = "#Wei004_Zaohui" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local p = room:getTag("zaohuiinvoke"):toPlayer()
		if p then
			if p:hasSkill("Wei004_Zaohui") then
				if p:getMark("zaohui") > 0 then
					p:setMark("zaohui", 0)
					p:gainAnExtraTurn()
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		if target then
			return target:getPhase() == sgs.Player_NotActive
		end
		return false
	end,
	priority = -3
}
--啮衣：你攻击范围内的一名其他角色受到伤害后，你可对自己造成一点伤害或弃置装备区内的一张牌，令受到伤害的角色回复一点体力。
Wei004_Nieyi = sgs.CreateTriggerSkill{
	name = "Wei004_Nieyi" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local players = room:getAlivePlayers()
		for _, p in sgs.qlist(players) do
			if p:hasSkill(self:objectName()) then
				if p:inMyAttackRange(player) then
					if p:objectName() ~= player:objectName() then
						if p:askForSkillInvoke(self:objectName(), data) then
							local choice
							if p:hasEquip() then
								choice = room:askForChoice(p, self:objectName(), "nieyidiscardequip+nieyidamage")
							else
								choice = "nieyidamage"
							end
							if choice == "nieyidiscardequip" then
								local card = room:askForCardChosen(p, p, "e", self:objectName())
								--这是临时处理方法，本来想用askForCard+技能卡达到效果
								room:throwCard(card, p, p)
							else
								local thedamage = sgs.DamageStruct()
								thedamage.damage = 1
								thedamage.from = p
								thedamage.to = p
								thedamage.card = nil
								thedamage.nature = sgs.DamageStruct_Normal
								room:damage(thedamage)
							end
							local recover = sgs.RecoverStruct()
							recover.recover = 1
							recover.who = p
							recover.card = nil
							room:recover(player, recover)
						end
					end
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

Wei004_Caochong:addSkill(Wei004_ZaohuiCount)
Wei004_Caochong:addSkill(Wei004_ZaohuiDo)
Wei004_Caochong:addSkill(Wei004_Zaohui)
Wei004_Caochong:addSkill(Wei004_Nieyi)
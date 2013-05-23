--[[
	扩展包信息
	全称：“失落的三将”扩展武将测试之吴III包
	名称：吴III包（wu003）
	武将：共1名
		朱然（持守）
	版本号：20130224
]]--
module("extensions.wu003", package.seeall)
extension = sgs.Package("wu003")
--[[朱然]]--
Wu003_Zhuran = sgs.General(extension, "Wu003_Zhuran", "wu", "4")
--[[
	技能：持守（锁定技）
	描述：回合外，你不能成为【杀】的目标；若使用【杀】能攻击到你的角色于其出牌阶段未使用【杀】，则其可以于此阶段结束时将一张【杀】置于你的武将牌上，称为“围”；你的回合开始阶段开始时，须将所有“围”置入弃牌堆并视为与你距离最近的另一名角色对你使用一张【杀】，此【杀】造成的伤害为“围”的数量。
	状态：已完成，待验证
]]--
Wu003_ChishouAvoid = sgs.CreateProhibitSkill{ 
	name = "#Wu003_ChishouAvoid", 
	is_prohibited = function(self, from, to, card) 
		if to:hasSkill(self:objectName()) then
			if card:isKindOf("Slash") then
				return to:getMark("ChishouNotActive") > 0
			end
		end
	end
}
Wu003_ChishouEffect = sgs.CreateTriggerSkill{ 
	name = "#Wu003_ChishouEffect", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseChanging}, 
	on_trigger = function(self, event, player, data) 
		local change = data:toPhaseChange()
		local room = player:getRoom()
		if change.to == sgs.Player_NotActive then
			room:setPlayerMark(player, "ChishouNotActive", 1)
		elseif change.to == sgs.Player_Start then
			room:setPlayerMark(player, "ChishouNotActive", 0)
		end
	end, 
	priority = 2
}
Wu003_ChishouAsk = sgs.CreateTriggerSkill{ 
	name = "#Wu003_ChishouAsk", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardUsed, sgs.EventPhaseEnd}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local slash = use.card
			if slash:isKindOf("Slash") then
				local source = use.from
				if source and source:objectName() == player:objectName() then
					room:setPlayerMark(player, "ChishouCount", 1)
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				if player:getMark("ChishouCount") == 0 then
					local others = room:getOtherPlayers(player)
					local ai_data = sgs.QVariant()
					for _,source in sgs.qlist(others) do
						if source:hasSkill("Wu003_Chishou") then
							if player:inMyAttackRange(source) then
								ai_data:setValue(source)
								local slash = room:askForCard(player, "slash", "@ChishouAsk", ai_data, "Wu003_Chishou")
								if slash then
									source:addToPile("Wu003_wei", slash, true)
								end
							end
						end
					end
				else
					room:setPlayerMark(player, "ChishouCount", 0)
				end
			end
		end
	end, 
	can_trigger = function(self, target) 
		if target then
			return target:isAlive()
		end
		return false
	end, 
	priority = 2
}
Wu003_Chishou = sgs.CreateTriggerSkill{ 
	name = "Wu003_Chishou", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart, sgs.DamageCaused}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				local card_ids = player:getPile("Wu003_wei")
				local count = card_ids:length()
				if count > 0 then
					player:removePileByName("Wu003_wei")
					local min_dist = 999
					local others = room:getOtherPlayers(player)
					for _,p in sgs.qlist(others) do
						local dist = p:distanceTo(player)
						if dist < min_dist then
							min_dist = dist
						end
					end
					local source_list = sgs.SPlayerList()
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _,p in sgs.qlist(others) do
						local dist = p:distanceTo(player)
						if dist == min_dist then
							if p:canSlash(player, slash, false) then
								source_list:append(p)
							end
						end
					end
					if not source_list:isEmpty() then
						local source = nil
						if source_list:length() == 1 then
							source = source_list:first()
						else
							source = room:askForPlayerChosen(player, source_list, self:objectName())
						end
						if source then
							slash:setSkillName(self:objectName())
							room:setCardFlag(slash, "ChishouSlash")
							room:setPlayerMark(player, "ChishouDamage", count)
							local use = sgs.CardUseStruct()
							use.from = source
							use.to:append(player)
							use.card = slash
							room:useCard(use, false)
						end
					end
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			local victim = damage.to
			if victim and victim:objectName() == player:objectName() then
				local slash = damage.card
				if slash and slash:isKindOf("Slash") then
					if slash:hasFlag("ChishouSlash") then
						local count = player:getMark("ChishouDamage")
						if count > 0 then
							damage.damage = count
							data:setValue(damage)
							room:setPlayerMark(player, "ChishouDamage", 0)
						end
					end
				end
			end
		end
	end
}
--[[添加技能]]--
Wu003_Zhuran:addSkill(Wu003_ChishouAvoid)
Wu003_Zhuran:addSkill(Wu003_ChishouEffect)
Wu003_Zhuran:addSkill(Wu003_ChishouAsk)
Wu003_Zhuran:addSkill(Wu003_Chishou)
--[[翻译表]]--
sgs.LoadTranslationTable{
    ["Wu003"] = "吴III包",
	
	["Wu003_Zhuran"] = "朱然",
	["#Wu003_Zhuran"] = "谈判专家",
	["designer:Wu003_Zhuran"] = "武威1984",
	["cv:Wu003_Zhuran"] = "无",
	["illustrator:Wu003_Zhuran"] = "待查",
	
	["Wu003_Chishou"] = "持守",
	[":Wu003_Chishou"] = "<b>锁定技</b>, 回合外，你不能成为【杀】的目标；若使用【杀】能攻击到你的角色于其出牌阶段未使用【杀】，则其可以于此阶段结束时将一张【杀】置于你的武将牌上，称为“围”；你的回合开始阶段开始时，须将所有“围”置入弃牌堆并视为与你距离最近的另一名角色对你使用一张【杀】，此【杀】造成的伤害为“围”的数量。",
	["Wu003_wei"] = "围",
	["@ChishouAsk"] = "您可以将一张【杀】置于目标角色的武将牌上。",
}
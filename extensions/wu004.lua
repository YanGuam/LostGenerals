--[[
	扩展包信息
	全称：“失落的三将”扩展武将测试之吴IV包
	名称：吴IV包（wu004）
	武将：共1名
		虞翻（刚谏、易理）
	版本号：20130224
]]--
module("extensions.wu004", package.seeall)
extension = sgs.Package("wu004")
--[[虞翻]]--
Wu004_Yufan = sgs.General(extension, "Wu004_Yufan", "wu", "4")
--[[
	技能：刚谏
	描述：出牌阶段，你可与任一其他角色交换手牌，若你与该角色手牌数差≥2，交换后手牌较多者回复一点体力且失去所有技能直至其下回合结束。（每阶段限用一次）
	状态：已完成。
]]--
Wu004_GangjianCard = sgs.CreateSkillCard{ 
	name = "Wu004_GangjianCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		local moveA = sgs.CardsMoveStruct()
		moveA.card_ids = source:handCards()
		moveA.to = target
		moveA.to_place = sgs.Player_PlaceHand
		local moveB = sgs.CardsMoveStruct()
		moveB.card_ids = target:handCards()
		moveB.to = source
		moveB.to_place = sgs.Player_PlaceHand
		room:moveCards(moveA, false)
		room:moveCards(moveB, false)
		local countA = source:getHandcardNum()
		local countB = target:getHandcardNum()
		if math.abs(countA - countB) >= 2 then
			local more = nil
			local less = nil
			if countA > countB then
				more = source
				less = target
			else
				more = target
				less = source
			end
			if more and less then
				local recover = sgs.RecoverStruct()
				recover.who = source
				recover.recover = 1
				room:recover(more, recover)
				local skills = more:getVisibleSkillList()
				if not skills:isEmpty() then
					local names = {}
					for _,skill in sgs.qlist(skills) do
						local name = skill:objectName()
						table.insert(names, name)
						room:detachSkillFromPlayer(more, name)
					end
					local key = "GangJianSkills:"..more:objectName()
					local tag = table.concat(names, "+")
					room:setTag(key, sgs.QVariant(tag))
					room:setPlayerMark(more, "GangJianTarget", 1)
				end
			end
		end
	end
}
Wu004_Gangjian = sgs.CreateViewAsSkill{ 
	name = "Wu004_Gangjian", 
	n = 0, 
	view_as = function(self, cards) 
		return Wu004_GangjianCard:clone()
	end, 
	enabled_at_play = function(self, player) 
		return not player:hasUsed("#Wu004_GangjianCard")
	end
}
Wu004_GangjianEffect = sgs.CreateTriggerSkill{ 
	name = "#Wu004_GangjianEffect", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseEnd}, 
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Finish then
			local key = "GangJianSkills:"..player:objectName()
			local room = player:getRoom()
			local tag = room:getTag(key)
			if tag then
				local names = tag:toString()
				if names then
					names = names:split("+")
					for _,name in ipairs(names) do
						room:acquireSkill(player, name)
					end
				end
				room:removeTag(key)
			end
			room:setPlayerMark(player, "GangJianTarget", 0)
		end
	end, 
	can_trigger = function(self, target) 
		if target then
			if target:isAlive() then
				return target:getMark("GangJianTarget") > 0
			end
		end
		return false
	end, 
	priority = 2
}
--[[
	技能：易理
	描述：摸牌阶段你可少摸一张牌并进行一次判定。若判定牌为基本牌或非延时类锦囊牌，你摸一张牌且本回合你可将任一不同类别的手牌当该牌使用或打出；否则你获得判定牌.
	状态：已完成。
	评论：如果判定结果为铁索连环，按现有的内容，可以无限重铸，于是平局大师诞生了。
]]--
Wu004_YiliVS = sgs.CreateViewAsSkill{ 
	name = "Wu004_Yili", 
	n = 1, 
	view_filter = function(self, selected, to_select) 
		if #selected == 0 then
			if not to_select:isEquipped() then
				local id = sgs.Self:getMark("YiliUsable")
				if id > 0 then
					local card = sgs.Sanguosha:getCard(id)
					local class = card:getClassName()
					return not to_select:isKindOf(class)
				end
			end
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = sgs.Self:getMark("YiliUsable")
			if id > 0 then
				local target = sgs.Sanguosha:getCard(id)
				local name = target:objectName()
				local vs_card = sgs.Sanguosha:cloneCard(name, suit, point)
				vs_card:setSkillName(self:objectName())
				vs_card:addSubcard(card)
				return vs_card
			end
		end
	end, 
	enabled_at_play = function(self, player) 
		local id = player:getMark("YiliUsable")
		if id > 0 and not player:isKongcheng() then
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("Slash") then
				return sgs.Slash_IsAvailable(player)
			elseif card:isKindOf("Jink") then
				return false
			elseif card:isKindOf("Peach") then
				return player:isWounded()
			elseif card:isKindOf("Analeptic") then
				return sgs.Analeptic_IsAvailable(player)
			elseif card:isKindOf("Nullification") then
				return false
			end
			return true
		end
		return false
	end, 
	enabled_at_response = function(self, player, pattern) 
		local id = player:getMark("YiliUsable")
		if id > 0 then
			local card = sgs.Sanguosha:getCard(id)
			local name = card:objectName()
			return string.find(pattern, name)
		end
		return false
	end,
	enabled_at_nullification = function(self, player) 
		local cards = player:getCards("h")
		for _,c in sgs.qlist(cards) do
			if c:objectName() == "nullification" then
				return true
			end
		end
		local id = player:getMark("YiliUsable")
		if id > 0 then
			local card = sgs.Sanguosha:getCard(id)
			local name = card:objectName()
			if name == "nullification" then
				return not player:isKongcheng()
			end
		end
		return false
	end
}
Wu004_Yili = sgs.CreateTriggerSkill{ 
	name = "Wu004_Yili", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart, sgs.DrawNCards, sgs.AfterDrawNCards, sgs.EventPhaseEnd}, 
	view_as_skill = Wu004_YiliVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:setPlayerMark(player, "YiliInvoked", 1)
				end
			end
		elseif event == sgs.DrawNCards then
			if player:getMark("YiliInvoked") > 0 then
				local count = data:toInt() - 1
				data:setValue(count)
			end
		elseif event == sgs.AfterDrawNCards then
			if player:getMark("YiliInvoked") > 0 then
				local judge = sgs.JudgeStruct()
				judge.who = player
				judge.reason = self:objectName()
				judge.pattern = sgs.QRegExp("(.*):(.*):(.*)")
				room:judge(judge)
				local card = judge.card
				if card:isKindOf("BasicCard") or card:isNDTrick() then
					room:drawCards(player, 1, self:objectName())
					room:setPlayerMark(player, "YiliUsable", card:getEffectiveId())
				else
					room:obtainCard(player, card, true)
				end
				room:setPlayerMark(player, "YiliInvoked", 0)
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				room:setPlayerMark(player, "YiliUsable", 0)
			end
		end
	end
}
--[[添加技能]]--
Wu004_Yufan:addSkill(Wu004_Gangjian)
Wu004_Yufan:addSkill(Wu004_GangjianEffect)
Wu004_Yufan:addSkill(Wu004_Yili)
--[[翻译表]]--
sgs.LoadTranslationTable{
    ["wu004"] = "吴IV包",
	
	["Wu004_Yufan"] = "虞翻",
	["#Wu004_Yufan"] = "古之狂直",
	["designer:Wu004_Yufan"] = "sarsdd",
	["cv:Wu004_Yufan"] = "无",
	["illustrator:Wu004_Yufan"] = "待查",
	
	["Wu004_Gangjian"] = "刚谏",
	[":Wu004_Gangjian"] = "出牌阶段，你可与任一其他角色交换手牌，若你与该角色手牌数差≥2，交换后手牌较多者回复一点体力且失去所有技能直至其下回合结束。（每阶段限用一次）",
	["Wu004_GangjianCard"] = "刚谏",
	
	["Wu004_Yili"] = "易理",
	[":Wu004_Yili"] = "摸牌阶段你可少摸一张牌并进行一次判定。若判定牌为基本牌或非延时类锦囊牌，你摸一张牌且本回合你可将任一不同类别的手牌当该牌使用或打出；否则你获得判定牌.",
}
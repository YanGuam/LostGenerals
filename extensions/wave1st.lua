--[[
	扩展包信息
	全称：“失落的三将”扩展武将第一波种子包
	名称：第一波包（wave1st）
	武将：共11名
		曹冲（仁慧、天意）
		郭淮（谋动）
		满宠（明森）
		简雍（昭德、纵节）
		关平（临城、殉志）
		刘封（刚勇、自保）
		李儒（毒策、焚城）
		伏皇后（密笺、祸族）
		朱然（胆略）
		虞翻（渊硕、耿烈）
		潘璋马忠（避锋、伺机）
	版本号：20130224
	附注：再强调一遍，这只是第一波种子技能，非定稿，非定稿
]]--
module("extensions.wave1st", package.seeall)
extension = sgs.Package("wave1st")
--[[曹冲]]--
Wave1st_Caochong = sgs.General(extension, "Wave1st_Caochong", "wei", "3")
--[[
	技能：仁慧
	描述：每当你的攻击范围内（包括你）有角色受到牌的伤害时，你可弃置一张牌进行一次判定，若判定牌与你弃置的牌点数之和大于造成伤害的牌，则受伤角色选择回复1点体力或摸两张牌。
	状态：尚未验证
	问题：造成伤害的牌不止一张，如何计算点数？是算0点还是算所有牌的点数之和？比如乱击、奇策等情形。
	暂解：这里先按技能卡的点数（默认为0点）计算了。
	作者解释：如果为不止一张的话按照所有牌点数的和来算
]]--
Wave1st_Renhui = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Renhui", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged}, 
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local victim = damage.to
		if victim:objectName() == player:objectName() then
			local card = damage.card
			if card then
				local room = player:getRoom()
				local alives = room:getAlivePlayers()
				for _,source in sgs.qlist(alives) do
					if source:hasSkill(self:objectName()) then
						if source:inMyAttackRange(victim) or victim:objectName() == source:objectName() then
							if not source:isNude() then
								local mycard = room:askForCard(source, ".", "@RenhuiDiscard")
								if mycard then
									local judge = sgs.JudgeStruct()
									judge.reason = self:objectName()
									judge.who = source
									judge.pattern = sgs.QRegExp("(.*):(.*):(.*)")
									room:judge(judge)
									local judgePoint = judge.card:getNumber()
									local myPoint = mycard:getNumber()
									--local point = card:getNumber()
									local point
									if not card:isVirtualCard() then
										point = card:getNumber()
									else
										for _, c in sgs.qlist(card:getSubcards()) do
											point = point + c:getNumber()
										end
									end
									if judgePoint + myPoint > point then
										local choice = "draw"
										if victim:isWounded() then
											choice = room:askForChoice(victim, self:objectName(), "draw+recover")
										end
										if choice == "recover" then
											local recover = sgs.RecoverStruct()
											recover.who = source
											recover.recover = 1
											room:recover(victim, recover)
										elseif choice == "draw" then
											room:drawCards(victim, 2, self:objectName())
										end
									end
								end
							end
						end
					end
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
--[[
	技能：天意（锁定技）
	描述：每当你的红桃判定牌生效时，你需回复1点体力或摸一张牌；每当你的黑桃判定牌生效时，你需失去1点体力或弃一张牌。
	状态：尚未验证
]]--
Wave1st_Tianyi = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Tianyi", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.FinishJudge}, 
	on_trigger = function(self, event, player, data) 
		local judge = data:toJudge()
		local suit = judge.card:getSuit()
		local room = player:getRoom()
		if suit == sgs.Card_Heart then
			local choice = "draw" 
			if player:isWounded() then
				choice = room:askForChoice(player, self:objectName(), "recover+draw")
			end
			if choice == "recover" then
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1
				room:recover(player, recover)
			elseif choice == "draw" then
				room:drawCards(player, 1, self:objectName())
			end
		elseif suit == sgs.Card_Spade then
			local choice = "lose"
			if not player:isNude() then
				choice = room:askForChoice(player, self:objectName(), "lose+discard")
			end
			if choice == "lose" then
				room:loseHp(player, 1)
			elseif choice == "discard" then
				room:askForDiscard(player, self:objectName(), 1, 1, false, true, "@TianyiDiscard")
			end
		end
	end
}
--[[郭淮]]--
Wave1st_Guohuai = sgs.General(extension, "Wave1st_Guohuai", "wei", "4")
--[[
	技能：谋动
	描述：出牌阶段，你可以选择一种花色后展示一名角色的一张手牌，若此牌与所选花色相同，则你令另一名角色获得之。每阶段限一次。
	状态：尚未验证
	附注：强度偏弱，认为应该进行修改
]]--
Wave1st_MoudongCard = sgs.CreateSkillCard{ 
	name = "Wave1st_MoudongCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		local suit = room:askForSuit(source, self:objectName())
		local alives = room:getAlivePlayers()
		local show_group = sgs.SPlayerList()
		for _,p in sgs.qlist(alives) do
			if not p:isKongcheng() then
				show_group:append(p)
			end
		end
		if not show_group:isEmpty() then
			local show_target = room:askForPlayerChosen(source, show_group, "MoudongShow")
			if show_target then
				local id = room:askForCardChosen(source, show_target, "h", self:objectName())
				room:showCard(source, id, nil)
				local card = sgs.Sanguosha:getCard(id)
				if card:getSuit() == suit then
					local others = room:getOtherPlayers(show_target)
					local obtain_target = room:askForPlayerChosen(source, others, "MoudongObtain")
					if obtain_target then
						room:obtainCard(obtain_target, id, true)
					end
				end
			end
		end
	end
}
Wave1st_Moudong = sgs.CreateViewAsSkill{ 
	name = "Wave1st_Moudong", 
	n = 0, 
	view_as = function(self, cards) 
		return Wave1st_MoudongCard:clone()
	end, 
	enabled_at_play = function(self, player) 
		return not player:hasUsed("#Wave1st_MoudongCard")
	end
}
--[[满宠]]--
Wave1st_Manchong = sgs.General(extension, "Wave1st_Manchong", "wei", "4")
--[[
	技能：明森
	描述：每当你使用【杀】对角色造成伤害时，你可以令此伤害-1，然后弃置目标角色区域内至多两张牌，或令目标角色摸一张牌并将武将牌翻面。
	状态：验证通过
	附注：Fs：个人认为这个人比徐盛都弱
]]--
Wave1st_Mingsen = sgs.CreateTriggerSkill{
    name = "Wave1st_Mingsen",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.DamageCaused},
    priority = 2,
    on_trigger = function(self, event, player, data)
        local damage = data:toDamage()
        local slash = damage.card
        if slash and slash:isKindOf("Slash") then
            local source = damage.from
            if source and source:objectName() == player:objectName() then
                if player:askForSkillInvoke(self:objectName(), data) then
                    damage.damage = damage.damage - 1
                    data:setValue(damage)
                    local room = player:getRoom()
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
		if damage.damage ==0 then return true end
    end
}
--[[简雍]]--
Wave1st_Jianyong = sgs.General(extension, "Wave1st_Jianyong", "shu", "3")
--[[
	技能：昭德
	描述：出牌阶段开始时，你可与一名其他角色进行拼点，若你赢，根据你的拼点牌的类别执行相应的效果：
		基本牌：弃置其一张手牌；
		非基本牌牌：弃置其装备区内的一张牌；
		若你没赢，你立即进入弃牌阶段。
	状态：尚未验证
]]--
Wave1st_ZhaodeCard = sgs.CreateSkillCard{ 
	name = "Wave1st_ZhaodeCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			if not to_select:isKongcheng() then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		local success = source:pindian(target, self:objectName(), self)
		if success then
			local card_ids = self:getSubcards()
			local id = card_ids:first()
			local card = sgs.Sanguosha:getCard(id)
			local to_throw = nil
			if card:isKindOf("BasicCard") then
				if not target:isKongcheng() then
					to_throw = room:askForCardChosen(source, target, "h", self:objectName())
				end
			else
				if target:hasEquip() then
					to_throw = room:askForCardChosen(source, target, "e", self:objectName())
				end
			end
			if to_throw then
				room:throwCard(to_throw, target, source)
			end
		else
			source:setPhase(sgs.Player_Discard)
		end
	end
}
Wave1st_ZhaodeVS = sgs.CreateViewAsSkill{ 
	name = "Wave1st_Zhaode", 
	n = 1, 
	view_filter = function(self, selected, to_select) 
		if #selected == 0 then
			return not to_select:isEquipped()
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = Wave1st_ZhaodeCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player) 
		return false
	end, 
	enabled_at_response = function(self, player, pattern) 
		return pattern == "@@Zhaode"
	end
}
Wave1st_Zhaode = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Zhaode", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = Wave1st_ZhaodeVS, 
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Play then
			if not player:isKongcheng() then
				room:askForUseCard(player, "@@Zhaode", "@Zhaode")
			end
		end
	end
}
--[[
	技能：纵节（锁定技）
	描述：当一名角色于弃牌阶段弃置了至少一张牌时，你摸一张牌。
	状态：尚未验证
]]--
Wave1st_Zongjie = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Zongjie", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:getPhase() == sgs.Player_Discard then
				if move.to_place == sgs.Player_DiscardPile then
					local places = move.from_places
					if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
						local count = move.card_ids:length()
						local mark = source:getMark("DiscardCount")
						room:setPlayerMark(source, "DiscardCount", mark+count)
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard then
				local mark = player:getMark("DiscardCount")
				if mark > 0 then
					local alives = room:getAlivePlayers()
					for _,source in sgs.qlist(alives) do
						if source:hasSkill(self:objectName()) then
							room:drawCards(source, 1, self:objectName())
						end
					end
					room:setPlayerMark(player, "DiscardCount", 0)
				end
			end
		end
	end, 
	can_trigger = function(self, target) 
		if target then
			return target:isAlive()
		end
		return false
	end
}
--[[关平]]--
Wave1st_Guanping = sgs.General(extension, "Wave1st_Guanping", "shu", "4")
--[[
	技能：临城（锁定技）
	描述：若一名其他角色的手牌数和体力值均不少于你，你与该角色的距离视为1且无视其防具。
	附注：Fs：1技能无视防具的时机？使用杀时？使用南蛮万箭时？还是什么时？回合内还是回合外？建议修正描述。
	评论：这个要是真的被选上，张皇后又有做伴的了……
]]--
--[[
	技能：殉志（觉醒技）
	描述：回合开始阶段开始时，若你已损失的体力是全场最多的（或之一且至少损失1点），你须减1点体力上限，回复体力至体力上限，并获得技能“武圣”和“当先”。
	附注：2技能和已有技能重名。
	状态：暂时验证成功
]]--
Wave1st_Xunzhi = sgs.CreateTriggerSkill{
	name = "Wave1st_Xunzhi" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_RoundStart then return end
		if player:getLostHp() == 0 then return end
		local room = player:getRoom()
		if room:getTag("xunzhiinvoked"):toInt() == 1 then return end
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getLostHp() > player:getLostHp() then return end
		end
		room:loseMaxHp(player)
		local recover = sgs.RecoverStruct()
		recover.recover = player:getLostHp()
		recover.who = player
		room:recover(player, recover)
		room:acquireSkill(player, "wusheng")
		room:acquireSkill(player, "dangxian")
		room:setTag("xunzhiinvoked", sgs.QVariant(1))
	end ,
	priority = 3
}

--[[刘封]]--
Wave1st_Liufeng = sgs.General(extension, "Wave1st_Liufeng", "shu", "4")
--[[
	技能：刚勇
	描述：摸牌阶段后你可进行一个额外的弃牌阶段，本回合你的攻击范围额外+X，你使用的黑色【杀】可额外指定X个目标。（X为弃牌阶段你所弃牌数）
	状态：尚未验证
]]--
Wave1st_Gangyong = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Gangyong", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseChanging, sgs.CardsMoveOneTime}, 
	on_trigger = function(self, event, player, data) 
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local last = change.from
			local room = player:getRoom()
			if last == sgs.Player_Draw then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:setPlayerMark(player, "GangyongInvoked", 1)
					change.to = sgs.Player_Discard
					data:setValue(change)
					player:insertPhase(sgs.Player_Discard)
					return false
				end
			end
			if change.to == sgs.Player_NotActive then
				room:setPlayerMark(player, "GangyongInvoked", 0)
				player:loseAllMarks("@valour")
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				if player:getMark("GangyongInvoked") > 0 then
					if move.to_place == sgs.Player_DiscardPile then
						local places = move.from_places
						if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
							local count = move.card_ids:length()
							player:gainMark("@valour", count)
						end
					end
				end
			end
		end
	end
}
Wave1st_GangyongTarget = sgs.CreateTargetModSkill{ 
	name = "#Wave1st_GangyongTarget", 
	distance_limit_func = function(self, from, card) 
		if from:hasSkill("Wave1st_Gangyong") then
			if card:isKindOf("Slash") then
				return from:getMark("@valour")
			end
		end
	end,
	extra_target_func = function(self, from, card) 
		if from:hasSkill("Wave1st_Gangyong") then
			if card:isKindOf("Slash") then
				if card:isBlack() then
					return from:getMark("@valour")
				end
			end
		end
	end,
	pattern = "Slash" 
}
--[[
	技能：自保（锁定技）
	描述：令自己回复体力时你额外回复一点体力。
	状态：尚未验证
	附注：记忆和计算略复杂，建议修改
]]--
--[[
Wave1st_Zibao = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Zibao", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.HpRecover},  
	on_trigger = function(self, event, player, data) 
		if player:getMark("ZibaoRecover") == 0 then
			local recover = data:toRecover()
			local source = recover.who
			if source and source:objectName() == player:objectName() then
				local room = player:getRoom()
				room:setPlayerMark(player, "ZibaoRecover", 1)
				local recv = sgs.RecoverStruct()
				recv.who = player
				recv.recover = 1
				room:recover(player, recv)
				room:setPlayerMark(player, "ZibaoRecover", 0)
			end
		end
	end
}]]
--明月飞月明提出用PreHpRecover更新结构体完成
Wave1st_Zibao = sgs.CreateTriggerSkill{
	name = "Wave1st_Zibao" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.PreHpRecover} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local recover = data:toRecover()
		if not recover.who then return end
		if recover.who:objectName() ~= player:objectName() then return end
		if recover.card then
			if recover.card:isKindOf("SliverLion") then return end
		end
		recover.recover = recover.recover + 1
		data:setValue(recover)
	end
}

--[[李儒]]--
Wave1st_Liru = sgs.General(extension, "Wave1st_Liru", "qun", "3")
--[[
	技能：毒策
	描述：当除你以外的一名角色打出或使用黑桃牌时，你可弃一张锦囊牌令其选择失去1点体力或失去一项技能。
	状态：尚未验证
	附注：技能一破坏玩家游戏体验，建议大修
]]--
Wave1st_Duce = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Duce", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardUsed, sgs.CardResponsed}, 
	on_trigger = function(self, event, player, data) 
		local spade = nil
		local victim = nil
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			spade = use.card
			victim = use.from
		elseif even == sgs.CardResponsed then
			local resp = data:toResponsed()
			spade = resp.m_card
			victim = resp.m_who
		end
		if spade and spade:getSuit() == sgs.Card_Spade then
			local room = player:getRoom()
			local others = room:getOtherPlayers(victim)
			for _,source in sgs.qlist(others) do
				if source:hasSkill(self:objectName()) then
					if not source:isNude() then
						local trick = room:askForCard(source, "TrickCard|.|.|.", "@DuceTrick")
						if trick then
							local choice = "hp"
							local skills = victim:getVisibleSkillList()
							if not skills:isEmpty() then
								choice = room:askForChoice(source, self:objectName(), "hp+skill")
							end
							if choice == "hp" then
								room:loseHp(victim, 1)
							elseif choice == "skill" then
								local skillnames = {}
								for _,skill in sgs.qlist(skills) do
									table.insert(skillnames, skill:objectName())
								end
								choice = room:askForChoice(source, "DuceSkill", table.concat(skillnames, "+"))
								room:detachSkillFromPlayer(victim, choice, false)
							end
						end
					end
				end
			end
		end
	end, 
	can_trigger = function(self, target) 
		if target then
			return target:isAlive()
		end
		return false
	end
}
--[[
	技能：焚城（限定技）
	描述：出牌阶段，你可指定一名除你以外的角色，你对其造成1点火焰伤害，然后弃置其所有装备牌。
	状态：尚未验证
]]--
Wave1st_FenchengCard = sgs.CreateSkillCard{ 
	name = "Wave1st_FenchengCard", 
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
		source:loseMark("@burn", 1)
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.to = target
		damage.nature = sgs.DamageStruct_Fire
		damage.damage = 1
		room:damage(damage)
		if target:isAlive() then
			target:throwAllEquips()
		end
	end
}
Wave1st_Fencheng = sgs.CreateViewAsSkill{ 
	name = "Wave1st_Fencheng", 
	n = 0, 
	view_as = function(self, cards) 
		return Wave1st_FenchengCard:clone()
	end, 
	enabled_at_play = function(self, player) 
		return player:getMark("@burn") > 0
	end
}
Wave1st_FenchengStart = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Fencheng", 
	frequency = sgs.Skill_Limited, 
	events = {sgs.GameStart}, 
	view_as_skill = Wave1st_Fencheng, 
	on_trigger = function(self, event, player, data) 
		player:gainMark("@burn", 1)
	end, 
	priority = 2
}
--[[伏皇后]]--
Wave1st_Fuhuanghou = sgs.General(extension, "Wave1st_Fuhuanghou", "qun", "3")
--[[
	技能：密笺
	描述：你可以跳过你的出牌阶段并将至少一张手牌交给一名其他角色，然后该角色进行一个额外的出牌阶段，若其于该阶段内未造成过伤害，其失去１点体力。
	状态：尚未验证
]]--
Wave1st_MijianCard = sgs.CreateSkillCard{ 
	name = "Wave1st_MijianCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		room:obtainCard(target, self, false)
		target:gainMark("@letter", 1)
		target:gainAnExtraTurn()
	end
}
Wave1st_MijianVS = sgs.CreateViewAsSkill{ 
	name = "Wave1st_Mijian", 
	n = 999, 
	view_filter = function(self, selected, to_select) 
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards > 0 then
			local card = Wave1st_MijianCard:clone()
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
		return pattern == "@@Mijian"
	end
}
Wave1st_Mijian = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Mijian", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseChanging}, 
	view_as_skill = Wave1st_MijianVS, 
	on_trigger = function(self, event, player, data) 
		local change = data:toPhaseChange()
		if change.to = sgs.Player_Play then
			if not player:isSkipped(sgs.Player_Play) then
				if player:askForSkillInvoke(self:objectName(), data) then
					player:skip(sgs.Player_Play)
					local room = player:getRoom()
					room:askForUseCard(player, "@@Mijian", "@Mijian")
				end
			end
		end
	end
}
Wave1st_MijianEffect = sgs.CreateTriggerSkill{ 
	name = "#Wave1st_MijianEffect", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Damage, sgs.EventPhaseEnd}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			local source = damage.from
			if source and source:objectName() == player:objectName() then
				room:setPlayerMark(player, "MijianSuccess", 1)
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("MijianSuccess") == 0 then
					room:loseHp(player, 1)
				else
					room:setPlayerMark(player, "MijianSuccess", 0)
				end
				player:loseAllMarks("@letter")
			end
		end
	end, 
	can_trigger = function(self, target) 
		if target and target:getMark("@letter") > 0 then
			return target:isAlive()
		end
		return false
	end, 
	priority = 2
}
--[[
	技能：祸族
	描述：你死亡时，可令至多Ｘ名角色依次展示其手牌，并弃置其中的基本牌（Ｘ此回合你受到伤害的点数）
	附注：技能二威慑力不足，建议大修
]]--
--[[朱然]]--
Wave1st_Zhuran = sgs.General(extension, "Wave1st_Zhuran", "wu", "4")
--[[
	技能：胆略
	描述：一名其他角色的回合开始时，你可以弃置不少于你体力值数量的牌，然后将牌堆顶等量的牌置于武将牌上，此回合内每当你失去一次牌后，你可以摸一张牌。此回合结束时，你获得武将牌上所有的牌。
	状态：尚未验证
]]--
Wave1st_DanlveCard = sgs.CreateSkillCard{ 
	name = "Wave1st_DanlveCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		local count = self:subcardsLength()
		local ids = room:drawCards(count)
		source:addToPile("danlve", ids, false)
		room:setPlayerMark(source, "DanlveInvoked", 1)
	end
}
Wave1st_DanlveVS = sgs.CreateViewAsSkill{ 
	name = "Wave1st_Danlve", 
	n = 999, 
	view_filter = function(self, selected, to_select) 
		return true
	end, 
	view_as = function(self, cards) 
		local hp = sgs.Self:getHp()
		if #cards >= hp then
			local card = Wave1st_DanlveCard:clone()
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
		return pattern == "@@Danlve"
	end
}
Wave1st_Danlve = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Danlve", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = Wave1st_DanlveVS, 
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local others = room:getOtherPlayers(player)
			for _,source in sgs.qlist(others) do
				if source:hasSkill(self:objectName()) then
					local hp = source:getHp()
					local cards = source:getCards("he")
					if cards:length() >= hp then
						if source:askForSkillInvoke(self:objectName(), data) then
							room:askForUseCard(source, "@@Danlve", "@Danlve")
						end
					end
				end
			end
		end
	end, 
	can_trigger = function(self, target) 
		if target then
			return target:isAlive()
		end
		return false
	end
}
Wave1st_DanlveEffect = sgs.CreateTriggerSkill{ 
	name = "#Wave1st_DanlveEffect", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				local places = move.from_places
				if places:contains(sgs.Player_PlaceHand) or places:contains(sgs.Player_PlaceEquip) then
					if player:askForSkillInvoke("Wave1st_Danlve", data) then
						room:drawCards(player, 1, "Wave1st_Danlve")
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			local current = room:getCurrent()
			if current:getPhase() == sgs.Player_Finish then
				local danlvelist = player:getPile("danlve")
				if not danlvelist:isEmpty() then
					for _,id in sgs.qlist(danlvelist) do
						room:obtainCard(player, id, false)
					end
				end
				room:setPlayerMark(player, "DanlveInvoked", 0)
			end
		end
	end, 
	can_trigger = function(self, target) 
		if target then
			if target:isAlive() then
				return target:getMark("DanlveInvoked") > 0
			end
		end
		return false
	end, 
	priority = 2
}
Wave1st_DanlveClear = sgs.CreateTriggerSkill{ 
	name = "#Wave1st_DanlveClear", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventLoseSkill}, 
	on_trigger = function(self, event, player, data) 
		if data:toString() == "Wave1st_Danlve" then
			player:removePileByName("danlve")
		end
	end
	priority = 2
}
--[[虞翻]]--
Wave1st_Yufan = sgs.General(extension, "Wave1st_Yufan", "wu", "3")
--[[
	技能：渊硕
	描述：出牌阶段,你可弃置一张手牌并选择一项执行:
		1.观看一名其他角色的至多两张手牌；
		2.令一名角色恢复一点体力，对每名角色只能发动一次；
		3.指定一名装备区没有牌的角色.若如此做,该角色可获得场上任意一张由你指定的装备牌。
	状态：尚未验证
	附注：描述及效果略复杂，且记忆问题较大，无联动，我自己都不知道谁选的，虽然2技能契合不错
	问题：观看手牌的流程是怎样的？由自己选还是该角色选？是一张张地看还是一次性展示所有选牌？
		在什么时间段内对每名角色只能发动一次？是本阶段（每阶段限一次）、本回合（考虑当先）还是整局游戏（类似颂词）？
	暂解：先定为由自己选择并一张张地观看所选牌。
		每阶段对每名角色只能发动一次（毕竟这个技能本身没有限制阶段发动次数，只要有手牌就可以一个阶段内多次发动）。
]]--
Wave1st_YuanshuoShowCard = sgs.CreateSkillCard{ 
	name = "Wave1st_YuanshuoShowCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			if not to_select:isKongcheng() then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		local card_ids = target:handCards()
		for i=1, 2, 1 do
			if not card_ids:isEmpty() then
				if source:askForSkillInvoke(self:objectName()) then
					local count = card_ids:length()
					local index = math.random(0, count-1)
					local id = card_ids:at(index)
					room:showCard(target, id, source)
					card_ids:removeOne(id)
				end
			end
		end
	end
}
Wave1st_YuanshuoRecoverCard = sgs.CreateSkillCard{ 
	name = "Wave1st_YuanshuoRecoverCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			if to_select:isWounded() then
				return not to_select:hasFlag("YuanshuoRecoverTarget")
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		local recover = sgs.RecoverStruct()
		recover.who = source
		recover.recover = 1
		room:recover(target, recover)
		room:setPlayerFlag(target, "YuanshuoRecoverTarget")
	end
}
Wave1st_YuanshuoObtainCard = sgs.CreateSkillCard{ 
	name = "Wave1st_YuanshuoObtainCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return not to_select:hasEquip()
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		local alives = room:getAlivePlayers()
		local equip_owners = sgs.SPlayerList()
		for _,p in sgs.qlist(alives) do
			if p:hasEquip() then
				equip_owners:append(p)
			end
		end
		if not equip_owners:isEmpty() then
			local owner = room:askForPlayerChosen(source, equip_owners, self:objectName())
			local id = room:askForCardChosen(source, owner, "e", self:objectName())
			room:obtainCard(target, id, true)
		end
	end
}
Wave1st_YuanshuoCard = sgs.CreateSkillCard{ 
	name = "Wave1st_YuanshuoCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		local choice == room:askForChoice(source, self:objectName(), "show+recover+obtain")
		if choice == "show" then
			room:setPlayerMark(source, "YuanshuoChoice", 1)
			room:askForUseCard(source, "@@Yuanshuo", "@YuanshuoShow")
		elseif choice == "recover" then
			room:setPlayerMark(source, "YuanshuoChoice", 2)
			room:askForUseCard(source, "@@Yuanshuo", "@YuanshuoRecover")
		elseif choice == "obtain" then
			room:setPlayerMark(source, "YuanshuoChoice", 3)
			room:askForUseCard(source, "@@Yuanshuo", "@YuanshuoObtain")
		end
		room:setPlayerMark(source, "YuanshuoChoice", 0)
	end
}
Wave1st_Yuanshuo = sgs.CreateViewAsSkill{ 
	name = "Wave1st_Yuanshuo", 
	n = 1, 
	view_filter = function(self, selected, to_select) 
		local mark = sgs.Self:getMark("YuanshuoChoice")
		if mark == 0 then
			if #selected == 0 then
				return not to_select:isEquipped()
			end
		end
		return false
	end, 
	view_as = function(self, cards) 
		local mark = sgs.Self:getMark("YuanshuoChoice")
		if mark == 0 then
			if #cards == 1 then
				local card = Wave1st_YuanshuoCard:clone()
				card:addSubcard(cards[1])
				return card
			end
		elseif mark == 1 then
			if #cards == 0 then
				return Wave1st_YuanshuoShowCard:clone()
			end
		elseif mark == 2 then
			if #cards == 0 then
				return Wave1st_YuanshuoRecoverCard:clone()
			end
		elseif mark == 3 then
			if #cards == 0 then
				return Wave1st_YuanshuoObtainCard:clone()
			end
		end
	end, 
	enabled_at_play = function(self, player) 
		return not player:isKongcheng()
	end, 
	enabled_at_response = function(self, player, pattern) 
		return pattern == "@@Yuanshuo"
	end
}
--[[
	技能：耿烈（锁定技）
	描述：当场上有角色对与其同势力角色造成伤害后,你弃置伤害来源的两张牌或对其造成1点伤害。
	状态：尚未验证
	附注：Fs：2技能个人认为应该改。身份局除了主公技之外不应涉及势力
	问题：某角色对自己造成的伤害是否算对同势力角色造成的伤害？
	暂解：算是吧……毕竟没有约定“同势力的其他角色”。
]]--
Wave1st_Genglie = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Genglie", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damage}, 
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local source = damage.from
		if source and source:objectName() == player:objectName() then
			local victim = damage.to
			if victim and victim:getKingdom() == source:getKingdom() then
				local room = player:getRoom()
				local alives = room:getAlivePlayers()
				for _,police in sgs.qlist(alives) do
					if police:hasSkill(self:objectName()) then
						local choice = "damage"
						local cards = source:getCards("he")
						if cards:length() >= 2 then
							choice = room:askForChoice(police, self:objectName(), "discard+damage")
						end
						if choice == "discard" then
							room:askForDiscard(source, self:objectName(), 2, 2, false, true, "@GenglieDiscard")
						elseif choice == "damage" then
							local new_damage = sgs.DamageStruct()
							new_damage.from = police
							new_damage.to = source
							new_damage.damage = 1
							room:damage(new_damage)
						end
					end
				end
			end
		end
	end, 
	can_trigger = function(self, target) 
		if target then
			return target:isAlive()
		end
		return false
	end
}
--[[潘璋马忠]]--
Wave1st_PanzhangMazhong = sgs.General(extension, "Wave1st_PanzhangMazhong", "wu", "4")
Wave1st_Anjiang = sgs.General(extension, "Wave1st_Anjiang", "god", "5")
--[[
	技能：暗箭
	描述：在你的回合内你可以弃置一张“箭”令一名角色失去一点体力然后立即结束该回合；回合外将要受到伤害时你可以弃置一张“箭”令该伤害-1
	状态：尚未验证
]]--
Wave1st_AnjianCard = sgs.CreateSkillCard{ 
	name = "Wave1st_AnjianCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return #targets == 0
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		local arrows = source:getPile("arrow")
		room:fillAG(arrows, source)
		local id = room:askForAG(source, arrows, false, self:objectName())
		room:throwCard(id, source, source)
		source:invoke("clearAG")
		room:loseHp(target, 1)
		source:setPhase(sgs.Player_NotActive)
	end
}
Wave1st_Anjian = sgs.CreateViewAsSkill{ 
	name = "Wave1st_Anjian", 
	n = 0, 
	view_as = function(self, cards) 
		return Wave1st_AnjianCard:clone()
	end, 
	enabled_at_play = function(self, player) 
		local arrows = player:getPile("arrow")
		return not arrows:isEmpty()
	end
}
Wave1st_Anjiang:addSkill(Wave1st_Anjian)
--[[
	技能：避锋
	描述：当你造成或受到伤害时，可摸一张牌并将一张黑色牌置于武将牌上称之为“箭”，你可以将“箭”当无视距离和防具的杀使用，若造成伤害，你立即结束该回合。
	状态：尚未验证（没有处理与目标增强技相关的内容，此杀目前只能指定单一目标）
]]--
Wave1st_BifengCard = sgs.CreateSkillCard{ 
	name = "Wave1st_BifengCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		local arrows = source:getPile("arrow")
		room:fillAG(arrows, source)
		local id = room:askForAG(source, arrows, false, self:objectName())
		room:takeAG(source, id)
		source:invoke("clearAG")
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:addSubcard(id)
		slash:setSkillName(self:objectName())
		local alives = room:getAlivePlayers()
		local victims = sgs.SPlayerList()
		for _,p in sgs.qlist(alives) do
			if source:canSlash(p, slash, false) then
				victims:append(p)
			end
		end
		if not victims:isEmpty() then
			local target = room:askForPlayerChosen(source, victims, self:objectName())
			room:setPlayerMark(target, "qinggang", 1)
			local use = sgs.CardUseStruct()
			use.card = slash
			use.from = source
			use.to:append(target)
			room:useCard(use, true)
			room:setPlayerMark(target, "qinggang", 0)
		end
	end
}
Wave1st_BifengVS = sgs.CreateViewAsSkill{ 
	name = "Wave1st_Bifeng", 
	n = 0, 
	view_as = function(self, cards) 
		return Wave1st_BifengCard:clone()
	end, 
	enabled_at_play = function(self, player) 
		local arrows = player:getPile("arrow")
		return not arrows:isEmpty()
	end
}
Wave1st_Bifeng = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Bifeng", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageCaused}, 
	view_as_skill = Wave1st_BifengVS, 
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local flag = false
		local source = damage.from
		local victim = damage.to
		if source and source:objectName() == player:objectName() then
			flag = true
		elseif victim and victim:objectName() == player:objectName() then
			flag = true
		end
		if flag then
			if player:askForSkillInvoke(self:objectName(), data) then
				local room = player:getRoom()
				room:drawCards(player, 1, self:objectName())
				local arrow = room:askForCard(player, ".|spade,club|.|.", "@Bifeng", data, self:objectName())
				if arrow then
					player:addToPile("arrow", arrow, true)
				end
			end
		end
	end
}
Wave1st_BifengEffect = sgs.CreateTriggerSkill{ 
	name = "#Wave1st_BifengEffect", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Damaged}, 
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local slash = damage.card
		if slash and slash:isKindOf("Slash") then
			if slash:getSkillName() == "Wave1st_BifengCard" then
				local room = player:getRoom()
				local current = room:getCurrent()
				current:setPhase(sgs.Player_NotActive)
			end
		end
	end
	priority = 2
}
--[[
	技能：伺机（觉醒技）
	描述：回合开始阶段，当你的“箭”达到3张或更多时你失去一点体力上限然后获得技能“暗箭 ”（在你的回合内你可以弃置一张“箭”令一名角色失去一点体力然后立即结束该回合；回合外将要受到伤害时你可以弃置一张“箭”令该伤害-1）。
	状态：尚未验证
]]--
Wave1st_Siji = sgs.CreateTriggerSkill{ 
	name = "Wave1st_Siji", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Start then
			local arrows = player:getPile("arrow")
			if arrows:length() >= 3 then
				local room = player:getRoom()
				room:setPlayerMark(player, "SijiWaked", 1)
				room:loseMaxHp(player, 1)
				room:acquireSkill(player, "Wave1st_Anjian")
				player:gainMark("@waked", 1)
			end
		end
	end, 
	can_trigger = function(self, target) 
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				return target:getMark("SijiWaked") == 0 
			end
		end
		return false
	end
}
--[[添加技能]]--
Wave1st_Caochong:addSkill(Wave1st_Renhui)
Wave1st_Caochong:addSkill(Wave1st_Tianyi)
Wave1st_Guohuai:addSkill(Wave1st_Moudong)
Wave1st_Manchong:addSkill(Wave1st_Mingsen)
Wave1st_Jianyong:addSkill(Wave1st_Zhaode)
Wave1st_Jianyong:addSkill(Wave1st_Zongjie)
--Wave1st_Guanping:addSkill()
--Wave1st_Guanping:addSkill()
Wave1st_Liufeng:addSkill(Wave1st_Gangyong)
Wave1st_Liufeng:addSkill(Wave1st_GangyongTarget)
Wave1st_Liufeng:addSkill(Wave1st_Zibao)
Wave1st_Liru:addSkill(Wave1st_Duce)
Wave1st_Liru:addSkill(Wave1st_FenchengStart)
Wave1st_Fuhuanghou:addSkill(Wave1st_Mijian)
Wave1st_Fuhuanghou:addSkill(Wave1st_MijianEffect)
--Wave1st_Fuhuanghou:addSkill()
Wave1st_Zhuran:addSkill(Wave1st_Danlve)
Wave1st_Zhuran:addSkill(Wave1st_DanlveEffect)
Wave1st_Zhuran:addSkill(Wave1st_DanlveClear)
Wave1st_Yufan:addSkill(Wave1st_Yuanshuo)
Wave1st_Yufan:addSkill(Wave1st_Genglie)
Wave1st_PanzhangMazhong:addSkill(Wave1st_Bifeng)
Wave1st_PanzhangMazhong:addSkill(Wave1st_BifengEffect)
Wave1st_PanzhangMazhong:addSkill(Wave1st_Siji)
--[[翻译表]]--
sgs.LoadTranslationTable{
    ["wave1st"] = "第一波",
	
	["Wave1st_Caochong"] = "曹冲",
	["#Wave1st_Caochong"] = "早夭的神童",
	["designer:Wave1st_Caochong"] = "",
	["cv:Wave1st_Caochong"] = "",
	["illustrator:Wave1st_Caochong"] = "",
	
	[""] = "",
	[":"] = "",
	
	[""] = "",
	[":"] = "",
	
	["Wave1st_Guohuai"] = "郭淮",
	["#Wave1st_Guohuai"] = "垂问秦雍",
	["designer:Wave1st_Guohuai"] = "",
	["cv:Wave1st_Guohuai"] = "",
	["illustrator:Wave1st_Guohuai"] = "",
	
	[""] = "",
	[":"] = "",
	
	["Wave1st_Manchong"] = "满宠",
	["#Wave1st_Manchong"] = "刚肃严明",
	["designer:Wave1st_Manchong"] = "",
	["cv:Wave1st_Manchong"] = "",
	["illustrator:Wave1st_Manchong"] = "",
	
	[""] = "",
	[":"] = "",
	
	["Wave1st_Jianyong"] = "简雍",
	["#Wave1st_Jianyong"] = "昭德将军",
	["designer:Wave1st_Jianyong"] = "",
	["cv:Wave1st_Jianyong"] = "",
	["illustrator:Wave1st_Jianyong"] = "",
	
	[""] = "",
	[":"] = "",
	
	[""] = "",
	[":"] = "",
	
	["Wave1st_Guanping"] = "关平",
	["#Wave1st_Guanping"] = "真武的传承",
	["designer:Wave1st_Guanping"] = "",
	["cv:Wave1st_Guanping"] = "",
	["illustrator:Wave1st_Guanping"] = "",
	
	[""] = "",
	[":"] = "",
	
	["Wave1st_Liufeng"] = "刘封",
	["#Wave1st_Liufeng"] = "螟蛉之悲",
	["designer:Wave1st_Liufeng"] = "",
	["cv:Wave1st_Liufeng"] = "",
	["illustrator:Wave1st_Liufeng"] = "",
	
	[""] = "",
	[":"] = "",
	
	[""] = "",
	[":"] = "",
	
	["Wave1st_Liru"] = "李儒",
	["#Wave1st_Liru"] = "助纣为虐",
	["designer:Wave1st_Liru"] = "",
	["cv:Wave1st_Liru"] = "",
	["illustrator:Wave1st_Liru"] = "",
	
	[""] = "",
	[":"] = "",
	
	[""] = "",
	[":"] = "",
	
	["Wave1st_Fuhuanghou"] = "伏皇后",
	["#Wave1st_Fuhuanghou"] = "悲鸣之凰",
	["designer:Wave1st_Fuhuanghou"] = "",
	["cv:Wave1st_Fuhuanghou"] = "",
	["illustrator:Wave1st_Fuhuanghou"] = "",
	
	[""] = "",
	[":"] = "",
	
	[""] = "",
	[":"] = "",
	
	["Wave1st_Zhuran"] = "朱然",
	["#Wave1st_Zhuran"] = "不破之城",
	["designer:Wave1st_Zhuran"] = "",
	["cv:Wave1st_Zhuran"] = "",
	["illustrator:Wave1st_Zhuran"] = "",
	
	[""] = "",
	[":"] = "",
	
	["Wave1st_Yufan"] = "虞翻",
	["#Wave1st_Yufan"] = "刚正之魂",
	["designer:Wave1st_Yufan"] = "",
	["cv:Wave1st_Yufan"] = "",
	["illustrator:Wave1st_Yufan"] = "",
	
	[""] = "",
	[":"] = "",
	
	[""] = "",
	[":"] = "",
	
	["Wave1st_PanzhangMazhong"] = "潘璋&马忠",
	["#Wave1st_PanzhangMazhong"] = "猎杀者",
	["designer:Wave1st_PanzhangMazhong"] = "",
	["cv:Wave1st_PanzhangMazhong"] = "",
	["illustrator:Wave1st_PanzhangMazhong"] = "",
	
	[""] = "",
	[":"] = "",
	
	[""] = "",
	[":"] = "",
}

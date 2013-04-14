--[[
  扩展包信息
	全称：“失落的三将”扩展武将测试之魏I包
	名称：魏I包（wei001）
	武将：共1名
		郭淮（精备、整顿）
	版本号：20130224
]]--
module("extensions.wei001", package.seeall)
extension = sgs.Package("wei001")

sgs.LoadTranslationTable{
    ["wei001"] = "魏I包",

	["Wei001_Guohuai"] = "郭淮",
	["&Wei001_Guohuai"] = "郭淮",
	["#Wei001_Guohuai"] = "垂问秦雍",
	["designer:Wei001_Guohuai"] = "待查",
	["cv:Wei001_Guohuai"] = "无",
	["illustrator:Wei001_Guohuai"] = "待查",

	["Wei001_Jingbei"] = "精备",
	[":Wei001_Jingbei"] = "你拥有额外的手牌/装备区各一个，你须声明用其中的一个手牌/装备区进行游戏，未进行游戏的手牌/装备区视为移出游戏，在你的每个回合开始时和结束后，你可以声明替换同类型区域。",
	["replaceequip"] = "替换装备",
	["replacehandcard"] = "替换手牌",
	["notreplace"] = "不替换" ,
	["equip2nd"] = "装备" ,
	["handcard2nd"] = "手牌" ,

	["Wei001_Zhengdun"] = "整顿",
	[":Wei001_Zhengdun"] = "出牌阶段，你可以将任意张装备区里的牌置于手牌中，每阶段限一次。",
	
}

Wei001_Guohuai = sgs.General(extension, "Wei001_Guohuai", "wei")

--[[你拥有额外的手牌/装备区各一个，你须声明用其中的一个手牌/装备区进行游戏，未进行游戏
的手牌/装备区视为移出游戏，在你的每个回合开始时和结束后，你可以声明替换同类型区域。]]
--[[已知问题（不知道是否算Bug）在装备替换时会触发装备技能比如白银狮子会加血]]
Wei001_Jingbei = sgs.CreateTriggerSkill{
	name = "Wei001_Jingbei" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Start then return end
		else
			if player:getPhase() ~= sgs.Player_Finish then return end
		end
		local room = player:getRoom()
		local choice = "replaceequip+notreplace"
		if room:askForChoice(player, self:objectName(), choice, sgs.QVariant()) == "replaceequip" then
			local equippile = player:getPile("equip2nd")
			local currentequip = player:getEquips()
			-------------DummyCard法-----------------
			local equipdummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, c in sgs.qlist(currentequip) do
				equipdummy:addSubcard(c)
			end
			player:addToPile("equip2nd", equipdummy, true)
			-----------------------------------------
			for _, i in sgs.qlist(equippile) do
				local realcard = sgs.Sanguosha:getCard(i)
				room:moveCardTo(realcard, player, sgs.Player_PlaceEquip)
			end
		end
		choice = "replacehandcard+notreplace"
		if room:askForChoice(player, self:objectName(), choice, sgs.QVariant()) == "replacehandcard" then
			local handcardpile = player:getPile("handcard2nd") 
			local currenthandcard = player:handCards() 
			---------------DummyCard法------------------
			local handcarddummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, c in sgs.qlist(currenthandcard) do
				handcarddummy:addSubcard(c)
			end
			player:addToPile("handcard2nd", handcarddummy, false)
			local handcard2nddummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, i in sgs.qlist(handcardpile) do
				handcard2nddummy:addSubcard(i)
			end
			player:obtainCard(handcard2nddummy, false)
		end
	end
}

--[[出牌阶段，你可以将任意张装备区里的牌置于手牌中，每阶段限一次。]]
Wei001_ZhengdunCard = sgs.CreateSkillCard{
	name = "Wei001_Zhengdun" ,
	target_fixed = true ,
	will_throw = false ,
	on_use = function(self, room, source, targets)
		local cards = self:getSubcards()
		for _, i in sgs.qlist(cards) do
			local card = sgs.Sanguosha:getCard(i)
			room:moveCardTo(card, source, sgs.Player_PlaceHand)
		end
	end
}
Wei001_Zhengdun = sgs.CreateViewAsSkill{
	name = "Wei001_Zhengdun" ,
	n = 4, 
	view_filter = function(self, selected, to_select)
		return to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards ~= 0 then
			local card = Wei001_ZhengdunCard:clone()
			for i = 1, #cards, 1 do
				card:addSubcard(cards[i])
			end
			return card
		end
	end,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#Wei001_Zhengdun")
	end
}

Wei001_Guohuai:addSkill(Wei001_Jingbei)
Wei001_Guohuai:addSkill(Wei001_Zhengdun)

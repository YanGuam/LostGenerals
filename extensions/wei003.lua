--[[
	扩展包信息
	全称：“失落的三将”扩展武将测试之魏III包
	名称：魏III包（wei003）
	武将：共1名
		满宠（严拷）
	版本号：20130224
]]--
module("extensions.wei003", package.seeall)
extension = sgs.Package("wei003")
--[[满宠]]--
Wei003_Manchong = sgs.General(extension, "Wei003_Manchong", "wei", "4")
--[[
	技能：严拷
	描述：出牌阶段，你可以令一名武将牌未横置的其他角色选择一项: 
		1、让你弃置其一张牌；
		2、跟你进行拼点，若你赢，则你获得其一张牌并横置其武将牌，此时你可以立即对另一名武将牌未横置的角色发动"严拷"，若你没赢，则你进入弃牌阶段，并该角色可以令至多两名角色的武将牌重置之。
		每阶段限一次。
	状态：设计中
]]--
Wei003_YankaoCard = sgs.CreateSkillCard{ 
	name = "Wei003_YankaoCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			if not to_select:hasFlag("YankaoUsed") then
				if to_select:objectName() ~= sgs.Self:objectName() then
					if not to_select:isChained() then
						return not to_select:isNude()
					end
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets) 
		local target = targets[1]
		local choice = ""
		if source:isKongcheng() or target:isKongcheng() then
			choice = "discard"
		else
			choice = room:askForChoice(target, self:objectName(), "discard+pindian")
		end
		if choice == "discard" then
			local id = room:askForCardChosen(source, target, "he", self:objectName())
			room:throwCard(id, target, source)
		elseif choice == "pindian" then
			local success = source:pindian(target, self:objectName(), nil)
			if success then
				local id = room:askForCardChosen(source, target, "he", self:objectName())
				room:obtainCard(source, id, false)
				target:setChained(true)
				room:setPlayerFlag(target, "YankaoUsed")
				room:askForUseCard(source, "@@Wei003_Yankao", "@@Wei003_Yankao")
			else
				--< Warning! >--
			end
		end
	end
}
Wei003_Yankao = sgs.CreateViewAsSkill{ 
	name = "Wei003_Yankao", 
	n = 0, 
	view_as = function(self, cards) 
		return Wei003_YankaoCard:clone()
	end, 
	enabled_at_play = function(self, player) 
		return not player:hasUsed("#Wei003_YankaoCard")
	end,
	enabled_at_response = function(self, player, pattern) 
		return pattern == "@@Wei003_Yankao"
	end
}
--[[添加技能]]--
Wei003_Manchong:addSkill(Wei003_Yankao)
--[[翻译表]]--
sgs.LoadTranslationTable{
    ["wei002"] = "魏III包",
	
	["Wei003_Manchong"] = "满宠",
	["&Wei003_Manchong"] = "满宠",
	["#Wei003_Manchong"] = "严酷的审问师",
	["designer:Wei003_Manchong"] = "待查",
	["cv:Wei003_Manchong"] = "无",
	["illustrator:Wei003_Manchong"] = "待查",
	
	["Wei003_Yankao"] = "严拷",
	[":Wei003_Yankao"] = "出牌阶段，你可以令一名武将牌未横置的其他角色选择一项: \
	1、让你弃置其一张牌；\
	2、跟你进行拼点，若你赢，则你获得其一张牌并横置其武将牌，此时你可以立即对另一名武将牌未横置的角色发动"严拷"，若你没赢，则你进入弃牌阶段，并该角色可以令至多两名角色的武将牌重置之。\
	每阶段限一次。",
	["Wei003_YankaoCard"] = "严拷",
}
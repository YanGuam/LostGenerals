
sgs.ai_skill_invoke.Wei004_Nieyi = function(self, data)
	local damage = data:toDamage()
	local caninvoke = true
	if damage then
		if self:isWeak() then
			if self.player:getHp() == 1 then
				caninvoke = false
			else
				if not ((damage.to:getHp() == 1) and (damage.to:getHandcardNum() == 0)) then
					caninvoke = false
				end
			end
		end
		if self:hasEquip() then 
			caninvoke = true
		end
		if caninvoke then
			return self:isFriend(damage.to)
		else
			return false
		end
	end
end

sgs.ai_skill_choice.Wei004_Nieyi = "nieyidiscardequip"



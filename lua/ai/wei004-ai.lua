
sgs.ai_skill_invoke.Wei004_Nieyi = function(self, data)
	local damage = data:toDamage()
	if damage then
		if (self:isWeak()) and (self.player:getHp() > 1) then
			if not self:hasEquip() then 
				return (damage.to:getHp() == 1) and (damage.to:getHandcardNum() == 0)
			end
		end
		return self:isFriend(damage.to)
	end
end

sgs.ai_skill_choice.Wei004_Nieyi = "nieyidiscardequip"



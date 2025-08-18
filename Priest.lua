MyrkPriest = {
}

function MyrkPriest:PriestOffense()
  local m=UnitMana("player")/UnitManaMax("player");
  if m>0.6 and UnitExists("target") and not UnitIsFriend("player","target") then 
    CastSpellByName("Smite"); 
  else 
    UIErrorsFrame:AddMessage("Not enough mana (>60%) or no hostile target.",1,0.2,0.2); 
  end
end



def checkCode

  codeBank = [
  "HIPPY","VORTEX","FISHHEAD",
  "EASTER***","HALLOWEEN***","CHRISTMAS***",
  "V0.10"
  ];
  if !($usedCodes.is_a?(Array))
    $usedCodes = Array.new
  end

  code = pbEnterText(_INTL("Code?"),0,10,"")

  if codeBank.include?(code.upcase)

      if $usedCodes.include?(code.upcase)
        pbMessage(_INTL("You have already redeemed this code."))
      else
        pbMessage(_INTL("A successful Code!"))

        case (code.upcase)
          when "HIPPY"; pkmn = pbGenPkmn(:ZORUA,5)
            pkmn.owner.name = "Hippy"
            pkmn.shiny = true
          when "VORTEX"; pkmn = pbGenPkmn(:RALTS,5)
            pkmn.owner.name = "Vortex"
            pkmn.shiny = true
            pkmn.makeFemale
          when "FISHHEAD"; pkmn = pbGenPkmn(:APPLIN,5)
            pkmn.owner.name = "FishHead"
            pkmn.shiny = true
            pkmn.item = :SWEETAPPLE
          when "EASTER***"; pkmn = pbGenPkmn(:EXEGGCUTE,5)
            pkmn.owner.name = "???"
            pkmn.shiny = true
          when "HALLOWEEN***"; pkmn = pbGenPkmn(:PUMPKABOO,5)
            pkmn.owner.name = "???"
            pkmn.shiny = true
            pkmn.item = :RARECANDY
          when "CHRISTMAS***"; pkmn = pbGenPkmn(:DELIBIRD,5)
            pkmn.owner.name = "???"
            pkmn.shiny = true
            pkmn.item = :ABILITYCAPSULE
          when "V0.10"; pkmn = pbGenPkmn(:BIDOOF,5)
            pkmn.owner.name = "???"
            pkmn.shiny = true
            pkmn.ability = :MOODY
            pkmn.learn_move(:THIEF)
            pkmn.item = :ABILITYCAPSULE
        end

        if pkmn
          pkmn.owner.id = 00000
          pkmn.poke_ball = :CHERISHBALL
          pbAddPokemon(pkmn)
        end

        $usedCodes.push(code.upcase)
      end

  else
    pbMessage(_INTL("{1} is not a valid code.",code))
  end

end

def randFossil
    case rand (15)
      when 0; pbReceiveItem(:HELIXFOSSIL,1) # Omanyte
      when 1; pbReceiveItem(:DOMEFOSSIL,1) # Kabuto
      when 2; pbReceiveItem(:OLDAMBER,1) # Aerodactyl
      when 3; pbReceiveItem(:ROOTFOSSIL,1) # Lileep
      when 4; pbReceiveItem(:CLAWFOSSIL,1) # Anorith
      when 5; pbReceiveItem(:SKULLFOSSIL,1) # Cranidos
      when 6; pbReceiveItem(:ARMORFOSSIL,1) # Shieldon
      when 7; pbReceiveItem(:COVERFOSSIL,1) # Tirtouga
      when 8; pbReceiveItem(:PLUMEFOSSIL,1) # Archen
      when 9; pbReceiveItem(:JAWFOSSIL,1) # Tyrunt
      when 10; pbReceiveItem(:SAILFOSSIL,1) # Amaura
      when 11; pbReceiveItem(:FOSSILIZEDBIRD,1)
      when 12; pbReceiveItem(:FOSSILIZEDFISH,1)
      when 13; pbReceiveItem(:FOSSILIZEDDRAKE,1)
      when 14; pbReceiveItem(:FOSSILIZEDDINO,1)
    end
end

def searchFossils
  if pbConfirmMessage(_INTL("Would you like to search the rock for fossils?"))
    case rand(12)
      when 0..9; randFossil
      when 10; pbMessage(_INTL("The rock was packed full of fossils."))
        randFossil
        randFossil
        randFossil
      when 11; pbMessage(_INTL("The rock didn't have any fossils inside."))
    end
  end
end


def pbMergeFossils
  if $game_variables[53] == 686 && $game_variables[54] == 688
    pbMessage(_INTL("Here is your new Pokemon!"))
    pbAddPokemon(:DRACOZOLT,20)
    $PokemonBag.pbDeleteItem(686,1)
    $PokemonBag.pbDeleteItem(688,1)
  elsif $game_variables[53] == 686 && $game_variables[54] == 689
    pbMessage(_INTL("Here is your new Pokemon!"))
    pbAddPokemon(:ARCTOZOLT,20)
    $PokemonBag.pbDeleteItem(686,1)
    $PokemonBag.pbDeleteItem(689,1)
  elsif $game_variables[53] == 687 && $game_variables[54] == 688
   pbMessage(_INTL("Here is your new Pokemon!"))
     pbAddPokemon(:DRACOVISH,20)
    $PokemonBag.pbDeleteItem(687,1)
    $PokemonBag.pbDeleteItem(688,1)
  elsif $game_variables[53] == 687 && $game_variables[54] == 689
    pbMessage(_INTL("Here is your new Pokemon!"))
    pbAddPokemon(:ARCTOVISH,20)
    $PokemonBag.pbDeleteItem(687,1)
    $PokemonBag.pbDeleteItem(689,1)
  else
    pbMessage(_INTL("I will return this fossil to you then."))
  end
  $game_variables[53] = 0
  $game_variables[54] = 0
end

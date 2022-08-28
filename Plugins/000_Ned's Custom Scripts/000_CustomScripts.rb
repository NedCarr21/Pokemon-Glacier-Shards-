def gsRoamingBattle(species, minlevel, maxlevel)
  species = GameData::Species.get(species).id
    level = rand(minlevel, maxlevel)
    handled = [nil]
    species.makeShiny if rand(80) == 1

  Events.onWildBattleOverride.trigger(nil,species,level,handled)
    return handled[0] if handled[0]!=nil

  decision = pbWildBattleCore(species, level)
  Events.onWildBattleEnd.trigger(nil,species,level,decision)

  return (decision!=2 && decision!=5)
end

def rareDexEval
  seen = 0
  owned = 0
  seen = $Trainer.pokedexSeen(3)
  $game_variables[91] = seen
  owned = $Trainer.pokedexOwned(3)
  $game_variables[92] = owned
end

def randRareItem
  case rand(73)
    when 0; pbReceiveItem(:LUCKYEGG,1)
    when 1..2; pbReceiveItem(:RAREBONE,1)
    when 3..5; pbReceiveItem(:BASICBAIT,5)
    when 6..7; pbReceiveItem(:SWEETBAIT,3)
    when 8; pbReceiveItem(:SPECIALTYBAIT,1)
    when 9..14; pbReceiveItem(:POTION,9)
    when 15..19; pbReceiveItem(:SUPERPOTION,5)
    when 20..23; pbReceiveItem(:HYPERPOTION,1)
    when 24..26; pbReceiveItem(:MONOBALL,2)
    when 27..28; pbReceiveItem(:DUELBALL,1)
    when 29..30; pbReceiveItem(:SNOWBALLBALL,1)
    when 31..33; pbReceiveItem(:POKEBALL,7)
    when 34..36; pbReceiveItem(:GREATBALL,5)
    when 37..39; pbReceiveItem(:ULTRABALL,3)
    when 40; pbReceiveItem(:OMEGABALL,1)
    when 41; pbReceiveItem(:MAXREPEL,1)
    when 42..44; pbReceiveItem(:EXPCANDYXS,4)
    when 45..46; pbReceiveItem(:EXPCANDYS,3)
    when 47..48; pbReceiveItem(:EXPCANDYM,2)
    when 49; pbReceiveItem(:EXPCANDYL,1)
    when 50; pbReceiveItem(:NUGGET,1)
    when 51; pbReceiveItem(:BIGNUGGET,1)
    when 52; pbReceiveItem(:PEARL,1)
    when 53; pbReceiveItem(:BIGPEARL,1)
    when 54; pbReceiveItem(:PEARLSTRING,1)
    when 55; pbReceiveItem(:STARPIECE,1)
    when 56; pbReceiveItem(:COMETSHARD,1)
    when 57..59; pbReceiveItem(:TINYMUSHROOM,2)
    when 60..61; pbReceiveItem(:BIGMUSHROOM,1)
    when 62; pbReceiveItem(:BALMMUSHROOM,1)
    when 63..64; pbReceiveItem(:RARECANDY,1)
    when 65..68; pbReceiveItem(:HEARTSCALE,3)
    when 69..72; pbReceiveItem(:HEARTSCALE,1)
  end
end

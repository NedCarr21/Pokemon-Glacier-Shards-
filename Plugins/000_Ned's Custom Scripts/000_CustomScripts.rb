def gsRoamingBattle(species1, minlevel, maxlevel)
    species = GameData::Species.get(species1).id
    level = rand(minlevel, maxlevel)
    Pokemon.play_cry(species)
    pbWait(12)
    WildBattle.start(species,level)
end

def rareDexEval
  seen = 0
  owned = 0
  seen = $Trainer.pokedexSeen(3)
  $game_variables[91] = seen
  owned = $Trainer.pokedexOwned(3)
  $game_variables[92] = owned
end

ITEMARR = [ #[:ITEM,QUANTITY,WEIGHT]
  [:LUCKYEGG,1,1],
  [:RAREBONE,1,2],
  [:SWEETBAIT,3,2],
  [:SPECIALTYBAIT,1,1],
  [:HYPERPOTION,1,4],
  [:MONOBALL,2,3],
  [:DUELBALL,1,2],
  [:SNOWBALLBALL,1,2],
  [:ULTRABALL,3,3],
  [:OMEGABALL,1,1],
  [:EXPCANDYM,2,2],
  [:EXPCANDYL,1,1],
  [:NUGGET,1,1],
  [:BIGNUGGET,1,1],
  [:PEARL,1,1],
  [:BIGPEARL,1,1],
  [:PEARLSTRING,1,1],
  [:STARPIECE,1,1],
  [:COMETSHARD,1,1],
  [:BIGMUSHROOM,1,2],
  [:BALMMUSHROOM,1,1],
  [:RARECANDY,1,2],
  [:HEARTSCALE,3,5]
]
  #[:ITEM,QUANTITY,WEIGHT]
  def randRareItem
    weightTotal = 0
    count = 0
    for i in 0..ITEMARR.length-1
      weightTotal += ITEMARR[i][2]
    end
      itemnum = rand(ITEMARR[1][2]..weightTotal)
      for n in 0..ITEMARR.length-1
        count += ITEMARR[n][2]
        if count > itemnum
          item = GameData::Item.get(ITEMARR[n][0])
          quantity = rand(ITEMARR[n][1]/2.floor..ITEMARR[n][1])
          pbReceiveItem(item, quantity)
          break
        end
      end
  end

  GS_REGIONAL_ARRAY = pbAllRegionalSpecies(0)
  GS_ALTERNATE_FORMS = [
    :RATTATA,:RATICATE,
    :RAICHU,
    :SANDSHREW,:SANDSLASH,
    :VULPIX,:NINETAILS,
    :DIGLETT,:DUGTRIO,
    :MEOWTH,:PERSIAN, # Meowth can be form id:1 and id:2 (alolan & galarian)
    :GEODUDE,:GRAVELER,:GOLEM,
    :PONYTA,:RAPIDASH,
    :SLOWPOKE,:SLOWBRO,:SLOWKING,
    :FARFETCHD,
    :GRIMER,:MUK,
    :EXEGGUTOR,
    :MAROWAK,
    :WEEZING,
    :MRMIME,
    :ARTICUNO,:ZAPDOS,:MOLTRES,
    :CORSOLA,
    :ZIGZAGOON,:LINOONE,
    :DARUMAKA,:DARMANITAN, # special case since regional form is id:2
    :YAMASK,
    :STUNFISK,
    :TOXTRICITY # to allow for Low-Key and High-Key forms
  ]
#randomizer encounters
EventHandlers.add(:on_wild_pokemon_created, :gs_randomizer,
  proc { |pkmn|
    if $game_switches[61]
      pkmn.species = GS_REGIONAL_ARRAY.sample
      pkmn.level = 2 if pkmn.level < 2
      pkmn.form = 0
      pkmn.calc_stats
      pkmn.reset_moves
    end
  }
)

#randomizer trainers
EventHandlers.add(:on_trainer_load, :gs_randomizer,
  proc { |trainer|
    if trainer && $game_switches[61]
      trainer.party.each { |pkmn|
      pkmn.species = GS_REGIONAL_ARRAY.sample
      pkmn.level = 2 if pkmn.level < 2
      pkmn.form = 0
      pkmn.calc_stats
      pkmn.reset_moves
      for pokemon in trainer.party do
        pokemon = pkmn
      end
      }
    end
  }
)

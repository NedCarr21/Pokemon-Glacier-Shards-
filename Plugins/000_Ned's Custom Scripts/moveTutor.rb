
  TUTOR_VARIABLE = 96 # Variable used to determine what move to learn.

  ITEM1 = :REDSHARD #Items consumed when learning a new move, currently only supports 4 items ONLY, no more, no less.
  ITEM2 = :YELLOWSHARD
  ITEM3 = :BLUESHARD
  ITEM4 = :GREENSHARD

  # Prices of moves in the order, [MoveName, cost of ITEM1, cost of ITEM2, cost of ITEM3, cost of ITEM4.]
  PRICES = [
    [:BURNINGJEALOUSY,2,1,0,0],
    [:COACHING,0,2,1,0],
    [:CORROSIVEGAS,0,0,2,1],
    [:DUALWINGBEAT,0,1,2,0],
    [:EXPANDINGFORCE,2,0,1,0],
    [:FLIPTURN,1,0,2,0],
    [:GRASSYGLIDE,0,0,1,2],
    [:LASHOUT,0,1,0,2],
    [:METEORBEAM,0,2,0,1],
    [:MISTYEXPLOSION,1,2,0,0],
    [:POLTERGEIST,2,0,0,1],
    [:RISINGVOLTAGE,2,0,1,0],
    [:SCALESHOT,1,0,2,0],
    [:SCORCHINGSANDS,1,0,2,0],
    [:SKITTERSMACK,0,1,0,2],
    [:STEELROLLER,2,0,0,1],
    [:TERRAINPULSE,0,2,1,0],
    [:TRIPLEAXEL,0,1,2,0]
    ]

    CHOICES = Array.new

    def nMoveTutor
      if (CHOICES.is_a?(Array))
        CHOICES.delete_at(3)
        CHOICES.delete_at(2)
        CHOICES.delete_at(1)
        CHOICES.delete_at(0)
      end

      $game_variables[TUTOR_VARIABLE] = 0

      pbMessage(_INTL("I am a move tutor, I can teach your pokemon many different moves in exchange for shards."))
      if (pbConfirmMessage(_INTL("Would you like me to teach a move to one of your Pokemon?")))
        pbChooseTradablePokemon(3,1)
        pkmn = $Trainer.party[pbGet(3)]
        pkmnName = pbGet(1)
        move0 = GameData::Move.get(PRICES.sample[0])
        move1 = GameData::Move.get(PRICES.sample[0])
        move2 = GameData::Move.get(PRICES.sample[0])
        move3 = GameData::Move.get(PRICES.sample[0])
        CHOICES.push(move0)
        CHOICES.push(move1)
        CHOICES.push(move2)
        CHOICES.push(move3)
          pbMessage(_INTL("Which move would you like to teach {1}?\\ch[#{pbGet(TUTOR_VARIABLE)},0,{2},{3},{4},{5}]", pkmnName, move0.name, move1.name, move2.name, move3.name))
            @Nmove = GameData::Move.get(CHOICES[pbGet(TUTOR_VARIABLE)])
            @NmoveName = GameData::Move.get(@Nmove).name
              if !(pkmn.compatible_with_move?(@Nmove))
                  pbMessage(_INTL("{1} cannot learn {2}", pkmnName, @NmoveName))
              else
                if (($PokemonBag.pbQuantity(ITEM1) < @Ncost1 && @Ncost1 != 0) || ($PokemonBag.pbQuantity(ITEM2) < @Ncost2 && @Ncost2 !=0) || ($PokemonBag.pbQuantity(ITEM3) < @Ncost3 && @Ncost3 != 0) || ($PokemonBag.pbQuantity(ITEM4) < @Ncost4 && @Ncost4 !=0))
                  pbMessage(_INTL("You don't have enough shards."))
                else
                  @Ncost1 = PRICES[pbGet(TUTOR_VARIABLE)][1]
                  @Ncost2 = PRICES[pbGet(TUTOR_VARIABLE)][2]
                  @Ncost3 = PRICES[pbGet(TUTOR_VARIABLE)][3]
                  @Ncost4 = PRICES[pbGet(TUTOR_VARIABLE)][4]
                  if pkmn.shadowPokemon?
                    pbMessage(_INTL("Shadow Pokémon can't be taught any moves."))
                  elsif !pkmn.compatible_with_move?(@Nmove)
                    pbMessage(_INTL("{1} can't learn {2}.", pkmnName, @NmoveName))
                  else
                    if pbConfirmMessage(_INTL("Would you like to teach {1}, {2}?", pkmnName, @NmoveName))
                      if (pbLearnMove(pkmn,@Nmove))
                          $PokemonBag.pbDeleteItem(ITEM1,@Ncost1)
                          $PokemonBag.pbDeleteItem(ITEM2,@Ncost2)
                          $PokemonBag.pbDeleteItem(ITEM3,@Ncost3)
                          $PokemonBag.pbDeleteItem(ITEM4,@Ncost4)
                      end #end of pbLearnMove
                    else
                      pbMessage(_INTL("Come back if you ever need me to teach a move to your Pokemon."))
                    end #end of pbConfirmMessage (Would you like to teach)
                  end #end of if shadowPokemon?
                end #end of shard check
          end #end of pkmn.compatible_with_move
      end #end of pbConfirmMessage (Would you like to teach)
    end #end of def

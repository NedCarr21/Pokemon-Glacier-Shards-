class Pokemon
#==============================================================
#Checks if the move is in the level up list of the pokemon
#==============================================================
  def learnable?(move_id)
	if BetterMoveTutorConfig::LEVEL_MOVE_EXPERT
		move_data = GameData::Move.try_get(move_id)
		return move_data && species_data.moves.any? { |move| move.include?(move_id) }
	end
  end
  
#==============================================================
#Checks if the move can be learned by egg-move, either by that mon or by a
#==============================================================
  def from_eggmove?(move_id)
	if BetterMoveTutorConfig::EGGMOVE_CONNOISSEUR
		move_data = GameData::Move.try_get(move_id)
		babyspecies = species_data.get_baby_species
		babyeggmoves =  GameData::Species.get(babyspecies).egg_moves
		return move_data && species_data.egg_moves.include?(move_data.id) || move_data && babyeggmoves.include?(move_data.id)
	end
  end
  
#==============================================================
#Checks if the move could be learned by level up from its pre-evolution (For example, Spore for Breloom)
#==============================================================
  def pre_evoexclusive?(move_id)
	if BetterMoveTutorConfig::SECOND_OPPORTUNITY
		move_data = GameData::Move.try_get(move_id)
		prevo = species_data.get_previous_species
		prevomoves =  GameData::Species.get(prevo).moves
		return move_data && species_data.egg_moves.include?(move_data.id) || move_data && prevomoves.any?{ |move| move.include?(move_id) }
		#The "egg_moves.include?" is mostly leftovers from me trying to make it work, but i was too afraid to remove it and break everything lol
	end
  end 
end


#=========================================================================
#Now, time to add it to the move tutor
#=========================================================================
def pbMoveTutorAnnotations(move, movelist = nil)
  ret = []
  $player.party.each_with_index do |pkmn, i|
    if pkmn.egg?
      ret[i] = _INTL("NOT ABLE")
    elsif pkmn.hasMove?(move)
      ret[i] = _INTL("LEARNED")
    else
      species = pkmn.species
      if movelist&.any? { |j| j == species }
        # Checked data from movelist given in parameter
        ret[i] = _INTL("ABLE")
      elsif pkmn.compatible_with_move?(move)
        # Checked data from Pokémon's tutor moves in pokemon.txt
        ret[i] = _INTL("ABLE")
      elsif pkmn.learnable?(move)
        # Checked data from Pokémon's level up
        ret[i] = _INTL("ABLE")
      elsif pkmn.from_eggmove?(move)
		# Checks if the move is in the egg_moves of the species (Defined in the pbs)
         ret[i] = _INTL("ABLE")
      elsif pkmn.pre_evoexclusive?(move)
		# Cheks if the move was in the level-up move list of the pre-evolution (Hi breloom)
         ret[i] = _INTL("ABLE")
      else
        ret[i] = _INTL("NOT ABLE")
      end
    end
  end
  return ret
end

def pbMoveTutorChoose(move, movelist = nil, bymachine = false, oneusemachine = false)
  ret = false
  move = GameData::Move.get(move).id
  if movelist.is_a?(Array)
    movelist.map! { |m| GameData::Move.get(m).id }
  end
  pbFadeOutIn {
    movename = GameData::Move.get(move).name
    annot = pbMoveTutorAnnotations(move, movelist)
    scene = PokemonParty_Scene.new
    screen = PokemonPartyScreen.new(scene, $player.party)
    screen.pbStartScene(_INTL("Teach which Pokémon?"), false, annot)
    loop do
      chosen = screen.pbChoosePokemon
      break if chosen < 0
      pokemon = $player.party[chosen]
      if pokemon.egg?
        pbMessage(_INTL("Eggs can't be taught any moves.")) { screen.pbUpdate }
      elsif pokemon.shadowPokemon?
        pbMessage(_INTL("Shadow Pokémon can't be taught any moves.")) { screen.pbUpdate }
      elsif movelist && movelist.none? { |j| j == pokemon.species }
        pbMessage(_INTL("{1} can't learn {2}.", pokemon.name, movename)) { screen.pbUpdate }
      elsif !pokemon.compatible_with_move?(move) && !pokemon.learnable?(move) && !pokemon.from_eggmove?(move) && !pokemon.pre_evoexclusive?(move)
        pbMessage(_INTL("{1} can't learn {2}.", pokemon.name, movename)) { screen.pbUpdate }
      elsif pbLearnMove(pokemon, move, false, bymachine) { screen.pbUpdate }
        $stats.moves_taught_by_item += 1 if bymachine
        $stats.moves_taught_by_tutor += 1 if !bymachine
        pokemon.add_first_move(move) if oneusemachine
        ret = true
        break
      end
    end
    screen.pbEndScene
  }
  return ret   # Returns whether the move was learned by a Pokemon
end

#=========================================================================
#And now the same deal but for HM/TMs
#=========================================================================
def pbUseItemOnPokemon(item, pkmn, scene)
  itm = GameData::Item.get(item)
  # TM or HM
  if itm.is_machine?
    machine = itm.move
    return false if !machine
    movename = GameData::Move.get(machine).name
    if pkmn.shadowPokemon?
      pbMessage(_INTL("Shadow Pokémon can't be taught any moves.")) { scene.pbUpdate }
    elsif !pkmn.compatible_with_move?(machine) && !pkmn.learnable?(machine) && !pkmn.from_eggmove?(machine) && !pkmn.pre_evoexclusive?(machine)
      pbMessage(_INTL("{1} can't learn {2}.", pkmn.name, movename)) { scene.pbUpdate }
    else
      pbMessage(_INTL("\\se[PC access]You booted up {1}.\1", itm.name)) { scene.pbUpdate }
      if pbConfirmMessage(_INTL("Do you want to teach {1} to {2}?", movename, pkmn.name)) { scene.pbUpdate }
        if pbLearnMove(pkmn, machine, false, true) { scene.pbUpdate }
          $bag.remove(item) if itm.consumed_after_use?
          return true
        end
      end
    end
    return false
  end
  # Other item
  qty = 1
  max_at_once = ItemHandlers.triggerUseOnPokemonMaximum(item, pkmn)
  max_at_once = [max_at_once, $bag.quantity(item)].min
  if max_at_once > 1
    qty = scene.scene.pbChooseNumber(
      _INTL("How many {1} do you want to use?", itm.name), max_at_once
    )
    scene.scene.pbSetHelpText("") if scene.is_a?(PokemonPartyScreen)
  end
  return false if qty <= 0
  ret = ItemHandlers.triggerUseOnPokemon(item, qty, pkmn, scene)
  scene.pbClearAnnotations
  scene.pbHardRefresh
  if ret && itm.consumed_after_use?
    $bag.remove(item, qty)
    if !$bag.has?(item)
      pbMessage(_INTL("You used your last {1}.", itm.name)) { scene.pbUpdate }
    end
  end
  return ret
end


class PokemonParty_Scene
def pbUseItem(bag, pokemon)
    ret = nil
    pbFadeOutIn {
      scene = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene, bag)
      ret = screen.pbChooseItemScreen(proc { |item|
        itm = GameData::Item.get(item)
        next false if !pbCanUseOnPokemon?(itm)
        next false if pokemon.hyper_mode && !GameData::Item.get(item)&.is_scent?
        if itm.is_machine?
          move = itm.move
          next false if pokemon.hasMove?(move) || !pokemon.compatible_with_move?(move) || !pokemon.learnable?(move) || !pokemon.from_eggmove?(move) || !pokemon.pre_evoexclusive?(move)
        end
        next true
      })
      yield if block_given?
    }
    return ret
  end
end
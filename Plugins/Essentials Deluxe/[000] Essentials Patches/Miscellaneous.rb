#===============================================================================
# Revamps miscellaneous bits of Essentials code to allow for plugin compatibility.
#===============================================================================


#-------------------------------------------------------------------------------
# Orders Egg Groups numerically, including Legendary groups.
#-------------------------------------------------------------------------------
def egg_group_hash
  data ={
    :Monster      => 0,
    :Water1       => 1,
    :Bug          => 2,
    :Flying       => 3,
    :Field        => 4,
    :Fairy        => 5,
    :Grass        => 6,
    :Humanlike    => 7,
    :Water3       => 8,
    :Mineral      => 9,
    :Amorphous    => 10,
    :Water2       => 11,
    :Ditto        => 12,
    :Dragon       => 13,
    :Undiscovered => 14,
    :Skycrest     => 15,
    :Bestial      => 16,
    :Titan        => 17,
    :Overlord     => 18,
    :Nebulous     => 19,
    :Enchanted    => 20,
    :Ancestor     => 21,
    :Ultra        => 22,
    :Unused1      => 23,
    :Unused2      => 24,
    :Unknown      => 25
  }
  return data
end


#-------------------------------------------------------------------------------
# Rewrites Egg Generator to include plugin mechanics.
#-------------------------------------------------------------------------------
class DayCare
  module EggGenerator
    module_function
    
    def fluid_egg_group?(groups)
      return groups.include?(:Ditto) || groups.include?(:Ancestor)
    end
    
    def generate(mother, father)
      if mother.male? || father.female? || mother.genderless?
        mother, father = father, mother
      end
      mother_data = [mother, fluid_egg_group?(mother.species_data.egg_groups)]
      father_data = [father, fluid_egg_group?(father.species_data.egg_groups)]
      species_parent = (mother_data[1]) ? father : mother
      baby_species = determine_egg_species(species_parent.species, mother, father)
      mother_data.push(mother.species_data.breeding_can_produce?(baby_species))
      father_data.push(father.species_data.breeding_can_produce?(baby_species))
      egg = generate_basic_egg(baby_species)
      inherit_form(egg, species_parent, mother_data, father_data)
      inherit_nature(egg, mother, father)
      inherit_ability(egg, mother_data, father_data)
      inherit_moves(egg, mother_data, father_data)
      inherit_IVs(egg, mother, father)
      inherit_poke_ball(egg, mother_data, father_data)
      birthsign_inheritance(egg, mother, father) if PluginManager.installed?("Pokémon Birthsigns")
      set_shininess(egg, mother, father)
      set_pokerus(egg)
      egg.calc_stats
      return egg
    end
  end
end

def legendary_egg_group?(groups)
  egg_groups = egg_group_hash
  return egg_groups[groups[0]] > 13 || (groups[1] && egg_groups[groups[1]] > 13)
end


#-------------------------------------------------------------------------------
# Adds Ultra Space habitat for Ultra Beasts.
#-------------------------------------------------------------------------------
GameData::Habitat.register({
  :id   => :UltraSpace,
  :name => _INTL("Ultra Space")
})


#-------------------------------------------------------------------------------
# Rewrites Pokemon Storage to show displays added by plugins.
#-------------------------------------------------------------------------------
class PokemonStorageScene
  def pbUpdateOverlay(selection, party = nil)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    if !@sprites["plugin_overlay"]
      @sprites["plugin_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @boxsidesviewport)
      pbSetSystemFont(@sprites["plugin_overlay"].bitmap)
    end
    plugin_overlay = @sprites["plugin_overlay"].bitmap
    plugin_overlay.clear
    buttonbase = Color.new(248, 248, 248)
    buttonshadow = Color.new(80, 80, 80)
    pbDrawTextPositions(
      overlay,
      [[_INTL("Party: {1}", (@storage.party.length rescue 0)), 270, 334, 2, buttonbase, buttonshadow, 1],
       [_INTL("Exit"), 446, 334, 2, buttonbase, buttonshadow, 1]]
    )
    pokemon = nil
    if @screen.pbHeldPokemon
      pokemon = @screen.pbHeldPokemon
    elsif selection >= 0
      pokemon = (party) ? party[selection] : @storage[@storage.currentBox, selection]
    end
    if !pokemon
      @sprites["pokemon"].visible = false
      return
    end
    @sprites["pokemon"].visible = true
    base   = Color.new(88, 88, 80)
    shadow = Color.new(168, 184, 184)
    nonbase   = Color.new(208, 208, 208)
    nonshadow = Color.new(224, 224, 224)
    pokename = pokemon.name
    textstrings = [
      [pokename, 10, 14, false, base, shadow]
    ]
    if !pokemon.egg?
      imagepos = []
      if pokemon.male?
        textstrings.push([_INTL("♂"), 148, 14, false, Color.new(24, 112, 216), Color.new(136, 168, 208)])
      elsif pokemon.female?
        textstrings.push([_INTL("♀"), 148, 14, false, Color.new(248, 56, 32), Color.new(224, 152, 144)])
      end
      imagepos.push(["Graphics/Pictures/Storage/overlay_lv", 6, 246])
      textstrings.push([pokemon.level.to_s, 28, 240, false, base, shadow])
      if pokemon.ability
        textstrings.push([pokemon.ability.name, 86, 312, 2, base, shadow])
      else
        textstrings.push([_INTL("No ability"), 86, 312, 2, nonbase, nonshadow])
      end
      if pokemon.item
        textstrings.push([pokemon.item.name, 86, 348, 2, base, shadow])
      else
        textstrings.push([_INTL("No item"), 86, 348, 2, nonbase, nonshadow])
      end
      if pokemon.shiny?
        pbDrawImagePositions(plugin_overlay, [["Graphics/Pictures/shiny", 134, 16]])
      end
      if PluginManager.installed?("ZUD Mechanics")
        pbDisplayGmaxFactor(pokemon, plugin_overlay, 8, 52)
      end
      if PluginManager.installed?("Pokémon Birthsigns")
        pbDisplayToken(pokemon, plugin_overlay, 149, 167, true)
      end
      if PluginManager.installed?("Enhanced UI")
        pbDisplayShinyLeaf(pokemon, plugin_overlay, 158, 50)      if Settings::STORAGE_SHINY_LEAF
        pbDisplayIVRatings(pokemon, plugin_overlay, 8, 198, true) if Settings::STORAGE_IV_RATINGS
      end
      typebitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
      pokemon.types.each_with_index do |type, i|
        type_number = GameData::Type.get(type).icon_position
        type_rect = Rect.new(0, type_number * 28, 64, 28)
        type_x = (pokemon.types.length == 1) ? 52 : 18 + (70 * i)
        overlay.blt(type_x, 272, typebitmap.bitmap, type_rect)
      end
      drawMarkings(overlay, 70, 240, 128, 20, pokemon.markings)
      pbDrawImagePositions(overlay, imagepos)
    end
    pbDrawTextPositions(overlay, textstrings)
    @sprites["pokemon"].setPokemonBitmap(pokemon)
  end
end


#-------------------------------------------------------------------------------
# Checks if a common animation exists.
#-------------------------------------------------------------------------------
class Battle::Scene
  def pbCommonAnimationExists?(animName)
    animations = pbLoadBattleAnimations
    animations.each do |a|
      next if !a || a.name != "Common:" + animName
      return true
    end
    return false
  end
end


#-------------------------------------------------------------------------------
# Fixes to allow certain forms to be generated for wild battles without being
# prompted to learn an exclusive move. (Moves are instead taught automatically)
#-------------------------------------------------------------------------------
# Rotom forms.
#-------------------------------------------------------------------------------
MultipleForms.register(:ROTOM, {
  "onSetForm" => proc { |pkmn, form, oldForm|
    form_moves = [
      :OVERHEAT,
      :HYDROPUMP,
      :BLIZZARD,
      :AIRSLASH,
      :LEAFSTORM
    ]
    old_move_index = -1
    pkmn.moves.each_with_index do |move, i|
      next if !form_moves.include?(move.id)
      old_move_index = i
      break
    end
    new_move_id = (form > 0) ? form_moves[form - 1] : nil
    new_move_id = nil if !GameData::Move.exists?(new_move_id)
    if $game_temp.dx_pokemon? || $game_temp.dx_midbattle?
	  next if form == 0 && old_move_index == -1
      new_move_id = :SHADOWBALL if !new_move_id
      old_move_index = pkmn.moves.length - 1 if old_move_index < 0
      pkmn.moves[old_move_index].id = new_move_id
      next
    end
    if new_move_id.nil? && old_move_index >= 0 && pkmn.numMoves == 1
      new_move_id = :THUNDERSHOCK
      new_move_id = nil if !GameData::Move.exists?(new_move_id)
      raise _INTL("Rotom is trying to forget its last move, but there isn't another move to replace it with.") if new_move_id.nil?
    end
    new_move_id = nil if pkmn.hasMove?(new_move_id)
    if old_move_index >= 0
      old_move_name = pkmn.moves[old_move_index].name
      if new_move_id.nil?
        pkmn.forget_move_at_index(old_move_index)
        pbMessage(_INTL("{1} forgot {2}...", pkmn.name, old_move_name))
      else
        pkmn.moves[old_move_index].id = new_move_id
        new_move_name = pkmn.moves[old_move_index].name
        pbMessage(_INTL("{1} forgot {2}...\1", pkmn.name, old_move_name))
        pbMessage(_INTL("\\se[]{1} learned {2}!\\se[Pkmn move learnt]\1", pkmn.name, new_move_name))
      end
    elsif !new_move_id.nil?
      pbLearnMove(pkmn, new_move_id, true)
    end
  }
})

#-------------------------------------------------------------------------------
# Necrozma forms.
#-------------------------------------------------------------------------------
MultipleForms.register(:NECROZMA, {
  "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
    next pkmn.form - 2 if pkmn.form >= 3 && (pkmn.fainted? || endBattle)
  },
  "onSetForm" => proc { |pkmn, form, oldForm|
    next if form > 2 || oldForm > 2
    form_moves = [
      :SUNSTEELSTRIKE,
      :MOONGEISTBEAM
    ]
    inBattle = $game_temp.dx_pokemon? || $game_temp.dx_midbattle?
    if form == 0
      form_moves.each do |move|
        next if !pkmn.hasMove?(move)
        pkmn.forget_move(move)
        pkmn.learn_move(:PSYCHIC) if inBattle
        pbMessage(_INTL("{1} forgot {2}...", pkmn.name, GameData::Move.get(move).name)) if !inBattle
      end
      pbLearnMove(pkmn, :CONFUSION) if pkmn.numMoves == 0 && !inBattle
    else
      new_move_id = form_moves[form - 1]
      if inBattle
        old_move_index = -1
        pkmn.moves.each_with_index do |move, i|
          next if !form_moves.include?(move.id)
          old_move_index = i
          break
        end
        old_move_index = pkmn.moves.length - 1 if old_move_index < 0
        pkmn.moves[old_move_index].id = new_move_id
      else
        pbLearnMove(pkmn, new_move_id, true)
      end
    end
  }
})

#-------------------------------------------------------------------------------
# Calyrex forms.
#-------------------------------------------------------------------------------
MultipleForms.register(:CALYREX, {
  "onSetForm" => proc { |pkmn, form, oldForm|
    form_moves = [
      :GLACIALLANCE,
      :ASTRALBARRAGE
    ]
    inBattle = $game_temp.dx_pokemon? || $game_temp.dx_midbattle?
    if form == 0
      form_moves.each do |move|
        next if !pkmn.hasMove?(move)
        pkmn.forget_move(move)
        pkmn.learn_move(:PSYCHIC) if inBattle
        pbMessage(_INTL("{1} forgot {2}...", pkmn.name, GameData::Move.get(move).name)) if !inBattle
      end
      sp_data = pkmn.species_data
      pkmn.moves.each_with_index do |move, i|
        next if sp_data.moves.any? { |learn_move| learn_move[1] == move.id }
        next if sp_data.tutor_moves.include?(move.id)
        next if sp_data.egg_moves.include?(move.id)
        pbMessage(_INTL("{1} forgot {2}...", pkmn.name, move.name)) if !inBattle
        pkmn.moves[i] = nil
      end
      pkmn.moves.compact!
      if pkmn.numMoves == 0
        (inBattle) ? pkmn.learn_move(:PSYCHIC) : pbLearnMove(pkmn, :CONFUSION)
      end
    else
      new_move_id = form_moves[form - 1]
      if inBattle
        old_move_index = -1
        pkmn.moves.each_with_index do |move, i|
          next if !form_moves.include?(move.id)
          old_move_index = i
          break
        end
        old_move_index = pkmn.moves.length - 1 if old_move_index < 0
        pkmn.moves[old_move_index].id = new_move_id
      else
        pbLearnMove(pkmn, new_move_id, true)
      end
    end
  }
})
#===============================================================================
# Core additions to the Battler class.
#===============================================================================
class Battle::Battler
  attr_accessor :power_index         # Saves the move index of a selected Power Move.
  attr_accessor :power_trigger       # Flags whether the button for Z-Moves/Ultra Burst/Dynamax was toggled on or off.
  attr_accessor :ignore_dynamax      # Flags whether HP changing effects should factor in the user's Dynamax HP or not.
  attr_accessor :selectedMoveIsZMove # Checks if the user's selected move is considered a Z-Move.
  attr_accessor :lastMoveUsedIsZMove # Checks if a Z-Move was the user's last selected move (even if it failed to trigger).
  
  #-----------------------------------------------------------------------------
  # Checks if the battler is in one of these modes.
  #-----------------------------------------------------------------------------
  def ultra?;        return @pokemon&.ultra?;        end
  def dynamax?;      return @pokemon&.dynamax?;      end
  def gmax?;         return @pokemon&.gmax?;         end
    
  #-----------------------------------------------------------------------------
  # Checks various Dynamax conditions.
  #-----------------------------------------------------------------------------
  def dynamax_able?; return @pokemon&.dynamax_able?; end
  def dynamax_boost; return @pokemon&.dynamax_boost; end
  def gmax_factor?;  return @pokemon&.gmax_factor?;  end
    
  #-----------------------------------------------------------------------------
  # Gets the non-Dynamax HP of a Pokemon.
  #-----------------------------------------------------------------------------
  def real_hp;       return @pokemon&.real_hp;       end
  def real_totalhp;  return @pokemon&.real_totalhp;  end

  #-----------------------------------------------------------------------------
  # Mega Evolution
  #-----------------------------------------------------------------------------
  # Returns false if:
  #   -User is Transformed.
  #   -User is a Shadow Pokemon.
  #   -User has an available Z-Move.
  #   -User is in Primal form, or able to Primal Revert.
  #   -User is in Ultra form, or able to Ultra Burst.
  #   -User is currently Dynamaxed.
  #   -User is in Celestial form (Birthsigns plugin).
  #   -User has an available Zodiac Power (Birthsigns plugin).
  #   -User doesn't have a Mega form.
  #-----------------------------------------------------------------------------
  def hasMega?
    return false if @effects[PBEffects::Transform]
    return false if shadowPokemon?
    return false if hasZMove?
    return false if primal? || hasPrimal?
    return false if ultra?  || hasUltra?
    return false if dynamax?
    return false if celestial? || hasZodiacPower?
    return @pokemon&.hasMegaForm?
  end
  
  #-----------------------------------------------------------------------------
  # Z-Move
  #-----------------------------------------------------------------------------
  # Returns false if:
  #   -User is Transformed.
  #   -User is a Shadow Pokemon.
  #   -User is in Primal form, or able to Primal Revert.
  #   -User is able to Ultra Burst first.
  #   -User is currently Dynamaxed.
  #   -User is in Celestial form (Birthsigns plugin).
  #   -User has an available Zodiac Power (Birthsigns plugin).
  #   -User doesn't have a compatible Z-Move.
  #-----------------------------------------------------------------------------
  def hasZMove?
    return false if shadowPokemon?
    return false if primal? || hasPrimal?
    return false if hasUltra?
    return false if dynamax?
    return false if celestial? || hasZodiacPower?
    return hasCompatibleZMove?(@moves)
  end
  
  def hasCompatibleZMove?(move = nil)
    transform = @effects[PBEffects::Transform]
    newpoke   = @effects[PBEffects::TransformPokemon]
    species   = (transform) ? newpoke.species_data.id : nil
    return false if transform && self.item && GameData::Item.get(self.item).is_ultra_item?
    return @pokemon&.compat_zmove?(move, nil, species)
  end
  
  #-----------------------------------------------------------------------------
  # Ultra Burst
  #-----------------------------------------------------------------------------
  # Returns false if:
  #   -User is Transformed.
  #   -User is a Shadow Pokemon.
  #   -User is in Primal form, or able to Primal Revert.
  #   -User is in Mega form.
  #   -User is already in Ultra form.
  #   -User is currently Dynamaxed.
  #   -User is in Celestial form (Birthsigns plugin).
  #   -User has an available Zodiac Power (Birthsigns plugin).
  #   -User doesn't have an Ultra form.
  #-----------------------------------------------------------------------------
  def hasUltra?
    return false if @effects[PBEffects::Transform]
    return false if shadowPokemon?
    return false if primal? || hasPrimal?
    return false if mega? || ultra? || dynamax?
    return false if celestial? || hasZodiacPower?
    return @pokemon&.hasUltraForm?
  end
  
  #-----------------------------------------------------------------------------
  # Dynamax
  #-----------------------------------------------------------------------------
  # Returns false if:
  #   -User is already Dynamaxed.
  #   -User has an available Z-Move.
  #   -User is in Mega form, or able to Mega Evolve.
  #   -User is in Primal form, or able to Primal Revert.
  #   -User is in Ultra form, or able to Ultra Burst.
  #   -User is Transformed into a species already in a Mega, Primal, or Ultra form.
  #   -User has an available Zodiac Power (Birthsigns plugin).
  #   -User is a Shadow Pokemon.
  #   -User is in Celestial form (Birthsigns plugin).
  #   -User is a species that is unable to Dynamax.
  #   -User is Transformed into a species that is unable to Dynamax.
  #-----------------------------------------------------------------------------
  def hasDynamax?
    return false if dynamax?
    return false if hasZMove?
    return false if hasZodiacPower?
    transform  = @effects[PBEffects::Transform]        || @effects[PBEffects::Illusion]
    newpoke    = @effects[PBEffects::TransformPokemon] if @effects[PBEffects::Transform]
    newpoke    = @effects[PBEffects::Illusion]         if @effects[PBEffects::Illusion]
    pokemon    = transform ? newpoke : @pokemon
    return false if pokemon.mega?   || hasMega?
    return false if pokemon.primal? || hasPrimal?
    return false if pokemon.ultra?  || hasUltra?
    return true if canEmax? && !transform
    return pokemon&.dynamax_able? && !isSpecies?(:ETERNATUS)
  end
  
  def hasGmax?
    return false if !hasDynamax?
    return @pokemon&.hasGmax?
  end
  
  def canGmax?
    return hasGmax? && gmax_factor?
  end
  
  def canEmax?
    return @pokemon&.canEmax?
  end
  
  #-----------------------------------------------------------------------------
  # Determines the correct sprite to set when going in and out of Dynamax.
  #-----------------------------------------------------------------------------
  def set_changed_sprite
    pkmn = @pokemon
    back = !@battle.opposes?(@index)
    if @effects[PBEffects::Transform]
      pkmn = @effects[PBEffects::TransformPokemon]
      @battle.scene.sprites["pokemon_#{@index}"].setPokemonBitmap(pkmn, back, self)
    elsif @effects[PBEffects::Illusion]
      pkmn = @effects[PBEffects::Illusion]
      @battle.scene.sprites["pokemon_#{@index}"].setPokemonBitmap(pkmn, back, self)
    else
      @battle.scene.sprites["pokemon_#{@index}"].setPokemonBitmap(pkmn, back)
    end
    @battle.scene.sprites["shadow_#{@index}"].setPokemonBitmap(pkmn)
  end
  
  #-----------------------------------------------------------------------------
  # Reverts the effects of Dynamax.
  #-----------------------------------------------------------------------------
  def unmax
    @pokemon.dynamax = false
    pbUpdate(false)
    @pokemon.reversion = false
    if !@effects[PBEffects::MaxRaidBoss]
      display_base_moves
      @effects[PBEffects::Dynamax] = 0
      @power_trigger = false
      @battle.scene.pbRevertDynamax(@index)
      self.form = @effects[PBEffects::NonGMaxForm] if isSpecies?(:ALCREMIE)
      set_changed_sprite
      @battle.scene.pbChangePokemon(self, @pokemon)
      @battle.scene.pbRevertDynamax2(@index)
      @battle.scene.pbHPChanged(self, totalhp) if !fainted?
      @battle.scene.pbRefresh
    end
  end
end
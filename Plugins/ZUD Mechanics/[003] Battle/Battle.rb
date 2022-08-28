#===============================================================================
# Core additions to the Battle class.
#===============================================================================
class Battle
  attr_accessor :zMove, :ultraBurst, :dynamax
  
  #-----------------------------------------------------------------------------
  # Z-Rings
  #-----------------------------------------------------------------------------
  def pbHasZRing?(idxBattler)
    if pbOwnedByPlayer?(idxBattler)
      @z_rings.each { |item| return true if $bag.has?(item) }
    else
      trainer_items = pbGetOwnerItems(idxBattler)
      return false if !trainer_items
      @z_rings.each { |item| return true if trainer_items.include?(item) }
    end
    return false
  end
  
  def pbGetZRingName(idxBattler)
    if !@z_rings.empty?
      if pbOwnedByPlayer?(idxBattler)
        @z_rings.each { |item| return GameData::Item.get(item).name if $bag.has?(item) }
      else
        trainer_items = pbGetOwnerItems(idxBattler)
        @z_rings.each { |item| return GameData::Item.get(item).name if trainer_items&.include?(item) }
      end
    end
    return _INTL("Z-Ring")
  end
  
  #-----------------------------------------------------------------------------
  # Dynamax Bands
  #-----------------------------------------------------------------------------
  def pbHasDynamaxBand?(idxBattler)
    if pbOwnedByPlayer?(idxBattler)
      @dynamax_bands.each { |item| return true if $bag.has?(item) }
    else
      trainer_items = pbGetOwnerItems(idxBattler)
      return false if !trainer_items
      @dynamax_bands.each { |item| return true if trainer_items.include?(item) }
    end
    return false
  end
  
  def pbGetDynamaxBandName(idxBattler)
    if !@dynamax_bands.empty?
      if pbOwnedByPlayer?(idxBattler)
        @dynamax_bands.each { |item| return GameData::Item.get(item).name if $bag.has?(item) }
      else
        trainer_items = pbGetOwnerItems(idxBattler)
        @dynamax_bands.each { |item| return GameData::Item.get(item).name if trainer_items&.include?(item) }
      end
    end
    return _INTL("Dynamax Band")
  end
  
  #-----------------------------------------------------------------------------
  # Eligibility checks.
  #-----------------------------------------------------------------------------
  def pbCanZMove?(idxBattler)
    battler = @battlers[idxBattler]
    return false if $game_switches[Settings::NO_Z_MOVE]       # No Z-Moves if switch enabled.
    return false if !battler.hasZMove?                        # No Z-Moves if ineligible.
    return false if battler.wild?                             # No Z-Moves for wild Pokemon.
    return true  if $DEBUG && Input.press?(Input::CTRL)       # Allows Z-Moves with CTRL in Debug.
    return false if battler.effects[PBEffects::SkyDrop] >= 0  # No Z-Moves if in Sky Drop.
    return false if !pbHasZRing?(idxBattler)                  # No Z-Moves if no Z-Ring.
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @zMove[side][owner] == -1
  end
  
  def pbCanUltraBurst?(idxBattler)
    battler = @battlers[idxBattler]
    return false if $game_switches[Settings::NO_ULTRA_BURST]  # No Ultra Burst if switch enabled.
    return false if !battler.hasUltra?                        # No Ultra Burst if ineligible.
    return false if battler.wild?                             # No Ultra Burst for wild Pokemon.
    return true  if $DEBUG && Input.press?(Input::CTRL)       # Allows Ultra Burst with CTRL in Debug.
    return false if battler.effects[PBEffects::SkyDrop] >= 0  # No Ultra Burst if in Sky Drop.
    return false if !pbHasZRing?(idxBattler)                  # No Ultra Burst if no Z-Ring.
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @ultraBurst[side][owner] == -1
  end
  
  def pbCanDynamax?(idxBattler)
    battler = @battlers[idxBattler]
    side    = battler.idxOwnSide
    owner   = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    powerspot  = $game_map && Settings::POWERSPOTS.include?($game_map.map_id)
    eternaspot = $game_map && Settings::ETERNASPOT.include?($game_map.map_id)
    return false if $game_switches[Settings::NO_DYNAMAX]       # No Dynamax if switch enabled.
    return false if !battler.hasDynamax?                       # No Dynamax if ineligible.
    return false if battler.wild?                              # No Dynamax for wild Pokemon.
    return true  if $DEBUG && Input.press?(Input::CTRL)        # Allows Dynamax with CTRL in Debug.
    return false if @dynamax[side][owner] != -1                # No Dynamax if already used.
    return false if battler.effects[PBEffects::SkyDrop] >= 0   # No Dynamax if in Sky Drop.
    return false if !pbHasDynamaxBand?(idxBattler)             # No Dynamax if no Dynamax Band.
    return false if battler.canEmax? && !eternaspot            # No Eternamax if not on an Eternaspot map.
    return true  if @raid_battle                               # Allows Dynamax in Max Raid battles.
    return false if !Settings::CAN_DYNAMAX_WILD && wildBattle? # No Dynamax in wild battles unless switch is on.
    return false if !powerspot && !Settings::DYNAMAX_ANY_MAP   # No Dynamax if not on a Dynamax map.
    return @dynamax[side][owner] == -1
  end
  
  #-----------------------------------------------------------------------------
  # Uses the eligible battle mechanic.
  #-----------------------------------------------------------------------------  
  def pbUltraBurst(idxBattler)
    battler = @battlers[idxBattler]
    return if !battler || !battler.pokemon
    return if !battler.hasUltra? || battler.ultra?
    trigger = (battler.pbOwnedByPlayer?) ? "ultra" : (battler.opposes?) ? "ultra_foe" : "ultra_ally"
    @scene.dx_midbattle(idxBattler, nil, trigger)
    old_ability = battler.ability_id
    if battler.hasActiveAbility?(:ILLUSION)
      Battle::AbilityEffects.triggerOnBeingHit(battler.ability, nil, battler, nil, self)
    end
    pbDisplay(_INTL("Bright light is about to burst out of {1}!", battler.pbThis(true)))    
    @scene.pbShowUltraBurst(idxBattler, self) if Settings::SHOW_ULTRA_ANIM
    battler.pokemon.makeUltra
    battler.form = battler.pokemon.form
    battler.pbUpdate(true)
    @scene.pbChangePokemon(battler, battler.pokemon)
    @scene.pbRefreshOne(idxBattler)
    pbDisplay(_INTL("{1} regained its true power with Ultra Burst!", battler.pbThis))    
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @ultraBurst[side][owner] = -2
    battler.pbOnLosingAbility(old_ability)
    battler.pbTriggerAbilityOnGainingIt
    pbCalculatePriority(false, [idxBattler]) if Settings::RECALCULATE_TURN_ORDER_AFTER_MEGA_EVOLUTION
  end
  
  def pbDynamax(idxBattler)
    battler = @battlers[idxBattler]
    return if !battler || !battler.pokemon
    return if !battler.hasDynamax? || battler.dynamax?
    return if @choices[idxBattler][2]==@struggle
    trigger = (battler.pbOwnedByPlayer?) ? "dynamax" : (battler.opposes?) ? "dynamax_foe" : "dynamax_ally"
    @scene.dx_midbattle(idxBattler, nil, trigger)
    trainerName = pbGetOwnerName(idxBattler)
    battler.effects[PBEffects::Dynamax]     = Settings::DYNAMAX_TURNS
    battler.effects[PBEffects::NonGMaxForm] = battler.form
    battler.effects[PBEffects::Encore]      = 0
    battler.effects[PBEffects::Disable]     = 0
    battler.effects[PBEffects::Substitute]  = 0
    battler.effects[PBEffects::Torment]     = false
    # Alcremie reverts to form 0 only for the duration of Gigantamax.
    battler.pokemon.form = 0 if battler.isSpecies?(:ALCREMIE) && battler.gmax_factor?
    # Cramorant resets its form for some reason.
    battler.pokemon.form = 0 if battler.isSpecies?(:CRAMORANT)
    back = !opposes?(idxBattler)
    if Settings::SHOW_DYNAMAX_ANIM && $PokemonSystem.battlescene == 0
      @scene.pbShowDynamax(idxBattler, self)
      battler.pokemon.dynamax = true
      battler.set_changed_sprite
    else
      pbDisplay(_INTL("{1} recalled {2}!", trainerName, battler.pbThis(true)))
      @scene.pbRecall(idxBattler)
      text = (battler.canEmax?) ? "Eternamax" : (battler.canGmax?) ? "Gigantamax" : "Dynamax"
      pbDisplay(_INTL("{1}'s ball surges with {2} energy!", battler.pbThis, text))
      party = pbParty(idxBattler)
      idxPartyStart, idxPartyEnd = pbTeamIndexRangeFromBattlerIndex(idxBattler)
      for i in idxPartyStart...idxPartyEnd
        if party[i] == battler.pokemon
          battler.pokemon.dynamax = true
          pbSendOut([ [idxBattler, party[i]] ])
          battler.set_changed_sprite
          break
        end
      end
    end
    @scene.pbRefresh
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @dynamax[side][owner] = -2
    oldhp = battler.hp
    battler.pbUpdate(false)
    @scene.pbHPChanged(battler, oldhp)
    battler.pokemon.reversion = true
  end
  
  #-----------------------------------------------------------------------------
  # Registering Z-Moves.
  #-----------------------------------------------------------------------------
  def pbRegisterZMove(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @zMove[side][owner] = idxBattler
  end
  
  def pbUnregisterZMove(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @zMove[side][owner] = -1 if @zMove[side][owner] == idxBattler
  end

  def pbToggleRegisteredZMove(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    if @zMove[side][owner] == idxBattler
      @zMove[side][owner] = -1
    else
      @zMove[side][owner] = idxBattler
    end
  end
  
  def pbRegisteredZMove?(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @zMove[side][owner] == idxBattler
  end
  
  def pbAttackPhaseZMoves
    pbPriority.each do |b|
      next if b.wild?
      next unless @choices[b.index][0] == :UseMove && !b.fainted?
      owner = pbGetOwnerIndexFromBattlerIndex(b.index)
      next if @zMove[b.idxOwnSide][owner] != b.index
      b.selectedMoveIsZMove = true
    end
  end
  
  #-----------------------------------------------------------------------------
  # Registering Ultra Burst.
  #-----------------------------------------------------------------------------
  def pbRegisterUltraBurst(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @ultraBurst[side][owner] = idxBattler
  end
  
  def pbUnregisterUltraBurst(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @ultraBurst[side][owner] = -1 if @ultraBurst[side][owner] == idxBattler
  end

  def pbToggleRegisteredUltraBurst(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    if @ultraBurst[side][owner] == idxBattler
      @ultraBurst[side][owner] = -1
    else
      @ultraBurst[side][owner] = idxBattler
    end
  end
  
  def pbRegisteredUltraBurst?(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @ultraBurst[side][owner] == idxBattler
  end
  
  def pbAttackPhaseUltraBurst
    pbPriority.each do |b|
      next if b.wild?
      next unless @choices[b.index][0] == :UseMove && !b.fainted?
      owner = pbGetOwnerIndexFromBattlerIndex(b.index)
      next if @ultraBurst[b.idxOwnSide][owner] != b.index
      pbUltraBurst(b.index)
    end
  end

  def pbAttackPhaseCheer;    end # Placeholder for normal battles.
  def pbAttackPhaseRaidBoss; end # Placeholder for normal battles.

  #-----------------------------------------------------------------------------
  # Registering Dynamax
  #-----------------------------------------------------------------------------
  def pbRegisterDynamax(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @dynamax[side][owner] = idxBattler
  end

  def pbUnregisterDynamax(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @dynamax[side][owner] = -1 if @dynamax[side][owner] == idxBattler
  end

  def pbToggleRegisteredDynamax(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    if @dynamax[side][owner] == idxBattler
      @dynamax[side][owner] = -1
    else
      @dynamax[side][owner] = idxBattler
    end
  end

  def pbRegisteredDynamax?(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @dynamax[side][owner] == idxBattler
  end
  
  def pbAttackPhaseDynamax
    pbPriority.each do |b|
      next if b.wild?
      next unless @choices[b.index][0] == :UseMove && !b.fainted?
      owner = pbGetOwnerIndexFromBattlerIndex(b.index)
      next if @dynamax[b.idxOwnSide][owner] != b.index
      pbDynamax(b.index)
    end
  end
end
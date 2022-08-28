#===============================================================================
# Revamps miscellaneous Pokemon and battler-related code in base Essentials to 
# allow for plugin compatibility.
#===============================================================================


#-------------------------------------------------------------------------------
# Battler effects.
#-------------------------------------------------------------------------------
module PBEffects
  CriticalBoost    = 300  # General crit-boosting effect used by a variety of mechanics.
  EncoreRestore    = 301  # Used to restore Encore after using a battle mechanic that may temporarily ignore its effect.
  TransformPokemon = 302  # Used to get the correct sprite data while transformed in certain situations.
end


#-------------------------------------------------------------------------------
# Pokemon data.
#-------------------------------------------------------------------------------
class Pokemon
  def ace?; return @trainer_ace || false; end
  def ace=(value); @trainer_ace = value;  end
  
  alias dx_initialize initialize  
  def initialize(*args)
    dx_initialize(*args)
    @trainer_ace  = nil
  end
  
  # Compatibility across multiple plugins.
  def dynamax?;   return false; end
  def gmax?;      return false; end
  def celestial?; return false; end
end


#-------------------------------------------------------------------------------
# Pokemon sprite compatibility.
#-------------------------------------------------------------------------------
class Sprite
  def applyDynamax(arg); end
  def unDynamax;         end
  def applyDynamaxIcon;  end
end

class Battle::Scene::BattlerSprite < RPG::Sprite
  def applyDynamax(arg); end
  def unDynamax;         end
end


#-------------------------------------------------------------------------------
# Initializes battler effects.
#-------------------------------------------------------------------------------
class Battle::Battler
  attr_accessor :base_moves
  
  def ace?; return @pokemon&.ace?; end
  
  alias dx_pbInitEffects pbInitEffects  
  def pbInitEffects(batonPass)
    dx_pbInitEffects(batonPass)
    @base_moves = []
    @effects[PBEffects::CriticalBoost]    = 0
    @effects[PBEffects::EncoreRestore]    = []
    @effects[PBEffects::TransformPokemon] = nil
  end
  
  #-----------------------------------------------------------------------------
  # Reverts to base moves. Used by plugins that change moves mid-battle.
  #-----------------------------------------------------------------------------
  def display_base_moves
    return if @base_moves.empty?
    for i in 0...@moves.length
      if @base_moves[i].is_a?(Battle::Move)
        @moves[i] = @base_moves[i]
      else
        @moves[i] = Battle::Move.from_pokemon_move(@battle, @base_moves[i])
      end
    end
    @base_moves.clear
  end
  
  # Compatibility across multiple plugins.
  def hasZMove?;       return false; end
  def hasUltra?;       return false; end
  def ultra?;          return false; end
  def hasDynamax?;     return false; end
  def dynamax?;        return false; end
  def dynamax_able?;   return false; end
  def hasGmax?;        return false; end
  def gmax?;           return false; end
  def gmax_factor?;    return false; end
  def hasZodiacPower?; return false; end
  def celestial?;      return false; end
end


#-------------------------------------------------------------------------------
# Safari Zone compatibility
#-------------------------------------------------------------------------------
class Battle::FakeBattler
  attr_reader :effects
  
  alias zud_initialize initialize
  def initialize(*args)
    zud_initialize(*args)
    @effects = {}
  end
  
  # Compatibility across multiple plugins.
  def hasZMove?;       return false; end
  def hasUltra?;       return false; end
  def ultra?;          return false; end
  def hasDynamax?;     return false; end
  def dynamax?;        return false; end
  def gmax?;           return false; end
  def gmax_factor?;    return false; end
  def hasZodiacPower?; return false; end
  def celestial?;      return false; end
end


#-------------------------------------------------------------------------------
# Adds shortened move names; rewrites critical hit to include new effect.
#-------------------------------------------------------------------------------
class Battle::Move
  attr_accessor :short_name
  
  alias dx_initialize initialize
  def initialize(battle, move)
    dx_initialize(battle, move)
    @short_name = (Settings::SHORTEN_MOVES && @name.length > 16) ? @name[0..12] + "..." : @name
  end
  
  def pbIsCritical?(user, target)
    return false if target.pbOwnSide.effects[PBEffects::LuckyChant] > 0
    ratios = (Settings::NEW_CRITICAL_HIT_RATE_MECHANICS) ? [24, 8, 2, 1] : [16, 8, 4, 3, 2]
    c = 0
    if c >= 0 && user.abilityActive?
      c = Battle::AbilityEffects.triggerCriticalCalcFromUser(user.ability, user, target, c)
    end
    if c >= 0 && target.abilityActive? && !@battle.moldBreaker
      c = Battle::AbilityEffects.triggerCriticalCalcFromTarget(target.ability, user, target, c)
    end
    if c >= 0 && user.itemActive?
      c = Battle::ItemEffects.triggerCriticalCalcFromUser(user.item, user, target, c)
    end
    if c >= 0 && target.itemActive?
      c = Battle::ItemEffects.triggerCriticalCalcFromTarget(target.item, user, target, c)
    end
    return false if c < 0
    case pbCritialOverride(user, target)
    when 1  then return true
    when -1 then return false
    end
    return true if c > 50
    return true if user.effects[PBEffects::LaserFocus] > 0
    c += 1 if highCriticalRate?
    c += user.effects[PBEffects::FocusEnergy]
    c += user.effects[PBEffects::CriticalBoost]
    c += 1 if user.inHyperMode? && @type == :SHADOW
    c = ratios.length - 1 if c >= ratios.length
    return true if ratios[c] == 1
    r = @battle.pbRandom(ratios[c])
    return true if r == 0
    if r == 1 && Settings::AFFECTION_EFFECTS && @battle.internalBattle &&
       user.pbOwnedByPlayer? && user.affection_level == 5 && !target.mega?
      target.damageState.affection_critical = true
      return true
    end
    return false
  end
end


#-------------------------------------------------------------------------------
# Correctly records seen shadow Pokemon.
#-------------------------------------------------------------------------------
class Battle
  def pbSetSeen(battler)
    return if !battler || !@internalBattle
    if battler.is_a?(Battler)
      pbPlayer.pokedex.register(battler.displaySpecies, battler.displayGender,
                                battler.displayForm, battler.shiny?, 
                                true, battler.gmax?, battler.shadowPokemon?)
    else
      pbPlayer.pokedex.register(battler)
    end
  end
end


#-------------------------------------------------------------------------------
# Correctly records captured shadow Pokemon.
#-------------------------------------------------------------------------------
module Battle::CatchAndStoreMixin
  def pbRecordAndStoreCaughtPokemon
    @caughtPokemon.each do |pkmn|
      pbSetCaught(pkmn)
      pbSetSeen(pkmn)
      if !pbPlayer.owned?(pkmn.species)
        pbPlayer.pokedex.set_owned(pkmn.species)
        if $player.has_pokedex
          pbDisplayPaused(_INTL("{1}'s data was added to the Pokédex.", pkmn.name))
          pbPlayer.pokedex.register_last_seen(pkmn)
          @scene.pbShowPokedex(pkmn.species)
        end
      end
      pbPlayer.pokedex.set_shadow_pokemon_owned(pkmn.species_data.id) if pkmn.shadowPokemon?
      pbStorePokemon(pkmn)
    end
    @caughtPokemon.clear
  end
end
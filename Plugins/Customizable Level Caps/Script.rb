#New Level Cap System
#---------------------------------------------------------
module Settings
  LEVEL_CAP_SWITCH = true
end
#---------------------------------------------------------
class PokemonSystem
  attr_accessor :level_caps
  alias initialize_caps initialize
  def initialize
    initialize_caps
    @level_caps = 0 #Level caps set to on by default
  end
end

class Game_System
  attr_accessor :level_cap
  alias initialize_cap initialize
  def initialize
    initialize_cap
    @level_cap          = 0
  end
  def level_cap
    return @level_cap
  end
end

#---------------------------------------------------------
#Define all your levels caps in this array. Every time you run Game.level_cap_update, it will move to the next level cap in the array.
LEVEL_CAP = [14,20,24,31,36,40]
#beginning, after theo battle1, after rare dex obtained, after theo battle2, after reaching pinoidae, after theo battle3
#---------------------------------------------------------

module Game
  def self.level_cap_update
    $game_system.level_cap += 1
    $game_system.level_cap = LEVEL_CAP.size-1 if $game_system.level_cap >= LEVEL_CAP.size
  end
  def self.start_new
    if $game_map&.events
      $game_map.events.each_value { |event| event.clear_starting }
    end
    $game_system.initialize
    $game_temp.common_event_id = 0 if $game_temp
    $game_temp.begun_new_game = true
    $scene = Scene_Map.new
    SaveData.load_new_game_values
    $stats.play_sessions += 1
    $map_factory = PokemonMapFactory.new($data_system.start_map_id)
    $game_player.moveto($data_system.start_x, $data_system.start_y)
    $game_player.refresh
    $PokemonEncounters = PokemonEncounters.new
    $PokemonEncounters.setup($game_map.map_id)
    $game_map.autoplay
    $game_map.update
  end
end

##class PokemonPauseMenu_Scene
##  def pbStartScene
  #  if $game_switches[NavNums::Dispose] == false
##      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
##      @viewport.z = 99999
##      @sprites = {}
##      @sprites["cmdwindow"] = Window_CommandPokemon.new([])
##      @sprites["cmdwindow"].visible = false
##      @sprites["cmdwindow"].viewport = @viewport
##      @sprites["infowindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 32, 32, @viewport)
##      @sprites["infowindow"].visible = false
##      @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 32, 32, @viewport)
##      @sprites["helpwindow"].visible = false
##      @sprites["levelcapwindow"] = Window_UnformattedTextPokemon.newWithSize("Level Cap: #{LEVEL_CAP[$game_system.level_cap]}",0,64,208,64,@viewport)
##      @sprites["levelcapwindow"].visible = false
##      @infostate = false
##      @helpstate = false
##      $close_dexnav = 0
##      $sprites = @sprites
##      pbSEPlay("GUI menu open")
#    else
#      $viewport1.dispose
#      $currentDexSearch = nil
#      $close_dexnav = 1
#      $game_switches[NavNums::Dispose] = false
#      pbSEPlay("GUI menu close")
#      return
#    end
##  end
##  def pbShowLevelCap
##    if Settings::LEVEL_CAP_SWITCH && !$currentDexSearch
##      @sprites["levelcapwindow"].visible = true
##    end
##  end
##  def pbShowMenu
##    @sprites["cmdwindow"].visible = true
##    @sprites["levelcapwindow"].visible = true
##    @sprites["infowindow"].visible = @infostate
##    @sprites["helpwindow"].visible = @helpstate
##  end
##
##  def pbHideMenu
##    @sprites["cmdwindow"].visible = false
##    @sprites["levelcapwindow"].visible = false
##    @sprites["infowindow"].visible = false
##    @sprites["helpwindow"].visible = false
##  end
##end

##class PokemonPauseMenu
  #def pbShowLevelCap
    #@scene.pbShowLevelCap
  #end
##
##  def pbStartPokemonMenu
##    if !$player
##      if $DEBUG
##        pbMessage(_INTL("The player trainer was not defined, so the pause menu can't be displayed."))
##        pbMessage(_INTL("Please see the documentation to learn how to set up the trainer player."))
##      end
##      return
##    end
##    @scene.pbStartScene
##    # Show extra info window if relevant
##    pbShowInfo
##    if $close_dexnav != 1
##      #pbShowLevelCap if Settings::LEVEL_CAP_SWITCH
##    end
##    # Get all commands
##    command_list = []
##    commands = []
##    MenuHandlers.each_available(:pause_menu) do |option, hash, name|
##      command_list.push(name)
##      commands.push(hash)
##    end
##    # Main loop
##    end_scene = false
##    loop do
##      if !$currentDexSearch
##        choice = @scene.pbShowCommands(command_list)
##      else
##        choice = -1
##      end
##      if choice < 0
##        pbPlayCloseMenuSE if !$currentDexSearch
##        end_scene = true
##        break
##      end
##      break if commands[choice]["effect"].call(@scene)
##    end
##    if $close_dexnav != 0
##      @scene.pbEndScene if end_scene
##    end
##  end
##end

class Battle
  def pbGainExpOne(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages = true)
    pkmn = pbParty(0)[idxParty]   # The Pokémon gaining Exp from defeatedBattler
    growth_rate = pkmn.growth_rate
    # Don't bother calculating if gainer is already at max Exp
    if pkmn.exp >= growth_rate.maximum_exp
      pkmn.calc_stats   # To ensure new EVs still have an effect
      return
    end
    isPartic    = defeatedBattler.participants.include?(idxParty)
    hasExpShare = expShare.include?(idxParty)
    level = defeatedBattler.level
    level_cap = $PokemonSystem.level_caps == 0 ? LEVEL_CAP[$game_system.level_cap] : Settings::MAXIMUM_LEVEL
    level_cap_gap = growth_rate.exp_values[level_cap] - pkmn.exp
    # Main Exp calculation
    exp = 0
    a = level * defeatedBattler.pokemon.base_exp
    if expShare.length > 0 && (isPartic || hasExpShare)
      if numPartic == 0   # No participants, all Exp goes to Exp Share holders
        exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? expShare.length : 1)
      elsif Settings::SPLIT_EXP_BETWEEN_GAINERS   # Gain from participating and/or Exp Share
        exp = a / (2 * numPartic) if isPartic
        exp += a / (2 * expShare.length) if hasExpShare
      else   # Gain from participating and/or Exp Share (Exp not split)
        exp = (isPartic) ? a : a / 2
      end
    elsif isPartic   # Participated in battle, no Exp Shares held by anyone
      exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? numPartic : 1)
    elsif expAll   # Didn't participate in battle, gaining Exp due to Exp All
      # NOTE: Exp All works like the Exp Share from Gen 6+, not like the Exp All
      #       from Gen 1, i.e. Exp isn't split between all Pokémon gaining it.
      exp = a / 2
    end
    return if exp <= 0
    # Pokémon gain more Exp from trainer battles
    exp = (exp * 1.5).floor if trainerBattle?
    # Scale the gained Exp based on the gainer's level (or not)
    if Settings::SCALED_EXP_FORMULA
      exp /= 5
      levelAdjust = ((2 * level) + 10.0) / (pkmn.level + level + 10.0)
      levelAdjust = levelAdjust**5
      levelAdjust = Math.sqrt(levelAdjust)
      exp *= levelAdjust
      exp = exp.floor
      exp += 1 if isPartic || hasExpShare
      if pkmn.level >= level_cap
        exp /= 250
      end
      if exp >= level_cap_gap
        exp = level_cap_gap + 1
      end
    else
      if a <= level_cap_gap
        exp = a
      else
        exp /= 7
      end
    end
    # Foreign Pokémon gain more Exp
    isOutsider = (pkmn.owner.id != pbPlayer.id ||
                 (pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language))
    if isOutsider
      if pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language
        exp = (exp * 1.7).floor
      else
        exp = (exp * 1.5).floor
      end
    end
    # Exp. Charm increases Exp gained
    exp = exp * 3 / 2 if $bag.has?(:EXPCHARM)
    # Modify Exp gain based on pkmn's held item
    i = Battle::ItemEffects.triggerExpGainModifier(pkmn.item, pkmn, exp)
    if i < 0
      i = Battle::ItemEffects.triggerExpGainModifier(@initialItems[0][idxParty], pkmn, exp)
    end
    exp = i if i >= 0
    # Boost Exp gained with high affection
    if Settings::AFFECTION_EFFECTS && @internalBattle && pkmn.affection_level >= 4 && !pkmn.mega?
      exp = exp * 6 / 5
      isOutsider = true   # To show the "boosted Exp" message
    end
    # Make sure Exp doesn't exceed the maximum
    expFinal = growth_rate.add_exp(pkmn.exp, exp)
    expGained = expFinal - pkmn.exp
    return if expGained <= 0
    # "Exp gained" message
    if showMessages
      if isOutsider
        pbDisplayPaused(_INTL("{1} got a boosted {2} Exp. Points!", pkmn.name, expGained))
      else
        pbDisplayPaused(_INTL("{1} got {2} Exp. Points!", pkmn.name, expGained))
      end
    end
    curLevel = pkmn.level
    newLevel = growth_rate.level_from_exp(expFinal)
    if newLevel < curLevel
      debugInfo = "Levels: #{curLevel}->#{newLevel} | Exp: #{pkmn.exp}->#{expFinal} | gain: #{expGained}"
      raise _INTL("{1}'s new level is less than its\r\ncurrent level, which shouldn't happen.\r\n[Debug: {2}]",
                  pkmn.name, debugInfo)
    end
    # Give Exp
    if pkmn.shadowPokemon?
      if pkmn.heartStage <= 3
        pkmn.exp += expGained
        $stats.total_exp_gained += expGained
      end
      return
    end
    $stats.total_exp_gained += expGained
    tempExp1 = pkmn.exp
    battler = pbFindBattler(idxParty)
    loop do   # For each level gained in turn...
      # EXP Bar animation
      levelMinExp = growth_rate.minimum_exp_for_level(curLevel)
      levelMaxExp = growth_rate.minimum_exp_for_level(curLevel + 1)
      tempExp2 = (levelMaxExp < expFinal) ? levelMaxExp : expFinal
      pkmn.exp = tempExp2
      @scene.pbEXPBar(battler, levelMinExp, levelMaxExp, tempExp1, tempExp2)
      tempExp1 = tempExp2
      curLevel += 1
      if curLevel > newLevel
        # Gained all the Exp now, end the animation
        pkmn.calc_stats
        battler&.pbUpdate(false)
        @scene.pbRefreshOne(battler.index) if battler
        break
      end
      # Levelled up
      pbCommonAnimation("LevelUp", battler) if battler
      oldTotalHP = pkmn.totalhp
      oldAttack  = pkmn.attack
      oldDefense = pkmn.defense
      oldSpAtk   = pkmn.spatk
      oldSpDef   = pkmn.spdef
      oldSpeed   = pkmn.speed
      if battler&.pokemon
        battler.pokemon.changeHappiness("levelup")
      end
      pkmn.calc_stats
      battler&.pbUpdate(false)
      @scene.pbRefreshOne(battler.index) if battler
      pbDisplayPaused(_INTL("{1} grew to Lv. {2}!", pkmn.name, curLevel))
      @scene.pbLevelUp(pkmn, battler, oldTotalHP, oldAttack, oldDefense,
                       oldSpAtk, oldSpDef, oldSpeed)
      # Learn all moves learned at this level
      moveList = pkmn.getMoveList
      moveList.each { |m| pbLearnMove(idxParty, m[1]) if m[0] == curLevel }
    end
  end
end

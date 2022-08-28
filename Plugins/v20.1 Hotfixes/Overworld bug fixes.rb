#===============================================================================
# "v20.1 Hotfixes" plugin
# This file contains fixes for overworld bugs in Essentials v20.1.
# These bug fixes are also in the dev branch of the GitHub version of
# Essentials:
# https://github.com/Maruno17/pokemon-essentials
#===============================================================================

#===============================================================================
# Fixed playing the credits/changing $scene leaving a ghost image of the old map
# behind.
#===============================================================================
class Scene_Map
  def dispose
    disposeSpritesets
    @map_renderer.dispose
    @map_renderer = nil
    @spritesetGlobal.dispose
    @spritesetGlobal = nil
  end

  def main
    createSpritesets
    Graphics.transition
    loop do
      Graphics.update
      Input.update
      update
      break if $scene != self
    end
    Graphics.freeze
    dispose
    if $game_temp.title_screen_calling
      pbMapInterpreter.command_end if pbMapInterpreterRunning?
      $game_temp.title_screen_calling = false
      Graphics.transition
      Graphics.freeze
    end
  end
end

def pbLoadRpgxpScene(scene)
  return if !$scene.is_a?(Scene_Map)
  oldscene = $scene
  $scene = scene
  Graphics.freeze
  oldscene.dispose
  visibleObjects = pbHideVisibleObjects
  Graphics.transition
  Graphics.freeze
  while $scene && !$scene.is_a?(Scene_Map)
    $scene.main
  end
  Graphics.transition
  Graphics.freeze
  $scene = oldscene
  $scene.createSpritesets
  pbShowObjects(visibleObjects)
  Graphics.transition
end

#===============================================================================
# Fixed SystemStackError when two events on connected maps have their backs to
# the other map.
#===============================================================================
class Game_Character
  def calculate_bush_depth
    if @tile_id > 0 || @always_on_top || jumping?
      @bush_depth = 0
      return
    end
    this_map = (self.map.valid?(@x, @y)) ? [self.map, @x, @y] : $map_factory&.getNewMap(@x, @y, self.map.map_id)
    if this_map && this_map[0].deepBush?(this_map[1], this_map[2])
      xbehind = @x + (@direction == 4 ? 1 : @direction == 6 ? -1 : 0)
      ybehind = @y + (@direction == 8 ? 1 : @direction == 2 ? -1 : 0)
      if moving?
        behind_map = (self.map.valid?(xbehind, ybehind)) ? [self.map, xbehind, ybehind] : $map_factory&.getNewMap(xbehind, ybehind, self.map.map_id)
        @bush_depth = Game_Map::TILE_HEIGHT if behind_map[0].deepBush?(behind_map[1], behind_map[2])
      else
        @bush_depth = Game_Map::TILE_HEIGHT
      end
    elsif this_map && this_map[0].bush?(this_map[1], this_map[2]) && !moving?
      @bush_depth = 12
    else
      @bush_depth = 0
    end
  end
end

#===============================================================================
# Fixed error when getting terrain tag when the player moves between connected
# maps.
#===============================================================================
class Game_Player < Game_Character
  def pbTerrainTag(countBridge = false)
    return $map_factory.getTerrainTagFromCoords(self.map.map_id, @x, @y, countBridge) if $map_factory
    return $game_map.terrain_tag(@x, @y, countBridge)
  end
end

#===============================================================================
# Fixed being unable to set the player's movement speed during a move route.
#===============================================================================
class Game_Player < Game_Character
  def set_movement_type(type)
    meta = GameData::PlayerMetadata.get($player&.character_ID || 1)
    new_charset = nil
    case type
    when :fishing
      new_charset = pbGetPlayerCharset(meta.fish_charset)
    when :surf_fishing
      new_charset = pbGetPlayerCharset(meta.surf_fish_charset)
    when :diving, :diving_fast, :diving_jumping, :diving_stopped
      self.move_speed = 3 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.dive_charset)
    when :surfing, :surfing_fast, :surfing_jumping, :surfing_stopped
      if !@move_route_forcing
        self.move_speed = (type == :surfing_jumping) ? 3 : 4
      end
      new_charset = pbGetPlayerCharset(meta.surf_charset)
    when :cycling, :cycling_fast, :cycling_jumping, :cycling_stopped
      if !@move_route_forcing
        self.move_speed = (type == :cycling_jumping) ? 3 : 5
      end
      new_charset = pbGetPlayerCharset(meta.cycle_charset)
    when :running
      self.move_speed = 4 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.run_charset)
    when :ice_sliding
      self.move_speed = 4 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.walk_charset)
    else   # :walking, :jumping, :walking_stopped
      self.move_speed = 3 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.walk_charset)
    end
    @character_name = new_charset if new_charset
  end
end

#===============================================================================
# Fixed crash when ending a Bug Catching Contest.
#===============================================================================
class BugContestState
  def pbJudge
    judgearray = []
    if @lastPokemon
      judgearray.push([-1, @lastPokemon.species, pbBugContestScore(@lastPokemon)])
    end
    maps_with_encounters = []
    @contestMaps.each do |map|
      enc_type = :BugContest
      enc_type = :Land if !$PokemonEncounters.map_has_encounter_type?(map, enc_type)
      if $PokemonEncounters.map_has_encounter_type?(map, enc_type)
        maps_with_encounters.push([map, enc_type])
      end
    end
    raise _INTL("There are no Bug Contest/Land encounters for any Bug Contest maps.") if maps_with_encounters.empty?
    @contestants.each do |cont|
      enc_data = maps_with_encounters.sample
      enc = $PokemonEncounters.choose_wild_pokemon_for_map(enc_data[0], enc_data[1])
      raise _INTL("No encounters for map {1} somehow, so can't judge contest.", enc_data[0]) if !enc
      pokemon = Pokemon.new(enc[0], enc[1])
      pokemon.hp = rand(1...pokemon.totalhp)
      score = pbBugContestScore(pokemon)
      judgearray.push([cont, pokemon.species, score])
    end
    if judgearray.length < 3
      raise _INTL("Too few bug catching contestants")
    end
    judgearray.sort! { |a, b| b[2] <=> a[2] }   # sort by score in descending order
    @places.push(judgearray[0])
    @places.push(judgearray[1])
    @places.push(judgearray[2])
  end
end

#===============================================================================
# Additions to the Battler class specific to converting the user's moves.
#===============================================================================
class Battle::Battler
  #-----------------------------------------------------------------------------
  # Converts base moves into Power Moves.
  #-----------------------------------------------------------------------------
  def display_power_moves(mode = 0)
    # Set "mode" to 1 to convert to Z-Moves.
    # Set "mode" to 2 to convert to Max Moves.
    transform = @effects[PBEffects::TransformSpecies]
    for i in 0...@moves.length
      @base_moves.push(@moves[i])
      # Z-Moves
      case mode
      when 1, "Z-Move"
        next if !@pokemon.compat_zmove?(@moves[i], nil, transform)
        @moves[i]          = convert_zmove(@moves[i], transform)
        @moves[i].pp       = [1, @base_moves[i].pp].min
        @moves[i].total_pp = 1
      # Max Moves
      when 2, "Max Move"
        @moves[i]          = convert_maxmove(@moves[i], transform)
        @moves[i].pp       = @base_moves[i].pp   
        @moves[i].total_pp = @base_moves[i].total_pp
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Gets a battler's Z-Move based on the inputted base move.
  #-----------------------------------------------------------------------------
  def convert_zmove(move, transform = nil)
    if move.statusMove?
      poke_move = Pokemon::Move.new(move.id)
    else
      id = @pokemon.get_zmove(move, transform)
      poke_move = Pokemon::Move.new(id)
    end
    poke_move.old_move = move
    return Battle::PowerMove.from_pokemon_move(@battle, poke_move)
  end
  
  #-----------------------------------------------------------------------------
  # Gets a battler's Max Move based on the inputted base move.
  #-----------------------------------------------------------------------------
  def convert_maxmove(move, transform = nil)
    id = @pokemon.get_maxmove(move, move.category, transform)
    poke_move = Pokemon::Move.new(id)
    poke_move.old_move = move
    return Battle::PowerMove.from_pokemon_move(@battle, poke_move)
  end
  
  #-----------------------------------------------------------------------------
  # Effects that may change a Power Move into one of a different type.
  #-----------------------------------------------------------------------------
  def calc_power_move(move)
    newtype = nil
    if move.powerMove?
      base_move = @base_moves[@power_index]
      #-------------------------------------------------------------------------
      # Abilities that change move type (only applies to Max Moves).
      #-------------------------------------------------------------------------
      if move.damagingMove? && move.maxMove? && move.type == :NORMAL
        newtype = :ICE      if hasActiveAbility?(:REFRIGERATE) 
        newtype = :FAIRY    if hasActiveAbility?(:PIXILATE)
        newtype = :FLYING   if hasActiveAbility?(:AERILATE)
        newtype = :ELECTRIC if hasActiveAbility?(:GALVANIZE)
      end
      #-------------------------------------------------------------------------
      # Base move is Revelation Dance.
      #-------------------------------------------------------------------------
      case base_move.id
      when :REVELATIONDANCE;    newtype = pbTypes(true)[0]
      #-------------------------------------------------------------------------
      # Weather is in play and base move is Weather Ball.
      #-------------------------------------------------------------------------
      when :WEATHERBALL
        case @battle.pbWeather
        when :Sun, :HarshSun;   newtype = :FIRE
        when :Rain, :HeavyRain; newtype = :WATER
        when :Sandstorm;        newtype = :ROCK
        when :Hail;             newtype = :ICE
        end
      #-------------------------------------------------------------------------
      # Terrain is in play and base move is Terrain Pulse.
      #-------------------------------------------------------------------------
      when :TERRAINPULSE
        case @battle.field.terrain
        when :Electric;         newtype = :ELECTRIC
        when :Grassy;           newtype = :GRASS
        when :Misty;            newtype = :FAIRY
        when :Psychic;          newtype = :PSYCHIC
        end
      #-------------------------------------------------------------------------
      # Base move is Techno Blast and a drive is held by Genesect.
      #-------------------------------------------------------------------------
      when :TECHNOBLAST
        if isSpecies?(:GENESECT)
          itemTypes = {
             :SHOCKDRIVE => :ELECTRIC,
             :BURNDRIVE  => :FIRE,
             :CHILLDRIVE => :ICE,
             :DOUSEDRIVE => :WATER
          }
          itemTypes.each do |item, type|
            next if !hasActiveItem?(item)
            newtype = type
            break
          end
        end
      #-------------------------------------------------------------------------
      # Base move is Multi-Attack and user has RKS System and held memory.
      #-------------------------------------------------------------------------
      when :MULTIATTACK
        if hasActiveAbility?(:RKSSYSTEM)
          itemTypes = {
             :FIGHTINGMEMORY => :FIGHTING,
             :FLYINGMEMORY   => :FLYING,
             :POISONMEMORY   => :POISON,
             :GROUNDMEMORY   => :GROUND,
             :ROCKMEMORY     => :ROCK,
             :BUGMEMORY      => :BUG,
             :GHOSTMEMORY    => :GHOST,
             :STEELMEMORY    => :STEEL,
             :FIREMEMORY     => :FIRE,
             :WATERMEMORY    => :WATER,
             :GRASSMEMORY    => :GRASS,
             :ELECTRICMEMORY => :ELECTRIC,
             :PSYCHICMEMORY  => :PSYCHIC,
             :ICEMEMORY      => :ICE,
             :DRAGONMEMORY   => :DRAGON,
             :DARKMEMORY     => :DARK,
             :FAIRYMEMORY    => :FAIRY
          }
          itemTypes.each do |item, type|
            next if !hasActiveItem?(item)
            newtype = type
            break
          end
        end
      #-------------------------------------------------------------------------
      # Base move is Judgment and user has Multitype and held plate/Z-Crystal.
      #-------------------------------------------------------------------------
      when :JUDGMENT
        if hasActiveAbility?(:MULTITYPE)
          typeArray = {
             :FIGHTING => [:FISTPLATE,   :FIGHTINIUMZ],
             :FLYING   => [:SKYPLATE,    :FLYINIUMZ],
             :POISON   => [:TOXICPLATE,  :POISONIUMZ],
             :GROUND   => [:EARTHPLATE,  :GROUNDIUMZ],
             :ROCK     => [:STONEPLATE,  :ROCKIUMZ],
             :BUG      => [:INSECTPLATE, :BUGINIUMZ],
             :GHOST    => [:SPOOKYPLATE, :GHOSTIUMZ],
             :STEEL    => [:IRONPLATE,   :STEELIUMZ],
             :FIRE     => [:FLAMEPLATE,  :FIRIUMZ],
             :WATER    => [:SPLASHPLATE, :WATERIUMZ],
             :GRASS    => [:MEADOWPLATE, :GRASSIUMZ],
             :ELECTRIC => [:ZAPPLATE,    :ELECTRIUMZ],
             :PSYCHIC  => [:MINDPLATE,   :PSYCHIUMZ],
             :ICE      => [:ICICLEPLATE, :ICIUMZ],
             :DRAGON   => [:DRACOPLATE,  :DRAGONIUMZ],
             :DARK     => [:DREADPLATE,  :DARKINIUMZ],
             :FAIRY    => [:PIXIEPLATE,  :FAIRIUMZ]
          }
          typeArray.each do |type, items|
            items.each do |item|
              next if !hasActiveItem?(item)
              newtype = type
              break
            end
            break if newtype
          end
        end
      end
      #-------------------------------------------------------------------------
      # Effects for Electrify, Ion Deluge, and Normalize.
      #-------------------------------------------------------------------------
      if move.type == :NORMAL
        newtype = :ELECTRIC if @battle.field.effects[PBEffects::IonDeluge]
      else
        newtype = :NORMAL if hasActiveAbility?(:NORMALIZE)
      end
      newtype = :ELECTRIC if @effects[PBEffects::Electrify]
      #-------------------------------------------------------------------------
      # Converts Power Move if new type was found.
      #-------------------------------------------------------------------------
      if newtype && GameData::Type.exists?(newtype)
        transform = @effects[PBEffects::TransformSpecies]
        if move.zMove?
          z_move    = @pokemon.get_zmove(newtype, transform)
          poke_move = Pokemon::Move.new(z_move)
          poke_move.old_move = base_move
          return Battle::PowerMove.from_pokemon_move(@battle, poke_move)
        elsif move.maxMove?
          max_move  = @pokemon.get_maxmove(newtype, nil, transform)
          poke_move = Pokemon::Move.new(max_move)
          poke_move.old_move = base_move
          return Battle::PowerMove.from_pokemon_move(@battle, poke_move)
        end
      end
    end
    return move
  end
end
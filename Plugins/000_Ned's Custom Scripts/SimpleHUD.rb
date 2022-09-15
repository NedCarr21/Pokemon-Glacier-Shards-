#===============================================================================
# * Simple HUD - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It displays a HUD with the party icons,
# HP bars, tone (for status) and some small text.
#
#== INSTALLATION ===============================================================
#
# To this script works, put it above main.
#
#===============================================================================

if defined?(PluginManager) && !PluginManager.installed?("Simple HUD")
  PluginManager.register({
    :name    => "Simple HUD",
    :version => "3.0",
    :link    => "https://www.pokecommunity.com/showthread.php?t=390640",
    :credits => "FL"
  })
end

class HUD
  # If you wish to use a background picture, put the image path below, like
  # BG_PATH="Graphics/Pictures/battleMessage". I recommend a 512x64 picture.
  # If there is no image, a blue background will be draw.
  BG_PATH="Graphics/Pictures/HUD"

  # Make as 'false' to don't show the blue bar
  USE_BAR=true

  # Make as 'true' to draw the HUD at bottom
  DRAW_AT_BOTTOM=false

  # Make as 'true' to only show HUD in the pause menu
  DRAW_ONLY_IN_MENU=false

  # Make as 'false' to don't show the hp bars
  SHOW_HP_BARS=true

  # Make as 'true' to change pokémon tone when it has a status condition
  APPLY_STATUS_TONE=false

  # Make as 'true' to animate icons
  ANIMATED_ICONS=true

  # When above 0, only displays HUD when this switch is on.
  SWITCH_NUMBER = 62

  # Lower this number = more lag.
  FRAMES_PER_UPDATE = 30

  # The size of drawable content.
  BAR_HEIGHT = 64

  HP_BAR_GREEN    = [Color.new(24,192,32),Color.new(0,144,0)]
  HP_BAR_YELLOW   = [Color.new(248,184,0),Color.new(184,112,0)]
  HP_BAR_RED      = [Color.new(240,80,32),Color.new(168,48,56)]
  TEXT_COLORS = [Color.new(72,72,72), Color.new(160,160,160)]
  BACKGROUND_COLOR = Color.new(128,128,192)

  @@lastGlobalRefreshFrame = -1
  @@instanceArray = []
  @@tonePerStatus = nil

  attr_reader :lastRefreshFrame

  # Note that this method is called on each refresh, but the texts
  # only will be redrawed if any character change.
  def textsDefined
    ret=[]
    ret[0] = _INTL("text one")
    ret[1] = _INTL("text two")
    return ret
  end

  class PokemonData
    attr_reader :species, :form, :isEgg, :status, :hp, :totalhp

    def initialize(pokemon)
      @isEgg = pokemon.egg?
      @species = pokemon.species
      @form = pokemon.form
      @hp = pokemon.hp
      @totalhp = pokemon.totalhp
      @status = @hp==0 ? :FAINT : pokemon.status
    end

    def self.eqlHP?(a, b)
      return a==b if !a || !b
      return a.hp == b.hp && a.totalhp == b.totalhp
    end

    def self.eqlSpecies?(a, b)
      return a==b if !a || !b
      return a.species == b.species && a.isEgg == b.isEgg && a.form == b.form
    end

    def self.eqlStatus?(a, b)
      return a==b if !a || !b
      return a.status == b.status
    end
  end

  def initialize(viewport1)
    @viewport1 = viewport1
    @sprites = {}
    @yposition = DRAW_AT_BOTTOM ? Graphics.height-64 : 0
    @@tonePerStatus = createTonePerStatus if !@@tonePerStatus
    @@instanceArray.compact!
    @@instanceArray.push(self)
  end

  def showHUD?
    return (
      $player &&
      (SWITCH_NUMBER<=0 || !$game_switches[SWITCH_NUMBER]) &&
      (!DRAW_ONLY_IN_MENU || $game_temp.in_menu)
    )
  end

  def createTonePerStatus
    ret = {}
    ret[:NONE]      = Tone.new(0,0,0,0)
    ret[:FAINT]     = Tone.new(0,0,0,255)
    ret[:SLEEP]     = Tone.new(102,102,102,50)
    ret[:POISON]    = Tone.new(153,102,204,50)
    ret[:BURN]      = Tone.new(204,51,51,50)
    ret[:PARALYSIS] = Tone.new(255,255,153,50)
    ret[:FROZEN]    = Tone.new(153,204,204,50)
    # For compatibility with older versions
    statusArray = [:NONE, :SLEEP, :POISON, :BURN, :PARALYSIS, :FROZEN]
    for i in 0...statusArray.size
      ret[i] = ret[statusArray[i]]
    end
    return ret
  end

  def create
    @pokemonDataArray = []
    @currentTextArray = []
    createSprites
    for sprite in @sprites.values
      sprite.z+=600
    end
    refresh
  end

  def createSprites
    createBackground
    for i in 0...6
      createPokemon(i)
    end
    createOverlay
  end

  def createBackground
    @sprites["bar"]=IconSprite.new(0,@yposition,@viewport1)
    if BG_PATH == ""
      @sprites["bar"].bitmap = Bitmap.new(Graphics.width,BAR_HEIGHT)
      @sprites["bar"].bitmap.fill_rect(Rect.new(
        0,0,@sprites["bar"].bitmap.width,@sprites["bar"].bitmap.height
      ),BACKGROUND_COLOR)
    else
      @sprites["bar"].setBitmap(BG_PATH)
    end
  end

  def createPokemon(i)
    y = @yposition-8
    y-=8 if SHOW_HP_BARS
    if ANIMATED_ICONS
      @sprites["pokeicon#{i}"] = PokemonIconSprite.new(nil,@viewport1)
    else
      @sprites["pokeicon#{i}"] = IconSprite.new(@viewport1)
    end
    @sprites["pokeicon#{i}"].x = 16+64*i
    @sprites["pokeicon#{i}"].y = y
    createPokemonHPBar(i, 64*i+48, @yposition+55, 36, 10)
  end

  def createPokemonHPBar(i, x, y, width, height)
    fillWidth = width-4
    fillHeight = height-4
    @sprites["hpbarborder#{i}"] = BitmapSprite.new(width,height,@viewport1)
    @sprites["hpbarborder#{i}"].x = x-width/2
    @sprites["hpbarborder#{i}"].y = y-height/2
    @sprites["hpbarborder#{i}"].bitmap.fill_rect(
      Rect.new(0,0,width,height), Color.new(32,32,32)
    )
    @sprites["hpbarborder#{i}"].bitmap.fill_rect(
      (width-fillWidth)/2, (height-fillHeight)/2,
      fillWidth, fillHeight, Color.new(96,96,96)
    )
    @sprites["hpbarborder#{i}"].visible = false
    @sprites["hpbarfill#{i}"] = BitmapSprite.new(fillWidth,fillHeight,@viewport)
    @sprites["hpbarfill#{i}"].x = x-fillWidth/2
    @sprites["hpbarfill#{i}"].y = y-fillHeight/2
  end

  def createOverlay
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,BAR_HEIGHT,@viewport1)
    @sprites["overlay"].y = @yposition
    pbSetSystemFont(@sprites["overlay"].bitmap)
  end

  def refresh
    refreshAllPokemon
    refreshOverlay
  end

  def refreshAllPokemon
    for i in 0...6
      if $player && $player.party.size > i
        refreshPokemon(i, PokemonData.new($Trainer.party[i]))
      else
        refreshPokemon(i, nil)
      end
    end
  end

  def refreshPokemon(i, pokemonData)
    refreshPokemonIcon(i, pokemonData)
    refreshPokemonIconTone(i, pokemonData) if APPLY_STATUS_TONE
    refreshPokemonHPBar(i, pokemonData)
    @pokemonDataArray[i] = pokemonData
  end

  def refreshPokemonIcon(i, pokemonData)
    @sprites["pokeicon#{i}"].visible = pokemonData != nil
    if !pokemonData || PokemonData.eqlSpecies?(pokemonData,@pokemonDataArray[i])
      return
    end
    if ANIMATED_ICONS
      @sprites["pokeicon#{i}"].pokemon = $player.party[i]
    else
      @sprites["pokeicon#{i}"].setBitmap(
       GameData::Species.icon_filename_from_pokemon($player.party[i])
      )
      @sprites["pokeicon#{i}"].src_rect=Rect.new(0,0,64,64)
    end
  end

  def refreshPokemonIconTone(i, pokemonData)
    if !pokemonData || PokemonData.eqlStatus?(pokemonData,@pokemonDataArray[i])
      return
    end
    @sprites["pokeicon#{i}"].tone = @@tonePerStatus.fetch(
      pokemonData.status,:NONE
    )
  end

  def refreshPokemonHPBar(i, pokemonData)
    @sprites["hpbarborder#{i}"].visible = pokemonData!=nil && !pokemonData.isEgg
    @sprites["hpbarfill#{i}"].visible = @sprites["hpbarborder#{i}"].visible
    if !pokemonData || PokemonData.eqlHP?(pokemonData, @pokemonDataArray[i])
      return
    end
    @sprites["hpbarfill#{i}"].bitmap.clear
    fillAmount = (pokemonData.hp==0 || pokemonData.totalhp==0) ? 0 : (
      pokemonData.hp*@sprites["hpbarfill#{i}"].bitmap.width/pokemonData.totalhp
    )
    # Always show a bit of HP when alive
    fillAmount = 1 if fillAmount==0 && pokemonData.hp>0
    return if fillAmount <= 0
    hpColors = hpBarCurrentColors(pokemonData.hp, pokemonData.totalhp)
    shadowHeight = 2
    @sprites["hpbarfill#{i}"].bitmap.fill_rect(
      Rect.new(0,0,fillAmount,shadowHeight), hpColors[1]
    )
    @sprites["hpbarfill#{i}"].bitmap.fill_rect(
      Rect.new(
        0,shadowHeight,fillAmount,
        @sprites["hpbarfill#{i}"].bitmap.height-shadowHeight
      ), hpColors[0]
    )
  end

  def hpBarCurrentColors(hp, totalhp)
    if hp<=(totalhp/4.0)
      return HP_BAR_RED
    elsif hp<=(totalhp/2.0)
      return HP_BAR_YELLOW
    end
    return HP_BAR_GREEN
  end

  def refreshOverlay
    newText = textsDefined
    return if newText == @currentTextArray
    @currentTextArray = newText
    @sprites["overlay"].bitmap.clear
    x = Graphics.width-64
    textpos=[
      [@currentTextArray[0],x,6,2,TEXT_COLORS[0],TEXT_COLORS[1]],
      [@currentTextArray[1],x,38,2,TEXT_COLORS[0],TEXT_COLORS[1]]
    ]
    pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
  end

  def tryUpdate(force=false)
    if showHUD?
      update(force) if @lastRefreshFrame != Graphics.frame_count
    else
      dispose if hasSprites?
    end
  end

  def update(force)
    if hasSprites?
      if (
        force || FRAMES_PER_UPDATE<=1 ||
        Graphics.frame_count%FRAMES_PER_UPDATE==0
      )
        refresh
      end
    else
      create
    end
    pbUpdateSpriteHash(@sprites)
    @lastRefreshFrame = Graphics.frame_count
    self.class.tryUpdateAll if self.class.shouldUpdateAll?
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
  end

  def hasSprites?
    return !@sprites.empty?
  end

  def recreate
    dispose
    create
  end

  class << self
    def shouldUpdateAll?
      return @@lastGlobalRefreshFrame != Graphics.frame_count
    end

    def tryUpdateAll
      @@lastGlobalRefreshFrame = Graphics.frame_count
      for hud in @@instanceArray
        if (
          hud && hud.hasSprites? &&
          hud.lastRefreshFrame < @@lastGlobalRefreshFrame
        )
          hud.tryUpdate
        end
      end
    end

    def recreateAll
      for hud in @@instanceArray
        hud.recreate if hud && hud.hasSprites?
      end
    end
  end
end

class Spriteset_Map
  alias :initializeOldFL :initialize
  alias :disposeOldFL :dispose
  alias :updateOldFL :update

  def initialize(map=nil)
    $player = $Trainer if !$player # For compatibility with v20 and older
    initializeOldFL(map)
  end

  def dispose
    @hud.dispose if @hud
    disposeOldFL
  end

  def update
    updateOldFL
    @hud = HUD.new(@viewport1) if !@hud
    @hud.tryUpdate
  end
end

# For compatibility with older versions
module GameData
  class Species
    class << self
      if !method_defined?(:icon_filename_from_pokemon)
        def icon_filename_from_pokemon(pkmn)
          pbPokemonIconFile(pkmn)
        end
      end
    end
  end
end

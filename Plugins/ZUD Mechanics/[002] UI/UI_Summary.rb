#===============================================================================
# Adds Dynamax displays to the Summary UI.
#===============================================================================
class PokemonSummary_Scene
  #-----------------------------------------------------------------------------
  # Displays G-Max Factor. Will not display if the NO_DYNAMAX switch is active.
  #-----------------------------------------------------------------------------
  alias zud_drawPage drawPage
  def drawPage(page)
    @sprites["pokemon"].unDynamax
    if !@sprites["zud_overlay"]
      @sprites["zud_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    else
      @sprites["zud_overlay"].bitmap.clear
    end
    overlay = @sprites["zud_overlay"].bitmap
    coords = (PluginManager.installed?("BW Summary Screen")) ? [454, 82] : [88, 95]
    pbDisplayGmaxFactor(@pokemon, overlay, coords[0], coords[1])
    zud_drawPage(page)
  end
  
  alias zud_drawPageFour drawPageFour
  def drawPageFour
    @sprites["zud_overlay"].visible = true if @sprites["zud_overlay"]
    zud_drawPageFour
  end
  
  alias zud_drawSelectedMove drawSelectedMove
  def drawSelectedMove(*args)
    @sprites["zud_overlay"].visible = false if @sprites["zud_overlay"] 
    zud_drawSelectedMove(*args)
  end
  
  #-----------------------------------------------------------------------------
  # Displays Dynamax meter. Won't display on Pokemon that cannot use Dynamax.
  # Will not display if the NO_DYNAMAX switch is active.
  #-----------------------------------------------------------------------------
  alias zud_drawPageTwo drawPageTwo
  def drawPageTwo
	if PluginManager.installed?("BW Summary Screen")
      if @pokemon.dynamax_able? && !@pokemon.isSpecies?(:ETERNATUS) && !$game_switches[Settings::NO_DYNAMAX]
        path = "Graphics/Pictures/Summary/"
        meter = (SUMMARY_B2W2_STYLE) ? "overlay_dynamax_B2W2" : "overlay_dynamax"
        imagepos = [[sprintf(path + meter), 0, 302]]
        overlay = @sprites["zud_overlay"].bitmap
        pbSetSystemFont(overlay)
        pbDrawImagePositions(overlay, imagepos)
        dlevel = @pokemon.dynamax_lvl
        levels = AnimatedBitmap.new(_INTL(path + "dynamax_bar"))
        overlay.blt(82, 332, levels.bitmap, Rect.new(0, 0, dlevel * 16, 14))
        pbDrawTextPositions(overlay, [ [_INTL("Dynamax Lv."), 42, 296, 0, Color.new(255, 255, 255), Color.new(123, 123, 123)] ])
      end
    end
    zud_drawPageTwo
  end
  
  alias zud_drawPageThree drawPageThree
  def drawPageThree
    if !PluginManager.installed?("BW Summary Screen")
      if @pokemon.dynamax_able? && !@pokemon.isSpecies?(:ETERNATUS) && !$game_switches[Settings::NO_DYNAMAX]
        path = "Graphics/Plugins/ZUD/UI/"
        imagepos = [[sprintf(path + "dynamax_meter"), 56, 308]]
        overlay = @sprites["zud_overlay"].bitmap
        pbDrawImagePositions(overlay, imagepos)
        dlevel = @pokemon.dynamax_lvl
        levels = AnimatedBitmap.new(_INTL(path + "dynamax_levels"))
        overlay.blt(69, 325, levels.bitmap, Rect.new(0, 0, dlevel * 12, 21))
      end
    end
    zud_drawPageThree
  end
  
  #-----------------------------------------------------------------------------
  # Resets displays when changing Pokemon.
  #-----------------------------------------------------------------------------
  alias zud_pbChangePokemon pbChangePokemon
  def pbChangePokemon
    @sprites["zud_overlay"].bitmap.clear
    zud_pbChangePokemon
  end
end


#===============================================================================
# Draws the icon for G-Max Factor on a UI overlay.
#===============================================================================
def pbDisplayGmaxFactor(pokemon, overlay, xpos, ypos)
  return if $game_switches[Settings::NO_DYNAMAX]
  return if !pokemon.gmax_factor? || pokemon.isSpecies?(:ETERNATUS)
  path = (PluginManager.installed?("BW Party Screen")) ? "Graphics/Pictures/Summary/gfactor" : "Graphics/Plugins/ZUD/UI/gfactor"
  pbDrawImagePositions(overlay, [ [path, xpos, ypos] ])
end


#===============================================================================
# Applies Dynamax visuals to icon sprites in the Party menu.
#===============================================================================
class PokemonPartyPanel < Sprite
  alias zud_initialize initialize
  def initialize(*args)
    zud_initialize(*args)
    @pkmnsprite.applyDynamaxIcon
  end
  
  def pokemon=(value)
    @pokemon = value
    if @pkmnsprite && !@pkmnsprite.disposed?
      @pkmnsprite.pokemon = value
      @pkmnsprite.applyDynamaxIcon
    end
    @helditemsprite.pokemon = value if @helditemsprite && !@helditemsprite.disposed?
    @refreshBitmap = true
    refresh
  end
  
  alias zud_refresh_pokemon_icon refresh_pokemon_icon
  def refresh_pokemon_icon
    zud_refresh_pokemon_icon
    if @pkmnsprite && !@pkmnsprite.disposed?
      @pkmnsprite.unDynamax
      @pkmnsprite.applyDynamaxIcon
    end
  end
end
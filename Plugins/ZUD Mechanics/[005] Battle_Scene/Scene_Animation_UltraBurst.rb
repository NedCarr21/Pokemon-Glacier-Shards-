#===============================================================================
# Battle animation for triggering Ultra Burst.
#===============================================================================
class Battle::Scene::Animation::BattlerUltraBurst < Battle::Scene::Animation
  def initialize(sprites, viewport, idxBattler, battle)
    @idxBattler = idxBattler
    #---------------------------------------------------------------------------
    # Gets Pokemon data from battler index.
    #---------------------------------------------------------------------------
    @battle = battle
    @battler = @battle.battlers[idxBattler]
    @opposes = @battle.opposes?(idxBattler)
    pkmn = @battler.pokemon
    poke_data = [pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?]
    ultra_data = [pkmn.species, pkmn.getUltraForm, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?]
    #---------------------------------------------------------------------------
    # Gets background data from battle.
    #---------------------------------------------------------------------------
    case @battle.time
    when 1 then time = "eve"
    when 2 then time = "night"
    end
    backdropFilename = @battle.backdrop
    baseFilename = @battle.backdrop
    baseFilename = sprintf("%s_%s", baseFilename, @battle.backdropBase) if @battle.backdropBase
    if time
      trialName = sprintf("%s_%s", backdropFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_bg"))
        backdropFilename = trialName
      end
      trialName = sprintf("%s_%s", baseFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_base1"))
        baseFilename = trialName
      end
    end
    if !pbResolveBitmap(sprintf("Graphics/Battlebacks/" + baseFilename + "_base1")) &&
       @battle.backdropBase
      baseFilename = @battle.backdropBase
      if time
        trialName = sprintf("%s_%s", baseFilename, time)
        if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_base1"))
          baseFilename = trialName
        end
      end
    end
    @bg_zoom = 1 # Used to properly fit background on screen.
    #---------------------------------------------------------------------------
    # File names
    #---------------------------------------------------------------------------
    @fade_name    = "Graphics/Plugins/ZUD/Animations/anim_fade"
    @icon_name    = "Graphics/Plugins/ZUD/Animations/anim_ultra_icon"
    @strobes_name = "Graphics/Plugins/ZUD/Animations/anim_ultra_strobes"
    @bg_name      = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    @bg2_name     = "Graphics/Plugins/ZUD/Animations/anim_transition"
    @button_name  = "Graphics/Plugins/ZUD/Animations/skip_button"
    @base_name    = "Graphics/Battlebacks/" + baseFilename + "_base1"
    @poke_name    = GameData::Species.front_sprite_filename(*poke_data)
    @poke2_name   = GameData::Species.front_sprite_filename(*ultra_data)
    @cry_name     = GameData::Species.cry_filename(pkmn.species, pkmn.getUltraForm)
    super(sprites, viewport)
  end

  #-----------------------------------------------------------------------------
  # Plays the animation.
  #-----------------------------------------------------------------------------
  def createProcesses
    delay = 0
    center_x, center_y = Graphics.width / 2, Graphics.height / 2
    outline_offsets = [ [2, 0],  [-2, 0], [0, 2],  [0, -2], [2, 2],  
                        [-2, -2], [2, -2], [-2, 2], [0, 0] ]
    ############################################################################
    # Sets up sprites.
    ############################################################################
    # Background setup.
    #---------------------------------------------------------------------------
    if pbResolveBitmap("Graphics/Plugins/ZUD/Animations/anim_ultra")
      @bg_name = "Graphics/Plugins/ZUD/Animations/anim_ultra"
      pictureBG = addNewSprite(0, 0, @bg_name)
    elsif pbResolveBitmap(@bg_name)
      @bg_zoom = 1.5
      pictureBG = addNewSprite(0, 0, @bg_name)
    else
      @bg_name = "Graphics/Pictures/evolutionbg"
      pictureBG = addNewSprite(0, 0, @bg_name)
    end
    pictureBG.setVisible(delay, false)
    spriteBG = @pictureEx.length - 1
    @pictureSprites[spriteBG].z = 999
    pictureBG.setZ(delay, @pictureSprites[spriteBG].z)
    pictureBG.setZoom(delay, 100 * @bg_zoom)
    #---------------------------------------------------------------------------
    # Battle base setup.
    #---------------------------------------------------------------------------
    if pbResolveBitmap("Graphics/Plugins/ZUD/Animations/anim_ultra_base")
      @base_name = "Graphics/Plugins/ZUD/Animations/anim_ultra_base"
    end
    pictureBASE = addNewSprite(0, 0, @base_name)
    pictureBASE.setVisible(delay, false)
    spriteBASE = @pictureEx.length - 1
    @pictureSprites[spriteBASE].x = center_x - @pictureSprites[spriteBASE].bitmap.width / 2
    @pictureSprites[spriteBASE].y = center_y
    base_x, base_y = @pictureSprites[spriteBASE].x, @pictureSprites[spriteBASE].y
    pictureBASE.setXY(delay, base_x, base_y)
    pictureBASE.setZ(delay, @pictureSprites[spriteBG].z + 1)
    #---------------------------------------------------------------------------
    # Transition setup.
    #---------------------------------------------------------------------------
    pictureBG2 = addNewSprite(0, 0, @bg2_name)
    pictureBG2.setVisible(delay, false)
    spriteBG2 = @pictureEx.length - 1
    pictureBG2.setZ(delay, @pictureSprites[spriteBG].z + 2)
    pictureBG2.setOpacity(delay, 0)
    #---------------------------------------------------------------------------
    # Pokemon setup.
    #---------------------------------------------------------------------------
    battle_pos = Battle::Scene.pbBattlerPosition(1, 1)
    picturePOKE = addNewSprite(0, 0, @poke_name, PictureOrigin::BOTTOM)
    picturePOKE.setVisible(delay, false)
    spritePOKE = @pictureEx.length - 1
    @pictureSprites[spritePOKE].x = battle_pos[0] - 128
    @pictureSprites[spritePOKE].y = battle_pos[1] + 80
    @pictureSprites[spritePOKE].mirror = !@opposes
    @pictureSprites[spritePOKE].ox = @pictureSprites[spritePOKE].bitmap.width / 2
    @pictureSprites[spritePOKE].oy = @pictureSprites[spritePOKE].bitmap.height
    @battler.pokemon.species_data.apply_metrics_to_sprite(@pictureSprites[spritePOKE], 1)
    poke_x, poke_y = @pictureSprites[spritePOKE].x, @pictureSprites[spritePOKE].y
    picturePOKE.setXY(delay, poke_x, poke_y)
    picturePOKE.setZ(delay, @pictureSprites[spriteBG].z + 3)
    picturePOKE.setZoom(delay, 200) if PluginManager.installed?("Generation 8 Pack Scripts")
    #---------------------------------------------------------------------------
    # Ultra Pokemon setup.
    #---------------------------------------------------------------------------
    picturePOKE2 = []
    for i in outline_offsets
      outline = addNewSprite(0, 0, @poke2_name, PictureOrigin::BOTTOM)
      outline.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      @pictureSprites[sprite].mirror = !@opposes
      @pictureSprites[sprite].x = battle_pos[0] + i[0] - 128
      @pictureSprites[sprite].y = battle_pos[1] + i[1] + 80
      @pictureSprites[sprite].ox = @pictureSprites[sprite].bitmap.width / 2
      @pictureSprites[sprite].oy = @pictureSprites[sprite].bitmap.height
      metrics_data = GameData::SpeciesMetrics.get_species_form(@battler.species, @battler.pokemon.getUltraForm)
      metrics_data.apply_metrics_to_sprite(@pictureSprites[sprite], 1)
      outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
      outline.setZ(delay, @pictureSprites[spriteBG].z + 4)
      outline.setColor(delay, Color.new(255, 255, 255, 255)) if i != [0, 0]
      outline.setZoom(delay, 200) if PluginManager.installed?("Generation 8 Pack Scripts")
      picturePOKE2.push([outline, sprite])
    end
    #---------------------------------------------------------------------------
    # Ultra icon setup.
    #---------------------------------------------------------------------------
    pictureICON = addNewSprite(0, 0, @icon_name, PictureOrigin::CENTER)
    pictureICON.setVisible(delay, false)
    spriteICON = @pictureEx.length - 1
    @pictureSprites[spriteICON].x = center_x
    @pictureSprites[spriteICON].y = @pictureSprites[spriteICON].bitmap.height / 2
    pictureICON.setXY(delay, @pictureSprites[spriteICON].x, @pictureSprites[spriteICON].y)
    pictureICON.setZ(delay, @pictureSprites[spriteBG].z + 5)
    pictureICON.setOpacity(delay, 0)
    #---------------------------------------------------------------------------
    # Ultra strobes setup.
    #---------------------------------------------------------------------------
    x_offset, y_offset, pos_offset = 77, 64, 200
    pictureSTROBES = []
    4.times do |i|
      strobe = addNewSprite(0, 0, @strobes_name, PictureOrigin::CENTER)
      strobe.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      case i
      when 0
        strobe.setSrc(delay, 0, 0)
        strobe.setSrcSize(delay, 77, 64)
        @pictureSprites[sprite].x = center_x - pos_offset
        @pictureSprites[sprite].y = center_y - pos_offset
      when 1
        strobe.setSrc(delay, 77, 0)
        strobe.setSrcSize(delay, 154, 64)
        @pictureSprites[sprite].x = center_x + x_offset + pos_offset
        @pictureSprites[sprite].y = center_y - pos_offset
      when 2
        strobe.setSrc(delay, 0, 64)
        strobe.setSrcSize(delay, 77, 128)
        @pictureSprites[sprite].x = center_x - pos_offset
        @pictureSprites[sprite].y = center_y + y_offset + pos_offset
      when 3
        strobe.setSrc(delay, 77, 64)
        strobe.setSrcSize(delay, 154, 128)
        @pictureSprites[sprite].x = center_x + x_offset + pos_offset
        @pictureSprites[sprite].y = center_y + y_offset + pos_offset
      end
      origin_x, origin_y = @pictureSprites[sprite].x, @pictureSprites[sprite].y
      strobe.setXY(delay, origin_x, origin_y)
      strobe.setZ(delay, @pictureSprites[spriteBG].z + 6)
      pictureSTROBES.push([strobe, origin_x, origin_y])
    end
    #---------------------------------------------------------------------------
    # Skip button setup.
    #---------------------------------------------------------------------------
    pictureBUTTON = addNewSprite(0, Graphics.height, @button_name)
    pictureBUTTON.setZ(delay, @pictureSprites[spriteBG].z + 10)
    #---------------------------------------------------------------------------
    # Fade setup.
    #---------------------------------------------------------------------------
    pictureFADE = addNewSprite(0, 0, @fade_name)
    pictureFADE.setZ(delay, @pictureSprites[spriteBG].z + 10)
    pictureFADE.setOpacity(delay, 0)
    ############################################################################
    # Animation start.
    ############################################################################
    # Fades in scene.
    #---------------------------------------------------------------------------
    pictureFADE.moveOpacity(delay, 8, 255)
    delay = pictureFADE.totalDuration
    pictureBG.setVisible(delay, true)
    pictureBASE.setVisible(delay, true)
    picturePOKE.setVisible(delay, true)
    pictureFADE.moveOpacity(delay, 8, 0)
    delay = pictureFADE.totalDuration
    pictureBUTTON.moveXY(delay, 6, 0, Graphics.height - 38)
    pictureBUTTON.moveXY(delay + 26, 6, 0, Graphics.height)
    #---------------------------------------------------------------------------
    # Darkens background/base tone; begins zooming in ultra strobes.
    #---------------------------------------------------------------------------
    picturePOKE.setSE(delay, "Z-Power Up")
    pictureBG.moveTone(delay, 15, Tone.new(-200, -200, -200))
    pictureBASE.moveTone(delay, 15, Tone.new(-200, -200, -200))
    repeat = delay
    2.times do |t|
      repeat -= 4  if t > 0
      pictureSTROBES.each_with_index do |p, i|
        p[0].setVisible(repeat + i, true)
        p[0].moveXY(repeat + i, 4, center_x, center_y)
        p[0].moveZoom(repeat + i, 4, 0)
        repeat = p[0].totalDuration
        p[0].setVisible(repeat + i, false)
        p[0].setXY(repeat + i, p[1], p[2])
        p[0].setZoom(repeat + i, 100)
        repeat = p[0].totalDuration - 2
      end
    end
    #---------------------------------------------------------------------------
    # Shakes Pokemon; changes tone to white; shows and zooms in ultra icon.
    #---------------------------------------------------------------------------
    t = 0.5
    16.times do |i|
      picturePOKE.moveXY(delay, t, @pictureSprites[spritePOKE].x, @pictureSprites[spritePOKE].y + 2)
      picturePOKE.moveXY(delay + t, t, @pictureSprites[spritePOKE].x, @pictureSprites[spritePOKE].y - 2)
      delay = picturePOKE.totalDuration
      if i == 0
        pictureICON.setVisible(delay + 8, true)
        pictureICON.moveOpacity(delay + 8, 16, 255)
        pictureICON.moveZoom(delay + 8, 16, 50)
      end
    end
    picturePOKE.moveTone(delay - 8, 2, Tone.new(255, 255, 255, 255))
    #---------------------------------------------------------------------------
    # White screen flash; hides icon; reveals Ultra Pokemon with outline.
    #---------------------------------------------------------------------------
    pictureFADE.setColor(delay + 8, Color.white)
    pictureFADE.moveOpacity(delay + 8, 12, 255)
    delay = pictureFADE.totalDuration
    picturePOKE.setVisible(delay, false)
    pictureICON.setVisible(delay, false)
    picturePOKE2.each { |p, s| p.setVisible(delay, true) }
    pictureFADE.moveOpacity(delay, 6, 0)
    pictureFADE.setColor(delay + 6, Color.black)
    delay = pictureFADE.totalDuration
    #---------------------------------------------------------------------------
    # Shakes Pokemon; plays cry; flashes transition. Fades out.
    #---------------------------------------------------------------------------
    pictureBG2.setVisible(delay, true)
    16.times do |i|
      if i > 0
        picturePOKE2.each { |p, s| p.moveXY(delay, t, @pictureSprites[s].x, @pictureSprites[s].y + 2) }
        picturePOKE2.each { |p, s| p.moveXY(delay + t, t, @pictureSprites[s].x, @pictureSprites[s].y - 2) }
        pictureBG2.moveOpacity(delay + t, 2, 160)
      else
        picturePOKE.setSE(delay + t, @cry_name) if @cry_name
      end
      pictureBG2.moveOpacity(delay + t, 2, 240)
      delay = picturePOKE2.last[0].totalDuration
    end
    pictureBG2.moveOpacity(delay, 4, 0)
    pictureFADE.moveOpacity(delay + 20, 8, 255)
  end
end

#===============================================================================
# Calls the animation.
#===============================================================================
class Battle::Scene
  def pbShowUltraBurst(idxBattler, battle)
    ultraAnim = Animation::BattlerUltraBurst.new(@sprites, @viewport, idxBattler, battle)
    loop do
	  if Input.press?(Input::ACTION)
	    pbPlayCancelSE
	    break 
	  end
      ultraAnim.update
      pbUpdate
      break if ultraAnim.animDone?
    end
    ultraAnim.dispose
  end
end
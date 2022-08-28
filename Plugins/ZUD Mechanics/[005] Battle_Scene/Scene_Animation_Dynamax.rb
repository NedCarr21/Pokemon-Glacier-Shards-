#===============================================================================
# Battle animation for triggering Dynamax.
#===============================================================================
class Battle::Scene::Animation::BattlerDynamax < Battle::Scene::Animation
  #-----------------------------------------------------------------------------
  # Initializes data used for the animation.
  #-----------------------------------------------------------------------------
  def initialize(sprites, viewport, idxBattler, battle)
    #---------------------------------------------------------------------------
    # Gets Pokemon data from battler index.
    #---------------------------------------------------------------------------
    @battle = battle
    @battler = @battle.battlers[idxBattler]
    @opposes = @battle.opposes?(idxBattler)
    pkmn = @battler.pokemon
    if @battler.effects[PBEffects::Transform]
      pkmn = @battler.effects[PBEffects::TransformPokemon]
    elsif @battler.effects[PBEffects::Illusion]
      pkmn = @battler.effects[PBEffects::Illusion]
    end
    poke_data = [pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?, false, false]
    cry_data  = [pkmn.species, pkmn.form, "", pkmn.shiny?, pkmn.shadowPokemon?, true, @battler.gmax_factor?]
    @species_data = pkmn.species_data
    #---------------------------------------------------------------------------
    # Gets trainer data from battler index.
    #---------------------------------------------------------------------------
    items = []
    trainer_item = :DYNAMAXBAND
    trainer = @battle.pbGetOwnerFromBattlerIndex(idxBattler)
    GameData::Item.each { |item| items.push(item.id) if item.has_flag?("DynamaxBand") }
    if @battle.pbOwnedByPlayer?(idxBattler)
      items.each do |item|
        next if !$bag.has?(item)
        trainer_item = item
      end
    else
      trainer_items = @battle.pbGetOwnerItems(idxBattler)
      items.each do |item|
        next if !trainer_items&.include?(item)
        trainer_item = item
      end
    end
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
    @bg_zoom = 1                         # Used to properly fit background on screen.
    @calyrex = pkmn.isSpecies?(:CALYREX) # Used to determine colors used.
    #---------------------------------------------------------------------------
    # File names
    #---------------------------------------------------------------------------
    @fade_name    = "Graphics/Plugins/ZUD/Animations/anim_fade"
    @bg_name      = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    @bg2_name     = "Graphics/Plugins/ZUD/Animations/anim_transition"
    @button_name  = "Graphics/Plugins/ZUD/Animations/skip_button"
    @base_name    = "Graphics/Battlebacks/" + baseFilename + "_base1"
    @shadow_name  = GameData::Species.shadow_filename(pkmn.species, pkmn.form, true)
    @poke_name    = GameData::Species.front_sprite_filename(*poke_data)
    @poke2_name   = GameData::Species.front_sprite_filename(*poke_data += [true, @battler.gmax_factor?])
    @trainer_name = GameData::TrainerType.front_sprite_filename(trainer.trainer_type)
    @item_name    = "Graphics/Items/" + trainer_item.to_s
    @ball_name    = "Graphics/Battle animations/ball_" + pkmn.poke_ball.to_s
    @cry_name     = GameData::Species.cry_filename(*cry_data)
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
    if pbResolveBitmap("Graphics/Plugins/ZUD/Animations/anim_dynamax")
      @bg_name = "Graphics/Plugins/ZUD/Animations/anim_dynamax"
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
    # Transition setup.
    #---------------------------------------------------------------------------
    pictureBG2 = addNewSprite(0, 0, @bg2_name)
    pictureBG2.setVisible(delay, false)
    spriteBG2 = @pictureEx.length - 1
    pictureBG2.setZ(delay, @pictureSprites[spriteBG].z + 1)
    pictureBG2.setOpacity(delay, 0)
    #---------------------------------------------------------------------------
    # Dynamax shadow setup.
    #---------------------------------------------------------------------------
    pictureSHADOW = addNewSprite(0, 0, @shadow_name, PictureOrigin::CENTER)
    pictureSHADOW.setVisible(delay, false)
    spriteSHADOW = @pictureEx.length - 1
    shadow_offset = @pictureSprites[spriteSHADOW].bitmap.width / 2
    @pictureSprites[spriteSHADOW].x = center_x - shadow_offset
    @pictureSprites[spriteSHADOW].y = center_y
    shadow_x, shadow_y = @pictureSprites[spriteSHADOW].x, @pictureSprites[spriteSHADOW].y
    pictureSHADOW.setXY(delay, shadow_x, shadow_y)
    pictureSHADOW.setZ(delay, @pictureSprites[spriteBG].z + 1)
    pictureSHADOW.setZoom(delay, 0)
    pictureSHADOW.setOpacity(delay, 0)
    #---------------------------------------------------------------------------
    # Battle base setup.
    #---------------------------------------------------------------------------
    if pbResolveBitmap("Graphics/Plugins/ZUD/Animations/anim_dynamax_base")
      @base_name = "Graphics/Plugins/ZUD/Animations/anim_dynamax_base"
    end
    pictureBASE = addNewSprite(0, 0, @base_name)
    pictureBASE.setVisible(delay, false)
    spriteBASE = @pictureEx.length - 1
    @pictureSprites[spriteBASE].x = center_x - @pictureSprites[spriteBASE].bitmap.width / 2
    @pictureSprites[spriteBASE].y = center_y
    base_x, base_y = @pictureSprites[spriteBASE].x, @pictureSprites[spriteBASE].y
    pictureBASE.setXY(delay, base_x, base_y)
    pictureBASE.setZ(delay, @pictureSprites[spriteBG].z + 2)
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
    @species_data.apply_metrics_to_sprite(@pictureSprites[spritePOKE], 1)
    poke_x, poke_y = @pictureSprites[spritePOKE].x, @pictureSprites[spritePOKE].y
    picturePOKE.setXY(delay, poke_x, poke_y)
    picturePOKE.setZ(delay, @pictureSprites[spriteBG].z + 3)
    picturePOKE.setZoom(delay, 200) if PluginManager.installed?("Generation 8 Pack Scripts")
    #---------------------------------------------------------------------------
    # Dynamax Pokemon setup, with Dynamax outline.
    #---------------------------------------------------------------------------
    picturePOKE2 = []
    for i in outline_offsets
      outline = addNewSprite(0, 0, @poke2_name, PictureOrigin::BOTTOM)
      outline.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      @pictureSprites[sprite].mirror = !@opposes
      @pictureSprites[sprite].x = battle_pos[0] + i[0] - 128
      @pictureSprites[sprite].y = battle_pos[1] + i[1] + 110
      @pictureSprites[sprite].ox = @pictureSprites[sprite].bitmap.width / 2
      @pictureSprites[sprite].oy = @pictureSprites[sprite].bitmap.height
      @species_data.apply_metrics_to_sprite(@pictureSprites[sprite], 1, nil, @battler.pokemon.gmax_factor? ? 2 : 1)
      poke2_x, poke2_y = @pictureSprites[sprite].x, @pictureSprites[sprite].y
      outline.setXY(delay, poke2_x, poke2_y)
      outline.setZ(delay, @pictureSprites[spriteBG].z + 3)
      outline.setZoom(delay, 0)
      outline.setOpacity(delay, 0)
      outline.setColor(delay, Color.new(255, 255, 255, 255))
      picturePOKE2.push([outline, sprite])
    end
    #---------------------------------------------------------------------------
    # Trainer setup.
    #---------------------------------------------------------------------------
    pictureTRAINER = addNewSprite(0, 0, @trainer_name)
    pictureTRAINER.setVisible(delay, false)
    spriteTRAINER = @pictureEx.length - 1
    @pictureSprites[spriteTRAINER].y = 138
    if @opposes
      offset = 64
      @pictureSprites[spriteTRAINER].x = Graphics.width
    else
      offset = -64
      @pictureSprites[spriteTRAINER].mirror = true
      @pictureSprites[spriteTRAINER].x = -@pictureSprites[spriteTRAINER].bitmap.width
    end
    trainer_x, trainer_y = @pictureSprites[spriteTRAINER].x, @pictureSprites[spriteTRAINER].y
    pictureTRAINER.setXY(delay, trainer_x, trainer_y)
    pictureTRAINER.setZ(delay, @pictureSprites[spriteBG].z + 4)
    trainer_end_x = center_x - @pictureSprites[spriteTRAINER].bitmap.width / 2
    #---------------------------------------------------------------------------
    # Dynamax Band setup, with white outline.
    #---------------------------------------------------------------------------
    pictureITEM = []
    for i in outline_offsets
      outline = addNewSprite(0, 0, @item_name, PictureOrigin::BOTTOM)
      outline.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      @pictureSprites[sprite].x = center_x + i[0]
      @pictureSprites[sprite].y = 130 + i[1]
      @pictureSprites[sprite].oy = @pictureSprites[sprite].bitmap.height
      outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
      outline.setZ(delay, @pictureSprites[spriteBG].z + 5)
      outline.setOpacity(delay, 0)
      outline.setColor(delay, Color.new(255, 255, 255, 255)) if i != [0, 0]
      pictureITEM.push([outline, sprite])
    end
    #---------------------------------------------------------------------------
    # Poke Ball setup.
    #---------------------------------------------------------------------------
    pictureBALL = addNewSprite(0, 0, @ball_name, PictureOrigin::CENTER)
    pictureBALL.setVisible(delay, false)
    spriteBALL = @pictureEx.length - 1
    @pictureSprites[spriteBALL].x = center_x + 112
    @pictureSprites[spriteBALL].y = center_y + 55
    ball_x, ball_y = @pictureSprites[spriteBALL].x, @pictureSprites[spriteBALL].y
    pictureBALL.setSrcSize(delay, 32, 64)
    pictureBALL.setXY(delay, ball_x, ball_y)
    pictureBALL.setZ(delay, @pictureSprites[spriteBG].z + 5)
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
    pictureBALL.setVisible(delay, true)
    pictureFADE.moveOpacity(delay, 8, 0)
    delay = pictureFADE.totalDuration
    pictureBUTTON.moveXY(delay, 6, 0, Graphics.height - 38)
    pictureBUTTON.moveXY(delay + 36, 6, 0, Graphics.height)
    #---------------------------------------------------------------------------
    # Opens Poke Ball; begins recall of Pokemon.
    #---------------------------------------------------------------------------
    picturePOKE.moveColor(delay, 4, Color.new(31 * 8, 22 * 8, 30 * 8, 255))
    delay = picturePOKE.totalDuration
    picturePOKE.setSE(delay, "Battle recall")
    pictureBALL.setName(delay, @ball_name + "_open")
    pictureBALL.setSrcSize(delay, 32, 64)
    #---------------------------------------------------------------------------
    # Shrink and move Pokemon sprite to ball; close ball.
    #---------------------------------------------------------------------------
    picturePOKE.moveZoom(delay, 6, 0)
    picturePOKE.moveXY(delay, 6, center_x, ball_y)
    picturePOKE.setVisible(delay + 6, false)
    delay = picturePOKE.totalDuration + 1
    pictureBALL.setName(delay, @ball_name)
    pictureBALL.setSrcSize(delay, 32, 64)
    #---------------------------------------------------------------------------
    # Slides trainer on screen; shifts ball over.
    #---------------------------------------------------------------------------
    pictureBALL.moveXY(delay, 8, ball_x + -offset, ball_y)
    pictureTRAINER.setVisible(delay + 6, true)
    pictureTRAINER.moveXY(delay + 6, 12, trainer_end_x, trainer_y)
    delay = pictureTRAINER.totalDuration + 1
    #---------------------------------------------------------------------------
    # Dynamax Band appears with outline; slides upwards.
    #---------------------------------------------------------------------------    
    pictureBALL.setSE(delay, "Z-Power Up")
    pictureITEM.each do |p, s| 
      p.setVisible(delay, true)
      p.moveXY(delay, 15, @pictureSprites[s].x, @pictureSprites[s].y - 20)
      p.moveOpacity(delay, 15, 255)
    end
    delay = pictureITEM.last[0].totalDuration + 1
    #---------------------------------------------------------------------------
    # Poke Ball enlarges and changes color.
    #---------------------------------------------------------------------------
    pictureBALL.setSE(delay, sprintf("Anim/Psych Up"), 100)
    pictureBALL.moveZoom(delay, 6, 150)
    enlarge_x = (@opposes) ? -8 : 120
    pictureBALL.moveXY(delay, 6, ball_x + enlarge_x, ball_y)
    pictureBALL.moveColor(delay, 6, Color.new(255, 51, 153, 180))
    delay = pictureBALL.totalDuration + 6
    pictureBALL.setVisible(delay, false)
    pictureITEM.each { |p, s| p.setVisible(delay, false) }
    #---------------------------------------------------------------------------
    # Transition flashes; trainer and battle base zoom off screen.
    #---------------------------------------------------------------------------
    pictureBG.moveZoom(delay, 6, @bg_zoom * 150)
    pictureBG2.setVisible(delay, true)
    pictureBG2.moveOpacity(delay, 6, 255)
    pictureBASE.moveZoom(delay, 6, 600)
    pictureBASE.setOpacity(delay + 6, 0)
    pictureTRAINER.moveXY(delay, 6, trainer_end_x + 128, trainer_y) if @opposes
    pictureTRAINER.moveZoom(delay, 6, 600)
    pictureTRAINER.setSE(delay, "Battle throw", 100)
    pictureTRAINER.setVisible(delay + 6, false)
    delay = pictureTRAINER.totalDuration
    #---------------------------------------------------------------------------
    # Base reappears to serve as the "landing" spot for Poke Ball.
    #---------------------------------------------------------------------------
    bg_x, bg_y = -(Graphics.width / 4), -(Graphics.height / 4)
    pictureBG.setXY(delay, bg_x, bg_y)
    pictureBASE.setXY(delay, base_x, base_y)
    pictureBASE.setZoom(delay, 100)
    pictureBASE.moveOpacity(delay, 6, 255)
    pictureBG2.moveOpacity(delay, 6, 0)
    pictureBG2.setVisible(delay + 4, false)
    delay = pictureBG2.totalDuration + 20
    #---------------------------------------------------------------------------
    # Poke Ball drops, sinks into base, and shakes screen.
    #---------------------------------------------------------------------------
    new_ball_x = ball_x + enlarge_x + offset
    pictureBALL.setVisible(delay, true)
    pictureBALL.setXY(delay, new_ball_x, -32)
    delay = pictureBALL.totalDuration + 2
    4.times do |i|
      t = [4, 4, 3, 2][i]
      d = [1, 2, 4, 8][i]
      delay -= t if i == 0
      if i > 0
        pictureBG.moveXY(delay, t, bg_x, bg_y - (100 / d))
        pictureBASE.moveXY(delay, t, base_x, base_y - (100 / d))
        pictureBALL.moveXY(delay, t, new_ball_x, ball_y - (100 / d))
      else
        pictureBALL.setSrcSize(delay + (2 * t), 32, 40)
        pictureBALL.setSE(delay + (2 * t), sprintf("Anim/Earth1"))
      end
      pictureBG.moveXY(delay + t, t, bg_x, bg_y)
      pictureBASE.moveXY(delay + t, t, base_x, base_y)
      pictureBALL.moveXY(delay + t, t, new_ball_x, ball_y)
      delay = pictureBALL.totalDuration
    end
    #---------------------------------------------------------------------------
    # Poke Ball opens.
    #---------------------------------------------------------------------------
    delay += 10
    pictureBASE.moveOpacity(delay, 4, 0)
    picturePOKE2.each do |p, s| 
      p.setVisible(delay, true)
      p.setXY(delay, @pictureSprites[s].x, @pictureSprites[s].y - 48)
    end
    pictureBALL.setSE(delay, "Battle recall")
    pictureBALL.setName(delay, @ball_name + "_open")
    pictureBALL.setSrcSize(delay, 32, 40)
    pictureBALL.moveOpacity(delay, 4, 0)
    #---------------------------------------------------------------------------
    # Dynamax Pokemon zooms out of ball; shadow expands along with Pokemon.
    #---------------------------------------------------------------------------
    pictureSHADOW.setVisible(delay, true)
    pictureSHADOW.setXY(delay, shadow_x + shadow_offset, shadow_y *= 1.5)
    pictureSHADOW.moveZoom(delay, 20, 200)
    pictureSHADOW.moveOpacity(delay, 20, 100)
    zoom = (PluginManager.installed?("Generation 8 Pack Scripts")) ? 300 : 150
    picturePOKE2.each do |p, s| 
      p.setSE(delay, sprintf("Anim/Psych Up"), 100, 60)
      p.moveXY(delay, 6, @pictureSprites[s].x, @pictureSprites[s].y)
      p.moveZoom(delay, 20, zoom)
      p.moveOpacity(delay, 4, 255)
    end
    #---------------------------------------------------------------------------
    # Background zooms out along with Pokemon; color and tone changes.
    #---------------------------------------------------------------------------
    delay += 4
    pictureBG.moveXY(delay, 20, -4, -4)
    pictureBG.moveZoom(delay, 20, @bg_zoom * 100)
    bg_color = (@calyrex) ? Color.new(0, 204, 204, 245) : Color.new(255, 51, 153, 245)
    pictureBG.moveColor(delay, 20, bg_color)
    pictureBG.moveTone(delay, 10, Tone.new(100, 100, 100, 100))
    #---------------------------------------------------------------------------
    # Trainer and the battle base zoom back in from off screen.
    #---------------------------------------------------------------------------
    trainer_x = (@opposes) ? offset * 2 + 32 : offset / 2
    new_trainer_x, new_trainer_y = trainer_end_x + trainer_x, trainer_y + 160
    pictureBASE.setOrigin(delay, PictureOrigin::CENTER)
    pictureBASE.setXY(delay, new_trainer_x, new_trainer_y + 228)
    pictureBASE.setZoom(delay, 600)
    pictureBASE.moveZoom(delay, 16, 50)
    pictureBASE.moveXY(delay, 16, new_trainer_x, new_trainer_y + 32)
    pictureBASE.moveOpacity(delay, 16, 255)
    pictureTRAINER.setVisible(delay, true)
    pictureTRAINER.setOrigin(delay, PictureOrigin::CENTER)
    pictureTRAINER.setXY(delay, new_trainer_x, new_trainer_y)
    pictureTRAINER.moveZoom(delay, 16, 50)
    delay = pictureBG.totalDuration + 4
    #---------------------------------------------------------------------------
    # Changes the tone and color of the background and base. Flashes transition.
    #---------------------------------------------------------------------------
    bg_color = (@calyrex) ? Color.new(0, 204, 204, 80) : Color.new(255, 51, 153, 80)
    pictureBG2.setOpacity(delay, 255)
    pictureBG2.setColor(delay, Color.new(255, 51, 153, 200)) if !@calyrex
    pictureBG.setName(delay, "Graphics/Pictures/evolutionbg")
    pictureBG.setZoom(delay, 110)
    pictureBG.setXY(delay, -25, -19)
    pictureBG.moveColor(delay, 10, bg_color)
    pictureBG.moveTone(delay, 10, Tone.new(-200, -200, -200))
    pictureBASE.moveColor(delay, 10, bg_color)
    pictureBASE.moveTone(delay, 10, Tone.new(-100, -100, -100))
    #---------------------------------------------------------------------------
    # Shakes screen; plays Pokemon cry while flashing the transition. Fades out.
    #---------------------------------------------------------------------------
    delay = pictureBG.totalDuration + 12
    6.times do |i|
      t = [4, 4, 3, 2, 2, 2][i]
      d = [2, 4, 4, 4, 8, 8][i]
      delay -= t if i == 0
      if i > 0
        pictureBG2.moveOpacity(delay + 2, t, 240)
        pictureBG.moveXY(delay, t, -25, -(100 / d))        
        pictureBASE.moveXY(delay, t, new_trainer_x, (new_trainer_y + 32) - (100 / d))
        pictureTRAINER.moveXY(delay, t, new_trainer_x, new_trainer_y - (100 / d))
        picturePOKE2.each { |p, s| p.moveXY(delay + 2, t, @pictureSprites[s].x, @pictureSprites[s].y - (200 / d)) }
      else
        pictureBG2.setVisible(delay, true)
        for i in 0...picturePOKE2.length
          if picturePOKE2[i] == picturePOKE2.last
            if @battler.gmax_factor?
              picturePOKE2[i][0].setSE(delay + (2 * t), @cry_name) if @cry_name
            else
              picturePOKE2[i][0].setSE(delay + (2 * t), @cry_name, 100, 60) if @cry_name
            end
            picturePOKE2[i][0].setSE(delay + (2 * t), sprintf("Anim/Explosion3"))
            if Settings::SHOW_DYNAMAX_COLOR
              poke_color = (@calyrex) ? Settings::CALYREX_COLOR : Settings::DYNAMAX_COLOR
              picturePOKE2[i][0].moveColor(delay, 5, poke_color)
            else
              picturePOKE2[i][0].moveColor(delay, 5, Color.new(31 * 8, 22 * 8, 30 * 8, 0))
            end
          else
            outline_color = (@calyrex) ? Color.new(36, 243, 243) : Color.new(250, 57, 96)
            picturePOKE2[i][0].moveColor(delay, 5, outline_color)
          end
        end
      end
      pictureBG2.moveOpacity(delay + t, t, 160)
      pictureBG.moveXY(delay + t, t, -25, -19)
      pictureBASE.moveXY(delay + t, t, new_trainer_x, new_trainer_y + 32)
      pictureTRAINER.moveXY(delay + t, t, new_trainer_x, new_trainer_y)
      picturePOKE2.each { |p, s| p.moveXY(delay + t, t, @pictureSprites[s].x, @pictureSprites[s].y) }
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
  def pbShowDynamax(idxBattler, battle)
    dynamaxAnim = Animation::BattlerDynamax.new(@sprites, @viewport, idxBattler, battle)
    loop do
	  if Input.press?(Input::ACTION)
	    pbPlayCancelSE
	    break 
	  end
      dynamaxAnim.update
      pbUpdate
      break if dynamaxAnim.animDone?
    end
    dynamaxAnim.dispose
  end
end


#===============================================================================
# Battle animations for reverting Dynamax.
# Note that the actual changing of the Pokemon sprite is handled elsewhere.
#===============================================================================
class Battle::Scene::Animation::RevertDynamax < Battle::Scene::Animation
  def initialize(sprites, viewport, idxBattler)
    @idxBattler = idxBattler
    super(sprites, viewport)
  end

  def createProcesses
    # Flashes the Pokemon white, plays sound effect.
    battler = addSprite(@sprites["pokemon_#{@idxBattler}"], PictureOrigin::BOTTOM)
    battler.setSE(0, sprintf("Anim/Psych Up"))
    battler.moveTone(0, 8, Tone.new(255, 255, 255, 255))
  end
end

class Battle::Scene::Animation::RevertDynamax2 < Battle::Scene::Animation
  def initialize(sprites, viewport, idxBattler)
    @idxBattler = idxBattler
    super(sprites, viewport)
  end

  def createProcesses
    # Reverts Pokemon to its proper colors.
    battler = addSprite(@sprites["pokemon_#{@idxBattler}"], PictureOrigin::BOTTOM)
    battler.moveTone(0, 8, Tone.new(0, 0, 0, 0))
  end
end

#-------------------------------------------------------------------------------
# Calls the animations.
#-------------------------------------------------------------------------------
class Battle::Scene
  def pbRevertDynamax(idxBattler)
    reversionAnim = Animation::RevertDynamax.new(@sprites, @viewport, idxBattler)
    loop do
      reversionAnim.update
      pbUpdate
      break if reversionAnim.animDone?
    end
    reversionAnim.dispose
  end
  
  def pbRevertDynamax2(idxBattler)
    reversionAnim = Animation::RevertDynamax2.new(@sprites, @viewport, idxBattler)
    loop do
      reversionAnim.update
      pbUpdate
      break if reversionAnim.animDone?
    end
    reversionAnim.dispose
  end
end
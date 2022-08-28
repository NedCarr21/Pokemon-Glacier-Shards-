#===============================================================================
# Battle animation for triggering Z-Moves.
#===============================================================================
class Battle::Scene::Animation::BattlerZMove < Battle::Scene::Animation
  #-----------------------------------------------------------------------------
  # Initializes data used for the animation.
  #-----------------------------------------------------------------------------
  def initialize(sprites, viewport, idxBattler, move_id, battle)
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
    poke_data = [pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?]
    @species_data = pkmn.species_data
    #---------------------------------------------------------------------------
    # Gets trainer data from battler index.
    #---------------------------------------------------------------------------
    items = []
    trainer_item = :ZRING
    trainer = @battle.pbGetOwnerFromBattlerIndex(idxBattler)
    GameData::Item.each { |item| items.push(item.id) if item.has_flag?("ZRing") }
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
    # Gets type colors from move id.
    #---------------------------------------------------------------------------
    case GameData::Move.get(move_id).type
    when :NORMAL   then @type_outline = [216, 216, 192]; @type_bg = [168, 168, 120]
    when :FIGHTING then @type_outline = [240, 128, 48];  @type_bg = [192, 48, 40]
    when :FLYING   then @type_outline = [200, 192, 248]; @type_bg = [168, 144, 240]
    when :POISON   then @type_outline = [216, 128, 184]; @type_bg = [160, 64, 160]
    when :GROUND   then @type_outline = [248, 248, 120]; @type_bg = [224, 192, 104]
    when :ROCK     then @type_outline = [224, 192, 104]; @type_bg = [184, 160, 56]
    when :BUG      then @type_outline = [216, 224, 48];  @type_bg = [168, 184, 32]
    when :GHOST    then @type_outline = [168, 144, 240]; @type_bg = [112, 88, 152]
    when :STEEL    then @type_outline = [216, 216, 192]; @type_bg = [184, 184, 208]
    when :FIRE     then @type_outline = [248, 208, 48];  @type_bg = [240, 128, 48]
    when :WATER    then @type_outline = [152, 216, 216]; @type_bg = [104, 144, 240]
    when :GRASS    then @type_outline = [192, 248, 96];  @type_bg = [120, 200, 80]
    when :ELECTRIC then @type_outline = [248, 248, 120]; @type_bg = [248, 208, 48]
    when :PSYCHIC  then @type_outline = [248, 192, 176]; @type_bg = [248, 88, 136]
    when :ICE      then @type_outline = [208, 248, 232]; @type_bg = [152, 216, 216]
    when :DRAGON   then @type_outline = [184, 160, 248]; @type_bg = [112, 56, 248]
    when :DARK     then @type_outline = [168, 168, 120]; @type_bg = [112, 88, 72]
    when :FAIRY    then @type_outline = [248, 216, 224]; @type_bg = [240, 168, 176]
    else                @type_outline = [255, 255, 255]; @type_bg = [200, 200, 200]
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
    @bg_zoom = 1 # Used to properly fit background on screen.
    #---------------------------------------------------------------------------
    # File names
    #---------------------------------------------------------------------------
    @fade_name    = "Graphics/Plugins/ZUD/Animations/anim_fade"
    @bg_name      = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    @bg2_name     = "Graphics/Plugins/ZUD/Animations/anim_transition"
    @button_name  = "Graphics/Plugins/ZUD/Animations/skip_button"
    @base_name    = "Graphics/Battlebacks/" + baseFilename + "_base1"
    @poke_name    = GameData::Species.front_sprite_filename(*poke_data)
    @trainer_name = GameData::TrainerType.front_sprite_filename(trainer.trainer_type)
    @item_name    = "Graphics/Items/" + trainer_item.to_s
    @crystal_name = "Graphics/Items/" + @battler.item_id.to_s
    @title_name   = "Graphics/Plugins/ZUD/Animations/Titles/" + move_id.to_s
    @upper_title  = [:CATASTROPIKA, :TENMILLIONVOLTTHUNDERBOLT, :LETSSNUGGLEFOREVER].include?(move_id)
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
    if pbResolveBitmap("Graphics/Plugins/ZUD/Animations/anim_zmove")
      @bg_name = "Graphics/Plugins/ZUD/Animations/anim_zmove"
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
    if pbResolveBitmap("Graphics/Plugins/ZUD/Animations/anim_zmove_base")
      @base_name = "Graphics/Plugins/ZUD/Animations/anim_zmove_base"
    end
    tr_base_offset = 0
    pictureBASE = []
    2.times do |i|
      base = addNewSprite(0, 0, @base_name)
      base.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      case i
      when 0
        if @opposes
          @pictureSprites[sprite].x = Graphics.width
        else
          @pictureSprites[sprite].x = -@pictureSprites[sprite].bitmap.width
        end
        @pictureSprites[sprite].y = center_y - 33
        tr_base_offset = @pictureSprites[sprite].bitmap.width / 4
      when 1
        @pictureSprites[sprite].x = center_x - @pictureSprites[sprite].bitmap.width / 2
        @pictureSprites[sprite].y = center_y + 20
      end
      base.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
      base.setZ(delay, @pictureSprites[spriteBG].z + i)
      pictureBASE.push(base)
    end
    #---------------------------------------------------------------------------
    # Trainer setup.
    #---------------------------------------------------------------------------
    pictureTRAINER = addNewSprite(0, 0, @trainer_name)
    pictureTRAINER.setVisible(delay, false)
    spriteTRAINER = @pictureEx.length - 1
    @pictureSprites[spriteTRAINER].y = 105
    if @opposes
      @pictureSprites[spriteTRAINER].x = Graphics.width 
      trainer_end_x = Graphics.width - @pictureSprites[spriteTRAINER].bitmap.width
    else
      @pictureSprites[spriteTRAINER].mirror = true
      @pictureSprites[spriteTRAINER].x = -@pictureSprites[spriteTRAINER].bitmap.width
      trainer_end_x = 0
    end
    trainer_x, trainer_y = @pictureSprites[spriteTRAINER].x, @pictureSprites[spriteTRAINER].y
    pictureTRAINER.setXY(delay, trainer_x, trainer_y)
    pictureTRAINER.setZ(delay, @pictureSprites[spriteBG].z + 1)
    #---------------------------------------------------------------------------
    # Z-Ring setup, with white outline.
    #---------------------------------------------------------------------------
    pictureITEM = []
    for i in outline_offsets
      outline = addNewSprite(0, 0, @item_name, PictureOrigin::BOTTOM)
      outline.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      @pictureSprites[sprite].x = trainer_end_x + (@pictureSprites[spriteTRAINER].bitmap.width / 2) + i[0]
      @pictureSprites[sprite].y = 97 + i[1]
      @pictureSprites[sprite].oy = @pictureSprites[sprite].bitmap.height
      outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
      outline.setZ(delay, @pictureSprites[spriteBG].z + 3)
      outline.setOpacity(delay, 0)
      outline.setColor(delay, Color.new(255, 255, 255, 255)) if i != [0, 0]
      pictureITEM.push([outline, sprite])
    end
    #---------------------------------------------------------------------------
    # Pokemon setup, with type outline.
    #---------------------------------------------------------------------------
    picturePOKE = []
    battle_pos = Battle::Scene.pbBattlerPosition(1, 1)
    for i in outline_offsets
      outline = addNewSprite(0, 0, @poke_name, PictureOrigin::BOTTOM)
      outline.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      @pictureSprites[sprite].mirror = !@opposes
      @pictureSprites[sprite].x = battle_pos[0] + i[0] - 128
      @pictureSprites[sprite].y = battle_pos[1] + i[1] + 100
      @pictureSprites[sprite].ox = @pictureSprites[sprite].bitmap.width / 2
      @pictureSprites[sprite].oy = @pictureSprites[sprite].bitmap.height
      @species_data.apply_metrics_to_sprite(@pictureSprites[sprite], 1)
      poke_x, poke_y = @pictureSprites[sprite].x, @pictureSprites[sprite].y
      outline.setXY(delay, poke_x, poke_y)
      outline.setZ(delay, @pictureSprites[spriteBG].z + 4)
      outline.setColor(delay, Color.new(*@type_outline)) if i != [0, 0]
      outline.setZoom(delay, 200) if PluginManager.installed?("Generation 8 Pack Scripts")
      picturePOKE.push([outline, sprite])
    end
    #---------------------------------------------------------------------------
    # Z-Crystal setup, with white outline.
    #---------------------------------------------------------------------------
    pictureCRYSTAL = []
    for i in outline_offsets
      outline = addNewSprite(0, 0, @crystal_name, PictureOrigin::BOTTOM)
      outline.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      @pictureSprites[sprite].x = center_x + i[0]
      @pictureSprites[sprite].y = (poke_y - @pictureSprites[picturePOKE.last[1]].bitmap.height) + i[1]
      @pictureSprites[sprite].oy = @pictureSprites[sprite].bitmap.height
      outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
      outline.setZ(delay, @pictureSprites[spriteBG].z + 5)
      outline.setOpacity(delay, 0)
      outline.setColor(delay, Color.new(255, 255, 255, 255)) if i != [0, 0]
      pictureCRYSTAL.push([outline, sprite])
    end
    #---------------------------------------------------------------------------
    # Z-Move Title setup, with type outline.
    #---------------------------------------------------------------------------
    pictureTITLE = []
    if pbResolveBitmap(@title_name)
      for i in outline_offsets
        outline = addNewSprite(0, 0, @title_name, PictureOrigin::CENTER)
        outline.setVisible(delay, false)
        sprite = @pictureEx.length - 1
        @pictureSprites[sprite].x = (Graphics.width - @pictureSprites[sprite].bitmap.width / 2) + i[0]
        if @upper_title
          @pictureSprites[sprite].y = @pictureSprites[sprite].bitmap.height / 2 + i[1]
        else
          @pictureSprites[sprite].y = (Graphics.height - @pictureSprites[sprite].bitmap.height / 2) + i[1]
        end
        outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
        outline.setZ(delay, @pictureSprites[spriteBG].z + 6)
        outline.setZoom(delay, 300)
        outline.setOpacity(delay, 0)
        outline.setColor(delay, Color.new(*@type_outline)) if i != [0, 0]
        outline.setTone(delay, Tone.new(255, 255, 255, 255))
        pictureTITLE.push([outline, sprite])
      end
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
    pictureBASE.last.setVisible(delay, true)
    picturePOKE.last[0].setVisible(delay, true)
    pictureFADE.moveOpacity(delay, 8, 0)
    delay = pictureFADE.totalDuration
    pictureBUTTON.moveXY(delay, 6, 0, Graphics.height - 38)
    pictureBUTTON.moveXY(delay + 36, 6, 0, Graphics.height)
    #---------------------------------------------------------------------------
    # Slides trainer on screen with base.
    #---------------------------------------------------------------------------
    pictureTRAINER.setVisible(delay + 4, true)
    pictureBASE.first.setVisible(delay + 4, true)
    pictureTRAINER.moveXY(delay + 4, 8, trainer_end_x, trainer_y)
    pictureBASE.first.moveXY(delay + 4, 8, trainer_end_x - tr_base_offset, center_y - 33)
    delay = pictureTRAINER.totalDuration + 1
    #---------------------------------------------------------------------------
    # Z-Ring and Z-Crystal appear with outline; slide upwards.
    #---------------------------------------------------------------------------    
    pictureTRAINER.setSE(delay, "Z-Power Up")
    pictureITEM.each do |p, s| 
      p.setVisible(delay, true)
      p.moveXY(delay, 15, @pictureSprites[s].x, @pictureSprites[s].y - 20)
      p.moveOpacity(delay, 15, 255)
    end
    pictureCRYSTAL.each do |p, s| 
      p.setVisible(delay, true)
      p.moveXY(delay, 15, @pictureSprites[s].x, @pictureSprites[s].y - 20)
      p.moveOpacity(delay, 15, 255)
    end
    #---------------------------------------------------------------------------
    # Darkens background/base tone; brightens Pokemon tone to white. Shakes Pokemon.
    #---------------------------------------------------------------------------
    pictureBG.moveColor(delay, 15, Color.new(*@type_bg, 180))
    pictureBG.moveTone(delay, 15, Tone.new(-200, -200, -200))
    pictureBASE.each do |p|
      p.moveColor(delay, 15, Color.new(*@type_bg, 180))
      p.moveTone(delay, 15, Tone.new(-200, -200, -200))
    end
    picturePOKE.last[0].moveTone(delay, 15, Tone.new(255, 255, 255, 255))
    delay = pictureTRAINER.totalDuration
    t = 0.5
    16.times do |i|
      picturePOKE.each { |p, s| p.moveXY(delay, t, @pictureSprites[s].x, @pictureSprites[s].y + 2) }
      picturePOKE.each { |p, s| p.moveXY(delay + t, t, @pictureSprites[s].x, @pictureSprites[s].y - 2) }
      delay = picturePOKE.first[0].totalDuration
    end
    #---------------------------------------------------------------------------
    # White screen flash; hides item sprites; reverts Pokemon tone; shows outline.
    #---------------------------------------------------------------------------
    pictureFADE.setColor(delay, Color.white)
    pictureFADE.moveOpacity(delay, 12, 255)
    delay = pictureFADE.totalDuration
    pictureITEM.each { |p, s| p.setVisible(delay, false) }
    pictureCRYSTAL.each { |p, s| p.setVisible(delay, false) }
    picturePOKE.each { |p, s| p.setVisible(delay, true) }
    picturePOKE.last[0].moveTone(delay, 6, Tone.new(0, 0, 0, 0))
    pictureFADE.moveOpacity(delay, 6, 0)
    pictureFADE.setColor(delay + 6, Color.black)
    delay = pictureFADE.totalDuration
    #---------------------------------------------------------------------------
    # Zooms Z-Move title on screen; shakes title and reveals name; fades out.
    #---------------------------------------------------------------------------
    if !pictureTITLE.empty?
      pictureTITLE.last[0].setSE(delay, "Z-Move Title")
      pictureTITLE.each do |p, s|
        p.setVisible(delay, true)
        p.moveOpacity(delay, 4, 255)
        p.moveZoom(delay, 4, 100)
      end
      delay = pictureTITLE.last[0].totalDuration
      16.times do |i|
        pictureTITLE.each { |p, s| p.moveXY(delay, t, @pictureSprites[s].x + 8, @pictureSprites[s].y) }
        pictureTITLE.each { |p, s| p.moveXY(delay + t, t, @pictureSprites[s].x - 8, @pictureSprites[s].y) }
        delay = pictureTITLE.last[0].totalDuration
      end
      pictureTITLE.each do |p, s|
        p.setXY(delay, @pictureSprites[s].x + 8, @pictureSprites[s].y)
        p.setTone(delay, Tone.new(0, 0, 0, 0))
      end
      delay = pictureTITLE.last[0].totalDuration
    end
    pictureFADE.moveOpacity(delay + 20, 8, 255)
  end
end

#===============================================================================
# Calls the animation.
#===============================================================================
class Battle::Scene
  def pbShowZMove(idxBattler, move_id, battle)
    zmoveAnim = Animation::BattlerZMove.new(@sprites, @viewport, idxBattler, move_id, battle)
    loop do
	  if Input.press?(Input::ACTION)
	    pbPlayCancelSE
	    break 
	  end
      zmoveAnim.update
      pbUpdate
      break if zmoveAnim.animDone?
    end
    zmoveAnim.dispose
  end
end
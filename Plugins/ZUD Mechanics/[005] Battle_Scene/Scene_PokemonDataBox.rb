#===============================================================================
# Additions to Battle::Scene::PokemonDataBox.
#===============================================================================
class Battle::Scene::PokemonDataBox < SpriteWrapper
  #-----------------------------------------------------------------------------
  # Edited for including bitmaps for raid graphics.
  #-----------------------------------------------------------------------------
  def initializeOtherGraphics(viewport)
    path = "Graphics/Plugins/ZUD/Battle/"
    @raidNumbersBitmap = AnimatedBitmap.new(path + "raid_num")
    @raidBarBitmap     = AnimatedBitmap.new(path + "raid_bar")
    @shieldHPBitmap    = AnimatedBitmap.new(path + "raid_shield")
    if @battler.effects[PBEffects::MaxRaidBoss] 
      @hpBarBitmap = AnimatedBitmap.new(path + "overlay_hp")
    else
      @hpBarBitmap = AnimatedBitmap.new("Graphics/Pictures/Battle/overlay_hp")
    end
    @numbersBitmap = AnimatedBitmap.new("Graphics/Pictures/Battle/icon_numbers")
    @expBarBitmap  = AnimatedBitmap.new("Graphics/Pictures/Battle/overlay_exp")
    @hpNumbers = BitmapSprite.new(124, 16, viewport)
    @sprites["hpNumbers"] = @hpNumbers
    @hpBar = Sprite.new(viewport)
    @hpBar.bitmap = @hpBarBitmap.bitmap
    @hpBar.src_rect.height = @hpBarBitmap.height / 3
    @sprites["hpBar"] = @hpBar
    @expBar = Sprite.new(viewport)
    @expBar.bitmap = @expBarBitmap.bitmap
    @sprites["expBar"] = @expBar
    @contents = BitmapWrapper.new(@databoxBitmap.width, @databoxBitmap.height)
    self.bitmap  = @contents
    self.visible = false
    self.z       = 150 + ((@battler.index / 2) * 5)
    pbSetSystemFont(self.bitmap)
  end
  
  alias zud_dispose dispose
  def dispose
    @raidBarBitmap.dispose
    @shieldHPBitmap.dispose
    @raidNumbersBitmap.dispose
    zud_dispose
  end
  
  #-----------------------------------------------------------------------------
  # Edited so Max Raid Pokemon names are outlined in red.
  #-----------------------------------------------------------------------------
  def draw_name
    if @battler.effects[PBEffects::MaxRaidBoss]
      name_base   = Color.new(248, 248, 248)
      name_shadow = Color.new(248, 32, 32)
      pbDrawTextPositions(self.bitmap,
        [[@battler.name, 26, 6, false, name_base, name_shadow]]
      )
    else
      nameWidth = self.bitmap.text_size(@battler.name).width
      nameOffset = 0
      nameOffset = nameWidth - 116 if nameWidth > 116
      name_base   = NAME_BASE_COLOR
      name_shadow = NAME_SHADOW_COLOR
      pbDrawTextPositions(self.bitmap,
        [[@battler.name, @spriteBaseX + 8 - nameOffset, 12, false, name_base, name_shadow]]
      )
    end
  end
  
  #-----------------------------------------------------------------------------
  # Edited for status icon coordinates on Max Raid Pokemon databoxes.
  #-----------------------------------------------------------------------------
  def draw_status
    return if @battler.status == :NONE
    if @battler.status == :POISON && @battler.statusCount > 0
      s = GameData::Status.count - 1
    else
      s = GameData::Status.get(@battler.status).icon_position
    end
    return if s < 0
    if @battler.effects[PBEffects::MaxRaidBoss]
      xpos, ypos = 155, 12
    else
      xpos, ypos = @spriteBaseX + 24, 36
    end
    pbDrawImagePositions(self.bitmap, [["Graphics/Pictures/Battle/icon_statuses", xpos, ypos,
                                        0, s * STATUS_ICON_HEIGHT, -1, STATUS_ICON_HEIGHT]])
  end
  
  #-----------------------------------------------------------------------------
  # Edited to use shiny and owned icons for Max Raid Pokemon.
  #-----------------------------------------------------------------------------
  def draw_shiny_icon
    return if !@battler.shiny?
    if @battler.effects[PBEffects::MaxRaidBoss]
      pbDrawImagePositions(self.bitmap, [["Graphics/Plugins/ZUD/Battle/shiny", 0, 30]])
    else
      shiny_x = (@battler.opposes?(0)) ? 206 : -6
      pbDrawImagePositions(self.bitmap, [["Graphics/Pictures/shiny", @spriteBaseX + shiny_x, 36]])
    end
  end
  
  def draw_owned_icon
    return if !@battler.owned? || !@battler.opposes?(0)
    if @battler.effects[PBEffects::MaxRaidBoss]
      pbDrawImagePositions(self.bitmap, [["Graphics/Plugins/ZUD/Battle/icon_own", 8, 12]])
    else
      pbDrawImagePositions(self.bitmap, [["Graphics/Pictures/Battle/icon_own", @spriteBaseX + 8, 36]])
    end
  end
  
  #-----------------------------------------------------------------------------
  # Edited to allow Ultra Burst and Dynamax icons to display.
  #----------------------------------------------------------------------------- 
  def draw_special_form_icon
    return if @battler.effects[PBEffects::MaxRaidBoss]
    specialX = (@battler.opposes?(0)) ? 208 : -28
    if @battler.mega?
      pbDrawImagePositions(self.bitmap, [["Graphics/Pictures/Battle/icon_mega", @spriteBaseX + 8, 34]])
    elsif @battler.primal?
      filename = nil
      if @battler.isSpecies?(:GROUDON)
        filename = "Graphics/Pictures/Battle/icon_primal_Groudon"
      elsif @battler.isSpecies?(:KYOGRE)
        filename = "Graphics/Pictures/Battle/icon_primal_Kyogre"
      end
      pbDrawImagePositions(self.bitmap, [[filename, @spriteBaseX + specialX, 4]]) if filename
    elsif @battler.ultra?
      pbDrawImagePositions(self.bitmap, [["Graphics/Plugins/ZUD/Battle/icon_ultra", @spriteBaseX + specialX, 4]])
    elsif @battler.dynamax?
      pbDrawImagePositions(self.bitmap, [["Graphics/Plugins/ZUD/Battle/icon_dynamax", @spriteBaseX + specialX, 4]])
    end
  end
  
  #-----------------------------------------------------------------------------
  # Draws the turn count and KO count numbers on a raid databox.
  #-----------------------------------------------------------------------------
  def raid_DrawNumbers(counter, number, btmp, startX, startY)
    color = 0
    case counter
    when 0
      color = 1 if number <= Settings::MAXRAID_TIMER / 2
      color = 2 if number <= Settings::MAXRAID_TIMER / 4
      color = 3 if number <= Settings::MAXRAID_TIMER / 8
    when 1
      color = 1 if number <= Settings::MAXRAID_KOS / 2
      color = 2 if number <= Settings::MAXRAID_KOS / 4
      color = 3 if number <= 1
    end
    n = (number == -1) ? 10 : number.to_i.digits.reverse
    charWidth  = @raidNumbersBitmap.width / 11
    charHeight = @raidNumbersBitmap.height / 4
    startX -= charWidth * n.length
    n.each do |i|
      numberRect = Rect.new(i * charWidth, color * 14, charWidth, charHeight)
      btmp.blt(startX, startY, @raidNumbersBitmap.bitmap, numberRect)
      startX += charWidth
    end
  end
  
  #-----------------------------------------------------------------------------
  # Draws the Timer and KO counters on a Max Raid databox.
  #-----------------------------------------------------------------------------
  def draw_raid_counters
    turncount = @battler.effects[PBEffects::Dynamax]
    kocount   = @battler.effects[PBEffects::KnockOutCount]
    kocount   = 0 if kocount < 0
    raid_DrawNumbers(0, turncount, self.bitmap, 231, 14)
    raid_DrawNumbers(1, kocount, self.bitmap, 260, 14)
  end
  
  #-----------------------------------------------------------------------------
  # Draws raid shields on a Max Raid databox.
  #-----------------------------------------------------------------------------
  def draw_raid_shield
    shieldHP = @battler.effects[PBEffects::RaidShield]
    if shieldHP > 0
	  shieldLvl = @battler.effects[PBEffects::MaxShieldHP]
	  offset = (137 - (2 + shieldLvl * 26 / 2))
      self.bitmap.blt(offset, 46, @raidBarBitmap.bitmap, Rect.new(0, 0, 2 + shieldLvl * 26, 12))
	  self.bitmap.blt(offset, 46, @shieldHPBitmap.bitmap, Rect.new(0, 0, 2 + shieldHP * 26, 12))
    end
  end
  
  #-----------------------------------------------------------------------------
  # Edited to include Max Raid displays.
  #-----------------------------------------------------------------------------
  def refresh
    self.bitmap.clear
    return if !@battler.pokemon
    draw_background
    draw_name
    if @battler.effects[PBEffects::MaxRaidBoss]
      draw_raid_shield
      draw_raid_counters
    else
      draw_level
      draw_gender
    end
    draw_status
    draw_shiny_icon
    draw_special_form_icon
    draw_owned_icon
    refreshHP
    refreshExp
  end
end
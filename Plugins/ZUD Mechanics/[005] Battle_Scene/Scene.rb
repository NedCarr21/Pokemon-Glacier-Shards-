#===============================================================================
# Additions to Battle::Scene to allow for Dynamax sprites.
#===============================================================================
class Battle::Scene
  def pbAnimationCore(animation, user, target, oppMove = false)
    return if !animation
    @briefMessage = false
    userSprite   = (user) ? @sprites["pokemon_#{user.index}"] : nil
    targetSprite = (target) ? @sprites["pokemon_#{target.index}"] : nil
    oldUserX = (userSprite) ? userSprite.x : 0
    oldUserY = (userSprite) ? userSprite.y : 0
    oldTargetX = (targetSprite) ? targetSprite.x : oldUserX
    oldTargetY = (targetSprite) ? targetSprite.y : oldUserY
    #---------------------------------------------------------------------------
    # Used for Enlarged Dynamax sprites.
    #---------------------------------------------------------------------------
    if Settings::SHOW_DYNAMAX_SIZE
      oldUserZoomX   = (userSprite)   ? userSprite.zoom_x   : 1
      oldUserZoomY   = (userSprite)   ? userSprite.zoom_y   : 1
      oldTargetZoomX = (targetSprite) ? targetSprite.zoom_x : 1
      oldTargetZoomY = (targetSprite) ? targetSprite.zoom_y : 1
    end
    if Settings::SHOW_DYNAMAX_COLOR
      newcolor  = Settings::DYNAMAX_COLOR
      newcolor2 = Settings::CALYREX_COLOR
      oldcolor  = Color.new(0,0,0,0)
      # Colors user's sprite.
      if userSprite && user.dynamax?
        oldUserColor = user.isSpecies?(:CALYREX) ? newcolor2 : newcolor
      else
        oldUserColor = oldcolor
      end
      # Colors target's sprite.
      if targetSprite && target.dynamax?
        oldTargetColor = target.isSpecies?(:CALYREX) ? newcolor2 : newcolor
      else
        oldTargetColor = oldcolor
      end
    end
    #---------------------------------------------------------------------------
    animPlayer = PBAnimationPlayerX.new(animation,user,target,self,oppMove)
    userHeight = (userSprite && userSprite.bitmap && !userSprite.bitmap.disposed?) ? userSprite.bitmap.height : 128
    if targetSprite
      targetHeight = (targetSprite.bitmap && !targetSprite.bitmap.disposed?) ? targetSprite.bitmap.height : 128
    else
      targetHeight = userHeight
    end
    animPlayer.setLineTransform(
      FOCUSUSER_X, FOCUSUSER_Y, FOCUSTARGET_X, FOCUSTARGET_Y,
      oldUserX, oldUserY - (userHeight / 2), oldTargetX, oldTargetY - (targetHeight / 2)
    )
    animPlayer.start
    loop do
      animPlayer.update
      #-------------------------------------------------------------------------
      # Used for Enlarged Dynamax sprites.
      #-------------------------------------------------------------------------
      if Settings::SHOW_DYNAMAX_SIZE
        userSprite.zoom_x   = oldUserZoomX   if userSprite
        userSprite.zoom_y   = oldUserZoomY   if userSprite
        targetSprite.zoom_x = oldTargetZoomX if targetSprite
        targetSprite.zoom_y = oldTargetZoomY if targetSprite
      end
      if Settings::SHOW_DYNAMAX_COLOR
        userSprite.color   = oldUserColor    if userSprite
        targetSprite.color = oldTargetColor  if targetSprite
      end
      #-------------------------------------------------------------------------
      pbUpdate
      break if animPlayer.animDone?
    end
    animPlayer.dispose
    if userSprite
      userSprite.x = oldUserX
      userSprite.y = oldUserY
      userSprite.pbSetOrigin
    end
    if targetSprite
      targetSprite.x = oldTargetX
      targetSprite.y = oldTargetY
      targetSprite.pbSetOrigin
    end
  end

#-------------------------------------------------------------------------------
# Changes a battler's sprite. Recalculates if Dynamax effects should apply.
#-------------------------------------------------------------------------------
  def pbChangePokemon(idxBattler, pkmn)
    idxBattler   = idxBattler.index if idxBattler.respond_to?("index")
    battler      = @battle.battlers[idxBattler]
    pkmnSprite   = @sprites["pokemon_#{idxBattler}"]
    shadowSprite = @sprites["shadow_#{idxBattler}"]
    back         = !@battle.opposes?(idxBattler)
    if !battler.is_a?(Battle::FakeBattler)
	  if battler.effects[PBEffects::Transform]
        pkmn = battler.effects[PBEffects::TransformPokemon]
	  elsif battler.effects[PBEffects::Illusion]
	    pkmn = battler.effects[PBEffects::Illusion]
	  end
    end
    pkmnSprite.setPokemonBitmap(pkmn, back, battler)
    shadowSprite.setPokemonBitmap(pkmn)
    shadowSprite.visible = pkmn.species_data.shows_shadow? if shadowSprite && !back
    pkmnSprite.unDynamax if !battler.dynamax? && !pbInSafari?
  end
  
#-------------------------------------------------------------------------------
# Small fix to allow going back to previous command selection.
#-------------------------------------------------------------------------------  
  def pbCommandMenuEx(idxBattler, texts, mode = 0)
    pbShowWindow(COMMAND_BOX)
    cw = @sprites["commandWindow"]
    cw.setTexts(texts)
    cw.setIndexAndMode(@lastCmd[idxBattler], mode)
    pbSelectBattler(idxBattler)
    ret = -1
    loop do
      oldIndex = cw.index
      pbUpdate(cw)
      if Input.trigger?(Input::LEFT)
        cw.index -= 1 if (cw.index & 1) == 1
      elsif Input.trigger?(Input::RIGHT)
        cw.index += 1 if (cw.index & 1) == 0
      elsif Input.trigger?(Input::UP)
        cw.index -= 2 if (cw.index & 2) == 2
      elsif Input.trigger?(Input::DOWN)
        cw.index += 2 if (cw.index & 2) == 0
      end
      pbPlayCursorSE if cw.index != oldIndex
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        ret = cw.index
        @lastCmd[idxBattler] = ret
        break
      elsif Input.trigger?(Input::BACK) && mode > 0
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::F9) && $DEBUG
        pbPlayDecisionSE
        ret = -2
        break
      end
    end
    return ret
  end
end
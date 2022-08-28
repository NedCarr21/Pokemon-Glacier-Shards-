#===============================================================================
# Adds battle animations used for deluxe battle trainer dialogue.
#===============================================================================


#-------------------------------------------------------------------------------
# Animation used to toggle visibility of data boxes.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::ToggleDataBox < Battle::Scene::Animation
  def initialize(sprites, viewport, idxBattler)
    @idxBattler = idxBattler
    super(sprites, viewport)
  end

  def createProcesses
    delay = 0
    toggle = !@sprites["dataBox_#{@idxBattler}"].visible
    box = addSprite(@sprites["dataBox_#{@idxBattler}"])
    box.setVisible(delay, toggle)
  end
end


#-------------------------------------------------------------------------------
# Animation used to slide a trainer off screen.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::TrainerDisappear < Battle::Scene::Animation
  def initialize(sprites, viewport, idxTrainer)
    @idxTrainer = idxTrainer + 1
    super(sprites, viewport)
  end

  def createProcesses
    delay = 0
    if @sprites["trainer_#{@idxTrainer}"].visible
      trainer = addSprite(@sprites["trainer_#{@idxTrainer}"], PictureOrigin::BOTTOM)
      trainer.moveDelta(delay, 8, Graphics.width / 4, 0)
      trainer.setVisible(delay + 8, false)
    end
  end
end


#-------------------------------------------------------------------------------
# Plays animations.
#-------------------------------------------------------------------------------
class Battle::Scene
  def pbHideOpponent(idxTrainer)
    hideAnim = Animation::TrainerDisappear.new(@sprites, @viewport, idxTrainer)
    @animations.push(hideAnim)
    while inPartyAnimation?
      pbUpdate
    end
  end
  
  def pbToggleDataboxes
    @battle.allBattlers.each do |b|
      next if !b
      dataBoxAnim = Animation::ToggleDataBox.new(@sprites, @viewport, b.index)
      loop do
        dataBoxAnim.update
        pbUpdate
        break if dataBoxAnim.animDone?
      end
      dataBoxAnim.dispose
    end
  end
  
  def pbFlashRefresh
    tone = 0
    toneDiff = 20 * 20 / Graphics.frame_rate
    loop do
      Graphics.update
      pbUpdate
      tone += toneDiff
      @viewport.tone.set(tone, tone, tone, 0)
      break if tone >= 255
    end
    pbRefreshEverything
    (Graphics.frame_rate / 4).times do
      Graphics.update
      pbUpdate
    end
    tone = 255
    toneDiff = 40 * 20 / Graphics.frame_rate
    loop do
      Graphics.update
      pbUpdate
      tone -= toneDiff
      @viewport.tone.set(tone, tone, tone, 0)
      break if tone <= 0
    end
  end
end
ItemHandlers::UseFromBag.add(:QUESTLOG, proc { |item|
  pbFadeOutIn {
        scene = QuestList_Scene.new
        screen = QuestList_Screen.new(scene)
        screen.pbStartScreen
        menu.pbRefresh
      }
  next 1
})

MenuHandlers.add(:options_menu, :hud_toggle, {
  "name"        => _INTL("Toggle HUD"),
  "order"       => 1000,
  "type"        => EnumOption,
  "parameters"  => [_INTL("On"), _INTL("Off")],
  "description" => _INTL("Choose whether you wish to see the HUD at the top of the screen."),
  "get_proc"    => proc { next $game_switches[62] },
  "set_proc"    => proc { |value, _scene| $game_switches[62] = value }
})

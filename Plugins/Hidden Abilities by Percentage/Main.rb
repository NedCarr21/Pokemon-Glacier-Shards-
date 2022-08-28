#===============================================================================
# Wild & Gift Pokémon Having Their Hidden Ability Based On Percentage
#===============================================================================
# Have you ever wanted to make wild Pokémon have their Hidden Ability,
# but not by event, or adding it in the PBS alongside their normal abilities?
# To have a chance of finding the ability naturally? Well, now you can!
#===============================================================================
# To modify the percentage, increase the number below.
# It's currently set to 1/20, which is 5%.
# Example: If you wanted to make it 50%, you'd change it to < 10.
#===============================================================================

module WildHiddenAbilityPercentage #Hi, I change Wild Encounter Abilities
  Chance = rand(15) < 1
end

module GiftHiddenAbilityPercentage #Hi, I change Gift Abilities
  Chance = rand(15) < 1
end

#===============================================================================
# Code Stuffs
# No need to touch these
#===============================================================================

# Make all wild Pokémon have a chance to have their hidden ability.
EventHandlers.add(:on_wild_pokemon_created, :give_hidden_ability,
proc { |pkmn|
	pkmn.ability_index = 2 if WildHiddenAbilityPercentage::Chance
}
)

# Modifying Gift Pokémon/Eggs, but not foreign Pokémon.
#===============================================================================
# Giving Pokémon to the player (will send to storage if party is full)
#===============================================================================
def pbAddPokemon(pkmn, level = 1, see_form = true)
    return false if !pkmn
    if pbBoxesFull?
      pbMessage(_INTL("There's no more room for Pokémon!\1"))
      pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
      return false
    end
    pkmn = Pokemon.new(pkmn, level) if !pkmn.is_a?(Pokemon)
    if GiftHiddenAbilityPercentage::Chance #Hidden Ability Modifier
        pkmn.ability_index = 2
    end
    species_name = pkmn.speciesName
    pbMessage(_INTL("{1} obtained {2}!\\me[Pkmn get]\\wtnp[80]\1", $player.name, species_name))
    was_owned = $player.owned?(pkmn.species)
    $player.pokedex.set_seen(pkmn.species)
    $player.pokedex.set_owned(pkmn.species)
    $player.pokedex.register(pkmn) if see_form
    # Show Pokédex entry for new species if it hasn't been owned before
    if Settings::SHOW_NEW_SPECIES_POKEDEX_ENTRY_MORE_OFTEN && see_form && !was_owned && $player.has_pokedex
      pbMessage(_INTL("{1}'s data was added to the Pokédex.", species_name))
      $player.pokedex.register_last_seen(pkmn)
      pbFadeOutIn {
        scene = PokemonPokedexInfo_Scene.new
        screen = PokemonPokedexInfoScreen.new(scene)
        screen.pbDexEntry(pkmn.species)
      }
    end
    # Nickname and add the Pokémon
    pbNicknameAndStore(pkmn)
    return true
end

def pbAddPokemonSilent(pkmn, level = 1, see_form = true)
  return false if !pkmn || pbBoxesFull?
  pkmn = Pokemon.new(pkmn, level) if !pkmn.is_a?(Pokemon)
    if GiftHiddenAbilityPercentage::Chance #Hidden Ability Modifier
        pkmn.ability_index = 2
    end
  $player.pokedex.set_seen(pkmn.species)
  $player.pokedex.set_owned(pkmn.species)
  $player.pokedex.register(pkmn) if see_form
  pkmn.record_first_moves
  if $player.party_full?
    $PokemonStorage.pbStoreCaught(pkmn)
  else
    $player.party[$player.party.length] = pkmn
  end
  return true
end

#===============================================================================
# Giving Pokémon/eggs to the player (can only add to party)
#===============================================================================
def pbAddToParty(pkmn, level = 1, see_form = true)
  return false if !pkmn || $player.party_full?
  pkmn = Pokemon.new(pkmn, level) if !pkmn.is_a?(Pokemon)
    if GiftHiddenAbilityPercentage::Chance #Hidden Ability Modifier
        pkmn.ability_index = 2
    end
  species_name = pkmn.speciesName
  pbMessage(_INTL("{1} obtained {2}!\\me[Pkmn get]\\wtnp[80]\1", $player.name, species_name))
  was_owned = $player.owned?(pkmn.species)
  $player.pokedex.set_seen(pkmn.species)
  $player.pokedex.set_owned(pkmn.species)
  $player.pokedex.register(pkmn) if see_form
  # Show Pokédex entry for new species if it hasn't been owned before
  if Settings::SHOW_NEW_SPECIES_POKEDEX_ENTRY_MORE_OFTEN && see_form && !was_owned && $player.has_pokedex
    pbMessage(_INTL("{1}'s data was added to the Pokédex.", species_name))
    $player.pokedex.register_last_seen(pkmn)
    pbFadeOutIn {
      scene = PokemonPokedexInfo_Scene.new
      screen = PokemonPokedexInfoScreen.new(scene)
      screen.pbDexEntry(pkmn.species)
    }
  end
  # Nickname and add the Pokémon
  pbNicknameAndStore(pkmn)
  return true
end

def pbAddToPartySilent(pkmn, level = nil, see_form = true)
  return false if !pkmn || $player.party_full?
  pkmn = Pokemon.new(pkmn, level) if !pkmn.is_a?(Pokemon)
    if GiftHiddenAbilityPercentage::Chance #Hidden Ability Modifier
        pkmn.ability_index = 2
    end
  $player.pokedex.register(pkmn) if see_form
  $player.pokedex.set_owned(pkmn.species)
  pkmn.record_first_moves
  $player.party[$player.party.length] = pkmn
  return true
end

def pbGenerateEgg(pkmn, text = "")
  return false if !pkmn || $player.party_full?
  pkmn = Pokemon.new(pkmn, Settings::EGG_LEVEL) if !pkmn.is_a?(Pokemon)
    if GiftHiddenAbilityPercentage::Chance #Hidden Ability Modifier
        pkmn.ability_index = 2
    end
  # Set egg's details
  pkmn.name           = _INTL("Egg")
  pkmn.steps_to_hatch = pkmn.species_data.hatch_steps
  pkmn.obtain_text    = text
  pkmn.calc_stats
  # Add egg to party
  $player.party[$player.party.length] = pkmn
  return true
end
alias pbAddEgg pbGenerateEgg
alias pbGenEgg pbGenerateEgg
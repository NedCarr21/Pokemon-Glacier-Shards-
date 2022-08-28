#===============================================================================
# Revamps base Essentials battle code related to PBS Compiling to allow for
# plugin compatibility.
#===============================================================================


#-------------------------------------------------------------------------------
# Allows certain data to be rewritten by plugin compilers.
#-------------------------------------------------------------------------------
module GameData
  class Move
    attr_accessor :function_code
  end
  
  class Species
    attr_accessor :gender_ratio
    attr_accessor :egg_groups
    attr_accessor :egg_moves
    attr_accessor :offspring
    attr_accessor :habitat
    attr_accessor :flags
  end
end


#-------------------------------------------------------------------------------
# Compiler.
#-------------------------------------------------------------------------------
module Compiler
  module_function
  
  PLUGIN_FILES = []
  
  #-----------------------------------------------------------------------------
  # Writing data
  #-----------------------------------------------------------------------------
  alias plugin_write_all write_all
  def write_all
    plugin_write_all
    if !PLUGIN_FILES.empty?
      Console.echo_h1 _INTL("Writing all PBS/Plugin files")
      if PluginManager.installed?("ZUD Mechanics")
        write_dynamax_metrics
        write_power_moves
        write_raid_ranks
        write_lair_maps
      end
      if PluginManager.installed?("Pokémon Birthsigns")
        write_birthsigns
      end
      echoln ""
      Console.echo_h2("Successfully compiled all additional PBS/Plugin files", text: :green)
    end
  end
  
  def write_trainers(path = "PBS/trainers.txt")
    write_pbs_file_message_start(path)
    File.open(path, "wb") { |f|
      idx = 0
      add_PBS_header_to_file(f)
      GameData::Trainer.each do |trainer|
        echo "." if idx % 50 == 0
        idx += 1
        Graphics.update if idx % 250 == 0
        f.write("\#-------------------------------\r\n")
        if trainer.version > 0
          f.write(sprintf("[%s,%s,%d]\r\n", trainer.trainer_type, trainer.real_name, trainer.version))
        else
          f.write(sprintf("[%s,%s]\r\n", trainer.trainer_type, trainer.real_name))
        end
        f.write(sprintf("Items = %s\r\n", trainer.items.join(","))) if trainer.items.length > 0
        if trainer.real_lose_text && !trainer.real_lose_text.empty?
          f.write(sprintf("LoseText = %s\r\n", trainer.real_lose_text))
        end
        trainer.pokemon.each do |pkmn|
          f.write(sprintf("Pokemon = %s,%d\r\n", pkmn[:species], pkmn[:level]))
          f.write(sprintf("    Name = %s\r\n", pkmn[:name])) if pkmn[:name] && !pkmn[:name].empty?
          f.write(sprintf("    Form = %d\r\n", pkmn[:form])) if pkmn[:form] && pkmn[:form] > 0
          f.write(sprintf("    Gender = %s\r\n", (pkmn[:gender] == 1) ? "female" : "male")) if pkmn[:gender]
          f.write("    Shiny = yes\r\n") if pkmn[:shininess] && !pkmn[:super_shininess]
          f.write("    SuperShiny = yes\r\n") if pkmn[:super_shininess]
          f.write("    Shadow = yes\r\n") if pkmn[:shadowness]
          f.write(sprintf("    Moves = %s\r\n", pkmn[:moves].join(","))) if pkmn[:moves] && pkmn[:moves].length > 0
          f.write(sprintf("    Ability = %s\r\n", pkmn[:ability])) if pkmn[:ability]
          f.write(sprintf("    AbilityIndex = %d\r\n", pkmn[:ability_index])) if pkmn[:ability_index]
          f.write(sprintf("    Item = %s\r\n", pkmn[:item])) if pkmn[:item]
          f.write(sprintf("    Nature = %s\r\n", pkmn[:nature])) if pkmn[:nature]
          ivs_array = []
          evs_array = []
          GameData::Stat.each_main do |s|
            next if s.pbs_order < 0
            ivs_array[s.pbs_order] = pkmn[:iv][s.id] if pkmn[:iv]
            evs_array[s.pbs_order] = pkmn[:ev][s.id] if pkmn[:ev]
          end
          f.write(sprintf("    IV = %s\r\n", ivs_array.join(","))) if pkmn[:iv]
          f.write(sprintf("    EV = %s\r\n", evs_array.join(","))) if pkmn[:ev]
          f.write(sprintf("    Happiness = %d\r\n", pkmn[:happiness])) if pkmn[:happiness]
          f.write(sprintf("    Ball = %s\r\n", pkmn[:poke_ball])) if pkmn[:poke_ball]
          f.write("    Ace = yes\r\n") if pkmn[:trainer_ace]
          f.write(sprintf("    Focus = %s\r\n", pkmn[:focus])) if PluginManager.installed?("Focus Meter System") && pkmn[:focus]
          f.write(sprintf("    Birthsign = %s\r\n", pkmn[:birthsign])) if PluginManager.installed?("Pokémon Birthsigns") && pkmn[:birthsign]
          f.write(sprintf("    DynamaxLvl = %d\r\n", pkmn[:dynamax_lvl])) if PluginManager.installed?("ZUD Mechanics") && pkmn[:dynamax_lvl]
          f.write("    Gigantamax = yes\r\n") if PluginManager.installed?("ZUD Mechanics") && pkmn[:gmaxfactor]
        end
      end
    }
    process_pbs_file_message_end
  end
  
  #-----------------------------------------------------------------------------
  # Compiles any additional items included by a plugin.
  #-----------------------------------------------------------------------------
  def compile_plugin_items
    compiled = false
    return if PLUGIN_FILES.empty?
    schema = GameData::Item::SCHEMA
    item_names        = []
    item_names_plural = []
    item_descriptions = []
    PLUGIN_FILES.each do |plugin|
      path = "PBS/Plugins/#{plugin}/items.txt"
      next if !safeExists?(path)
      compile_pbs_file_message_start(path)
      item_hash = nil
      idx = 0
      pbCompilerEachPreppedLine(path) { |line, line_no|
        echo "." if idx % 250 == 0
        idx += 1
        if line[/^\s*\[\s*(.+)\s*\]\s*$/]
          GameData::Item.register(item_hash) if item_hash
          item_id = $~[1].to_sym
          if GameData::Item.exists?(item_id)
            item_hash = nil
            next
          end
          item_hash = {
            :id => item_id
          }
        elsif line[/^\s*(\w+)\s*=\s*(.*)\s*$/] && !item_hash.nil?
          property_name = $~[1]
          line_schema = schema[property_name]
          next if !line_schema
          property_value = pbGetCsvRecord($~[2], line_no, line_schema)
          item_hash[line_schema[0]] = property_value
          case property_name
          when "Name"
            item_names.push(item_hash[:name])
          when "NamePlural"
            item_names_plural.push(item_hash[:name_plural])
          when "Description"
            item_descriptions.push(item_hash[:description])
          end
        end
      }
      if item_hash
        GameData::Item.register(item_hash)
        compiled = true
      end
      process_pbs_file_message_end
      begin
        File.delete(path)
        rescue SystemCallError
      end
    end
    if compiled
      GameData::Item.save
      Compiler.write_items
      MessageTypes.setMessagesAsHash(MessageTypes::Items, item_names)
      MessageTypes.setMessagesAsHash(MessageTypes::ItemPlurals, item_names_plural)
      MessageTypes.setMessagesAsHash(MessageTypes::ItemDescriptions, item_descriptions)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Compiles any additional moves included by a plugin.
  #-----------------------------------------------------------------------------
  def compile_plugin_moves
    compiled = false
    return if PLUGIN_FILES.empty?
    schema = GameData::Move::SCHEMA
    move_names        = []
    move_descriptions = []
    PLUGIN_FILES.each do |plugin|
      path = "PBS/Plugins/#{plugin}/moves.txt"
      next if !safeExists?(path)
      compile_pbs_file_message_start(path)
      move_hash = nil
      idx = 0
      pbCompilerEachPreppedLine(path) { |line, line_no|
        echo "." if idx % 500 == 0
        idx += 1
        if line[/^\s*\[\s*(.+)\s*\]\s*$/]
          if move_hash
            if (move_hash[:category] || 2) == 2 && (move_hash[:base_damage] || 0) != 0
              raise _INTL("Move {1} is defined as a Status move with a non-zero base damage.\r\n{2}", line[2], FileLineData.linereport)
            elsif (move_hash[:category] || 2) != 2 && (move_hash[:base_damage] || 0) == 0
              print _INTL("Warning: Move {1} was defined as Physical or Special but had a base damage of 0. Changing it to a Status move.\r\n{2}", line[2], FileLineData.linereport)
              move_hash[:category] = 2
            end
            GameData::Move.register(move_hash)
          end
          move_id = $~[1].to_sym
          if GameData::Move.exists?(move_id)
            move_hash = nil
            next
          end
          move_hash = {
            :id => move_id
          }
        elsif line[/^\s*(\w+)\s*=\s*(.*)\s*$/] && !move_hash.nil?
          property_name = $~[1]
          line_schema = schema[property_name]
          next if !line_schema
          property_value = pbGetCsvRecord($~[2], line_no, line_schema)
          move_hash[line_schema[0]] = property_value
          case property_name
          when "Name"
            move_names.push(move_hash[:name])
          when "Description"
            move_descriptions.push(move_hash[:description])
          end
        end
      }
      if move_hash
        if (move_hash[:category] || 2) == 2 && (move_hash[:base_damage] || 0) != 0
          raise _INTL("Move {1} is defined as a Status move with a non-zero base damage.\r\n{2}", line[2], FileLineData.linereport)
        elsif (move_hash[:category] || 2) != 2 && (move_hash[:base_damage] || 0) == 0
          print _INTL("Warning: Move {1} was defined as Physical or Special but had a base damage of 0. Changing it to a Status move.\r\n{2}", line[2], FileLineData.linereport)
          move_hash[:category] = 2
        end
        GameData::Move.register(move_hash)
        compiled = true
      end
      process_pbs_file_message_end
      begin
        File.delete(path)
        rescue SystemCallError
      end
    end
    if compiled
      GameData::Move.save
      Compiler.write_moves
      MessageTypes.setMessagesAsHash(MessageTypes::Moves, move_names)
      MessageTypes.setMessagesAsHash(MessageTypes::MoveDescriptions, move_descriptions)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Compiles changes to species data altered by a plugin.
  #-----------------------------------------------------------------------------
  def compile_plugin_species_data
    compiled = false
    return if PLUGIN_FILES.empty?
    schema = {
      "GenderRatio" => [0, "e",  :GenderRatio],
      "EggMoves"    => [0, "*e", :Move],
      "EggGroups"   => [0, "*e", :EggGroup],
      "Offspring"   => [0, "*e", :Species],
      "Habitat"     => [0, "e",  :Habitat],
      "Flags"       => [0, "*s"]
    }
    PLUGIN_FILES.each do |plugin|
      path = "PBS/Plugins/#{plugin}/pokemon.txt"
      next if !safeExists?(path)
      compile_pbs_file_message_start(path)
      File.open(path, "rb") { |f|
        FileLineData.file = path
        idx = 0
        pbEachFileSectionEx(f) { |contents, species_id|
          FileLineData.setSection(species_id, "header", nil)
          id = species_id.to_sym
          next if !GameData::Species.try_get(id)
          species = GameData::Species::DATA[id]
          schema.keys.each do |key|
            if nil_or_empty?(contents[key])
              contents[key] = nil
              next
            end
            FileLineData.setSection(species_id, key, contents[key])
            value = pbGetCsvRecord(contents[key], key, schema[key])
            value = nil if value.is_a?(Array) && value.length == 0
            contents[key] = value
            case key
            when "GenderRatio"
              species.gender_ratio = contents[key]
            when "Habitat"
              species.habitat = contents[key]
            when "Flags"
              species.flags = contents[key]
            when "EggMoves", "EggGroups", "Offspring"      
              contents[key] = [contents[key]] if !contents[key].is_a?(Array)
              contents[key].compact!
              species.egg_moves  = contents[key] if key == "EggMoves"
              species.egg_groups = contents[key] if key == "EggGroups"
              species.offspring  = contents[key] if key == "Offspring"
            end
          end
          compiled = true
        }
      }
      process_pbs_file_message_end
      begin
        File.delete(path)
        rescue SystemCallError
      end
    end
    if compiled
      GameData::Species.save
      Compiler.write_pokemon
      Compiler.write_pokemon_forms
    end
  end
  
  #-----------------------------------------------------------------------------
  # Compiling all plugin data
  #-----------------------------------------------------------------------------
  def compile_all(mustCompile)
    PLUGIN_FILES.each do |plugin|
      for file in ["items", "moves", "pokemon"]
        path = "PBS/Plugins/#{plugin}/#{file}.txt"
        mustCompile = true if safeExists?(path)
      end
    end
    return if !mustCompile
    FileLineData.clear
    Console.echo_h1 _INTL("Starting full compile")
    compile_pbs_files
    if !PLUGIN_FILES.empty?
      echoln ""
      Console.echo_h1 _INTL("Compiling additional plugin data")
      compile_plugin_items
      compile_plugin_moves
      compile_plugin_species_data
      echoln ""
      if PluginManager.installed?("ZUD Mechanics")
        Console.echo_li "ZUD Mechanics"
        compile_lair_maps
        Console.echo_li "ZUD Mechanics"
        compile_raid_ranks       # Depends on Species
        Console.echo_li "ZUD Mechanics"
        compile_power_moves      # Depends on Move, Item, Type, Species
        Console.echo_li "ZUD Mechanics"
        compile_dynamax_metrics  # Depends on Species, Power Moves
      end
      if PluginManager.installed?("Pokémon Birthsigns")
        Console.echo_li "Pokémon Birthsigns"
        compile_birthsigns       # Depends on Type, Move, Ability, Species
      end
      echoln ""
      Console.echo_h2("Plugin data fully compiled", text: :green)
      echoln ""
    end
    compile_animations
    compile_trainer_events(mustCompile)
    Console.echo_li _INTL("Saving messages...")
    pbSetTextMessages
    MessageTypes.saveMessages
    MessageTypes.loadMessageFile("Data/messages.dat") if safeExists?("Data/messages.dat")
    Console.echo_done(true)
    Console.echo_li _INTL("Reloading cache...")
    System.reload_cache
    Console.echo_done(true)
    echoln ""
    Console.echo_h2("Successfully fully compiled", text: :green)
  end
  
  def main
    return if !$DEBUG
    begin
      dataFiles = [
        "abilities.dat",
        "berry_plants.dat",
        "encounters.dat",
        "items.dat",
        "map_connections.dat",
        "map_metadata.dat",
        "metadata.dat",
        "moves.dat",
        "phone.dat",
        "player_metadata.dat",
        "regional_dexes.dat",
        "ribbons.dat",
        "shadow_pokemon.dat",
        "species.dat",
        "species_metrics.dat",
        "town_map.dat",
        "trainer_lists.dat",
        "trainer_types.dat",
        "trainers.dat",
        "types.dat"
      ]
      textFiles = [
        "abilities.txt",
        "battle_facility_lists.txt",
        "berry_plants.txt",
        "encounters.txt",
        "items.txt",
        "map_connections.txt",
        "map_metadata.txt",
        "metadata.txt",
        "moves.txt",
        "phone.txt",
        "pokemon.txt",
        "pokemon_forms.txt",
        "pokemon_metrics.txt",
        "regional_dexes.txt",
        "ribbons.txt",
        "shadow_pokemon.txt",
        "town_map.txt",
        "trainer_types.txt",
        "trainers.txt",
        "types.txt"
      ]
      if PluginManager.installed?("ZUD Mechanics")
        dataFiles.push("power_moves.dat", "raid_ranks.dat", "adventure_maps.dat")
        textFiles.push("Plugins/ZUD/power_moves.txt", "Plugins/ZUD/raid_ranks.txt", "Plugins/ZUD/adventure_maps.txt")
      end
      if PluginManager.installed?("Pokémon Birthsigns")
        dataFiles.push("birthsigns.dat")
        textFiles.push("Plugins/Birthsigns/birthsigns.txt")
      end
      latestDataTime = 0
      latestTextTime = 0
      mustCompile = false
      mustCompile |= import_new_maps
      if !safeIsDirectory?("PBS")
        Dir.mkdir("PBS") rescue nil
        write_all
        mustCompile = true
      end
      dataFiles.each do |filename|
        if safeExists?("Data/" + filename)
          begin
            File.open("Data/#{filename}") { |file|
              latestDataTime = [latestDataTime, file.mtime.to_i].max
            }
          rescue SystemCallError
            mustCompile = true
          end
        else
          mustCompile = true
          break
        end
      end
      textFiles.each do |filename|
        next if !safeExists?("PBS/" + filename)
        begin
          File.open("PBS/#{filename}") { |file|
            latestTextTime = [latestTextTime, file.mtime.to_i].max
          }
        rescue SystemCallError
        end
      end
      mustCompile |= (latestTextTime >= latestDataTime)
      Input.update
      mustCompile = true if Input.press?(Input::CTRL)
      if mustCompile
        dataFiles.length.times do |i|
          begin
            File.delete("Data/#{dataFiles[i]}") if safeExists?("Data/#{dataFiles[i]}")
          rescue SystemCallError
          end
        end
      end
      compile_all(mustCompile)
      rescue Exception
      e = $!
      raise e if e.class.to_s == "Reset" || e.is_a?(Reset) || e.is_a?(SystemExit)
      pbPrintException(e)
      dataFiles.length.times do |i|
        begin
          File.delete("Data/#{dataFiles[i]}")
        rescue SystemCallError
        end
      end
      raise Reset.new if e.is_a?(Hangup)
      loop do
        Graphics.update
      end
    end
  end
end
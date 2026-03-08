#===============================================================================
# PC Shit
#===============================================================================

class PokemonStorageScreen
  def pbChoosePokemonForVault(eligibility_proc = nil, helptext = nil)
    $game_temp.in_storage = true
    @scene.pbStartBox(self, 0)
    chosen = nil

    loop do
      selected = @scene.pbSelectBox(@storage.party)

      if selected && selected[0] == -3
        break if pbConfirmMessage(_INTL("Exit the PC?"))
        next
      end

      break if selected.nil?

      box, slot = selected
      pkmn = @storage[box, slot]
      next if !pkmn

      if eligibility_proc && !eligibility_proc.call(pkmn)
        pbMessage(_INTL("That Pokémon can’t be stored in the Vault."))
        next
      end

      if box < 0
        pbMessage(_INTL("You can only select Pokémon from PC Boxes."))
        next
      end

      commands = [
        _INTL("Select"),
        _INTL("Summary"),
        _INTL("Cancel")
      ]

      command = pbShowCommands(helptext || _INTL("{1} is selected.", pkmn.name), commands)

      case command
      when 0
        chosen = [pkmn, box, slot]
        break
      when 1
        pbSummary(selected, nil)
      end
    end

    @scene.pbCloseBox
    $game_temp.in_storage = false
    return chosen
  end
end


#===============================================================================
# Pokémon Vault UI
#===============================================================================

module PokemonVault
  module_function

  def open_menu
    loop do
      choice = pbMessage(
        _INTL("Pokémon Vault"),
        [
          _INTL("Upload Pokémon"),
          _INTL("Upload Box"),
          _INTL("Download Pokémon"),
          _INTL("Download Box"),
          _INTL("Export Pokémon"),
          _INTL("Import External Pokémon"),
          _INTL("Quit")
        ]
      )

case choice
when 0
  PokemonVault.upload_single_pokemon
when 1
  PokemonVault.upload_entire_box
when 2
  PokemonVault.download_single_pokemon
when 3
  PokemonVault.download_entire_box
when 4
  export_pokemon
      when 5
        import_external_pokemon
      else
        break
      end
    end
  end

  #---------------------------------------------------------------------------
  # Upload From PC
  #---------------------------------------------------------------------------

def upload_entire_box
    box = pbMessage(
      _INTL("Which box do you want to upload?"),
      (1..Settings::NUM_STORAGE_BOXES).map { |i| _INTL("Box {1}", i) }
    )
    return if box < 0

    box_index = box
    uploaded  = 0
    skipped   = 0

    BOX_SIZE.times do |slot|
      pkmn = $PokemonStorage[box_index, slot]
      next if !storable_pokemon?(pkmn)

      if add_pokemon(pkmn)
        $PokemonStorage[box_index, slot] = nil
        uploaded += 1
      else
        skipped += 1
        break
      end
    end

    pbMessage(
      _INTL(
        "Uploaded {1} Pokémon.\nSkipped {2}.",
        uploaded,
        skipped
      )
    )

  Game.save if uploaded > 0
  pbMEPlay("GUI save game") if uploaded > 0
  end
end


  def choose_pokemon_from_pc(eligibility_proc = nil, helptext = nil)
    chosen = nil
    pbFadeOutIn do
      scene  = PokemonStorageScene.new
      screen = PokemonStorageScreen.new(scene, $PokemonStorage)
      chosen = screen.pbChoosePokemonForVault(eligibility_proc, helptext)
    end
    return chosen
  end

def upload_single_pokemon
  chosen = choose_pokemon_from_pc(
    proc { |pkmn| storable_pokemon?(pkmn) },
    _INTL("Choose a Pokémon to upload.")
  )

  return if !chosen

  pkmn, box, slot = chosen

  return if !pbConfirmMessage(
    _INTL("Upload {1} to the Pokémon Vault?", pkmn.name)
  )

  removed = remove_from_pc(box, slot)

  if add_pokemon(removed)
    pbMessage(_INTL("{1} was uploaded to the Vault.", removed.name))
    Game.save
    pbMEPlay("GUI save game")
  else
    pbMessage(_INTL("The Vault is full."))
    add_to_pc(removed)
  end
end

#===============================================================================
# Download Single Pokémon
#===============================================================================

def download_single_pokemon
  chosen = choose_pokemon_from_vault
  return if !chosen

  pkmn, box, slot = chosen

  return if !pbConfirmMessage(
    _INTL("Download {1} from the Pokémon Vault?", pkmn.name)
  )

  removed = remove_pokemon(box, slot)
  return if !removed

  if add_to_pc(removed)
    pbMessage(_INTL("{1} was downloaded to your PC.", removed.name))
    Game.save
    pbMEPlay("GUI save game")
  else
    pbMessage(_INTL("Your PC Boxes are full."))
    add_pokemon(removed)
  end
end


#===============================================================================
# Download Entire Box
#===============================================================================


  def download_entire_box
  vault = load_vault
  box_choices = []

  vault.each_with_index do |box, i|
    count = box.compact.length
    next if count == 0
    box_choices << [i, count]
  end

  if box_choices.empty?
    pbMessage(_INTL("The Pokémon Vault is empty."))
    return
  end

  commands = box_choices.map do |(b, count)|
    _INTL("Vault Box {1} ({2} Pokémon)", b + 1, count)
  end
  commands << _INTL("Cancel")

  choice = pbMessage(_INTL("Choose a Vault box to download."), commands)
  return if choice < 0 || choice >= box_choices.length

  box_index, _ = box_choices[choice]

  downloaded = 0
  skipped = 0

  vault[box_index].each_with_index do |pkmn, slot|
    next if !pkmn

    if add_to_pc(pkmn)
      vault[box_index][slot] = nil
      downloaded += 1
    else
      skipped += 1
      break
    end
  end

  save_vault(vault)

  pbMessage(
    _INTL("Downloaded {1} Pokémon.\nSkipped {2}.",
      downloaded,
      skipped
    )
  )

  Game.save if downloaded > 0
  pbMEPlay("GUI save game") if downloaded > 0
end


#===============================================================================
# Choose Pokémon From Vault
#===============================================================================

def choose_pokemon_from_vault
  vault = load_vault
  entries = []

  vault.each_with_index do |box, b|
    box.each_with_index do |pkmn, s|
      next if !pkmn
      entries << [pkmn, b, s]
    end
  end

  if entries.empty?
    pbMessage(_INTL("The Pokémon Vault is empty."))
    return nil
  end

  commands = entries.map.with_index do |(pkmn, b, s), i|
    _INTL("{1}. {2} (Box {3}, Slot {4})",
      i + 1,
      pkmn.name,
      b + 1,
      s + 1
    )
  end

  commands << _INTL("Cancel")

  choice = pbMessage(
    _INTL("Choose a Pokémon to download."),
    commands
  )

  return nil if choice < 0 || choice >= entries.length

  return entries[choice]
end


#===============================================================================
# Export Pokémon
#===============================================================================

def export_pokemon
  vault_snapshot = load_vault

  has_pokemon = vault_snapshot.any? { |box| box.any? { |pkmn| pkmn } }

  if !has_pokemon
    pbMessage(_INTL("No hay Pokémon para exportar."))
    return
  end

  pbMessage(_INTL(
    "ATENCIÓN\n\nAl exportar tus Pokémon, se guardarán en un archivo llamado transfer.dat dentro de la carpeta Pokemon Vault.\n\nPara transferirlos a otro juego, debes copiar ese archivo a la carpeta Pokemon Vault del juego destino."
  ))

  return if !pbConfirmMessage(_INTL("¿Quieres exportar los Pokémon almacenados en el Vault?"))

  if PokemonVault.export_transfer
    Game.save
    pbMEPlay("GUI save game")

    pbMessage(_INTL("El archivo transfer.dat se ha creado correctamente."))

    if pbConfirmMessage(_INTL("¿Quieres ver la información de los Pokémon exportados?"))
      show_exported_pokemon(vault_snapshot)
    end

    pbMessage(_INTL(
      "Recuerda:\nLos Pokémon exportados se encuentran dentro del archivo transfer.dat en la carpeta Pokemon Vault."
    ))
  end
end


#===============================================================================
# Import External Pokémon
#===============================================================================

def import_external_pokemon
  path = transfer_path

  if !File.exist?(path)
    pbMessage(_INTL(
      "No se han detectado Pokémon para transferir.\n\nSi deseas importar Pokémon desde otro juego, asegúrate de haber exportado Pokémon en ese juego y de haber colocado el archivo transfer.dat dentro de la carpeta Pokemon Vault de este juego."
    ))
    return
  end

  pbMessage(_INTL("Importando Pokémon..."))

  if PokemonVault.import_transfer
    Game.save
    pbMEPlay("GUI save game")
    pbMessage(_INTL("Los Pokémon se han importado exitosamente."))
  end
end


#===============================================================================
# Show Exported Pokémon
#===============================================================================

def show_exported_pokemon(vault)
  text = ""

  vault.each_with_index do |box, b|
    box.each_with_index do |pkmn, s|
      next if !pkmn
      text += _INTL("{1} (Box {2}, Slot {3})\n", pkmn.name, b + 1, s + 1)
    end
  end

  if text == ""
    pbMessage(_INTL("Los Pokémon fueron exportados desde el Vault."))
  else
    pbMessage(_INTL("Pokémon exportados:\n\n{1}", text))
  end
end


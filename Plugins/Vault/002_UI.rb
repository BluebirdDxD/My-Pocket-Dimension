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
        break if pbConfirmMessage(_INTL("¿Salir del PC?"))
        next
      end

      break if selected.nil?

      box, slot = selected
      pkmn = @storage[box, slot]
      next if !pkmn

      if eligibility_proc && !eligibility_proc.call(pkmn)
        pbMessage(_INTL("Ese Pokémon no puede almacenarse en la Bóveda Virtual."))
        next
      end

      if box < 0
        pbMessage(_INTL("Solo puedes seleccionar Pokémon de las cajas."))
        next
      end

      commands = [
        _INTL("Seleccionar"),
        _INTL("Datos"),
        _INTL("Cancelar")
      ]

      command = pbShowCommands(helptext || _INTL("{1} seleccionado.", pkmn.name), commands)

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
        _INTL(PokemonVaultConfig::VAULT_NAME),
        [
          _INTL("Depositar Pokémon"),
          _INTL("Depositar Caja"),
          _INTL("Retirar Pokémon"),
          _INTL("Retirar Caja"),
          _INTL("Exportar Pokémon"),
          _INTL("Importar Pokémon Externos"),
          _INTL("Cancelar")
        ]
      )

      case choice
      when 0 then upload_single_pokemon
      when 1 then upload_entire_box
      when 2 then download_single_pokemon
      when 3 then download_entire_box
      when 4 then export_pokemon
      when 5 then import_external_pokemon
      else break
      end
    end
  end


  #---------------------------------------------------------------------------
  # Upload Box
  #---------------------------------------------------------------------------

  def upload_entire_box
    box = pbMessage(
      _INTL("¿Qué caja deseas depositar?"),
      (1..Settings::NUM_STORAGE_BOXES).map { |i| _INTL("Caja {1}", i) }
    )
    return if box < 0

    box_index = box
    uploaded = 0
    skipped  = 0

    PokemonVaultConfig::VAULT_BOX_SIZE.times do |slot|
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

    pbMessage(_INTL("Se han depositado {1} Pokémon.\nOmitidos {2}.", uploaded, skipped))

    Game.save if uploaded > 0
    pbMEPlay("GUI save game") if uploaded > 0
  end


  #---------------------------------------------------------------------------
  # Upload Single
  #---------------------------------------------------------------------------

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
      _INTL("Elige un Pokémon para depositar.")
    )
    return if !chosen

    pkmn, box, slot = chosen

    return if !pbConfirmMessage(
      _INTL("¿Deseas depositar a {1} en la Bóveda Virtual?", pkmn.name)
    )

    removed = remove_from_pc(box, slot)

    if add_pokemon(removed)
      pbMessage(_INTL("{1} ha sido depositado en la Bóveda Virtual.", removed.name))
      Game.save
      pbMEPlay("GUI save game")
    else
      pbMessage(_INTL("La Bóveda Virtual está llena."))
      add_to_pc(removed)
    end
  end


  #---------------------------------------------------------------------------
  # Download Single
  #---------------------------------------------------------------------------

  def download_single_pokemon
    chosen = choose_pokemon_from_vault
    return if !chosen

    pkmn, box, slot = chosen

    return if !pbConfirmMessage(
      _INTL("¿Deseas retirar a {1} de la Bóveda Virtual?", pkmn.name)
    )

    removed = remove_pokemon(box, slot)
    return if !removed

    if add_to_pc(removed)
      pbMessage(_INTL("{1} fue enviado a las cajas del PC.", removed.name))
      Game.save
      pbMEPlay("GUI save game")
    else
      pbMessage(_INTL("Tus cajas de almacenamiento están llenas."))
      add_pokemon(removed)
    end
  end


  #---------------------------------------------------------------------------
  # Download Box
  #---------------------------------------------------------------------------

  def download_entire_box
    vault = load_vault
    box_choices = []

    vault.each_with_index do |box, i|
      count = box.compact.length
      next if count == 0
      box_choices << [i, count]
    end

    if box_choices.empty?
      pbMessage(_INTL("La Bóveda Virtual está vacía."))
      return
    end

    commands = box_choices.map do |(b, count)|
      _INTL("Caja de Bóveda {1} ({2} Pokémon)", b + 1, count)
    end
    commands << _INTL("Cancelar")

    choice = pbMessage(_INTL("Elige una caja de la Bóveda para retirar."), commands)
    return if choice < 0 || choice >= box_choices.length

    box_index, _ = box_choices[choice]

    downloaded = 0
    skipped    = 0

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

    pbMessage(_INTL("Se retiraron {1} Pokémon.\nOmitidos {2}.", downloaded, skipped))

    Game.save if downloaded > 0
    pbMEPlay("GUI save game") if downloaded > 0
  end


  #---------------------------------------------------------------------------
  # Choose Pokémon
  #---------------------------------------------------------------------------

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
      pbMessage(_INTL("La Bóveda Virtual está vacía."))
      return nil
    end

    commands = entries.map.with_index do |(pkmn, b, s), i|
      _INTL("{1}. {2} (Caja {3}, Espacio {4})", i + 1, pkmn.name, b + 1, s + 1)
    end

    commands << _INTL("Cancelar")

    choice = pbMessage(_INTL("Elige un Pokémon para retirar."), commands)

    return nil if choice < 0 || choice >= entries.length
    return entries[choice]
  end


  #---------------------------------------------------------------------------
  # Export
  #---------------------------------------------------------------------------

  def export_pokemon
    vault_snapshot = load_vault

    has_pokemon = vault_snapshot.any? { |box| box.any? { |pkmn| pkmn } }

    if !has_pokemon
      pbMessage(_INTL("No hay Pokémon para exportar."))
      return
    end

    pbMessage(_INTL(
      "ATENCIÓN\nAl exportar tus Pokémon se creará un archivo transfer.dat en la carpeta Pokemon Vault."
    ))

    return if !pbConfirmMessage(_INTL("¿Deseas continuar?"))

    if export_transfer
      Game.save
      pbMEPlay("GUI save game")

      pbMessage(_INTL("El archivo transfer.dat se ha creado correctamente."))

      if pbConfirmMessage(_INTL("¿Quieres ver la información de los Pokémon exportados?"))
        show_exported_pokemon(vault_snapshot)
      end
    end
  end


  #---------------------------------------------------------------------------
  # Import
  #---------------------------------------------------------------------------

  def import_external_pokemon
    path = transfer_path

    if !File.exist?(path)
      pbMessage(_INTL("No se detectó ningún archivo transfer.dat."))
      return
    end

    data = Marshal.load(File.binread(path))
    source = data[:source_game]

    name =
      case source
      when "ETERNA_EMOCION" then "Pokémon Eterna Emoción"
      when "REFULGENTE"     then "Pokémon Refulgente"
      when "SV"             then "Proyecto Paldea"
      else source
      end

    pbMessage(_INTL("Se detectó un archivo de transferencia proveniente de {1}.", name))

result = import_transfer

if result == :overflow
  if !pbConfirmMessage(_INTL(
    "Hay más Pokémon de los que caben en la Bóveda.\n" \
    "Los Pokémon actuales serán enviados a las cajas del PC.\n" \
    "¿Deseas continuar?"
  ))
    return
  end

  result = import_transfer(true)
end

if result
  Game.save
  pbMEPlay("GUI save game")
  pbMessage(_INTL("Los Pokémon se han importado correctamente."))
end
end


  #---------------------------------------------------------------------------
  # Show Export
  #---------------------------------------------------------------------------

  def show_exported_pokemon(vault)
    text = ""

    vault.each_with_index do |box, b|
      box.each_with_index do |pkmn, s|
        next if !pkmn
        text += _INTL("{1} (Caja {2}, Espacio {3})\n", pkmn.name, b + 1, s + 1)
      end
    end

    pbMessage(_INTL("Pokémon exportados:\n\n{1}", text))
  end

end
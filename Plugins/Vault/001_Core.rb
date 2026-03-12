require 'securerandom'

module PokemonVault
  module_function


  #===============================================================================
  # Vault Menu
  #===============================================================================

  def open_menu
    loop do
      choice = pbMessage(
        _INTL("Bóveda Virtual"),
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


  #===============================================================================
  # Vault Data
  #===============================================================================

  def vault_directory
    dir = File.join(Dir.pwd, PokemonVaultConfig::VAULT_FOLDER_NAME)
    Dir.mkdir(dir) unless Dir.exist?(dir)
    return dir
  end

  def vault_path
    File.join(vault_directory, PokemonVaultConfig::VAULT_FILE)
  end

  def transfer_path
    File.join(vault_directory, PokemonVaultConfig::TRANSFER_FILE)
  end

  def empty_vault
    Array.new(PokemonVaultConfig::VAULT_MAX_BOXES) {
      Array.new(PokemonVaultConfig::VAULT_BOX_SIZE)
    }
  end

  def valid_vault?(vault)
    return false if !vault.is_a?(Array)
    return false if vault.length != PokemonVaultConfig::VAULT_MAX_BOXES
    vault.all? { |box| box.is_a?(Array) && box.length == PokemonVaultConfig::VAULT_BOX_SIZE }
  end

  def load_vault
    path = vault_path
    return empty_vault if !File.exist?(path)

    data = Marshal.load(File.binread(path))

    return empty_vault if !data.is_a?(Hash)
    return empty_vault if data[:game_id] != PokemonVaultConfig::GAME_ID

    vault = data[:boxes]

    return valid_vault?(vault) ? vault : empty_vault
  rescue
    return empty_vault
  end

  def save_vault(vault)
    data = {
      game_id: PokemonVaultConfig::GAME_ID,
      boxes: vault
    }
    File.binwrite(vault_path, Marshal.dump(data))
  end


  #===============================================================================
  # Eligibility Rules
  #===============================================================================

  def storable_pokemon?(pkmn)
    return false if !pkmn
    return false if pkmn.egg?

    species = pkmn.species_data
    return false if species.has_flag?("NotTradeable")
    return false if species.has_flag?("NotStorable")

    true
  end


  #===============================================================================
  # Vault Operations
  #===============================================================================

  def first_empty_slot(vault)
    vault.each_with_index do |box, b|
      box.each_with_index do |slot, s|
        return [b, s] if slot.nil?
      end
    end
    nil
  end

  def add_pokemon(pkmn)
    return false if !storable_pokemon?(pkmn)
    vault = load_vault
    pos = first_empty_slot(vault)
    return false if !pos

    b, s = pos
    vault[b][s] = pkmn
    save_vault(vault)
    true
  end

  def remove_pokemon(box, slot)
    vault = load_vault
    return nil if !vault.dig(box, slot)

    pkmn = vault[box][slot]
    vault[box][slot] = nil
    save_vault(vault)
    pkmn
  end


  #===============================================================================
  # Remove/Add From PC
  #===============================================================================

  def remove_from_pc(box, slot)
    pkmn = $PokemonStorage[box, slot]
    return nil if !storable_pokemon?(pkmn)

    $PokemonStorage[box, slot] = nil
    pkmn
  end

  def add_to_pc(pkmn)
    return false if !pkmn
    return !$PokemonStorage.pbStoreCaught(pkmn).nil?
  end


  #===============================================================================
  # Transfer System
  #===============================================================================

def import_will_overflow?
  vault = load_vault
  current = vault.flatten.compact.length

  path = transfer_path
  return false if !File.exist?(path)

  data = Marshal.load(File.binread(path))
  transfer = data[:pokemon].flatten.compact.length

  capacity =
    PokemonVaultConfig::VAULT_MAX_BOXES *
    PokemonVaultConfig::VAULT_BOX_SIZE

  return (current + transfer) > capacity
end

def clear_vault_to_pc
  vault = load_vault

  vault.each do |box|
    box.each do |pkmn|
      next if !pkmn
      return false if !add_to_pc(pkmn)
    end
  end

save_vault(empty_vault)

Game.save
pbMEPlay("GUI save game")

return true
end

  def export_transfer(source_game = PokemonVaultConfig::GAME_ID)
    vault = load_vault

    if vault.all? { |box| box.all?(&:nil?) }
      pbMessage(_INTL("No hay Pokémon en la Bóveda Virtual para exportar."))
      return false
    end

    transfer_id = SecureRandom.hex(16)

    $PokemonGlobal.used_transfer_ids ||= []
    $PokemonGlobal.used_transfer_ids << transfer_id

    data = {
      source_game: source_game,
      target_game: PokemonVaultConfig::EXPORT_TARGET,
      transfer_id: transfer_id,
      timestamp: Time.now.to_i,
      used: false,
      pokemon: vault
    }

    File.binwrite(transfer_path, Marshal.dump(data))

    save_vault(empty_vault)

    return true
  end


  def import_transfer(force_clear = false)
    path = transfer_path
    return false if !File.exist?(path)

    data = Marshal.load(File.binread(path))

    if data[:target_game] != "ANY" && data[:target_game] != PokemonVaultConfig::GAME_ID
      pbMessage(_INTL("Este archivo de transferencia no es compatible con este juego."))
      return false
    end

    return false if !data.is_a?(Hash)

    if data[:used]
      pbMessage(_INTL("Este archivo de transferencia ya fue utilizado."))
      return false
    end

if import_will_overflow?
  return :overflow if !force_clear
  return false if !clear_vault_to_pc
end

transfer_id = data[:transfer_id]
pokemon_boxes = data[:pokemon]

$PokemonGlobal.used_transfer_ids ||= []

if $PokemonGlobal.used_transfer_ids.include?(transfer_id)
  pbMessage(_INTL("Esta transferencia ya fue utilizada en este juego."))
  return false
end

    vault = load_vault

    pokemon_boxes.each do |box|
      box.each do |pkmn|
        next if !pkmn
        pos = first_empty_slot(vault)
        next if !pos
        b, s = pos
        vault[b][s] = pkmn
      end
    end

    save_vault(vault)

    $PokemonGlobal.used_transfer_ids << transfer_id

    data[:used] = true
    File.binwrite(path, Marshal.dump(data))

    File.delete(path)

    return true
  end

end


class PokemonGlobalMetadata
  attr_accessor :used_transfer_ids
end
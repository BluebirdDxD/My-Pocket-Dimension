#===============================================================================
# 🛰️ TRASLADADOR ESTELAR
# Sistema de exportación con selección de juego + blacklist por destino
#===============================================================================

require 'securerandom'

module StellarTransfer
  module_function

  #=============================================================================
  # 🎯 JUEGOS DISPONIBLES
  #=============================================================================
  TARGET_GAMES = [
    { id: "REFULGENTE", name: "Pokémon Refulgente" },
    { id: "ETERNA_EMOCION", name: "Pokémon Eterna Emoción" }
  ]

  #=============================================================================
  # 🚫 BLACKLIST POR JUEGO
  # (usar símbolos internos de especie)
  #=============================================================================
  BLACKLIST = {
    "REFULGENTE" => [
      :MUSCIBEAT
    ],

    "ETERNA_EMOCION" => [
      # añade aquí si quieres
    ]
  }

  #=============================================================================
  # 🎮 SELECTOR DE JUEGO (versión simple)
  #=============================================================================
  def choose_target_game
    commands = TARGET_GAMES.map { |g| g[:name] }
    choice = pbMessage(_INTL("¿A qué juego deseas transferir?"), commands, -1)
    return nil if choice < 0
    return TARGET_GAMES[choice]
  end

  #=============================================================================
  # 🔍 FILTRAR POKÉMON SEGÚN BLACKLIST
  #=============================================================================
  def filter_vault_for_game(vault, target_id)
    blacklist = BLACKLIST[target_id] || []

    valid = []
    rejected = []

    vault.each_with_index do |box, b|
      box.each_with_index do |pkmn, s|
        next if !pkmn

        if blacklist.include?(pkmn.species)
          rejected << pkmn
        else
          valid << [pkmn, b, s]
        end
      end
    end

    return valid, rejected
  end

  #=============================================================================
  # 🧾 MENSAJES DE RECHAZO
  #=============================================================================
  def show_rejected_messages(rejected, game_name)
    rejected.each do |pkmn|
      pbMessage(_INTL(
        "{1} no está programado en {2}, no puede ser transferido.\nSe quedará en la Bóveda Virtual.",
        pkmn.name, game_name
      ))
    end
  end

  #=============================================================================
  # 📦 CREAR transfer.dat CON SOLO LOS VÁLIDOS
  #=============================================================================
  def create_transfer(valid_list, target_game)
    new_boxes = Array.new(PokemonVaultConfig::VAULT_MAX_BOXES) {
      Array.new(PokemonVaultConfig::VAULT_BOX_SIZE)
    }

    valid_list.each_with_index do |(pkmn, _, _), i|
      b = i / PokemonVaultConfig::VAULT_BOX_SIZE
      s = i % PokemonVaultConfig::VAULT_BOX_SIZE
      new_boxes[b][s] = pkmn
    end

    transfer_id = SecureRandom.hex(16)

# Registrar ID como usado en ESTE juego
$PokemonGlobal.used_transfer_ids ||= []
$PokemonGlobal.used_transfer_ids << transfer_id

data = {
  source_game: PokemonVaultConfig::GAME_ID,
  target_game: target_game[:id],
  transfer_id: transfer_id,
  timestamp: Time.now.to_i,
  used: false,
  pokemon: new_boxes
}

    File.binwrite(PokemonVault.transfer_path, Marshal.dump(data))
  end

  #=============================================================================
  # 🧹 ELIMINAR SOLO LOS TRANSFERIDOS DE LA BÓVEDA
  #=============================================================================
  def remove_transferred(valid_list)
    vault = PokemonVault.load_vault

    valid_list.each do |(_, b, s)|
      vault[b][s] = nil
    end

    PokemonVault.save_vault(vault)
  end

  #=============================================================================
  # 🚀 MÉTODO PRINCIPAL (LA MÁQUINA)
  #=============================================================================
  def start_machine
    vault = PokemonVault.load_vault

    if vault.flatten.compact.empty?
      pbMessage(_INTL("La Bóveda Virtual está vacía."))
      return
    end

    target = choose_target_game
    return if !target

    valid, rejected = filter_vault_for_game(vault, target[:id])

    if valid.empty?
      pbMessage(_INTL("No hay Pokémon compatibles para transferir."))
      return
    end

    show_rejected_messages(rejected, target[:name])

    if !pbConfirmMessage(_INTL("¿Deseas continuar con la transferencia?"))
      return
    end

    create_transfer(valid, target)
    remove_transferred(valid)

    Game.save
    pbMEPlay("GUI save game")

    pbMessage(_INTL("Transferencia completada correctamente."))
  end

end
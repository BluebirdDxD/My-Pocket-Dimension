def pbUwikiVault(overwrite = true)
  # ===== decidir si cargar o reiniciar =====
  vault =
    if overwrite
      PokemonVault.empty_vault
    else
      PokemonVault.load_vault
    end

  # ===== crear UWIKI =====
  pkmn = Pokemon.new(:UWIKI, 5)
  pkmn.calc_stats
  pkmn.obtain_text = "Región de Kojumi"

  # ===== buscar primer espacio =====
  placed = false

  vault.each_with_index do |box, b|
    box.each_with_index do |slot, s|
      if slot.nil?
        vault[b][s] = pkmn
        placed = true
        break
      end
    end
    break if placed
  end

  # ===== guardar =====
  PokemonVault.save_vault(vault)

  return placed
end
#===============================================================================
# Pokémon Global Counters (versión segura)
#===============================================================================

def pbGetAllPokemon(include_vault = true)
  list = []

  # ===== Equipo =====
  if $player && $player.party
    $player.party.each do |pkmn|
      list << pkmn if pkmn
    end
  end

  # ===== PC =====
  if $PokemonStorage
    for b in 0...$PokemonStorage.maxBoxes
      for s in 0...$PokemonStorage.maxPokemon(b)
        pkmn = $PokemonStorage[b, s]
        list << pkmn if pkmn
      end
    end
  end

  # ===== Vault =====
  if include_vault
    vault = PokemonVault.load_vault
    vault.each do |box|
      box.each do |pkmn|
        list << pkmn if pkmn
      end
    end
  end

  return list
end


#--------------------------------------------------
# Contar Pokémon por ORIGEN (seguro)
#--------------------------------------------------
def pbCountPokemonByOrigin(origin)
  all = pbGetAllPokemon

  return all.count do |pkmn|
    next false if !pkmn

    begin
      text = pkmn.obtain_text.to_s.downcase
      target = origin.to_s.downcase

      text.include?(target)
    rescue
      false
    end
  end
end


#--------------------------------------------------
# Contar por ESPECIE + FORMA + ORIGEN (seguro)
#--------------------------------------------------
def pbCountSpecificPokemon(species, form, origin)
  all = pbGetAllPokemon

  return all.count do |pkmn|
    next false if !pkmn

    begin
      species_match = (pkmn.species == species)
      form_match    = (pkmn.form == form)
      origin_match  = (pkmn.obtain_text.to_s.strip.downcase == origin.to_s.strip.downcase)

      species_match && form_match && origin_match
    rescue
      false
    end
  end
end


#--------------------------------------------------
# Versión avanzada (segura)
#--------------------------------------------------
def pbCountPokemonAdvanced(species: nil, form: nil, origin: nil)
  all = pbGetAllPokemon

  return all.count do |pkmn|
    next false if !pkmn

    begin
      if species && pkmn.species != species
        next false
      end

      if form && pkmn.form != form
        next false
      end

      if origin && pkmn.obtain_text.to_s.strip.downcase != origin.to_s.strip.downcase
        next false
      end

      true
    rescue
      false
    end
  end
end


#--------------------------------------------------
# Mostrar contador
#--------------------------------------------------
def pbShowPokemonCountByOrigin(origin)
  count = pbCountPokemonByOrigin(origin)
  pbMessage(_INTL("Tienes {1} Pokémon de {2}.", count, origin))
end


#--------------------------------------------------
# Debug completo (MUY útil)
#--------------------------------------------------
def pbDebugPokemonOrigins
  text = ""

  pbGetAllPokemon.each do |pkmn|
    next if !pkmn

    begin
      name = pkmn.name
    rescue
      name = "ERROR_MON"
    end

    origin = pkmn.obtain_text rescue "nil"

    text += name + " - " + origin.to_s + "\n"
  end

  pbMessage(text)
end

def pbDebugPokemonOriginsLimited(limit = 60)
  text = ""
  count = 0
  shown = 0

  pbGetAllPokemon.each do |pkmn|
    next if !pkmn

    name = "ERROR_MON"
    origin = "nil"

    begin
      name = pkmn.name
    rescue
    end

    begin
      origin = pkmn.obtain_text.to_s
    rescue
    end

    text += name + " - " + origin + "\n"
    count += 1
    shown += 1

    if count >= 10
      pbMessage(text)
      text = ""
      count = 0
    end

    break if shown >= limit
  end

  pbMessage(text) if text != ""
end

def pbFixAllPokemonOrigins
  pbGetAllPokemon.each do |pkmn|
    next if !pkmn

    if !pkmn.obtain_text || pkmn.obtain_text.strip == ""
      pkmn.obtain_text = "Dimensión Santuario"
    end
  end
end


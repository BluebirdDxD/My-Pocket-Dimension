#######################################################################################
def pbAmeuro01
  return if $game_switches[202]

  required = [:CHIMCHAR, :BULBASAUR, :POPPLIO]
  all = pbGetAllPokemon
  found = {}

  required.each { |sp| found[sp] = false }

  all.each do |pkmn|
    next if !pkmn
    begin
      species = pkmn.species
      origin  = pkmn.obtain_text.to_s.downcase

      if origin.include?("ameuro") && found.key?(species)
        found[species] = true
      end
    rescue
    end
  end

  # ===== verificar si todos están =====
  if found.values.all?
    pbMessage("Has completado la colección Primeros Compañeros.")
    pbItemBall(:GREATBALL)
    $game_switches[202] = true
    return true
  end

  # ===== calcular faltantes =====
  missing = found.select { |_, v| !v }.keys
  count = missing.length

  pbMessage("Aún te faltan #{count} Pokémon para completar esta tarea.")

  return false
end
#######################################################################################
def pbAmeuro02
  return if $game_switches[206]

  required = [:POMMEL, :ZIGZAGOON, :MUSCIBEAT, :FLYGER]
  all = pbGetAllPokemon
  found = {}

  required.each { |sp| found[sp] = false }

  all.each do |pkmn|
    next if !pkmn
    begin
      species = pkmn.species
      origin  = pkmn.obtain_text.to_s.downcase

      if origin.include?("ameuro") && found.key?(species)
        found[species] = true
      end
    rescue
    end
  end

  # ===== verificar si todos están =====
  if found.values.all?
    pbMessage("Has completado la colección La Ruta 1.")
    pbItemBall(:GREATBALL)
    $game_switches[206] = true
    return true
  end

  # ===== calcular faltantes =====
  missing = found.select { |_, v| !v }.keys
  count = missing.length

  pbMessage("Aún te faltan #{count} Pokémon para completar esta tarea.")

  return false
end
#######################################################################################

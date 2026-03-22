module MPDTransfer
  FILE = "transfer.txt"

  module_function

  def import_if_present
    return false unless File.exist?(FILE)

text = File.read(FILE)

# ===== detectar header GAME =====
mode_limit = 6
source_game = "SHOWDOWN"

if text.upcase.include?("#GAME: ESTRELLATO")
  mode_limit = 30
  source_game = "ESTRELLATO"
end

# ===== eliminar header antes de parsear =====
text = text.gsub(/^#GAME:.*$/i, "")

sets = text.split(/\n{2,}/)

team = []

sets.each do |set|
  break if team.length >= mode_limit
      pkmn = parse_set(set)
      next if !pkmn

      apply_external_nerf(pkmn)   # ⭐ AQUI SE NERFEA

      team << pkmn
    end

    if team.empty?
      pbMessage(_INTL("No se pudieron leer Pokémon válidos."))
      File.delete(FILE)
      return false
    end

    boxes = Array.new(PokemonVaultConfig::VAULT_MAX_BOXES) {
      Array.new(PokemonVaultConfig::VAULT_BOX_SIZE)
    }

    team.each_with_index do |pkmn, i|
      box = i / PokemonVaultConfig::VAULT_BOX_SIZE
      slot = i % PokemonVaultConfig::VAULT_BOX_SIZE
      boxes[box][slot] = pkmn
    end

    data = {
      source_game: source_game,
      target_game: "ANY",
      transfer_id: SecureRandom.hex(16),
      timestamp: Time.now.to_i,
      used: false,
      pokemon: boxes
    }

    File.binwrite(PokemonVault.transfer_path, Marshal.dump(data))

    File.delete(FILE)

    pbMessage(_INTL(
      "Equipo preparado para transferencia.\nUse la Bóveda Virtual → Importar Pokémon Externos."
    ))

    return true
  end


  #==================================================
  # ⭐ NERF EXTERNO DIMENSIONAL
  #==================================================

def apply_external_nerf(pkmn)

  return if pkmn.level < 50   # ⭐ regla nueva

  # ===== involución =====
  base_species = GameData::Species.get(pkmn.species).get_baby_species
  pkmn.species = base_species

  # ===== nivel =====
  pkmn.level = 5

  # ===== quitar objeto =====
  pkmn.item = nil

  # ===== reset EV =====
  pkmn.ev.each_key { |k| pkmn.ev[k] = 0 }

  # ===== habilidad válida =====
  species_data = GameData::Species.get(pkmn.species)
  abil_list = species_data.abilities + species_data.hidden_abilities
  abil_list.compact!
  pkmn.ability = abil_list.sample if abil_list.length > 0

  # ===== shiny nerf =====
  pkmn.shiny = false if pkmn.shiny? && rand(100) < 95

  # ===== moves random =====
  levelup_moves = []
  species_data.moves.each { |m| levelup_moves << m[1] if m[0] <= 5 }
  levelup_moves.uniq!
  new_moves = levelup_moves.sample(4)

  pkmn.moves.clear
  new_moves.each_with_index do |move_id, i|
    next if !move_id
    pkmn.moves[i] = Pokemon::Move.new(move_id)
  end

  pkmn.calc_stats

  pkmn.instance_variable_set(:@external_origin, true)
end


  #==================================================
  # PARSER SHOWDOWN
  #==================================================

  def parse_set(text)
    lines = text.lines.map(&:strip).reject(&:empty?)
    return nil if lines.empty?

    header = lines.shift

    species, gender, item = parse_header(header)

    level  = 100
    ability = nil
    nature  = nil
    shiny   = false
    ev = Hash.new(0)
    moves = []

    lines.each do |l|
      case l
      when /^Ability: (.+)$/
        ability = ability_symbol($1)
      when /^Level: (\d+)$/
        level = $1.to_i
      when /^Shiny: Yes$/
        shiny = true
      when /^EVs: (.+)$/
        ev = parse_evs($1)
      when /^(.+) Nature$/
        nature = nature_symbol($1)
      when /^\- (.+)$/
        moves << move_symbol($1)
      end
    end

    return nil unless species

    pkmn = Pokemon.new(species, level)

    pkmn.item = item if item
    pkmn.ability = ability if ability
    pkmn.nature = nature if nature
    pkmn.shiny = true if shiny

    ev.each { |stat, val| pkmn.ev[stat] = val }

    moves.each_with_index do |m, i|
      next unless m
      pkmn.moves[i] = Pokemon::Move.new(m)
    end

    return pkmn
  rescue
    return nil
  end


  def parse_header(h)
    item = nil
    gender = nil

    if h.include?("@")
      parts = h.split("@")
      h = parts[0].strip
      item = item_symbol(parts[1].strip)
    end

    if h =~ /\((M|F)\)/
      gender = ($1 == "M") ? 0 : 1
      h = h.gsub(/\(M\)|\(F\)/, "").strip
    end

    species = species_symbol(h)

    return species, gender, item
  end


  def parse_evs(str)
    map = {
      "HP" => :HP,
      "Atk" => :ATTACK,
      "Def" => :DEFENSE,
      "SpA" => :SPECIAL_ATTACK,
      "SpD" => :SPECIAL_DEFENSE,
      "Spe" => :SPEED
    }

    ev = Hash.new(0)

    str.split("/").each do |part|
      v, s = part.strip.split(" ")
      stat = map[s]
      ev[stat] = v.to_i if stat
    end

    ev
  end


  #==================================================
  # CONVERSION HELPERS
  #==================================================

  def species_symbol(name)
    GameData::Species.each do |sp|
      return sp.id if sp.name.downcase == name.downcase
    end
    nil
  end

  def move_symbol(name)
    GameData::Move.each do |m|
      return m.id if m.name.downcase == name.downcase
    end
    nil
  end

  def item_symbol(name)
    GameData::Item.each do |i|
      return i.id if i.name.downcase == name.downcase
    end
    nil
  end

  def ability_symbol(name)
    GameData::Ability.each do |a|
      return a.id if a.name.downcase == name.downcase
    end
    nil
  end

  def nature_symbol(name)
    GameData::Nature.each do |n|
      return n.id if n.name.downcase == name.downcase
    end
    nil
  end
end
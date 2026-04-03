def pbCountPokemonByKeyword(keyword)
  all = pbGetAllPokemon

  return all.count do |pkmn|
    next false if !pkmn

    begin
      text = pkmn.obtain_text.to_s.downcase
      key  = keyword.to_s.downcase

      text.include?(key)
    rescue
      false
    end
  end
end

def pbShowPokemonCountByKeyword(keyword)
  count = pbCountPokemonByKeyword(keyword)
  pbMessage(_INTL("Tienes {1} Pokémon de {2}.", count, keyword))
end

def pbCountSpecificPokemonByKeyword(species, form, keyword)
  all = pbGetAllPokemon

  return all.count do |pkmn|
    next false if !pkmn

    begin
      species_match = (pkmn.species == species)
      form_match    = (pkmn.form == form)

      text = pkmn.obtain_text.to_s.downcase
      key  = keyword.to_s.downcase

      origin_match = text.include?(key)

      species_match && form_match && origin_match
    rescue
      false
    end
  end
end
#===============================================================================
# Adds/edits various Summary utilities.
#===============================================================================
class PokemonSummary_Scene
  def drawPageAllStats
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    ev_total = 0
    # Determine which stats are boosted and lowered by the Pokémon's nature
    statshadows = {}
    GameData::Stat.each_main { |s| statshadows[s.id] = shadow; ev_total += @pokemon.ev[s.id] }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
      @pokemon.nature_for_stats.stat_changes.each do |change|
        statshadows[change[0]] = Color.new(136, 96, 72) if change[1] > 0
        statshadows[change[0]] = Color.new(64, 120, 152) if change[1] < 0
      end
    end
    # Write various bits of text
    textpos = [
      [_INTL("Total"), 361, 92, :left, base, shadow],
      [_INTL("IV"), 466, 92, :left, base, shadow],
      [_INTL("EV"), 511, 92, :left, base, shadow],
      [_INTL("PS"), 256, 131, :left, base, statshadows[:HP]],
      [@pokemon.totalhp.to_s, 381, 131, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      #[sprintf("%d", @pokemon.baseStats[:HP]), 408, 126, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.iv[:HP]), 466, 131, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.ev[:HP]), 511, 131, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Ataque"), 256, 168, :left, base, statshadows[:ATTACK]],
      [@pokemon.attack.to_s, 381, 168, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      #[sprintf("%d", @pokemon.baseStats[:ATTACK]), 408, 158, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.iv[:ATTACK]), 466, 168, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.ev[:ATTACK]), 511, 168, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Defensa"), 256, 205, :left, base, statshadows[:DEFENSE]],
      [@pokemon.defense.to_s, 381, 205, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      #[sprintf("%d", @pokemon.baseStats[:DEFENSE]), 408, 190, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.iv[:DEFENSE]), 466, 205, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.ev[:DEFENSE]), 511, 205, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("At. Esp."), 256, 242, :left, base, statshadows[:SPECIAL_ATTACK]],
      [@pokemon.spatk.to_s, 381, 242, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      #[sprintf("%d", @pokemon.baseStats[:SPECIAL_ATTACK]), 408, 222, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.iv[:SPECIAL_ATTACK]), 466, 242, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.ev[:SPECIAL_ATTACK]), 511, 242, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Def Esp."), 256, 279, :left, base, statshadows[:SPECIAL_DEFENSE]],
      [@pokemon.spdef.to_s, 381, 279, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      #[sprintf("%d", @pokemon.baseStats[:SPECIAL_DEFENSE]), 408, 254, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.iv[:SPECIAL_DEFENSE]), 466, 279, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.ev[:SPECIAL_DEFENSE]), 511, 279, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Velocidad"), 256, 316, :left, base, statshadows[:SPEED]],
      [@pokemon.speed.to_s, 381, 316, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      #[sprintf("%d", @pokemon.baseStats[:SPEED]), 408, 286, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.iv[:SPEED]), 466, 316, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.ev[:SPEED]), 511, 316, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("EVs Totales"), 300, 380, :left, base, shadow],
      [sprintf("%d/%d", ev_total, Pokemon::EV_LIMIT), 465, 380, :center, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Poder Oculto"), 300, 410, :left, base, shadow]
    ]
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    
    hiddenpower = pbHiddenPower(@pokemon)
    type_number = GameData::Type.get(hiddenpower[0]).icon_position
    type_rect = Rect.new(0, type_number * 28, 64, 28)
    overlay.blt(440, 406, @typebitmap.bitmap, type_rect)
  end
end
# Reemplazo completo y robusto de PokemonPartySidebar (con HP mínimo visible)
class PokemonPartySidebar
  BOX_WIDTH      = 260
  BOX_HEIGHT     = 60
  START_X        = 8
  START_Y        = 32
  ICON_SIZE      = 48
  MAX_SLOTS      = 6

  NAME_OFFSET_X   = 10
  HP_BAR_OFFSET_X = 15 - 7
  ICON_OFFSET_X   = 120 - 5

  STATUS_ICON_WIDTH  = 44
  STATUS_ICON_HEIGHT = 16

  attr_accessor :moving_index

  def initialize(viewport)
    @viewport = viewport
    @sprites  = {}
    @selected_index = 0
    @moving_index = nil
    @focus = :options
    @cache_bitmaps = {}
    load_ui_bitmaps
    refresh
  end

  # -----------------------------------------------------------
  # Carga bitmaps UI
  # -----------------------------------------------------------
  def load_ui_bitmaps
    paths = {
      party_box_normal:   "Graphics/UI/Menu + Sidebar/party_box_normal.png",
      party_box_selected: "Graphics/UI/Menu + Sidebar/party_box_selected.png",
      statuses:           "Graphics/UI/Menu + Sidebar/statuses.png",
      shiny:              "Graphics/UI/Menu + Sidebar/shiny.png",
      hp_bar:             "Graphics/UI/Menu + Sidebar/hp_bar.png",
      hp_fill_green:      "Graphics/UI/Menu + Sidebar/hp_fill_green.png",
      hp_fill_yellow:     "Graphics/UI/Menu + Sidebar/hp_fill_yellow.png",
      hp_fill_red:        "Graphics/UI/Menu + Sidebar/hp_fill_red.png",
      gender_icons:       "Graphics/UI/Menu + Sidebar/icon_genders.png"
    }
    paths.each { |k,v| @cache_bitmaps[k] = Bitmap.new(v) rescue nil }
  end

  # -----------------------------------------------------------
  # Update cada frame
  # -----------------------------------------------------------
  def update
    @sprites.each_value do |s|
      s.update if s.respond_to?(:update) rescue nil
    end
  end

  # -----------------------------------------------------------
  # Refresca toda la sidebar
  # -----------------------------------------------------------
  def refresh
    dispose_sprites
    size = (defined?(Settings) && Settings.const_defined?(:MAX_PARTY_SIZE)) ? Settings::MAX_PARTY_SIZE : $player.party.length
    spacing_y = BOX_HEIGHT + 4
    size.times do |i|
      pkmn = $player.party[i] rescue nil
      next unless pkmn
      x = START_X
      y = START_Y + i * spacing_y
      create_party_box(i, pkmn, x, y)
    end
    set_selected(@selected_index)
  end

  # -----------------------------------------------------------
  # Crear / (re)crear un slot completo
  # -----------------------------------------------------------
  def create_party_box(index, pkmn, x, y)
    cleanup_index_sprites(index)

    # Panel principal
    panel = Sprite.new(@viewport)
    panel.bitmap = Bitmap.new(BOX_WIDTH, BOX_HEIGHT)
    panel.x = x
    panel.y = y
    panel.z = (@viewport.z || 99_999) + 1
    @sprites["party#{index}"] = panel

    # Dibujado inicial del panel
    draw_party_panel(panel, index, pkmn)

    # Icono Pokémon
    if @sprites["icon#{index}"]
      @sprites["icon#{index}"].dispose rescue nil
      @sprites.delete("icon#{index}")
    end
    begin
      icon_sprite = PokemonIconSprite.new(pkmn, @viewport)
      icon_sprite.setOffset(PictureOrigin::TOP_LEFT) rescue nil
      icon_sprite.x = x + ICON_OFFSET_X
      icon_sprite.y = y + ((BOX_HEIGHT - ICON_SIZE) / 2) - 10
      icon_sprite.z = panel.z + 2
      icon_sprite.active = true if icon_sprite.respond_to?(:active=)
      @sprites["icon#{index}"] = icon_sprite
    rescue; end

    # Held Item
    if @sprites["helditem_#{index}"]
      @sprites["helditem_#{index}"].dispose rescue nil
      @sprites.delete("helditem_#{index}")
    end
    if pkmn.item
      begin
        held_icon = HeldItemIconSprite.new(x + ICON_OFFSET_X + 38, y + 36, pkmn, @viewport)
        held_icon.z = panel.z + 3
        @sprites["helditem_#{index}"] = held_icon
      rescue; end
    end

    # Barra de HP y texto
    ensure_hp_for_slot(index, pkmn)
  end

  # -----------------------------------------------------------
  # Dibuja panel
  # -----------------------------------------------------------
  def draw_party_panel(panel, index, pkmn)
  # ✅ Selección y movimiento sincronizados
  selected = ((@selected_index == index && @focus == :party) || (@moving_index == index))
  moving   = (@moving_index == index)
  
  # Fondo
  panel_bmp = moving ? @cache_bitmaps[:party_box_selected] : (selected ? @cache_bitmaps[:party_box_selected] : @cache_bitmaps[:party_box_normal])
  panel.bitmap.clear
  panel.bitmap.blt(0, 0, panel_bmp, panel_bmp.rect) if panel_bmp

  pbSetSystemFont(panel.bitmap)

  # Colores según selección
  if selected
    base_color   = Color.new(48, 70, 102)
    shadow_color = Color.new(174, 180, 186)
  else
    base_color   = Color.new(255, 255, 255)
    shadow_color = Color.new(0, 0, 0)
  end

  # Nombre
  pbDrawTextPositions(panel.bitmap, [[pkmn.name, NAME_OFFSET_X, 5, :left, base_color, shadow_color]])
  return if pkmn.egg?

  # Nivel
  pbSetSmallFont(panel.bitmap)
  pbDrawTextPositions(panel.bitmap, [[_INTL("Nv {1}", pkmn.level.to_s), 203, 7, :center, base_color, shadow_color]])

  # Género
  if @cache_bitmaps[:gender_icons] && pkmn.gender != 2
    gender_rect = case pkmn.gender
                  when 0 then Rect.new(0, 0, 22, 22)
                  when 1 then Rect.new(22, 0, 22, 22)
                  end
    panel.bitmap.blt(235, 4, @cache_bitmaps[:gender_icons], gender_rect) rescue nil
  end

  # Status
  if @sprites["status_#{index}"]
    @sprites["status_#{index}"].dispose rescue nil
    @sprites.delete("status_#{index}")
  end
  status_index = -1
  if pkmn.fainted?
    status_index = GameData::Status.count - 1 rescue -1
  elsif pkmn.status && pkmn.status != :NONE
    sd = GameData::Status.get(pkmn.status) rescue nil
    status_index = sd.icon_position rescue -1 if sd
  end
  if status_index >= 0 && @cache_bitmaps[:statuses]
    src_rect = Rect.new(0, STATUS_ICON_HEIGHT * status_index, STATUS_ICON_WIDTH, STATUS_ICON_HEIGHT)
    status_sprite = Sprite.new(@viewport)
    status_sprite.bitmap = @cache_bitmaps[:statuses]
    status_sprite.src_rect = src_rect
    status_sprite.x = panel.x + 181
    status_sprite.y = panel.y + 29
    status_sprite.z = panel.z + 3
    @sprites["status_#{index}"] = status_sprite
  end

  # Shiny
  if @sprites["shiny_#{index}"]
    @sprites["shiny_#{index}"].dispose rescue nil
    @sprites.delete("shiny_#{index}")
  end
  if pkmn.shiny? && @cache_bitmaps[:shiny]
    shiny_sprite = Sprite.new(@viewport)
    shiny_sprite.bitmap = @cache_bitmaps[:shiny]
    shiny_sprite.x = panel.x + 239
    shiny_sprite.y = panel.y + 29
    shiny_sprite.z = panel.z + 3
    @sprites["shiny_#{index}"] = shiny_sprite
  end
end


  # -----------------------------------------------------------
  # Barra de HP con protección para 1 HP
  # -----------------------------------------------------------
  def ensure_hp_for_slot(index, pkmn)
    return if pkmn.egg?
    panel = @sprites["party#{index}"]
    return unless panel && panel.bitmap

    # Limpiar HP previos
    ["hp_bg_#{index}", "hp_fill_#{index}", "hp_text_#{index}"].each do |key|
      if @sprites[key]
        @sprites[key].dispose rescue nil
        @sprites.delete(key)
      end
    end

    # Crear fondo de HP
    if @cache_bitmaps[:hp_bar]
      hp_bg = Sprite.new(@viewport)
      hp_bg.bitmap = @cache_bitmaps[:hp_bar]
      hp_bg.x = panel.x + HP_BAR_OFFSET_X
      hp_bg.y = panel.y + (BOX_HEIGHT - 24) / 2 + 9
      hp_bg.z = panel.z + 1
      @sprites["hp_bg_#{index}"] = hp_bg
      update_hp_bar(index, pkmn)
    else
      # fallback directo en panel
      begin
        hp_percent = (pkmn.totalhp > 0) ? (pkmn.hp / pkmn.totalhp.to_f) : 0.0
        panel.bitmap.fill_rect(HP_BAR_OFFSET_X, (BOX_HEIGHT - 24) / 2 + 9, ((BOX_WIDTH - HP_BAR_OFFSET_X - 10) * hp_percent).ceil, 24, Color.new(0,200,0))
      rescue; end
    end
  end

  def update_hp_bar(index, pkmn)
    bg = @sprites["hp_bg_#{index}"]
    return unless bg && !bg.disposed?

    hp_percent = (pkmn.totalhp > 0) ? (pkmn.hp / pkmn.totalhp.to_f) : 0.0
    hp_percent = 0.0 if hp_percent.nan?

    # Seleccionar fill
    fill_bitmap = case hp_percent
                  when 0.0...0.2 then @cache_bitmaps[:hp_fill_red]
                  when 0.2...0.5 then @cache_bitmaps[:hp_fill_yellow]
                  else @cache_bitmaps[:hp_fill_green]
                  end
    return unless fill_bitmap

    # Limpiar fill previo
    if @sprites["hp_fill_#{index}"]
      @sprites["hp_fill_#{index}"].dispose rescue nil
      @sprites.delete("hp_fill_#{index}")
    end

    rect = Rect.new(0, 0, fill_bitmap.width, fill_bitmap.height)
    fill_bitmap.width.times do |x|
      rect.x = x
      break unless fill_bitmap.get_pixel(x, fill_bitmap.height / 2).alpha == 0
    end
    rect.width = fill_bitmap.width - rect.x

    # ✅ Protección mínima de 2 píxeles si HP > 0
    scaled_width = (rect.width * hp_percent).ceil
    scaled_width = 2 if hp_percent > 0 && scaled_width < 2

    # Crear sprite de fill
    hp_fill = Sprite.new(@viewport)
    hp_fill.bitmap = Bitmap.new(scaled_width, rect.height)
    hp_fill.bitmap.stretch_blt(Rect.new(0, 0, scaled_width, rect.height), fill_bitmap, rect)
    hp_fill.x = bg.x + 4
    hp_fill.y = bg.y
    hp_fill.z = bg.z + 1
    @sprites["hp_fill_#{index}"] = hp_fill

    # Texto HP
    if @sprites["hp_text_#{index}"]
      @sprites["hp_text_#{index}"].dispose rescue nil
      @sprites.delete("hp_text_#{index}")
    end
    hp_text_sprite = Sprite.new(@viewport)
    hp_text_sprite.bitmap = Bitmap.new(bg.bitmap.width, bg.bitmap.height)
    pbSetSystemFont(hp_text_sprite.bitmap)
    hp_text = sprintf("% 3d /% 3d", pkmn.hp, pkmn.totalhp)
    pbDrawTextPositions(hp_text_sprite.bitmap, [[hp_text, 103, 7, :right, Color.new(255,255,255), Color.new(0,0,0)]])
    hp_text_sprite.x = bg.x
    hp_text_sprite.y = bg.y
    hp_text_sprite.z = bg.z + 2
    @sprites["hp_text_#{index}"] = hp_text_sprite
  end

  # -----------------------------------------------------------
  # Selección / moving
  # -----------------------------------------------------------
  # Ahora `moving` puede ser: true -> marcar moving en este index,
  # false -> limpiar moving_index, nil -> no tocar moving_index.
  def set_selected(index, moving = nil)
    party_size = $player.party.size rescue 0
    return if party_size == 0
    index = [[0, index].max, party_size - 1].min
    old_index = @selected_index
    @selected_index = index

    # Solo actualizar @moving_index si nos pasan explícitamente el flag
    if !moving.nil?
      @moving_index = moving ? index : nil
    end

    [old_index, @selected_index].compact.uniq.each do |i|
      next unless @sprites["party#{i}"]
      panel = @sprites["party#{i}"]
      pkmn = $player.party[i] rescue nil
      next unless panel && pkmn
      panel.bitmap.clear
      draw_party_panel(panel, i, pkmn)
      ensure_hp_for_slot(i, pkmn)
    end
  end


  # -----------------------------------------------------------
  # Limpieza sprites
  # -----------------------------------------------------------
  def cleanup_index_sprites(index)
    idx_s = index.to_s
    keys = @sprites.keys.select { |k| k.to_s.include?(idx_s) }
    keys.each { |k| @sprites[k].dispose rescue nil; @sprites.delete(k) }

    if defined?(@icons) && @icons
      ikeys = @icons.keys.select { |k| k.to_s.include?(idx_s) }
      ikeys.each { |k| @icons[k].dispose rescue nil; @icons.delete(k) }
    end

    PokemonIconSprite.invalidate if PokemonIconSprite.respond_to?(:invalidate) rescue nil
  end

  def refresh_single(index)
    return unless index && index >= 0 && $player && $player.party && index < $player.party.size
    cleanup_index_sprites(index)
    pkmn = $player.party[index]
    spacing_y = BOX_HEIGHT + 4
    x = START_X
    y = START_Y + index * spacing_y
    create_party_box(index, pkmn, x, y)
    panel = @sprites["party#{index}"]
    panel.bitmap.clear if panel && panel.bitmap
    draw_party_panel(panel, index, pkmn)
  end

def on_party_order_changed(old_idx, new_idx)
  # ✅ Primero, limpiar highlight de movimiento
  @moving_index = nil

  # Refrescar slots
  refresh_single(old_idx) if old_idx
  refresh_single(new_idx) if new_idx

  # Actualizar índice seleccionado
  @selected_index = new_idx if new_idx
  set_selected(@selected_index, false) # false fuerza que moving_index quede nil

rescue
  refresh rescue nil
end


  def set_focus(sym)
    @focus = sym
    set_selected(@selected_index)
  end

  def move_selection(direction)
    return if $player.party.empty?
    new_index = (@selected_index + direction) % $player.party.size
    set_selected(new_index)
  end

  def dispose_sprites
    @sprites.each_value { |s| s.dispose rescue nil } if @sprites
    @sprites.clear if @sprites
  end

  def dispose
    dispose_sprites
    if @cache_bitmaps
      @cache_bitmaps.each_value { |b| b.dispose rescue nil }
      @cache_bitmaps.clear
    end
  end
end

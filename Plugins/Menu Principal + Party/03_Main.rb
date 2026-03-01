# ===============================================================
# MenuCustomScene (Mockup estilo Scarlet/Violet)
# Opciones: Mochila, Cajas, Opciones, Guardar
# Incluye sidebar de party + context menu con gráficos
# ===============================================================
class MenuCustomScene
  ICON_FOLDER = File.join("Graphics", "UI", "Menu + Sidebar", "menu_icons")
  HIGHLIGHT_PATH = "Graphics/UI/Menu + Sidebar/menu_highlight.png"
  CONTEXT_MENU_BG_PATH = "Graphics/UI/Menu + Sidebar/context_menu_bg.png"
  CONTEXT_HIGHLIGHT_PATH = "Graphics/UI/Menu + Sidebar/context_highlight.png"

  # ==============================================================
  # Inicialización de escena
  # ==============================================================
  def pbStartScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99_999
    @finished = false
    @select = 0
    @focus = :options
    @focus_changed = @focus
    @party_index = 0
    @last_party_index = -1
    @switching_original = nil

    # Opciones principales
    @menu_options = [{ text: _INTL("Mochila"), icon: "bag.png" }]
# Pokédex → Switch 39
if $game_switches[39]
  @menu_options << { text: _INTL("Pokédex"), icon: "pokedex.png" }
end

if $game_switches[39]
  @menu_options << { text: _INTL("PokéNav"), icon: "pokenav.png" }
end

# Cajas → Switch 40
if $game_switches[40]
  @menu_options << { text: _INTL("Cajas"), icon: "boxes.png" }
end
    @menu_options += [
      { text: _INTL("Opciones"), icon: "options.png" },
      { text: _INTL("Guardar"), icon: "save.png" }
    ]

    # Tamaños y bitmaps de iconos
    @icon_size = 48
    @tile_h = @icon_size + 8
    @icon_padding = 6
    @icon_bitmaps = load_icon_bitmaps(@menu_options)

    # Bitmaps de highlight y menú contextual
    @highlight_bitmap = safe_bitmap(HIGHLIGHT_PATH)
    @context_bg_bitmap = safe_bitmap(CONTEXT_MENU_BG_PATH)
    @context_highlight_bitmap = safe_bitmap(CONTEXT_HIGHLIGHT_PATH)

    # Sidebar y panel principal
    @sidebar = PokemonPartySidebar.new(@viewport) if defined?(PokemonPartySidebar)
    create_menu_panel

    # Sprite de selección
    @sprites["menu_selection"] = Sprite.new(@viewport)
    @sprites["menu_selection"].bitmap = Bitmap.new(1,1)
    @sprites["menu_selection"].visible = false

    # Dibujar sidebar Pokémon
    pbDrawPokemonTeam
  end

  # ==============================================================
  # Carga segura de bitmaps (con log en modo DEBUG)
  # ==============================================================
  def safe_bitmap(path)
    return nil unless path && File.file?(path)
    Bitmap.new(path)
  rescue => e
    puts "safe_bitmap error: #{e.message} (#{path})" if $DEBUG
    nil
  end

  # ==============================================================
  # Carga y escala de iconos
  # ==============================================================
  def load_icon_bitmaps(options)
    hash = {}
    options.each do |opt|
      path = File.join(ICON_FOLDER, opt[:icon])
      next unless File.file?(path)
      begin
        orig = Bitmap.new(path)
        scaled = Bitmap.new(@icon_size, @icon_size)
        scaled.stretch_blt(Rect.new(0,0,@icon_size,@icon_size), orig, orig.rect)
        orig.dispose
        hash[opt[:icon]] = scaled
      rescue => e
        puts "load_icon_bitmaps error: #{e.message} (#{path})" if $DEBUG
        next
      end
    end
    hash
  end

  # ==============================================================
  # Panel principal
  # ==============================================================
  def create_menu_panel
    panel_w = 220
    total_tiles = @menu_options.length
    panel_h = 48 + total_tiles*@tile_h + (total_tiles-1)*6 + 16
    panel_x = Graphics.width - panel_w - 10
    panel_y = (@sidebar && @sidebar.instance_variable_get(:@sprites) && @sidebar.instance_variable_get(:@sprites)["party0"]) ?
              @sidebar.instance_variable_get(:@sprites)["party0"].y : 64

    @menu_panel_x, @menu_panel_y = panel_x, panel_y
    @menu_panel_w, @menu_panel_h = panel_w, panel_h

    spr = Sprite.new(@viewport)
    spr.bitmap = Bitmap.new(panel_w, panel_h)
    spr.x, spr.y = panel_x, panel_y
    spr.z = (@viewport.z || 99_999) + 1
    @sprites["menu_panel"] = spr

    redraw_menu_panel
  end

  def redraw_menu_panel
    bmp = @sprites["menu_panel"].bitmap
    bmp.clear
    pbSetSystemFont(bmp)

    # Fondo
    panel_bg = safe_bitmap("Graphics/UI/menu_bg.png")
    if panel_bg
      bmp.stretch_blt(Rect.new(0,0,@menu_panel_w,@menu_panel_h), panel_bg, panel_bg.rect)
      panel_bg.dispose
    else
      bmp.fill_rect(0,0,@menu_panel_w,@menu_panel_h,Color.new(18,18,22,220))
    end

    # Título
    pbDrawOutlineText(bmp,12,15,@menu_panel_w-24,28,_INTL("MENÚ PRINCIPAL"),Color.new(255,255,255),Color.new(0,0,0),0)
    bmp.fill_rect(12,43,@menu_panel_w-24,2,Color.new(200,200,200,180)) # Línea

    start_y = 52
    @menu_options.each_with_index do |opt,i|
      y = start_y + i*(@tile_h+6)
      # Highlight gráfico de fondo
      bmp.stretch_blt(Rect.new((@menu_panel_w-210)/2,y,210,@tile_h), @highlight_bitmap, @highlight_bitmap.rect) if i==@select && @focus==:options && @highlight_bitmap

      icon_bmp = @icon_bitmaps[opt[:icon]]
      text_x = 4 + @icon_padding
      if icon_bmp
        bmp.blt(4+@icon_padding, y + (@tile_h - @icon_size)/2, icon_bmp, icon_bmp.rect) rescue nil
        text_x += @icon_size + 6
      end

      # ✅ Color del texto según selección
      if i == @select && @focus == :options
          base_color   = Color.new(48, 70, 102)
          shadow_color = Color.new(174, 180, 186)
      else
        base_color   = Color.new(255,255,255)   # blanco normal
        shadow_color = Color.new(0,0,0)
      end

      pbDrawTextPositions(bmp, [[opt[:text], text_x, y+(@tile_h-20)/2, :left, base_color, shadow_color]])
    end
  end

  # ==============================================================
  # Sidebar de Pokémon
  # ==============================================================
  def pbDrawPokemonTeam
    return unless defined?(SHOW_POKEMON_TEAM) && SHOW_POKEMON_TEAM
    dispose_party_sidebar if @party_sprites
    create_party_sidebar
    update_party_selection_visual
  end

  def create_party_sidebar
    @party_sprites ||= {}
    size = (defined?(Settings) && Settings.const_defined?(:MAX_PARTY_SIZE)) ? Settings::MAX_PARTY_SIZE : 6
    party_x, party_y, spacing = 16, 80, 50
    size.times do |i|
      spr = Sprite.new(@viewport)
      spr.bitmap = Bitmap.new(1,1) rescue nil
      spr.x, spr.y = party_x, party_y + i*spacing
      spr.z = (@viewport.z||99_999)+1
      spr.visible = false
      @party_sprites[i] = spr
    end
  end

  def dispose_party_sidebar
    return unless @party_sprites
    @party_sprites.each_value do |s|
      next unless s
      s.bitmap.dispose if s.bitmap && !s.disposed?
      s.dispose if !s.disposed?
    end
    @party_sprites = nil
  end

  # refresca highlights/selección del sidebar (no reconstruye sprites)
  def refresh_party_sidebar
    return unless @party_sprites
    update_party_selection_visual
  end

  # actualiza internamente sprites hash
  def update_party_sidebar
    return unless @party_sprites
    pbUpdateSpriteHash(@party_sprites)
  end

  def update_party_selection_visual
    redraw_menu_panel if @focus_changed != @focus
    @focus_changed = @focus
    pbPlayCursorSE if @focus==:party && @last_party_index!=@party_index
    @last_party_index = @party_index
    return unless @sidebar
    @sidebar.set_focus(@focus) if @sidebar.respond_to?(:set_focus)
    @sidebar.moving_index = @switching_original if @sidebar.respond_to?(:moving_index=)
    @sidebar.set_selected(@party_index) if @sidebar.respond_to?(:set_selected)
  end

  # ==============================================================
  # FULL REFRESH (reconstruye sidebar y redibuja panel)
  # Usar cuando se vuelve desde subpantallas que pueden cambiar la party
  # ==============================================================
  def full_refresh
    # 1) Reconstruye los sprites de la party local para reflejar cambios reales en $player.party
    pbDrawPokemonTeam

    # 2) Intenta forzar que el objeto @sidebar (si existe) actualice sus propios sprites internos.
    if @sidebar
      if @sidebar.respond_to?(:refresh)
        @sidebar.refresh
      elsif @sidebar.respond_to?(:pbRefresh)
        @sidebar.pbRefresh
      elsif @sidebar.respond_to?(:refresh_party)
        @sidebar.refresh_party
      else
        # Fallback: intentar disponer y recrear el sidebar (si la clase está disponible)
        begin
          @sidebar.dispose if @sidebar.respond_to?(:dispose)
        rescue => e
          puts "full_refresh: fallo al disponer sidebar: #{e.message}" if $DEBUG
        end
        @sidebar = PokemonPartySidebar.new(@viewport) if defined?(PokemonPartySidebar)
      end
    else
      # Si no hay sidebar actualmente, intentar crearlo (por si estaba nil antes)
      @sidebar = PokemonPartySidebar.new(@viewport) if defined?(PokemonPartySidebar)
    end

    # 3) Redibuja el panel principal y fuerza una actualización de sprites
    redraw_menu_panel
    update_sprites
  end

  # ==============================================================
  # Helpers de índice
  # ==============================================================
  def next_valid_party_index(dir)
    return -1 if $player.party.empty?
    len = (defined?(Settings) && Settings.const_defined?(:MAX_PARTY_SIZE)) ? Settings::MAX_PARTY_SIZE : 6
    cur = @party_index
    attempts = 0
    loop do
      cur = (cur + dir) % len
      return cur if $player.party[cur]
      attempts += 1
      return -1 if attempts >= len
    end
  end

  def first_valid_party_index
    len = (defined?(Settings) && Settings.const_defined?(:MAX_PARTY_SIZE)) ? Settings::MAX_PARTY_SIZE : 6
    len.times { |i| return i if $player.party[i] }
    -1
  end

  # ==============================================================
  # Reset selección
  # ==============================================================
  def reset_selection
    @select = 0
    @focus = :options
    @focus_changed = @focus
  end

  # ==============================================================
  # Menú contextual de Pokémon
  # ==============================================================
  # Método auxiliar: quitar objeto sin mostrar mensaje
  def pbTakeItemFromPokemonSilent(pkmn)
    return nil unless pkmn && pkmn.hasItem?
    item = pkmn.item
    pkmn.item = nil
    return item
  end

# Menú contextual del Pokémon (cerrando menú para Summary y Dar objeto)
def pbOpenPartyContextMenu(party_idx)
  return if party_idx < 0
  pkmn = $player.party[party_idx]
  return unless pkmn

  # Proc para generar las opciones dinámicas
  create_options = proc {
    item_option_text = pkmn.hasItem? ? _INTL("Guardar objeto") : _INTL("Dar objeto")
    [_INTL("Datos"), _INTL("Mover"), item_option_text, _INTL("Salir")]
  }

  options = create_options.call

  # Posición y tamaño de la ventana
  menu_w = 140
  menu_h = options.length * 40 + 10
  slot_spr = @party_sprites[party_idx]
  menu_x = [10, [slot_spr.x + 200, Graphics.width - menu_w - 10].min].max
  menu_y = [10, [slot_spr.y - 50, Graphics.height - menu_h - 10].min].max
  max_slot_index = (defined?(Settings) && Settings.const_defined?(:MAX_PARTY_SIZE)) ? Settings::MAX_PARTY_SIZE-1 : $player.party.length-1
  menu_y += 50 if party_idx == max_slot_index
  menu_y = Graphics.height - menu_h if menu_y + menu_h > Graphics.height

  cmd_window = Window_CommandPokemon.new(options)
  cmd_window.index = 0
  cmd_window.x = menu_x
  cmd_window.y = menu_y
  cmd_window.z = (@viewport&.z || 99_999) + 10

  loop do
    Graphics.update
    Input.update
    pbUpdateSpriteHash(@sprites)
    @sidebar.update if @sidebar
    update_party_sidebar
    cmd_window.update if cmd_window && !cmd_window.disposed?

    break if Input.trigger?(Input::BACK)

    next unless Input.trigger?(Input::USE)

    case cmd_window.index
when 0
  # Summary / Datos
  cmd_window.visible = false  # 👈 oculta ventana
  pbFadeOutIn { PokemonSummaryScreen.new(PokemonSummary_Scene.new, false).pbStartScreen($player.party, party_idx) }
  refresh_party_sidebar if respond_to?(:refresh_party_sidebar)
  cmd_window.dispose if cmd_window && !cmd_window.disposed?
  break


    when 1
      # Mover Pokémon
      @switching_original = party_idx
      @focus = :party
      break

    when 2
      if pkmn.hasItem?
        # Quitar objeto
        pbTakeItemFromPokemonSilent(pkmn)
        @sidebar.refresh if @sidebar && @sidebar.respond_to?(:refresh)
        cmd_window.dispose if cmd_window && !cmd_window.disposed?
        break # Cierra menú automáticamente
      else
        # Dar objeto
        cmd_window.visible = false
        pbFadeOutIn do
          scene  = PokemonBag_Scene.new
          screen = PokemonBagScreen.new(scene, $bag)

          allowed_pockets = [1,5,6] # Objetos, Bayas, Cartas
          filterproc = proc { |item_id|
            itm = GameData::Item.get(item_id) rescue nil
            next false if itm.nil? || itm.is_machine? || itm.is_key_item?
            allowed_pockets.include?(itm.pocket)
          }

          scene.pbStartScene($bag, $player.party, true, filterproc)
          item = scene.pbChooseItem
          pbGiveItemToPokemon(item, pkmn, scene) if item
          @sidebar.refresh if @sidebar && @sidebar.respond_to?(:refresh)
          scene.pbEndScene
        end
        cmd_window.dispose if cmd_window && !cmd_window.disposed?
        break # Cierra menú automáticamente
      end

    when 3
      break # Salir
    end
  end

  cmd_window.dispose if cmd_window && !cmd_window.disposed?
  refresh_party_sidebar if respond_to?(:refresh_party_sidebar)
end



  # ==============================================================
  # Acciones menú principal
  # ==============================================================
def perform_menu_action(index)
  option = @menu_options[index][:text]

  case option
  when _INTL("Mochila")
    call_custom_menu_handler(:bag)

  when _INTL("Pokédex")
    call_custom_menu_handler(:pokedex)

 when _INTL("PokéNav")
    call_custom_menu_handler(:pokenav)

  when _INTL("Cajas")
    call_custom_menu_handler(:boxes)

  when _INTL("Opciones")
    call_custom_menu_handler(:options)

  when _INTL("Guardar")
    call_custom_menu_handler(:save)

  else
    pbPlayBuzzerSE
  end

  redraw_menu_panel
end

  # ==============================================================
  # Manejador de acciones
  # ==============================================================
  def call_custom_menu_handler(symbol)
    menu_proxy = Object.new
    menu_proxy.instance_variable_set(:@scene, self)

    # pbRefresh ahora intenta usar full_refresh si existe; si no cae al comportamiento anterior.
    def menu_proxy.pbRefresh
      scene = instance_variable_get(:@scene)
      if scene.respond_to?(:full_refresh)
        scene.full_refresh
      else
        scene.redraw_menu_panel if scene.respond_to?(:redraw_menu_panel)
        scene.refresh_party_sidebar if scene.respond_to?(:refresh_party_sidebar)
      end
    end

    def menu_proxy.pbEndScene
      scene = instance_variable_get(:@scene)
      scene.instance_variable_set(:@finished, true) if scene
    end

    pbPlayDecisionSE
    case symbol
    when :bag
      pbFadeOutIn { PokemonBagScreen.new(PokemonBag_Scene.new, $bag).pbStartScreen }
    when :pokedex
      pbFadeOutIn do
        scene = PokemonPokedex_Scene.new
        PokemonPokedexScreen.new(scene).pbStartScreen
      end
      menu_proxy.pbRefresh
when :pokenav
  pbFadeOutIn do
    scene  = PokemonPokenav_Scene.new
    screen = PokemonPokenavScreen.new(scene)
    screen.pbStartScreen
  end
  menu_proxy.pbRefresh
    when :boxes
      pbFadeOutIn do
        scene = PokemonStorageScene.new rescue nil
        storage = $PokemonStorage rescue nil
        if scene && storage
          PokemonStorageScreen.new(scene, storage).pbStartScreen(0)
        else
          pbMessage(_INTL("El sistema de cajas no está disponible."))
        end
      end
      # IMPORTANTE: forzamos refresh completo al volver de Boxes
      menu_proxy.pbRefresh
    when :options
      pbFadeOutIn { PokemonOptionScreen.new(PokemonOption_Scene.new).pbStartScreen; pbUpdateSceneMap }
    when :save
      PokemonSaveScreen.new(PokemonSave_Scene.new).pbSaveScreen
      menu_proxy.pbRefresh
    else
      pbPlayBuzzerSE
    end
  end

  # ==============================================================
  # Loop principal (refactor: separar inputs y sprites para mayor claridad)
  # ==============================================================
  def pbUpdate
    loop do
      Graphics.update
      Input.update
      update_sprites
      update_inputs
      break if @finished
    end
  end

  # Se encarga de actualizar sprites y sidebar (equivalente al comportamiento previo)
  def update_sprites
    pbUpdateSpriteHash(@sprites)
    @sidebar.update if @sidebar
    update_party_sidebar
  end

  # Se encarga únicamente de procesar inputs/navegación
  def update_inputs
    if @switching_original
      handle_switch_input
      update_party_selection_visual
      return
    end

    @focus == :options ? handle_menu_input : handle_party_input
    update_party_selection_visual
  end

  # ==============================================================
  # Manejo de inputs
  # ==============================================================
  def handle_switch_input
    if Input.trigger?(Input::UP)
      newidx = next_valid_party_index(-1)
      if newidx >= 0
        # Si nos estamos moviendo fuera del slot origen, quitar su highlight
        if @switching_original && newidx != @switching_original
          @sidebar.moving_index = nil if @sidebar && @sidebar.respond_to?(:moving_index=)
        end
        @party_index = newidx
      end

    elsif Input.trigger?(Input::DOWN)
      newidx = next_valid_party_index(1)
      if newidx >= 0
        if @switching_original && newidx != @switching_original
          @sidebar.moving_index = nil if @sidebar && @sidebar.respond_to?(:moving_index=)
        end
        @party_index = newidx
      end

    elsif Input.trigger?(Input::USE)
      target = @party_index
      if target>=0 && target != @switching_original && $player.party[target]
        old_idx = @switching_original
        new_idx = target

        # Intercambio real
        $player.party[old_idx], $player.party[new_idx] = $player.party[new_idx], $player.party[old_idx]
        pbSEPlay("GUI party switch") if respond_to?(:pbSEPlay)

        # Avisar al sidebar del swap (ya borra moving_index internamente)
        @sidebar.on_party_order_changed(old_idx, new_idx) if @sidebar && @sidebar.respond_to?(:on_party_order_changed)

        # Limpiar modo movimiento
        @switching_original = nil

        # Seleccionar el slot destino
        @party_index = new_idx
      else
        pbPlayBuzzerSE if respond_to?(:pbPlayBuzzerSE)
      end

    elsif Input.trigger?(Input::BACK)
      @switching_original = nil
      @sidebar.moving_index = nil if @sidebar && @sidebar.respond_to?(:moving_index=)
    end
  end

  def handle_menu_input
    if Input.trigger?(Input::UP)
      @select = (@select-1) % @menu_options.length
      redraw_menu_panel
    elsif Input.trigger?(Input::DOWN)
      @select = (@select+1) % @menu_options.length
      redraw_menu_panel
    elsif Input.trigger?(Input::USE)
      perform_menu_action(@select)
    elsif Input.trigger?(Input::LEFT) && defined?(SHOW_POKEMON_TEAM) && SHOW_POKEMON_TEAM && $player.party.any?
      @focus = :party
      @party_index = first_valid_party_index
    elsif Input.trigger?(Input::BACK)
      break_scene
    end
  end

  def handle_party_input
    if Input.trigger?(Input::UP)
      newidx = next_valid_party_index(-1)
      @party_index = newidx if newidx>=0
    elsif Input.trigger?(Input::DOWN)
      newidx = next_valid_party_index(1)
      @party_index = newidx if newidx>=0
    elsif Input.trigger?(Input::USE)
      pbOpenPartyContextMenu(@party_index) if $player.party[@party_index]
    elsif Input.trigger?(Input::RIGHT) || Input.trigger?(Input::BACK)
      @focus = :options
      redraw_menu_panel
    end
  end

  def break_scene
    @finished = true
  end

  # ==============================================================
  # Cierre de escena
  # ==============================================================
  def pbEndScene
    dispose_party_sidebar
    @icon_bitmaps&.each_value { |b| b.dispose if b && !b.disposed? }
    @highlight_bitmap&.dispose if @highlight_bitmap && !@highlight_bitmap.disposed?
    @context_bg_bitmap&.dispose if @context_bg_bitmap && !@context_bg_bitmap.disposed?
    @context_highlight_bitmap&.dispose if @context_highlight_bitmap && !@context_highlight_bitmap.disposed?
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport && !@viewport.disposed?
  end
end

# ==============================================================
# Wrapper
# ==============================================================
class MenuCustom
  def initialize(scene); @scene = scene; end
  def pbStartPokemonMenu; @scene.pbStartScene; @scene.pbUpdate; @scene.pbEndScene; end
end

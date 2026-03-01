#===============================================================================
#
#===============================================================================
class UI::MoveReminderCursor < IconSprite
  attr_accessor :top_index

  CURSOR_WIDTH     = 238
  CURSOR_HEIGHT    = 66
  CURSOR_THICKNESS = 6

  def initialize(viewport = nil)
    super(0, 0, viewport)
    setBitmap("Graphics/UI/Move Reminder/cursor")
    self.src_rect = Rect.new(0, 0, CURSOR_WIDTH, CURSOR_HEIGHT)
    self.z = 50
    @bg_sprite = IconSprite.new(x, y, viewport)
    @bg_sprite.setBitmap("Graphics/UI/Move Reminder/cursor")
    @bg_sprite.src_rect = Rect.new(0, CURSOR_HEIGHT, CURSOR_WIDTH, CURSOR_HEIGHT)
    @top_index = 0
    self.index = 0
  end

  def dispose
    @bg_sprite.dispose
    @bg_sprite = nil
    super
  end

  def index=(value)
    @index = value
    refresh_position
  end

  def visible=(value)
    super
    @bg_sprite.visible = value
  end

def refresh_position
  return if @index < 0
  self.x = UI::MoveReminderVisuals::MOVE_LIST_X + 62 - 2

  vertical_offset = 2   # <- cambia este valor para subir más/menos
  base_y = UI::MoveReminderVisuals::MOVE_LIST_Y + CURSOR_THICKNESS - vertical_offset

  self.y = base_y + (@index - @top_index) * UI::MoveReminderVisuals::MOVE_LIST_SPACING
  @bg_sprite.x = self.x
  @bg_sprite.y = self.y
end

end

#===============================================================================
#
#===============================================================================
class UI::MoveReminderVisuals < UI::BaseVisuals
  attr_reader :index

  GRAPHICS_FOLDER   = "Move Reminder/"   # Subfolder in Graphics/UI
  TEXT_COLOR_THEMES = {   # These color themes are added to @sprites[:overlay]
    :default  => [Color.new(248, 248, 248), Color.new(74, 112, 175)],   # Base and shadow colour
    :white    => [Color.new(248, 248, 248), Color.new(0, 0, 0)],
    :black    => [Color.new(64, 64, 64),   Color.new(176, 176, 176)],
    :header   => [Color.new(88, 88, 80),   Color.new(168, 184, 184)],
    # Tema para fila seleccionada (colores que solicitaste)
    #:selected => TEXT_COLOR_THEMES[:default]
  }
  MOVE_LIST_X        = 0-16
  MOVE_LIST_Y        = 84
  MOVE_LIST_SPACING  = 64    # Y distance between top of two adjacent move areas
  VISIBLE_MOVES      = 4
  TYPE_ICONS_X       = 340 + 98
  TYPE_ICONS_Y       = 70 - 5
  TYPE_ICONS_SPACING = -36
  POKEMON_ICON_X     = 354 + 8
  POKEMON_ICON_Y     = 84 - 17
  HEADER_X           = 16
  HEADER_Y           = 40
  BUTTON_UP_HEIGHT   = 32
  BUTTON_UP_WIDTH    = 76
  BUTTON_UP_X        = 44
  BUTTON_UP_Y        = 350
  BUTTON_DOWN_HEIGHT = 32
  BUTTON_DOWN_WIDTH  = 76
  BUTTON_DOWN_X      = 132
  BUTTON_DOWN_Y      = 350
  TYPE_ICON_WIDTH  = 24
  TYPE_ICON_HEIGHT = 30

  def initialize(pokemon, moves)
    @pokemon   = pokemon
    @moves     = moves
    @top_index = 0
    @index     = 0
    super()
    refresh_cursor
  end

  def initialize_bitmaps
    @bitmaps[:types]   = AnimatedBitmap.new(UI_FOLDER + _INTL("types_mini"))
    @bitmaps[:types_pokemon] = AnimatedBitmap.new(UI_FOLDER + _INTL("types"))
    @bitmaps[:buttons] = AnimatedBitmap.new(graphics_folder + "buttons")
  end

  def initialize_sprites
    # Pokémon icon
    @sprites[:pokemon_icon] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites[:pokemon_icon].setOffset(PictureOrigin::CENTER)
    @sprites[:pokemon_icon].x = POKEMON_ICON_X
    @sprites[:pokemon_icon].y = POKEMON_ICON_Y
    @sprites[:pokemon_icon].z = 200
    # Cursor
    @sprites[:cursor] = UI::MoveReminderCursor.new(@viewport)
  end

  #-----------------------------------------------------------------------------

  def moves=(move_list)
    @moves = move_list
    @index = @moves.length - 1 if @index >= @moves.length
    refresh_on_index_changed(@index)
    @cursor.visible = false if @moves.empty?
    refresh
  end

  #-----------------------------------------------------------------------------

  def refresh_overlay
    super
    draw_header
    draw_pokemon_type_icons(TYPE_ICONS_X, TYPE_ICONS_Y, TYPE_ICONS_SPACING)
    draw_moves_list
    draw_move_properties
    draw_buttons
  end

  def draw_header
    # Título (igual que antes)
    draw_text(_INTL("¿Enseñar movimiento?"), HEADER_X, HEADER_Y, theme: :default)
    # Nombre del Pokémon (posición clásica)
    draw_text(@pokemon.name, 336+50+12, 38-2, theme: :black)
    # Icono de género (si aplica)
    if @pokemon.male?
      draw_image("Graphics/UI/Summary/icon_genders", 336+42+20-8-2, 68-2, 0, 0, 22, 22)
    elsif @pokemon.female?
      draw_image("Graphics/UI/Summary/icon_genders", 336+42+20-8-2, 68-2, 22, 0, 22, 22)
    end
  end

  # x and y are the top left corner of the type icon if there is only one type.
def draw_pokemon_type_icons(x, y, spacing)
  diff = PluginManager.installed?("[DBK] Terastallization") && @pokemon.tera_type ? 36 : 0
  @pokemon.types.each_with_index do |type, i|
    type_number = GameData::Type.get(type).icon_position
    type_x = (@pokemon.types.length == 1) ? 352+70-6 : 352+70-6 + (110 * i)
    draw_image(@bitmaps[:types_pokemon], type_x, 66,
               0, type_number * 28, 100, 28)
  end
end

  def draw_moves_list
    VISIBLE_MOVES.times do |i|
      move = @moves[@top_index + i]
      next if move.nil?
      # Pasamos i como visible_index para que draw_move_in_list sepa la posición relativa
      draw_move_in_list(move, MOVE_LIST_X, MOVE_LIST_Y + (i * MOVE_LIST_SPACING), i)
    end
  end

  # draw_move_in_list ahora recibe visible_index (0..VISIBLE_MOVES-1)
  def draw_move_in_list(move, x, y, visible_index)
    move_data = GameData::Move.get(move[0])

    # --- Dibuja el icono del tipo ---
    type_number = GameData::Type.get(move_data.display_type(@pokemon)).icon_position
    draw_image(@bitmaps[:types], x + 64, y + 10,
               type_number * TYPE_ICON_WIDTH, 0,
           TYPE_ICON_WIDTH, TYPE_ICON_HEIGHT)

    # --- Preparar nombre del movimiento ---
    move_name = move_data.name
    move_name = crop_text(move_name, 230)

    # --- Determinar si está seleccionado (comparando índice global) ---
    selected = (@index == @top_index + visible_index)

    # --- Usar tema :selected si está seleccionado, otherwise :default ---
    theme_to_use = (selected ? :selected : :default)

    # --- Dibuja el nombre del movimiento usando el tema correspondiente ---
    draw_text(move_name, x + 64 + GameData::Type::ICON_SIZE[0] - 36, y + 12, theme: theme_to_use)

    # --- Dibuja nivel o TM/HM ---
    draw_text(move[1], x + 70, y + 42, theme: :default) if move[1]

    # --- Dibuja PP ---
    if move_data.total_pp > 0
      draw_text(sprintf("PP", move_data.total_pp, move_data.total_pp),
                x + 150 + 12+14+24, y + 40, align: :right, theme: :default)
      draw_text(sprintf("%d/%d", move_data.total_pp, move_data.total_pp),
                x + 260 + 12+14, y + 40, align: :right, theme: :default)
    end
  end

  def draw_move_properties
    move = @moves[@index]
    move_data = GameData::Move.get(move[0])

    # --- Clase / Categoría ---
    draw_text(_INTL("Clase"), 330, 120, theme: :black)
    draw_image(UI_FOLDER + "category", 466+98, 114,
               0, move_data.display_category(@pokemon) * GameData::Move::CATEGORY_ICON_SIZE[1],
               *GameData::Move::CATEGORY_ICON_SIZE)

    # --- Potencia ---
    draw_text(_INTL("Potencia"), 330, 152, theme: :black)
    power_text = move_data.display_power(@pokemon)
    power_text = "---" if power_text == 0
    power_text = "???" if power_text == 1
    draw_text(power_text, 520+99+2, 152, align: :right, theme: :black)

    # --- Precisión ---
    draw_text(_INTL("Precisión"), 330, 184, theme: :black)
    accuracy = move_data.display_accuracy(@pokemon)
    if accuracy == 0
      draw_text("---", 520+99+2, 184, align: :right, theme: :black)
    else
      draw_text(accuracy, 520+99-3, 184, align: :right, theme: :black)
      draw_text("%", 520+99-3, 184, theme: :black)
    end

    # --- Descripción ---
    draw_paragraph_text(move_data.description, 335, 235, 235, 5, theme: :black)
  end

  def draw_buttons
    return if @bitmaps[:buttons].nil?

    if @top_index < @moves.length - VISIBLE_MOVES
      draw_image(@bitmaps[:buttons], 44-16, 350-31, 0, 0, 20, 20)
    end
    if @top_index > 0
      draw_image(@bitmaps[:buttons], 44-16, 75+17, 20, 0, 20, 20)
    end
  end

  #-----------------------------------------------------------------------------

  def refresh_cursor
    @sprites[:cursor].top_index = @top_index
    @sprites[:cursor].index = @index
  end

  def refresh_on_index_changed(old_index)
    pbPlayCursorSE if old_index != @index && defined?(old_index)
    middle_range_top = (VISIBLE_MOVES / 2) - ((VISIBLE_MOVES + 1) % 2)
    middle_range_bottom = VISIBLE_MOVES / 2
    if @index < @top_index + middle_range_top
      @top_index = @index - middle_range_top
    elsif @index > @top_index + middle_range_bottom
      @top_index = @index - middle_range_bottom
    end
    @top_index = @top_index.clamp(0, [@moves.length - VISIBLE_MOVES, 0].max)
    refresh_cursor
    refresh
  end

  #-----------------------------------------------------------------------------
  def update_input
    update_cursor_movement
    if Input.trigger?(Input::USE)
      return update_interaction(Input::USE)
    elsif Input.trigger?(Input::BACK)
      return update_interaction(Input::BACK)
    elsif Input.trigger?(Input::ACTION)
      return update_interaction(Input::ACTION)
    end
    return nil
  end

  def update_cursor_movement
    old_index = @index
    if Input.repeat?(Input::UP)
      @index -= 1
      if Input.trigger?(Input::UP)
        @index = @moves.length - 1 if @index < 0
      else
        @index = 0 if @index < 0
      end
    elsif Input.repeat?(Input::DOWN)
      @index += 1
      if Input.trigger?(Input::DOWN)
        @index = 0 if @index >= @moves.length
      else
        @index = @moves.length - 1 if @index >= @moves.length
      end
    elsif Input.repeat?(Input::JUMPUP)
      @index -= VISIBLE_MOVES
      @index = 0 if @index < 0
    elsif Input.repeat?(Input::JUMPDOWN)
      @index += VISIBLE_MOVES
      @index = @moves.length - 1 if @index >= @moves.length
    end
    if old_index != @index
      refresh_on_index_changed(old_index)
    end
    return old_index != @index
  end

  def update_interaction(input)
    case input
    when Input::USE
      pbPlayDecisionSE
      return :learn
    when Input::BACK
      pbPlayCloseMenuSE
      return :quit
    end
    return nil
  end
end






#===============================================================================
#
#===============================================================================
class UI::MoveReminder < UI::BaseScreen
  attr_reader :pokemon

    ACTIONS = {
    :learn => {
      :effect => proc { |screen|
        move = screen.move
        if screen.show_confirm_message(_INTL("¿Enseñar {1}?", GameData::Move.get(move[0]).name))
          is_machine = move[1] ? true : false
          if pbLearnMove(screen.pokemon, move[0], false, is_machine)
            $stats.moves_taught_by_reminder += 1 if !is_machine
            $stats.moves_taught_by_item += 1 if is_machine
            if screen.mode == :normal
              screen.refresh_move_list
            else
              screen.end_screen
            end
          end
        end
      }
    }
  }

  # mode is either :normal or :single.
  def initialize(pokemon, mode: :normal)
    @pokemon = pokemon
    @mode = mode
    @moves = []
    @result = nil
    generate_move_list
    super()
  end

  def initialize_visuals
    @visuals = UI::MoveReminderVisuals.new(@pokemon, @moves)
  end

  #-----------------------------------------------------------------------------

  def generate_move_list
    @moves = []
    return if !@pokemon || @pokemon.egg? || @pokemon.shadowPokemon?
    @pokemon.getMoveList.each do |move|
      next if move[0] > @pokemon.level || @pokemon.hasMove?(move[1])
      # @moves.push(move[1]) if !@moves.include?(move[1])
      move_to_add = move.is_a?(GameData::Move) ? move.id : move[1]
      @moves << [move_to_add, "Nv. #{move[0].to_i.abs}"] if !@moves.include?(move_to_add)
    end
    if Settings::MOVE_RELEARNER_CAN_TEACH_MORE_MOVES && @pokemon.first_moves
      first_moves = []
      @pokemon.first_moves.each do |move|
        first_moves.push([move, "Nv. 1"]) if !@moves.any? { |m| m[0] == move } && !@pokemon.hasMove?(move)
      end
      @moves = first_moves + @moves   # List first moves before level-up moves
    end
    @moves = @moves.uniq { |move| move[0] }   # remove duplicates based on move ID

    if Settings::SHOW_MTS_MOS_IN_MOVE_RELEARNER
      tms = pbGetTMMoves(@pokemon)
      for tm in tms
        if !@moves.any? { |m| m[0] == tm[0] }
            @moves.push([tm[0], tm[1]])
        end
      end
    end

  end

  def refresh_move_list
    generate_move_list
    @visuals.moves = @moves
  end

  #-----------------------------------------------------------------------------

  def move
    return @moves[self.index]
  end

  #-----------------------------------------------------------------------------

  def main
    return if @disposed
    start_screen
    @visuals.refresh if @visuals
    Graphics.update
    loop do
      on_start_main_loop
      command = @visuals.navigate
      break if command == :quit && (@mode == @normal ||
               show_confirm_message(_INTL("¿Prefieres que {1} no aprenda un movimiento nuevo?", @pokemon.name)))
      perform_action(command)
      if @moves.empty?
        show_message(_INTL("No hay más movimientos para que {1} aprenda.", @pokemon.name))
        break
      end
      if @disposed
        @result = true
        break
      end
    end
    end_screen
    return @result
  end
end

#===============================================================================
# Actions that can be triggered in the Move Reminder screen.
#===============================================================================


#===============================================================================
#
#===============================================================================
def pbRelearnMoveScreen(pkmn)
  ret = true
  pbFadeOutIn do
    mode = Settings::CLOSE_MOVE_RELEARNER_AFTER_TEACHING_MOVE ? :single : :normal
    ret = UI::MoveReminder.new(pkmn, mode: mode).main
  end
  return ret
end

def pbGetTMMoves(pokemon)
  tmmoves = []
  for item_aux in $bag.pockets[4]
    item = GameData::Item.get(item_aux[0])
    if item.is_machine?
      machine = item.move
      tmorhm = item.is_HM? ? "MO" : "MT"
      if pokemon.compatible_with_move?(machine) && !pokemon.hasMove?(machine)
        tmmoves.push([machine, tmorhm])
      end
    end
  end
  return tmmoves
end

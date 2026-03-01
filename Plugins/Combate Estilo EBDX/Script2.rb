#=============================================================================
#   #BOTONES ATAQUES HORIZONTAL
#=============================================================================
class Battle::Scene::FightMenu < Battle::Scene::MenuBase
  GET_MOVE_TEXT_COLOR_FROM_MOVE_BUTTON = false
end

class Battle::Scene::MenuBase
  BUTTON_HEIGHT = 40
  TEXT_BASE_COLOR   = Color.new(255, 255, 255)
  TEXT_SHADOW_COLOR = Color.new(32, 32, 32)
end

class Battle::Scene::FightMenu < Battle::Scene::MenuBase
  def initialize(viewport, z)
    super(viewport)
    self.x = 0
    self.y = Graphics.height - 94
    @battler = nil
    resetMenuToggles
    @customUI = PluginManager.installed?("Customizable Battle UI")
    folder = @customUI ? "#{$game_variables[53]}/" : ""
    path = "Graphics/UI/Battle/" + folder

    if USE_GRAPHICS
      @buttonBitmap  = AnimatedBitmap.new(_INTL(path + "cursor_fight"))
      @typeBitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
      @shiftBitmap   = AnimatedBitmap.new(_INTL(path + "cursor_shift"))
      @actionButtonBitmap = {}
      addSpecialActionButtons(path)

      background = IconSprite.new(0, Graphics.height - 96, viewport)
      background.setBitmap(path + "overlay_fight")
      addSprite("background", background)

      button_width = 254
      button_height = 40
      spacing_x = button_width + 4
      spacing_y = button_height + 4
      total_width = 2 * spacing_x
      start_x = (Graphics.width - total_width) / 2

      @buttons = Array.new(Pokemon::MAX_MOVES) do |i|
        button = Sprite.new(viewport)
        button.bitmap = @buttonBitmap.bitmap
        row = i / 2
        col = i % 2
        button.x = (start_x + col * spacing_x) + 2
        button.y = self.y + 4 + row * spacing_y
        button.src_rect.width = button_width
        button.src_rect.height = button_height
        addSprite("button_#{i}", button)
        next button
      end

      @overlay = BitmapSprite.new(Graphics.width, Graphics.height - self.y, viewport)
      @overlay.x = self.x
      @overlay.y = self.y
      pbSetNarrowFont(@overlay.bitmap)
      addSprite("overlay", @overlay)

      @infoOverlay = BitmapSprite.new(Graphics.width, Graphics.height - self.y, viewport)
      @infoOverlay.x = self.x
      @infoOverlay.y = self.y
      pbSetNarrowFont(@infoOverlay.bitmap)
      addSprite("infoOverlay", @infoOverlay)

      @typeIcon = Sprite.new(viewport)
      @typeIcon.bitmap = @typeBitmap.bitmap
      @typeIcon.x = self.x + 416
      @typeIcon.y = self.y + 20
      @typeIcon.src_rect.height = TYPE_ICON_HEIGHT
      addSprite("typeIcon", @typeIcon)

      @actionButton = Sprite.new(viewport)
      addSprite("actionButton", @actionButton)

      @shiftButton = Sprite.new(viewport)
      @shiftButton.bitmap = @shiftBitmap.bitmap
      @shiftButton.x = self.x + 4
      @shiftButton.y = self.y - @shiftBitmap.height
      addSprite("shiftButton", @shiftButton)
    end
    self.z = z
  end

  #--------------------------------
  # NOMBRES — COLOR FIJO
  def refreshButtonNames
    moves = (@battler) ? @battler.moves : []
    return if !USE_GRAPHICS
    @overlay.bitmap.clear
    textPos = []
@buttons.each_with_index do |button, i|
  next if !@visibility["button_#{i}"]
  move = moves[i]
  next if !move   # <-- ESTA LÍNEA ES LA CLAVE

  x = button.x - self.x + 20
  y = button.y - self.y + 11

  base   = Color.new(30,30,30)
  shadow = Color.new(220,220,220)

  textPos.push([move.short_name, x, y, :left, base, shadow])
end
    pbDrawTextPositions(@overlay.bitmap, textPos)
  end

  #--------------------------------
  # PP — COLOR FIJO
  def refreshMoveData(_move = nil)
    return if !USE_GRAPHICS
    @infoOverlay.bitmap.clear
    moves = (@battler) ? @battler.moves : []
    moves.each_with_index do |move, i|
      next if !move
      button = @buttons[i]
      next if !button

      pp_text = _INTL("{1}/{2}", move.pp, move.total_pp)
      x = button.x - self.x + button.src_rect.width - 43
      y = button.y - self.y + 11

      base   = Color.new(0,0,0)
      shadow = Color.new(255,255,255)

      pbDrawTextPositions(@infoOverlay.bitmap, [[pp_text, x, y, :center, base, shadow]])
    end

    @visibility["typeIcon"] = false
  end

  #--------------------------------
  def refreshSelection
    moves = (@battler) ? @battler.moves : []
    @buttons.each_with_index do |button, i|
      next if !moves[i]
      @visibility["button_#{i}"] = true
      button.src_rect.x = (i == @index) ? @buttonBitmap.width / 2 : 0
      button.src_rect.y = GameData::Type.get(moves[i].display_type(@battler)).icon_position * @buttonBitmap.height / 19
      button.z = self.z + ((i == @index) ? 4 : 3)
    end
    refreshMoveData(moves[@index])
  end
end
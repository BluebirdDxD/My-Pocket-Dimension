#=============================================================================
# COMBATE HORIZONTAL
# EDITADO — botones bajos + texto visible sobre overlay
#=============================================================================
class Battle::Scene
  def pbSafariStart
    @briefMessage = false
    @sprites["dataBox_0"] = SafariDataBox.new(@battle, @viewport)
    dataBoxAnim = Animation::DataBoxAppear.new(@sprites, @viewport, 0)
    loop do
      dataBoxAnim.update
      pbUpdate
      break if dataBoxAnim.animDone?
    end
    dataBoxAnim.dispose
    pbRefresh
  end

  def pbSafariCommandMenu(index)
    pbCommandMenuEx(index,
      ["", _INTL("Ball"), _INTL("Cebo"), _INTL("Roca"), _INTL("Huir")], 3)
  end

  def pbCommandMenu(idxBattler, firstAction)
    shadowTrainer = (GameData::Type.exists?(:SHADOW) && @battle.trainerBattle?)
    cmds = [
      "",
      _INTL("Luchar"),
      _INTL("Mochila"),
      _INTL("Pokémon"),
      (shadowTrainer) ? _INTL("Llamar") : (firstAction) ? _INTL("Huir") : _INTL("Cancelar")
    ]
    ret = pbCommandMenuEx(idxBattler, cmds, (shadowTrainer) ? 2 : (firstAction) ? 0 : 1)
    ret = 4 if ret == 3 && shadowTrainer
    ret = -1 if ret == 3 && !firstAction
    return ret
  end

#=============================================================================
# COMMAND MENU
#=============================================================================
class Battle::Scene::CommandMenu < Battle::Scene::MenuBase
  USE_GRAPHICS = true

  BUTTON_Y_OFFSET = 18

  MODES = [
    [0,2,1,3],
    [0,2,1,9],
    [0,2,1,4],
    [5,7,6,3],
    [0,8,1,3]
  ]

  def initialize(viewport, z)
    super(viewport)
    self.x = 0
    self.y = Graphics.height - 96   # ← NO mover
# dummy msgBox para compatibilidad con otros scripts
@msgBox = Window_UnformattedTextPokemon.new("")
@msgBox.visible = false
addSprite("msgBox", @msgBox)

    if USE_GRAPHICS
      # ===== OVERLAY EDITABLE =====
      background = IconSprite.new(self.x, self.y, viewport)
      base = RPG::Cache.load_bitmap("Graphics/UI/Battle/", "overlay_command")
      @overlayBitmap = Bitmap.new(base.width, base.height)
      @overlayBitmap.blt(0, 0, base, base.rect)
      background.bitmap = @overlayBitmap
      addSprite("background", background)

      @buttonBitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Battle/cursor_command"))

      button_width = 123
      spacing = 4
      total = (button_width + spacing) * 4 - spacing
      start_x = (Graphics.width - total) / 2

      @buttons = Array.new(4) do |i|
        b = Sprite.new(viewport)
        b.bitmap = @buttonBitmap.bitmap
        b.x = start_x + i * (button_width + spacing)
        b.y = (self.y + Graphics.width - 640) + 4 + BUTTON_Y_OFFSET
        b.src_rect.width  = button_width
        b.src_rect.height = 84
        addSprite("button_#{i}", b)
        b
      end
    else
      @cmdWindow = Window_CommandPokemon.newWithSize(
        [], self.x + Graphics.width - 640, self.y, 640, Graphics.height - 84, viewport
      )
      @cmdWindow.ignore_input = true
      addSprite("cmdWindow", @cmdWindow)
    end

    self.z = z
    refresh
  end

  # ===== TEXTO SOBRE OVERLAY =====
  def drawActionPrompt(text)
    return if !@overlayBitmap
    base = RPG::Cache.load_bitmap("Graphics/UI/Battle/", "overlay_command")
    @overlayBitmap.clear
    @overlayBitmap.blt(0, 0, base, base.rect)

    pbSetSystemFont(@overlayBitmap)
    w = @overlayBitmap.text_size(text).width
    x = (@overlayBitmap.width - w) / 2
    y = 4

    pbDrawTextPositions(@overlayBitmap, [
      [text, x, y, :left, Color.new(255,255,255), Color.new(0,0,0)]
    ])
  end

  def dispose
    super
    @buttonBitmap&.dispose
    @overlayBitmap&.dispose
  end

  def refreshButtons
    return if !USE_GRAPHICS
    @buttons.each_with_index do |button, i|
      button.src_rect.x = (i == @index) ? @buttonBitmap.width/2 : 0
      button.src_rect.y = MODES[@mode][i] * 84
      button.z = self.z + ((i == @index) ? 3 : 2)
    end
  end

  def refresh
    @cmdWindow&.refresh
    refreshButtons
  end
end

#=============================================================================
# MENÚ — TEXTO DINÁMICO
#=============================================================================
def pbCommandMenuEx(idxBattler, texts, mode = 0)
  battler = @battle.battlers[idxBattler]
  texts[0] = _INTL("¿Qué hará {1}?", battler.name)

  pbRefreshUIPrompt(idxBattler, COMMAND_BOX)
  pbShowWindow(COMMAND_BOX)
  cw = @sprites["commandWindow"]
  cw.setTexts(texts)
  cw.drawActionPrompt(texts[0]) if cw.respond_to?(:drawActionPrompt)
  cw.setIndexAndMode(@lastCmd[idxBattler], mode)
  pbSelectBattler(idxBattler)

  loop do
    old = cw.index
    pbUpdate(cw)

    cw.index = (cw.index + 3) % 4 if Input.trigger?(Input::LEFT)
    cw.index = (cw.index + 1) % 4 if Input.trigger?(Input::RIGHT)
    pbPlayCursorSE if cw.index != old

    if Input.trigger?(Input::USE)
      pbPlayDecisionSE
      @lastCmd[idxBattler] = cw.index
      return cw.index
    elsif Input.trigger?(Input::BACK) && mode > 0
      pbPlayCancelSE
      return -1
    end
  end
end
end

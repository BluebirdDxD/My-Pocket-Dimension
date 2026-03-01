class Battle::Scene::AbilitySplashBar < Sprite
  attr_reader :battler
  TEXT_BASE_COLOR   = Color.new(0, 0, 0)
  TEXT_SHADOW_COLOR = Color.new(248, 248, 248)
  def initialize(side, viewport = nil)
    super(viewport)
    @side    = side
    @battler = nil
    @bgBitmap = AnimatedBitmap.new("Graphics/UI/Battle/ability_bar")
    @bgSprite = Sprite.new(viewport)
    @bgSprite.bitmap = @bgBitmap.bitmap
    @bgSprite.src_rect.y      = (side == 0) ? 0 : @bgBitmap.height / 2
    @bgSprite.src_rect.height = @bgBitmap.height / 2
    @contents = Bitmap.new(@bgBitmap.width, @bgBitmap.height / 2)
    self.bitmap = @contents
    pbSetSystemFont(self.bitmap)
    @iconSprite = Sprite.new(viewport)
    @iconSprite.z = 121
    @iconSprite.visible = false
    self.x       = ((side == 0) ? -Graphics.width / 2 : Graphics.width + 64)
    self.y       = (side == 0) ? 180 : 80
    self.z       = 120
    self.visible = false
  end
  def dispose
    @iconSprite.dispose if @iconSprite
    @bgSprite.dispose
    @bgBitmap.dispose
    @contents.dispose
    super
  end
  def x=(value)
    super
    @bgSprite.x = value
    updateIconPosition
  end
  def y=(value)
    super
    @bgSprite.y = value
    updateIconPosition
  end
  def z=(value)
    super
    @bgSprite.z = value - 1
    @iconSprite.z = value + 1 if @iconSprite
  end
  def opacity=(value)
    super
    @bgSprite.opacity = value
    @iconSprite.opacity = value if @iconSprite
  end
  def visible=(value)
    super
    @bgSprite.visible = value
    @iconSprite.visible = value if @iconSprite
  end
  def color=(value)
    super
    @bgSprite.color = value
    @iconSprite.color = value if @iconSprite
  end
  def battler=(value)
    @battler = value
    refresh
  end
  def updateIconPosition
    return if !@iconSprite || !@battler
    if @side == 0

      @iconSprite.x = self.x + 42
      @iconSprite.y = self.y + 15
    else

      @iconSprite.x = self.x + self.bitmap.width - 86
      @iconSprite.y = self.y + 15
    end
  end
  def refresh
    self.bitmap.clear
    return if !@battler

    if @iconSprite
      @iconSprite.bitmap&.dispose
      fullBitmap = GameData::Species.icon_bitmap(@battler.displaySpecies, @battler.displayForm)

      @iconSprite.bitmap = Bitmap.new(fullBitmap.width / 2, fullBitmap.height)
      @iconSprite.bitmap.blt(0, 0, fullBitmap, Rect.new(0, 0, fullBitmap.width / 2, fullBitmap.height))
      updateIconPosition
    end
    
    textPos = []
    textX = (@side == 0) ? 10 : self.bitmap.width - 8
    align = (@side == 0) ? :left : :right

    textPos.push([@battler.abilityName, textX, 8, align,
                  TEXT_BASE_COLOR, TEXT_SHADOW_COLOR, :outline])

    textPos.push([_INTL("de"), textX, 38, align,
                  TEXT_BASE_COLOR, TEXT_SHADOW_COLOR, :outline])
    pbDrawTextPositions(self.bitmap, textPos)
  end
  def update
    super
    @bgSprite.update
    @iconSprite.update if @iconSprite
  end
end
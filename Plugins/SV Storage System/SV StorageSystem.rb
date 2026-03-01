#===============================================================================
# Pokémon icons
#===============================================================================
#===============================================================================
# Pokémon icons con Pokéball y género
#===============================================================================
class PokemonBoxIcon < IconSprite
  def initialize(pokemon, viewport = nil)
    super(0, 0, viewport)
    @pokemon = pokemon
    @release_timer_start = nil
    @pokeball_sprite = nil
    @gender_sprite  = nil
    refresh
  end

  def releasing?
    return !@release_timer_start.nil?
  end

  def release
    self.ox = self.src_rect.width / 2
    self.oy = self.src_rect.height / 2
    self.x += self.src_rect.width / 2
    self.y += self.src_rect.height / 2
    @release_timer_start = System.uptime
  end

  def refresh
    return if !@pokemon
    self.setBitmap(GameData::Species.icon_filename_from_pokemon(@pokemon))
    self.src_rect = Rect.new(0, 0, self.bitmap.height, self.bitmap.height)
  end

  def update
    super
    self.color = Color.new(0, 0, 0, 0)
    if releasing?
      time_now = System.uptime
      self.zoom_x = lerp(1.0, 0.0, 1.5, @release_timer_start, System.uptime)
      self.zoom_y = self.zoom_x
      self.opacity = lerp(255, 0, 1.5, @release_timer_start, System.uptime)
      if self.opacity == 0
        @release_timer_start = nil
        dispose
      end
    end
  end
end


#===============================================================================
# Pokémon sprite
#===============================================================================
class MosaicPokemonSprite < PokemonSprite
  attr_reader :mosaic

  def initialize(*args)
    super(*args)
    @mosaic = 0
    @inrefresh = false
    @mosaicbitmap = nil
    @mosaicbitmap2 = nil
    @oldbitmap = self.bitmap
  end

  def dispose
    super
    @mosaicbitmap&.dispose
    @mosaicbitmap = nil
    @mosaicbitmap2&.dispose
    @mosaicbitmap2 = nil
  end

  def bitmap=(value)
    super
    mosaicRefresh(value)
  end

  def mosaic=(value)
    @mosaic = value
    @mosaic = 0 if @mosaic < 0
    mosaicRefresh(@oldbitmap)
  end

  def mosaicRefresh(bitmap)
    return if @inrefresh
    @inrefresh = true
    @oldbitmap = bitmap
    if @mosaic <= 0 || !@oldbitmap
      @mosaicbitmap&.dispose
      @mosaicbitmap = nil
      @mosaicbitmap2&.dispose
      @mosaicbitmap2 = nil
      self.bitmap = @oldbitmap
    else
      newWidth  = [(@oldbitmap.width / @mosaic), 1].max
      newHeight = [(@oldbitmap.height / @mosaic), 1].max
      @mosaicbitmap2&.dispose
      @mosaicbitmap = pbDoEnsureBitmap(@mosaicbitmap, newWidth, newHeight)
      @mosaicbitmap.clear
      @mosaicbitmap2 = pbDoEnsureBitmap(@mosaicbitmap2, @oldbitmap.width, @oldbitmap.height)
      @mosaicbitmap2.clear
      @mosaicbitmap.stretch_blt(Rect.new(0, 0, newWidth, newHeight), @oldbitmap, @oldbitmap.rect)
      @mosaicbitmap2.stretch_blt(
        Rect.new((-@mosaic / 2) + 1, (-@mosaic / 2) + 1, @mosaicbitmap2.width, @mosaicbitmap2.height),
        @mosaicbitmap, Rect.new(0, 0, newWidth, newHeight)
      )
      self.bitmap = @mosaicbitmap2
    end
    @inrefresh = false
  end
end

#===============================================================================
#
#===============================================================================
class AutoMosaicPokemonSprite < MosaicPokemonSprite
  INITIAL_MOSAIC = 10   # Pixellation factor

  def mosaic=(value)
    @mosaic = value
    @mosaic = 0 if @mosaic < 0
    @start_mosaic = @mosaic if !@start_mosaic
  end

  def mosaic_duration=(val)
    @mosaic_duration = val
    @mosaic_duration = 0 if @mosaic_duration < 0
    @mosaic_timer_start = System.uptime if @mosaic_duration > 0
  end

  def update
    super
    if @mosaic_timer_start
      @start_mosaic = INITIAL_MOSAIC if !@start_mosaic || @start_mosaic == 0
      new_mosaic = lerp(@start_mosaic, 0, @mosaic_duration, @mosaic_timer_start, System.uptime).to_i
      self.mosaic = new_mosaic
      mosaicRefresh(@oldbitmap)
      if new_mosaic == 0
        @mosaic_timer_start = nil
        @start_mosaic = nil
      end
    end
  end
end

#===============================================================================
# Cursor
#===============================================================================
class PokemonBoxArrow < Sprite
  attr_accessor :quickswap

  # Time in seconds for the cursor to move down and back up to grab/drop a
  # Pokémon.
  GRAB_TIME = 0.4

  def initialize(viewport = nil)
    super(viewport)
    @holding    = false
    @updating   = false
    @quickswap  = false
    @heldpkmn   = nil
    @handsprite = ChangelingSprite.new(0, 0, viewport)
    @handsprite.addBitmap("point1", "Graphics/UI/Storage/cursor_point_1")
    @handsprite.addBitmap("point2", "Graphics/UI/Storage/cursor_point_2")
    @handsprite.addBitmap("grab", "Graphics/UI/Storage/cursor_grab")
    @handsprite.addBitmap("fist", "Graphics/UI/Storage/cursor_fist")
    @handsprite.addBitmap("point1q", "Graphics/UI/Storage/cursor_point_1_q")
    @handsprite.addBitmap("point2q", "Graphics/UI/Storage/cursor_point_2_q")
    @handsprite.addBitmap("grabq", "Graphics/UI/Storage/cursor_grab_q")
    @handsprite.addBitmap("fistq", "Graphics/UI/Storage/cursor_fist_q")
    @handsprite.changeBitmap("fist")
    @spriteX = self.x
    @spriteY = self.y
  end


  def dispose
    @handsprite.dispose
    @heldpkmn&.dispose
    super
  end

  def x=(value)
    super
    @handsprite.x = self.x
    @spriteX = x if !@updating
    heldPokemon.x = self.x if holding?
  end

  def y=(value)
    super
    @handsprite.y = self.y
    @spriteY = y if !@updating
    heldPokemon.y = self.y + 16 if holding?
  end

  def z=(value)
    super
    @handsprite.z = value
  end

  def visible=(value)
    super
    @handsprite.visible = value
    sprite = heldPokemon
    sprite.visible = value if sprite
  end

  def color=(value)
    super
    @handsprite.color = value
    sprite = heldPokemon
    sprite.color = value if sprite
  end

  def heldPokemon
    @heldpkmn = nil if @heldpkmn&.disposed?
    @holding = false if !@heldpkmn
    return @heldpkmn
  end

  def holding?
    return self.heldPokemon && @holding
  end

  def grabbing?
    return !@grabbing_timer_start.nil?
  end

  def placing?
    return !@placing_timer_start.nil?
  end

  def setSprite(sprite)
    if holding?
      @heldpkmn = sprite
      @heldpkmn.viewport = self.viewport if @heldpkmn
      @heldpkmn.z = 1 if @heldpkmn
      @holding = false if !@heldpkmn
      self.z = 2
    end
  end

  def deleteSprite
    @holding = false
    if @heldpkmn
      @heldpkmn.dispose
      @heldpkmn = nil
    end
  end

  def grab(sprite)
    @grabbing_timer_start = System.uptime
    @heldpkmn = sprite
    @heldpkmn.viewport = self.viewport
    @heldpkmn.z = 1
    self.z = 2
  end
  def place
    @placing_timer_start = System.uptime
  end

  def release
    @heldpkmn&.release
  end

  def update
    @updating = true
    super
    heldpkmn = heldPokemon
    heldpkmn&.update
    @handsprite.update
    @holding = false if !heldpkmn
    if @grabbing_timer_start
      if System.uptime - @grabbing_timer_start <= GRAB_TIME / 2
        @handsprite.changeBitmap((@quickswap) ? "grabq" : "grab")
        self.y = @spriteY + lerp(0, 16, GRAB_TIME / 2, @grabbing_timer_start, System.uptime)
      else
        @holding = true
        @handsprite.changeBitmap((@quickswap) ? "fistq" : "fist")
        delta_y = lerp(16, 0, GRAB_TIME / 2, @grabbing_timer_start + (GRAB_TIME / 2), System.uptime)
        self.y = @spriteY + delta_y
        @grabbing_timer_start = nil if delta_y == 0
      end
    elsif @placing_timer_start
      if System.uptime - @placing_timer_start <= GRAB_TIME / 2
        @handsprite.changeBitmap((@quickswap) ? "fistq" : "fist")
        self.y = @spriteY + lerp(0, 16, GRAB_TIME / 2, @placing_timer_start, System.uptime)
      else
        @holding = false
        @heldpkmn = nil
        @handsprite.changeBitmap((@quickswap) ? "grabq" : "grab")
        delta_y = lerp(16, 0, GRAB_TIME / 2, @placing_timer_start + (GRAB_TIME / 2), System.uptime)
        self.y = @spriteY + delta_y
        @placing_timer_start = nil if delta_y == 0
      end
    elsif holding?
      @handsprite.changeBitmap((@quickswap) ? "fistq" : "fist")
    else   # Idling
      self.x = @spriteX
      self.y = @spriteY
      if (System.uptime / 0.5).to_i.even?   # Changes every 0.5 seconds
        @handsprite.changeBitmap((@quickswap) ? "point1q" : "point1")
      else
        @handsprite.changeBitmap((@quickswap) ? "point2q" : "point2")
      end
    end
    @updating = false
  end
end

#===============================================================================
# Box
#===============================================================================
class PokemonBoxSprite < Sprite
  attr_accessor :refreshBox
  attr_accessor :refreshSprites

  def initialize(storage, boxnumber, viewport = nil)
    super(viewport)
    @storage = storage
    @boxnumber = boxnumber
    @refreshBox = true
    @refreshSprites = true
    @pokemonsprites = []
    PokemonBox::BOX_SIZE.times do |i|
      @pokemonsprites[i] = nil
      pokemon = @storage[boxnumber, i]
      @pokemonsprites[i] = PokemonBoxIcon.new(pokemon, viewport)
    end
    @contents = Bitmap.new(450,450)#tamaño original(324, 302)
    self.bitmap = @contents
    self.x = 190+64#cajas
    self.y = 18
    refresh
  end

  def dispose
    if !disposed?
      PokemonBox::BOX_SIZE.times do |i|
        @pokemonsprites[i]&.dispose
        @pokemonsprites[i] = nil
      end
      @boxbitmap.dispose
      @contents.dispose
      super
    end
  end

  def x=(value)
    super
    refresh
  end

  def y=(value)
    super
    refresh
  end

  def color=(value)
    super
    if @refreshSprites
      PokemonBox::BOX_SIZE.times do |i|
        if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
          @pokemonsprites[i].color = value
        end
      end
    end
    refresh
  end

  def visible=(value)
    super
    PokemonBox::BOX_SIZE.times do |i|
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].visible = value
      end
    end
    refresh
  end

  def getBoxBitmap
    if !@bg || @bg != @storage[@boxnumber].background
      curbg = @storage[@boxnumber].background
      if !curbg || (curbg.is_a?(String) && curbg.length == 0)
        @bg = @boxnumber % PokemonStorage::BASICWALLPAPERQTY
      else
        if curbg.is_a?(String) && curbg[/^box(\d+)$/]
          curbg = $~[1].to_i
          @storage[@boxnumber].background = curbg
        end
        @bg = curbg
      end
      if !@storage.isAvailableWallpaper?(@bg)
        @bg = @boxnumber % PokemonStorage::BASICWALLPAPERQTY
        @storage[@boxnumber].background = @bg
      end
      @boxbitmap&.dispose
      @boxbitmap = AnimatedBitmap.new("Graphics/UI/Storage/box_#{@bg}")
    end
  end

  def getPokemon(index)
    return @pokemonsprites[index]
  end

  def setPokemon(index, sprite)
    @pokemonsprites[index] = sprite
    @pokemonsprites[index].refresh
    refresh
  end

  def grabPokemon(index, arrow)
    sprite = @pokemonsprites[index]
    if sprite
      arrow.grab(sprite)
      @pokemonsprites[index] = nil
      refresh
    end
  end

  def deletePokemon(index)
    @pokemonsprites[index].dispose
    @pokemonsprites[index] = nil
    refresh
  end

  def refresh
    if @refreshBox
      boxname = @storage[@boxnumber].name
      getBoxBitmap
      # Changed Box Height by a few pixels
      @contents.blt(0, 0, @boxbitmap.bitmap, Rect.new(0, 0, 450, 450))
      pbSetSystemFont(@contents)
      widthval = @contents.text_size(boxname).width
      xval = 163 - (widthval / 2) + 34
      # Changed color of Box Name
      pbDrawShadowText(@contents, xval, 14 - 4, widthval, 32,
                       boxname, Color.new(248, 248, 248), Color.new(74, 112, 175) )
      @refreshBox = false
    end
    # Changed position of Pokémon Icons inside the box
    yval = self.y + 30
    yval += 8 + 5 ###
    PokemonBox::BOX_HEIGHT.times do |j|
      xval = self.x + 10
      xval += 2 + 8###
      PokemonBox::BOX_WIDTH.times do |k|
        sprite = @pokemonsprites[(j * PokemonBox::BOX_WIDTH) + k]
      if sprite && !sprite.disposed?
        sprite.viewport = self.viewport
        sprite.x = xval
        sprite.y = yval
-       sprite.z = 1
+       # Aseguramos z relativo a la caja: box.z (self.z) + 2 para que los iconos siempre queden por encima del highlight
+       sprite.z = (self.z || 0) + 2
        end
        xval += 48+9
      end
      yval += 48+9
    end
  end

  def update
    super
    PokemonBox::BOX_SIZE.times do |i|
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].update
      end
    end
  end
end

#===============================================================================
# Party pop-up panel
#===============================================================================
class PokemonBoxPartySprite < Sprite
  def initialize(party, viewport = nil)
    super(viewport)
    @party = party
    @boxbitmap = AnimatedBitmap.new("Graphics/UI/Storage/overlay_party")
    @pokemonsprites = []
    Settings::MAX_PARTY_SIZE.times do |i|
      @pokemonsprites[i] = nil
      pokemon = @party[i]
      @pokemonsprites[i] = PokemonBoxIcon.new(pokemon, viewport) if pokemon
    end
    @contents = Bitmap.new(172, 352)
    self.bitmap = @contents
    self.x = 182
    self.y = Graphics.height - 352
    pbSetSystemFont(self.bitmap)
    refresh
  end

  def dispose
    Settings::MAX_PARTY_SIZE.times do |i|
      @pokemonsprites[i]&.dispose
    end
    @boxbitmap.dispose
    @contents.dispose
    super
  end

  def x=(value)
    super
    refresh
  end

  def y=(value)
    super
    refresh
  end

  def color=(value)
    super
    Settings::MAX_PARTY_SIZE.times do |i|
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].color = pbSrcOver(@pokemonsprites[i].color, value)
      end
    end
  end

  def visible=(value)
    super
    Settings::MAX_PARTY_SIZE.times do |i|
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].visible = value
      end
    end
  end

  def getPokemon(index)
    return @pokemonsprites[index]
  end

  def setPokemon(index, sprite)
    @pokemonsprites[index] = sprite
    @pokemonsprites.compact!
    refresh
  end

  def grabPokemon(index, arrow)
    sprite = @pokemonsprites[index]
    if sprite
      arrow.grab(sprite)
      @pokemonsprites.delete_at(index)
      refresh
    end
  end

  def deletePokemon(index)
    @pokemonsprites[index].dispose
    @pokemonsprites[index] = nil
    @pokemonsprites.compact!
    refresh
  end

  def refresh
    @contents.clear
    @contents.stretch_blt(Rect.new(0, 0, 172, 352), @boxbitmap.bitmap, @boxbitmap.bitmap.rect)

    pbDrawTextPositions(
      self.bitmap,
      # Changed position of Back Menu
      [[_INTL("Atrás"), 86, 248, :center, Color.new(248, 248, 248), Color.new(74, 112, 175)]]
    )
    xvalues = []   # [18, 90, 18, 90, 18, 90]
    yvalues = []   # [2, 18, 66, 82, 130, 146]
    Settings::MAX_PARTY_SIZE.times do |i|
      xvalues.push(18 + (72 * (i % 2)))
      yvalues.push(2 + (16 * (i % 2)) + (64 * (i / 2)))
    end
    @pokemonsprites.delete_if { |sprite| sprite&.disposed? }
    @pokemonsprites.each { |sprite| sprite&.refresh }
Settings::MAX_PARTY_SIZE.times do |j|
  sprite = @pokemonsprites[j]
  next if sprite.nil? || sprite.disposed?
  sprite.viewport = self.viewport
  sprite.x = self.x + xvalues[j]
  sprite.y = self.y + yvalues[j] + 5
  # Aseguramos z relativo a la party
  sprite.z = (self.z || 0) + 2
    end
  end

  def update
    super
    Settings::MAX_PARTY_SIZE.times do |i|
      @pokemonsprites[i].update if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
    end
  end
end

#===============================================================================
# Pokémon storage visuals
#===============================================================================
class PokemonStorageScene
  attr_reader :quickswap

  MARK_WIDTH  = 22
  MARK_HEIGHT = 22
    TYPE_ICON_INDEX = {
  :NORMAL   => 0,
  :FIGHTING => 1,
  :FLYING   => 2,
  :POISON   => 3,
  :GROUND   => 4,
  :ROCK     => 5,
  :BUG      => 6,
  :GHOST    => 7,
  :STEEL    => 8,
  :FIRE     => 10,
  :WATER    => 11,
  :GRASS    => 12,
  :ELECTRIC => 13,
  :PSYCHIC  => 14,
  :ICE      => 15,
  :DRAGON   => 16,
  :DARK     => 17,
  :FAIRY    => 18
}

  def initialize
    @command = 1
  end

def pbStartBox(screen, command)
  @screen = screen
  @storage = screen.storage
  # Viewports
  @bgviewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  @boxviewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  @boxsidesviewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  @arrowviewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  [@bgviewport, @boxviewport, @boxsidesviewport, @arrowviewport, @viewport].each { |v| v.z = 99999 }

  @selection = -1
  @numbersBitmap  = AnimatedBitmap.new("Graphics/UI/Summary/icon_numbers")
  @sprites = {}
  @command = command

  # --- Fondo ---
  addBackgroundPlane(@sprites, "background", "Storage/bg", @bgviewport)

  # --- Caja ---
  @sprites["box"] = PokemonBoxSprite.new(@storage, @storage.currentBox, @boxviewport)
  @sprites["box"].refreshSprites = true

  # --- Overlay lateral ---
  @sprites["boxsides"] = IconSprite.new(0, 0, @boxsidesviewport)
  @sprites["boxsides"].setBitmap("Graphics/UI/Storage/overlay_main")
  @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @boxsidesviewport)
  pbSetSystemFont(@sprites["overlay"].bitmap)

  # --- Pokémon ---
  @sprites["pokemon"] = AutoMosaicPokemonSprite.new(@boxsidesviewport)
  @sprites["pokemon"].setOffset(PictureOrigin::CENTER)
  @sprites["pokemon"].x = 98 + 26 - 2
  @sprites["pokemon"].y = 148 + 42

  # --- Equipo de la caja ---
  @sprites["boxparty"] = PokemonBoxPartySprite.new(@storage.party, @boxsidesviewport)
  if command != 2   # Solo Drop down tab en Deposit
    @sprites["boxparty"].x = 182 + 90
    @sprites["boxparty"].y = Graphics.height
  end

  # --- Marcajes ---
  @markingbitmap = AnimatedBitmap.new("Graphics/UI/Storage/markings")
  @sprites["markingbg"] = IconSprite.new(292, 68 + 43, @boxsidesviewport)
  @sprites["markingbg"].setBitmap("Graphics/UI/Storage/overlay_marking")
  @sprites["markingbg"].z = 10
  @sprites["markingbg"].visible = false
  @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @boxsidesviewport)
  @sprites["markingoverlay"].z = 11
  @sprites["markingoverlay"].visible = false
  pbSetSystemFont(@sprites["markingoverlay"].bitmap)

  # --- Flecha ---
  @sprites["arrow"] = PokemonBoxArrow.new(@arrowviewport)
  @sprites["arrow"].z += 1

  # --- Highlight ---
  pbCreateHighlight
  @sprites["_highlight_ui"] = @highlight_sprite if defined?(@highlight_sprite) && @highlight_sprite
  @sprites["_highlight_box"] = @highlight_box_sprite if defined?(@highlight_box_sprite) && @highlight_box_sprite

  # --- Overlay inicial ---
  if command == 2
    pbPartySetArrow(@sprites["arrow"], @selection)
    pbUpdateOverlay(@selection, @storage.party)
  else
    pbSetArrow(@sprites["arrow"], @selection)
    pbUpdateOverlay(@selection)
  end
  pbSetMosaic(@selection)
  pbSEPlay("PC access")

  # --- Fade in de todos los sprites juntos ---
  pbFadeInAndShow(@sprites)
end



def pbCloseBox
  # 1) Construir un hash con todos los sprites que deben hacer fade
  sprites_for_fade = {}

  # Añadir todos los sprites de @sprites (si existen y no están disposed)
  if @sprites && @sprites.is_a?(Hash)
    @sprites.each do |k, s|
      next if !s || s.disposed?
      # Asegurar z entero
      s.z = 0 if s.z.nil?
      sprites_for_fade[k] = s
    end
  end

  # Añadir los highlights (si existen y no están disposed)
  if defined?(@highlight_sprite) && @highlight_sprite && !@highlight_sprite.disposed?
    @highlight_sprite.z = 0 if @highlight_sprite.z.nil?
    sprites_for_fade["_highlight_ui"] = @highlight_sprite
  end
  if defined?(@highlight_box_sprite) && @highlight_box_sprite && !@highlight_box_sprite.disposed?
    @highlight_box_sprite.z = 0 if @highlight_box_sprite.z.nil?
    sprites_for_fade["_highlight_box"] = @highlight_box_sprite
  end

  # 2) Si no hay sprites válidos, simplemente continuar con dispose
  if sprites_for_fade.empty?
    # fallback: intentar deshacer highlight y disposes
    pbDisposeSpriteHash(@sprites) if @sprites
    @markingbitmap&.dispose
    pbDisposeHighlight
    @boxviewport&.dispose
    @boxsidesviewport&.dispose
    @arrowviewport&.dispose
    @bgviewport&.dispose
    @viewport&.dispose
    return
  end

  # 3) Hacer fade out y ocultar todos los sprites que hemos recogido
  # Usamos pbFadeOutAndHide porque queremos fade-out (cerrar PC) sin fade-in.
  pbFadeOutAndHide(sprites_for_fade)

  # 4) Ahora liberar todo como antes
  pbDisposeSpriteHash(@sprites) if @sprites
  @markingbitmap&.dispose

  # Limpiar highlight (dispose de bitmaps y sprites)
  pbDisposeHighlight

  # Dispose de viewports con cheques de seguridad
  @boxviewport&.dispose
  @boxsidesviewport&.dispose
  @arrowviewport&.dispose
  @bgviewport&.dispose
  @viewport&.dispose
end





  def pbDisplay(message)
    msgwindow = Window_UnformattedTextPokemon.newWithSize("", 180, 0, Graphics.width - 180, 32)
    msgwindow.viewport       = @viewport
    msgwindow.visible        = true
    msgwindow.letterbyletter = false
    msgwindow.resizeHeightToFit(message, Graphics.width - 180)
    msgwindow.text = message
    pbBottomRight(msgwindow)
    loop do
      Graphics.update
      Input.update
      if Input.trigger?(Input::BACK) || Input.trigger?(Input::USE)
        break
      end
      msgwindow.update
      self.update
    end
    msgwindow.dispose
    Input.update
  end

  def pbShowCommands(message, commands, index = 0)
    ret = -1
    msgwindow = Window_UnformattedTextPokemon.newWithSize("", 180, 0, Graphics.width - 180, 32)
    msgwindow.viewport       = @viewport
    msgwindow.visible        = true
    msgwindow.letterbyletter = false
    msgwindow.text           = message
    msgwindow.resizeHeightToFit(message, Graphics.width - 180)
    pbBottomRight(msgwindow)
    cmdwindow = Window_CommandPokemon.new(commands)
    cmdwindow.viewport = @viewport
    cmdwindow.visible  = true
    cmdwindow.resizeToFit(cmdwindow.commands)
    cmdwindow.height = Graphics.height - msgwindow.height if cmdwindow.height > Graphics.height - msgwindow.height
    pbBottomRight(cmdwindow)
    cmdwindow.y -= msgwindow.height
    cmdwindow.index = index
    loop do
      Graphics.update
      Input.update
      msgwindow.update
      cmdwindow.update
      if Input.trigger?(Input::BACK)
        ret = -1
        break
      elsif Input.trigger?(Input::USE)
        ret = cmdwindow.index
        break
      end
      self.update
    end
    msgwindow.dispose
    cmdwindow.dispose
    Input.update
    return ret
  end

  # ---------------------------
# Highlight system (parche)
# ---------------------------
def pbCreateHighlight
  return if @highlight_src
  begin
    @highlight_src = AnimatedBitmap.new("Graphics/UI/Storage/highlight_storage")
  rescue
    @highlight_src = nil
    return
  end

  # Alturas de cada highlight
  @highlight_heights = [39, 56, 41, 41, 50, 60]

  # Crear slices pre-hechos (para no recrear bitmaps cada vez)
  @highlight_slices = []
  off = 0
  @highlight_heights.each do |h|
    bmp = Bitmap.new(226, h)
    bmp.blt(0, 0, @highlight_src.bitmap, Rect.new(0, off, 226, h))
    @highlight_slices << bmp
    off += h
  end

  # Sprite para caja: lo ponemos en el mismo viewport que la caja (@boxviewport)
  # para que quede debajo de los iconos que también están en ese viewport.
  @highlight_box_sprite = Sprite.new(@boxviewport)
  @highlight_box_sprite.bitmap = Bitmap.new(226, @highlight_heights.max)
  @highlight_box_sprite.visible = false
  # Le damos un z intermedio (fondo de caja z=0, iconos z=1 en PokemonBoxSprite.refresh)
  @highlight_box_sprite.z = (@sprites["box"]&.z || 0) + 0.5

  # Sprite para UI (overlay lateral), lo dejamos en boxsidesviewport
  @highlight_sprite = Sprite.new(@boxsidesviewport)
  @highlight_sprite.bitmap = Bitmap.new(226, @highlight_heights.max)
  @highlight_sprite.visible = false
  @highlight_sprite.z = (@sprites["overlay"]&.z || 20)
end


def pbDisposeHighlight
  if @highlight_box_sprite
    @highlight_box_sprite.bitmap.dispose if @highlight_box_sprite.bitmap && !@highlight_box_sprite.bitmap.disposed?
    @highlight_box_sprite.dispose if !@highlight_box_sprite.disposed?
    @highlight_box_sprite = nil
  end
  if @highlight_sprite
    @highlight_sprite.bitmap.dispose if @highlight_sprite.bitmap && !@highlight_sprite.bitmap.disposed?
    @highlight_sprite.dispose if !@highlight_sprite.disposed?
    @highlight_sprite = nil
  end

  # Dispose del origen y slices
  @highlight_src&.dispose
  @highlight_src = nil
  if @highlight_slices
    @highlight_slices.each { |b| b.dispose if b && !b.disposed? }
    @highlight_slices = nil
  end

  @highlight_heights = nil
end

def pbShowHighlight(selection, party_index = nil)
  return if !@highlight_src
  # Ocultar ambos sprites primero
  @highlight_box_sprite.visible = false if @highlight_box_sprite
  @highlight_sprite.visible = false if @highlight_sprite

  # Determinar idx
  idx = nil
  if selection == :party
    idx = (party_index == Settings::MAX_PARTY_SIZE) ? 5 : 4
  else
    case selection
    when -1, -4, -5 then idx = 0  # Nombre de caja / cambio de caja
    when -2 then idx = 2           # Party Pokémon
    when -3 then idx = 3           # Close Box
    else idx = 1                   # Huecos de la caja
    end
  end
  return if idx.nil? || @highlight_heights[idx].nil?

  h = @highlight_heights[idx]

  # Selección de sprite según idx
  if idx == 1   # Huecos de la caja
    s = @highlight_box_sprite
    other = @highlight_sprite
    # Viewport: ya está en @boxviewport
    s.viewport = @boxviewport
    # z dinámico: debajo de los iconos de Pokémon (estos se ponen a z = 1 en PokemonBoxSprite.refresh)
    s.z = (@sprites["box"]&.z || 0) +1
  else
    s = @highlight_sprite
    other = @highlight_box_sprite
    s.viewport = @boxsidesviewport
    s.z = (@sprites["overlay"]&.z || 20)
  end
  other.visible = false
  return if !s

  # Llenar bitmap usando slice pre-hecho
  s.bitmap.clear
  s.bitmap.blt(0, 0, @highlight_slices[idx], @highlight_slices[idx].rect)

  # Posicionamiento según idx
  case idx
  when 0
    base_x = (@sprites["box"].x || 0) + 196
    base_y = (@sprites["box"].y || 0) + 20
    s.x = base_x - (s.bitmap.width / 2)
    s.y = base_y - (h / 2)
  when 1
    col = selection % PokemonBox::BOX_WIDTH
    row = selection / PokemonBox::BOX_WIDTH
    left = (@sprites["box"].x || 0) + 25 + col * 57
    top  = (@sprites["box"].y || 0) + 51 + row * 57
    s.x = left
    s.y = top
  when 2
    tx = 204 + 111 + 77
    ty = 399
    s.x = tx - (s.bitmap.width / 2)
    s.y = ty - (h / 2)
  when 3
    tx = 617
    ty = 399
    s.x = tx - (s.bitmap.width / 2)
    s.y = ty - (h / 2)
  when 4
    # Highlight sobre un Pokémon del party
    col = party_index % 2
    row = party_index / 2
    panel_x = @sprites["boxparty"].x || 0
    panel_y = @sprites["boxparty"].y || 0
    x_offset = 18 + 72 * col
    y_offset = 2 + 16 * col + 64 * row + 5
    s.x = panel_x + x_offset - (s.bitmap.width / 2) + 32 + 79 - 1
    s.y = panel_y + y_offset - (h / 2) + 32 + 5 - 1
    s.viewport = @sprites["boxparty"].viewport
    s.z = @sprites["boxparty"].z + 1
  when 5
    tx = (@sprites["boxparty"].x || 0) + 130
    ty = (@sprites["boxparty"].y || 0) + 257
    s.x = tx - (s.bitmap.width / 2)
    s.y = ty - (h / 2)
  end

  s.visible = true
end




def pbSetArrow(arrow, selection, party_index = nil)
  # Posicionar flecha
  case selection
  when -1, -4, -5
    arrow.x = 396 + 6 + 10
    arrow.y = -24
  when -2
    arrow.x = 292 + 30
    arrow.y = 278 + 60
  when -3
    arrow.x = 568 - 40
    arrow.y = 278 + 60
  else
    arrow.x = (270 + (57 * (selection % PokemonBox::BOX_WIDTH)))
    arrow.y = (30 + (57 * (selection / PokemonBox::BOX_WIDTH)))
  end

  # Mostrar highlight solo si selection es válido o :party
  if selection == :party
    pbShowHighlight(:party, party_index)
  else
    pbShowHighlight(selection)
  end
end

  def pbChangeSelection(key, selection)
    case key
    when Input::UP
      case selection
      when -1   # Box name
        selection = -2
      when -2   # Party
        selection = PokemonBox::BOX_SIZE - 1 - (PokemonBox::BOX_WIDTH * 2 / 3)   # 25
      when -3   # Close Box
        selection = PokemonBox::BOX_SIZE - (PokemonBox::BOX_WIDTH / 3)   # 28
      else
        selection -= PokemonBox::BOX_WIDTH
        selection = -1 if selection < 0
      end
    when Input::DOWN
      case selection
      when -1   # Box name
        selection = PokemonBox::BOX_WIDTH / 3   # 2
      when -2   # Party
        selection = -1
      when -3   # Close Box
        selection = -1
      else
        selection += PokemonBox::BOX_WIDTH
        if selection >= PokemonBox::BOX_SIZE
          if selection < PokemonBox::BOX_SIZE + (PokemonBox::BOX_WIDTH / 2)
            selection = -2   # Party
          else
            selection = -3   # Close Box
          end
        end
      end
    when Input::LEFT
      if selection == -1   # Box name
        selection = -4   # Move to previous box
      elsif selection == -2
        selection = -3
      elsif selection == -3
        selection = -2
      elsif (selection % PokemonBox::BOX_WIDTH) == 0   # Wrap around
        selection += PokemonBox::BOX_WIDTH - 1
      else
        selection -= 1
      end
    when Input::RIGHT
      if selection == -1   # Box name
        selection = -5   # Move to next box
      elsif selection == -2
        selection = -3
      elsif selection == -3
        selection = -2
      elsif (selection % PokemonBox::BOX_WIDTH) == PokemonBox::BOX_WIDTH - 1   # Wrap around
        selection -= PokemonBox::BOX_WIDTH - 1
      else
        selection += 1
      end
    end
    return selection
  end

  def pbPartySetArrow(arrow, selection)
    return if selection < 0
    xvalues = []   # [200, 272, 200, 272, 200, 272, 236]
    yvalues = []   # [2, 18, 66, 82, 130, 146, 220]
    Settings::MAX_PARTY_SIZE.times do |i|
      xoffset = 90  # misma cantidad que moviste boxparty
      xvalues.push(200 + (72 * (i % 2)) + xoffset)
      yvalues.push(2 + (16 * (i % 2)) + (64 * (i / 2))+62)
    end
    xvalues.push(236+90)
    yvalues.push(220+62)
    arrow.angle = 0
    arrow.mirror = false
    arrow.ox = 0
    arrow.oy = 0
    arrow.x = xvalues[selection]
    arrow.y = yvalues[selection]

    # Actualiza el highlight para la pestaña party
    pbShowHighlight(:party, selection) if respond_to?(:pbShowHighlight)
  end

  def pbPartyChangeSelection(key, selection)
    case key
    when Input::LEFT
      selection -= 1
      selection = Settings::MAX_PARTY_SIZE if selection < 0
    when Input::RIGHT
      selection += 1
      selection = 0 if selection > Settings::MAX_PARTY_SIZE
    when Input::UP
      if selection == Settings::MAX_PARTY_SIZE
        selection = Settings::MAX_PARTY_SIZE - 1
      else
        selection -= 2
        selection = Settings::MAX_PARTY_SIZE if selection < 0
      end
    when Input::DOWN
      if selection == Settings::MAX_PARTY_SIZE
        selection = 0
      else
        selection += 2
        selection = Settings::MAX_PARTY_SIZE if selection > Settings::MAX_PARTY_SIZE
      end
    end
    return selection
  end

  def pbSelectBoxInternal(_party)
    selection = @selection
    pbSetArrow(@sprites["arrow"], selection)
    pbUpdateOverlay(selection)
    pbSetMosaic(selection)
    loop do
      Graphics.update
      Input.update
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key >= 0
        pbPlayCursorSE
        selection = pbChangeSelection(key, selection)
        pbSetArrow(@sprites["arrow"], selection)
        case selection
        when -4
          nextbox = (@storage.currentBox + @storage.maxBoxes - 1) % @storage.maxBoxes
          pbSwitchBoxToLeft(nextbox)
          @storage.currentBox = nextbox
        when -5
          nextbox = (@storage.currentBox + 1) % @storage.maxBoxes
          pbSwitchBoxToRight(nextbox)
          @storage.currentBox = nextbox
        end
        selection = -1 if [-4, -5].include?(selection)
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      end
      self.update
      if Input.trigger?(Input::JUMPUP)
        pbPlayCursorSE
        nextbox = (@storage.currentBox + @storage.maxBoxes - 1) % @storage.maxBoxes
        pbSwitchBoxToLeft(nextbox)
        @storage.currentBox = nextbox
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      elsif Input.trigger?(Input::JUMPDOWN)
        pbPlayCursorSE
        nextbox = (@storage.currentBox + 1) % @storage.maxBoxes
        pbSwitchBoxToRight(nextbox)
        @storage.currentBox = nextbox
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      elsif Input.trigger?(Input::SPECIAL)   # Jump to box name
        if selection != -1
          pbPlayCursorSE
          selection = -1
          pbSetArrow(@sprites["arrow"], selection)
          pbUpdateOverlay(selection)
          pbSetMosaic(selection)
        end
      elsif Input.trigger?(Input::ACTION) && @command == 0   # Organize only
        pbPlayDecisionSE
        pbSetQuickSwap(!@quickswap)
      elsif Input.trigger?(Input::BACK)
        @selection = selection
        return nil
      elsif Input.trigger?(Input::USE)
        @selection = selection
        if selection >= 0
          return [@storage.currentBox, selection]
        elsif selection == -1   # Box name
          return [-4, -1]
        elsif selection == -2   # Party Pokémon
          return [-2, -1]
        elsif selection == -3   # Close Box
          return [-3, -1]
        end
      end
    end
  end

  def pbSelectBox(party)
    return pbSelectBoxInternal(party) if @command == 1   # Withdraw
    ret = nil
    loop do
      ret = pbSelectBoxInternal(party) if !@choseFromParty
      if @choseFromParty || (ret && ret[0] == -2)   # Party Pokémon
        if !@choseFromParty
          pbShowPartyTab
          @selection = 0
        end
        ret = pbSelectPartyInternal(party, false)
        if ret < 0
          pbHidePartyTab
          @selection = -2
          @choseFromParty = false
        else
          @choseFromParty = true
          return [-1, ret]
        end
      else
        @choseFromParty = false
        return ret
      end
    end
  end

  def pbSelectPartyInternal(party, depositing)
    selection = @selection
    pbPartySetArrow(@sprites["arrow"], selection)
    pbUpdateOverlay(selection, party)
    pbSetMosaic(selection)
    lastsel = 1
    loop do
      Graphics.update
      Input.update
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key >= 0
        pbPlayCursorSE
        newselection = pbPartyChangeSelection(key, selection)
        case newselection
        when -1
          return -1 if !depositing
        when -2
          selection = lastsel
        else
          selection = newselection
        end
        pbPartySetArrow(@sprites["arrow"], selection)
        lastsel = selection if selection > 0
        pbUpdateOverlay(selection, party)
        pbSetMosaic(selection)
      end
      self.update
      if Input.trigger?(Input::ACTION) && @command == 0   # Organize only
        pbPlayDecisionSE
        pbSetQuickSwap(!@quickswap)
      elsif Input.trigger?(Input::BACK)
        @selection = selection
        return -1
      elsif Input.trigger?(Input::USE)
        if selection >= 0 && selection < Settings::MAX_PARTY_SIZE
          @selection = selection
          return selection
        elsif selection == Settings::MAX_PARTY_SIZE   # Close Box
          @selection = selection
          return (depositing) ? -3 : -1
        end
      end
    end
  end

  def pbSelectParty(party)
    return pbSelectPartyInternal(party, true)
  end

  def pbChangeBackground(wp)
    duration = 0.2   # Time in seconds to fade out or fade in
    @sprites["box"].refreshSprites = false
    Graphics.update
    self.update
    # Fade old background to white
    timer_start = System.uptime
    loop do
      alpha = lerp(0, 255, duration, timer_start, System.uptime)
      @sprites["box"].color = Color.new(248, 248, 248, alpha)
      Graphics.update
      self.update
      break if alpha >= 255
    end
    # Fade in new background from white
    @sprites["box"].refreshBox = true
    @storage[@storage.currentBox].background = wp
    timer_start = System.uptime
    loop do
      alpha = lerp(255, 0, duration, timer_start, System.uptime)
      @sprites["box"].color = Color.new(248, 248, 248, alpha)
      Graphics.update
      self.update
      break if alpha <= 0
    end
    @sprites["box"].refreshSprites = true
    Input.update
  end

def pbSwitchBoxToRight(new_box_number)
  newbox = PokemonBoxSprite.new(@storage, new_box_number, @boxviewport)
  newbox.x = @sprites["box"].x

  @sprites["box"].dispose
  @sprites["box"] = newbox
  @sprites["box"].z = 0 if @sprites["box"].z.nil?

  # Reset selección si estaba en un Pokémon
  @selection = -1 if @selection >= 0

  # Forzar z de los iconos de la box
  PokemonBox::BOX_SIZE.times do |i|
    ps = @sprites["box"].getPokemon(i) rescue nil
    next if !ps || ps.disposed?
    ps.viewport = @sprites["box"].viewport
    ps.z = @sprites["box"].z + 2
  end

  # Highlight si corresponde
  if [-1, -4, -5].include?(@selection) && @highlight_box_sprite
    pbShowHighlight(@selection)
    @highlight_box_sprite.viewport = @sprites["box"].viewport
    @highlight_box_sprite.z = @sprites["box"].z + 1
  end
  Input.update
end


def pbSwitchBoxToLeft(new_box_number)
  # Crear nueva box directamente en posición final
  newbox = PokemonBoxSprite.new(@storage, new_box_number, @boxviewport)
  newbox.x = @sprites["box"].x   # misma posición sin animación

  # Reemplazar la box anterior
  @sprites["box"].dispose
  @sprites["box"] = newbox

  # Asegurarnos de una base z clara para la caja
  @sprites["box"].z = 0 if @sprites["box"].z.nil?

  # Reset selección si estaba en un Pokémon
  @selection = -1 if @selection >= 0

  # Forzar z de los iconos de la box (asegura que queden por encima del highlight)
  PokemonBox::BOX_SIZE.times do |i|
    ps = @sprites["box"].getPokemon(i) rescue nil
    next if !ps || ps.disposed?
    ps.viewport = @sprites["box"].viewport
    ps.z = @sprites["box"].z + 2
  end

  # Highlight si corresponde: calcular y forzar z relativo a la nueva box
  if [-1, -4, -5].include?(@selection) && @highlight_box_sprite
    pbShowHighlight(@selection)   # esto posiciona/activa el highlight
    @highlight_box_sprite.viewport = @sprites["box"].viewport
    @highlight_box_sprite.z = @sprites["box"].z + 1
  end

  Input.update
end






  def pbJumpToBox(newbox)
    return if @storage.currentBox == newbox
    if newbox > @storage.currentBox
      pbSwitchBoxToRight(newbox)
    else
      pbSwitchBoxToLeft(newbox)
    end
    @storage.currentBox = newbox
  end

  def pbSetMosaic(selection)
    return if @screen.pbHeldPokemon
    return if @boxForMosaic == @storage.currentBox && @selectionForMosaic == selection
    @sprites["pokemon"].mosaic_duration = 0.25   # In seconds
    @boxForMosaic = @storage.currentBox
    @selectionForMosaic = selection
  end

  def pbSetQuickSwap(value)
    @quickswap = value
    @sprites["arrow"].quickswap = value
  end

  def pbShowPartyTab
  @sprites["arrow"].visible = false

  # Ocultar cualquier highlight visible
  @highlight_sprite.visible = false if @highlight_sprite
  @highlight_box_sprite.visible = false if @highlight_box_sprite

  if !@screen.pbHeldPokemon
    pbUpdateOverlay(-1)
    pbSetMosaic(-1)
  end

  pbSEPlay("GUI storage show party panel")
  start_y = @sprites["boxparty"].y
  timer_start = System.uptime
  loop do
    @sprites["boxparty"].y = lerp(start_y, start_y - @sprites["boxparty"].height,
                                  0.4, timer_start, System.uptime)
    self.update
    Graphics.update
    break if @sprites["boxparty"].y == start_y - @sprites["boxparty"].height
  end
  Input.update
  @sprites["arrow"].visible = true
end

def pbHidePartyTab
  @sprites["arrow"].visible = false

  # Ocultar cualquier highlight visible
  @highlight_sprite.visible = false if @highlight_sprite
  @highlight_box_sprite.visible = false if @highlight_box_sprite

  if !@screen.pbHeldPokemon
    pbUpdateOverlay(-1)
    pbSetMosaic(-1)
  end

  pbSEPlay("GUI storage hide party panel")
  start_y = @sprites["boxparty"].y
  timer_start = System.uptime
  loop do
    @sprites["boxparty"].y = lerp(start_y, start_y + @sprites["boxparty"].height,
                                  0.4, timer_start, System.uptime)
    self.update
    Graphics.update
    break if @sprites["boxparty"].y == start_y + @sprites["boxparty"].height
  end
  Input.update
  @sprites["arrow"].visible = true
end


  def pbHold(selected)
    pbSEPlay("GUI storage pick up")
    if selected[0] == -1
      @sprites["boxparty"].grabPokemon(selected[1], @sprites["arrow"])
    else
      @sprites["box"].grabPokemon(selected[1], @sprites["arrow"])
    end
    while @sprites["arrow"].grabbing?
      Graphics.update
      Input.update
      self.update
    end
  end

  def pbSwap(selected, _heldpoke)
    pbSEPlay("GUI storage pick up")
    heldpokesprite = @sprites["arrow"].heldPokemon
    boxpokesprite = nil
    if selected[0] == -1
      boxpokesprite = @sprites["boxparty"].getPokemon(selected[1])
    else
      boxpokesprite = @sprites["box"].getPokemon(selected[1])
    end
    if selected[0] == -1
      @sprites["boxparty"].setPokemon(selected[1], heldpokesprite)
    else
      @sprites["box"].setPokemon(selected[1], heldpokesprite)
    end
    @sprites["arrow"].setSprite(boxpokesprite)
    @sprites["pokemon"].mosaic_duration = 0.25   # In seconds
    @boxForMosaic = @storage.currentBox
    @selectionForMosaic = selected[1]
  end

  def pbPlace(selected, _heldpoke)
    pbSEPlay("GUI storage put down")
    heldpokesprite = @sprites["arrow"].heldPokemon
    @sprites["arrow"].place
    while @sprites["arrow"].placing?
      Graphics.update
      Input.update
      self.update
    end
    if selected[0] == -1
      @sprites["boxparty"].setPokemon(selected[1], heldpokesprite)
    else
      @sprites["box"].setPokemon(selected[1], heldpokesprite)
    end
    @boxForMosaic = @storage.currentBox
    @selectionForMosaic = selected[1]
  end

  def pbWithdraw(selected, heldpoke, partyindex)
    pbHold(selected) if !heldpoke
    pbShowPartyTab
    pbPartySetArrow(@sprites["arrow"], partyindex)
    pbPlace([-1, partyindex], heldpoke)
    pbHidePartyTab
  end

  def pbStore(selected, heldpoke, destbox, firstfree)
    if heldpoke
      if destbox == @storage.currentBox
        heldpokesprite = @sprites["arrow"].heldPokemon
        @sprites["box"].setPokemon(firstfree, heldpokesprite)
        @sprites["arrow"].setSprite(nil)
      else
        @sprites["arrow"].deleteSprite
      end
    else
      sprite = @sprites["boxparty"].getPokemon(selected[1])
      if destbox == @storage.currentBox
        @sprites["box"].setPokemon(firstfree, sprite)
        @sprites["boxparty"].setPokemon(selected[1], nil)
      else
        @sprites["boxparty"].deletePokemon(selected[1])
      end
    end
  end

  def pbRelease(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    if heldpoke
      sprite = @sprites["arrow"].heldPokemon
    elsif box == -1
      sprite = @sprites["boxparty"].getPokemon(index)
    else
      sprite = @sprites["box"].getPokemon(index)
    end
    if sprite
      sprite.release
      while sprite.releasing?
        Graphics.update
        sprite.update
        self.update
      end
    end
  end

  def pbChooseBox(msg)
    commands = []
    @storage.maxBoxes.times do |i|
      box = @storage[i]
      if box
        commands.push(_INTL("{1} ({2}/{3})", box.name, box.nitems, box.length))
      end
    end
    return pbShowCommands(msg, commands, @storage.currentBox)
  end

  
def pbBoxName(helptext, minchars, maxchars)
  # Mostrar un cuadro de texto simple para ingresar el nombre
  ret = pbMessageFreeText(helptext, "", minchars, maxchars)
  
  # Guardar nombre si se ingresó algo
  if ret && ret.length > 0
    @storage[@storage.currentBox].name = ret
      @sprites["box"].bitmap.clear      # <--- limpiar el bitmap
    @sprites["box"].refreshBox = true
    pbRefresh
  end

  return ret
end

# Función de helper para input de texto libre
def pbMessageFreeText(helptext, default_value = "", minchars = 1, maxchars = 12)
  # Este es básicamente un wrapper de pb_message_free_text_with_on_input sin callback
  term = pb_message_free_text_with_on_input(
    helptext,
    default_value,
    false,           # no multiline
    maxchars
  )
  return term
end




  def pbChooseItem(bag)
    ret = nil
    pbFadeOutIn do
      scene = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene, bag)
      ret = screen.pbChooseItemScreen(proc { |item| GameData::Item.get(item).can_hold? })
    end
    return ret
  end

def pbSummary(selected, heldpoke)
  ret = nil
  pbFadeOutIn do
    # Crear la escena y la pantalla de summary
    scene = PokemonSummary_Scene.new
    screen = PokemonSummaryScreen.new(scene)

    # Decidir qué Pokémon mostrar
    if heldpoke
      ret = screen.pbStartScreen([heldpoke], 0)
    elsif selected[0] == -1
      ret = screen.pbStartScreen(@storage.party, selected[1])
      pbPartySetArrow(@sprites["arrow"], ret)
      pbUpdateOverlay(ret, @storage.party)
    else
      ret = screen.pbStartScreen(@storage.boxes[selected[0]], selected[1])
      pbSetArrow(@sprites["arrow"], ret)
      pbUpdateOverlay(ret)
    end
  end
  return ret
end


  def pbMarkingSetArrow(arrow, selection)
    return if selection < 0

    # Valores base
    xvalues = [162-14, 191-14, 220-14, 162-14, 191-14, 220-14, 190, 190]
    yvalues = [24, 24, 24, 49, 49, 49, 77, 109]

    # Offset general para todas las flechas
    x_offset_all = 5
    y_offset_all = 40
    xvalues.map! { |x| x + x_offset_all }
    yvalues.map! { |y| y + y_offset_all }

    # Offset individual para penúltima flecha (OK)
    x_offset_penultimate = -15
    y_offset_penultimate = 0
    xvalues[6] += x_offset_penultimate
    yvalues[6] += y_offset_penultimate

    # Offset individual para última flecha (Cancelar)
    x_offset_last = -15
    y_offset_last = -7
    xvalues[7] += x_offset_last
    yvalues[7] += y_offset_last

    # Configura la flecha
    arrow.angle  = 0
    arrow.mirror = false
    arrow.ox     = 0
    arrow.oy     = 0
    arrow.x      = xvalues[selection] * 2
    arrow.y      = yvalues[selection] * 2
  end

  def pbMarkingChangeSelection(key, selection)
    case key
    when Input::LEFT
      if selection < 6
        selection -= 1
        selection += 3 if selection % 3 == 2
      end
    when Input::RIGHT
      if selection < 6
        selection += 1
        selection -= 3 if selection % 3 == 0
      end
    when Input::UP
      if selection == 7
        selection = 6
      elsif selection == 6
        selection = 4
      elsif selection < 3
        selection = 7
      else
        selection -= 3
      end
    when Input::DOWN
      if selection == 7
        selection = 1
      elsif selection == 6
        selection = 7
      elsif selection >= 3
        selection = 6
      else
        selection += 3
      end
    end
    return selection
  end

  def pbMark(selected, heldpoke)
    @sprites["markingbg"].visible      = true
    @sprites["markingoverlay"].visible = true
    msg = _INTL("Marca a tu Pokémon.")
    msgwindow = Window_UnformattedTextPokemon.newWithSize("", 180, 0, Graphics.width - 180, 32)
    msgwindow.viewport       = @viewport
    msgwindow.visible        = true
    msgwindow.letterbyletter = false
    msgwindow.text           = msg
    msgwindow.resizeHeightToFit(msg, Graphics.width - 180)
    pbBottomRight(msgwindow)
    base   = Color.new(248, 248, 248)
    shadow = Color.new(80, 80, 80)
    pokemon = heldpoke
    if heldpoke
      pokemon = heldpoke
    elsif selected[0] == -1
      pokemon = @storage.party[selected[1]]
    else
      pokemon = @storage.boxes[selected[0]][selected[1]]
    end
    markings = pokemon.markings.clone
    mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT
    index = 0
    redraw = true
    markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
    loop do
      # Redraw the markings and text
      if redraw
        @sprites["markingoverlay"].bitmap.clear
        (@markingbitmap.bitmap.width / MARK_WIDTH).times do |i|
          markrect.x = i * MARK_WIDTH
          markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
          @sprites["markingoverlay"].bitmap.blt(328 + (58 * (i % 3)), 179 + (50 * (i / 3)),
                                                @markingbitmap.bitmap, markrect)
        end
        textpos = [
          # Changed Text Color and Positions
          [_INTL("Aceptar"), 402-3, 216+60+5, :center, Color.new(248, 248, 248), Color.new(74, 112, 175), :outline],
          [_INTL("Cancelar"), 402-3, 280+50+1, :center, Color.new(248, 248, 248), Color.new(74, 112, 175), :outline]
        ]
        pbDrawTextPositions(@sprites["markingoverlay"].bitmap, textpos)
        pbMarkingSetArrow(@sprites["arrow"], index)
        redraw = false
      end
      Graphics.update
      Input.update
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key >= 0
        oldindex = index
        index = pbMarkingChangeSelection(key, index)
        pbPlayCursorSE if index != oldindex
        pbMarkingSetArrow(@sprites["arrow"], index)
      end
      self.update
      if Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        case index
        when 6   # OK
          pokemon.markings = markings
          break
        when 7   # Cancel
          break
        else
          markings[index] = ((markings[index] || 0) + 1) % mark_variants
          redraw = true
        end
      end
    end
    @sprites["markingbg"].visible      = false
    @sprites["markingoverlay"].visible = false
    msgwindow.dispose
  end

  def pbRefresh
    @sprites["box"].refresh
    @sprites["boxparty"].refresh
  end

  def pbHardRefresh
    oldPartyY = @sprites["boxparty"].y
    @sprites["box"].dispose
    @sprites["box"] = PokemonBoxSprite.new(@storage, @storage.currentBox, @boxviewport)
    @sprites["boxparty"].dispose
    @sprites["boxparty"] = PokemonBoxPartySprite.new(@storage.party, @boxsidesviewport)
    @sprites["boxparty"].y = oldPartyY
  end

  def drawMarkings(bitmap, x, y, markings)
    mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT  # número de variantes por marca
    mark_count    = @markingbitmap.bitmap.width / MARK_WIDTH   # número de marcas horizontales
    markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
    
    mark_count.times do |i|
      markrect.x = i * MARK_WIDTH
      # evita salirse del rango de variantes
      markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
      bitmap.blt(x + i * (MARK_WIDTH + 4), y, @markingbitmap.bitmap, markrect)
    end
  end

  def drawNumber(number, btmp, startX, startY, align = :left)
    # -1 means draw the / character
    n = (number == -1) ? [10] : number.to_i.digits.reverse
    charWidth  = @numbersBitmap.width / 11
    charHeight = @numbersBitmap.height
    startX -= charWidth * n.length if align == :right
    n.each do |i|
      btmp.blt(startX, startY, @numbersBitmap.bitmap, Rect.new(i * charWidth, 0, charWidth, charHeight))
      startX += charWidth
    end
  end

  def pbUpdateOverlay(selection, party = nil)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # Changed Text Colors
    buttonbase = Color.new(248, 248, 248)
    buttonshadow = Color.new(74, 112, 175)
    pbDrawTextPositions(
      overlay,
      # Changed Text Positions
      [[_INTL("Equipo: {1}", (@storage.party.length rescue 0)), 204+111, 390-1, :left, buttonbase, buttonshadow],
       [_INTL("Salir"), 404+111+24, 390-1, :left, buttonbase, buttonshadow]]
    )
    pokemon = nil
    if @screen.pbHeldPokemon
      pokemon = @screen.pbHeldPokemon
    elsif selection >= 0
      pokemon = (party) ? party[selection] : @storage[@storage.currentBox, selection]
    end
    if !pokemon
      @sprites["pokemon"].visible = false
      return
    end
    @sprites["pokemon"].visible = true
    # Changed Text Colors
    base   = Color.new(90, 82, 82)
    shadow = Color.new(165, 165, 173)
    nonbase   = Color.new(90, 82, 82)
    nonshadow = Color.new(165, 165, 173)
    pokename = pokemon.name
    textstrings = [
      # Changed Text Positions
      [pokename, 10 + 50 - 17, 16 - 6, :left, Color.new(48, 70, 102), Color.new(174, 180, 186)]
    ]
    if !pokemon.egg?
      imagepos = []
      # Changed Text Positions
      # Icono de género
      gender_bitmap = AnimatedBitmap.new("Graphics/UI/storage/gender") # tu imagen de género
      if pokemon.male?
        overlay.blt(148+85, 16-8, gender_bitmap.bitmap, Rect.new(0, 0, 22, 22))
      elsif pokemon.female?
        overlay.blt(148+85, 16-8, gender_bitmap.bitmap, Rect.new(22, 0, 22, 22))
      end

      # Cambia la fuente a pequeña
# --- dibujar nivel, right-aligned respecto al icono de género ---
# --- dibujar nivel, right-aligned respecto al icono de género ---
pbSetSmallFont(overlay)
level_text = _INTL("Nv {1}", pokemon.level)

# Determinar el punto derecho según si hay icono de género
if pokemon.gender == 2   # Sin género
  right_anchor = 148 + 85 + 22-3  # Avanzamos más a la derecha
else
  right_anchor = 148 + 85      # Punto original si hay género
  right_anchor -= 8             # padding entre texto y icono
end

# Medir ancho del texto
level_width = overlay.text_size(level_text).width
# Calcular X para dibujar el texto (alineado a la derecha)
level_x = right_anchor - level_width +4
level_y = 12
pbDrawTextPositions(overlay, [[level_text, level_x, level_y, :left,
                              Color.new(48, 70, 102), Color.new(174, 180, 186)]])
pbSetSystemFont(overlay)


      # Habilidad
      label_x = 16 - 10     # posición inicial del texto fijo
      value_x = 100 + 30 - 18    # posición donde empieza el valor (habilidad u objeto)

  # --- HABILIDAD Y OBJETO CON SMALLFONT ---
small_texts = []

label_x = 4     # posición inicial del texto fijo
value_x = 80+2  # posición donde empieza el valor

# Habilidad
small_texts.push([_INTL("Habilidad"), label_x, 328+12+4+2, :left,
                  Color.new(246, 198, 6), Color.new(74, 97, 103)])
small_texts.push([pokemon.ability ? pokemon.ability.name : _INTL("Sin habilidad"),
                  value_x, 328+12+4+2, :left,
                  Color.new(248, 248, 248), Color.new(74, 112, 175)])

# Objeto
small_texts.push([_INTL("Objeto"), label_x, 360+17-2+2, :left,
                  Color.new(246, 198, 6), Color.new(74, 97, 103)])
small_texts.push([pokemon.item ? pokemon.item.name : _INTL("Sin objeto"),
                  value_x, 360+17-2+2, :left,
                  Color.new(248, 248, 248), Color.new(74, 112, 175)])

# Dibujamos con small font
pbSetSmallFont(overlay)
pbDrawTextPositions(overlay, small_texts)
pbSetSystemFont(overlay)  # Restauramos font normal

# --- Changed Shiny Icon ---
imagepos.push(["Graphics/UI/summary/icon_shiny", 68+160-4, 262 - 222]) if pokemon.shiny?

# --- Poké Ball ---
ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", pokemon.poke_ball)
imagepos.push([ballimage, 13 - 7, 302 - 300])

# --- Dibuja iconos de tipo personalizados ---
@typebitmap ||= AnimatedBitmap.new("Graphics/UI/types")   # Asegúrate de tener la bitmap cargada
pokemon.types.each_with_index do |type, i|
  type_data = GameData::Type.get(type)
  type_number = TYPE_ICON_INDEX[type_data.id] || 0

  icon_width  = 64
  icon_height = 28
  type_rect = Rect.new(0, type_number * icon_height, icon_width, icon_height)

  base_x = 42
  base_y = 302
  type_x = base_x + (i * 110)
  overlay.blt(type_x, base_y, @typebitmap.bitmap, type_rect)
end

# --- Changed Markings Position ---
drawMarkings(overlay, 86-32, 262+150+2, pokemon.markings)

# --- Dibujamos imágenes ---
pbDrawImagePositions(overlay, imagepos)

# --- Dibujamos cualquier otro texto que tengas en textstrings ---
pbDrawTextPositions(overlay, textstrings)

# --- Actualizamos sprite del Pokémon ---
@sprites["pokemon"].setPokemonBitmap(pokemon)
end
end
end

#===============================================================================
# Pokémon storage mechanics
#===============================================================================
class PokemonStorageScreen
  attr_reader :scene
  attr_reader :storage
  attr_accessor :heldpkmn

  def initialize(scene, storage)
    @scene = scene
    @storage = storage
    @pbHeldPokemon = nil
  end

  def pbStartScreen(command)
    $game_temp.in_storage = true
    @heldpkmn = nil
    case command
    when 0   # Organise
      @scene.pbStartBox(self, command)
      loop do
        selected = @scene.pbSelectBox(@storage.party)
        if selected.nil?
          if pbHeldPokemon
            pbDisplay(_INTL("¡Llevas un Pokémon!"))
            next
          end
          next if pbConfirm(_INTL("¿Continuar operaciones?"))
          break
        elsif selected[0] == -3   # Close box
          if pbHeldPokemon
            pbDisplay(_INTL("¡Llevas un Pokémon!"))
            next
          end
          if pbConfirm(_INTL("¿Salir del PC?"))
            pbSEPlay("PC close")
            break
          end
          next
        elsif selected[0] == -4   # Box name
          pbBoxCommands
        else
          pokemon = @storage[selected[0], selected[1]]
          heldpoke = pbHeldPokemon
          next if !pokemon && !heldpoke
          if @scene.quickswap
            if @heldpkmn
              (pokemon) ? pbSwap(selected) : pbPlace(selected)
            else
              pbHold(selected)
            end
          else
            commands = []
            cmdMove     = -1
            cmdSummary  = -1
            cmdWithdraw = -1
            cmdItem     = -1
            cmdMark     = -1
            cmdRelease  = -1
            cmdDebug    = -1
            if heldpoke
              helptext = _INTL("Has seleccionado a {1}.", heldpoke.name)
              commands[cmdMove = commands.length] = (pokemon) ? _INTL("Cambiar") : _INTL("Dejar")
            elsif pokemon
              helptext = _INTL("Has seleccionado a {1}.", pokemon.name)
              commands[cmdMove = commands.length] = _INTL("Mover")
            end
            commands[cmdSummary = commands.length]  = _INTL("Datos")
            commands[cmdWithdraw = commands.length] = (selected[0] == -1) ? _INTL("Guardar") : _INTL("Sacar")
            commands[cmdItem = commands.length]     = _INTL("Objeto")
            commands[cmdMark = commands.length]     = _INTL("Marcas")
            commands[cmdRelease = commands.length]  = _INTL("Liberar")
            commands[cmdDebug = commands.length]    = _INTL("Debug") if $DEBUG
            commands[commands.length]               = _INTL("Cancelar")
            command = pbShowCommands(helptext, commands)
            if cmdMove >= 0 && command == cmdMove   # Move/Shift/Place
              if @heldpkmn
                (pokemon) ? pbSwap(selected) : pbPlace(selected)
              else
                pbHold(selected)
              end
            elsif cmdSummary >= 0 && command == cmdSummary   # Summary
              pbSummary(selected, @heldpkmn)
            elsif cmdWithdraw >= 0 && command == cmdWithdraw   # Store/Withdraw
              (selected[0] == -1) ? pbStore(selected, @heldpkmn) : pbWithdraw(selected, @heldpkmn)
            elsif cmdItem >= 0 && command == cmdItem   # Item
              pbItem(selected, @heldpkmn)
            elsif cmdMark >= 0 && command == cmdMark   # Mark
              pbMark(selected, @heldpkmn)
            elsif cmdRelease >= 0 && command == cmdRelease   # Release
              pbRelease(selected, @heldpkmn)
            elsif cmdDebug >= 0 && command == cmdDebug   # Debug
              pbPokemonDebug((@heldpkmn) ? @heldpkmn : pokemon, selected, heldpoke)
            end
          end
        end
      end
      @scene.pbCloseBox
    when 1   # Withdraw
      @scene.pbStartBox(self, command)
      loop do
        selected = @scene.pbSelectBox(@storage.party)
        if selected.nil?
          next if pbConfirm(_INTL("¿Continuar con las operaciones?"))
          break
        else
          case selected[0]
          when -2   # Party Pokémon
            pbDisplay(_INTL("¿Cuál quieres tomar?"))
            next
          when -3   # Close box
            if pbConfirm(_INTL("¿Salir del PC?"))
              pbSEPlay("PC close")
              break
            end
            next
          when -4   # Box name
            pbBoxCommands
            next
          end
          pokemon = @storage[selected[0], selected[1]]
          next if !pokemon
          command = pbShowCommands(_INTL("Has seleccionado a {1}.", pokemon.name),
                                   [_INTL("Sacar"),
                                    _INTL("Datos"),
                                    _INTL("Marcas"),
                                    _INTL("Liberar"),
                                    _INTL("Cancelar")])
          case command
          when 0 then pbWithdraw(selected, nil)
          when 1 then pbSummary(selected, nil)
          when 2 then pbMark(selected, nil)
          when 3 then pbRelease(selected, nil)
          end
        end
      end
      @scene.pbCloseBox
    when 2   # Deposit
      @scene.pbStartBox(self, command)
      loop do
        selected = @scene.pbSelectParty(@storage.party)
        if selected == -3   # Close box
          if pbConfirm(_INTL("¿Salir del PC?"))
            pbSEPlay("PC close")
            break
          end
          next
        elsif selected < 0
          next if pbConfirm(_INTL("¿Continuar con las operacions?"))
          break
        else
          pokemon = @storage[-1, selected]
          next if !pokemon
          command = pbShowCommands(_INTL("Has seleccionado a {1}.", pokemon.name),
                                   [_INTL("Dejar"),
                                    _INTL("Datos"),
                                    _INTL("Marcar"),
                                    _INTL("Liberar"),
                                    _INTL("Cancelar")])
          case command
          when 0 then pbStore([-1, selected], nil)
          when 1 then pbSummary([-1, selected], nil)
          when 2 then pbMark([-1, selected], nil)
          when 3 then pbRelease([-1, selected], nil)
          end
        end
      end
      @scene.pbCloseBox
    when 3
      @scene.pbStartBox(self, command)
      @scene.pbCloseBox
    end
    $game_temp.in_storage = false
  end

  def pbUpdate   # For debug
    @scene.update
  end

  def pbHardRefresh   # For debug
    @scene.pbHardRefresh
  end

  def pbRefreshSingle(i)   # For debug
    @scene.pbUpdateOverlay(i[1], (i[0] == -1) ? @storage.party : nil)
    @scene.pbHardRefresh
  end

  def pbDisplay(message)
    @scene.pbDisplay(message)
  end

  def pbConfirm(str)
    return pbShowCommands(str, [_INTL("Sí"), _INTL("No")]) == 0
  end

  def pbShowCommands(msg, commands, index = 0)
    return @scene.pbShowCommands(msg, commands, index)
  end

  def pbAble?(pokemon)
    pokemon && !pokemon.egg? && pokemon.hp > 0
  end

  def pbAbleCount
    count = 0
    @storage.party.each do |p|
      count += 1 if pbAble?(p)
    end
    return count
  end

  def pbHeldPokemon
    return @heldpkmn
  end

  def pbWithdraw(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    raise _INTL("No se puede sacar del equipo...") if box == -1
    if @storage.party_full?
      pbDisplay(_INTL("¡Tu equipo está lleno!"))
      return false
    end
    @scene.pbWithdraw(selected, heldpoke, @storage.party.length)
    if heldpoke
      @storage.pbMoveCaughtToParty(heldpoke)
      @heldpkmn = nil
    else
      @storage.pbMove(-1, -1, box, index)
    end
    @scene.pbRefresh
    return true
  end
  def pbStore(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    raise _INTL("No se puede depositar...") if box != -1
    if pbAbleCount <= 1 && pbAble?(@storage[box, index]) && !heldpoke
      pbPlayBuzzerSE
      pbDisplay(_INTL("¡Es tu último Pokémon!"))
    elsif heldpoke&.mail
      pbDisplay(_INTL("Debes retirar la carta que lleva."))
    elsif !heldpoke && @storage[box, index].mail
      pbDisplay(_INTL("Debes retirar la carta que lleva."))
    elsif heldpoke&.cannot_store
      pbDisplay(_INTL("¡{1} no quiere quedarse en el PC!", heldpoke.name))
    elsif !heldpoke && @storage[box, index].cannot_store
      pbDisplay(_INTL("¡{1} no quiere quedarse en el PC", @storage[box, index].name))
    else
      loop do
        destbox = @scene.pbChooseBox(_INTL("¿Dejar en qué caja?"))
        if destbox >= 0
          firstfree = @storage.pbFirstFreePos(destbox)
          if firstfree < 0
            pbDisplay(_INTL("La caja está llena."))
            next
          end
          if heldpoke || selected[0] == -1
            p = (heldpoke) ? heldpoke : @storage[-1, index]
            if Settings::HEAL_STORED_POKEMON
              old_ready_evo = p.ready_to_evolve
              p.heal
              p.ready_to_evolve = old_ready_evo
            end
          end
          @scene.pbStore(selected, heldpoke, destbox, firstfree)
          if heldpoke
            @storage.pbMoveCaughtToBox(heldpoke, destbox)
            @heldpkmn = nil
          else
            @storage.pbMove(destbox, -1, -1, index)
          end
        end
        break
      end
      @scene.pbRefresh
    end
  end

  def pbHold(selected)
    box = selected[0]
    index = selected[1]
    if box == -1 && pbAble?(@storage[box, index]) && pbAbleCount <= 1
      pbPlayBuzzerSE
      pbDisplay(_INTL("¡Es tu último Pokémon!"))
      return
    end
    @scene.pbHold(selected)
    @heldpkmn = @storage[box, index]
    @storage.pbDelete(box, index)
    @scene.pbRefresh
  end

  def pbPlace(selected)
    box = selected[0]
    index = selected[1]
    if @storage[box, index]
      raise _INTL("La posición {1},{2} no está vacía...", box, index)
    elsif box != -1
      if index >= @storage.maxPokemon(box)
        pbDisplay("No se puede dejar ahí.")
        return
      elsif @heldpkmn.mail
        pbDisplay("Debes retirar la carta que lleva.")
        return
      elsif @heldpkmn.cannot_store
        pbDisplay(_INTL("¡{1} no quiere quedarse en el PC", @heldpkmn.name))
        return
      end
    end
    if Settings::HEAL_STORED_POKEMON && box >= 0
      old_ready_evo = @heldpkmn.ready_to_evolve
      @heldpkmn.heal
      @heldpkmn.ready_to_evolve = old_ready_evo
    end
    @scene.pbPlace(selected, @heldpkmn)
    @storage[box, index] = @heldpkmn
    @storage.party.compact! if box == -1
    @scene.pbRefresh
    @heldpkmn = nil
  end

  def pbSwap(selected)
    box = selected[0]
    index = selected[1]
    if !@storage[box, index]
      raise _INTL("La posición {1},{2} está vacía...", box, index)
    end
    if @heldpkmn.cannot_store && box != -1
      pbPlayBuzzerSE
      pbDisplay(_INTL("¡{1} no quiere quedarse en el PC", @heldpkmn.name))
      return false
    elsif box == -1 && pbAble?(@storage[box, index]) && pbAbleCount <= 1 && !pbAble?(@heldpkmn)
      pbPlayBuzzerSE
      pbDisplay(_INTL("¡Es tu último Pokémon!"))
      return false
    end
    if box != -1 && @heldpkmn.mail
      pbDisplay("Debes retirar la carta que lleva.")
      return false
    end
    if Settings::HEAL_STORED_POKEMON && box >= 0
      old_ready_evo = @heldpkmn.ready_to_evolve
      @heldpkmn.heal
      @heldpkmn.ready_to_evolve = old_ready_evo
    end
    @scene.pbSwap(selected, @heldpkmn)
    tmp = @storage[box, index]
    @storage[box, index] = @heldpkmn
    @heldpkmn = tmp
    @scene.pbRefresh
    return true
  end

  def pbRelease(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    pokemon = (heldpoke) ? heldpoke : @storage[box, index]
    return if !pokemon
    if pokemon.egg?
      pbDisplay(_INTL("No puedes liberar un Huevo."))
      return false
    elsif pokemon.mail
      pbDisplay(_INTL("Debes retirar la carta que lleva."))
      return false
    elsif pokemon.cannot_release
      pbDisplay(_INTL("¡{1} no quiere separarse de ti!", pokemon.name))
      return false
    end
    if box == -1 && pbAbleCount <= 1 && pbAble?(pokemon) && !heldpoke
      pbPlayBuzzerSE
      pbDisplay(_INTL("¡Es tu último Pokémon!"))
      return
    end
    command = pbShowCommands(_INTL("¿Liberar este Pokémon?"), [_INTL("No"), _INTL("Sí")])
    if command == 1
      pkmnname = pokemon.name
      @scene.pbRelease(selected, heldpoke)
      if heldpoke
        @heldpkmn = nil
      else
        @storage.pbDelete(box, index)
      end
      @scene.pbRefresh
      pbDisplay(_INTL("Has liberado a {1}.", pkmnname))
      pbDisplay(_INTL("¡Hasta siempre, {1}!", pkmnname))
      @scene.pbRefresh
    end
    return
  end

  def pbChooseMove(pkmn, helptext, index = 0)
    movenames = []
    pkmn.moves.each do |i|
      if i.total_pp <= 0
        movenames.push(_INTL("{1} (PP: ---)", i.name))
      else
        movenames.push(_INTL("{1} (PP: {2}/{3})", i.name, i.pp, i.total_pp))
      end
    end
    return @scene.pbShowCommands(helptext, movenames, index)
  end

  def pbSummary(selected, heldpoke)
    @scene.pbSummary(selected, heldpoke)
  end

  def pbMark(selected, heldpoke)
    @scene.pbMark(selected, heldpoke)
  end

  def pbItem(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    pokemon = (heldpoke) ? heldpoke : @storage[box, index]
    if pokemon.egg?
      pbDisplay(_INTL("Los Huevos no pueden llevar objetos."))
      return
    elsif pokemon.mail
      pbDisplay(_INTL("Debes retirar la carta que lleva."))
      return
    end
    if pokemon.item
      itemname = pokemon.item.portion_name
      if pbConfirm(_INTL("¿Tomar {1}?", itemname))
        if $bag.add(pokemon.item)
          pbDisplay(_INTL("Has tomado {1}.", itemname))
          pokemon.item = nil
          @scene.pbHardRefresh
        else
          pbDisplay(_INTL("No se puede guardar {1}.", itemname))
        end
      end
    else
      item = scene.pbChooseItem($bag)
      if item
        itemname = GameData::Item.get(item).name
        pokemon.item = item
        $bag.remove(item)
        pbDisplay(_INTL("Has equipado {1}.", itemname))
        @scene.pbHardRefresh
      end
    end
  end

  def pbBoxCommands
    commands = [
      _INTL("Saltar"),
      _INTL("Nombre"),
      _INTL("Cancelar")
    ]
    command = pbShowCommands(_INTL("¿Qué deseas hacer?"), commands)
    case command
    when 0   # Saltar
      destbox = @scene.pbChooseBox(_INTL("¿Saltar a qué Caja?"))
      @scene.pbJumpToBox(destbox) if destbox >= 0
    when 1   # Nombre
      @scene.pbBoxName(_INTL("Introduce el nombre de la caja"), 0, 12)
    end
  end


  def pbChoosePokemon(_party = nil)
    $game_temp.in_storage = true
    @heldpkmn = nil
    @scene.pbStartBox(self, 1)
    retval = nil
    loop do
      selected = @scene.pbSelectBox(@storage.party)
      if selected && selected[0] == -3   # Close box
        if pbConfirm(_INTL("¿Salir de la Caja"))
          pbSEPlay("PC close")
          break
        end
        next
      end
      if selected.nil?
        next if pbConfirm(_INTL("¿Continuar con las operaciones?"))
        break
      elsif selected[0] == -4   # Box name
        pbBoxCommands
      else
        pokemon = @storage[selected[0], selected[1]]
        next if !pokemon
        commands = [
          _INTL("Seleccionar"),
          _INTL("Datos"),
          _INTL("Sacar"),
          _INTL("Objeto"),
          _INTL("Marcas")
        ]
        commands.push(_INTL("Cancelar"))
        commands[2] = _INTL("Guardar") if selected[0] == -1
        helptext = _INTL("Has seleccionado a {1}", pokemon.name)
        command = pbShowCommands(helptext, commands)
        case command
        when 0   # Select
          if pokemon
            retval = selected
            break
          end
        when 1
          pbSummary(selected, nil)
        when 2   # Store/Withdraw
          if selected[0] == -1
            pbStore(selected, nil)
          else
            pbWithdraw(selected, nil)
          end
        when 3
          pbItem(selected, nil)
        when 4
          pbMark(selected, nil)
        end
      end
    end
    @scene.pbCloseBox
    $game_temp.in_storage = false
    return retval
  end
end

#===============================================================================
#  Battle Bag interface
#  UI overhaul by Luka S.J
#  Porteado a BES y mejorado por Clara
#  Porteado a v21.1 por Maryn, DPertierra y Skyflyer
#===============================================================================
class NewBattleBag
  POCKET_TEXT = [_INTL("Medicinas"), _INTL("Poké Balls"), _INTL("Bayas"), _INTL("Objeto Batalla")]
  attr_accessor :index, :ret, :finished
  
  def initialize(scene, viewport)
    @scene = scene
    $lastUsed ||= nil
    offset = 0
    @background = Viewport.new(0, offset, Graphics.width, Graphics.height)
    @background.z = viewport.z + 5
    @viewport = Viewport.new(0, offset, Graphics.width, Graphics.height)
    @viewport.z = viewport.z + 5
    @lastUsed = $lastUsed
    @index = 0
    @item = 0
    @finished = false
    @disposed = true
    @page = -1
    @selPocket = 0
    @ret = nil
    @over = false
    @baseColor = Color.new(252, 252, 252)
    @shadowColor = Color.new(48, 48, 48)
    @offsetX = (Graphics.width - 512) / 2
    @offsetY = (Graphics.height - 384) / 2
    
    @sprites = {}
    @items = {}
    @bitmaps = []
    
    @spritesCreated = false
    createSprites
  end
  
  def createSprites
    return if @spritesCreated
    
    @bitmaps = [
      AnimatedBitmap.new(File.join("Graphics", "UI", "Mochila EBDX", "battleBagChoices")),
      AnimatedBitmap.new(File.join("Graphics", "UI", "Mochila EBDX", "battleBagLast")),
      AnimatedBitmap.new(File.join("Graphics", "UI", "Mochila EBDX", "battleBackButtons"))
    ]
    
    @sprites["back"] = Sprite.new(@background)
    @sprites["back"].bitmap = AnimatedBitmap.new(File.join("Graphics", "UI", "Mochila EBDX", "shadeFull")).bitmap
    @sprites["back"].opacity = 0

    @sprites["sel"] = Sprite.new(@viewport)
    @sprites["sel"].x = -216
    @sprites["sel"].y = 34
    @sprites["sel"].z += 1
    
    @sprites["name"] = Sprite.new(@viewport)
    @sprites["name"].bitmap = Bitmap.new(380, 44)
    pbSetSystemFont(@sprites["name"].bitmap)
    @sprites["name"].x = -380
    @sprites["name"].y = 328
    
    for i in 0...4
      @sprites["pocket#{i}"] = Sprite.new(@viewport)
      @sprites["pocket#{i}"].bitmap = @bitmaps[0].bitmap
      @sprites["pocket#{i}"].src_rect.set(216 * i, 0, 216, 92)
      @sprites["pocket#{i}"].z -= 1
      
      wdt = @sprites["pocket#{i}"].bitmap.width / 6
      hgt = @sprites["pocket#{i}"].bitmap.height

      @sprites["pocket#{i}"].x = @offsetX + 26 + (i % 2) * (wdt + 26) + ((i % 2 == 0) ? -260 : 260)
      @sprites["pocket#{i}"].y = @offsetY + 56 + (i / 2) * (hgt + 32)

      x = @offsetX + 16 + (i % 2) * wdt + 26 + ((i % 2 == 0) ? 0 : 26)
      y = @offsetY + 86 + (i / 2) * (hgt + 32)
      
      @sprites["overlay#{i}"] = Sprite.new(@viewport)
      @sprites["overlay#{i}"].bitmap = Bitmap.new(512, 384)
      pbSetSystemFont(@sprites["overlay#{i}"].bitmap)

      pbDrawOutlineText(@sprites["overlay#{i}"].bitmap, x, y, wdt - 26, hgt, 
                        _INTL("{1}", POCKET_TEXT[i]), @baseColor, @shadowColor, 1)
    end

    @sprites["pocket4"] = Sprite.new(@viewport)
    @sprites["pocket4"].bitmap = Bitmap.new(356, 60)
    pbSetSystemFont(@sprites["pocket4"].bitmap)
    @sprites["pocket4"].x = 24 + @offsetX
    @sprites["pocket4"].y = 316 + 80 + @offsetY
    self.refresh
    
    @sprites["pocket5"] = Sprite.new(@viewport)
    @sprites["pocket5"].bitmap = @bitmaps[2].bitmap
    @sprites["pocket5"].src_rect.set(0, 0, 120, 52)
    @sprites["pocket5"].x = 384 + @offsetX
    @sprites["pocket5"].y = 320 + 80 + @offsetY
    @sprites["pocket5"].z = 5
    
    @sprites["confirm"] = Sprite.new(@viewport)
    @sprites["confirm"].bitmap = Bitmap.new(466, 156)
    pbSetSmallFont(@sprites["confirm"].bitmap)
    @sprites["confirm"].x = 26 - 520
    @sprites["confirm"].y = 80
    
    @sprites["cancel"] = Sprite.new(@viewport)
    @sprites["cancel"].bitmap = AnimatedBitmap.new(File.join("Graphics", "UI", "Mochila EBDX", "battleItemConfirm")).bitmap
    @sprites["cancel"].src_rect.set(466, 0, 466, 72)
    @sprites["cancel"].x = 26 - 520
    @sprites["cancel"].y = 234
    
    @spritesCreated = true
  end
  
  def disposeSprites
    return if !@spritesCreated
    
    pbDisposeSpriteHash(@sprites)
    @sprites = {}
    
    pbDisposeSpriteHash(@items)
    @items = {}
    
    @spritesCreated = false
  end
  
  def dispose
    return if @disposed
    
    disposeSprites
    
    @bitmaps.each { |bmp| bmp.dispose } if @bitmaps
    @bitmaps = []
    
    @background.dispose if @background && !@background.disposed?
    @viewport.dispose if @viewport && !@viewport.disposed?
    
    @disposed = true
  end
  
  def disposed?
    return @disposed
  end
  
  def checkPockets
    @mergedPockets = []
    for i in 1...$bag.pockets.length
      pocket = $bag.pockets[i]
      next if !pocket
      pocket.each do |item, quantity|
        @mergedPockets.push([item, quantity])
      end
    end
  end
  
  def canUseInBattle?(item)
    item_data = GameData::Item.get(item)
    return false if !item_data.battle_use || item_data.battle_use == 0
    return true if item_data.pocket == 2  
    return true if item_data.is_poke_ball? 
    return true if item_data.is_berry?      
    return true if item_data.pocket == 7 

    return false
  end

  def drawPocket(pocket, index)
    @pocket = []
    @pgtrigger = false
    self.checkPockets
    for item_data in @mergedPockets
      next if item_data.nil?
      item = item_data[0]
      item_obj = GameData::Item.get(item)
      next unless canUseInBattle?(item)
      case index
      when 0
        @pocket.push([item_data[0], item_data[1]]) if item_obj.pocket == 2 && GameData::Item.get(item).battle_use  
      when 1 
        @pocket.push([item_data[0], item_data[1]]) if item_obj.is_poke_ball? && GameData::Item.get(item).battle_use 
      when 2 
        @pocket.push([item_data[0], item_data[1]]) if item_obj.is_berry? && GameData::Item.get(item).battle_use 
      when 3 
        @pocket.push([item_data[0], item_data[1]]) if item_obj.pocket == 7 && GameData::Item.get(item).battle_use 
      end        
    end    
    if @pocket.length < 1
      pbPlayBuzzerSE
      return false
    end
    
    @xpos = []
    @pages = @pocket.length / 6
    @pages += 1 if @pocket.length % 6 > 0
    @page = 0
    @item = 0
    @back = false
    @selPocket = pocket + 1
    pbDisposeSpriteHash(@items)
    @items = {}
    @pname = POCKET_TEXT[index]
    
    x = 0
    y = 0
    for j in 0...@pocket.length
      i = j
      @items["#{j}"] = Sprite.new(@viewport)
      @items["#{j}"].bitmap = Bitmap.new(216, 96)
      pbSetSystemFont(@items["#{j}"].bitmap)
      @items["#{j}"].bitmap.blt(0, 0, @bitmaps[0].bitmap, Rect.new(216 * 5, 0, 216, 96))
      
      item_icon = GameData::Item.icon_filename(@pocket[i][0])
      icon_bitmap = AnimatedBitmap.new(item_icon)
      @items["#{j}"].bitmap.blt(156, 32, icon_bitmap.bitmap, Rect.new(0, 0, 48, 48))
      icon_bitmap.dispose
      
      item_name = GameData::Item.get(@pocket[i][0]).name
      pbDrawOutlineText(@items["#{j}"].bitmap, 8, 14, 200, 38, item_name, @baseColor, @shadowColor, 1)
      pbDrawOutlineText(@items["#{j}"].bitmap, 8, 48, 200, 38, "x#{@pocket[i][1]}", @baseColor, @shadowColor, 1)
      
      @items["#{j}"].x = 28 + x * 246 + (i / 6) * 512 + 512 + @offsetX
      @xpos.push(@items["#{j}"].x - 512)
      @items["#{j}"].y = 28 + y * 90 + @offsetY
      @items["#{j}"].opacity = 255
      
      x += 1
      y += 1 if x > 1
      x = 0 if x > 1
      y = 0 if y > 2
    end
    
    return true
  end
  
  def name
    bitmap = @sprites["name"].bitmap
    bitmap.clear
    lastitem_bmp = AnimatedBitmap.new(File.join("Graphics", "UI", "Mochila EBDX", "battleLastItem"))
    bitmap.blt(0, 0, lastitem_bmp.bitmap, Rect.new(0, 0, 320, 44))
    lastitem_bmp.dispose
    pbDrawOutlineText(bitmap, 0, 8, 320, 36, @pname, @baseColor, @shadowColor, 1)
    pbDrawOutlineText(bitmap, 300, 8, 80, 36, "#{@page + 1}/#{@pages}", @baseColor, @shadowColor, 1)
    @sprites["name"].x += 38 if @sprites["name"].x < 0
  end
  
def updatePocket
  @page = @item / 6
  self.name
  for i in 0...@pocket.length
    @items["#{i}"].x -= (@items["#{i}"].x - (@xpos[i] - @page * 512)) * 0.2
    @items["#{i}"].src_rect.y -= 1 if @items["#{i}"].src_rect.y > 0
  end
  
  if @back
    @sprites["sel"].bitmap = @bitmaps[2].bitmap
    @sprites["sel"].src_rect.set(120 * 2, 0, 120, 52)
    @sprites["sel"].x = @sprites["pocket5"].x
    @sprites["sel"].y = @sprites["pocket5"].y
    @sprites["sel"].z + 1
  else
    @sprites["sel"].bitmap = @bitmaps[0].bitmap
    @sprites["sel"].src_rect.set(216 * 4, 0, 216, 92)
    @sprites["sel"].x = @items["#{@item}"].x
    @sprites["sel"].y = @items["#{@item}"].y
  end
  
  @sprites["pocket5"].src_rect.y -= 1 if @sprites["pocket5"].src_rect.y > 0
  
  if Input.trigger?(Input::LEFT) && !@back
    pbPlayCursorSE
    if ![0, 2, 4].include?(@item)
      if @item % 2 == 0
        @item -= 5
      else
        @item -= 1
      end
    else
      @item -= 1 if @item > 0
    end
    @item = 0 if @item < 0
    @items["#{@item}"].src_rect.y += 6
  elsif Input.trigger?(Input::RIGHT) && !@back
    pbPlayCursorSE
    if @page < (@pocket.length) / 6
      if @item % 2 == 1
        @item += 5
      else
        @item += 1
      end
    else
      @item += 1 if @item < @pocket.length - 1 
    end
    @item = @pocket.length - 1 if @item > @pocket.length - 1
    @items["#{@item}"].src_rect.y += 6
  elsif Input.trigger?(Input::UP)
    pbPlayCursorSE
    if @back
      @item += 4 if (@item % 6) < 2
      @back = false
    else
      @item -= 2
      if (@item % 6) > 3
        @item += 6
        @back = true
      end
    end
    @item = 0 if @item < 0
    @item = @pocket.length - 1 if @item > @pocket.length - 1
    @items["#{@item}"].src_rect.y += 6 if !@back
    @sprites["pocket5"].src_rect.y += 6 if @back
  elsif Input.trigger?(Input::DOWN)
    pbPlayCursorSE
    if @back
      @item -= 4 if (@item % 6) > 3
      @back = false
    else
      @item += 2
      if (@item % 6) < 2
        @item -= 6
        @back = true
      end
      @back = true if @item > @pocket.length - 1
    end
    @item = @pocket.length - 1 if @item > @pocket.length - 1
    @item = 0 if @item < 0
    @items["#{@item}"].src_rect.y += 6 if !@back
    @sprites["pocket5"].src_rect.y += 6 if @back
  end
  
  @over = false
  if Input.trigger?(Input::USE) && !@back
    self.intoPocket
  elsif Input.trigger?(Input::USE) && @back
    pbPlayCancelSE
    self.closeCurrent
  elsif Input.trigger?(Input::BACK)
    pbPlayCancelSE
    self.closeCurrent
  end
end
  
  def closeCurrent
    @selPocket = 0
    @page = -1
    @back = false
    @ret = nil
    self.refresh
  end
  
  def show
    createSprites if !@spritesCreated
    
    @ret = nil
    @sprites["back"].opacity = 0
    
    pbSEPlay("GUI storage show")
    10.times do
      for i in 0...4
        @sprites["pocket#{i}"].x += ((i % 2 == 0) ? 26 : -26)
        @sprites["overlay#{i}"].opacity += 25.5 if @sprites["overlay#{i}"]
      end
      for i in 4...6
        @sprites["pocket#{i}"].y -= 8
      end
      @sprites["back"].opacity += 25.5
      Graphics.update
      Input.update
    end
    
    self.refresh
  end
  
  def hide
    return if !@spritesCreated
    
    @sprites["sel"].x = Graphics.width
    10.times do
      for i in 0...4
        @sprites["pocket#{i}"].x -= ((i % 2 == 0) ? 46 : -46)
        @sprites["overlay#{i}"].opacity -= 25.5 if @sprites["overlay#{i}"]
      end
      for i in 4...6
        @sprites["pocket#{i}"].y += 8
      end
      if @pocket
        for i in 0...@pocket.length
          @items["#{i}"].opacity -= 25.5 if @items["#{i}"]
        end
      end
      @sprites["name"].x -= 38 if @sprites["name"].x > -380
      @sprites["back"].opacity -= 25.5
      Graphics.update
      Input.update
    end
    
    disposeSprites
  end
  
  def useItem?
    loop do
      Graphics.update
      Input.update
      break unless Input.press?(Input::USE) || Input.press?(Input::BACK)
    end
    
    Input.update
    
    bitmap = @sprites["confirm"].bitmap
    bitmap.clear
    confirm_bmp = AnimatedBitmap.new(File.join("Graphics", "UI", "Mochila EBDX", "battleItemConfirm"))
    bitmap.blt(0, 0, confirm_bmp.bitmap, Rect.new(0, 0, 466, 156))
    confirm_bmp.dispose
    
    item_icon = GameData::Item.icon_filename(@ret)
    icon_bitmap = AnimatedBitmap.new(item_icon)
    bitmap.blt(20, 30, icon_bitmap.bitmap, Rect.new(0, 0, 48, 48))
    icon_bitmap.dispose
    
    item_desc = GameData::Item.get(@ret).description
    drawTextEx(bitmap, 80, 16, 364, 3, item_desc, Color.new(80, 80, 88), Color.new(160, 160, 168))

    confirm_bmp2 = AnimatedBitmap.new(File.join("Graphics", "UI", "Mochila EBDX", "battleItemConfirm"))
    @sprites["sel"].bitmap = confirm_bmp2.bitmap
    confirm_bmp2.dispose
    @sprites["sel"].x = Graphics.width
    @sprites["sel"].src_rect.width = 466
    @sprites["sel"].z += 1
    
    @sprites["overlay2_1"] = Sprite.new(@viewport)
    @sprites["overlay2_1"].bitmap = Bitmap.new(512, 384)
    @sprites["overlay2_2"] = Sprite.new(@viewport)
    @sprites["overlay2_2"].bitmap = Bitmap.new(512, 384)
    pbSetSystemFont(@sprites["overlay2_1"].bitmap)
    pbSetSystemFont(@sprites["overlay2_2"].bitmap)
    pbDrawOutlineText(@sprites["overlay2_1"].bitmap, 0, 218 - 32, 512, 384, _INTL("USAR"), @baseColor, @shadowColor, 1)
    pbDrawOutlineText(@sprites["overlay2_2"].bitmap, 0, 280 - 22, 512, 384, _INTL("NO USAR"), @baseColor, @shadowColor, 1)
    
    10.times do
      @sprites["overlay2_1"].opacity += 52 if @sprites["overlay2_1"].opacity <= 255
      @sprites["overlay2_2"].opacity += 52 if @sprites["overlay2_2"].opacity <= 255
      @sprites["confirm"].x += 52
      @sprites["cancel"].x += 52
      if @pocket
        for i in 0...@pocket.length
          @items["#{i}"].opacity -= 25.5
        end
      end
      for i in 0...4
        @sprites["pocket#{i}"].opacity -= 51 if @sprites["pocket#{i}"].opacity > 0
        @sprites["overlay#{i}"].opacity = @sprites["pocket#{i}"].opacity if @sprites["overlay#{i}"]
      end
      @sprites["pocket4"].y += 8 if @sprites["pocket4"].y < 316 + 80
      @sprites["pocket5"].y += 8 if @sprites["pocket5"].y < 400
      @sprites["name"].x -= 38
      Graphics.update
      Input.update
    end
    @sprites["name"].x = -380
    
    index = 0
    choice = (index == 0) ? "confirm" : "cancel"
    overlay = (index == 0) ? "overlay2_1" : "overlay2_2"
    
    loop do
      Graphics.update
      Input.update
      @sprites["sel"].x = @sprites["#{choice}"].x
      @sprites["sel"].y = @sprites["#{choice}"].y
      @sprites["sel"].src_rect.x = (466 * (index + 2))
      @sprites["#{choice}"].src_rect.y -= 1 if @sprites["#{choice}"].src_rect.y > 0
      @sprites["#{overlay}"].src_rect.y -= 1 if @sprites["#{overlay}"].src_rect.y > 0
      
      if Input.trigger?(Input::UP)
        pbPlayCursorSE
        index -= 1
        index = 1 if index < 0
        choice = (index == 0) ? "confirm" : "cancel"
        overlay = (index == 0) ? "overlay2_1" : "overlay2_2"
        @sprites["#{choice}"].src_rect.y += 6
        @sprites["#{overlay}"].src_rect.y += 6
      elsif Input.trigger?(Input::DOWN)
        pbPlayCursorSE
        index += 1
        index = 0 if index > 1
        choice = (index == 0) ? "confirm" : "cancel"
        overlay = (index == 0) ? "overlay2_1" : "overlay2_2"
        @sprites["#{choice}"].src_rect.y += 6
        @sprites["#{overlay}"].src_rect.y += 6
      end
      
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        break
      end
      if Input.trigger?(Input::BACK)
        pbPlayCancelSE
        index = 1
        break
      end
    end
    
    @sprites["sel"].x = Graphics.width
    
    if @sprites["overlay2_1"]
      @sprites["overlay2_1"].bitmap.dispose
      @sprites["overlay2_1"].dispose
      @sprites.delete("overlay2_1")
    end
    if @sprites["overlay2_2"]
      @sprites["overlay2_2"].bitmap.dispose
      @sprites["overlay2_2"].dispose
      @sprites.delete("overlay2_2")
    end
    
    10.times do
      @sprites["confirm"].x -= 52
      @sprites["cancel"].x -= 52
      @sprites["pocket5"].y -= 8 if index > 0
      if @pocket && index > 0
        for i in 0...@pocket.length
          @items["#{i}"].opacity += 25.5 if @items["#{i}"]
        end
      end
      for i in 0...4
        @sprites["pocket#{i}"].opacity += 51 if @sprites["pocket#{i}"].opacity < 255 && index > 0
        @sprites["overlay#{i}"].opacity = @sprites["pocket#{i}"].opacity if @sprites["overlay#{i}"]
      end
      @sprites["pocket4"].y -= 8 if @sprites["pocket4"].y > 316 && index > 0
      Graphics.update
      Input.update
    end
    
    if index > 0
      self.refresh
      return false
    else
      @index = 0 if @index == 4 && @lastUsed.nil?
      return true
    end
  end
  
  def refresh
    bitmap = @sprites["pocket4"].bitmap
    bitmap.clear
    i = (@lastUsed ? 1 : 0)
    text = [_INTL("Último objeto usado"), @lastUsed ? GameData::Item.get(@lastUsed).name : ""]
    bitmap.blt(0, 0, @bitmaps[1].bitmap, Rect.new(i * 356, 0, 356, 60))
    if @lastUsed
      item_icon = GameData::Item.icon_filename(@lastUsed)
      icon_bitmap = AnimatedBitmap.new(item_icon)
      bitmap.blt(28, 6, icon_bitmap.bitmap, Rect.new(0, 0, 48, 48))
      icon_bitmap.dispose
    end
    pbDrawOutlineText(bitmap, 0, 22, 358, 60, text[i], @baseColor, @shadowColor, 1)
  end
  
  def update
    pbUpdateSpriteHash(@sprites)
    pbUpdateSpriteHash(@items)
    
    if @selPocket == 0
      updateMain
      for i in 0...4
        @sprites["pocket#{i}"].opacity += 51 if @sprites["pocket#{i}"].opacity < 255
        @sprites["overlay#{i}"].opacity = @sprites["pocket#{i}"].opacity if @sprites["overlay#{i}"]
      end
      @sprites["pocket4"].y -= 8 if @sprites["pocket4"].y > 316
      @sprites["pocket5"].y -= 8 if @sprites["pocket5"].y > 320
      if @pocket
        for i in 0...@pocket.length
          @items["#{i}"].opacity -= 51 if @items["#{i}"] && @items["#{i}"].opacity > 0
        end
      end
      @sprites["name"].x -= 38 if @sprites["name"].x > -380
    else
      updatePocket
      for i in 0...4
        @sprites["pocket#{i}"].opacity -= 51 if @sprites["pocket#{i}"].opacity > 0
        @sprites["overlay#{i}"].opacity = @sprites["pocket#{i}"].opacity if @sprites["overlay#{i}"]
      end
      @sprites["pocket4"].y += 8 if @sprites["pocket4"].y < 316 + 80
      for i in 0...@pocket.length
        @items["#{i}"].opacity += 51 if @items["#{i}"] && @items["#{i}"].opacity < 255
      end
    end
  end
  
  def updateMain
    if @index < 4
      @sprites["sel"].bitmap = @bitmaps[0].bitmap
      @sprites["sel"].src_rect.set(216 * 4, 0, 216, 92)
    elsif @index == 4
      @sprites["sel"].bitmap = @bitmaps[1].bitmap
      @sprites["sel"].src_rect.set(356 * 2, 0, 356, 60)
    else
      @sprites["sel"].bitmap = @bitmaps[2].bitmap
      @sprites["sel"].src_rect.set(120 * 2, 0, 120, 52)
    end
    @sprites["sel"].z += 1
    @sprites["sel"].x = @sprites["pocket#{@index}"].x
    @sprites["sel"].y = @sprites["pocket#{@index}"].y
    
    if Input.trigger?(Input::LEFT)
      pbPlayCursorSE
      @index -= 1
      @index += 2 if @index % 2 == 1
      @index = 3 if @index == 4 && !@lastUsed
      @sprites["pocket#{@index}"].src_rect.y += 6
      @sprites["overlay#{@index}"].src_rect.y += 6 if @sprites["overlay#{@index}"]
    elsif Input.trigger?(Input::RIGHT)
      pbPlayCursorSE
      @index += 1
      @index -= 2 if @index % 2 == 0
      @index = 2 if @index == 4 && !@lastUsed
      @sprites["pocket#{@index}"].src_rect.y += 6
      @sprites["overlay#{@index}"].src_rect.y += 6 if @sprites["overlay#{@index}"]
    elsif Input.trigger?(Input::UP)
      pbPlayCursorSE
      @index -= 2
      @index += 6 if @index < 0
      @index = 5 if @index == 4 && !@lastUsed
      @sprites["pocket#{@index}"].src_rect.y += 6
      @sprites["overlay#{@index}"].src_rect.y += 6 if @sprites["overlay#{@index}"]
    elsif Input.trigger?(Input::DOWN)
      pbPlayCursorSE
      @index += 2
      @index -= 6 if @index > 5
      @index = 5 if @index == 4 && !@lastUsed
      @sprites["pocket#{@index}"].src_rect.y += 6
      @sprites["overlay#{@index}"].src_rect.y += 6 if @sprites["overlay#{@index}"]
    end
    
    @over = false
    for i in 0...6
      @sprites["pocket#{i}"].src_rect.y -= 1 if @sprites["pocket#{i}"].src_rect.y > 0
      @sprites["overlay#{i}"].src_rect.y -= 1 if @sprites["overlay#{i}"].src_rect.y > 0 if @sprites["overlay#{i}"]
    end
    
    @doubleback = false
    @finished = false

    if Input.trigger?(Input::USE) && !@doubleback && @index < 5
      self.confirm
    elsif (Input.trigger?(Input::BACK) || (Input.trigger?(Input::USE) && @index == 5)) && @selPocket == 0 && !@doubleback
      self.finish
    end
  end
  
  def finish
    pbPlayCancelSE
    @finished = true
    Input.update
  end
  
  def confirm
    pbPlayDecisionSE
    if @index < 4
      result = self.drawPocket(@index, @index)
      if result == false
        @selPocket = 0
        @page = -1
      end
    else
      @selPocket = 0
      @page = -1
      @ret = @lastUsed
      @lastUsed = nil if !($bag.quantity(@lastUsed) > 1)
    end
  end
  
  def intoPocket
    pbPlayDecisionSE
    @selPocket = 0
    @page = -1
    @lastUsed = nil
    @lastUsed = @pocket[@item][0] if @pocket[@item][1] > 1
    $lastUsed = @lastUsed
    @ret = @pocket[@item][0]
  end
end

class Battle::Scene
  alias pbItemMenu_ebs pbItemMenu unless method_defined?(:pbItemMenu_ebs)

  def pbItemMenu(idxBattler, _firstAction)
    @bagWindow = NewBattleBag.new(self, @viewport)
    @bagWindow.show

    loop do
  Graphics.update
  Input.update
  @bagWindow.update
      
      if @bagWindow.finished
        @bagWindow.hide
        @bagWindow.dispose
        @bagWindow = nil
        return
      end
      
      if !@bagWindow.ret.nil?
        if @bagWindow.useItem?
          chosen_item = @bagWindow.ret
          item_data = GameData::Item.get(chosen_item)
          useType = item_data.battle_use || 0

          case useType
          when 1, 2, 3
            idxPartyRet = -1
            idxMove = -1
            @bagWindow.hide
            
            pbFadeOutIn do
              partyScene = PokemonParty_Scene.new
              partyScreen = PokemonPartyScreen.new(partyScene, @battle.pbParty(idxBattler))
              partyScene.pbStartScene(@battle.pbParty(idxBattler), _INTL("¿Usar en qué Pokémon?"))
              
              idxPartyRet = partyScreen.pbChoosePokemon
              
              if idxPartyRet >= 0 && useType == 2
                pbPlayDecisionSE
                idxMove = partyScreen.pbChooseMove(
                  @battle.pbParty(idxBattler)[idxPartyRet],
                  _INTL("¿Qué movimiento restaurar?")
                )
                idxPartyRet = -1 if idxMove < 0
              end
              
              partyScene.pbEndScene
            end

            if idxPartyRet >= 0
              @bagWindow.dispose
              @bagWindow = nil
              yield(chosen_item, useType, idxPartyRet, idxMove, self) if block_given?
              return
            else
              @bagWindow.dispose if @bagWindow
              @bagWindow = NewBattleBag.new(self, @viewport)
              @bagWindow.show
            end

          when 4
            if @battle.pbOpposingBattlerCount(idxBattler) == 1
              target_idx = -1
              @battle.allOtherSideBattlers(idxBattler).each { |b| target_idx = b.index }
              @bagWindow.hide
              @bagWindow.dispose
              @bagWindow = nil
              yield(chosen_item, useType, target_idx, -1, self) if block_given?
              return
            else
              @bagWindow.hide
              idxTarget = pbChooseTarget(idxBattler, GameData::Target.get(:Foe))
              if idxTarget >= 0
                @bagWindow.dispose
                @bagWindow = nil
                yield(chosen_item, useType, idxTarget, -1, self) if block_given?
                return
              else
                @bagWindow.dispose if @bagWindow
                @bagWindow = NewBattleBag.new(self, @viewport)
                @bagWindow.show
              end
            end

          when 5
            @bagWindow.hide
            @bagWindow.dispose
            @bagWindow = nil
            yield(chosen_item, useType, idxBattler, -1, self) if block_given?
            return

          else
            @bagWindow.hide
            @bagWindow.dispose
            @bagWindow = nil
            yield(chosen_item, useType, idxBattler, -1, self) if block_given?
            return
          end
        else
          @bagWindow.ret = nil
        end
      end
    end
  end

  alias pbDisposeSprites_ebs pbDisposeSprites unless method_defined?(:pbDisposeSprites_ebs)
  def pbDisposeSprites
    pbDisposeSprites_ebs
    if @bagWindow && !@bagWindow.disposed?
      @bagWindow.dispose
      @bagWindow = nil
    end
  end
end
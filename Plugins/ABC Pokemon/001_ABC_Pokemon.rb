#===============================================================================
# ABC Pokémon
# Autor: Zik
#===============================================================================

#-------------------------------------------------------------------------------
# Módulo para Gestión de Datos y Probabilidades
#-------------------------------------------------------------------------------
module ABCPokemonSystem
  @@variant_data = nil

  def self.load_variant_data
    if FileTest.exist?("Data/abc_pokemon.dat")
      @@variant_data = load_data("Data/abc_pokemon.dat")
    else
      @@variant_data = {}
    end
  end

  def self.variant_data
    self.load_variant_data if @@variant_data.nil?
    return @@variant_data
  end

  def self.roll_variant(species)
    data = self.variant_data
    return nil if !data.key?(species)
    
    sp_data = data[species]
    roll = rand(100)
    current_prob = 0
    
    sp_data[:variants].each_with_index do |variant, index|
      prob = sp_data[:probs][index]
      return variant if roll < current_prob + prob
      current_prob += prob
    end
    
    return nil # El porcentaje restante es para el Sprite Original.
  end

  def self.get_variant_metrics(species, variant)
    data = self.variant_data
    return nil if !data.key?(species)
    return data[species][:metrics][variant]
  end

  def self.save_abc_pbs
    path = "PBS/abc_pokemon.txt"
    File.open(path, "wb") do |f|
      f.write("\xEF\xBB\xBF")
      self.variant_data.each do |species, data|
        f.write("[#{species}]\r\n")
        f.write("Variants = #{data[:variants].join(",")}\r\n")
        f.write("Probabilities = #{data[:probs].join(",")}\r\n")
        data[:variants].each do |v|
          m = data[:metrics][v]
          f.write("BackSprite_#{v} = #{m[:back_sprite].join(",")}\r\n")
          f.write("FrontSprite_#{v} = #{m[:front_sprite].join(",")}\r\n")
          f.write("FrontSpriteAltitude_#{v} = #{m[:front_sprite_altitude]}\r\n")
          f.write("ShadowX_#{v} = #{m[:shadow_x]}\r\n")
          f.write("ShadowSize_#{v} = #{m[:shadow_size]}\r\n")
          if PluginManager.installed?("[DBK] Animated Pokémon System")
            f.write("ShadowSprite_#{v} = #{m[:shadow_sprite].join(",")}\r\n") if m[:shadow_sprite]
          end
        end
        f.write("\r\n")
      end
    end
    save_data(self.variant_data, "Data/abc_pokemon.dat")
  end
end

#-------------------------------------------------------------------------------
# Compilador para el PBS Custom
#-------------------------------------------------------------------------------
module Compiler
  class << self
    unless method_defined?(:abc_pokemon_compile_pbs_files)
      alias_method :abc_pokemon_compile_pbs_files, :compile_pbs_files
    end
    
    def compile_pbs_files
      abc_pokemon_compile_pbs_files
      compile_abc_pokemon
    end

    def compile_abc_pokemon
      path = "PBS/abc_pokemon.txt"
      return unless FileTest.exist?(path)
      
      compile_pbs_file_message_start(path)
      abc_data = {}
      
      File.open(path, "rb") do |f|
        FileLineData.file = path
        pbEachFileSection(f) do |contents, section_name|
          species = section_name.to_sym
          next if !GameData::Species.exists?(species)
          
          variants = contents["Variants"] ? contents["Variants"].split(",").map(&:strip) :[]
          probs = contents["Probabilities"] ? contents["Probabilities"].split(",").map(&:to_i) :[]
          
          if variants.length != probs.length
            raise _INTL("Las Variantes y Probabilidades no coinciden para {1} en abc_pokemon.txt", species)
          end
          
          abc_data[species] = {
            variants: variants,
            probs: probs,
            metrics: {}
          }
          
          base_metrics = GameData::SpeciesMetrics.get_species_form(species, 0)
          variants.each do |v|
            back = contents["BackSprite_#{v}"] ? contents["BackSprite_#{v}"].split(",").map(&:to_i) : base_metrics.back_sprite.clone
            front = contents["FrontSprite_#{v}"] ? contents["FrontSprite_#{v}"].split(",").map(&:to_i) : base_metrics.front_sprite.clone
            alt = contents["FrontSpriteAltitude_#{v}"] ? contents["FrontSpriteAltitude_#{v}"].to_i : base_metrics.front_sprite_altitude
            shadow_x = contents["ShadowX_#{v}"] ? contents["ShadowX_#{v}"].to_i : base_metrics.shadow_x
            shadow_size = contents["ShadowSize_#{v}"] ? contents["ShadowSize_#{v}"].to_i : base_metrics.shadow_size
            shadow_sprite = contents["ShadowSprite_#{v}"] ? contents["ShadowSprite_#{v}"].split(",").map(&:to_i) : (base_metrics.respond_to?(:shadow_sprite) ? base_metrics.shadow_sprite.clone : [0,0,0])
            
            abc_data[species][:metrics][v] = {
              back_sprite: back,
              front_sprite: front,
              front_sprite_altitude: alt,
              shadow_x: shadow_x,
              shadow_size: shadow_size,
              shadow_sprite: shadow_sprite
            }
          end
        end
      end
      
      save_data(abc_data, "Data/abc_pokemon.dat")
      process_pbs_file_message_end
    end
  end
end

#-------------------------------------------------------------------------------
# Clase Pokemon
#-------------------------------------------------------------------------------
class Pokemon
  attr_accessor :abc_variant

  unless method_defined?(:abc_pokemon_initialize)
    alias_method :abc_pokemon_initialize, :initialize
  end
  
  def initialize(species, level, owner = $player, withMoves = true, recheck_form = true)
    abc_pokemon_initialize(species, level, owner, withMoves, recheck_form)
    @abc_variant = ABCPokemonSystem.roll_variant(@species)
  end
end

#-------------------------------------------------------------------------------
# Inyección de Sprites
#-------------------------------------------------------------------------------
module GameData
  class Species
    class << self
      unless method_defined?(:abc_pokemon_sprite_bitmap_from_pokemon)
        alias_method :abc_pokemon_sprite_bitmap_from_pokemon, :sprite_bitmap_from_pokemon
        alias_method :abc_pokemon_icon_filename_from_pokemon, :icon_filename_from_pokemon
      end
      
      def sprite_bitmap_from_pokemon(pkmn, back = false, species = nil)
        if pkmn && pkmn.abc_variant && !pkmn.egg?
          species_sym = species || pkmn.species
          species_sym = GameData::Species.get(species_sym).species
          subfolder = back ? "Back" : "Front"
          
          path = "Graphics/Plugins/ABC Pokemon/#{pkmn.abc_variant}/"
          filename = check_graphic_file(path, species_sym, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?, subfolder)
          
          if filename
            if PluginManager.installed?("[DBK] Animated Pokémon System")
              sp_data = GameData::SpeciesMetrics.get_species_form(species_sym, pkmn.form, pkmn.gender == 1)
              ret = DeluxeBitmapWrapper.new(filename, sp_data, back)
              ret.compile_strip(pkmn, back)
              return ret
            else
              ret = AnimatedBitmap.new(filename)
              alter_bitmap_function = MultipleForms.getFunction(species_sym, "alterBitmap")
              if ret && alter_bitmap_function
                new_ret = ret.copy
                ret.dispose
                new_ret.each { |bitmap| alter_bitmap_function.call(pkmn, bitmap) }
                ret = new_ret
              end
              return ret
            end
          end
        end
        return abc_pokemon_sprite_bitmap_from_pokemon(pkmn, back, species)
      end
      
      def icon_filename_from_pokemon(pkmn)
        if pkmn && pkmn.abc_variant && !pkmn.egg?
          path = "Graphics/Plugins/ABC Pokemon/#{pkmn.abc_variant}/"
          filename = check_graphic_file(path, pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?, "Icons")
          return filename if filename
        end
        return abc_pokemon_icon_filename_from_pokemon(pkmn)
      end
    end
  end

  class SpeciesMetrics
    unless method_defined?(:abc_pokemon_apply_metrics_to_sprite)
      alias_method :abc_pokemon_apply_metrics_to_sprite, :apply_metrics_to_sprite
    end
    
    def apply_metrics_to_sprite(sprite, index, shadow = false)
      pkmn = nil
      if sprite.respond_to?(:pkmn) && sprite.pkmn
        pkmn = sprite.pkmn.respond_to?(:pokemon) ? sprite.pkmn.pokemon : sprite.pkmn
      elsif sprite.respond_to?(:pokemon) && sprite.pokemon
        pkmn = sprite.pokemon
      end
      
      if pkmn && pkmn.is_a?(Pokemon) && pkmn.abc_variant
        metrics = ABCPokemonSystem.get_variant_metrics(pkmn.species, pkmn.abc_variant)
        if metrics
          if PluginManager.installed?("[DBK] Animated Pokémon System")
            if shadow
              if (index & 1) == 0
                sprite.x += (metrics[:back_sprite][0] * 2 + metrics[:shadow_sprite][0] * 2)
                sprite.y += (metrics[:back_sprite][1] * 2 + metrics[:shadow_sprite][1] * 2)
              else
                sprite.x += (metrics[:front_sprite][0] * 2 + metrics[:shadow_sprite][0] * 2)
                sprite.y += (metrics[:front_sprite][1] * 2 + metrics[:shadow_sprite][2] * 2)
              end
            elsif (index & 1) == 0
              sprite.x += metrics[:back_sprite][0] * 2
              sprite.y += metrics[:back_sprite][1] * 2
            else
              sprite.x += metrics[:front_sprite][0] * 2
              sprite.y += metrics[:front_sprite][1] * 2
              sprite.y -= metrics[:front_sprite_altitude] * 2
            end
          else
            if shadow
              sprite.x += metrics[:shadow_x] * 2 if (index & 1) == 1
            elsif (index & 1) == 0
              sprite.x += metrics[:back_sprite][0] * 2
              sprite.y += metrics[:back_sprite][1] * 2
            else
              sprite.x += metrics[:front_sprite][0] * 2
              sprite.y += metrics[:front_sprite][1] * 2
              sprite.y -= metrics[:front_sprite_altitude] * 2
            end
          end
          return
        end
      end
      
      abc_pokemon_apply_metrics_to_sprite(sprite, index, shadow)
    end
  end
end

#-------------------------------------------------------------------------------
# Extensión de PokemonSprite para el Editor Visual
#-------------------------------------------------------------------------------
class PokemonSprite < Sprite
  def setVariantBitmap(species, variant, back = false, shiny = false)
    @_iconbitmap&.dispose    
    subfolder = back ? "Back" : "Front"
    path = "Graphics/Plugins/ABC Pokemon/#{variant}/"
    filename = GameData::Species.check_graphic_file(path, species, 0, 0, shiny, false, subfolder)    
    
    if filename
      if PluginManager.installed?("[DBK] Animated Pokémon System")
        sp_data = GameData::SpeciesMetrics.get_species_form(species, 0, false)
        @_iconbitmap = DeluxeBitmapWrapper.new(filename, sp_data, back)
        @_iconbitmap.compile_strip(nil, back)
      else
        @_iconbitmap = AnimatedBitmap.new(filename)
      end
    else
      @_iconbitmap = GameData::Species.sprite_bitmap(species, 0, 0, shiny, false, back)
    end    
    
    self.bitmap = (@_iconbitmap) ? @_iconbitmap.bitmap : nil
    self.color = Color.new(0, 0, 0, 0)
    changeOrigin
  end

  def setVariantShadowBitmap(species, variant, back = false, shiny = false)
    setVariantBitmap(species, variant, back, shiny)
    return if !@_iconbitmap
    setOffset
    self.color = Color.black
    self.opacity = 100
    metrics = ABCPokemonSystem.get_variant_metrics(species, variant)
    shadow_size = metrics ? metrics[:shadow_size] : 2    
    self.visible = false if shadow_size == 0
    shadow_size -= 1 if shadow_size > 0
    self.zoom_x = 1 + (shadow_size * 0.1)
    self.zoom_y = 0.25 + (shadow_size * 0.025)
  end
end

#-------------------------------------------------------------------------------
# Editor Visual de Métricas ABC
#-------------------------------------------------------------------------------
class ABCSpritePositioner
  def pbOpen
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    battlebg   = "Graphics/Battlebacks/indoor1_bg"
    playerbase = "Graphics/Battlebacks/indoor1_base0"
    enemybase  = "Graphics/Battlebacks/indoor1_base1"
    @sprites["battle_bg"] = AnimatedPlane.new(@viewport)
    @sprites["battle_bg"].setBitmap(battlebg)
    @sprites["battle_bg"].z = 0
    baseX, baseY = Battle::Scene.pbBattlerPosition(0)
    @sprites["base_0"] = IconSprite.new(baseX, baseY, @viewport)
    @sprites["base_0"].setBitmap(playerbase)
    @sprites["base_0"].x -= @sprites["base_0"].bitmap.width / 2 if @sprites["base_0"].bitmap
    @sprites["base_0"].y -= @sprites["base_0"].bitmap.height if @sprites["base_0"].bitmap
    @sprites["base_0"].z = 1
    baseX, baseY = Battle::Scene.pbBattlerPosition(1)
    @sprites["base_1"] = IconSprite.new(baseX, baseY, @viewport)
    @sprites["base_1"].setBitmap(enemybase)
    @sprites["base_1"].x -= @sprites["base_1"].bitmap.width / 2 if @sprites["base_1"].bitmap
    @sprites["base_1"].y -= @sprites["base_1"].bitmap.height / 2 if @sprites["base_1"].bitmap
    @sprites["base_1"].z = 1
    @sprites["messageBox"] = IconSprite.new(0, Graphics.height - 96, @viewport)
    @sprites["messageBox"].setBitmap("Graphics/UI/Debug/battle_message")
    @sprites["messageBox"].z = 2
    
    if PluginManager.installed?("[DBK] Animated Pokémon System")
      @sprites["shadow_0"] = PokemonSprite.new(@viewport)
      @sprites["shadow_0"].setOffset(PictureOrigin::CENTER)
      @sprites["shadow_0"].z = 3
      @sprites["shadow_1"] = PokemonSprite.new(@viewport)
      @sprites["shadow_1"].setOffset(PictureOrigin::CENTER)
      @sprites["shadow_1"].z = 3
    else
      @sprites["shadow_1"] = IconSprite.new(0, 0, @viewport)
      @sprites["shadow_1"].z = 3
    end
    
    @sprites["pokemon_0"] = PokemonSprite.new(@viewport)
    @sprites["pokemon_0"].setOffset(PictureOrigin::BOTTOM)
    @sprites["pokemon_0"].z = 4
    @sprites["pokemon_1"] = PokemonSprite.new(@viewport)
    @sprites["pokemon_1"].setOffset(PictureOrigin::BOTTOM)
    @sprites["pokemon_1"].z = 4
    @sprites["info"] = Window_UnformattedTextPokemon.new("")
    @sprites["info"].viewport = @viewport
    @sprites["info"].visible  = false
    @oldSpeciesIndex = 0
    @species = nil
    @variant = nil
    @metricsChanged = false
    refresh
    @starting = true
  end

  def pbClose
    if @metricsChanged && pbConfirmMessage(_INTL("Algunas métricas se han editado. ¿Guardar cambios en abc_pokemon.txt?"))
      ABCPokemonSystem.save_abc_pbs
      @metricsChanged = false
      pbMessage(_INTL("Métricas guardadas exitosamente."))
    else
      ABCPokemonSystem.load_variant_data # Descartar cambios
    end
    pbFadeOutAndHide(@sprites) { update }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def update
    pbUpdateSpriteHash(@sprites)
  end

  def refresh
    if !@species || !@variant
      @sprites["pokemon_0"].visible = false
      @sprites["pokemon_1"].visible = false
      @sprites["shadow_1"].visible = false
      @sprites["shadow_0"].visible = false if @sprites["shadow_0"]
      return
    end
    metrics = ABCPokemonSystem.get_variant_metrics(@species, @variant)
    
    if PluginManager.installed?("[DBK] Animated Pokémon System")
      sp_data = GameData::SpeciesMetrics.get_species_form(@species, 0, false)
      2.times do |i|
        scale = (i == 0) ? sp_data.back_sprite_scale : sp_data.front_sprite_scale
        speed = (i == 0) ? sp_data.back_sprite_speed : sp_data.front_sprite_speed
        @sprites["pokemon_#{i}"].iconBitmap.scale = scale
        @sprites["pokemon_#{i}"].iconBitmap.speed = speed
        @sprites["pokemon_#{i}"].iconBitmap.refresh
        @sprites["pokemon_#{i}"].update
        
        if @sprites["shadow_#{i}"] && @sprites["shadow_#{i}"].bitmap
          @sprites["shadow_#{i}"].iconBitmap.scale = scale
          @sprites["shadow_#{i}"].iconBitmap.speed = speed
          @sprites["shadow_#{i}"].iconBitmap.refresh
          @sprites["shadow_#{i}"].update
          @sprites["shadow_#{i}"].setOffset(PictureOrigin::CENTER)
        end
      end
    end

    2.times do |i|
      pos = Battle::Scene.pbBattlerPosition(i, 1)
      @sprites["pokemon_#{i}"].x = pos[0]
      @sprites["pokemon_#{i}"].y = pos[1]
      
      if i == 0
        @sprites["pokemon_#{i}"].x += metrics[:back_sprite][0] * 2
        @sprites["pokemon_#{i}"].y += metrics[:back_sprite][1] * 2
        
        if PluginManager.installed?("[DBK] Animated Pokémon System") && @sprites["shadow_0"]
          @sprites["shadow_0"].x = pos[0]
          @sprites["shadow_0"].y = pos[1] - (@sprites["shadow_0"].height / 4).round
          @sprites["shadow_0"].x += (metrics[:back_sprite][0] * 2 + metrics[:shadow_sprite][0] * 2)
          @sprites["shadow_0"].y += (metrics[:back_sprite][1] * 2 + metrics[:shadow_sprite][1] * 2)
          @sprites["shadow_0"].visible = true
        end
      else
        @sprites["pokemon_#{i}"].x += metrics[:front_sprite][0] * 2
        @sprites["pokemon_#{i}"].y += metrics[:front_sprite][1] * 2
        @sprites["pokemon_#{i}"].y -= metrics[:front_sprite_altitude] * 2
        
        @sprites["shadow_1"].x = pos[0]
        
        if PluginManager.installed?("[DBK] Animated Pokémon System")
          @sprites["shadow_1"].y = pos[1] - (@sprites["shadow_1"].height / 4).round
          @sprites["shadow_1"].x += (metrics[:front_sprite][0] * 2 + metrics[:shadow_sprite][0] * 2)
          @sprites["shadow_1"].y += (metrics[:front_sprite][1] * 2 + metrics[:shadow_sprite][2] * 2)
        else
          @sprites["shadow_1"].y = pos[1]
          if @sprites["shadow_1"].bitmap
            @sprites["shadow_1"].x -= @sprites["shadow_1"].bitmap.width / 2
            @sprites["shadow_1"].y -= @sprites["shadow_1"].bitmap.height / 2
          end
          @sprites["shadow_1"].x += metrics[:shadow_x] * 2
        end
        @sprites["shadow_1"].visible = true
      end
      @sprites["pokemon_#{i}"].visible = true
    end
  end

  def pbAutoPosition
    metrics = ABCPokemonSystem.get_variant_metrics(@species, @variant)
    old_back_y         = metrics[:back_sprite][1]
    old_front_y        = metrics[:front_sprite][1]
    old_front_altitude = metrics[:front_sprite_altitude]
    bitmap1 = @sprites["pokemon_0"].bitmap
    bitmap2 = @sprites["pokemon_1"].bitmap
    new_back_y  = (bitmap1.height - (findBottom(bitmap1) + 1)) / 2
    new_front_y = (bitmap2.height - (findBottom(bitmap2) + 1)) / 2
    new_front_y += 4
    if new_back_y != old_back_y || new_front_y != old_front_y || old_front_altitude != 0
      metrics[:back_sprite][1]        = new_back_y
      metrics[:front_sprite][1]       = new_front_y
      metrics[:front_sprite_altitude] = 0
      @metricsChanged = true
      refresh
    end
  end

  def pbChangeSpecies(species, variant, shiny = false)
    @species = species
    @variant = variant
    return if !@species || !@variant
    
    @sprites["pokemon_0"].setVariantBitmap(@species, @variant, true, shiny)
    @sprites["pokemon_1"].setVariantBitmap(@species, @variant, false, shiny)
    
    if PluginManager.installed?("[DBK] Animated Pokémon System")
      # Usar nuestro nuevo generador de sombras basado en la variante
      @sprites["shadow_0"].setVariantShadowBitmap(@species, @variant, true, shiny) if @sprites["shadow_0"]
      @sprites["shadow_1"].setVariantShadowBitmap(@species, @variant, false, shiny)
    else
      # Lógica Vanilla: Cargar el óvalo genérico o la sombra específica
      metrics = ABCPokemonSystem.get_variant_metrics(@species, @variant)
      size = metrics ? metrics[:shadow_size] : 2
      if pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%s", @species))
        @sprites["shadow_1"].setBitmap(sprintf("Graphics/Pokemon/Shadow/%s", @species))
      else
        @sprites["shadow_1"].setBitmap(sprintf("Graphics/Pokemon/Shadow/%d", size))
      end
    end
  end

  def pbShadowSize
    pbChangeSpecies(@species, @variant)
    refresh
    metrics = ABCPokemonSystem.get_variant_metrics(@species, @variant)
    
    if pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%s", @species))
      pbMessage("Esta especie tiene su propio sprite oscuro. Las métricas del tamaño de la sombra no se pueden editar.")
      return false
    end
    
    oldval = metrics[:shadow_size]
    cmdvals = [0]
    commands =[_INTL("Ninguno")]
    defindex = 0
    i = 0
    loop do
      i += 1
      fn = sprintf("Graphics/Pokemon/Shadow/%d", i)
      break if !pbResolveBitmap(fn)
      cmdvals.push(i)
      commands.push(i.to_s)
      defindex = cmdvals.length - 1 if oldval == i
    end
    cw = Window_CommandPokemon.new(commands)
    cw.index    = defindex
    cw.viewport = @viewport
    ret = false
    oldindex = cw.index
    loop do
      Graphics.update
      Input.update
      cw.update
      self.update
      if cw.index != oldindex
        oldindex = cw.index
        metrics[:shadow_size] = cmdvals[cw.index]
        pbChangeSpecies(@species, @variant)
        refresh
      end
      if Input.trigger?(Input::ACTION)
        pbPlayDecisionSE
        @metricsChanged = true if metrics[:shadow_size] != oldval
        ret = true
        break
      elsif Input.trigger?(Input::BACK)
        metrics[:shadow_size] = oldval
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        @metricsChanged = true if metrics[:shadow_size] != oldval
        break
      end
    end
    cw.dispose
    return ret
  end

  def pbSetParameter(param)
    return if !@species || !@variant
    
    if PluginManager.installed?("[DBK] Animated Pokémon System")
      return pbShadowSize if param == 6
      if param == 5
        pbAutoPosition
        return false
      end
    else
      return pbShadowSize if param == 2
      if param == 4
        pbAutoPosition
        return false
      end
    end
    
    metrics = ABCPokemonSystem.get_variant_metrics(@species, @variant)
    
    if PluginManager.installed?("[DBK] Animated Pokémon System")
      2.times do |i|
        @sprites["pokemon_#{i}"].iconBitmap.deanimate
        @sprites["shadow_#{i}"].iconBitmap.deanimate if @sprites["shadow_#{i}"]
      end
    end

    case param
    when 0
      sprite = @sprites["pokemon_0"]
      xpos = metrics[:back_sprite][0]
      ypos = metrics[:back_sprite][1]
    when 1
      sprite = @sprites["pokemon_1"]
      xpos = metrics[:front_sprite][0]
      ypos = metrics[:front_sprite][1]
    when 2 # DBK Shadow Position
      sprite = @sprites["shadow_1"]
      xpos = metrics[:shadow_sprite][0]
      scale = metrics[:shadow_sprite][1] # Ally Y
      ypos = metrics[:shadow_sprite][2]  # Enemy Y
    when 3 # Vanilla Shadow Position
      sprite = @sprites["shadow_1"]
      xpos = metrics[:shadow_x]
      ypos = 0
    end
    
    oldxpos = xpos
    oldypos = ypos
    oldscale = scale if param == 2 && PluginManager.installed?("[DBK] Animated Pokémon System")
    
    @sprites["info"].visible = true
    ret = false
    loop do
      sprite.visible = ((System.uptime * 8).to_i % 4) < 3
      Graphics.update
      Input.update
      self.update
      
      if PluginManager.installed?("[DBK] Animated Pokémon System")
        case param
        when 0 then @sprites["info"].setTextToFit("Posicion aliado = #{xpos},#{ypos}")
        when 1 then @sprites["info"].setTextToFit("Posición enemigo = #{xpos},#{ypos}")
        when 2 then @sprites["info"].setTextToFit("Posición sombra = #{xpos},#{scale},#{ypos}")
        end
      else
        case param
        when 0 then @sprites["info"].setTextToFit("Posicion aliado = #{xpos},#{ypos}")
        when 1 then @sprites["info"].setTextToFit("Posición enemigo = #{xpos},#{ypos}")
        when 3 then @sprites["info"].setTextToFit("Posición sombra = #{xpos}")
        end
      end
      
      if Input.repeat?(Input::UP) || Input.repeat?(Input::DOWN)
        if PluginManager.installed?("[DBK] Animated Pokémon System")
          ypos += (Input.repeat?(Input::DOWN)) ? 1 : -1
          case param
          when 0 then metrics[:back_sprite][1]  = ypos
          when 1 then metrics[:front_sprite][1] = ypos
          when 2 then metrics[:shadow_sprite][2] = ypos
          end
          refresh
        else
          if param != 3
            ypos += (Input.repeat?(Input::DOWN)) ? 1 : -1
            case param
            when 0 then metrics[:back_sprite][1]  = ypos
            when 1 then metrics[:front_sprite][1] = ypos
            end
            refresh
          end
        end
      end
      
      if Input.repeat?(Input::LEFT) || Input.repeat?(Input::RIGHT)
        xpos += (Input.repeat?(Input::RIGHT)) ? 1 : -1
        if PluginManager.installed?("[DBK] Animated Pokémon System")
          case param
          when 0 then metrics[:back_sprite][0]  = xpos
          when 1 then metrics[:front_sprite][0] = xpos
          when 2 then metrics[:shadow_sprite][0] = xpos
          end
        else
          case param
          when 0 then metrics[:back_sprite][0]  = xpos
          when 1 then metrics[:front_sprite][0] = xpos
          when 3 then metrics[:shadow_x] = xpos
          end
        end
        refresh
      end
      
      if PluginManager.installed?("[DBK] Animated Pokémon System") && param == 2
        if (Input.repeat?(Input::JUMPUP) || Input.repeat?(Input::JUMPDOWN))
          scale += (Input.repeat?(Input::JUMPDOWN)) ? 1 : -1
          metrics[:shadow_sprite][1] = scale
          refresh
        end
      end
      
      if Input.repeat?(Input::ACTION)
        if PluginManager.installed?("[DBK] Animated Pokémon System")
          @metricsChanged = true if xpos != oldxpos || ypos != oldypos || (param == 2 && scale != oldscale)
        else
          @metricsChanged = true if xpos != oldxpos || (param != 3 && ypos != oldypos)
        end
        ret = true
        pbPlayDecisionSE
        break
      elsif Input.repeat?(Input::BACK)
        if PluginManager.installed?("[DBK] Animated Pokémon System")
          case param
          when 0
            metrics[:back_sprite][0] = oldxpos
            metrics[:back_sprite][1] = oldypos
          when 1
            metrics[:front_sprite][0] = oldxpos
            metrics[:front_sprite][1] = oldypos
          when 2
            metrics[:shadow_sprite][0] = oldxpos
            metrics[:shadow_sprite][1] = oldscale
            metrics[:shadow_sprite][2] = oldypos
          end
        else
          case param
          when 0
            metrics[:back_sprite][0] = oldxpos
            metrics[:back_sprite][1] = oldypos
          when 1
            metrics[:front_sprite][0] = oldxpos
            metrics[:front_sprite][1] = oldypos
          when 3
            metrics[:shadow_x] = oldxpos
          end
        end
        pbPlayCancelSE
        refresh
        break
      elsif Input.repeat?(Input::USE)
        if PluginManager.installed?("[DBK] Animated Pokémon System")
          @metricsChanged = true if xpos != oldxpos || ypos != oldypos || (param == 2 && scale != oldscale)
        else
          @metricsChanged = true if xpos != oldxpos || (param != 3 && ypos != oldypos)
        end
        pbPlayDecisionSE
        break
      end
    end
    @sprites["info"].visible = false
    sprite.visible = true
    
    if PluginManager.installed?("[DBK] Animated Pokémon System")
      2.times do |i|
        @sprites["pokemon_#{i}"].iconBitmap.reanimate
        @sprites["shadow_#{i}"].iconBitmap.reanimate if @sprites["shadow_#{i}"]
      end
    end
    
    return ret
  end

  def pbMenu
    refresh
    if PluginManager.installed?("[DBK] Animated Pokémon System")
      cmds =[
        _INTL("Establecer Posición Aliada"),
        _INTL("Establecer Posición Enemiga"),
        _INTL("Establecer Posición de Sombra"),
        _INTL("Posicionar Sprites Automáticamente")
      ]
    else
      cmds =[
        _INTL("Establecer Posición Aliada"),
        _INTL("Establecer Posición Enemiga"),
        _INTL("Establecer Tamaño de Sombra"),
        _INTL("Establecer Posición de Sombra"),
        _INTL("Posicionar Sprites Automáticamente")
      ]
    end
    
    cw = Window_CommandPokemon.new(cmds)
    cw.x        = Graphics.width - cw.width
    cw.y        = Graphics.height - cw.height
    cw.viewport = @viewport
    ret = -1
    loop do
      Graphics.update
      Input.update
      cw.update
      self.update
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        ret = cw.index
        if PluginManager.installed?("[DBK] Animated Pokémon System")
          ret = 5 if ret == 3 # Auto-position en DBK
        else
          ret = 4 if ret == 4 # Auto-position en Vanilla
        end
        break
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      end
    end
    cw.dispose
    return ret
  end

  def pbChooseSpecies
    shiny = false
    if @starting
      pbFadeInAndShow(@sprites) { update }
      @starting = false
    end

    cw = Window_CommandPokemonEx.newEmpty(0, 0, 260, 176, @viewport)
    cw.rowHeight = 24
    pbSetSmallFont(cw.contents)
    cw.x = Graphics.width - cw.width
    cw.y = Graphics.height - cw.height

    allvariants =[]
    ABCPokemonSystem.variant_data.each do |sp, data|
      data[:variants].each do |v|
        name = "#{GameData::Species.get(sp).name} - #{v}"
        allvariants.push([sp, v, name])
      end
    end

    if allvariants.empty?
      pbMessage(_INTL("No hay variantes ABC definidas en abc_pokemon.txt."))
      cw.dispose
      return nil
    end

    allvariants.sort! { |a, b| a[2] <=> b[2] }
    current_list = allvariants.clone
    
    refresh_list = proc do
      commands =[]
      current_list.each { |item| commands.push(item[2]) }
      cw.commands = commands
    end

    refresh_list.call
    cw.index = (@oldSpeciesIndex && @oldSpeciesIndex < current_list.length) ? @oldSpeciesIndex : 0
    
    ret = false
    oldindex = -1
    
    loop do
      Graphics.update
      Input.update
      cw.update
      
      if cw.index != oldindex
        oldindex = cw.index
        if current_list[cw.index]
            data = current_list[cw.index]
            pbChangeSpecies(data[0], data[1], shiny)
            refresh
        end
      end
      
      self.update
      
      if Input.trigger?(Input::BACK)
        pbChangeSpecies(nil, nil)
        refresh
        break
        
      elsif Input.trigger?(Input::USE)
        if current_list[cw.index]
            data = current_list[cw.index]
            pbChangeSpecies(data[0], data[1], shiny)
            ret = true
        end
        break
        
      elsif Input.trigger?(Input::SPECIAL)
        shiny = !shiny
        if current_list[cw.index]
            data = current_list[cw.index]
            pbChangeSpecies(data[0], data[1], shiny)
            ret = true
        end
      end
    end
    
    @oldSpeciesIndex = (current_list.length == allvariants.length) ? cw.index : 0
    cw.dispose
    return ret
  end
end

class ABCSpritePositionerScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStart
    @scene.pbOpen
    loop do
      has_selection = @scene.pbChooseSpecies
      break if !has_selection
      loop do
        command = @scene.pbMenu
        break if command < 0
        loop do
          par = @scene.pbSetParameter(command)
          break if !par
          if PluginManager.installed?("[DBK] Animated Pokémon System")
            case command
            when 0 then command = 1
            when 1 then command = 2
            when 2 then command = 6
            when 6 then command = 0
            end
          else
            case command
            when 0 then command = 1
            when 1 then command = 2
            when 2 then command = 3
            when 3 then command = 0
            end
          end
        end
      end
    end
    @scene.pbClose
  end
end

def pbABCSpritePositioner
  pbFadeOutIn do
    scene = ABCSpritePositioner.new
    screen = ABCSpritePositionerScreen.new(scene)
    screen.pbStart
  end
end

#-------------------------------------------------------------------------------
# Menú Debug
#-------------------------------------------------------------------------------
MenuHandlers.add(:debug_menu, :abc_sprite_positioner, {
  "name"        => _INTL("Posicionar Sprites ABC"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("Ajusta las métricas de los sprites de las variantes ABC."),
  "effect"      => proc {
    pbABCSpritePositioner
  }
})

=begin
#-------------------------------------------------------------------------------
# Auto-Compilación
#-------------------------------------------------------------------------------
if $DEBUG
  txt_path = "PBS/abc_pokemon.txt"
  dat_path = "Data/abc_pokemon.dat"
  if FileTest.exist?(txt_path)
    txt_time = File.mtime(txt_path).to_i
    dat_time = FileTest.exist?(dat_path) ? File.mtime(dat_path).to_i : 0
    if txt_time > dat_time
      Compiler.compile_abc_pokemon
    end
  end
end
=end

#-------------------------------------------------------------------------------
# Menú Debug del Pokémon (Fuera de combate)
#-------------------------------------------------------------------------------
MenuHandlers.add(:pokemon_debug_menu, :set_abc_variant, {
  "name"   => _INTL("Definir Variante ABC"),
  "parent" => :main,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    data = ABCPokemonSystem.variant_data[pkmn.species]
    if !data || data[:variants].empty?
      screen.pbDisplay("\\ts[]" + _INTL("La especie {1} no tiene variantes ABC definidas.", pkmn.speciesName))
      next false
    end
    
    variant_cmds = [_INTL("Original")]
    variants = [nil]
    
    data[:variants].each do |v|
      variant_cmds.push(_INTL("Variante {1}", v))
      variants.push(v)
    end
    
    cmd = variants.index(pkmn.abc_variant) || 0
    
    loop do
      current_name = pkmn.abc_variant ? _INTL("Variante {1}", pkmn.abc_variant) : _INTL("Original")
      cmd = screen.pbShowCommands(_INTL("La variante actual es: {1}.", current_name), variant_cmds, cmd)
      break if cmd < 0
      
      selected_variant = variants[cmd]
      next if selected_variant == pkmn.abc_variant
      
      pkmn.abc_variant = selected_variant
      screen.pbRefreshSingle(pkmnid) # Refresca el icono en el menú del equipo
    end
    next false
  }
})

#-------------------------------------------------------------------------------
# Menú Debug del Pokémon (En combate)
#-------------------------------------------------------------------------------
MenuHandlers.add(:battle_pokemon_debug_menu, :set_abc_variant, {
  "name"   => _INTL("Definir Variante ABC"),
  "parent" => :main,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    data = ABCPokemonSystem.variant_data[pkmn.species]
    if !data || data[:variants].empty?
      pbMessage("\\ts[]" + _INTL("La especie {1} no tiene variantes ABC definidas.", pkmn.speciesName))
      next
    end
    
    variant_cmds = [_INTL("Original")]
    variants = [nil]
    
    data[:variants].each do |v|
      variant_cmds.push(_INTL("Variante {1}", v))
      variants.push(v)
    end
    
    cmd = variants.index(pkmn.abc_variant) || 0
    
    loop do
      current_name = pkmn.abc_variant ? _INTL("Variante {1}", pkmn.abc_variant) : _INTL("Original")
      cmd = pbMessage("\\ts[]" + _INTL("La variante actual es: {1}.", current_name), variant_cmds, -1, nil, cmd)
      break if cmd < 0
      
      selected_variant = variants[cmd]
      next if selected_variant == pkmn.abc_variant
      
      pkmn.abc_variant = selected_variant
      
      # Si estamos modificando un Pokémon que está actualmente en el campo de batalla
      if battler
        battler.pokemon.abc_variant = selected_variant
        # Forzamos al motor gráfico de la batalla a recargar el sprite del Pokémon
        battle.scene.pbChangePokemon(battler, battler.pokemon)
      end
    end
  }
})
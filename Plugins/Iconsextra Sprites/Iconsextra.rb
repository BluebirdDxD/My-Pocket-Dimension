module IconsextraFallback

  def self.find_iconextra(species, shiny = false)
    name = species.to_s

    paths = []
    paths << "Graphics/Pokemon/Iconsextra shiny/#{name}" if shiny
    paths << "Graphics/Pokemon/Iconsextra/#{name}"

    paths.each do |p|
      ret = pbResolveBitmap(p)
      return ret if ret
    end

    return nil
  end

end


module GameData
  class Species

    class << self
      alias iex_old_front front_sprite_filename
      alias iex_old_back  back_sprite_filename
      alias iex_old_icon  icon_filename
    end


    #=====================
    # FRONT FALLBACK
    #=====================
    def self.front_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
      ret = iex_old_front(species, form, gender, shiny, shadow)

      if ret && File.basename(ret).start_with?("000")
        icon = IconsextraFallback.find_iconextra(species, shiny)
        return icon if icon
      end

      return ret
    end


    #=====================
    # BACK FALLBACK
    #=====================
    def self.back_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
      ret = iex_old_back(species, form, gender, shiny, shadow)

      if ret && File.basename(ret).start_with?("000")
        icon = IconsextraFallback.find_iconextra(species, shiny)
        return icon if icon
      end

      return ret
    end


    #=====================
    # ICON FALLBACK
    #=====================
    def self.icon_filename(species, form = 0, gender = 0, shiny = false, shadow = false, egg = false)
      ret = iex_old_icon(species, form, gender, shiny, shadow, egg)
      return ret if ret && !File.basename(ret).start_with?("000")

      icon = IconsextraFallback.find_iconextra(species, shiny)
      return icon if icon

      return ret
    end

  end
end
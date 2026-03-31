#===============================================================================
# [DBK] Terastallization compatibility for [SV] Summary Screen
#===============================================================================
if PluginManager.installed?("[DBK] Terastallization")
  class PokemonSummary_Scene
    alias tera_drawPage drawPage
    def drawPage(page)
      return if !Settings::SUMMARY_TERA_TYPES
      overlay = @sprites["overlay"].bitmap
      tera_drawPage(page)
      coords = [150, 340]
      pbDisplayTeraType(@pokemon, overlay, coords[0], coords[1])
    end

    alias tera_drawPageFourSelecting drawPageFourSelecting
    def drawPageFourSelecting(move_to_learn)
      return if !Settings::SUMMARY_TERA_TYPES
      overlay = @sprites["overlay"].bitmap
      tera_drawPageFourSelecting(move_to_learn)
      coords = [214, 80]
      pbDisplayTeraType(@pokemon, overlay, coords[0], coords[1])
    end
  end

  class MoveRelearner_Scene
    alias tera_pbDrawMoveList pbDrawMoveList
    def pbDrawMoveList
      return if !Settings::SUMMARY_TERA_TYPES
      overlay = @sprites["overlay"].bitmap
      tera_pbDrawMoveList
      coords = [466, 64]
      pbDisplayTeraType(@pokemon, overlay, coords[0], coords[1])
    end
  end
end
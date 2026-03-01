#===============================================================================
# Custom Menu Handlers – versión limpia con helper de refresh
#===============================================================================

# Helper para refrescar menú y sidebar tras cerrar subpantallas
def refresh_menu(menu)
  scene = menu.instance_variable_get(:@scene)
  scene.reset_selection if scene.respond_to?(:reset_selection)
  menu.pbRefresh if menu.respond_to?(:pbRefresh)
  Input.update
  Input.reset
end

# Handler genérico para subpantallas que no devuelven valor
def subscene_handler(menu)
  yield
  refresh_menu(menu)
  false
end

# Handler genérico para subpantallas que pueden devolver un valor (como Bag)
def subscene_handler_with_result(menu)
  result = nil
  yield(result)
  refresh_menu(menu)
  result
end

#===============================================================================
# Handlers
#===============================================================================

MenuHandlers.add(:custom_menu, :bag, {
  "name" => _INTL("Mochila"),
  "iconName" => "bag",
  "condition" => proc { !$player.in_bug_contest? rescue true },
  "effect" => proc do |menu|
    pbPlayDecisionSE
    item = nil
    pbFadeOutIn do
      scene = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene, $bag)
      item = screen.pbStartScreen
    end
    refresh_menu(menu)
    if item
      $game_temp.in_menu = false
      pbUseKeyItemInField(item)
      true
    else
      false
    end
  end
})

MenuHandlers.add(:custom_menu, :pokedex, {
  "name" => _INTL("Pokédex"),
  "iconName" => "pokedex",
"condition" => proc { $game_switches[39] },
  "effect" => proc do |menu|
    pbPlayDecisionSE
    subscene_handler(menu) do
      pbFadeOutIn do
        if Settings::USE_CURRENT_REGION_DEX || $player.pokedex.accessible_dexes.length == 1
          $PokemonGlobal.pokedexDex ||= $player.pokedex.accessible_dexes[0]
          scene = PokemonPokedex_Scene.new
          PokemonPokedexScreen.new(scene).pbStartScreen
        else
          scene = PokemonPokedexMenu_Scene.new
          PokemonPokedexMenuScreen.new(scene).pbStartScreen
        end
      end
    end
  end
})

MenuHandlers.add(:custom_menu, :pokenav, {
  "name" => _INTL("PokéNav"),
  "iconName" => "pokenav",
  "condition" => proc { $game_switches[39] },

  "effect" => proc do |menu|
    pbPlayDecisionSE
    subscene_handler(menu) do
      pbFadeOutIn do
        scene  = PokemonPokenav_Scene.new
        screen = PokemonPokenavScreen.new(scene)
        screen.pbStartScreen
      end
    end
  end
})

MenuHandlers.add(:custom_menu, :boxes, {
  "name" => _INTL("Cajas"),
  "iconName" => "boxes",
  "condition" => proc { $game_switches[40] },
  "effect" => proc do |menu|
    pbPlayDecisionSE
    subscene_handler(menu) { pbFadeOutIn { pbPokemonStorage } }
  end
})

MenuHandlers.add(:custom_menu, :options, {
  "name" => _INTL("Opciones"),
  "iconName" => "options",
  "condition" => proc { true },
  "effect" => proc do |menu|
    pbPlayDecisionSE
    subscene_handler(menu) do
      pbFadeOutIn do
        scene = PokemonOption_Scene.new
        screen = PokemonOptionScreen.new(scene)
        screen.pbStartScreen
        pbUpdateSceneMap
      end
    end
  end
})

MenuHandlers.add(:custom_menu, :save, {
  "name" => _INTL("Guardar"),
  "iconName" => "save",
  "condition" => proc { true },
  "effect" => proc do |menu|
    pbPlayDecisionSE
    subscene_handler(menu) do
      pbFadeOutIn do
        scene  = PokemonSave_Scene.new
        screen = PokemonSaveScreen.new(scene)
        screen.pbSaveScreen
      end
    end
  end
})

MenuHandlers.add(:custom_menu, :trainer_card, {
  "name" => proc { $player.name },
  "iconName" => "trainer",
  "condition" => proc { true },
  "effect" => proc do |menu|
    pbPlayDecisionSE
    subscene_handler(menu) do
      pbFadeOutIn do
        scene = PokemonTrainerCard_Scene.new
        screen = PokemonTrainerCardScreen.new(scene)
        screen.pbStartScreen
      end
    end
  end
})

MenuHandlers.add(:custom_menu, :debug, {
  "name" => _INTL("Debug"),
  "iconName" => "debug",
  "condition" => proc { $DEBUG },
  "effect" => proc do |menu|
    pbPlayDecisionSE
    subscene_handler(menu) { pbFadeOutIn { pbDebugMenu } }
  end
})

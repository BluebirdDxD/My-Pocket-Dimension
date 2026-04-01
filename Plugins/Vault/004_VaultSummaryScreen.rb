module PokemonVault
  module_function

  def view_vault_screen
    vault = load_vault

    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 99999

    sprites = {}

    # Fondo oscuro tipo panel
    bg = BitmapSprite.new(Graphics.width - 40, Graphics.height - 80, viewport)
    bg.x = 20
    bg.y = 40

    bg.bitmap.fill_rect(
      0, 0,
      bg.bitmap.width,
      bg.bitmap.height,
      Color.new(0, 0, 0, 160)
    )

    sprites["bg"] = bg

    # Título
    overlay = BitmapSprite.new(Graphics.width, Graphics.height, viewport)
    pbSetSystemFont(overlay.bitmap)

# ===== TÍTULO =====
title_text = _INTL("Bóveda Virtual")

# fondo del título
overlay.bitmap.fill_rect(
  0, 0,
  Graphics.width, 32,
  Color.new(0, 0, 0, 180)
)

overlay.bitmap.draw_text(
  0, 4,
  Graphics.width,
  32,
  title_text,
  1
)

# ===== TEXTO INFERIOR =====
if $game_switches[151]
  bottom_text = _INTL("D: Opciones de la Bóveda")

  overlay.bitmap.fill_rect(
    0,
    Graphics.height - 32,
    Graphics.width,
    32,
    Color.new(0, 0, 0, 180)
  )

  overlay.bitmap.draw_text(
    0,
    Graphics.height - 28,
    Graphics.width,
    32,
    bottom_text,
    1
  )
end
    sprites["overlay"] = overlay

    # Iconos (solo primera caja)

cols = 6
rows = 5
icon_size = 64

grid_w = cols * icon_size
grid_h = rows * icon_size

start_x = (Graphics.width - grid_w) / 2
start_y = (Graphics.height - grid_h) / 2

cursor_index = 0

# Dibujar iconos correctamente por slot
vault[0].each_with_index do |pkmn, slot|
  next if !pkmn

  icon = PokemonIconSprite.new(pkmn, viewport)

  x = start_x + (slot % cols) * icon_size
  y = start_y + (slot / cols) * icon_size

  icon.x = x
  icon.y = y

  sprites["icon#{slot}"] = icon
end

# Cursor (solo UNA vez)
cursor = BitmapSprite.new(64, 64, viewport)
cursor.bitmap.fill_rect(0, 0, 64, 64, Color.new(255,255,255,80))
sprites["cursor"] = cursor

refresh_icons = proc do
  # Borrar iconos viejos
  sprites.keys.each do |key|
    if key.include?("icon")
      sprites[key].dispose
      sprites.delete(key)
    end
  end

  # Recargar vault
  vault = load_vault

  # Volver a dibujar
vault[0].each_with_index do |pkmn, slot|
  next if !pkmn

  icon = PokemonIconSprite.new(pkmn, viewport)

  x = start_x + (slot % cols) * icon_size
  y = start_y + (slot / cols) * icon_size

  icon.x = x
  icon.y = y

  sprites["icon#{slot}"] = icon
end
end

loop do
  Graphics.update
  Input.update

  # Movimiento cursor
  if Input.trigger?(Input::RIGHT)
    cursor_index += 1 if cursor_index % cols < cols - 1
  elsif Input.trigger?(Input::LEFT)
    cursor_index -= 1 if cursor_index % cols > 0
  elsif Input.trigger?(Input::DOWN)
    cursor_index += cols if cursor_index < (rows - 1) * cols
  elsif Input.trigger?(Input::UP)
    cursor_index -= cols if cursor_index >= cols
  end

  # Posición del cursor
  cursor.x = start_x + (cursor_index % cols) * icon_size
  cursor.y = start_y + (cursor_index / cols) * icon_size

  # Selección
if $game_switches[151] && Input.trigger?(Input::SPECIAL)   # puedes cambiar el botón luego
  choice = pbMessage(
    _INTL("Opciones de la bóveda"),
    [
      _INTL("Importar caja"),
      _INTL("Exportar caja"),
      _INTL("Cancelar")
    ],
    3
  )

  case choice
  when 0
    import_box_to_vault(refresh_icons)
  when 1
    export_vault_to_pc(refresh_icons)
  end
end
  if Input.trigger?(Input::USE)
    pkmn = vault[0][cursor_index]

    if pkmn
      choice = pbMessage(
  _INTL("¿Qué hacer con {1}?", pkmn.name),
  [
    _INTL("Datos"),
    _INTL("Retirar"),
    _INTL("Cancelar")
  ],
  3
)

case choice
when 0
  pbFadeOutIn do
    scene = PokemonSummary_Scene.new
    screen = PokemonSummaryScreen.new(scene)
    screen.pbStartScreen([pkmn], 0)
  end

when 1
  removed = remove_pokemon(0, cursor_index)
  if removed

    if $game_switches[151]
      choice = pbMessage(
        _INTL("¿Qué quieres hacer con {1}?", removed.name),
        [
          _INTL("Enviar al equipo"),
          _INTL("PC"),
          _INTL("Cancelar")
        ],
        3
      )

      case choice
      when 0
        if $player.party.length < 6
          $player.party << removed
          pbMessage(_INTL("{1} fue añadido a tu equipo.", removed.name))
        else
          pbMessage(_INTL("Tu equipo está lleno."))
          set_pokemon_at(0, cursor_index, removed)
          next
        end

      when 1
        if add_to_pc(removed)
          pbMessage(_INTL("{1} fue enviado al PC.\nRevisa tus cajas.", removed.name))
        else
          pbMessage(_INTL("El PC está lleno."))
          set_pokemon_at(0, cursor_index, removed)
          next
        end

      else
        set_pokemon_at(0, cursor_index, removed)
        next
      end

    else
      if $player.party.length < 6
        $player.party << removed
        pbMessage(_INTL("{1} se unió a tu equipo.", removed.name))
      elsif add_to_pc(removed)
        pbMessage(_INTL("{1} fue enviado al PC.\nRevisa tus cajas.", removed.name))
      else
        pbMessage(_INTL("Equipo y PC llenos."))
        set_pokemon_at(0, cursor_index, removed)
        next
      end
    end

    Game.save
    pbMEPlay("GUI save game")
    refresh_icons.call
  end
end     

    else
choice = pbMessage(
  _INTL("Espacio vacío."),
  [
    _INTL("Añadir Pokémon"),
    _INTL("Cancelar")
  ],
  2
)

if choice == 0
  chosen = choose_pokemon_from_pc(
    proc { |pk| storable_pokemon?(pk) },
    _INTL("Elige un Pokémon.")
  )

  if chosen
    pkmn2, box, slot = chosen
    removed = remove_from_pc(box, slot)

    if removed
      if set_pokemon_at(0, cursor_index, removed)
        pbMessage(_INTL("{1} fue guardado en la Bóveda.", removed.name))

        Game.save
        pbMEPlay("GUI save game")

        refresh_icons.call
      else
        pbMessage(_INTL("Bóveda llena."))
        add_to_pc(removed)
      end
    end
  end
end
    end
  end

  if Input.trigger?(Input::BACK)
  Input.update   # limpia input
  break
end
end

    pbDisposeSpriteHash(sprites)
    viewport.dispose
  end

def import_box_to_vault(refresh_proc)
  box = pbMessage(
    _INTL("¿Qué caja quieres importar?"),
    (1..Settings::NUM_STORAGE_BOXES).map { |i| _INTL("Caja {1}", i) }
  )
  return if box < 0

  vault = load_vault

  # slots vacíos
  empty_slots = []
  vault[0].each_with_index do |pkmn, i|
    empty_slots << i if !pkmn
  end

  if empty_slots.empty?
    pbMessage(_INTL("La Bóveda está llena.\nLibera espacio para continuar."))
    return
  end

  inserted = 0

  # recorrer la caja real del PC
  $PokemonStorage.maxPokemon(box).times do |i|
    break if inserted >= empty_slots.length

    pkmn = $PokemonStorage[box, i]
    next if !storable_pokemon?(pkmn)

    slot = empty_slots[inserted]

    vault[0][slot] = pkmn
    $PokemonStorage[box, i] = nil

    inserted += 1
  end

  save_vault(vault)

  pbMessage(_INTL("{1} Pokémon fueron transferidos a la Bóveda.\nLos encontrarás en los espacios disponibles.",inserted))

  Game.save
  pbMEPlay("GUI save game")

  refresh_proc.call
end


def export_vault_to_pc(refresh_proc)
  vault = load_vault

  exported = 0

  vault[0].each_with_index do |pkmn, slot|
    next if !pkmn

    if add_to_pc(pkmn)
      vault[0][slot] = nil
      exported += 1
    else
      break
    end
  end

  save_vault(vault)

  pbMessage(_INTL(
  "{1} Pokémon fueron enviados al PC.\nRevisa tus cajas para encontrarlos.",
  exported
))

  Game.save
  pbMEPlay("GUI save game")

  refresh_proc.call
end

end
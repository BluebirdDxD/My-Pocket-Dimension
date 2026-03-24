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
    overlay.bitmap.draw_text(
      0, 8,
      Graphics.width,
      32,
      _INTL("Bóveda Virtual"),
      1
    )
    sprites["overlay"] = overlay

    # Iconos (solo primera caja)

cols = 6
rows = 5
icon_size = 64

grid_w = cols * icon_size
grid_h = rows * icon_size

start_x = (Graphics.width - grid_w) / 2
start_y = (Graphics.height - grid_h) / 2

    index = 0
    vault[0].each do |pkmn|
      next if !pkmn

      icon = PokemonIconSprite.new(pkmn, viewport)

x = start_x + (index % cols) * icon_size
y = start_y + (index / cols) * icon_size

      icon.x = x
      icon.y = y

      sprites["icon#{index}"] = icon
      index += 1
    end

    # Loop principal
    loop do
      Graphics.update
      Input.update

      if Input.trigger?(Input::BACK) || Input.trigger?(Input::USE)
        break
      end
    end

    pbDisposeSpriteHash(sprites)
    viewport.dispose
  end
end
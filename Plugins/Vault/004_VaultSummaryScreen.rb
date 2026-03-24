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
      _INTL("Pokémon Vault"),
      1
    )
    sprites["overlay"] = overlay

    # Iconos (solo primera caja)
    index = 0
    vault[0].each do |pkmn|
      next if !pkmn

      icon = PokemonIconSprite.new(pkmn, viewport)

      x = 40 + (index % 6) * 64
      y = 80 + (index / 6) * 64

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
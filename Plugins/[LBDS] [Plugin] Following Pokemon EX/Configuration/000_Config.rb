#==============================================================================#
# SETTINGS DEL FOLLOW POKEMON                                                  #
#                                                                              #
# Aquí tienes toda la configuración personalizable del script de que te sigan  #
# los Pokémon.                                                                 #
#==============================================================================#

module FollowingPkmn
  # Evento común que contiene "FollowingPkmn.talk" en un comando de script
  # Cambia esto si deseas un evento común separado que se reproduzca al hablar con
  # el Pokémon que te sigue. De lo contrario, establece esto como nil.
  FOLLOWER_COMMON_EVENT     = nil 

  # IDs de animación del pokémon que te sigue.
  # Cambia esto si no estás utilizando las animaciones Animations.rxdata
  # proporcionadas en el script.
  ANIMATION_COME_OUT        = 30
  ANIMATION_COME_IN         = 29

  ANIMATION_EMOTE_HEART     = 32
  ANIMATION_EMOTE_MUSIC     = 35
  ANIMATION_EMOTE_HAPPY     = 33
  ANIMATION_EMOTE_ELIPSES   = 36
  ANIMATION_EMOTE_ANGRY     = 39
  ANIMATION_EMOTE_POISON    = 40

  # La tecla que el jugador debe presionar para alternar los Pokémon que te siguen. Establece esto como nil (nulo)
  # si deseas deshabilitar esta función. (:JUMPUP es la tecla A por defecto)
  TOGGLE_FOLLOWER_KEY       = Input::JUMPUP

  # Mostrar la opción para alternar los Pokémon que te siguen en la pantalla de Opciones.
  SHOW_TOGGLE_IN_OPTIONS    = true

  # Esta tecla permite al jugador recorrer rápidamente su equipo de Pokémon. 
  # Establece ENABLE_PARTY_CYCLING como true si quieres activar esta funcion
  # Input::JUMPDOWN es la tecla S - rota el grupo hacia adelante (el primer Pokémon va al final)
  # Input::AUX2 es la tecla W - rota el grupo hacia atrás (el último Pokémon va al principio)
  ENABLE_PARTY_CYCLING     = false
  CYCLE_PARTY_FORWARD_KEY  = Input::JUMPDOWN
  CYCLE_PARTY_BACKWARD_KEY = Input::AUX2

  # Tonos de estado a utilizar, si esto es verdadero (Rojo, Verde, Azul)
  APPLY_STATUS_TONES        = true
  TONE_BURN                 = [206, 73, 43]
  TONE_POISON               = [109, 55, 130]
  TONE_PARALYSIS            = [204, 152, 44]
  TONE_FROZEN               = [56, 160, 193]
  TONE_SLEEP                = [0, 0, 0]
  # Para tus condiciones de estado personalizadas, simplemente agrégalo como 
  # "TONE_(NOMBRE INTERNO)"
  # Ejemplo: TONE_SANGRADO, TONE_CONFUSIÓN, TONE_ENAMORAMIENTO


  # Tiempo necesario para que la amistad del Pokémon que te sigue aumente cuando
  # está primero en el grupo (en segundos)
  FRIENDSHIP_TIME_TAKEN     = 125

  # Elige si el Pokémon que te sigue puede encontrarse o no objetos al caminar
  # contigo.
  CAN_FIND_ITEMS = false

  # Tiempo necesario para que el Pokémon que te sigue encuentre un objeto 
  # cuando está primero en el grupo (en segundos). Si la opción anterior está
  # en false, nunca encontrará nada.
  ITEM_TIME_TAKEN           = 375

  # Si el Pokémon que te sigue siempre permanece en su ciclo de movimientos 
  # (como en HGSS) o no.
  ALWAYS_ANIMATE            = true

  # Si el Pokémon que te sigue siempre mira hacia el jugador o no, como en HGSS.
  ALWAYS_FACE_PLAYER        = false

  # Si otros eventos pueden atravesar al Pokémon que te sigue o no.
  IMPASSABLE_FOLLOWER       = false

  # Si el Pokémon que te sigue se desliza en la batalla en lugar de ser enviado
  # en una Pokébola. (Esto no afecta a EBDX, lee la documentación de EBDX para
  # cambiar esta característica en EBDX)
  SLIDE_INTO_BATTLE         = true

  # Mostrar la animación de apertura y cierre de la Pokébola cuando la Enfermera
  # Joy toma tus Poké Balls en el Centro Pokémon.
  SHOW_POKECENTER_ANIMATION = true

  # Lista de Pokémon clasificados como Pokémon que levitan, y que siempre 
  # aparecerán detrás del jugador al surfear.
  # No incluye ningún tipo volador o agua, ya que esos están gestionados de 
  # antemano.
  LEVITATING_FOLLOWERS = [
    # Gen 1
    :BEEDRILL, :VENOMOTH, :ABRA, :GEODUDE, :MAGNEMITE, :GASTLY, :HAUNTER,
    :KOFFING, :WEEZING, :PORYGON, :MEW,
    # Gen 2
    :MISDREAVUS, :UNOWN, :PORYGON2, :CELEBI,
    # Gen 3
    :DUSTOX, :SHEDINJA, :MEDITITE, :VOLBEAT, :ILLUMISE, :FLYGON, :LUNATONE,
    :SOLROCK, :BALTOY, :CLAYDOL, :CASTFORM, :SHUPPET, :DUSKULL, :CHIMECHO,
    :GLALIE, :BELDUM, :METANG, :LATIAS, :LATIOS, :JIRACHI,
    # Gen 4
    :MISMAGIUS, :BRONZOR, :BRONZONG, :SPIRITOMB, :CARNIVINE, :MAGNEZONE,
    :PORYGONZ, :PROBOPASS, :DUSKNOIR, :FROSLASS, :ROTOM, :UXIE, :MESPRIT,
    :AZELF, :GIRATINA_1, :CRESSELIA, :DARKRAI,
    # Gen 5
    :MUNNA, :MUSHARNA, :YAMASK, :COFAGRIGUS, :SOLOSIS, :DUOSION, :REUNICLUS,
    :VANILLITE, :VANILLISH, :VANILLUXE, :ELGYEM, :BEHEEYEM, :LAMPENT,
    :CHANDELURE, :CRYOGONAL, :HYDREIGON, :VOLCARONA, :RESHIRAM, :ZEKROM,
    # Gen 6
    :SPRITZEE, :DRAGALGE, :CARBINK, :KLEFKI, :PHANTUMP, :DIANCIE, :HOOPA,
    # Gen 7
    :VIKAVOLT, :CUTIEFLY, :RIBOMBEE, :COMFEY, :DHELMISE, :TAPUKOKO, :TAPULELE,
    :TAPUBULU, :COSMOG, :COSMOEM, :LUNALA, :NIHILEGO, :KARTANA, :NECROZMA,
    :MAGEARNA, :POIPOLE, :NAGANADEL,
    # Gen 8
    :ORBEETLE, :FLAPPLE, :SINISTEA, :POLTEAGEIST, :FROSMOTH, :DREEPY, :DRAKLOAK,
    :DRAGAPULT, :ETERNATUS, :REGIELEKI, :REGIDRAGO, :CALYREX,
    # Gen 9
    :TADBULB, :FLITTLE, :VAROOM, :REVAVROOM, :GLIMMET, :GLIMMORA, :MELENALETEO,
    :FERROPOLILLA, :CHIYU, :BRAMALUNA, :POLTCHAGEIST, :SINISTCHA, :PECHARUNT
  ]

  # Lista de Pokémon que no aparecerán detrás del jugador al surfear,
  # independientemente de si son de tipo volador, tienen levitación o están
  # mencionados en el array LEVITATING_FOLLOWERS.
  SURFING_FOLLOWERS_EXCEPTIONS = [
    # Gen I
    :CHARIZARD, :PIDGEY, :SPEAROW, :FARFETCHD, :DODUO, :DODRIO, :SCYTHER,
    :ZAPDOS_1,
    # Gen II
    :NATU, :XATU, :MURKROW, :DELIBIRD,
    # Gen III
    :TAILLOW, :VIBRAVA, :TROPIUS,
    # Gen IV
    :STARLY, :HONCHKROW, :CHINGLING, :CHATOT, :ROTOM_1, :ROTOM_2, :ROTOM_3,
    :ROTOM_5, :SHAYMIN_1, :ARCEUS_2,
    # Gen V
    :ARCHEN, :DUCKLETT, :EMOLGA, :EELEKTRIK, :EELEKTROSS, :RUFFLET, :VULLABY,
    :LANDORUS_1,
    # Gen VI
    :FLETCHLING, :HAWLUCHA,
    # Gen VII
    :ROWLET, :DARTRIX, :PIKIPEK, :ORICORIO, :SILVALLY_2,
    # Gen VIII
    :ROOKIDEE, :URSHIFU, :URSHIFU_1, :CALYREX_1, :CALYREX_2,
    # Gen IX
    :QUAXLY, :QUAXWELL, :QUAQUAVAL, :WIGLETT, :WUGTRIO, :FLAMIGO
  ]

  #-----------------------------------------------------------------------------
  # Fly Animation Settings
  #-----------------------------------------------------------------------------
  # Set to true to disable the fly animation
  DISABLE_FLY_ANIMATION = false


  # Permitir el follow dentro de edificios a Pokémon de más de 3 m.
  TALL_POKEMON_INDOOR = true

  # Permitir que el jugador hable con el Pokémon que le sigue.
  CAN_TALK_WITH_POKEMON = true

  #-----------------------------------------------------------------------------
  # Distance Setting
  #-----------------------------------------------------------------------------
  # La distancia en píxeles para alejar visualmente al seguidor lejos del jugador
  # para evitar superposiciones.
  FOLLOWER_DISTANCE_OFFSET = 8

  # Offsets específicos de distancia para ciertos Pokémon (por ejemplo, sprites grandes).
  # Úsalo para anular el offset predeterminado anterior.
  # Formato: :ESPECIE => offset_en_píxeles
  FOLLOWER_DISTANCE_EXCEPTIONS = {
    # Gen 1
    :VENUSAUR   => 16, :CHARIZARD  => 16, :BLASTOISE  => 16,
    :ONIX       => 24, :GYARADOS   => 24, :LAPRAS     => 16,
    :SNORLAX    => 16, :ARTICUNO   => 16, :ZAPDOS     => 16,
    :MOLTRES    => 16, :DRAGONITE  => 16, :MEWTWO     => 16,
    :RHYDON     => 16,
    # Gen 2
    :MEGANIUM   => 16, :FERALIGATR => 16, :STEELIX    => 24,
    :LUGIA      => 24, :HOOH       => 24, :TYRANITAR  => 16,
    # Gen 3
    :SCEPTILE   => 16, :SWAMPERT   => 16, :WAILORD    => 32,
    :AGGRON     => 16, :METAGROSS  => 16, :REGIROCK   => 16,
    :REGICE     => 16, :REGISTEEL  => 16, :KYOGRE     => 32,
    :GROUDON    => 32, :RAYQUAZA   => 32,
    # Gen 4
    :TORTERRA   => 24, :GARCHOMP   => 16, :RHYPERIOR  => 24,
    :DIALGA     => 32, :PALKIA     => 32, :HEATRAN    => 16,
    :REGIGIGAS  => 24, :GIRATINA   => 32, :ARCEUS     => 24,
    # Gen 5
    :SERPERIOR  => 16, :SCOLIPEDE  => 24, :GIGALITH   => 16,
    :RESHIRAM   => 32, :ZEKROM     => 32, :KYUREM     => 32,
    # Gen 6
    :XERNEAS    => 24, :YVELTAL    => 24, :ZYGARDE    => 32,
    :HOOPA      => 24, :VOLCANION  => 16,
    # Gen 7
    :SOLGALEO   => 24, :LUNALA     => 24, :NECROZMA   => 24,
    :GUZZLORD   => 32, :STAKATAKA  => 32,
    # Gen 8
    :ETERNATUS  => 32, :ZAMAZENTA  => 16, :ZACIAN     => 16,
    :CALYREX    => 16, :REGIDRAGO  => 16, :REGIELEKI  => 16
  }
end

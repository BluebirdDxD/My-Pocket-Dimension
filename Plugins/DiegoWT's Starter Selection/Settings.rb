#===============================================================================
# DiegoWT's Starter Selection script settings
# Traducido por Skyflyer
#===============================================================================
module StarterSelSettings

  # Para iniciar la escena, llama al script "DiegoWTsStarterSelection.new(x,y,z)", donde x, y y z son el ID de especie de tus starters.
  # Ejemplo de llamada al script usando Bulbasaur, Charmander y Squirtle:
  # DiegoWTsStarterSelection.new(:BULBASAUR,:CHARMANDER,:SQUIRTLE)
  
  # Nivel de tus starters:
    STARTERL = 5
   
  # Estilo de interfaz (1 para HGSS, 2 para BW):
    INSTYLE = 1
  
  # Elección de fondo (1 para la mesa del laboratorio, 2 para hierba)
    STARTERBG = 1
  
  # Forma de cada especie de Starter:
    STARTER1FORM = 0 # Primer Starter
    STARTER2FORM = 0 # Segundo Starter
    STARTER3FORM = 0 # Tercer Starter
  
  # Si cada starter es shiny o no, 0 es aleatorio, 1 bloquea en no shiny, 2 bloquea en shiny:
    STARTER1SHINY = 0 # Primer Starter
    STARTER2SHINY = 0 # Segundo Starter
    STARTER3SHINY = 0 # Tercer Starter
  
  # Si cada especie de Starter tendrá IVs aleatorios o no, 0 es aleatorio, 1 son 31 IVs para cada estado:
    STARTER1IV = 0 # Primer Starter
    STARTER2IV = 0 # Segundo Starter
    STARTER3IV = 0 # Tercer Starter
  # También puedes editar el Script para cambiar los valores a algo que no sea 31, líneas: 79, 93 y 107
  
  # Objeto de cada Starter (nil es nada):
    STARTER1ITEM = nil # Primer Starter
    STARTER2ITEM = nil # Segundo Starter
    STARTER3ITEM = nil # Tercer Starter
  # Usa el ID de los objetos al definirlos aquí, y pon un : antes del nombre. Como :ORANBERRY
    
  # Valores horizontales y verticales para editar la posición del starter:
    STARTER1X = 0; STARTER1Y = 0 # Primer Starter
    STARTER2X = 0; STARTER2Y = 0 # Segundo Starter
    STARTER3X = 0; STARTER3Y = 0 # Tercer Starter
  # Aquí, para las líneas horizontales, los números negativos son izquierda y los positivos
  # son derecha. Para las líneas verticales, los números negativos son arriba y los
  # positivos son abajo. ¡Siempre intenta usar números pares!
    
  # Configuración del tamaño del círculo del Starter. Configura qué tan grande quieres que sea el círculo blanco del Starter:
    STARTERCZ = 0 # 0 es tamaño normal; 1 es el doble del tamaño
    
  # Pon true si quieres que el script reproduzca el grito del starter seleccionado cuando se selecciona, 
  # o false si no:
    STARTERCRY = true
  
  # Configuración para usar dos gradientes para que coincidan con los colores de ambos tipos del starter.
  # Esto también funcionará si uno o más de tus starters solo tienen un tipo.
  # Pon true si quieres esto, o false si no:
    TYPE2COLOR = true
  
  end
  
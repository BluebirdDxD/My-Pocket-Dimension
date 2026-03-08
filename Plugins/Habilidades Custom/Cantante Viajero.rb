Battle::AbilityEffects::OnEndOfUsingMove.add(:MIGRANTSINGER,
  proc { |ability, user, targets, move, battle|
    # 1. Verificamos si el movimiento es de sonido
    next if !move.soundMove?
    
    # 2. Verificamos si puede subir la estadística (para que no salga el mensaje si ya está al máximo)
    next if !user.pbCanRaiseStatStage?(:SPECIAL_ATTACK, user)

    # 3. Subimos la estadística. 
    # Esta función AUTOMÁTICAMENTE muestra la "Ability Splash" (la barra de la habilidad).
    user.pbRaiseStatStageByAbility(:SPECIAL_ATTACK, 1, user)
  }
)
Battle::AbilityEffects::OnSwitchIn.add(:ADORABLE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.allOtherSideBattlers(battler.index, true).each do |b|
      next if !b.near?(battler)
      check_item = true
      if b.hasActiveAbility?(:CONTRARY)
        check_item = false if b.statStageAtMax?(:SPECIAL_ATTACK)
      elsif b.statStageAtMin?(:SPECIAL_ATTACK)
        check_item = false
      end
      check_ability = b.pbLowerStatStage(:SPECIAL_ATTACK, 1, battler)
      b.pbAbilitiesOnIntimidated if check_ability
      b.pbItemOnIntimidatedCheck if check_item
    end
    battle.pbHideAbilitySplash(battler)
  }
)
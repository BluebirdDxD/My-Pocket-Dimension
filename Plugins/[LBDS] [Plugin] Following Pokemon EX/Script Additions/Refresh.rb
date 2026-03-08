#===============================================================================
# [Following Pokemon EX] Refresh.rb
# patched for v22 compatibility
#===============================================================================

#-------------------------------------------------------------------------------
# Refresh Following Pokemon when mounting Bike
#-------------------------------------------------------------------------------
alias __followingpkmn__pbMountBike pbMountBike unless defined?(__followingpkmn__pbMountBike)
def pbMountBike(*args)
  ret = __followingpkmn__pbMountBike(*args)
  FollowingPkmn.refresh(false)
  return ret
end

alias __followingpkmn__pbDismountBike pbDismountBike unless defined?(__followingpkmn__pbDismountBike)
def pbDismountBike(*args)
  ret = __followingpkmn__pbDismountBike(*args)
  FollowingPkmn.refresh(false)
  return ret
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon when using PC
#-------------------------------------------------------------------------------
alias __followingpkmn__pbTrainerPC pbTrainerPC unless defined?(__followingpkmn__pbTrainerPC)
def pbTrainerPC(*args)
  ret = __followingpkmn__pbTrainerPC(*args)
  FollowingPkmn.refresh(false)
  return ret
end

alias __followingpkmn__pbPokeCenterPC pbPokeCenterPC unless defined?(__followingpkmn__pbPokeCenterPC)
def pbPokeCenterPC(*args)
  $game_temp.pokecenter_following_pkmn = 0
  if FollowingPkmn.active?
    $game_temp.pokecenter_following_pkmn = 1
    $game_temp.pokecenter_following_pkmn = 2 if FollowingPkmn::SHOW_POKECENTER_ANIMATION
  end
  ret = __followingpkmn__pbPokeCenterPC(*args)
  FollowingPkmn.refresh(false)
  return ret
end

#-------------------------------------------------------------------------------
# [V22 Port] Refresh Following Pokemon after Party Screen closes
# This patches the PokemonPartyScreen class directly to ensure compatibility
# with Modular UI Scenes plugin which overrides the global pbPokemonScreen
#-------------------------------------------------------------------------------
class PokemonPartyScreen
  alias __followingpkmn__pbPokemonScreen pbPokemonScreen unless method_defined?(:__followingpkmn__pbPokemonScreen)
  def pbPokemonScreen
    ret = __followingpkmn__pbPokemonScreen
    FollowingPkmn.refresh(false) if defined?(FollowingPkmn)
    return ret
  end
end

#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# [V22 Port] Refresh Following Pokemon after Evolution
# patched into PokemonEvolutionScene
#-------------------------------------------------------------------------------
class PokemonEvolutionScene
  alias __followingpkmn__pbEndScreen pbEndScreen unless method_defined?(:__followingpkmn__pbEndScreen)
  def pbEndScreen(*args)
    ret = __followingpkmn__pbEndScreen(*args)
    FollowingPkmn.refresh(false)
    return ret
  end
end

#-------------------------------------------------------------------------------
# [V22 Port] Refresh Following Pokemon after Trade
#-------------------------------------------------------------------------------
# NOTE: pbStartTrade is usually a global function.
alias __followingpkmn__pbStartTrade pbStartTrade unless defined?(__followingpkmn__pbStartTrade)
def pbStartTrade(*args)
  ret = __followingpkmn__pbStartTrade(*args)
  FollowingPkmn.refresh(false)
  return ret
end

#-------------------------------------------------------------------------------
# [V22 Port] Refresh Following Pokemon after Hatching
#-------------------------------------------------------------------------------
alias __followingpkmn__pbHatch pbHatch unless defined?(__followingpkmn__pbHatch)
def pbHatch(*args)
  ret = __followingpkmn__pbHatch(*args)
  FollowingPkmn.refresh(false)
  return ret
end
#-------------------------------------------------------------------------------
# [V22 Port] Refresh Following Pokemon after Bag (Item Choice)
#-------------------------------------------------------------------------------
alias __followingpkmn__pbChooseItem pbChooseItem unless defined?(__followingpkmn__pbChooseItem)
def pbChooseItem(*args)
  ret = __followingpkmn__pbChooseItem(*args)
  FollowingPkmn.refresh(false)
  return ret
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after using Debug menu
#-------------------------------------------------------------------------------
alias __followingpkmn__pbDebugMenu pbDebugMenu unless defined?(__followingpkmn__pbDebugMenu)
def pbDebugMenu(*args)
  ret = __followingpkmn__pbDebugMenu(*args)
  FollowingPkmn.refresh(false)
  return ret
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after taking a step, when a refresh is queued
#-------------------------------------------------------------------------------
class Scene_Map
  alias __followingpkmn__update update unless method_defined?(:__followingpkmn__update)
  def update(*args)
    __followingpkmn__update(*args)
    # Check toggle key first (before active? check) so we can toggle back on
    t_key = FollowingPkmn::TOGGLE_FOLLOWER_KEY
    if t_key && FollowingPkmn.can_check? && Input.trigger?(t_key)
      FollowingPkmn.toggle
    end
    return if !FollowingPkmn.active?
    
    # Quick party cycling with W/S/A keys
    if FollowingPkmn.can_check? && $player && $player.party.length >= 2 && FollowingPkmn::ENABLE_PARTY_CYCLING
      if !$game_temp.in_battle && !$game_temp.in_menu && !$game_player.moving?
        # S key - Rotate party forward (first Pokemon goes to end)
        forward_key = FollowingPkmn::CYCLE_PARTY_FORWARD_KEY
        if forward_key && Input.trigger?(forward_key)
          first_pkmn = $player.party.shift
          $player.party.push(first_pkmn)
          pbSEPlay("GUI party switch") rescue pbSEPlay("Choose")
          FollowingPkmn.refresh(true) if defined?(FollowingPkmn)
        end
        
        # W key - Rotate party backward (last Pokemon goes to first)
        backward_key = FollowingPkmn::CYCLE_PARTY_BACKWARD_KEY
        if backward_key && Input.trigger?(backward_key)
          last_pkmn = $player.party.pop
          $player.party.unshift(last_pkmn)
          pbSEPlay("GUI party switch") rescue pbSEPlay("Choose")
          FollowingPkmn.refresh(true) if defined?(FollowingPkmn)
        end
      end
    end
    
    if $PokemonGlobal.call_refresh[0]
      FollowingPkmn.refresh($PokemonGlobal.call_refresh[1])
      $PokemonGlobal.call_refresh = false
    end
  end
  #-----------------------------------------------------------------------------
  # Update Following Pokemon's time_taken for to tracking the happiness increase
  # and hold item
  #-----------------------------------------------------------------------------
  alias __followingpkmn__miniupdate miniupdate unless method_defined?(:__followingpkmn__miniupdate)
  def miniupdate(*args)
    __followingpkmn__miniupdate(*args)
    return if !FollowingPkmn.active?
    FollowingPkmn.increase_time
  end
  #-----------------------------------------------------------------------------
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after using the Pokecenter
#-------------------------------------------------------------------------------
# Queue a Pokecenter refresh if the Following Pokemon is active and the player
# heals at a PokeCenter
alias __followingpkmn__pbSetPokemonCenter pbSetPokemonCenter unless defined?(__followingpkmn__pbSetPokemonCenter)
def pbSetPokemonCenter(*args)
  ret = __followingpkmn__pbSetPokemonCenter(*args)
  $game_temp.pokecenter_following_pkmn = 1  if FollowingPkmn::SHOW_POKECENTER_ANIMATION && FollowingPkmn.active?
  return ret
end

class Interpreter
  #-----------------------------------------------------------------------------
  # Toggle Following Pokemon off if a Pokecenter refresh is queued and the
  # Pokemon are healed
  #-----------------------------------------------------------------------------
  alias __followingpkmn__command_314 command_314 unless method_defined?(:__followingpkmn__command_314)
  def command_314(*args)
    ret = __followingpkmn__command_314(*args)
    if FollowingPkmn::SHOW_POKECENTER_ANIMATION && $game_temp.pokecenter_following_pkmn > 0 &&
      FollowingPkmn.active?
      FollowingPkmn.toggle_off
      $game_temp.pokecenter_following_pkmn = 2
    end
    return ret
  end
  #-----------------------------------------------------------------------------
  # Refresh Following Pokemon after using the Pokecneter healing event is
  # completely done
  #-----------------------------------------------------------------------------
  alias __followingpkmn__update update unless method_defined?(:__followingpkmn__update)
  def update(*args)
    __followingpkmn__update(*args)
    if FollowingPkmn::SHOW_POKECENTER_ANIMATION && $game_temp.pokecenter_following_pkmn > 0 && !running?
      FollowingPkmn.toggle_on
      $game_temp.pokecenter_following_pkmn = 0
    end
  end
  #-----------------------------------------------------------------------------
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after Day Care interaction
#-------------------------------------------------------------------------------
class DayCare
  class << self
    alias __followingpkmn__deposit deposit unless method_defined?(:__followingpkmn__deposit)
    def deposit(*args)
      ret = __followingpkmn__deposit(*args)
      FollowingPkmn.refresh(false)
      return ret
    end

    alias __followingpkmn__withdraw withdraw unless method_defined?(:__followingpkmn__withdraw)
    def withdraw(*args)
      ret = __followingpkmn__withdraw(*args)
      FollowingPkmn.refresh(false)
      return ret
    end
  end
end

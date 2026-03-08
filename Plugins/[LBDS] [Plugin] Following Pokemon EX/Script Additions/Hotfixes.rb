#-------------------------------------------------------------------------------
# Refresh Following Pokemon upon loading up the game
#-------------------------------------------------------------------------------
module Game
  class << self
    alias __followingpkmn__load_map load_map unless method_defined?(:__followingpkmn__load_map)
    alias __followingpkmn__load load unless method_defined?(:__followingpkmn__load)
  end

  # Fix for frozen player when saving during Following Pokemon animations
  # This hook runs when loading a saved game
  def self.load(*args)
    __followingpkmn__load(*args)
    FollowingPkmn.clear_frozen_state
    FollowingPkmn.reset_follower_position
  end

  def self.load_map(*args)
    __followingpkmn__load_map(*args)
    FollowingPkmn.clear_frozen_state
    FollowingPkmn.reset_follower_position
    FollowingPkmn.refresh(false)
  end
end

module FollowingPkmn
  # Clear any stale movement states that may have been saved mid-animation
  def self.clear_frozen_state
    # Clear stale move routes from the player
    if $game_player
      $game_player.instance_variable_set(:@move_route_forcing, false)
      $game_player.instance_variable_set(:@original_move_route, nil)
      $game_player.instance_variable_set(:@original_move_route_index, 0)
      $game_player.instance_variable_set(:@locked, false)
      $game_player.instance_variable_set(:@wait_count, 0)
      $game_player.instance_variable_set(:@wait_start, nil)
    end
    # Also clear stale move routes from the Following Pokemon event
    follower_event = FollowingPkmn.get_event rescue nil
    if follower_event
      follower_event.instance_variable_set(:@move_route_forcing, false)
      follower_event.instance_variable_set(:@original_move_route, nil)
      follower_event.instance_variable_set(:@original_move_route_index, 0)
      follower_event.instance_variable_set(:@locked, false)
      follower_event.instance_variable_set(:@wait_count, 0)
      follower_event.instance_variable_set(:@wait_start, nil)
    end
    # Re-enable menu in case it was disabled during a Following Pokemon interaction
    $game_system.menu_disabled = false if $game_system
  end

   # Reset follower position to be next to the player
  def self.reset_follower_position
    return if !$game_temp || !$PokemonGlobal || !$game_player
    # Force recreation of the follower factory to properly link with loaded save data
    $game_temp.instance_variable_set(:@followers, nil)
    # This will trigger the lazy initialization with fresh data from $PokemonGlobal
    $game_temp.followers
  end
end

#-------------------------------------------------------------------------------
# Fix frozen player state when entering a map (safety net for interrupted animations)
# Also unhide follower after map transfer completes
#-------------------------------------------------------------------------------
EventHandlers.add(:on_enter_map, :following_pkmn_unfreeze_player, proc { |_old_map_id|
  FollowingPkmn.clear_frozen_state
  # Desocultar el follower después del cambio de mapa
  FollowingPkmn.unhide_follower(false) if FollowingPkmn.hidden?
})

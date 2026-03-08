#-------------------------------------------------------------------------------
# New animation to show the Following Pokemon execcuting a field move in the
# overworld
#-------------------------------------------------------------------------------
alias __followingpkmn__pbHiddenMoveAnimation pbHiddenMoveAnimation unless defined?(__followingpkmn__pbHiddenMoveAnimation)
def pbHiddenMoveAnimation(pokemon, field_move = true)
  no_field_move = !field_move || $game_temp.no_follower_field_move
  FollowingPkmn.move_route([PBMoveRoute::WAIT, 1]) if pokemon && FollowingPkmn.active?
  ret = __followingpkmn__pbHiddenMoveAnimation(pokemon)
  return ret if !ret || no_field_move || !FollowingPkmn.active? || pokemon != FollowingPkmn.get_pokemon
  initial_dir  = $game_player.direction
  pbTurnTowardEvent(FollowingPkmn.get_event, $game_player)
  pbWait(0.2)
  moved_dir    = 0
  possible_dir = []
  possible_dir.push($game_player.direction)
  possible_dir.push(10 - $game_player.direction)
  [2, 8, 4, 6].each { |d| possible_dir.push(d) if !possible_dir.include?(d) }
  possible_dir.each do |d|
    next if !$game_player.passable?($game_player.x, $game_player.y, 10 - d)
    moved_dir = 10 - d
    break
  end 
  if moved_dir > 0
    FollowingPkmn.get_event.move_toward_player
    pbMoveRoute($game_player, [(moved_dir) / 2], true)
    pbWait(0.2)
    pbTurnTowardEvent($game_player, FollowingPkmn.get_event)
    pbWait(0.2)
    FollowingPkmn.move_route([15 + (initial_dir / 2)])
    pbWait(0.2)
  end
  pbSEPlay("Player jump")
  FollowingPkmn.move_route([PBMoveRoute::JUMP, 0, 0])
  pbWait(0.2)
  return ret
end

#-------------------------------------------------------------------------------
# New sendout animation for Following Pokemon to slide in when sent out for
# the first time in battle. Toggleable.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::PokeballPlayerSendOut < Battle::Scene::Animation
  def initialize(sprites, viewport, idxTrainer, battler, startBattle, idxOrder=0)
    @idxTrainer     = idxTrainer
    @battler        = battler
    @showingTrainer = startBattle
    @idxOrder       = idxOrder
    @trainer        = @battler.battle.pbGetOwnerFromBattlerIndex(@battler.index)
    @shadowVisible  = sprites["shadow_#{battler.index}"].visible
    @sprites        = sprites
    @viewport       = viewport
    @pictureEx      = []   # For all the PictureEx
    @pictureSprites = []   # For all the sprites
    @tempSprites    = []   # For sprites that exist only for this animation
    @animDone       = false
    if FollowingPkmn.active? && startBattle &&
       battler.index == 0 && FollowingPkmn::SLIDE_INTO_BATTLE
      createFollowerProcesses
    else
      createProcesses
    end
  end

  def createFollowerProcesses
    delay = 0
    delay = 5 if @showingTrainer
    batSprite = @sprites["pokemon_#{@battler.index}"]
    shaSprite = @sprites["shadow_#{@battler.index}"]
    batSprite.y
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    battler.setVisible(delay, true)
    battler.setZoomXY(delay, 100, 100)
    battler.setColor(delay, Color.new(0, 0, 0, 0))
    battler.setDelta(0, -240, 0)
    battler.moveDelta(delay, 12, 240, 0)
    battler.setCallback(delay + 12, [batSprite,:pbPlayIntroAnimation])
    if @shadowVisible
      shadow = addSprite(shaSprite, PictureOrigin::CENTER)
      # Calculate shadow size like shadowAppear does
      if batSprite.respond_to?(:shadowVisible) && batSprite.shadowVisible
        if batSprite.respond_to?(:substitute) && batSprite.substitute
          shadow_size = 1
        else
          pkmn = batSprite.pkmn
          if pkmn
            metrics = GameData::SpeciesMetrics.get_species_form(pkmn.species, pkmn.form, pkmn.female?)
            shadow_size = metrics.shadow_size
            shadow_size -= 1 if shadow_size > 0
          else
            shadow_size = 1
          end
        end
        zoomX = 100 * (1 + shadow_size * 0.1)
        zoomY = 100 * (1 * 0.25 + (shadow_size * 0.025))
        shadow.setZoomXY(delay, zoomX, zoomY)
      end
      shadow.setVisible(delay, true)
      shadow.setDelta(0, -Graphics.width/2, 0)
      shadow.moveDelta(delay, 12, Graphics.width/2, 0)
    end
  end
end

#-------------------------------------------------------------------------------
# Tiny fix for emote Animations not playing in v20 since people are unable to
# read instructions and can't close RMXP before adding the Following Pokemon
# EX emote animations
#-------------------------------------------------------------------------------
class SpriteAnimation
  def effect?; return @_animation_duration > 0 if @_animation_duration; end
end
# Chris Tan Jian Yi — Player Systems and Integration
Student ID: 2400874

## Responsibilities
- Reusable Player scene and controller
- Input Map configuration
- Movement, run, jump, gravity, drop-through platform
- Health, damage, invincibility, respawn signals
- Torchlight cooldown and stun interface
- Generic F interaction system
- Player test scenes

## Main Files Owned
- scenes/player/player.tscn
- scripts/player/player.gd
- scenes/testing/player_test_level.tscn

## How to Test
Open scenes/testing/player_test_level.tscn and press F6.

## Integration Rules
- Guardian damage Area2D: `damage_zone` group
- Guardian torch target: `stunnable` group plus `stun()` function
- Interactable object: `interactable` group plus `interact(player)` function


# Shared Player System — Chris Tan Jian Yi

## Files
- Player scene: `scenes/player/player.tscn`
- Player script: `scripts/player/player.gd`
- Player test scene: `scenes/testing/player_test_level.tscn`

After the Player branch is merged into `main`, pull the latest `main` branch before using these files.

## How to add the player to a level
1. Open your level scene.
2. Drag `scenes/player/player.tscn` into the level.
3. Set the Player instance Position to the spawn point.
4. Do not rename the Player’s child nodes, because the script uses these names:
   - `AnimatedSprite2D`
   - `HurtBox`
   - `TorchZone`
   - `Flashlight`
   - `InteractionZone`

The Player scene already includes movement, collision, camera, health, torchlight, and interaction logic.

## Controls
- A / Left Arrow: move left
- D / Right Arrow: move right
- Shift: run
- Space / Up Arrow: jump
- S / Down Arrow: drop through one-way platform
- F: interact
- Left Mouse Button: torchlight flash

## Environment setup
For normal ground/walls:
- Use `StaticBody2D`
- Add `CollisionShape2D`

For a drop-through platform:
- Use `StaticBody2D`
- Add `CollisionShape2D`
- Enable `One Way Collision`

Ang can set `Camera2D` limits inside each level.

## Guardian integration for Kok
### Damage the player
Create a Guardian attack/touch `Area2D` with a `CollisionShape2D`.

Add the Area2D to this Scene Group:

```text
damage_zone

hvgcvhbjkhgyu

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

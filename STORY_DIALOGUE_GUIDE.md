# Intro and ending dialogue

The working scenes are now INSIDE Project_Hajimi. The older Level1_Intro_Assets project is only an artwork preview.

## Test in Godot

1. Open the main Project_Hajimi project.godot. Let Godot finish importing the story images and fonts.
2. In FileSystem, open scenes/story/intro_dialogue.tscn. Press F6 to play the intro. Its controls are click/Enter/Space to reveal or advance, Esc or the top-right Skip label to skip. Completing it enters Level 1.
3. Stop the game. Open scenes/story/ending_dialogue.tscn and press F6 to test the ending independently. The witch prepares the potion, Mum recovers, and Journey Complete appears. Return to Main Menu works there.
4. Press F5 to test the normal game. Main menu Start resets story flags; select Level 1 to see its intro. Returning to the selector or respawning within the same run does not replay it. A new Start or new application session does.

These scenes generate their UI when run; a mostly empty editor viewport before pressing F6 is expected. They use a 1280x720 composition, scaled and letterboxed as necessary to prevent portrait/text overlap.

## Connect the completed Level 3

The local Level 3 scene is currently a Coming Soon placeholder, so it has no actual success/escape event to modify yet. Do not put the ending call in the Level 3 selector button or its _ready().

In the finished Level 3 controller, at the point where the player has collected the final ingredient AND successfully completed the final escape, replace its old menu/next-scene transition with:

```gdscript
StoryState.finish_level_three()
```

This function defers the scene change safely from physics signals, guards duplicate victory calls, unpauses the tree, and opens the ending. Do not also execute the old change_scene_to_file call afterward.

For example, if your controller already has level_complete(), place the call there only if that method represents the completed escape:

```gdscript
func level_complete() -> void:
    StoryState.finish_level_three()
```

There is no ingredient inventory validation in this story helper. The Level 3 controller is responsible for invoking it at genuine victory.

## Edit the dialogue and appearance

- scripts/story/story_lines.gd: INTRO and ENDING arrays. Each dictionary is one dialogue box. Edit text, speaker, left/right portrait filenames, or background. BBCode colours and waves are supported. Do not remove brackets or quotes around the data.
- scripts/story/story_dialogue.gd: layout, text speed, transition timing, colours, and completion screen. Default reveal speed is 32 characters/second with punctuation pauses.
- assets/images/story/: seven portraits, two backgrounds, and the automatic green-removal shader. No manual green removal is required.
- assets/fonts/story/: Cinzel for names/titles and IM Fell English for dialogue, from google/fonts, with OFL licences.
- scripts/story/story_state.gd: intro/new-run flags and the Level 3 victory API. Flags currently last for the running session; no save-game system was added.

The original gameplay sprite is unchanged. The existing DarkAgesUi sheet supplies the panel. Portraits are RGB green-backed PNGs and need the included ShaderMaterial, already assigned automatically by the dialogue script. Source-art provenance is recorded in STORY_ASSET_SOURCES.md.

## Verification

tests/story_smoke.gd exercises reveal/advance, punctuation-independent line fitting, fades, pause restoration, new-game reset, ending completion, duplicate victory calls and return to menu. Run with the project's Godot executable:

```text
godot --headless --path . --script res://tests/story_smoke.gd
```

Use --capture after a -- separator with a graphical renderer to also save review images in the system temporary hajimi-story-qa folder.

Verified in Godot 4.6.3: all functional assertions passed, including the actual Level 1 entry and reload. Rendered intro, longest line, potion, recovery and completion screens were inspected. Automated shutdown emits an existing forest.mp3 playback/resource cleanup warning; no dialogue assertion failed. The full Level 3 escape cannot be tested until that map replaces its placeholder.

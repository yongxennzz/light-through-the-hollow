extends SceneTree

var failures := 0
var capture := false
var output_dir := ""

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func settle() -> void:
	await process_frame
	await process_frame

func screenshot(name: String) -> void:
	if capture:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output_dir.path_join(name + ".png"))

func _run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	output_dir = OS.get_environment("TEMP").path_join("hajimi-story-qa")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var state = root.get_node("StoryState")
	state.new_game()
	var fixture := Node2D.new()
	root.add_child(fixture)
	current_scene = fixture
	var intro = load("res://scenes/story/intro_dialogue.tscn").instantiate()
	fixture.add_child(intro)
	await settle()
	check(paused, "Intro must pause gameplay")
	intro.advance()
	check(not intro.typing and intro.line_index == 0, "First advance must reveal, not skip, the current line")
	await screenshot("intro_first")
	for index in range(intro.lines.size()):
		intro.line_index = index
		intro._apply_line()
		intro._reveal_all()
		await settle()
		check(intro.dialogue.get_content_height() <= intro.dialogue.size.y, "Intro text clipped at line %d" % index)
		if index == 5:
			await screenshot("intro_longest")
	# Exercise the actual background fade path.
	intro.line_index = 2
	intro._apply_line()
	intro._reveal_all()
	intro.advance()
	check(intro.transitioning, "Cottage exit must transition")
	await create_timer(0.65).timeout
	check(not intro.transitioning and intro.current_background == "cottage_outside", "Background transition must finish")
	# Escape consumes input and ends the intro, then restores the previous pause.
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	intro._input(escape)
	await settle()
	check(state.intro_seen and not paused, "Skipped intro must mark seen and restore gameplay")
	check(not is_instance_valid(intro), "Overlay must remove itself")
	# Existing Level 1 hook is covered without loading its unrelated map resources.
	paused = true
	var paused_intro = load("res://scenes/story/intro_dialogue.tscn").instantiate()
	fixture.add_child(paused_intro)
	paused_intro._finish_story()
	await settle()
	check(paused, "Overlay must preserve a pre-existing pause")
	paused = false
	state.new_game()
	check(not state.intro_seen and not state.ending_started, "New game must reset both flags")
	var ending = load("res://scenes/story/ending_dialogue.tscn").instantiate()
	fixture.add_child(ending)
	for index in range(ending.lines.size()):
		ending.line_index = index
		ending._apply_line()
		ending._reveal_all()
		await settle()
		check(ending.dialogue.get_content_height() <= ending.dialogue.size.y, "Ending text clipped at line %d" % index)
		if index == 3:
			check(ending.glow.visible, "Potion preparation must show the glow")
			await screenshot("ending_potion")
		if index == 7:
			await screenshot("ending_cured")
	ending.advance()
	await settle()
	check(ending.completed and ending.finish_screen.visible, "Last ending line must show Journey Complete")
	await screenshot("ending_complete")
	ending.queue_free()
	await settle()
	check(not paused, "Freeing the ending must release pause")
	# Victory API guards duplicate calls and opens the actual ending scene.
	state.finish_level_three()
	state.finish_level_three()
	await settle()
	await settle()
	check(current_scene.scene_file_path == "res://scenes/story/ending_dialogue.tscn", "Level 3 victory API must open the ending")
	current_scene._finish_story()
	check(current_scene.completed, "Skipping ending must still show completion")
	current_scene._return_to_menu()
	await settle()
	await settle()
	check(not paused and current_scene.scene_file_path == "res://scenes/ui/main_menu.tscn", "Completion must return to an unpaused main menu")
	# Validate the hook in the actual Level 1 scene and its reload behaviour.
	state.new_game()
	change_scene_to_file("res://scenes/levels/level_1/level_1.tscn")
	await settle()
	await settle()
	check(current_scene.has_node("IntroDialogue") and paused, "Actual Level 1 must show intro on first entry")
	if current_scene.has_node("IntroDialogue"):
		current_scene.get_node("IntroDialogue")._finish_story()
	await settle()
	check(not paused and state.intro_seen, "Actual Level 1 must resume after intro")
	reload_current_scene()
	await settle()
	await settle()
	check(not current_scene.has_node("IntroDialogue"), "Level 1 reload must not replay intro")
	root.get_node("MenuMusic").stop()
	root.get_node("MenuMusic").stream = null
	current_scene.queue_free()
	await settle()
	print("STORY_SMOKE failures=%d; captures=%s" % [failures, output_dir])
	quit(1 if failures else 0)

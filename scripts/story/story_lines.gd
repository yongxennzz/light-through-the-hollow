extends RefCounted

# Text is BBCode. Each dictionary describes one dialogue box.
# Left/right name a PNG in assets/images/story without its extension.
const INTRO: Array[Dictionary] = [
	{"speaker": "Boy", "left": "boy_worried", "right": "mother_weak", "background": "cottage_inside", "text": "Mum… I tried every herb I could find. Why aren't you getting better?"},
	{"speaker": "Mum", "left": "boy_worried", "right": "mother_reassuring", "background": "cottage_inside", "text": "You've done enough, my dear. Come and rest."},
	{"speaker": "Boy", "left": "boy_sad", "right": "mother_weak", "background": "cottage_inside", "text": "But I still haven't helped you…"},
	{"speaker": "Witch", "left": "boy_sad", "right": "witch_neutral", "background": "cottage_outside", "text": "Ordinary herbs cannot undo [color=#dba39d]dark magic[/color]."},
	{"speaker": "Boy", "left": "boy_worried", "right": "witch_neutral", "background": "cottage_outside", "text": "You know what's wrong with her? Can you help?"},
	{"speaker": "Witch", "left": "boy_worried", "right": "witch_neutral", "background": "cottage_outside", "text": "Bring me [color=#dcc47c]three rare ingredients[/color]—from the [color=#dcc47c]Whispering Forest[/color], the [color=#dcc47c]Hollow Mine[/color], and the [color=#dcc47c]Forgotten Dungeon[/color]."},
	{"speaker": "Witch", "left": "boy_worried", "right": "witch_serious", "background": "cottage_outside", "text": "Together, they can break her [wave amp=3.0 freq=2.0][color=#dba39d]curse[/color][/wave]. But [color=#dba39d]Guardians[/color] haunt those places."},
	{"speaker": "Boy", "left": "boy_determined", "right": "witch_neutral", "background": "cottage_outside", "text": "Then I'll start with the forest. Mum is waiting for me."},
]

const ENDING: Array[Dictionary] = [
	{"speaker": "Boy", "left": "boy_determined", "right": "witch_neutral", "background": "cottage_inside", "text": "I found them—all three. Please, help my mum."},
	{"speaker": "Witch", "left": "boy_determined", "right": "witch_neutral", "background": "cottage_inside", "text": "You've done well. These are exactly what we need."},
	{"speaker": "Witch", "left": "boy_worried", "right": "witch_serious", "background": "cottage_inside", "text": "Together, these ingredients will break the curse."},
	{"speaker": "", "left": "boy_worried", "right": "witch_neutral", "background": "cottage_inside", "brew": true, "text": "The witch grinds the ingredients, murmuring a spell. [color=#dcc47c]A golden light[/color] gathers in the bowl."},
	{"speaker": "Witch", "left": "boy_worried", "right": "witch_neutral", "background": "cottage_inside", "text": "It is ready. Help her drink, slowly."},
	{"speaker": "", "left": "boy_worried", "right": "mother_weak", "background": "cottage_inside", "transition": true, "text": "He helps his mother drink the potion. For a moment, the room falls silent."},
	{"speaker": "Boy", "left": "boy_worried", "right": "mother_weak", "background": "cottage_inside", "text": "Mum… can you hear me?"},
	{"speaker": "Mum", "left": "boy_worried", "right": "mother_reassuring", "background": "cottage_inside", "text": "Yes, my dear… the pain is gone."},
	{"speaker": "Boy", "left": "boy_determined", "right": "mother_reassuring", "background": "cottage_inside", "text": "You're better… You're really better!"},
	{"speaker": "Witch", "left": "boy_determined", "right": "witch_neutral", "background": "cottage_inside", "text": "The [color=#dcc47c]curse is broken[/color]. She needs rest now."},
	{"speaker": "Mum", "left": "boy_determined", "right": "mother_reassuring", "background": "cottage_inside", "text": "You brought me home from the darkness. Come here."},
	{"speaker": "Boy", "left": "boy_determined", "right": "mother_reassuring", "background": "cottage_inside", "text": "I'm here, Mum. I'm not going anywhere."},
]

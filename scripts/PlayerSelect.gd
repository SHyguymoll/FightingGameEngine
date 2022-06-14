extends Area

var player: int
var selected: int

var maxWidth: int
var lastID: int
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func move():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed(("first" if player == 1 else "second") + "_left"):
		if selected % maxWidth == 0:
			selected += maxWidth - 1
		else:
			selected -= 1
	if Input.is_action_just_pressed(("first" if player == 1 else "second") + "_right"):
		if selected % maxWidth == maxWidth - 1:
			selected -= maxWidth - 1
		else:
			selected += 1
	if Input.is_action_just_pressed(("first" if player == 1 else "second") + "_up"):
		if (selected % maxWidth == selected) or selected == 0: #if mod of selected is selected then at top
			if (selected % maxWidth) > (lastID % maxWidth): #if position of last char is to the left of selected
				selected = lastID
			elif (selected % maxWidth) <= (lastID % maxWidth): #position of last char is directly below/to the right of selected
				selected = lastID - ((maxWidth - 1) - selected)
		else: #mod of selected does not equal selected, somewhere under the top
			selected -= maxWidth
	if Input.is_action_just_pressed(("first" if player == 1 else "second") + "_down"):
# warning-ignore:integer_division
# warning-ignore:integer_division
		if selected/maxWidth == lastID/maxWidth: #integer division trick, cursor at bottom of choices if true
			selected = selected % maxWidth
		else: #cursor anywhere from top of screen to bottom edge (but not bottom of select)
			if (selected + maxWidth) > lastID: #if last is to left of cursor
				selected = lastID
			else:
				selected += maxWidth

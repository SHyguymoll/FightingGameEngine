extends MeshInstance

var playerList = [
	"first",
	"second"
]
var player: int

var selected = Vector2(0, 0)
var maxX: int
var maxY: int

var choiceMade = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func move():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !choiceMade:
		if Input.is_action_just_pressed(playerList[player] + "_left"):
			selected.x -= 1
			if selected.x == -1:
				selected.x = maxX - 1
			if CharactersDict.charMap[selected.y][selected.x] == null:
				while CharactersDict.charMap[selected.y][selected.x] == null:
					selected.x -= 1
					if selected.x == -1:
						selected.x = maxX - 1
		if Input.is_action_just_pressed(playerList[player] + "_right"):
			selected.x += 1
			if selected.x == maxX:
				selected.x = 0
			if CharactersDict.charMap[selected.y][selected.x] == null:
				while CharactersDict.charMap[selected.y][selected.x] == null:
					selected.x += 1
					if selected.x == maxX:
						selected.x = 0
		if Input.is_action_just_pressed(playerList[player] + "_up"):
			selected.y -= 1
			if selected.y == -1:
				selected.y = maxY - 1
			if CharactersDict.charMap[selected.y][selected.x] == null:
				while CharactersDict.charMap[selected.y][selected.x] == null:
					selected.y -= 1
					if selected.y == -1:
						selected.y = maxY - 1
		if Input.is_action_just_pressed(playerList[player] + "_down"):
			selected.y += 1
			if selected.y == maxY:
				selected.y = 0
			if CharactersDict.charMap[selected.y][selected.x] == null:
				while CharactersDict.charMap[selected.y][selected.x] == null:
					selected.y += 1
					if selected.y == maxY:
						selected.y = 0
		choiceMade = Input.is_action_just_pressed(playerList[player] + "_button0")
	else:
		if Input.is_action_just_pressed(playerList[player] + "_button1"):
			choiceMade = false

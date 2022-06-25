extends Sprite3D

const menuPos = Vector3(0, -2, -10) #Only required variable

func _process(delta): #make this whatever you want
	rotation_degrees.y += delta * 10

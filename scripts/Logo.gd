extends Sprite3D

#REQUIRED VARIABLE
const menuPos = Vector3(0, 0, -15) #required to position the logo on the main menu
#REQUIRED METHOD
func buildTexture(image: String) -> ImageTexture:
	var iconTexture = ImageTexture.new()
	var iconImage = Image.new()
	iconImage.load(image)
	iconTexture.create_from_image(iconImage)
	return iconTexture

func _ready():
	texture = buildTexture(filename.get_base_dir() + "/Logo.png") #load the texture for the logo
	$Outline.texture = buildTexture(filename.get_base_dir() + "/LogoShadow.png") #if your logo has an outline, also load it here!
#passed this point, do whatever you want
	pass

func _process(delta): #make this whatever you want
	rotation_degrees.y += delta * 30

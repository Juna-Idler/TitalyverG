extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	
	var image = Image.new()
#	image.load("res://image_data/Titalyver.svg")
	image.load("C:/Users/junai/OneDrive/Pictures/vlcsnap-2022-04-08-18h38m47s576.png")
	
#	image = gaussian_blur(image,2,12)

	var width := image.get_width()
	var height := image.get_height()
#	image.resize(width / 5,height / 5,Image.INTERPOLATE_LANCZOS)
#	image.resize(width,height,Image.INTERPOLATE_BILINEAR)
	
	var texture := ImageTexture.create_from_image(image)
	
	%SubViewport.size = Vector2(width,height)
	
	%TextureRect.texture = texture
#	$TextureRect.texture = texture

	
	await RenderingServer.frame_post_draw
	var v_texture : ViewportTexture = %SubViewport.get_texture()
	var v_image := v_texture.get_image()
	$TextureRect.texture = ImageTexture.create_from_image(v_image)
	

func gaussian_blur(image : Image,r : int,d : float) -> Image:

	var weight := PackedFloat32Array()
	weight.resize(1 + r * 2)
	weight[r] = 1.0
	var total := 1.0
	
	for i in range(1,r + 1):
		var w := exp(-0.5 * pow(i,2) / d)
		weight[r + i] = w
		weight[r - i] = w
		total += w * 2
	for i in weight.size():
		weight[i] /= total
	
	image.convert(Image.FORMAT_RGBA8)
	var data := image.get_data()
	var height := image.get_height()
	var width := image.get_width()
	var tmp := PackedByteArray()
	tmp.resize(data.size())
	for y in height:
		for x in width:
			var total_color := Color(0,0,0,0)
			for w in range(-r,r + 1):
				if x + w < 0 or x + w >= width:
					continue
				var point : int = (y * width + x + w) * 4
				var c := Color8(data[point],data[point + 1],data[point + 2],data[point + 3])
				total_color += c * weight[w + r]
			var point : int = (y * width + x) * 4
			tmp[point] = total_color.r8
			tmp[point + 1] = total_color.g8
			tmp[point + 2] = total_color.b8
			tmp[point + 3] = total_color.a8

	for y in height:
		for x in width:
			var total_color := Color(0,0,0,0)
			for w in range(-r,r + 1):
				if y + w < 0 or y + w >= height:
					continue
				var point : int = ((y + w) * width + x) * 4
				var c := Color8(tmp[point],tmp[point + 1],tmp[point + 2],tmp[point + 3])
				total_color += c * weight[w + r]
			var point : int = (y * width + x) * 4
			data[point] = total_color.r8
			data[point + 1] = total_color.g8
			data[point + 2] = total_color.b8
			data[point + 3] = total_color.a8
	
	return Image.create_from_data(width,height,false,Image.FORMAT_RGBA8,data)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	

extends Node
class_name FixedSkylineProvider

func generate_specs(view_size: Vector2, ground_y: float) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	var x: float = 0.0
	var building_widths: Array[float] = [84.0, 66.0, 95.0, 72.0, 80.0, 60.0, 92.0, 70.0, 76.0, 88.0, 62.0, 94.0]
	var building_heights: Array[float] = [180.0, 220.0, 170.0, 260.0, 200.0, 240.0, 185.0, 230.0, 210.0, 165.0, 250.0, 190.0]
	var colors: Array[Color] = [
		Color("2d435f"), Color("374f6e"), Color("3e5d82"), Color("29405c"),
		Color("46648a"), Color("335474"), Color("2f4a68"), Color("3d597a")
	]
	var i: int = 0
	while x < view_size.x + 120.0:
		var width: float = building_widths[i % building_widths.size()]
		var height: float = building_heights[i % building_heights.size()]
		height = min(height, ground_y - 80.0)
		specs.append({
			"position": Vector2(x, ground_y - height),
			"size": Vector2(width, height),
			"color": colors[i % colors.size()]
		})
		x += width
		i += 1
	return specs

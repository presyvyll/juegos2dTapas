class_name CapAppearance
extends Resource
## Visual identity only. Textures can replace procedural art without changing physics.

enum Style { BALANCED, BOLD, SWIFT, TECH, ELEGANT, WILD }
@export var personality: String = "Equilibrada"
@export var style: Style = Style.BALANCED
@export var accent: Color = Color("fff0a6")
@export var trail_color: Color = Color("ffe786")
@export var body_texture: Texture2D
@export var portrait_texture: Texture2D

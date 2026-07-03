extends Resource
class_name PipeSliceConfig

# Texture của slice
@export var texture: Texture2D

# Bitmask năng lượng cục bộ (Top=1, Right=2, Bottom=4, Left=8)
@export var flow_mask: int = 0

# Mô tả ngắn gọn
@export var description: String = ""

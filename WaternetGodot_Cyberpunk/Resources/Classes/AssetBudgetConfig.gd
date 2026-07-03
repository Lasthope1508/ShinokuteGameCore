class_name AssetBudgetConfig
extends Resource

@export var web_pck_mb: float = 30.0
@export var android_aab_mb: float = 80.0
@export var texture_total_mb: float = 25.0
@export var generated_ui_mode_mb: float = 10.0
@export var single_texture_mb: float = 1.2
@export var vfx_atlas_mb: float = 1.5
@export var bgm_mb: float = 3.0
@export var sfx_total_mb: float = 2.0
@export var texture_import_compress_mode: int = 1
@export var texture_import_lossy_quality: float = 0.55
@export var bgm_publish_vorbis_quality: float = 0.0
@export var forbidden_export_markers: PackedStringArray = PackedStringArray([
	"debug/",
	"Tests/",
	"docs/",
	"component_refs/",
	"style_trial_",
	"_raw.png",
	"raw.png",
	"preview_sheet",
	"backup_cyberpunk_assets_before",
	"Audio/Music/Gameplay",
	"Audio/Sfx/default",
	"fruit_theme",
	"garden_theme",
	"wood_theme",
	"chaos",
	"energy_sheets_ai"
])
@export var runtime_manifest_path: String = "res://docs/runtime_asset_manifest.json"

# BloxChain VFX Checklist

- Runtime VFX uses Godot scenes/materials plus particle textures referenced by `ThemeManager`.
- Runtime VFX resource roots are limited to `effects/2d_explosion`, `effects/2d_vortex`, and `addons/kenney_particle_pack`.
- Non-runtime VFX workbench folders such as `effects/2d_eyeball`, `effects/2d_trail`, `effects/2d_water`, and `effects/3d_*` must not ship.
- Video captures and preview workbench media must not ship.

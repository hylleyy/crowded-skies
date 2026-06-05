shader_type canvas_item;

// Changed filter_nearest_mipmap to filter_linear_mipmap for a smooth blur
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float lod: hint_range(0.0, 5) = 0.0;

void fragment(){
    COLOR = textureLod(screen_texture, SCREEN_UV, lod);
}
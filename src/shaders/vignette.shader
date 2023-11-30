shader_type canvas_item;

uniform float intensity = 0.0; // This will be the starting intensity
uniform float alpha = 0.0; // This will control the transparency of the vignette

void fragment() {
    // Calculate the distance from the center of the screen
    vec2 center = vec2(0.5, 0.5);
    vec2 uv_offset = UV - center;
    float dist = length(uv_offset) * 2.0;

    // The smoothstep function will interpolate between the edge of the vignette and the center
    float vignette = smoothstep(1.0 - intensity, 1.0, dist);

    // Apply the vignette effect by reducing the color's brightness
    // based on the vignette factor and adjusting the alpha
    COLOR.rgb *= vignette; // This will darken the edges
    COLOR.a = alpha; // This will set the transparency
}

shader_type canvas_item;

uniform float junction : hint_range(-1.0, 2.0);

global uniform vec4 sleep_color;
global uniform vec4 standby_color;
global uniform vec4 active_color;

global uniform vec4 sleep_outline_color;
global uniform vec4 standby_outline_color;
global uniform vec4 active_outline_color;


void fragment() {
	vec4 tex = texture(TEXTURE,UV);
	vec4 color;

	if (junction <= -1.0 || junction >= 2.0)
	{
		color = tex.r * sleep_color + tex.g * sleep_outline_color;
	}
	else if (junction <= 0.0)
	{
		float rate = 0.0 - junction;
		color = tex.r * (standby_color * (1.0 - rate) + sleep_color * rate)
			  + tex.g * (standby_outline_color * (1.0 - rate) + sleep_outline_color * rate);
	}
	else if (junction >= 1.0)
	{
		float rate = junction - 1.0;
		color = tex.r * (active_color * (1.0 - rate) + sleep_color * rate)
			  + tex.g * (active_outline_color * (1.0 - rate) + sleep_outline_color * rate);
	}
	else
	{
		if (UV.x < junction)
		{
			color = tex.r * active_color + tex.g * active_outline_color;
		}
		else
		{
			color = tex.r * standby_color + tex.g * standby_outline_color;
		}
	}
	color.a = tex.a;
	COLOR = color;
}

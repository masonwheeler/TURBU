namespace dm.shaders

import System

partial class TdmShaders:
	private def Initialize():
		FragLibs = Dictionary[of string, string]()
		Vertex = Dictionary[of string, string]()
		Fragment = Dictionary[of string, string]()

		self.FragLibs.Add('shift',
"""
#version 140
uniform int hShift;
uniform float satMult;
uniform float valMult;
uniform vec4 rgbValues;

#define RED 0
#define GREEN 1
#define BLUE 2

const float epsilon = 1e-6;
const vec3 Luma = vec3(0.299, 0.587, 0.114);

vec3 RGBtoHSV(vec3 color)
{

	/* hue, saturation and value are all in the range [0,1> here , as opposed to their
		normal ranges of: hue: [0,360>, sat: [0, 100] and value:  [0, 256> */
	float hue, saturation, value, chroma, huePrime;
	float minCol, maxCol;
	int maxIndex;

	minCol = min(color.r, min(color.g, color.b));
	maxCol = max(color.r, max(color.g, color.b));

	if (maxCol == color.r){
		maxIndex = RED;}
	else if (maxCol == color.g){
		maxIndex = GREEN;}
	else maxIndex = BLUE;

	chroma = maxCol - minCol;

	/* Hue */
	if( chroma < epsilon){
		huePrime = 0.0;
	}
	else if(maxIndex == RED){
		huePrime = ((color.g - color.b) / chroma);
	}
	else if(maxIndex == GREEN){
		huePrime = ((color.b - color.r) / chroma) + 2.0;
	}
	else if(maxIndex == BLUE){
		huePrime = ((color.r - color.g) / chroma) + 4.0;
	}
	
	hue = huePrime / 6.0;

	/* Saturation */
	if(maxCol < epsilon)
	{
		saturation = 0.0;
		hue = 1.0;
	}
	else
		saturation = (maxCol - minCol) / maxCol;

	/* Value */
	value = maxCol;

	return vec3(hue, saturation, value);
}

vec3 HSVtoRGB(vec3 color)
{
	float f,p,q,t, hueRound;
	int hueIndex;
	float hue, saturation, value;
	vec3 result, luminance;

	/* just for clarity */
	hue = color.r;
	saturation = color.g;
	value = color.b;

	hueRound = floor(hue * 6.0);
	hueIndex = int(hueRound) % 6;
	f = (hue * 6.0) - hueRound;
	p = value * (1.0 - saturation);
	q = value * (1.0 - f*saturation);
	t = value * (1.0 - (1.0 - f)*saturation);
	
	switch(hueIndex)
	{
		case 0:
			result = vec3(value,t,p);
		break;
		case 1:
			result = vec3(q,value,p);
		break;
		case 2:
			result = vec3(p,value,t);
		break;
		case 3:
			result = vec3(p,q,value);
		break;
		case 4:
			result = vec3(t,p,value);
		break;
		case 5:
			result = vec3(value,p, q);
		break;
	}
	return clamp(result, 0.0, 1.0);
}

vec3 slideHue(vec3 rgbColor)
{
	vec3 hsvColor = RGBtoHSV(rgbColor);
	hsvColor.r = fract(hsvColor.r + (float(hShift) / 360.0) + 1.0);
	return HSVtoRGB(hsvColor);
}

vec3 HSVShift(vec3 rgbColor)
{
	vec3 grayVec;
	float gray;

	if (hShift != 0)
		rgbColor = slideHue(rgbColor);
	grayVec = rgbColor * Luma;
	gray = (grayVec.r + grayVec.g + grayVec.b);

	return clamp(mix(vec3(gray, gray, gray), rgbColor, satMult) * valMult, 0.0, 1.0);
}


void MixChannel(inout float channel, float modifier, float alpha)
{
	if (modifier < 1.0)
		channel *= modifier * alpha;
	else if (modifier > 1.0)
		channel += (modifier - 1.0) * alpha;
}

vec3 MixRGB(vec3 rgbColor)
{
	MixChannel(rgbColor.r, rgbValues.r, rgbValues.a);
	MixChannel(rgbColor.g, rgbValues.g, rgbValues.a);
	MixChannel(rgbColor.b, rgbValues.b, rgbValues.a);
	return rgbColor;
}

vec3 ProcessShifts(vec3 rgbColor)
{
	return(MixRGB(HSVShift(rgbColor)));
}""")

		self.Vertex.Add('default',
"""
#version 130
in vec2 RPG_Vertex;
in vec2 RPG_TexCoord;
in vec4 RPG_Color;
uniform mat4 RPG_ModelViewProjectionMatrix;
out vec2 texture_coordinate;
out vec4 v_color;

void main()
{
	gl_Position = RPG_ModelViewProjectionMatrix * vec4(RPG_Vertex, 0.0, 1.0);
	
	// Passing The Texture Coordinate Of Texture Unit 0 To The Fragment Shader
	texture_coordinate = RPG_TexCoord;
	v_color = RPG_Color;
	gl_FrontColor = gl_Color;
}""")

		self.Vertex.Add('textV',
"""
#version 130
in vec2 RPG_Vertex;
in vec2 RPG_TexCoord;
in vec2 RPG_TexCoord2;
uniform mat4 RPG_ModelViewProjectionMatrix;
out vec2 texCoord;
out vec2 texCoord2;
void main(void)
{
	texCoord = vec2(RPG_TexCoord);
	texCoord2 = vec2(RPG_TexCoord2);
	gl_Position = RPG_ModelViewProjectionMatrix * vec4(RPG_Vertex, 0.0, 1.0);
}""")

		self.Fragment.Add('defaultF',
"""
#version 110
varying vec4 v_color;
varying vec2 texture_coordinate; 
uniform sampler2D baseTexture; 

void MixChannel(inout float channel, float modifier, float alpha, float gray)
{
	if (modifier < 1.0)
		channel = mix(gray * modifier, channel, alpha);
	else if (modifier > 1.0)
		channel += (modifier - 1.0) * alpha;
}

vec3 MixRGBValue(vec3 rgbColor, vec4 value)
{
	float gray;
	
	gray = (rgbColor.r + rgbColor.g + rgbColor.b) / 3.0;

	MixChannel(rgbColor.r, value.r, value.a, gray);
	MixChannel(rgbColor.g, value.g, value.a, gray);
	MixChannel(rgbColor.b, value.b, value.a, gray);
	return rgbColor;
}

const vec4 STANDARD = vec4(1.0, 1.0, 1.0, 1.0);

void main() 
{
	vec4 result;
	result = texture2D(baseTexture, texture_coordinate) * v_color;
	if (v_color != STANDARD)
		result = vec4(MixRGBValue(result.rgb, v_color), result.a);
	gl_FragColor = result;
}""")

		self.Fragment.Add('tint',
"""
#version 140
varying vec2 texture_coordinate; 
varying vec4 v_color;
uniform sampler2D baseTexture;
uniform vec4 rgbValues;

vec3 ProcessShifts(vec3 rgbColor);

void main(void)
{
	vec4 lColor = texture2D(baseTexture, texture_coordinate);
	gl_FragColor = vec4(ProcessShifts(lColor.rgb), lColor.a * v_color.a);
}""")

		self.Fragment.Add('textF',
"""
#version 110
uniform sampler2D texAlpha;
uniform sampler2D texRGB;
varying vec2 texCoord;
varying vec2 texCoord2;
void main()
{
	float alpha = texture2D(texAlpha, texCoord).a;
	vec3 rgb = texture2D(texRGB, texCoord2).rgb;
	gl_FragColor = vec4(rgb, alpha);
}""")

		self.Fragment.Add('textShadow',
"""
#version 130
in vec2 texCoord;
uniform float strength;
uniform sampler2D texAlpha;
float alpha;
void main(void)
{
	alpha = texture2D(texAlpha, texCoord).a;
	if (alpha < 0.1)
		discard;
	gl_FragColor = vec4(0, 0, 0, alpha * strength);
}""")

		self.Fragment.Add('textBlit',
"""
#version 110
uniform sampler2D texAlpha;
float alpha;
void main()
{
	alpha = texture2D(texAlpha, gl_TexCoord[0].st).a;
	gl_FragColor = vec4(0, 0, 0, alpha);
}""")

		self.Fragment.Add('flash',
"""
#version 130
varying vec2 texture_coordinate;
uniform sampler2D baseTexture;
uniform vec4 flashColor;

void main(void)
{
	vec4 lColor = texture2D(baseTexture, texture_coordinate);
	vec3 mixColor = mix(lColor.rgb, flashColor.rgb, flashColor.a);
	gl_FragColor = vec4(mixColor, lColor.a);
}""")

		self.Fragment.Add('noAlpha',
"""
#version 110
varying vec2 texture_coordinate;
uniform sampler2D baseTexture;
varying vec4 v_color;

void MixChannel(inout float channel, float modifier, float alpha, float gray)
{
	if (modifier < 1.0)
		channel = mix(gray * modifier, channel, alpha);
	else if (modifier > 1.0)
		channel += (modifier - 1.0) * alpha;
}

vec3 MixRGBValue(vec3 rgbColor, vec4 value)
{
	float gray;
	
	gray = (rgbColor.r + rgbColor.g + rgbColor.b) / 3.0;

	MixChannel(rgbColor.r, value.r, value.a, gray);
	MixChannel(rgbColor.g, value.g, value.a, gray);
	MixChannel(rgbColor.b, value.b, value.a, gray);
	return rgbColor;
}

void main()
{
	vec3 base = MixRGBValue(texture2D(baseTexture, texture_coordinate).rgb, v_color);
	gl_FragColor = vec4(base, 1.0);
}""")

		self.Fragment.Add('Ellipse',
"""
#version 110
uniform vec2 tl;
uniform vec2 br;
float x;
float y;
float x0, y0, a, b;
float dist;

float sqr(float value)
{
	return value * value;
}

void main()
{
	x = gl_TexCoord[0].s;
	y = gl_TexCoord[0].t;

	x0 =(tl.x + br.x) / 2.0;
	y0 =(tl.y + br.y) / 2.0;
	a = (tl.x - br.x) / 2.0;
	b = (tl.y - br.y) / 2.0;
	dist = sqr((x-x0)/a)+sqr((y-y0)/b);
	if (abs(1.0 - dist) > 0.5)
		discard;

	gl_FragColor = vec4(1, 1, 1, 1);
}""")

		self.Fragment.Add('MaskF',
"""
#version 110
uniform sampler2D before;
uniform sampler2D after;
uniform sampler2D mask;
varying vec2 texture_coordinate; 

void main()
{
	vec3 maskValue = texture2D(mask, texture_coordinate).rgb;
	
	float alpha = maskValue.r; //(maskValue.r + maskValue.g + maskValue.b) / 3.0;
	vec4 beforeValue = texture2D(before, texture_coordinate);
	vec4 afterValue = texture2D(after, texture_coordinate);
	gl_FragColor = mix(beforeValue, afterValue, alpha);
}""")

		self.Fragment.Add('mosaic',
"""
#version 140
varying vec4 v_color;
varying vec2 texture_coordinate;
uniform sampler2D baseTexture;
uniform float blockSize;

void main()
{
	float blockStartX = (floor(texture_coordinate.x / blockSize) * blockSize) + (blockSize / 2);
	float blockStartY = (floor(texture_coordinate.y / blockSize) * blockSize) + (blockSize / 2);
	gl_FragColor = texture2D(baseTexture, vec2(blockStartX, blockStartY));
}""")

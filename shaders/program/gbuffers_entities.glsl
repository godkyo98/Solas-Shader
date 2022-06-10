//Settings//
#include "/lib/common.glsl"

#define GBUFFERS_ENTITIES

#ifdef FSH

//Varyings//
in float mat;

in vec2 texCoord, lmCoord;
in vec3 sunVec, upVec, eastVec, normal;
in vec4 color;

//Uniforms//
uniform int entityId;

uniform float nightVision;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;

uniform vec3 cameraPosition;

uniform sampler2D texture;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform vec4 entityColor;

//Common Variables//
float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

//Includes//
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/dimensionColor.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/lighting/forwardLighting.glsl"

#ifdef INTEGRATED_EMISSION
#include "/lib/lighting/integratedEmissionEntities.glsl"
#endif

#if defined SSPT || defined INTEGRATED_SPECULAR
#include "/lib/util/encode.glsl"
#endif

//Program//
void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;
	vec3 newNormal = normal;
	vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));

	float lightningBolt = float(entityId == 0);

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	vec3 viewPos = ToNDC(screenPos);
	vec3 worldPos = ToWorld(viewPos);

	albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

	float emissive = float(entityColor.a > 0.05) * 0.125 + lightningBolt;

	if (lightningBolt > 0.5) {
		albedo.rgb = vec3(1.0);
		albedo.rgb *= albedo.rgb * albedo.rgb;
		albedo.a = 1.0;
	} else {
		#ifdef INTEGRATED_EMISSION
		getIntegratedEmission(emissive, lightmap, albedo);
		#endif

		GetLighting(albedo.rgb, viewPos, worldPos, newNormal, lightmap, emissive, 0.0);
	}
	
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = albedo;

	#if defined WATER_REFLECTION || defined INTEGRATED_SPECULAR
	/* DRAWBUFFERS:05 */
	gl_FragData[1] = albedo;
	#endif

	#ifdef ENTITY_OUTLINE
	 /* DRAWBUFFERS:052 */
	gl_FragData[2].b = 1.0;
	#endif

	#if defined SSPT || defined INTEGRATED_SPECULAR
	/* DRAWBUFFERS:0526 */
	gl_FragData[3] = vec4(EncodeNormal(normal), 0.0, emissive);
	#endif
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out float mat;
out vec2 texCoord, lmCoord;
out vec3 sunVec, upVec, eastVec, normal;
out vec4 color;

//Uniforms
#if defined OVERWORLD || defined END
uniform float timeAngle;
#endif

uniform mat4 gbufferModelView;

//Attributes//
#ifdef INTEGRATED_EMISSION
uniform int entityId;
#endif

//Includes//
#ifdef INTEGRATED_EMISSION
#include "/lib/lighting/integratedEmissionEntities.glsl"
#endif

void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	//Normal
	normal = normalize(gl_NormalMatrix * gl_Normal);

	//Sun & Other vectors
    #if defined OVERWORLD
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
    #elif defined END
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
    sunVec = normalize((gbufferModelView * vec4(vec3(0.0, sunRotationData * 2000.0), 1.0)).xyz);
    #endif
	
	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

	//Materials
	mat = 0.0;

	#ifdef INTEGRATED_EMISSION
	getIntegratedEmissionEntities(mat);
	#endif

	//Color & Position
	color = gl_Color;

	gl_Position = ftransform();
}

#endif
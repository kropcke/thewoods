// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

// Toony Colors Pro+Mobile 2
// (c) 2014-2018 Jean Moreno

Shader "Toony Colors Pro 2/User/Test_Shader_Lightening"
{
	Properties
	{
	[TCP2HeaderHelp(BASE, Base Properties)]
		//TOONY COLORS
		_Color ("Color", Color) = (1,1,1,1)
		_HColor ("Highlight Color", Color) = (0.785,0.785,0.785,1.0)
		_SColor ("Shadow Color", Color) = (0.195,0.195,0.195,1.0)
		_HighlightMultiplier ("Highlight Multiplier", Range(0,4)) = 1
		_ShadowMultiplier ("Shadow Multiplier", Range(0,4)) = 1

		//DIFFUSE
		_MainTex ("Main Texture", 2D) = "white" {}
	[TCP2Separator]

		//TOONY COLORS RAMP
		[TCP2Header(RAMP SETTINGS)]

		_RampThreshold ("Ramp Threshold", Range(0,1)) = 0.5
		_RampSmooth ("Ramp Smoothing", Range(0.001,1)) = 0.1
	[TCP2Separator]

	[TCP2HeaderHelp(EMISSION, Emission)]
		[NoScaleOffset] _EmissionMap ("Emission (RGB)", 2D) = "black" {}
		[HDR] _EmissionColor ("Emission Color", Color) = (1,1,1,1.0)
	[TCP2Separator]

	[TCP2HeaderHelp(NORMAL MAPPING, Normal Bump Map)]
		//BUMP
		_BumpMap ("Normal map (RGB)", 2D) = "bump" {}
	[TCP2Separator]

	[TCP2HeaderHelp(SPECULAR, Specular)]
		//SPECULAR
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Smoothness ("Smoothness", Float) = 0.2
	[TCP2Separator]

	[TCP2HeaderHelp(TRANSPARENCY)]
		//Blending
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendTCP2 ("Blending Source", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlendTCP2 ("Blending Dest", Float) = 10
	[TCP2Separator]

	[TCP2HeaderHelp(MISC)]
		_NoTileNoiseTex ("Non-repeat tiling Noise", 2D) = "white" {}
	[TCP2Separator]


		//Avoid compile error if the properties are ending with a drawer
		[HideInInspector] __dummy__ ("unused", Float) = 0
	}

	SubShader
	{

		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		Blend [_SrcBlendTCP2] [_DstBlendTCP2]

		CGPROGRAM

		#pragma surface surf ToonyColorsCustom keepalpha exclude_path:deferred exclude_path:prepass
		#pragma target 3.0

		//================================================================
		// VARIABLES

		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _NoTileNoiseTex;
		float4 _NoTileNoiseTex_TexelSize;
		half4 _EmissionColor;
		sampler2D _EmissionMap;
		sampler2D _BumpMap;
		fixed _Smoothness;

		#define UV_MAINTEX uv_MainTex

		struct Input
		{
			half2 uv_MainTex;
			half2 uv_BumpMap;
		};

		//================================================================
		// CUSTOM LIGHTING

		//Lighting-related variables
		fixed4 _HColor;
		fixed4 _SColor;
		fixed _HighlightMultiplier;
		fixed _ShadowMultiplier;
		half _RampThreshold;
		half _RampSmooth;

		// Instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		//Custom SurfaceOutput
		struct SurfaceOutputCustom
		{
			half atten;
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			half Specular;
			fixed Gloss;
			fixed Alpha;
		};

		inline half4 LightingToonyColorsCustom (inout SurfaceOutputCustom s, half3 viewDir, UnityGI gi)
		{
		#define IN_NORMAL s.Normal
	
			half3 lightDir = gi.light.dir;
		#if defined(UNITY_PASS_FORWARDBASE)
			half3 lightColor = _LightColor0.rgb;
			half atten = s.atten;
		#else
			half3 lightColor = gi.light.color.rgb;
			half atten = 1;
		#endif

			IN_NORMAL = normalize(IN_NORMAL);
			fixed ndl = max(0, dot(IN_NORMAL, lightDir));
			#define NDL ndl

			#define		RAMP_THRESHOLD	_RampThreshold
			#define		RAMP_SMOOTH		_RampSmooth

			fixed3 ramp = smoothstep(RAMP_THRESHOLD - RAMP_SMOOTH*0.5, RAMP_THRESHOLD + RAMP_SMOOTH*0.5, NDL);
		#if !(POINT) && !(SPOT)
			ramp *= atten;
		#endif
		#if !defined(UNITY_PASS_FORWARDBASE)
			_SColor = fixed4(0,0,0,1);
		#endif
			_SColor = lerp(_HColor, _SColor, _SColor.a * _ShadowMultiplier);	//Shadows intensity through alpha
			ramp = lerp(_SColor.rgb, _HColor.rgb * _HighlightMultiplier, ramp);
			//Blinn-Phong Specular (legacy)
			half3 h = normalize(lightDir + viewDir);
			float ndh = max(0, dot (IN_NORMAL, h));
			float spec = pow(ndh, s.Specular*128.0) * s.Gloss * 2.0;
			spec *= atten;
			fixed4 c;
			c.rgb = s.Albedo * lightColor.rgb * ramp;
		#if (POINT || SPOT)
			c.rgb *= atten;
		#endif

			#define SPEC_COLOR	_SpecColor.rgb
			c.rgb += lightColor.rgb * SPEC_COLOR * spec;
			c.a = s.Alpha;

		#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
			c.rgb += s.Albedo * gi.indirect.diffuse;
		#endif

		#if defined(UNITY_PASS_FORWARDADD)
			//multiply RGB with alpha for additive lights for proper transparency behavior
			c.rgb *= c.a;
		#endif
			return c;
		}

		void LightingToonyColorsCustom_GI(inout SurfaceOutputCustom s, UnityGIInput data, inout UnityGI gi)
		{
			gi = UnityGlobalIllumination(data, 1.0, IN_NORMAL);

			s.atten = data.atten;	//transfer attenuation to lighting function
			gi.light.color = _LightColor0.rgb;	//remove attenuation
		}

		//================================================================
		// SURFACE FUNCTION

	// No Tiling texture fetch function
	// (c) 2017 Inigo Quilez - MIT License
	// Source: http://www.iquilezles.org/www/articles/texturerepetition/texturerepetition.htm
	float4 tex2DnoTile( sampler2D samp, in float2 uv )
	{
		// sample variation pattern    
		float k = tex2D(_NoTileNoiseTex, (1/_NoTileNoiseTex_TexelSize.zw)*uv).a; // cheap (cache friendly) lookup    

		// compute index    
		float index = k*8.0;
		float i = floor(index);
		float f = frac(index);

		// offsets for the different virtual patterns    
		float2 offa = sin(float2(3.0,7.0)*(i+0.0)); // can replace with any other hash    
		float2 offb = sin(float2(3.0,7.0)*(i+1.0)); // can replace with any other hash    

		// compute derivatives for mip-mapping    
		float2 dx = ddx(uv);
		float2 dy = ddy(uv);

		// sample the two closest virtual patterns    
		float4 cola = tex2Dgrad(samp, uv + offa, dx, dy);
		float4 colb = tex2Dgrad(samp, uv + offb, dx, dy);

		// interpolate between the two virtual patterns    
		return lerp(cola, colb, smoothstep(0.2,0.8,f-0.1*dot(cola-colb, 1)));
	}

		void surf(Input IN, inout SurfaceOutputCustom o)
		{
			fixed4 mainTex = tex2DnoTile(_MainTex, IN.UV_MAINTEX);
			o.Albedo = mainTex.rgb * _Color.rgb;
			o.Alpha = mainTex.a * _Color.a;

			//Specular
			o.Gloss = 1;
			o.Specular = _Smoothness;

			//Normal map
			half4 normalMap = tex2D(_BumpMap, IN.uv_BumpMap.xy);
			o.Normal = UnpackNormal(normalMap);

			//Emission
			half3 emissiveColor = half3(1,1,1);
			emissiveColor *= mainTex.rgb * mainTex.a;
			emissiveColor *= tex2D(_EmissionMap, IN.UV_MAINTEX);
			emissiveColor *= _EmissionColor.rgb * _EmissionColor.a;
			o.Emission += emissiveColor;
		}

		ENDCG
	}

	Fallback "Diffuse"
	CustomEditor "TCP2_MaterialInspector_SG"
}

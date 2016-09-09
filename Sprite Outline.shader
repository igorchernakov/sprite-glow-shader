Shader "Custom/Sprite Outline"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		_GlowColor ("Glow Tint", Color) = (1,1,1,1)
		_Spread ("Spread", Range(0, 0.1)) = 0.01
		_Blur ("Blur", Range(0, 5)) = 4
		[Toggle(USE_DIAGONAL_BLUR)] _UseDiagonalBlur ("Use Diagonal Blur (2x Slower)", Float) = 0
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}
		
		Cull Off
		Lighting Off
		ZWrite Off
		ZTest [unity_GUIZTestMode]

		Pass
		{
		Blend SrcAlpha One
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ USE_DIAGONAL_BLUR

			#include "UnityCG.cginc"

			struct appdata_t
			{
				float4 vertex   : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				half2 texcoord  : TEXCOORD0;
			};
			
			fixed4 _GlowColor;
			fixed _Spread;
			fixed _Blur;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.vertex = mul(UNITY_MATRIX_MVP, IN.vertex);
				OUT.texcoord = IN.texcoord;
				
				#ifdef UNITY_HALF_TEXEL_OFFSET
				OUT.vertex.xy += (_ScreenParams.zw-1.0)*float2(-1,1);
				#endif

				return OUT;
			}

			sampler2D _MainTex;

			fixed4 frag(v2f IN) : SV_Target
			{
				#define BLURV(weight, v, x, y) tex2Dlod(_MainTex, fixed4(IN.texcoord + half2(x * v, y * v), 0, _Blur)).a * weight

				#define BLUR(x, y) \
					sum += BLURV(0.05, -4.0, x, y); \
					sum += BLURV(0.09, -3.0, x, y); \
					sum += BLURV(0.12, -2.0, x, y); \
					sum += BLURV(0.15, -1.0, x, y); \
					sum += BLURV(0.18,  0.0, x, y); \
					sum += BLURV(0.15, +1.0, x, y); \
					sum += BLURV(0.12, +2.0, x, y); \
					sum += BLURV(0.09, +3.0, x, y); \
					sum += BLURV(0.05, +4.0, x, y);

                half sum = 0;

                #ifdef USE_DIAGONAL_BLUR
                BLUR(_Spread * 0.75, _Spread * 0.75)
                BLUR(_Spread * 0.75, -_Spread * 0.75)
                #endif
                BLUR(_Spread, 0)
                BLUR(0, _Spread)

				return half4(_GlowColor.rgb, sum * _GlowColor.a);
			}
		ENDCG
		}

		Pass
		{
		Blend SrcAlpha OneMinusSrcAlpha
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata_t
			{
				float4 vertex   : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				half2 texcoord  : TEXCOORD0;
			};
			
			v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.vertex = mul(UNITY_MATRIX_MVP, IN.vertex);
				OUT.texcoord = IN.texcoord;
				
				#ifdef UNITY_HALF_TEXEL_OFFSET
				OUT.vertex.xy += (_ScreenParams.zw-1.0)*float2(-1,1);
				#endif

				return OUT;
			}

			fixed4 _Color;
			sampler2D _MainTex;

			fixed4 frag(v2f IN) : SV_Target
			{
				return tex2D(_MainTex, IN.texcoord) * _Color;
			}
		ENDCG
		}
	}
}

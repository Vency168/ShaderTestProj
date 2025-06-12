Shader "Custom/NewSurfaceShader"
{
    Properties
    {  
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Tint ("Tint", Color) = (1,1,1,1)       
        _Smoothness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Debug("Debug", Range(0,3)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
      Pass
      {
        Tags{"LightMode"="ForwardBase"}
        CGPROGRAM
       
        #pragma vertex vert
        #pragma fragment frag
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        float4 _Tint;
        float4 _MainTex_ST;
        float _Metallic;
        float _Smoothness;
        float _Debug;

        struct a2v
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float2 uv : TEXCOORD0;
        };

        struct v2f{
            float4 pos : SV_POSITION;
            float3 worldNormal : TEXCOORD0;
            float3 worldPos : TEXCOORD1;
            float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
                }

                fixed4 frag(v2f i): SV_Target{
                    float a = (1-_Smoothness);
                    float N = normalize(i.worldNormal);
                    float V = normalize(_WorldSpaceCameraPos-i.worldPos);
                    float L = normalize(_WorldSpaceLightPos0);

                    float k = (a+1)*(a+1)/8;
                    float G1NV = dot(N,V)/(dot(N,V)*(1-k)+k);
                    float G1NL = dot(N,L)/(dot(N,L)*(1-k)+k);
                    float G = G1NV*G1NL;

                    float h = normalize(L+V);
                    float3 D = a*a/pow(dot(N,h)*dot(N,h)*(a-1)*(a-1)+1,2);

                    float F0 = 0.04;
                    float3 F = F0+(1-F0)*pow(1-dot(V,h),5);                    

                    float kD = (1-F0)*(1-_Metallic);
                    float3 diffuse = kD/UNITY_PI;
                    float3 spec = (D*F*G)/(4*dot(N,L)*dot(N,V));

                    float3 outCol;
                    if(_Debug == 1)  outCol = D;
                    else if(_Debug == 2) outCol=F;
                    else if(_Debug == 3) outCol = G;
                    else outCol =diffuse+spec;

                    return fixed4(outCol,1.0);
                    }
                 ENDCG
      }
    }
    FallBack "Diffuse"
}

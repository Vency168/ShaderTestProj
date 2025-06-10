Shader "Custom/myshader003"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _RampTex ("Albedo (RGB)", 2D) = "white" {}
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0,256)) = 20
    }
    SubShader
    {
      Pass{
          Tags{"LightMode"="ForwardBase"}

        CGPROGRAM
        
        #pragma vertex vert
        #pragma fragment frag
        #include "Lighting.cginc"

        fixed4 _Color;
        sampler2D _RampTex;
        float4 _RampTex_ST;
        fixed4 _Specular;
        float _Gloss;

        struct a2v{
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 texcoord : TEXCOORD0;
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
            o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
            o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);//宏展开为v.texcoord.xy*_RampTex.xy+_RampTex_ST.zw
            return o;
            }

        fixed4 frag(v2f i): SV_Target{
            fixed3 worldNormal = normalize(i.worldNormal);
            fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

            fixed halfLambert = 0.5 * dot(worldNormal,worldLightDir)+0.5;
            fixed3 diffuseColor = tex2D(_RampTex,fixed2(halfLambert,halfLambert)).rgb *_Color.rgb;
            //在Ramp贴图上采样,把半Lambert值映射到某个颜色
            //半Lambert：0.5N·L+0.5, 将其线性映射到【0，1】构造更平滑的阴影过渡
            fixed3 diffuse = _LightColor0.rgb*diffuseColor;

            fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
            fixed3 halfDir = normalize(worldLightDir + viewDir);
            fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);
            //max保证值大于等于0，dot计算法线与半角向量余弦，半角向量是把光线向量和视线方向相加归一化得到的向量记作H
            return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
      }
        
    }
    FallBack "Diffuse"
}

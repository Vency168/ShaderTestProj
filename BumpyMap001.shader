﻿Shader "Custom/myshader002"
{
    //切线空间下计算
    Properties{
        _Color("Color Tint", Color)=(1,1,1,1)
        _MainTex("Main Tex", 2D) = "white"{}
        _BumpMap("Normal Map",2D) = "bump"{}
        _BumpScale("Bump Scale", Float) = 1.0
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0,256))=20
        }

    SubShader
    {
        Pass{
            Tags{"LightMode"="ForwardBase"}//前向渲染基光通道，自动获得主光源方向/颜色等

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 lightDir :TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;                
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                //计算切线空间基向量
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;//cross(N,T),得到Binormal再乘切线w分量修正方向

                float3x3 rotation = float3x3(worldTangent,worldBinormal,worldNormal);//构建TBN矩阵（列向量顺序）

                float3 worldLightDir = UnityWorldSpaceLightDir(v.vertex);
                float3 worldViewDir = UnityWorldSpaceViewDir(v.vertex);

                //TANGENT_SPACE_ROTATION;???????
                o.lightDir = mul(rotation, WorldSpaceLightDir(v.vertex));
                o.viewDir = mul(rotation, WorldSpaceViewDir(v.vertex));

                return o;
                }

                fixed4 frag(v2f i):SV_Target{
                    //计算切线方向光照向量
                    fixed3 tangentLightDir = normalize(i.lightDir);
                    fixed3 tangentViewDir = normalize(i.viewDir);

                    fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);
                    fixed3 tangentNormal = UnpackNormal(packedNormal);               
                    
                    tangentNormal.xy *= _BumpScale;
                    tangentNormal.z = sqrt(1.0-saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                    fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,tangentLightDir));
                    fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal,halfDir)),_Gloss);
                     
                    fixed3 finalColor = ambient + diffuse + specular;
                    return fixed4(finalColor.x, finalColor.y, finalColor.z, 1.0);
                    }                             
                 ENDCG
            }
       
    }
    FallBack "Specular"
}
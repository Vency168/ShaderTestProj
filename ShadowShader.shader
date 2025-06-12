

Shader "Custom/ShadowShader"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("Specular",Color)=(1,1,1,1)//高光颜色
        _Glosss("Gloss",Range(8.0,256))=20//高光锐度
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
      Pass{
            Tags{"LightMode"="ForwardBase"}
            
        CGPROGRAM
        
        #pragma multi_compile_fwdbase

        #pragma vertex vert
        #pragma fragment frag
        #include "AutoLight.cginc"
        #include "Lighting.cginc"

        fixed4 _Diffuse;
        fixed4 _Specular;
        float _Gloss;

        struct a2v
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
        };

        struct v2f{
            float4 pos : SV_POSITION;
            float3 worldNormal : TEXCOORD0;
            float3 worldPos : TEXCOORD1;
            float4 _ShadowCoord : TEXCOORD2;
            };

        v2f vert(a2v v){
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            o.worldNormal = UnityObjectToWorldNormal(v.normal);

            o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

            TRANSFER_SHADOW(o);

            return o;
            }

        fixed4 frag(v2f i):SV_Target{
            fixed3 worldNormal = normalize(i.worldNormal);
            fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

            fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLightDir));

            fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
            fixed3 halfDir = normalize(worldLightDir + viewDir);
            fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);

            fixed atten = 1.0;

            fixed shadow = SHADOW_ATTENUATION(i);

            return fixed4(ambient+(diffuse+specular)*atten*shadow,1.0);
            }
            /*
            Iambient=unity_ambient
            Idiffuse = dot(dot(IL,Kd),max(0,dot(N,L))
            Ispecular = dot(dot(IL,Ks),pow((max(0,dot(N,H)),a))
            */
            ENDCG        
      }
        pass
        {
            Tags{"LightMode"="ForwardAdd"}
            //只叠加光源，不考虑阴影

            Blend One One

            CGPROGRAM

            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include"AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                };

            struct v2f{
                float4 position : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                };

                v2f vert(a2v v){
                    v2f o;
                    o.position = UnityObjectToClipPos(v.vertex);

                    o.worldNormal = UnityObjectToWorldNormal(v.normal);

                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                    return o;
                    }
                    fixed4 frag(v2f i):SV_Target{
                        fixed3 worldNormal = normalize(i.worldNormal);
                        #ifdef USING_DIRECTIONAL_LIGHT
                        fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                        #else
                        fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                        #endif
                        fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLightDir));

                        fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                        fixed3 halfDir = normalize(worldLightDir + viewDir);
                        fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                        #ifdef USING_DIRECTIONAL_LIGHT//光向量不随位置衰减
                        fixed atten = 1.0;
                        #else 
                        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos,1)).xyz;
                        fixed atten = tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
                        //变换光的裁剪空间，做贴图采样
                        #endif

                        return fixed4((diffuse + specular)*atten, 1.0);
                        }
                        ENDCG
        }
    }
    FallBack "Specular"
}

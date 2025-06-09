Shader "Custom/myshader002"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)//材质的色彩调节Tint,在片元着色器中将与贴图颜色相乘，得到最终基色
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5//对应Blinn-Phong 模型中的高光锐度指数（s),specular=(max(0,N点乘H))^s，s越大高光越小越集中
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Pass{
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM
            //指定顶点着色器和片元着色器函数
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;//与Properties相对应固定四分量颜色
            sampler2D _MainTex;//主贴图采样器
            float4 _MainTex_ST;//贴图的Tiling/Offset,_ST.xy=缩放,_ST.zw=偏移
            fixed4 _Specular;//高光颜色
            float _Gloss;//高光指数

            struct a2v {
                float4 vertex : POSITION;//模型空间顶点
                float4 normal : NORMAL;//法线xyz
                float4 texcoord : TEXCOORD0;//UV
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldNormal :TEXCOORD0;
                float3 worldPos :TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);//模型空间到裁剪空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);//法线变换：模型空间法线到世界空间法线，对法线的逆转置也叫归一化
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//顶点世界坐标
                o.uv = v.texcoord.xy * _MainTex_ST.xy+_MainTex_ST.zw;//UV缩放和偏移

                return o;
                }
                //归一化方向
                fixed4 frag(v2f i): SV_Target{
                    fixed3 worldNormal = normalize(i.worldNormal);
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                    fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//场景环境光颜色
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal,worldLightDir));

                    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                    fixed3 halfDir = normalize(worldLightDir + viewDir);//半角向量H=normalize(L+V)
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);
                    //N点乘L：表面法线与光线方向的点积，控制漫反射强度。pow(...,s):用指数控制高光衰减速度，s即_Gloss

                    return fixed4(ambient + diffuse +specular, 1.0);
                    }
                 ENDCG
            }
       
    }
    FallBack "Specular"
}

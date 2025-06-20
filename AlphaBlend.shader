﻿Shader "Custom/TransparencyShaderTest"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _AlphaScale("Alpha Scale",Range(0,1))=1//全部采用原本颜色
    }
    SubShader
    {
        Tags {"Queue"="AlphaTest""IgnoreProjector"="True""RenderType"="TransparentCutout"}
        /*将subshader排入透明队列，保证在不写深度，读取其他不透明物体之后执行
          不受投影器影响
        */
        Pass 
        {
          Tags{"LightMode"="ForwardBase"}//只接受主光源

          Zwrite off//关闭深度写入，保证不影响不阻挡后面的物体
          Blend SrcAlpha OneMinusSrcAlpha//Alpha混合，实现透明

          CGPROGRAM
          
          #pragma vertex vert
          #pragma fragment frag

          #include"Lighting.cginc"

          fixed4 _Color;
          sampler2D _MainTex;
          float4 _MainTex_ST;
          /*Tiling在X/Y方向上重复贴图的次数，通常对应一个Vector(UScale,VScale),同理offset
          _MainTex_ST = float4(Tiling.x, Tiling.y,
                               Offset.x, Offset.y);即.xy缩放与.zw偏移
          */
          fixed _AlphaScale;

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

              o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);//等价于0.uv = v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw

              return o;
              }
             
              fixed4 frag(v2f i):SV_Target{
                  fixed3 worldNormal = normalize(i.worldNormal);
                  fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                  fixed4 texColor = tex2D(_MainTex,i.uv);
               
                  //clip(texColor.a-_Cutoff);

                  fixed3 albedo = texColor.rgb*_Color.rgb;
                  fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;//环境光ambient = ambientColor x albedo
                  fixed3 diffuse = _LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLightDir));//diffuse=lightColor x albedo x max(0,N点乘L)
                  return fixed4(ambient+diffuse,texColor.a*_AlphaScale);//输出RGB+透明度（透明度alpha = texColor.a*_AlphaScale）
                  }
          
          ENDCG

        }
    } 
          FallBack"Transparent/Cutout/VertexLit"
}

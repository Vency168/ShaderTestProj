Shader "Custom/myshader002"
{
    //世界空间下计算凹凸映射
    Properties{
        _Color("Color Tint", Color)=(1,1,1,1)//RGBA漫反射基色albedo tint，colot tint在片元着色器中与贴图颜色相乘，控制整体色调
        _MainTex("Main Tex", 2D) = "white"{}//sampler2D类型（采样读取二维纹理），法线贴图（切线空间法线）
        _BumpMap("Normal Map",2D) = "bump"{}//存放RGB编码的法线，解包到【-1，1】空间
        _BumpScale("Bump Scale", Float) = 1.0//法线贴图缩放系数，解包后乘此值控制凹凸强度
        _Specular("Specular", Color) = (1,1,1,1)//镜面反射颜色，Blinn-Phong模型中高光部分的颜色
        _Gloss("Gloss", Range(8.0,256))=20//光滑度指数，spec = (N点乘H)^s
        }

    SubShader
    {
        Pass{
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members worldPos)
#pragma exclude_renderers d3d11

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            //引入Unity内置光照函数和宏

            fixed4 _Color;//材质基色
            sampler2D _MainTex;//Albedo贴图
            float4 _MainTex_ST;//_ST.xy = scale, _ST.zw = offset
            sampler2D _BumpMap;//法线贴图
            float4 _BumpMap_ST;//法线贴图的UV变换
            float _BumpScale;//法线强度
            fixed4 _Specular;
            float _Gloss;

            struct a2v {
                float4 vertex : POSITION; //模型空间顶点坐标
                float4 normal : NORMAL; // 模型空间法线，使用.xyz
                float4 tangent : TANGENT;//模型空间切线＋副法线token"w"
                float4 texcoord : TEXCOORD0;//原始UV
            };

            struct v2f {
                float4 pos : SV_POSITION;//裁剪空间坐标
                float4 uv : TEXCOORD0;//xy = Albedo UV, zw = Normal UV
                float4 TtoW0 : TEXCOORD1;//切线空间到世界空间矩阵第一列 + worldPos.x
                float4 TtoW1 : TEXCOORD2;//切线空间到世界空间矩阵第二列 + worldPos.y
                float4 TtoW2 : TEXCOORD3;//切线空间到世界空间矩阵第三列 + worldPos.z

                //顶点着色器
            v2f vert(a2v v){
                v2f o;

                //模型空间顶点到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

              //计算UV变换
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;                
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                //构建切线空间TBN变换矩阵               
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;   
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                return o;
                }
                //片元着色器
                fixed4 frag(v2f i):SV_Target{
                    float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                    fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));//计算世界空间光照和视线方向（平行光时的常量方向）
                    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));//相机位置
                   
                    fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));//将【0.1】映射到【-1，1】               
                    
                    bump.xy *= _BumpScale;//调整法线xy分量
                    bump.z = sqrt(1.0-saturate(dot(bump.xy, bump.xy)));//保证长度为1
                    bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));//把切线空间法线转换为世界空间

                    fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;//漫反射&环境光，Albedo颜色=贴图RGB*材质Tint
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(bump,lightDir));//Lambert漫反射：N点乘L>=0时生效
                    fixed3 halfDir = normalize(lightDir + viewDir);
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump,halfDir)),_Gloss);//spec=光强*镜面颜色*（N点乘H)^shine
                     
                    //合成最终颜色
                    fixed3 finalColor = ambient + diffuse + specular;
                    return fixed4(finalColor.x, finalColor.y, finalColor.z, 1.0);//构造fixed4，四个参数是r g b a
                    }                             
                 ENDCG
            }
       
    }
    FallBack "Specular"
}
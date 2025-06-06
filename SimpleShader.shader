Shader "Custom/SimpleShader"
{
    Properties
    {
        _Color("Color Tint",Color)=(1,1,1,1)
    }
    //顶点到片元的颜色传递
    SubShader
    {
        Pass{
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            uniform fixed4 _Color;
            //结构体a2v 顶点输入结构，包含位置，法线，UV
            //结构体v2f 顶点输出以及片元输入结构，传递位置和颜色

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                };

            struct v2f{
                float4 pos : SV_POSITION;
                fixed3 color :COLOR0;
                };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = v.normal * 0.5 + fixed3(0.5,0.5,0.5);//可视化法线方法 可显示其RGB值
                return o;
                }

                fixed4 frag(v2f i): SV_Target{
                    fixed3 c = i.color;
                    c *=_Color.rgb;//从顶点着色器传输过来的c是法线转颜色值，*_Color的RGB实现着色调节
                    return fixed4(c,1.0);//不透明
                    }
               ENDCG
            }
        
    }
}

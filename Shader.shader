Shader "Custom/NewSurfaceShader"
{
    Properties
    {
       
    }
    //使用CG/HLSL自定义基础shader
    SubShader
    {
        Pass { //渲染通道
            CGPROGRAM //GPU编译器

            #pragma vertex vert //vertex shader
            #pragma fragment frag //fragment shader/pixel shader

            float4 vert(float4 v:POSITION):SV_POSITION{ //将来自于模型数据中的顶点位置转换为裁剪空间中的顶点坐标
                return UnityObjectToClipPos(v);
                }           
            //output给片元着色器
            fixed4 frag():SV_Target{ //fixed4是一种低精度4分量颜色类型
                return fixed4(0.5,1.0,1.0,1.0);
                }  
            ENDCG
        }
    }
    FallBack "Diffuse"
}

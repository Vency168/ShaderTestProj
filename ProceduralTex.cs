using UnityEngine;
using System.Collections;
using System.Collections.Generic;

[ExecuteInEditMode]//在编辑器模式下运行
public class ProceduralTextureGeneration : MonoBehaviour
{

    public Material material = null;//声明一个材质，此材质将使用该脚本中生成的程序纹理
    //声明4个纹理属性：纹理大小，纹理背景颜色，圆点颜色，模糊因子
    #region Material properties
    [SerializeField, ]
    private int m_textureWidth = 512;
    public int textureWidth
    {
        get
        {
            return m_textureWidth;
        }
        set
        {
            m_textureWidth = value;
            _UpdateMaterial();
        }
    }

    [SerializeField, ]
    private Color m_backgroundColor = Color.white;
    public Color backgroundColor
    {
        get
        {
            return m_backgroundColor;
        }
        set
        {
            m_backgroundColor = value;
            _UpdateMaterial();
        }
    }

    [SerializeField, ]
    private Color m_circleColor = Color.yellow;
    public Color circleColor
    {
        get
        {
            return m_circleColor;
        }
        set
        {
            m_circleColor = value;
            _UpdateMaterial();
        }
    }

    [SerializeField,]
    private float m_blurFactor = 2.0f;
    public float blurFactor
    {
        get
        {
            return m_blurFactor;
        }
        set
        {
            m_blurFactor = value;
            _UpdateMaterial();
        }
    }
    #endregion

    private Texture2D m_generatedTexture = null;

   
    void Start()
    {
        if (material == null)
        {
            Renderer renderer = gameObject.GetComponent<Renderer>();
            if (renderer == null)
            {
                Debug.LogWarning("Cannot find a renderer.");
                return;
            }

            material = renderer.sharedMaterial;
        }

        _UpdateMaterial();
    }
    //若material变量为空，则尝试从使用该脚本所在的物体上得到相应的材质，调用_UpdateMaterial函数为其生成程序纹理
    private void _UpdateMaterial()
    {
        if (material != null)
        {
            m_generatedTexture = _GenerateProceduralTexture();
            material.SetTexture("_MainTex", m_generatedTexture);
        }
    }

    private Color _MixColor(Color color0, Color color1, float mixFactor)
    {
        Color mixColor = Color.white;
        mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
        mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
        mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
        mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);
        return mixColor;
    }

    private Texture2D _GenerateProceduralTexture()//初始化一张二维纹理
    {
        Texture2D proceduralTexture = new Texture2D(textureWidth, textureWidth);

        //定义圆与圆之间的间距
        float circleInterval = textureWidth / 4.0f;
        //定义圆的半径
        float radius = textureWidth / 10.0f;
        //定义模糊系数
        float edgeBlur = 1.0f / blurFactor;

        for (int w = 0; w < textureWidth; w++)
        {
            for (int h = 0; h < textureWidth; h++)
            {
                //使用背景颜色进行初始化
                Color pixel = backgroundColor;

                
                for (int i = 0; i < 3; i++)
                {
                    for (int j = 0; j < 3; j++)
                    {
                        
                        Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));

                       
                        float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;

                       
                        Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f), Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));

                        
                        pixel = _MixColor(pixel, color, color.a);
                    }
                }

                proceduralTexture.SetPixel(w, h, pixel);
            }
        }

        proceduralTexture.Apply();//强制把像素值写入纹理

        return proceduralTexture;
    }
}

Shader "Shader/Liquid"
{
    Properties
    {
        _TopColor ("Top Color", Color) = (0, 1, 1, 1)
        _MidColor ("Middle Color", Color) = (1, 0, 1, 1)
        _BaseColor ("Base Color", Color) = (1, 1, 0, 1)

        [Space(10)]
        _LiquidAmount("Liquid Amount", Range(-2, 2)) = 0
        _MidAmount("Middle Amount", Range(0, 0.2)) = 0
        
        [Space(10)]
        _WaveSpeedX("Wave Speed X", Range(0, 10)) = 1
        _WaveFrequencyX("Wave Frequency X", Range(0, 10)) = 1
        _WaveAmplitudeX("Wave Amplitude X", Range(0, 1)) = 0.1
        
        [Space(10)]
        _WaveSpeedZ("Wave Speed Z", Range(0, 10)) = 1
        _WaveFrequencyZ("Wave Frequency Z", Range(0, 10)) = 1
        _WaveAmplitudeZ("Wave Amplitude Z", Range(0, 1)) = 0.1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque"}
        // Buffer de profundidad https://docs.unity3d.com/Manual/SL-ZWrite.html
        ZWrite On 
        // Se desactiva el culling, se dibujan todas las caras https://docs.unity3d.com/2020.1/Documentation/Manual/SL-CullAndDepth.html
        Cull Off
        // Activa el alpha https://docs.unity3d.com/Manual/SL-AlphaToMask.html
        AlphaToMask On
        // cuán exigente es computacionalmente https://docs.unity3d.com/Manual/SL-ShaderLOD.html
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata  // vertex input
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f  // vertex output
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float liquidEdge : TEXCOORD1; // Variable para la matriz de transformacion
            };

            // Variables de conexion
            float4 _TopColor; 
            float4 _MidColor;
            float4 _BaseColor;
            float _LiquidAmount;
            float _MidAmount;

            float _WaveSpeedX;
            float _WaveFrequencyX;
            float _WaveAmplitudeX;

            float _WaveSpeedZ;
            float _WaveFrequencyZ;
            float _WaveAmplitudeZ;

            v2f vert (appdata v) // vertex shader
            {
                v2f o; 
                // Transforma un punto del espacio de objetos al espacio de la cámara
                o.vertex = UnityObjectToClipPos(v.vertex);
                // Porque es transparente y no tiene textura
                o.uv = v.uv;

                // Calculo la onda del liquido en los ejes X y Z:
                // Calculo la onda del liquido a traves del tiempo
                float time = _Time.y;
                // Calcula la onda en X y en Z, la funcion "sin" es para calcular la onda sinoudal
                float waveOffsetX = sin(time * _WaveSpeedX + v.vertex.x * _WaveFrequencyX) * _WaveAmplitudeX;
                float waveOffsetZ = cos(time * _WaveSpeedZ + v.vertex.z * _WaveFrequencyZ) * _WaveAmplitudeZ;    
    
                // Uso la matriz de transformacion "unity_ObjectToWorld" para simular el movimiento de liquido
                // Esta matriz se usa para mantener estatica la rotacion del liquido en el espacio
                // Multiplico por el input de vertices xyz, para que la posicion del world space siga la posicion del objeto
                float3 worldPosition = mul(unity_ObjectToWorld, v.vertex.xyz);
                o.liquidEdge = worldPosition.y + _LiquidAmount + waveOffsetX + waveOffsetZ;                
                return o;
            }

            // VFACE retorna V si estamos renderizando la cara frontal del objeto o F si es la trasera
            // Con esto devuelvo un color u otro segun la cara del objeto
            fixed4 frag(v2f i, fixed facing : VFACE) : SV_Target  // fragment shader
            {
                // midEdge define la division de color entre el base color y el mid color
                // smoothstep genera el efecto smooth entre un color y el otro
                // (0.5 - _MidAmount) para que el cambio de color sea de arriba a abajo
                fixed4 midEdge = step(i.liquidEdge, 0.5) - smoothstep(i.liquidEdge, 0.6, (0.5 - _MidAmount));
                fixed4 midEdgeColor = midEdge * _MidColor; // Da el color
    
                // le restamos midEgde para mejorar la diferencia entre el base color y el mid color
                fixed4 base = step(i.liquidEdge, 0.5) - midEdge;
                fixed4 baseColor = base * _BaseColor; // Da el color

                fixed4 renderBase = baseColor + midEdgeColor;
                fixed4 renderTop = _TopColor * (midEdge + base);
    
                // Retornamos dependiendo la cara que se esta renderizando
                return facing > 0 ? renderBase : renderTop;
            }
            ENDCG
        }
    }
}

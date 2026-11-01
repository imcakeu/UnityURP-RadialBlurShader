// Credits: Nithink @ G2 Studios, 
// "【Unity URP】軽くて綺麗なラディアルブラーを作ろう！" - https://note.com/g2studios/n/n7b7a0c068a1c?hl=en
// Changes made:
// - Added a Radius Mask to prevent blurring the center of the screen, adjustable.
// - Updated Samples to use a Quality setting instead of a Vector. 
//   Updated loop to just use division instead of precomputing reciprocals, which doesn't save that much time and allows us to tweak samples more easily.
// - Added comments to make this easily understandable and modifiable.

Shader "Custom/RadialBlur"
{
    Properties
    {
        [KeywordEnum(Low, Medium, High)] _Quality("Quality", Float) = 1
        
        _Intensity("Intensity", Range(0, 1)) = 0.5
        _RadialCenter("Radial Center", Vector) = (0.5, 0.5, 0, 0)
        
        _ClearRadius("Clear Radius", Range(0, 1)) = 0.25
        _Softness("Transition Softness", Range(0.01, 1)) = 0.4
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        ZWrite Off ZTest Always Cull off

        Pass
        {
            Name "Radial Blur"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_local_fragment _QUALITY_LOW _QUALITY_MEDIUM _QUALITY_HIGH     
            
            #if defined(_QUALITY_LOW)
                #define SAMPLE_COUNT 3
            #elif defined(_QUALITY_HIGH)
                #define SAMPLE_COUNT 9
            #else
                #define SAMPLE_COUNT 6
            #endif

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            float _Intensity;
            float2 _RadialCenter;
            float _ClearRadius;
            float _Softness;

            // Half4 = Half precision RGBA
            half4 Frag (Varyings input) : SV_Target
            {
                // Unity XR: each eye gets computed separately
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half4 output = 0;
                
                // We want the radial center to be the origin of positions, and not a corner of the screen
                // This means that every pixel's position is a direction and distance from center, not a coordinate, hence UV
                float2 uv = input.texcoord - _RadialCenter;
                
                // Dither effect reduces smearing in low sample counts
                half dither = InterleavedGradientNoise(input.positionCS.xy, 0);
                
                // Distance from center, corrected so the clear zone is a circle and not ellipse
                float2 aspectUV = float2(uv.x * _ScreenParams.x / _ScreenParams.y, uv.y);
                float dist = length(aspectUV);
                
                // 0 inside clear radius, ramps smoothly to 1 over softness range
                float mask = smoothstep(_ClearRadius, _ClearRadius + _Softness, dist);
                
                // Tells the compiler to unroll the loop which is faster on GPU
                [unroll]
                for (int i = 0; i < SAMPLE_COUNT; i++)
                {
                    // Apply dithering to the i-th and i+1-th images
                    float t = ((float)i + dither) / SAMPLE_COUNT;
                    
                    // Sample across a line whose length is determined by the intensity of the effect
                    // Go from current point towards radial center
                    float2 sampleUV = uv * (1.0 - _Intensity * mask * t) + _RadialCenter;
                    
                    // Output holds sum of all samples
                    output += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, sampleUV);
                }

                // Average the outputs after all samples are computed
                return output / SAMPLE_COUNT;
            }
            ENDHLSL
        }
    }
}

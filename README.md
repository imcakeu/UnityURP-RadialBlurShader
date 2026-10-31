# URP Radial Blur (Full Screen Pass)

A lightweight radial (zoom) blur for Unity URP.
Based on Nithink's work @ G2 Studios, source: https://note.com/g2studios/n/n7b7a0c068a1c?hl=en 


## Features

- Radial blur that scales with distance from a center point
- Optional Radius Mask with soft transition (to avoid blurring middle of the screen) 
- Dithering effect to help with smearing at low sample counts
- Quality settings (Low/Medium/High) to change sample count
- Uses Full Screen Pass Renderer Feature in your URP Renderer

## Requirements

- Unity 6 (tested on 6.4)
- Universal Render Pipeline

## Setup

1. Copy the shader file into your project
2. Create a material that uses `Custom/FullScreenHLSLPass` or use the pre-packaged one
3. Select your URP Renderer asset, click **Add Renderer Feature**, and add **Full Screen Pass Renderer Feature**
4. Assign the material to the feature
5. Set **Injection Point** to **After/Before Rendering Post Processing** but avoid **Before Rendering Transparents**
6. Set **Requirements** to **None** or **Color**

## Properties

| Property | What it does |
|---|---|
| Quality | Low / Medium / High. Sets the sample count at compile time (3 / 6 / 9) |
| Intensity | How far the blur reaches. Scales intensely, a slight edge blur is ~0.05, and an intense full-screen blur is like ~0.5 |
| Radial Center | Center of the effect in UV space, (0.5, 0.5) is the middle of screen. Only XY values in the vector are used |
| Clear Radius | Radius of the masked zone, measured in screen-height units. Ex.: 0.25 is a circle with a radius of 1/4 of screen height. |
| Transition Softness | Width of the ramp from sharp to full blur. Small values give a visible ring, larger values blend in gradually. Should stay above 0. |

## Setting values from a script

Changing the Intensity from code is just a float on the material:

```csharp
static readonly int IntensityId = Shader.PropertyToID("_Intensity");

blurMaterial.SetFloat(IntensityId, flow * maxIntensity);
```

Quality is a keyword enum that switches automatically in the material inspector, but from a script you have to set the keywords yourself:

```csharp
public enum BlurQuality { Low, Medium, High }

static readonly string[] QualityKeywords = { "_QUALITY_LOW", "_QUALITY_MEDIUM", "_QUALITY_HIGH" };

public void SetQuality(BlurQuality quality)
{
    for (int i = 0; i < QualityKeywords.Length; i++)
    {
        if (i == (int)quality) blurMaterial.EnableKeyword(QualityKeywords[i]);
        else blurMaterial.DisableKeyword(QualityKeywords[i]);
    }
    blurMaterial.SetFloat("_Quality", (int)quality);
}
```

Note that the material is a shared asset, so values set from a script in the editor persist in the asset after you exit play mode. Reset them in `OnDisable` if that bothers you.
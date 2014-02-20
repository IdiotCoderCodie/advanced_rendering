//--------------------------------------------------------------------------------------
// File: BasicHLSL11.fx
//
// The effect file for the BasicHLSL sample.  
// 
// Copyright (c) Microsoft Corporation. All rights reserved.
//--------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------
// Global variables
//--------------------------------------------------------------------------------------
float4 g_MaterialAmbientColor;      // Material's ambient color
float4 g_MaterialDiffuseColor;      // Material's diffuse color
int g_nNumLights;

float3 g_LightDir[3];               // Light's direction in world space
float4 g_LightDiffuse[3];           // Light's diffuse color
float4 g_LightAmbient;              // Light's ambient color

Texture2D g_MeshTexture;            // Color texture for mesh

float    g_fTime;                   // App's time in seconds
float4x4 g_mWorld;                  // World matrix for object
float4x4 g_mView;
float4x4 g_mProjection;
float4x4 g_mWorldViewProjection;    // World * View * Projection matrix

float g_mHeadRotation; 

float g_PulsatingHeadScale; 

//--------------------------------------------------------------------------------------
// DepthStates
//--------------------------------------------------------------------------------------
DepthStencilState EnableDepth
{
    DepthEnable = TRUE;
    DepthWriteMask = ALL;
    DepthFunc = LESS_EQUAL;
};

//--------------------------------------------------------------------------------------
// Texture samplers
//--------------------------------------------------------------------------------------
SamplerState MeshTextureSampler
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};


//--------------------------------------------------------------------------------------
// Vertex shader output structure
//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
    float4 Position   : SV_POSITION; // vertex position 
    float4 Diffuse    : COLOR0;      // vertex diffuse color (note that COLOR0 is clamped from 0..1)
    float2 TextureUV  : TEXCOORD0;   // vertex texture coords 
};




//--------------------------------------------------------------------------------------
// This shader computes standard transform and lighting
//--------------------------------------------------------------------------------------
VS_OUTPUT RenderSceneVS( float4 vPos : POSITION,
                         float3 vNormal : NORMAL,
                         float2 vTexCoord0 : TEXCOORD,
                         uniform int nNumLights,
                         uniform bool bTexture,
                         uniform bool bAnimate )
{
    VS_OUTPUT Output;
    float3 vNormalWorldSpace;
  
	float4 vAnimatedPos = vPos;

	float cosTime = cos(g_fTime);
	float sinTime = sin(g_fTime);

	//vNormal = normalize(vNormal);

    // Animation the vertex based on time and the vertex's object space position
   // if( bAnimate )
		//vAnimatedPos += float4(vNormal, 0) * (sin(g_fTime+5.5)+0.5)*5;
    
	float3 headRotation;
	headRotation.z = smoothstep(160, 165, vAnimatedPos.z) * sinTime;
	float4 testPosition = vPos;

	vAnimatedPos = vPos + float4(0.0, -35.0, 0.0, 0.0);

	headRotation.z = 0.0f;
	float4x4 mHeadRotationZ =
	{
		cos(headRotation.z), -sin(headRotation.z), 0.0, 0.0,
		sin(headRotation.z), cos(headRotation.z), 0.0, 0.0,
		0.0, 0.0, 1.0, 0.0,
		0.0, 0.0, 0.0, 1.0
	};

	headRotation.y = smoothstep(160, 180, vAnimatedPos.z) * g_mHeadRotation;
	//headRotationY = 0.0f; // Temporarily resetting to zero for no rotation.
	float4x4 mHeadRotationY =
	{
		cos(headRotation.y), 0.0, sin(headRotation.y), 0.0,
		0.0, 1.0, 0.0, 0.0,
		-sin(headRotation.y), 0.0, cos(headRotation.y), 0.0,
		0.0, 0.0, 0.0, 1.0
	};


	headRotation.x = smoothstep(160, 165, vAnimatedPos.z) * cosTime;
	headRotation.x = 0.0f;
	float4x4 mHeadRotationX =
	{
		1.0, 0.0, 0.0, 0.0,
		0.0, cos(headRotation.x), -sin(headRotation.x), 0.0,
		0.0, sin(headRotation.x), cos(headRotation.x), 0.0,
		0.0, 0.0, 0.0, 1.0
	};

	float4x4 mFinalHeadRotation = mul(mHeadRotationX, mul(mHeadRotationY, mHeadRotationZ));
	float4x4 newWorldMat = mul(g_mWorld, mFinalHeadRotation);

	Output.Position = mul(vAnimatedPos, mul(newWorldMat, mul(g_mView, g_mProjection)));

    // Transform the position from object space to homogeneous projection space
    //Output.Position = mul(vAnimatedPos, g_mWorldViewProjection);
    
    // Transform the normal from object space to world space    
	vNormalWorldSpace = normalize(mul(vNormal, (float3x3)newWorldMat)); // normal (world space)
    
    // Compute simple directional lighting equation
    float3 vTotalLightDiffuse = float3(0,0,0);
    for(int i=0; i<nNumLights; i++ )
        vTotalLightDiffuse += g_LightDiffuse[i] * max(0,dot(vNormalWorldSpace, normalize(g_LightDir[i])));
        
    Output.Diffuse.rgb = g_MaterialDiffuseColor * vTotalLightDiffuse + 
                         g_MaterialAmbientColor * g_LightAmbient;   
    Output.Diffuse.a = 1.0f; 
    
    // Just copy the texture coordinate through
    if( bTexture ) 
        Output.TextureUV = vTexCoord0; 
    else
        Output.TextureUV = 0; 
    
    return Output;    
}


//--------------------------------------------------------------------------------------
// Shader for Lab 1, Exercise 1.
//--------------------------------------------------------------------------------------
VS_OUTPUT VS_Ex1(float4 vPos : POSITION,
	float3 vNormal : NORMAL,
	float2 vTexCoord0 : TEXCOORD,
	uniform int nNumLights,
	uniform bool bTexture,
	uniform bool bAnimate)
{
	VS_OUTPUT Output;
	float3 vNormalWorldSpace;

	float4 vAnimatedPos = vPos;

	//vNormal = normalize(vNormal);
	float cosTime = cos(g_fTime);
	float sinTime = sin(g_fTime);
	// Animation the vertex based on time and the vertex's object space position
	vAnimatedPos += 10.0f * float4(vNormal, 0);
	if (bAnimate)
	{
		float magnitude = g_PulsatingHeadScale;

		float scale = magnitude * smoothstep(160, 165, vAnimatedPos.z) * (sin(g_fTime) + 1.0);
		vAnimatedPos += scale * float4(vNormal, 0);
		//vAnimatedPos += float4(vNormal, 0) * (sin(g_fTime + 5.5) + 0.5) * 5;
	}

	//float4x4 newWorldMat = g_mWorld;
	float headRotationZ = smoothstep(150, 165, vAnimatedPos.z) * sinTime;
    
	float4x4 mHeadRotationZ = 
	{ 
		cos(headRotationZ), -sin(headRotationZ), 0.0			, 0.0,
		sin(headRotationZ), cos(headRotationZ) , 0.0			, 0.0,
		0.0				 , 0.0				   , 1.0			, 0.0,
		0.0				 , 0.0				   , 0.0			, 1.0 
	};

	float headRotationY = smoothstep(160, 165, vAnimatedPos.z) * sinTime;
	headRotationY = 0.0f; // Temporarily resetting to zero for no rotation.
	float4x4 mHeadRotationY =
	{
		cos(headRotationY)	, 0.0			, sin(headRotationY), 0.0,
		0.0					, 1.0			, 0.0				, 0.0,
		-sin(headRotationY) , 0.0			, cos(headRotationY), 0.0,
		0.0					, 0.0			, 0.0				, 1.0
	};
	

	float headRotationX = smoothstep(160, 165, vAnimatedPos.z) * cosTime;
	float4x4 mHeadRotationX = 
	{
		1.0, 0.0				, 0.0					, 0.0,
		0.0, cos(headRotationX)	, -sin(headRotationX)	, 0.0,
		0.0, sin(headRotationX)	, cos(headRotationX)	, 0.0,
		0.0, 0.0				, 0.0					, 1.0
	};

	float4x4 mFinalHeadRotation = mul(mHeadRotationY, mul(mHeadRotationX, mHeadRotationZ));
	float4x4 newWorldMat = mul(g_mWorld, mFinalHeadRotation);

    Output.Position = mul(vAnimatedPos, mul(newWorldMat, mul(g_mView, g_mProjection)));
	// Transform the position from object space to homogeneous projection space
	//Output.Position = mul(vAnimatedPos, g_mWorldViewProjection);

	// Transform the normal from object space to world space    
	vNormalWorldSpace = normalize(mul(vNormal, (float3x3)g_mWorld)); // normal (world space)

	// Compute simple directional lighting equation
	float3 vTotalLightDiffuse = float3(0, 0, 0);
	for (int i = 0; i<nNumLights; i++)
		vTotalLightDiffuse += g_LightDiffuse[i] * max(0, dot(vNormalWorldSpace, normalize(g_LightDir[i])));

	Output.Diffuse.rgb = g_MaterialDiffuseColor * vTotalLightDiffuse +
		g_MaterialAmbientColor * g_LightAmbient;
	Output.Diffuse.a = 1.0f;

	// Just copy the texture coordinate through
	if (bTexture)
		Output.TextureUV = vTexCoord0;
	else
		Output.TextureUV = 0;

	return Output;
}


//--------------------------------------------------------------------------------------
// Pixel shader output structure
//--------------------------------------------------------------------------------------
struct PS_OUTPUT
{
    float4 RGBColor : SV_Target;  // Pixel color
};


//--------------------------------------------------------------------------------------
// This shader outputs the pixel's color by modulating the texture's
//       color with diffuse material color
//--------------------------------------------------------------------------------------
PS_OUTPUT RenderScenePS( VS_OUTPUT In,
                         uniform bool bTexture ) 
{ 
    PS_OUTPUT Output;

    // Lookup mesh texture and modulate it with diffuse
    if( bTexture )
        Output.RGBColor = g_MeshTexture.Sample(MeshTextureSampler, In.TextureUV) * In.Diffuse;
    else
        Output.RGBColor = In.Diffuse;

    return Output;
}

PS_OUTPUT PS_Ex1(VS_OUTPUT In,
	uniform bool bTexture)
{
	PS_OUTPUT Output;

	// Lookup mesh texture and modulate it with diffuse
	if (bTexture)
		Output.RGBColor = g_MeshTexture.Sample(MeshTextureSampler, In.TextureUV) * In.Diffuse;
	else
		Output.RGBColor = In.Diffuse;

	Output.RGBColor.x = 1.0;

	return Output;
}

PS_OUTPUT AuraTest(VS_OUTPUT In,
	uniform bool bTexture)
{
	PS_OUTPUT Output;

	// Lookup mesh texture and modulate it with diffuse
	if (bTexture)
		Output.RGBColor = g_MeshTexture.Sample(MeshTextureSampler, In.TextureUV) * In.Diffuse;
	else
		Output.RGBColor = In.Diffuse;

	Output.RGBColor = float4(1.0, 0.0, 0.0, 0.2);

	return Output;
}


BlendState AlphaBlendingOn
{
	BlendEnable[0] = TRUE;
	DestBlend = ONE;
	SrcBlend = SRC_ALPHA;
};

BlendState NoBlend
{
	BlendEnable[0] = FALSE;
};


//--------------------------------------------------------------------------------------
// Renders scene to render target using D3D11 Techniques
//--------------------------------------------------------------------------------------
technique11 RenderSceneWithTexture1Light
{
    pass P0
    {
		SetBlendState(NoBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
        SetVertexShader( CompileShader( vs_4_0_level_9_1, RenderSceneVS( 1, true, false ) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0_level_9_1, RenderScenePS( true ) ) );

        SetDepthStencilState( EnableDepth, 0 );
    }
	/*pass P1
	{
		SetBlendState(AlphaBlendingOn, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetVertexShader( CompileShader( vs_4_0_level_9_1, VS_Ex1( 1, true, true ) ) );
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0_level_9_1, AuraTest(true)));
		SetDepthStencilState(EnableDepth, 0);
	}*/
}


technique11 RenderSceneWithTexture2Light
{
    pass P0
    {   
		SetBlendState(NoBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
        SetVertexShader( CompileShader( vs_4_0_level_9_1, RenderSceneVS( 2, true, false ) ) );
        SetGeometryShader( NULL );
		SetPixelShader(CompileShader(ps_4_0_level_9_1, RenderScenePS(true)));
        
        SetDepthStencilState( EnableDepth, 0 );
    }
	//pass P1
	//{
	//	/*AlphaBlendEnable = true;
	//	SrcBlend = SrcAlpha;
	//	DestBlend = One;*/
	//	SetBlendState(AlphaBlendingOn, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);

	//	SetVertexShader(CompileShader(vs_4_0_level_9_1, VS_Ex1(2, true, true)));
	//	SetGeometryShader(NULL);
	//	SetPixelShader(CompileShader(ps_4_0_level_9_1, AuraTest(true)));
	//	SetDepthStencilState(EnableDepth, 0);
	//}
}

technique11 RenderSceneWithTexture3Light
{
    pass P0
    {      
		SetBlendState(NoBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
        SetVertexShader( CompileShader( vs_4_0_level_9_1, RenderSceneVS( 3, true, false ) ) );
        SetGeometryShader( NULL );
		SetPixelShader(CompileShader(ps_4_0_level_9_1, RenderScenePS(true)));

        SetDepthStencilState( EnableDepth, 0 );
    }
	/*pass P1
	{
		SetBlendState(AlphaBlendingOn, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetVertexShader(CompileShader(vs_4_0_level_9_1, VS_Ex1(3, true, true)));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0_level_9_1, AuraTest(true)));
		SetDepthStencilState(EnableDepth, 0);
	}*/
}

technique11 RenderSceneNoTexture
{
    pass P0
    {          
        SetVertexShader( CompileShader( vs_4_0_level_9_1, RenderSceneVS( 1, true, true ) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0_level_9_1, RenderScenePS( false ) ) );

        SetDepthStencilState( EnableDepth, 0 );
    }
	/*pass P1
	{
		SetBlendState(AlphaBlendingOn, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetVertexShader(CompileShader(vs_4_0_level_9_1, VS_Ex1(1, true, true)));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0_level_9_1, RenderScenePS(true)));
		SetDepthStencilState(EnableDepth, 0);
	}*/
}
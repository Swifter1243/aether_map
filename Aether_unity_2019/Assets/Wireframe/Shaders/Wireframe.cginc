
uniform float _WireThickness = 100;
uniform float _WireSmoothness = 3;
#if !NOTE
uniform float4 _Color = float4(0.0, 1.0, 0.0, 1.0);
#endif
uniform float4 _BaseColor = float4(0.0, 0.0, 0.0, 0.0);
uniform float _MaxTriSize = 25.0;
uniform float _Glow = 0.0;
uniform float _FadeDistance;

#if NOTE
UNITY_INSTANCING_BUFFER_START(Props)
UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
UNITY_DEFINE_INSTANCED_PROP(float4, _CutPlane)
UNITY_INSTANCING_BUFFER_END(Props)
#endif

struct appdata
{
    float4 vertex : POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2g
{
    float4 projectionSpaceVertex : SV_POSITION;
    float4 worldSpacePosition : TEXCOORD1;
    #if DEBRIS
    float3 localPos : TEXCOORD2;
    #endif
    UNITY_VERTEX_OUTPUT_STEREO
};

struct g2f
{
    float4 projectionSpaceVertex : SV_POSITION;
    float4 worldSpacePosition : TEXCOORD0;
    float4 dist : TEXCOORD1;
    float4 area : TEXCOORD2;
    #if DEBRIS
    float3 localPos : TEXCOORD3;
    #endif
    UNITY_VERTEX_OUTPUT_STEREO
};

v2g vert (appdata v)
{
    v2g o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(v2g, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    o.projectionSpaceVertex = UnityObjectToClipPos(v.vertex);
    o.worldSpacePosition = mul(unity_ObjectToWorld, v.vertex);
    #if DEBRIS
    o.localPos = v.vertex;;
    #endif
    return o;
}

[maxvertexcount(3)]
void geom(triangle v2g i[3], inout TriangleStream<g2f> triangleStream)
{
    float2 p0 = (i[0].projectionSpaceVertex.xy / i[0].projectionSpaceVertex.w);
    float2 p1 = (i[1].projectionSpaceVertex.xy / i[1].projectionSpaceVertex.w);
    float2 p2 = (i[2].projectionSpaceVertex.xy / i[2].projectionSpaceVertex.w);

    float2 edge0 = p2 - p1;
    float2 edge1 = p2 - p0;
    float2 edge2 = p1 - p0;

    float4 worldEdge0 = i[0].worldSpacePosition - i[1].worldSpacePosition;
    float4 worldEdge1 = i[1].worldSpacePosition - i[2].worldSpacePosition;
    float4 worldEdge2 = i[0].worldSpacePosition - i[2].worldSpacePosition;

    // To find the distance to the opposite edge, we take the
    // formula for finding the area of a triangle Area = Base/2 * Height,
    // and solve for the Height = (Area * 2)/Base.
    // We can get the area of a triangle by taking its cross product
    // divided by 2.  However we can avoid dividing our area/base by 2
    // since our cross product will already be double our area.
    float area = abs(edge1.x * edge2.y - edge1.y * edge2.x);
    float wireThickness = 800 - _WireThickness;

    #if NOTE && !DEBRIS
    float Cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
    wireThickness /= 1 - Cutout;
    #endif

    g2f o;

    o.area = float4(0, 0, 0, 0);
    o.area.x = max(length(worldEdge0), max(length(worldEdge1), length(worldEdge2)));

    o.worldSpacePosition = i[0].worldSpacePosition;
    o.projectionSpaceVertex = i[0].projectionSpaceVertex;
    o.dist.xyz = float3( (area / length(edge0)), 0.0, 0.0) * o.projectionSpaceVertex.w * wireThickness;
    o.dist.w = 1.0 / o.projectionSpaceVertex.w;
    #if DEBRIS
    o.localPos = i[0].localPos;
    #endif
    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o);
    triangleStream.Append(o);

    o.worldSpacePosition = i[1].worldSpacePosition;
    o.projectionSpaceVertex = i[1].projectionSpaceVertex;
    o.dist.xyz = float3(0.0, (area / length(edge1)), 0.0) * o.projectionSpaceVertex.w * wireThickness;
    o.dist.w = 1.0 / o.projectionSpaceVertex.w;
    #if DEBRIS
    o.localPos = i[1].localPos;
    #endif
    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[2], o);
    triangleStream.Append(o);

    o.worldSpacePosition = i[2].worldSpacePosition;
    o.projectionSpaceVertex = i[2].projectionSpaceVertex;
    o.dist.xyz = float3(0.0, 0.0, (area / length(edge2))) * o.projectionSpaceVertex.w * wireThickness;
    o.dist.w = 1.0 / o.projectionSpaceVertex.w;
    #if DEBRIS
    o.localPos = i[2].localPos;
    #endif
    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[2], o);
    triangleStream.Append(o);
}

fixed4 frag(g2f i) : SV_Target
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i); //Insert

    #if NOTE
    float4 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
    #else
    float4 Color = _Color;
    #endif

    #if NOTE && DEBRIS
    float Cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
    float4 CutPlane = UNITY_ACCESS_INSTANCED_PROP(Props, _CutPlane);
    float3 samplePoint = i.localPos + CutPlane.xyz * CutPlane.w;
    float planeDistance = dot(samplePoint, CutPlane.xyz) / length(CutPlane.xyz);
    float c = planeDistance - Cutout * 0.25;
    clip(c);
    #endif

    float minDistanceToEdge = min(i.dist[0], min(i.dist[1], i.dist[2])) * i.dist[3];

    float alpha = Luminance(Color.rgb) * _Glow;

    // Early out if we know we are not on a line segment.
    if(minDistanceToEdge > 0.9 || i.area.x > _MaxTriSize )
    {
        _WireSmoothness *= _WireSmoothness;
    }

    // Smooth our line out
    float t = exp2(_WireSmoothness * -1.0 * minDistanceToEdge * minDistanceToEdge);
    half4 finalColor = lerp(_BaseColor, Color, t);

    return float4(finalColor.rgb, alpha);
}

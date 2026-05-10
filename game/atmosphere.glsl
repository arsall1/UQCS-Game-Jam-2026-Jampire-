extern vec2 screenSize;

extern float planetRadius;
extern float atmosphereRadius;

extern vec3 sunPos;
extern float cameraZ;
extern float zoomFactor;

extern vec3 betaRayleigh;
extern vec3 betaMie;
extern float mieG;

extern float scaleHeight;
extern float intensity;
extern int steps;

extern float densityFalloff;
extern float edgePower;
extern float edgeStrength;

extern vec3 skyColor;


const int MAX_STEPS = 32;
const float PI = 3.1415926535;

extern vec2 cameraOffset;

vec3 getRayOrigin(vec2 fragCoord)
{
    vec2 centered = fragCoord - screenSize * 0.5 - cameraOffset;
    vec2 worldXY = centered / zoomFactor;

    return vec3(worldXY, cameraZ);
}

vec3 getRayDir()
{
    return vec3(0.0, 0.0, -1.0);
}


vec2 intersectSphere(vec3 ro, vec3 rd, float radius)
{
    float b = dot(ro, rd);
    float c = dot(ro, ro) - radius * radius;
    float h = b * b - c;

    if (h < 0.0) return vec2(-1.0);

    h = sqrt(h);
    return vec2(-b - h, -b + h);
}


float getDensity(vec3 p)
{
    float h = length(p) - planetRadius;

    if (h < 0.0)
        return 0.0;

    float t = clamp(h / atmosphereRadius, 0.0, 1.0);

    float expDensity =
        exp(-pow(h / scaleHeight, densityFalloff));

    float edgeFade =
        exp(-pow(t, edgePower) * edgeStrength);

    return expDensity * edgeFade;
}


float opticalDepth(vec3 p, vec3 dir)
{
    float result = 0.0;

    float stepSize =
        atmosphereRadius / float(steps);

    for (int i = 0; i < MAX_STEPS; i++)
    {
        if (i >= steps) break;

        vec3 samplePos =
            p + dir * stepSize * float(i);

        float h =
            length(samplePos) - planetRadius;

        if (h < 0.0)
            return 1e6;

        result +=
            getDensity(samplePos) * stepSize;
    }

    return result;
}


float phaseRayleigh(float mu)
{
    return 3.0 / (16.0 * PI) * (1.0 + mu * mu);
}

float phaseMie(float mu)
{
    float g = mieG;
    float g2 = g * g;

    return (1.0 - g2) /
        (4.0 * PI * pow(1.0 + g2 - 2.0 * g * mu, 1.5));
}


vec4 effect(vec4 color, Image tex, vec2 uv, vec2 fragCoord)
{
    vec3 ro = getRayOrigin(fragCoord);
    vec3 rd = getRayDir();

    if (length(ro.xy) < planetRadius)
        return vec4(0.0);

    vec2 planetHit =
        intersectSphere(ro, rd, planetRadius);

    float tStart = 0.0;
    float tEnd = 2000.0;

    if (planetHit.x > 0.0)
        tEnd = planetHit.x;

    float segment =
        (tEnd - tStart) / float(steps);

    vec3 sumRayleigh = vec3(0.0);
    vec3 sumMie = vec3(0.0);

    float opticalDepthView = 0.0;

    for (int i = 0; i < MAX_STEPS; i++)
    {
        if (i >= steps) break;

        float t =
            tStart + segment * (float(i) + 0.5);

        vec3 pos = ro + rd * t;

        float density = getDensity(pos);

        if (density <= 0.00001)
            continue;

        opticalDepthView += density * segment;

        vec3 sunDir = normalize(sunPos - pos);

        float opticalDepthLight = opticalDepth(pos, sunDir);

        vec3 transmittance = exp(-(betaRayleigh + betaMie) * (opticalDepthLight + opticalDepthView));

        float mu = dot(rd, sunDir);

        float rayleighPhase = phaseRayleigh(mu);
        float miePhase = phaseMie(mu);

        sumRayleigh += density * transmittance * rayleighPhase;

        sumMie += density * transmittance * miePhase;
    }

    vec3 colorOut = sumRayleigh * betaRayleigh + sumMie * betaMie;

    colorOut *= intensity;

    float brightness =
    clamp(0.213 * colorOut.r + 0.715 * colorOut.g + 0.072 * colorOut.b, 0.0, 1.0);

    vec3 finalColor = mix(skyColor, colorOut, brightness);

    return vec4(finalColor, 1.0);
}   
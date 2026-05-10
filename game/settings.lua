local settings = {

    GRID_W = 60,
    GRID_H = 12,
    TILE_SIZE = 32,

    ATLAS_SIZE = {6, 2},

    LIGHTSKY = {0.2, 0.3, 0.8},
    DARKSKY = {0.05, 0.025, 0.1},

    GRAVITY = 10;


    vignette = {
        RADIUS = 0.8,
        SOFTNESS = 0.5
    },

    atmosphereParams = {
        rayleighR = 0.006,
        rayleighG = 0.0160,
        rayleighB = 0.025,

        mie = 0.013,
        mieG = 0.30,

        scaleHeight = 100,
        intensity = 4000,
        steps = 10,

        densityFalloff = 0.6,
        edgePower = 1.5,
        edgeStrength = 1.5,

        sunSpeed = 0.2,
        sunTilt = 0,
        skyColor = {0.1, 0.05, 0.2},
    }
}


return settings

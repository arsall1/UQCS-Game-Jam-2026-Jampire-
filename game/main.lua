local settings = require 'settings'

local anim8 = require 'libraries/anim8'

local world = {}
local mapData = require 'mapData'

local collidableIDs = {1, 2, 3, 4, 5}
local bridgeID = 7

local collideableBlocks = {}




local camera = {
    x = 0,
    y = 0,
    zoom = 1,
    tilt = 0,
}

local Rmed, Rinner, Router

local sun = {
    x = 0,
    y = 0,
    z = 0,
    dist = 500,
    angle = 0,
    tilt = 0,
    scale = 3,
}


local player = {
    x = 24,
    y = 6,
    vx = 0,
    vy = 0,
    speed = -20,
    spriteSheet = love.graphics.newImage('images/jampireAnim.png'),
    state = 'idle',
    facing = 1,
    airborne = false,
    down = false
    
}
player.spriteSheet:setFilter('nearest', 'nearest')
player.grid = anim8.newGrid(32, 32, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())
player.anims = {}
player.anims['idle'] = anim8.newAnimation(player.grid('1-5', 1), 0.2)
player.anims['run'] = anim8.newAnimation(player.grid('1-4', 2), 0.1) 

function player:getScreenPos()
    local x = screenCenter[1]
    local y = screenCenter[2] + camera.y * settings.TILE_SIZE - camera.zoom * (Rinner + self.y * settings.TILE_SIZE)

    return {x, y}
end

function player:update(dt)
    self.anims[self.state]:update(dt)

    self.vx = 0


    self.state = 'idle'

    if love.keyboard.isDown("right") then
        self.state = 'run'
        self.vx = self.vx + 0.2 * (-self.speed - self.vx)
        self.facing = 1
    end

    if love.keyboard.isDown("left") then
        self.state = 'run'
        self.vx = self.vx + 0.2 * (self.speed - self.vx)
        self.facing = -1
    end

    if love.keyboard.isDown("up") and player.airborne == false then
        self.vy = 4
    end
    self.airborne = true


    
    if love.keyboard.isDown("down") then
        self.down = true
    end

    self.vy = self.vy - settings.GRAVITY * dt
    self.y = self.y + self.vy * dt
    self.x = self.x + self.vx * dt

    if self.x > settings.GRID_W then
        self.x = 0
    end
    if self.x < 0 then
        self.x = settings.GRID_W
    end

    self:checkCollision()
end

counter = 0

function player:checkCollision()

    for _, block in pairs(collideableBlocks) do

        

        local bx, by = block[1], block[2]

        if self.down and block[3] == bridgeID then
            goto continue
        end


        if self.x >= bx and self.x < bx + 1 then
            
            if block[3] ~= bridgeID then
                if self.vx >= 0 then
                    if self.y > by and self.y < by + 1 then
                        self.x = bx
                        self.vx = 0

                        goto continue
                    end

                elseif self.vx < 0 then
                    if self.y > by and self.y < by + 1 then
                        self.x = bx + 1
                        self.vx = 0

                        goto continue
                    end
                end
            end

            
            if self.vy < 0 then
                if self.y <= by + 2 and self.y > by then
                    self.y = by + 2
                    self.vy = 0
                    
                    self.airborne = false
                    
                end
            end

            
        end

        ::continue::
    end
end

function player:draw(pos)
    self.anims[self.state]:draw(self.spriteSheet, pos[1], pos[2], nil, camera.zoom * self.facing, camera.zoom, 16, 0)
end

function sun:getPos()
    local x = self.dist * math.cos(self.angle) * math.sin(self.tilt)
    local y = self.dist * math.cos(self.angle) * math.cos(self.tilt)
    local z = self.dist * math.sin(self.angle)

    return x, y, z
end

function sun:getScreenPos()
    local adjustedTilt = camera.tilt + self.tilt
    local x = self.dist * math.cos(self.angle) * math.sin(adjustedTilt)
    local y = self.dist * math.cos(self.angle) * math.cos(adjustedTilt)
    
    local px = screenCenter[1] + camera.zoom * x
    local py = screenCenter[2] - camera.y * settings.TILE_SIZE + camera.zoom * y
    return {px, py}
end

function sun:draw(pos)

    love.graphics.draw(self.image, pos[1], pos[2], 0, self.scale * camera.zoom, self.scale * camera.zoom)
end

function love.load()
    

    sun.image = love.graphics.newImage('images/sun.png')
    sun.image:setFilter("nearest", "nearest")

    coreImage = love.graphics.newImage('images/core.png')
    coreImage:setFilter("nearest", "nearest")

    love.window.setMode(0, 0, {
        fullscreen = true,
        fullscreentype = "desktop"
    })

    canvas = love.graphics.newCanvas()

    for j = 0, settings.GRID_H - 1 do
        world[j] = {}
    end

    for i = 0, settings.GRID_W * settings.GRID_H - 1 do
        local column = i % settings.GRID_W
        local row = settings.GRID_H - math.floor(i / settings.GRID_W) - 1

        local tile = mapData.layer2[i+1]
        
        if tile > 0 then
            table.insert(collideableBlocks, {column, row, tile})
        end

        world[row][column] = {
            mapData.layer1[i+1],
            mapData.layer2[i+1]
        }
    end

    screenCenter = {
        love.graphics.getWidth() * 0.5,
        love.graphics.getHeight() * 0.5
    }

    width, height = love.graphics.getDimensions()


    Rmed = 1.25 * (settings.GRID_W * settings.TILE_SIZE) / (2 * math.pi)
    Rinner = Rmed - (settings.GRID_H * settings.TILE_SIZE) * 0.5
    Router = Rmed + (settings.GRID_H * settings.TILE_SIZE) * 0.5

    sun.dist = Router + 500

    meshes = {
        layer1 = buildMesh(1),
        layer2 = buildMesh(2)
    }

    mappingShader = love.graphics.newShader('mapping_vertex.glsl', 'mapping_fragment.glsl')

    mappingShader:send("W", settings.GRID_W)
    mappingShader:send("H", settings.GRID_H)
    mappingShader:send("Rinner", Rinner)
    mappingShader:send("Router", Router)
    mappingShader:send("center", screenCenter)
    

    atlas = love.graphics.newImage("images/mapAtlas.png")
    atlas:setFilter("nearest", "nearest")

    mappingShader:send("atlas", atlas)
    mappingShader:send("atlasSize", settings.ATLAS_SIZE)


    vignetteShader = love.graphics.newShader('vignette.glsl')
    vignetteShader:send('radius', settings.vignette.RADIUS)
    vignetteShader:send('softness', settings.vignette.SOFTNESS)

    atmoShader = love.graphics.newShader('atmosphere.glsl')




    
end


function love.update(dt)
    sun.x, sun.y, sun.z = sun:getPos()

    sun.angle = sun.angle + 0.3 * dt
    sun.tilt = sun.tilt + 0.02 * dt

    local sunScreenPos = sun:getScreenPos()
    local sunCamDisp = {
        sunScreenPos[1] - screenCenter[1],
        sunScreenPos[2] + (screenCenter[2] + (camera.y * settings.TILE_SIZE))
    }
    local sunCamDist = (sunCamDisp[1]^2 + sunCamDisp[2]^2)^0.5

    camera.y = camera.y + 0.1 * (camera.zoom *( Rinner/settings.TILE_SIZE + player.y ) - camera.y)

    camera.tilt = 2 * math.pi * camera.x/settings.GRID_W
    camera.x = -45 + player.x

    camera.zoom = camera.zoom + (3 -  0.07 * (player.vx^2 + player.vy^2)^0.5 - camera.zoom) * 0.05

    player:update(dt)

    local skyBrightness = 0.5 * (1 + sun.z/sun.dist)
    local adjustedSkyColor = {}
    for i, v in ipairs(settings.atmosphereParams.skyColor) do
        table.insert(adjustedSkyColor, settings.DARKSKY[i] + skyBrightness* (v - settings.DARKSKY[i]))
    end

    atmoShader:send("screenSize", {
        love.graphics.getWidth(),
        love.graphics.getHeight()
    })

    atmoShader:send("planetRadius", 200)
    atmoShader:send("atmosphereRadius", Router+100)

    local angle = -camera.tilt

    local c = math.cos(angle)
    local s = math.sin(angle)

    local sx, sy, sz = sun.x, sun.y, sun.z

    local rx = sx * c - sy * s
    local ry = sx * s + sy * c

    atmoShader:send("sunPos", {rx, ry, sz})

    atmoShader:send("cameraZ", 0)
    atmoShader:send("zoomFactor", camera.zoom)

    atmoShader:send("betaRayleigh", {
        settings.atmosphereParams.rayleighR,
        settings.atmosphereParams.rayleighG,
        settings.atmosphereParams.rayleighB
    })

    atmoShader:send("betaMie", {
        settings.atmosphereParams.mie,
        settings.atmosphereParams.mie,
        settings.atmosphereParams.mie
    })

    atmoShader:send("mieG", settings.atmosphereParams.mieG)
    atmoShader:send("scaleHeight", settings.atmosphereParams.scaleHeight)
    atmoShader:send("intensity", settings.atmosphereParams.intensity)
    atmoShader:send("steps", math.floor(settings.atmosphereParams.steps))

    atmoShader:send("densityFalloff", settings.atmosphereParams.densityFalloff)
    atmoShader:send("edgePower", settings.atmosphereParams.edgePower)
    atmoShader:send("edgeStrength", settings.atmosphereParams.edgeStrength)

    atmoShader:send("skyColor", settings.DARKSKY)

    atmoShader:send("cameraOffset", {
        0,
        camera.y * settings.TILE_SIZE
    })
end




function love.draw()
    
    --camera.zoom = camera.zoom - 0.001

    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    

    local sunScreenPos = sun:getScreenPos()

    
    

    love.graphics.setShader(atmoShader)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setShader()

    if sun.z > 0 then
        sun:draw(sunScreenPos)
    end

    


    mappingShader:send("camera", {
        camera.x,
        camera.y * settings.TILE_SIZE
    })
    
    mappingShader:send("zoom", camera.zoom)

    local coreSize = 2.05 * Rinner
    local coreScale = camera.zoom * coreSize / coreImage:getWidth()
    local coreCenter = {
        screenCenter[1],
        screenCenter[2] + (camera.y * settings.TILE_SIZE)
    }
    love.graphics.draw(coreImage, coreCenter[1], coreCenter[2], -camera.tilt, coreScale, coreScale,
                    coreImage:getWidth()/2, coreImage:getHeight()/2)

    love.graphics.setShader(mappingShader)
    mappingShader:send("atlas", atlas)

    for i, mesh in pairs(meshes) do
        love.graphics.draw(mesh)
    end

    

    love.graphics.setShader()
    love.graphics.setCanvas()

    


    love.graphics.setShader(vignetteShader)
    vignetteShader:send('resolution', {love.graphics.getWidth(), love.graphics.getHeight()})

    love.graphics.draw(canvas)

    love.graphics.setShader()


    player:draw(player:getScreenPos())

    
    
end

function buildMesh(layer)
    local vertices = {}

    for j = 0, settings.GRID_H - 1 do
        for i = 0, settings.GRID_W - 1 do
            if world[j][i][layer] > 0 then

                local tile = world[j][i][layer] - 1
                local id = tile

                local x, y = i, j

                table.insert(vertices, {x,     y,     0,1, id,0,0,1})
                table.insert(vertices, {x + 1, y,     1,1, id,0,0,1})
                table.insert(vertices, {x + 1, y + 1, 1,0, id,0,0,1})

                table.insert(vertices, {x,     y,     0,1, id,0,0,1})
                table.insert(vertices, {x + 1, y + 1, 1,0, id,0,0,1})
                table.insert(vertices, {x,     y + 1, 0,0, id,0,0,1})
            end
        end
    end

    return love.graphics.newMesh({
        {"VertexPosition", "float", 2},
        {"VertexTexCoord", "float", 2},
        {"VertexColor", "float", 4},
    }, vertices, "triangles", "static")


    
end

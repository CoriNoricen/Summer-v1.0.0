sw,sh = 28, 35          -- Sprite width/height
local isPressed = false

function love.load()
    --Sets fullscreen
    love.window.setFullscreen(true, "desktop")

    wf = require 'Libraries/windfield'
    world = wf.newWorld(0, 0)
    world:addCollisionClass('player')
    world:addCollisionClass('obstacle')

    --Loads movement Variables
    require 'movement'

    -- loads camera
    camera = require 'Libraries/camera'
    cam = camera()

    -- loads sprite animation
    anim8 = require 'Libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- loads map
    sti = require 'Libraries/sti'
    gameMap = sti('Maps/Desert.lua')

    -- creates player and animations
    player = {}
    player.collider = world:newBSGRectangleCollider(x, y, 60, 60, 10)
    player.collider:setFixedRotation(true)
    player.collider:setCollisionClass('player')
    player.spriteSheet = love.graphics.newImage('sprites/Summer V2 (1).png')
    -- Width/Height of sprite, Width/Height of SpriteSheet
    player.grid = anim8.newGrid( sw, sh, player.spriteSheet:getWidth(), player.spriteSheet:getHeight() )

    player.animations = {}
    player.animations.down = anim8.newAnimation( player.grid('1-4', 1), 0.32 )
    player.animations.left = anim8.newAnimation( player.grid('1-4', 2), 0.32 )
    player.animations.up = anim8.newAnimation( player.grid('1-4', 3), 0.32 )
    player.animations.right = anim8.newAnimation( player.grid('1-4', 4), 0.32 )

    player.anim = player.animations.down

    local function object_collision(collider_1, collider_2, contact)
        if collider_1.collision_class == 'player' and collider_2.collision_class == 'obstacle' then
            love.event.quit('restart')
        end
    end
    
    player.collider:setPreSolve(object_collision)

    object = {}
    if gameMap.layers["Objects"] then
        for i, obj in pairs(gameMap.layers["Objects"].objects) do
            local collision = world:newBSGRectangleCollider(obj.x, obj.y, obj.width, obj.height, 0)
            collision:setType('static')
            collision:setCollisionClass('obstacle')
            table.insert(object, collision)
        end
    end
end

-- Lookup to get the heading value from a keycode
local keys = 
{
    left = 1,
    right = 2,
    up = 3,
    down = 4,
}

-- Lookup to get a directional vector from a heading value
local heading_vectors = 
{
    { -1,  0 },
    {  1,  0 },
    {  0, -1 },
    {  0,  1 },
}

function love.keypressed(key, _, isrepeat)
    isPressed = true
    if not isrepeat then
        -- When the player presses a new directional key, change the heading
        local dir = keys[key]
        if dir and dir ~= key_heading then
            key_heading = dir
        end
    end
end

function love.keyreleased(key, _)
    isPressed = false
    -- When the player releases the current heading key, reset
    local dir = keys[key]
    if dir and dir == key_heading then
        key_heading = 0
    end
end

function love.update(dt)
    -- animation
    local isMoving = false
    --moves character
    if key_heading == 2 and canTurn == true then
        isMoving = true
        player.anim = player.animations.right
        canTurn = false
    end

    if key_heading == 1 and canTurn == true then
        isMoving = true
        canTurn = false
        player.anim = player.animations.left
    end

    if key_heading == 4 and canTurn == true then
        isMoving = true
        canTurn = false
        player.anim = player.animations.down
    end

    if key_heading == 3 and canTurn == true then
        isMoving = true
        canTurn = false
        player.anim = player.animations.up
    end

    if x / w ~= tile_x or x % w ~= 0 then
        isMoving = true
        canTurn = false
        player.anim:update(dt)
        -- If the player's pixel position hasn't reached the tile position, keep moving
        local dest = tile_x * w
        local sign = (dest - x) / math.abs(dest - x)
        x = x + (sign * 1)

    elseif y / h ~= tile_y or y % h ~= 0 then
        isMoving = true
        canTurn = false
        player.anim:update(dt)
        -- If the player's pixel position hasn't reached the tile position, keep moving
        local dest = tile_y * h
        local sign = (dest - y) / math.abs(dest - y)
        y = y + (sign * 1)
    else -- No need to move, handle input
        if key_heading ~= 0 then -- Directional key is held down

            -- If we need to turn, turn and start the timer
            if key_heading ~= heading then
                heading = key_heading
                turn_timer = turn_wait
            end

            -- Decrement the turn timer
            turn_timer = turn_timer - dt

            -- If we're done waiting, warp the player to the next tile position
            local vec = heading_vectors[heading]
            
            if tile_x + vec[1] >= 0 and tile_y + vec[2] > 0 and turn_timer <= 0 then
                turn_timer = 0

                
                tile_x = tile_x + vec[1]
                tile_y = tile_y + vec[2]
            end
        end
    end




    -- Prevents Animation running when no key is pressed
    if isPressed == false and isMoving == false then
        canTurn = true
        player.anim:gotoFrame(1)
    end

    world:update(dt)
    player.collider:setX(x + 35)
    player.collider:setY(y + 35)


    player.anim:update(dt)

    -- moves camera
    cam:lookAt(x, y)

    -- stop camera going over map
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    -- left border
    if cam.x < w/2 then
        cam.x = w/2
    end

    -- top border
    if cam.y < h/2 then
        cam.y = h/2
    end

    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight

    -- right border
    if cam.x > (mapW - w/2) then
        cam.x = (mapW - w/2)
    end

    -- bottom border
    if cam.y >(mapH - h/2) then
        cam.y = (mapH - h/2)
    end
end

function love.draw()
    -- draws layers of map and player
    cam:attach(0, 0)
        gameMap:drawLayer(gameMap.layers["Path"])
        gameMap:drawLayer(gameMap.layers["Sand"])
        gameMap:drawLayer(gameMap.layers["Object Bottoms"])
        player.anim:draw(player.spriteSheet, x + ((w * 0.5) - sw -2), y + ((w * 0.5) - sh * 2), nil, 2.2)
        gameMap:drawLayer(gameMap.layers["Object Tiles"])
        gameMap:drawLayer(gameMap.layers["Outer Border"])
        
        world:draw()
    cam:detach()
end
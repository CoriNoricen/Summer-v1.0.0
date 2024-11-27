tile_x,tile_y = 1,1     -- Player's tile position
w,h = 70,70             -- Tile width/height in pixels
x,y = tile_x*w,tile_y*h -- Player's pixel position
heading = 4             -- The player's in-game heading direction
key_heading = 0         -- The heading direction the player is holding
turn_timer = 0          -- Timer for waiting after the player turns before moving
turn_wait = 0.15         -- How long to wait after the player turns
canTurn = true          -- Prevents turning mid-movement
pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- BARBARA
-- by FREDERIC LINN

function _init()
  init_globals()
  init_objects()
  change_scene("START")
end

function init_globals()
  -- the y-offset of the map per stage.
  -- used for getting the correct map tile flags.
  MAP_OFFSETS = {
    ["FOREST"] = 0,
    ["CAVE"] = 16,
    ["CASTLE"] = 48,
  }

  MAX_HP = 10

  -- used for screen shake
  CAM_OFFSET = 0.5
  SHOULD_SHAKE = false

  -- enemy sounds
  SFX_COOLDOWN = 0

  CURRENT_SCENE = ""
  DEBUG_MSG = ""

  -- flag definitions
  F_COLLISION = 0
  F_DAMAGE = 1

  SCROLL_SPEED = 0.5
end

function init_objects()
  init_gameloop()
  init_witch()
  init_scenes()
end

function init_scenes()
  scenes = {}

  scenes["GAME_OVER"] = {
    init = function()
      music(-1, 300)
    end,
    update = function()
      if(btn(5)) _init()
    end,
    draw = function()
      cls()
      print("PRESS ❎ TO CONTINUE")
    end
  }

  scenes["START"] = {
    ticks = 0,
    map_x = 0,
    foreground_x = 0,
    background1_x = 0,
    background2_x = 0,
    background3_x = 128,
    colors = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
    curr_clr = 0,
    letters = {
      {spr = 67, x = 2}, -- B
      {spr = 69, x = 20}, -- A
      {spr = 71, x = 38}, -- R
      {spr = 67, x = 56}, -- B
      {spr = 69, x = 74}, -- A
      {spr = 71, x = 92}, -- R
      {spr = 69, x = 110}, -- A
    },
    init = function(self)
      self.ticks = 0
      self.map_x = 0
      self.foreground_x = 0
      self.background1_x = 0
      self.background2_x = 0
      self.background3_x = 128
    end,
    update = function(self)
      if(btn(5)) change_scene("FOREST")

      self.map_x -= SCROLL_SPEED
      self.background1_x -= 0.25
      self.background2_x -= 0.1
      self.background3_x -= 0.05
      self.foreground_x -= SCROLL_SPEED
      -- the main map is 4 screens wide
      if (self.map_x < -128*4) self.map_x = 0
      if (self.foreground_x < -128*2) self.foreground_x = 0
      -- the backgrounds are each 1 screen wide
      if (self.background1_x < -127) self.background1_x = 0
      if (self.background2_x < -127) self.background2_x = 0
      if (self.ticks % 60 == 0) then
        self.curr_clr = (self.curr_clr % 16) + 1
      end
      self.ticks += 1
    end,

    draw = function(self)
      cls(12)
      map(96, 0, self.background3_x, 0, 32, 16)
      map(80, 0, self.background2_x, 0, 16, 16)
      map(80, 0, self.background2_x + 128, 0, 16, 16)
      map(64, 0, self.background1_x + 128, 0, 16, 16)
      map(64, 0, self.background1_x, 0, 16, 16)
      palt(0, false)
      palt(8, true)
      map(0, 0, self.map_x, 0, 64, 16)
      map(0, 0, self.map_x + 128 * 4, 0, 64, 16)
      palt()

      pal(7, self.colors[self.curr_clr])
      for l in all(self.letters) do
        local sx, sy = get_sprite_coordinates(l.spr)
        sspr(sx, sy, 16, 16, l.x, 4, 16, 24)
      end
      pal()

      print("LOS GEHTS", 44, 32, 10)
      print("❎", 56, 38)
    end
  }

  scenes["FOREST"] = {
    map_x = 0,
    foreground_x = 0,
    background1_x = 0,
    background2_x = 0,
    background3_x = 128,
    -- the current position on the map (in tiles, not pixels)
    -- takes scrolling into account.
    -- used for spawning objects at specific points.
    spawn_x = 0,
    prev_spawn_x = 0,
    -- the maps are looping, so their x-coordinates
    -- can't be used for calculating our spawn points.
    -- we need an ever-increasing counter
    abs_x = 0,

    init = function(self)
      curr_e = {}
      self.map_x = 0
      self.foreground_x = 0
      self.background1_x = 0
      self.background2_x = 0
      self.background3_x = 128
      self.spawn_x = 0
      self.prev_spawn_x = 0
      self.abs_x = 0
      w:init()
      init_enemies()
    end,

    update = update_stage,

    ended = function(self)
      -- check if we reached the end of the forest
      if (self.spawn_x == 216) change_scene("POST_FOREST")
    end,

    update_map = function(self)
      self.map_x -= SCROLL_SPEED
      self.abs_x += SCROLL_SPEED
      self.background1_x -= 0.25
      self.background2_x -= 0.1
      self.background3_x -= 0.05
      self.foreground_x -= SCROLL_SPEED
      -- the main map is 4 screens wide
      if (self.map_x < -128*4) self.map_x = 0
      if (self.foreground_x < -128*2) self.foreground_x = 0
      -- the backgrounds are each 1 screen wide
      if (self.background1_x < -127) self.background1_x = 0
      if (self.background2_x < -127) self.background2_x = 0
    end,

    draw = function(self)
      cls(12)
      map(96, 0, self.background3_x, 0, 32, 16)
      map(80, 0, self.background2_x, 0, 16, 16)
      map(80, 0, self.background2_x + 128, 0, 16, 16)
      map(64, 0, self.background1_x + 128, 0, 16, 16)
      map(64, 0, self.background1_x, 0, 16, 16)
      palt(0, false)
      palt(8, true)
      map(0, 0, self.map_x, 0, 64, 16)
      map(0, 0, self.map_x + 128 * 4, 0, 64, 16)
      palt()

      if (self.spawn_x < 30) print("WALD", 50, 10, 7)
      foreach(curr_e, function(e) e:draw() end)
      w:draw()
      map(32, 16, self.foreground_x, 0, 32, 16)
      map(32, 16, self.foreground_x + 128*2, 0, 32, 16)
      draw_hp()
    end,
  }

  scenes["POST_FOREST"] = {
    irisd = -1,
    irisi = 92,
    update = function(self)
      if (self.irisi == 0) change_scene("PRE_CAVE")
    end,
    draw = function(self)
      local i, d = iris(self.irisi, self.irisd, 13)
      self.irisi = i
      self.irisd = d
    end
  }

  scenes["PRE_CAVE"] = {
    irisd = 1,
    irisi = 0,
    init = function(self)
      w.x = 8
      w.y = 60
    end,
    update = function(self)
      if (self.irisi == 92) change_scene("CAVE")
    end,
    draw = function(self)
      cls()
      palt(0, false)
      palt(7, true)
      map(64, 16, 0, 0, 16, 16)
      map(0, 16, 0, 0, 16, 16)
      palt()
      w:draw()
      local i, d = iris(self.irisi, self.irisd, 13)
      self.irisi = i
      self.irisd = d
    end
  }

  scenes["CAVE"] = {
    map_x = 0,
    background1_x = 0,
    spawn_x = 0,
    prev_spawn_x = 0,
    abs_x = 0,

    init = function(self)
      curr_e = {}
      self.map_x = 0
      self.background1_x = 0
      self.spawn_x = 0
      self.prev_spawn_x = 0
      self.abs_x = 0
      w:init()
      init_enemies()
    end,

    update = update_stage,

    ended = function(self)
      if (self.spawn_x == 216) change_scene("POST_CAVE")
    end,

    update_map = function(self)
      self.map_x -= SCROLL_SPEED
      self.abs_x += SCROLL_SPEED
      self.background1_x -= 0.1
      -- the foreground map is 2 screens wide
      if (self.map_x < -128*2) self.map_x = 0
      if (self.background1_x < -127) self.background1_x = 0
    end,

    draw = function(self)
      cls()
      palt(0, false)
      palt(7, true)
      map(64, 16, self.background1_x, 0, 16, 16)
      map(64, 16, self.background1_x + 128, 0, 16, 16)
      map(0, 16, self.map_x, 0, 32, 16)
      map(0, 16, self.map_x + 128 * 2, 0, 32, 16)
      palt()
      if (self.spawn_x < 30) print("BERG", 55, 10, 7)
      foreach(curr_e, function(e) e:draw() end)
      w:draw()
      draw_hp()
    end,
  }

  scenes["POST_CAVE"] = {
    irisd = -1,
    irisi = 92,
    update = function(self)
      if (self.irisi == 0) change_scene("PRE_CASTLE")
    end,
    draw = function(self)
      local i, d = iris(self.irisi, self.irisd, 13)
      self.irisi = i
      self.irisd = d
    end
  }

  scenes["PRE_CASTLE"] = {
    irisd = 1,
    irisi = 0,
    init = function(self)
      w.x = 8
      w.y = 60
    end,
    update = function(self)
      if (self.irisi == 92) change_scene("CASTLE")
    end,
    draw = function(self)
      cls()
      palt(0, false)
      palt(7, true)
      palt()
      w:draw()
      local i, d = iris(self.irisi, self.irisd, 13)
      self.irisi = i
      self.irisd = d
    end
  }

  scenes["CASTLE"] = {
    map_x = 0,
    background1_x = 0,
    spawn_x = 0,
    prev_spawn_x = 0,
    abs_x = 0,
    u = nil,

    init = function(self)
      w:init()
      curr_e = {}
      self.map_x = 0
      self.background1_x = 0
      self.u = unhold()
    end,

    update = function(self)
      w:update(abs(self.map_x))
      self.u:update()

      foreach(curr_e, function(e) e:update() end)

      for e in all(curr_e) do
        if (collide(w, e) and w.iframes == 0) then
          w:hit()
        end
      end

      -- collision with custom boss hitbox
      local boss_collide = collide_rect(w.x, w.y, 8, self.u.x-12, self.u.y-12, 24)
      if boss_collide and w.iframes == 0 then
        w:hit()
      end

      -- update the map
      self.map_x -= SCROLL_SPEED
      self.abs_x += SCROLL_SPEED
      self.background1_x -= 0.1
      if (self.map_x < -120*2 ) self.map_x = 0
      if (self.background1_x < -127) self.background1_x = 0
      if (self.u.beaten) change_scene("POST_CASTLE")
    end,

    draw = function(self)
      cls()
      -- always draw the moon
      map(124, 48, 90, 0, 32, 16)

      map(0, 48, self.map_x, 0, 32, 16)
      map(0, 48, self.map_x + 128*2 -16, 0, 32, 16)
      w:draw()
      self.u:draw()
      foreach(curr_e, function(e) e:draw() end)
      draw_hp()
    end
  }

  scenes["POST_CASTLE"] = {
    sparks = {},
    fireworks = {},
    t,
    curr_firework = 1,
    init = function(self)
      self.t = 0

      self.fireworks = {
        {64, 64, 5, 200},
        {20, 35, 2, 200},
        {80, 100, 5, 100},
        {64, 33, 3, 100},
        {80, 88, 5, 200},
      }

      for i=1,200 do
        local p = {
          x = 0,
          y = 0,
          velx = 0,
          vely = 0,
          r = 0,
          mass = 0,
          alive = false
        }
        add(self.sparks, p)
      end

    end,

    update = function(self)
      -- create an explosion every second.
      -- change scene if there are no more left.
      if(time() - self.t > 1) then
        if (not self.fireworks
        [self.curr_firework]) then
          change_scene("GAME_OVER")
          return
        end
        self:explode(unpack(self.fireworks[self.curr_firework]))
        self.curr_firework += 1
        self.t = time()
      end

      local sparks = self.sparks
      for i=1, #sparks do
        if sparks[i].alive then
          sparks[i].x += sparks[i].velx / sparks[i].mass
          sparks[i].y += sparks[i].vely / sparks[i].mass
          sparks[i].r -= 0.1
          if sparks[i].r < 0.1 then
            sparks[i].alive = false
          end
        end
      end
    end,

    draw = function(self)
      cls()

      local sparks = self.sparks
      for i=1, #sparks do
        if sparks[i].alive then
          circfill(sparks[i].x, sparks[i].y, sparks[i].r, 10)
        end
      end
    end,

    -- code by mikamulperi
    -- https://www.youtube.com/watch?v=UIZO1TKPlzY
    explode = function(self, x, y, r, particles)
      sfx(8)
      local sparks = self.sparks
      local selected = 0
      for i=1, #sparks do
        if (not sparks[i].alive) then
            sparks[i].x = x
            sparks[i].y = y
            sparks[i].vely = -1 + rnd(2)
            sparks[i].velx = -1 + rnd(2)
            sparks[i].r = 0.5 + rnd(r)
            sparks[i].mass = 0.5 + rnd(2)
            sparks[i].alive = true

            selected += 1
            if selected == particles then
              break
            end
          end
      end
    end
  }
end

function update_stage(self)
  -- we calculate where the right edge of the screen
  -- would be if we would travel the map continously.
  self.spawn_x = flr(self.abs_x / 8) + 16

  -- add objects only *once* per map tile
  if (self.spawn_x != self.prev_spawn_x) then
    self.prev_spawn_x = self.spawn_x
    foreach(all_e[CURRENT_SCENE][self.spawn_x], function(e) add(curr_e, e)  end)
  end

  -- we need the absolute x-coordinate of the map (in pixels)
  -- for collision detection.
  w:update(abs(self.map_x))

  foreach(curr_e, function(e) e:update() end)

  for e in all(curr_e) do
    if (collide(w, e) and w.iframes == 0) then
      w:hit()
    end
  end

  -- play enemy sound
  if (#curr_e > 0  and SFX_COOLDOWN <= 0) then
    local i = rndb(1, #curr_e)
    if (curr_e[i].sound) then
      curr_e[i]:sound()
      SFX_COOLDOWN = rndb(180, 240)
    end
  end

  SFX_COOLDOWN -= 1
  self:update_map()
  self:ended()
end

function init_gameloop()
  _update60 = game_update
  _draw = game_draw
end

function game_update()
  scenes[CURRENT_SCENE]:update()
end

function game_draw()
  if (SHOULD_SHAKE) then
    screen_shake()
  end
  scenes[CURRENT_SCENE]:draw()
  print(DEBUG_MSG, 50, 0)
end

-- drawing
function draw_hp()
  -- set the right colors to transparent
  palt(0, false)
  palt(15, true)

  -- first draw the full hearts
  local i = 0
  while i < w.hp do
    spr(48, i * 8 + 1, 1)
    i += 1
  end

  -- then draw the empty ones
  while i < MAX_HP do
    spr(49, i * 8 + 1, 1)
    i += 1
  end
  palt()
end

-- objects
function init_witch()
  local update_witch = function(self, map_x)
    self.iframes -= 1
    self.iframes = max(0, self.iframes)

    -- animate the witch
    animate(self)

    local tmp_y = self.y
    local accel = 0.3
    local friction = 0.9

    if(btn(2)) then
      self.dy -= accel
      self.dir = 1
    elseif(btn(3)) then
      self.dy += accel
      self.dir = -1
    end

    self.dy *= friction
    tmp_y += self.dy

    -- we iterate over every map tile that's currently on screen
    -- and see if barbara collides with any of them that have
    -- our collision flag set.
    local map_collision = false
    local x_offset= flr(map_x/8)
    local y_offset = MAP_OFFSETS[CURRENT_SCENE]

    for x=0,15 do
      for y=0,15 do
        local t = mget(x + x_offset, y + y_offset)
        local c = fget(t, F_COLLISION)
        if (c) then
           if
            w.x + 5 > x * 8 and
            w.y + 5 > y * 8 and
            w.x < x * 8 + 5 and
            w.y < y * 8 + 5
          then
            -- did we also take damage?
            if (fget(t, F_DAMAGE) and w.iframes == 0) then
              w:hit()
            end
            sfx(2)
            map_collision = true
          end
        end
      end
    end

    if (not map_collision) then
      -- reset the velocity if we hit the edges
      if (tmp_y < 0 or tmp_y > 120) then
        self.dy = 0
      end
      -- don't stray outside the screenspace
      self.y = mid(8, tmp_y, 120)

    else
      -- we don't want to get stuck,
      -- so we multiply the current direction (either 1 or -1)
      -- with the distance that we want the player to travel
      -- for resetting.
      self.dy = 0
      self.y += (self.dir * 3.0)
    end

    add(self.trail, trail_particle(self.x - 2, self.y + 5))
    foreach(self.trail, function(p) p:update() end)
  end

  local draw_witch = function(self)
    -- make her sprite flicker if she got hit
    if (self.iframes % 2 == 0) then
      spr(self.sprites[self.frame], self.x, self.y)
    end

    foreach(self.trail, function(p) p:draw() end)
  end

  local hit_witch = function(self)
    SHOULD_SHAKE = true
    sfx(1)
    w.hp -= 1
    w.iframes = 120
    if (w.hp <= 0) then
      SHOULD_SHAKE = false
      change_scene("GAME_OVER")
    end
  end

  local init_witch = function(self)
    self.trail = {}
    self.x = 20
    self.y = 50
    self.dy = 0
    self.dir = 0
    self.iframes = 0
    self.hp = MAX_HP
  end

  w = {
    x = 20,
    y = 50,
    dy = 0,
    dir = 0,
    accel = 0.5,
    sprites = {1, 2, 3},
    tick = 0,
    frame = 1,
    step = 8,
    hp = 3,
    iframes = 0,
    update = update_witch,
    draw = draw_witch,
    hit = hit_witch,
    init = init_witch,
  }
end

function draw_trail(self)
  circ(self.x, self.y, self.r, 10)
end

function update_trail(self)
  self.d -= 0.01
  self.r -= 0.1
  self.x -= rndb(0.5, 0.8)
  if (self.r <= 0) del(w.trail, self)
end

function trail_particle(_x, _y)
  -- we want to be able to go below
  -- and above the current y coordinate.
  local dir = {-1, 1}
  local sel_dir = flr(rnd(2)) + 1

  return {
    x = _x,
    y = _y - (dir[sel_dir] * flr(rnd(3))),
    d = rndb(0.15, 0.25),
    r = rndb(1, 2),
    draw = draw_trail,
    update = update_trail,
  }
end

function init_enemies()
  curr_e = {}
  all_e = {}

  all_e["FOREST"] = {
    [18] = {snake(0.5)},
    [20] = {bird(25, 1.0)},
    [23] = {bird(55, 1.0), snake(1.0)},
    [30] = {bird(68, 0.6), snake(0.5)},
    [32] = {bird(77, 2.0), snake(1.0)},
    [40] = {bird(10, 0.75), bird(55, 1.0)},
    [50] = {bird(33, 1.50), bird(80, 1.0), snake(1.0)},
    [58] = {bird(13, 0.75), bird(87, 1.0), snake(0.5)},
    [65] = {bird(66, 0.5), bird(72, 1.0), snake(1.2)},
    [71] = {bird(16, 0.75), bird(50, 1.0), snake(1.1)},
    [77] = {bird(59, 0.75), snake(0.7)},
    [95] = {bird(55, 0.75), bird(80, 0.7)},
    [100] = {bird(29, 1.75), bird(79, 1.0)},
    [108] = {bird(42, 0.6), bird(55, 1.0), snake(1.2)},
    [112] = {bird(12, 0.75), bird(40, 1.0), snake(1.0)},
    [120] = {bird(55, 2.75)},
    [124] = {bird(20, 1.75), snake(1.0)},
    [132] = {bird(60, 1.5)},
    [144] = {bird(20, 1.75), bird(60, 1.0), bird(75, 1.3), snake(1.25)},
    [149] = {snake(1.0)},
    [155] = {bird(18, 1.0), snake(0.7)},
    [162] = {bird(33, 1.25), bird(66, 1.2), snake(1.0)},
    [165] = {bird(40, 1.75)},
    [175] = {snake(0.8)},
    [177] = {bird(64, 1.0), snake(1.8)},
    [185] = {bird(15, 1.5), bird(60, 1.3)},
    [188] = {bird(35, 1.8), bird(71, 1.3), snake(0.9)},
    [192] = {bird(20, 1.0), bird(75, 0.9)},
    [200] = {bird(13, 0.75), bird(53, 0.75), bird(73, 0.75)},
  }

  all_e["CAVE"] = {
    [20] = {bat(25, 1.0)},
    [23] = {bat(55, 1.0)},
    [30] = {bat(68, 0.6)},
    [32] = {bat(77, 2.0)},
    [40] = {bat(10, 0.75)},
    [50] = {bat(33, 1.50)},
    [58] = {bat(13, 0.75)},
    [65] = {bat(66, 0.5)},
    [71] = {bat(16, 0.75)},
    [77] = {bat(59, 0.75)},
    [95] = {bat(55, 0.75)},
    [100] = {bat(29, 1.75),
    [108] = {bat(42, 0.6)},
    [112] = {bat(12, 0.75)},
    [120] = {bat(55, 2.75)},
    [124] = {bat(20, 1.75)},
    [132] = {bat(60, 1.5)}},
    [144] = {bat(20, 1.75)},
    [155] = {bat(18, 1.0)},
    [162] = {bat(33, 1.25)},
    [165] = {bat(40, 1.75)},
    [177] = {bat(64, 1.0)},
    [185] = {bat(15, 1.5)},
    [188] = {bat(35, 1.8)},
    [192] = {bat(20, 1.0)},
    [200] = {bat(13, 0.75)},
  }
end

function update_unhold(self)
  if (self.phase == "APPEAR") then
    if(time() - self.t > 3) self:next_phase()
    self.x = 106
    self.y = 23
 end

  if (self.phase == "BOUNCE") then
    if(time() - self.t > 15) self:next_phase()
    self.x += self.dx * 1
    self.y += self.dy * 0.5

    self.spin_speed = 0.05

    if (self.x + 16 >= 128 or self.x - 16 <= 0) then
      SHOULD_SHAKE = true
      sfx(7)
      self.dx = -self.dx
    end

    if (self.y + 16 >= 128 or self.y - 16 <= 0) then
      SHOULD_SHAKE = true
      sfx(7)
      self.dy = -self.dy
    end
  end

  if (self.phase == "PRE_SPAWN_GHOSTS") then
    if (self.x > 98 and self.y > 62)  then
      self.x = 100
      self.y = 64
      self:next_phase()
    end

    local delta_x = self.x - 100
    local delta_y = self.y - 64

    self.x -= delta_x / 100
    self.y -= delta_y / 100
  end

  if (self.phase == "SPAWN_GHOSTS") then
    if (time() - self.t > 15 and #curr_e == 0) self:next_phase()

    if (not(time() - self.t > 15) and self.spawn_cooldown == 0) then
      sfx(6)
      local y_ghost = rndb(10, 120)
      add(curr_e, ghost(y_ghost))
      self.spawn_cooldown = 120
    end

    self.spin_speed = 0.01
    self.spawn_cooldown -= 1
  end

  if (self.phase == "PRE_HORIZONTAL") then
    self.spin_speed = 0.05
    self.dx = 1
    if(self.angle > 0.7 and self.angle <= 0.75) then
      self.spin = false
      self.angle = 0.75
      self:next_phase()
    end
  end

  if (self.phase == "HORIZONTAL") then
    if (self.y < w.y) self.y += 1
    if (self.y > w.y) self.y -= 1

    if (time() - self.t > 3) self:next_phase()
  end

  if (self.phase == "LUNCH") then
    sfx(0)
    self.dx += 0.05
    self.dx = mid (0.05, self.dx, 1.5)
    self.x -= self.dx

    if (self.x + 16 < 0) then
      self.dx = 0.1
      self.lunch_cnt += 1
      self.x = 144
      self:next_phase()
    end
  end

  if (self.phase == "BEATEN") then
    sfx(0)
    self.dx += 0.1
    self.x -= self.dx

    if (self.x + 16 < 0) self.x = 144

    if (flr(self.dx) == 50) then
      self.beaten = true
    end
  end

  if (self.spin) then
    self.angle += self.spin_speed
    if (self.angle > 1.5) self.angle = 0.5
  end
  self.ticks += 1
end

function draw_unhold(self)
  local sx, sy = (12 % 16) * 8, (12 \ 16) * 8
  -- give him red eyes
  if self.phase == "BOUNCE" or
    self.phase ==  "SPAWN_GHOSTS" or
    self.phase ==  "LUNCH" then
    pal(11, 8)
  else
    pal(11, 0)
  end

  if self.phase == "BOUNCE" or
    self.phase == "PRE_SPAWN_GHOSTS" or
    self.phase == "SPAWN_GHOSTS" or
    self.phase == "PRE_HORIZONTAL" or
    self.phase == "HORIZONTAL" or
    self.phase == "LUNCH" or
    self.phase == "BEATEN" then
    spr_r(sx, sy, self.x, self.y, 4, 4, 0, 0, 16, 16, self.angle, 0)
  end

  if self.phase == "APPEAR" then
    if (self.ticks % 8 == 0) then
      cls(10)
      spr_r(sx, sy, self.x, self.y, 4, 4, 0, 0, 16, 16, self.angle, 0)
    end
  end

  pal()
end

function unhold()
  return {
    ticks = 0,
    angle = 0.5,
    phase = "APPEAR",
    spawn_cooldown = 140,
    spin = true,
    spin_speed = 0,
    x = 106,
    y = 23,
    dx = 1,
    dy = 1,
    t = time(),
    beaten = false, -- has the boss been beaten yet?
    lunch_cnt = 0,
    update = update_unhold,
    draw = draw_unhold,
    -- the last phase should return true so that
    -- the scene knows the boss is finished.
    next_phase = function(self)
      -- reset the timer
      self.t = time()
      self.ticks = 0

      -- our final condition for winning
      if (self.lunch_cnt == 5) then
        self.phase = "BEATEN"
      end

      if (self.phase == "LUNCH") self.phase = "PRE_HORIZONTAL"
      if (self.phase == "HORIZONTAL") self.phase = "LUNCH"
      if (self.phase == "PRE_HORIZONTAL") self.phase = "HORIZONTAL"
      if (self.phase == "SPAWN_GHOSTS") self.phase = "PRE_HORIZONTAL"
      if (self.phase == "PRE_SPAWN_GHOSTS") self.phase = "SPAWN_GHOSTS"
      if (self.phase == "BOUNCE") self.phase = "PRE_SPAWN_GHOSTS"
      if (self.phase == "APPEAR") self.phase = "BOUNCE"
    end
  }
end

function update_bird(self)
  self.x -= self.speed
  if (self.x < -8) then del(curr_e, self); return end
  animate(self)

  if (self.y_dir == "UP") then
    self.y -= 0.5
  end

  if (self.y_dir == "DOWN") then
    self.y += 0.5
  end

  if (self.y >= self.base_y + 10 ) then
    self.y_dir = "UP"
  end

  if (self.y <= self.base_y - 10) then
    self.y_dir = "DOWN"
  end
end

function draw_bird(self)
  pal(6, self.color)
  spr(self.sprites[self.frame], self.x, self.y)
  pal()
end

function make_sound(self)
  if (self.sfx) sfx(self.sfx)
end

function bird(_y, _speed)
  -- choose a random color
  local colors = {6, 13, 15}
  local i = rndb(1, 3)

  return {
    tick = 0,
    frame = 1,
    step = 6,
    sprites = {64, 65, 66},
    color = colors[i],
    base_y = _y,
    -- always spawn just outside the view port
    x = 128,
    sfx = 3,
    y = _y,
    y_dir = "DOWN",
    sfx = 3,
    sound = make_sound,
    speed = _speed,
    update = update_bird,
    draw = draw_bird,
  }
end

function update_bat(self)
  animate(self)
  self.x -= self.speed
end

function draw_bat(self)
  -- we want solid black!
  palt(0, false)
  palt(7, true)
  spr(self.sprites[self.frame], self.x, self.y)
  palt()
end

function bat(_y, _speed)
  return {
    tick = 0,
    frame = 1,
    step = 6,
    sprites = {80, 81, 82},
    x = 128,
    y = _y,
    sfx = 4,
    sound = make_sound,
    speed = _speed,
    update = update_bat,
    draw = draw_bat
  }
end

function update_snake(self)
  animate(self)
  self.x -= self.speed
end

function draw_snake(self)
  -- we want solid black!
  palt(0, false)
  palt(7, true)
  spr(self.sprites[self.frame], self.x, self.y)
  palt()
end

function snake(_speed)
  return {
    tick = 0,
    frame = 1,
    step = 12,
    sprites = {96, 97, 98},
    x = 128,
    y = 96,
    speed = _speed,
    update = update_snake,
    draw = draw_snake
  }
end

-- utilities
function animate(self)
  self.tick=(self.tick+1)%self.step --tick fwd
  if (self.tick==0) self.frame=self.frame%#self.sprites+1
end

function update_ghost(self)
  if (self.x < -8) del(curr_e, self)

  if (self.state == "SPAWN") then
    self.sprites = self.spawn_sprites
    if (self.frame == 3) self:next_state()
  end

  if (self.state == "NORMAL") then
    self.sprites = self.normal_sprites
    if (flr(self.ticks / 60) == 1) self:next_state()
  end

  animate(self)
  self.ticks += 1
end

function draw_ghost(self)
  -- we want solid black!
  palt(0, false)
  palt(15, true)
  spr(self.sprites[self.frame], self.x, self.y)
  palt()
end

function next_ghost_state(self)
  self.ticks = 0
  if (self.state == "NORMAL") then
    local tmp_y = rndb(self.y - 8, self.y + 8)
    self.y = mid(0, tmp_y, 120)
    self.x -=  rndb(10, 30)
    self.state = "SPAWN"
    sfx(self.sfx)
  elseif (self.state == "SPAWN") then
    self.state = "NORMAL"
  end
end

function ghost(_y)
  return {
    ticks = 0,
    tick = 0,
    frame = 1,
    step = 12,
    sprites = nil,
    normal_sprites = {112, 113, 114},
    spawn_sprites = {115, 116, 117},
    state = "SPAWN",
    x = 80,
    y = _y,
    sfx = 5,
    update = update_ghost,
    draw = draw_ghost,
    next_state = next_ghost_state,
  }
end

function collide(obj1, obj2)
  -- check if the object1's coordinates are inside
  -- the object2, therefore hitting it.
  if
    obj1.x + 8 > obj2.x and
    obj1.y + 8 > obj2.y and
    obj1.x < obj2.x + 8 and
    obj1.y < obj2.y + 8
  then
    return true
  end
end

function collide_rect (x1, y1, w1, x2, y2, w2)
  if
    x1 + w1 > x2 and
    y1 + w1 > y2 and
    x1 < x2 + w2 and
    y1 < y2 + w2
  then
    return true
  end
end

function change_scene(next_scene)
  -- initialize the state if a function is provided.
  if(scenes[next_scene].init) then
    scenes[next_scene]:init()
  end
  CURRENT_SCENE = next_scene
end

function get_sprite_coordinates(spr)
  local sx, sy = (spr % 16) * 8, (spr \ 16) * 8
  return sx, sy
end

-- code by doc_robs
-- https://gamedev.docrobs.co.uk/screen-shake-in-pico-8
function screen_shake()
  local fade = 0.95
  local offset_x=16-rnd(32)
  local offset_y=16-rnd(32)

  offset_x*=CAM_OFFSET
  offset_y*=CAM_OFFSET

  camera(offset_x,offset_y)

  CAM_OFFSET*=fade
  if CAM_OFFSET<0.05 then
    CAM_OFFSET=0.5
    SHOULD_SHAKE = false
  end
end

-- code by MBoffin
function rndb(low,high)
  return flr(rnd(high-low+1)+low)
end

-- code by dw817
-- https://www.lexaloffle.com/bbs/?tid=36250
function iris(irisi, irisd, clr)
  for i=91,irisi,-1 do
    for j=63,65 do
      circ(j,64,i,clr)
    end
  end
  circ(64,64,irisi-1,5)
  irisi+=irisd
  if (irisi<0) irisd=0 irisi=0
  if (irisi>92) irisd=0 irisi=92
  return irisi, irisd
end

-- code by huulong
-- https://www.lexaloffle.com/bbs/?tid=3593
function spr_r(sx, sy, x, y, w, h, flip_x, flip_y, pivot_x, pivot_y, angle, transparent_color)
  local sw = 8 * w
  local sh = 8 * h

  -- precompute angle trigonometry
  local sa = sin(angle)
  local ca = cos(angle)

  -- in the operations below, 0.5 offsets represent pixel "inside"
  -- we let PICO-8 functions floor coordinates at the last moment for more symmetrical results

  -- precompute "target disc": where we must draw pixels of the rotated sprite (relative to (x, y))
  -- the target disc ratio is the distance between the pivot the farthest corner of the sprite rectangle
  local max_dx = max(pivot_x, sw - pivot_x) - 0.5
  local max_dy = max(pivot_y, sh - pivot_y) - 0.5
  local max_sqr_dist = max_dx * max_dx + max_dy * max_dy
  local max_dist_minus_half = ceil(sqrt(max_sqr_dist)) - 0.5

  -- iterate over disc's bounding box, then check if pixel is really in disc
  for dx = - max_dist_minus_half, max_dist_minus_half do
    for dy = - max_dist_minus_half, max_dist_minus_half do
      if dx * dx + dy * dy <= max_sqr_dist then
        -- prepare flip factors
        local sign_x = flip_x and -1 or 1
        local sign_y = flip_y and -1 or 1

        -- if you don't use luamin (which has a bracket-related bug),
        -- you don't need those intermediate vars, you can just inline them if you want
        local rotated_dx = sign_x * ( ca * dx + sa * dy)
        local rotated_dy = sign_y * (-sa * dx + ca * dy)

        local xx = pivot_x + rotated_dx
        local yy = pivot_y + rotated_dy

        -- make sure to never draw pixels from the spritesheet
        --  that are outside the source sprite
        if xx >= 0 and xx < sw and yy >= 0 and yy < sh then
          -- get source pixel
          local c = sget(sx + xx, sy + yy)
          -- ignore if transparent color
          if c ~= transparent_color then
            -- set target pixel color to source pixel color
            pset(x + dx, y + dy, c)
          end
        end
      end
    end
  end
end

__gfx__
000000000000eee00000eee00000eee00000000000000000000000000000000000000111000000000000000000000ddd44404440444000033300044404440444
00000000000eeff000eeeff000eeeff0000000000000000000000000000000000000111c00000000000000000000ddd644404440444400033300444404440444
0070070000eefff000eefff0000efff000000000000000000000000000000000001111cc000000000000000000dddd6644444444444440333304444444444444
00077000a0002200a0002200a00022000000000000000000000000000000000000011cc70000000000000000000dd66044444444444440333304444444444444
00077000aa022220aa022220aa022220000000000000000000000000000000000011ccc7000000000000000000dd666004444444444493399339444444444440
00000000aaa222faaaa222faaaa222fa00000000000000000000000110000000011ccc7700000005d00000000dd6660000444444449933339333994444444400
00000000aa002200a9002200a900220000000000000000000000000c1100000111cc7c7700000006dd00000ddd66060000000000099333339333399000000000
00000000a00f2000900f2000a00f20000000000000000000000000ccc1000011ccc77777000000666d0000dd6660000000000000993333339933399900000000
000000000000000000000000000000000000000000000111ccc00000110001c11c77777766600000dd000d65d600000000000009993333399933333990000000
00000000000000000000000000000000000000000000111c11cc0c00c10001cccc777777dd6606006d000d666600000000000099999333399933339999000000
0000000000000000000000000000000000000000001111cc711ccc00c11011c7c77777770dd666006dd0dd606000000000000999999933999933339999900000
000000000000000000000000000000000000000000011cc07711ccc0cc101cc77777777700dd666066d0d6600000000000000999999999999993339999900000
00000000000000000000000000000000000000000011ccc077711cc07c111c7777777777000dd66006ddd600000000000000099b9999999999993399b9900000
0000000000000000000000000000000000000000011ccc00771111cc7c111c777777777700dddd6606ddd600000000000000999bbbb99999999999bbb9990000
000000000000000000000000000000000000000011cc0c007777111c77c1cc77777777770000ddd6006d66000000000000009999bbbbbb99999bbbbbb9990000
0000000000000000000000000000000000000000ccc0000077777111777cc7777777777700000ddd000660000000000000009999bbbbbbb999bbbbbb99990000
0000000000000000000000000000000000000000ccc0000077777777777cc777111777770000000000066000ddd00000005599999bbbbbb999bbbbb999995500
000000000000000000000000000000000000000011cc0c007777777777cc1c77c1117777000000000066d6006ddd00000555999999bbbbb999bbbbb999995550
0000000000000000000000000000000000000000011ccc007777777777c111c7cc11117700000000006ddd6066dddd00555599999999bbb919bbbb9999995555
00000000000000000000000000000000000000000011ccc07777777777c111c70cc1177700000000006ddd60066dd00055509999999999911199999999995555
000000000000000000000000000000000000000000011cc0777777777cc101cc0ccc117700000000066d0d660666dd0055500999999999111119999999900555
0000000000000000000000000000000000000000001111cc7777777c7c11011c00ccc1170000000606dd0dd600666dd050500999999999111119999999900505
00000000000000000000000000000000000000000000111c777777cccc10001c00c0cc110000006666d000d6006066dd00000999299999999999999299900000
000000000000000000000000000000000000000000000111777777c11110001100000ccc00000065ddd000dd0000066600000099222222229222222299000000
f00f00fff00f00ff00000000000000000000000000000ccc77777ccc1100001ccc00000000000666dd0000d66600000000000009922222222222222990000000
0880880f0660660f00000000000000000000000000c0cc1177c7cc1110000011c0000000006066ddd00000dd6000000000000000992222222222229900000000
0888e80f0666760f00000000000000000000000000ccc11077ccc110000000011000000000666dd00000000d5000000000000000099229222292299000000000
0888880f0666660f0000000000000000000000000ccc11007ccc110000000000000000000666dd00000000000000000000000000059999999999995000000000
f08880fff06660ff0000000000000000000000000cc110007cc110000000000000000000066dd000000000000000000000000000550099999999055500000000
ff080fffff060fff000000000000000000000000cc111100cc111100000000000000000066dddd00000000000000000000000005555500000000555550000000
fff0fffffff0ffff000000000000000000000000c1110000c111000000000000000000006ddd0000000000000000000000000050505050000005050505000000
ffffffffffffffff00000000000000000000000011100000111000000000000000000000ddd00000000000000000000000000000000000000000000000000000
00111000001110000011100007777777700000000000007777000000077777777770000000000000000000000000000000000000000000000000000000000000
0166100101661001016610017eeeeeee770000000000007ee70000007eeeeeeeeee7700000000000000000000000000000000000000000000000000000000000
9657611696576116965761167eeeeeeeee770000000007eeee7000007eeeeeeeeeee700000000000000000000000000000000000000000000000000000000000
0166666601666666016666667eee7777eeee7000000007eeee7000007eee77777eeee70000000000000000000000000000000000000000000000000000000000
0011111100111611001116617ee770077eee700000007eeeeee700007ee7000007eee70000000000000000000000000000000000000000000000000000000000
0001161000001161000011167ee700007eee700000007ee77ee700007ee7000007eee70000000000000000000000000000000000000000000000000000000000
0000161000000116000000117ee770077eee70000007ee7007ee70007ee700777eeee70000000000000000000000000000000000000000000000000000000000
0000000000000000000000007eee7777eeee70000007e700007e70007ee707eeeeee700000000000000000000000000000000000000000000000000000000000
7777777777717177777171777eeeeeeeeeee70000007e700007e70007eee7eeeee77000000000000000000000000000000000000000000000000000000000000
7777777771781871777818777eeeeeeeee7700000007e700007e70007eeeeeeee700000000000000000000000000000000000000000000000000000000000000
7771717771111111711111117eee7777e7000000007ee700007ee7007eeeeeeeee70000000000000000000000000000000000000000000000000000000000000
7178187171111111711111117ee770077e770000007eee7777eee7007ee77eeeeee7000000000000000000000000000000000000000000000000000000000000
7111111177711177717111717ee770077eee700007eeeeeeeeeeee707ee70777eeee700000000000000000000000000000000000000000000000000000000000
7111111177771777777717777eee7777eeee700007ee77777777ee707ee700007eeee70000000000000000000000000000000000000000000000000000000000
7171117177777777777777777eeeeeeeeeee70007ee7000000007ee77ee7000007eee70000000000000000000000000000000000000000000000000000000000
77771777777777777777777707777777777700000770000000000770077000000077700000000000000000000000000000000000000000000000000000000000
77bbbbb77bbbbb777bbbbb7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7bb0b0b3bb0b0b37bb0b0b3700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7bebbbe3bebbbe37bebbbe3700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77b333377b3333777b33337700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77bb0b7777bb0b777bb0b77700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7bb0bb377bb0bb37bb0bb37700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
73b3333b73b3333b3b3333b700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77bbbbb377bbbbb37bbbbb3700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777fff77777fff77777ffffffffffffffffffff7f77ff700000000000000000000000000000000000000000000000000000000000000000000000000000000
777777ff777777ff777777fffffffffffff7ffff7ff7f77700000000000000000000000000000000000000000000000000000000000000000000000000000000
070077ff070077ff070077fffffff7fff7fff7fff77f777f00000000000000000000000000000000000000000000000000000000000000000000000000000000
7777777f0700777f777777fffff77fffff777fffff7777ff00000000000000000000000000000000000000000000000000000000000000000000000000000000
7777777777777777777777fffff77ffffff777ff7f77777f00000000000000000000000000000000000000000000000000000000000000000000000000000000
788e7777788e7777788e777fff7fffffff7f7ff777777ff700000000000000000000000000000000000000000000000000000000000000000000000000000000
f7777777788e7777f7777777fffffffff7fff7fff7ff77ff00000000000000000000000000000000000000000000000000000000000000000000000000000000
fff77777f7777777fff77777fffffffffff7ffff7ff7ff7f00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000005500000000000000660000000888888888888b8883b888888cccccccccccccccc0000000000000000000000000000000000000aaaaaaa000000000000
000000555500000000000066660000008888888188883888b3888888cc111c1111c111cc00000000000000000000000000000000000aaaaaaaaaaa0000000000
00000555555000000000066666600000888888138183b3881b388888cc151115511151cc000000000000000000000000000000000aaaa777aaaaaaa600000000
000055555555000000006666666600008888813b88333b83b3b38888cc155555555551cc00000000000000000000000000000000aaa7777aaaa6aaaa60000000
0005555555555000000666666666600088881313881333b8113b8888cc155115511551cc0000000000000000000000000000000aa77777aaaaaaaaaa66000000
00555555555555000066666666666600888131b888113b38b3b3b8881111511551151111000000000000000000000000000000aa77777aaaaaaaaaaaa6600000
055555555555555006666666666666608883b1818133338338313888155151111115155100000000000000000000000000000aa7777a77aaaaaaaaaaaa660000
55555555555555556666666666666666881b81331331133b13183b88155111155111155100000000000000000000000000000a7777aaaaaaa66aaaaa6a660000
0000000770000000cccccccddccccccc888888833131333b3b88888815d555555555555100000000d00dd5dd000000000000aa777aaaaaa666666aaaaaaa6000
0000007777000000ccccccddddcccccc8888813131133b33b3b888881555551111555d510000000000055555000000000000a7777777aa6666776aaaaa6a6000
0000077777700000cccccddddddccccc88881313133333bb1b3b88881555d111111555510000000000d5ddd0000000000000a77777aaaa666777aaaaa6a66000
0000777777770000ccccddddddddcccc8831313b333b1333b3b3b388155551111115d551000000005555555000000000000aa77aaaaaa66666aaaaaaaa6aa600
0007777777777000cccddddddddddccc831313133133333b113b3b381d5551111115555100000000d5ddd5d000000000000aa77aa77aaaaaaaaaaaaa6aaa6600
0077777777777700ccddddddddddddcc8131313b333bb3b3b3b3b3b8155d511111155d51000000005005550000000000000aa777777aaaaaaaaaaaaaaa666600
0777777777777770cddddddddddddddc3813b1b11333bb333b31333315555111111555510000000000d5dd0500000000000aa777aaaaaaaaaaaaaaaa6aa66600
7777777777777777dddddddddddddddd1b1b8133138333bb13183b8b1111111111111111000000000555000000000000000aa777aaaaaaaaaaaaaaaaaaa66600
555555556666666677777777dddddddd00000000881444880000000000000000d5ddd5ddd5ddd0000000005d00000000000a777aaaaa666666aaaaa6aa6a6600
555555556666666677777777dddddddd0000000088141488000000000000000055555555555550500500055500000000000aaaaaaaa6666aa666aaaa66a66600
555555556666666677777777dddddddd00000000884144880000000000000000ddd5ddd5ddd5ddd00ddd0ddd00000000000aaa6aaaa666aa7766a6a666666000
555555556666666677777777dddddddd00000000881441880000000000e0e000555555555555555005555555000000000000aaaaaaa66aa777a6aa6a66a66000
555555556666666677777777dddddddd00000000881444880007000000080000d5ddd5ddd5ddd5d00d5ddd5d000000000000aa777aa66a777aaaaa6a6a666000
555555556666666677777777dddddddd0000000088414488007a700000e3e0005555555555555555555555550000000000000a777aaa6666aaaaa6a6aa660000
555555556666666677777777dddddddd000000008811148800070000000b0000ddd5ddd5ddd5ddd55ddd5ddd0000000000000aaa7a7aaaaaaaaaaa66a6660000
555555556666666677777777dddddddd000000008814448800030000000b000055555555555555555555555500000000000000aa7777aaaaaaa66aa666600000
4777777433bbb3b344444444000000000000000088144188000b00000000000055d445ddd5ddd5ddd00dd5dd000000000000000aaaa7aaaa6aaa66a666000000
70070077b33b3b3b44444494000003000000000b88144488bb0b000000000000dd44445555550555000555550000000000000000aaa7aaaaa66a666660000000
70070077333b33b34444444400300b3000b0b003884141880b3b0000000000005440044dddd50dd500d5ddd500000000000000000aaaaaa6aa6a666600000000
77777777434433b444449444b0b00300b033b00b88144488003b0bb0000000004440044455500055055555550000000000000000000aaaaaa666660000000000
77707774444434449444444430bbbb03b0bbb03b81444418000b3b000000000040400404d5ddd5d005ddd5dd000000000000000000000aaa6666000000000000
4777774944444449444449443bb0b030303b3bb084414141000b3000000000004040040450555500000555550000000000000000000000000000000000000000
4707074444944444444444440b03bb300333bb3341114444000b000000000000404004040005ddd500d5ddd50000000000000000000000000000000000000000
444444444444444444444444bb300bb0b303b30318814141000b0000000000004444444400555505055555550000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c8d8e8f8
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c9d9e9f9
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cadaeafa
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cbdbebfb
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa9a00aa9a00aa9a00aa9a00aa9a00aa9a00aa9a00aa9a00aa9a00aa9a0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ab9b00a98a009b8a009b8a00a98a008aa900ab9b00a98a00ab9b008a8a0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8a8aaa8a8a8a8a8aaa8a8a8a8a8aab8a8a8a8a8aab8a8a8a8a8a8a8a8a8a00000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8a9b8a8a8a8bab8a8a8a9a8baa8a8a8a9a8b8a8a8a8a8a8ba98a8a8a8a8b00000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8a8a8a9b8a8a8a8aab8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8aa98a8a00000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9b8a8a8a8a8a8a8a8a8a8a8aab8a8a8a8a8a8a8a8aa98a8a8a8a8a8a8a8a00000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000030000000000000001000000000303030100000000000000000000000003000303000000000000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008788000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009798000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090a2a2910000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000092a3a3a3a39300000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000092a3a3a3a3a3a393000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000909100000000000000000000000000000000000092a3a3a3a3a3a3a3a3930000000000000000000000
000000000000000000000000000000000000000000850000000000000000000000008500000000000000000000000000000000000000000000850000000000000000000000000000000000000000000000000000000090a2a2910000000000000000000000000000000092a3a3a3a3a3a3a3a3a3a39300000000000000000000
0000000000000000000000000000000000000000849586000000850000000000008495860000008500000000000000000000000000000000849586000000850000000000000080810000000000000000000000000082a1a1a1a183000000000000000000000000000092a3a3a3a3a3a3a3a3a3a3a3a393000000000000000000
00000000000000000000000000000000000000009495968500849586000000000094959685008495860000000000000000000000000000009495968500849586000000000080a0a081000000000000000000000082a1a1a1a1a1a18300000000000000000000000092a3a3a3a3a3a3a3a3a3a3a3a3a3a3930000000000000000
000000000000000000000000000000000000000094959695869495960000000000949596958694959600000000000000000000000000000094959695869495960000000080a0a0a0a08100000000000000000082a1a1a1a1a1a1a1a1830000000000000000000092a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a39300000000000000
000000000000000000000000000000000000000000a5949596949596000000000000a594959694959600000000000000000000000000000000a594959694959600000080a0a0a0a0a0a0818081000000000082a1a1a1a1a1a1a1a1a1a183000000000000000092a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a393000000000000
000000000000000000000000000000000000000000a500a50000a500000000000000a500a50000a50000000000000000000000000000000000a500a50000a500000080a0a0a0a0a0a0a0a0a0a08100000082a1a1a1a1a1a1a1a1a1a1a1a18300000000000092a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3930000000000
000000000000000000000000000000000000000000b500b50000b500000000000000b500b50000b50000000000000000000000000000000000b500b50000b5000080a0a0a0a0a0a0a0a0a0a0a0a0810082a1a1a1a1a1a1a1a1a1a1a1a1a1a1830000000092a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a39300000000
b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b180a0a0a0a0a0a0a0a0a0a0a0a0a0a081a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a100000092a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a393000000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b20000000000000000000000000000000000000000000000000000000000000000000092a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3930000
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0b2b2b2b2b2b2b2b200000000000000000000000000000000000000000000000000000000000000000092a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a39300
160710101010101010101010101010101010101010101010101010101010100800000000000000000000000000000000000000000000000000000000000000000000000000000000000019000000000000000000190b000000002a00003900000000000000000000000000000000000000000000000000000000000000000000
00160735101010101010101010101010100710101010101025101010102508000000000000000000000000000000000000000000000000000000000000000000190b00000000000000000b000000000a0019000a0b00000000393a2b390000390000000000000000000000000000000000000000000000000000000000000000
000016071010101010101010101010070817161510101010102507070708000000000000000000000000000000000000000000000000000000000000000000000b000000000000000000190000000b1a190a190b00000000390000002b2a39000000000000000000000000000000000000000000000000000000000000000000
00000017163510101010101010250817000000161010101010081717170000000000000000000000000000000000000000000000000000000000000000000000190a00000b0000000a0a0b0a0a0b000000190b00002a2a392b000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001607071007250817171800000000001615102508000000000000000000000000000000000000000000000000000000000000000000000000000000001a190b0000000b1a1a1a1a1a00000000001900393a3a00002b0000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000171717171718000000000000000000160708000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a19000b000000000000000000000000393a00000000002b00000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000017000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000392b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000392b3900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000027270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a2a000000000000000000393a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000003637372800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000392b3a2b00000000002a2a392b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000362510353728000000270000000000000000000000000000000000000000000000000000000000000000000000000000000039000000392b00002a393a3a2b002b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002727000000000027270000361010103810352827363728000027270000a6000000000000a7a70000000000a6000000a7000000a6a60000000000a700003900000000003a2b393a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2627363710280026273637102836253810101035101010101035283637372800b6b4b4b4b4b4b3b6b6b4b3b3b4b4b6b3b4b4b6b4b4b3b6b6b3b4b4b4b3b6b3b400000000000000392b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3625371010372836253710103710101010101010101010101010371010103528000000000000000000000000000000000000000000000000000000000000000000000000000039000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2510101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
86040000196103963010630206300e6301d6300d630326300c630346200b620286200a6203e6200a620166200a6500a6500b6500b6500b6500b6500b6500c6500c6502f6002b6002c60000600006000060000600
000500002b17025160241202c1002a10025101241002e1002b1002e1003110033100131001810016100111000d10016100111002310023100231001c1000d100231001c1002310018100261001c1002310018100
a2070000126500e62009620066100462003620036001f6001a6001c6002160011600296000a6003a600166002d60028600226001f6001d6001c6001c6001d6001d6001e6001e6001e6001e600006000060000600
160a0000385173850737507385171c507001073d70739507295073b5073d5072f50731507305072f5072d5072c5072a50728507265071850724507225071e507205071f5071f5071c50717507135070f50700500
4e080000381200900009000090000b00038100080000700007000100000f0000e0000d0000d000040000d0000d000381200d0000d0000a0000d000120000d000110000d0000d0000d0000d0000d0000e0002c000
c1040000181161a1161d11620116231162611629116292062c1062e10631106321063410635106371063710600006000060000600006000060000600006000060000600006000060000600006000060000600006
1e0700000c2510d25115201192010f25110251262012a201212010f251112511a20137201362011b2011a2011a2013220131201312013120131201312012a2010020100201002010020100201002010020100201
001000003f6233c613326133162300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
030300002363123631236312363123631236311963119631196312263122631216311f6311d63118631136310f6310c6310a63108631036310060100001000010000100001000010000100001000010000100001
00050000140000b4000b4000b400054000b4000b4000b4000e4000b4000b4000b400174000b4000b4000b4000b4000b4000c4000c4000c4003040030400004000040000400004000040000400004000040000400
__music__
02 00414344
00 43424344


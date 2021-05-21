pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- BARBARA
-- by FREDERIC LINN

function _init()
  -- the y-offset of the map per stage.
  -- used for getting the correct map tile flags.
  MAP_OFFSETS = {
    ["FORREST"] = 0,
    ["CAVE"] = 16,
  }

  fadedir = 1
  fadepos = 0
  DEBUG_MSG = ""
  -- flag definitions
  f_collision = 0
  f_damage = 1

  SCROLL_SPEED = 0.5
  CURRENT_STATE = "FORREST"
  init_gameloop()
  init_witch()
  init_enemies()
  init_ingredients()

  game_states = {
    ["GAME_OVER"] = {
    update = function()
      if(btn(5)) _init()
    end,
    draw = function()
      cls()
      print("PRESS ❎ TO CONTINUE")
    end
    },

    ["FORREST"] = {
      map_x = 0,
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
      curr_e = {},
      curr_i = {},

      init = function(self)
        self.curr_e = {}
        self.curr_i = {}
        self.map_x = 0
        self.background1_x = 0
        self.background2_x = 0
        self.background3_x = 128
        self.spawn_x = 0
        self.prev_spawn_x = 0
        self.abs_x = 0
        init_enemies()
        init_ingredients()
      end,

      update = update_stage,

      check_next_state = function(self)
        -- check if we reached the end of the forrest
        if (self.spawn_x == 216) change_state("POST_FORREST")
      end,

      update_map = function(self)
        self.map_x -= SCROLL_SPEED
        self.abs_x += SCROLL_SPEED
        self.background1_x -= 0.25
        self.background2_x -= 0.1
        self.background3_x -= 0.05
        -- the foreground map is 4 screens wide
        if (self.map_x <  -128*4) self.map_x = 0
        -- the backgrounds are each 1 screen wide
        if (self.background1_x < -127) self.background1_x = 0
        if (self.background2_x < -127) self.background2_x = 0
        end,

      draw = draw_stage,

      draw_map = function(self)
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
      end
    },

    ["POST_FORREST"] = {
      irisd = -1,
      irisi = 92,
      update = function(self)
        if (self.irisi == 0) change_state("PRE_CAVE")
      end,
      draw = function(self)
        local i, d = iris(self.irisi, self.irisd, 13)
        self.irisi = i
        self.irisd = d
      end
    },

    ["PRE_CAVE"] = {
      irisd = 1,
      irisi = 0,
      init = function(self)
        w.x = 100
        w.y = 60
      end,
      update = function(self)
        if (self.irisi == 92) change_state("CAVE")
      end,
      draw = function(self)
        cls()
        --TODO: Also draw barbara
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
    },

    ["CAVE"] = {
      curr_e = {},
      curr_i = {},
      map_x = 0,
      background1_x = 0,
      spawn_x = 0,
      prev_spawn_x = 0,
      abs_x = 0,

      init = function(self)
        self.curr_e = {}
        self.curr_i = {}
        self.map_x = 0
        self.background1_x = 0
        self.spawn_x = 0
        self.prev_spawn_x = 0
        self.abs_x = 0
        init_enemies()
        init_ingredients()
      end,

      update = update_stage,

      check_next_state = function(self)
        -- if (self.spawn_x == 23) change_state("GAME_OVER")
      end,

      update_map = function(self)
        self.map_x -= SCROLL_SPEED
        self.abs_x += SCROLL_SPEED
        self.background1_x -= 0.1
        -- the foreground map is 2 screens wide
        if (self.map_x < -128*2) self.map_x = 0
        if (self.background1_x < -127) self.background1_x = 0
      end,

      draw = draw_stage,

      draw_map = function(self)
        cls()
        palt(0, false)
        palt(7, true)
        map(64, 16, self.background1_x, 0, 16, 16)
        map(64, 16, self.background1_x + 128, 0, 16, 16)
        map(0, 16, self.map_x, 0, 32, 16)
        map(0, 16, self.map_x + 128 * 2, 0, 32, 16)
        palt()
      end
    },
  }
  change_state("PRE_CAVE")
end


function update_stage(self)
  -- we calculate where the right edge of the screen
  -- would be if we would travel the map continously.
  self.spawn_x = flr(self.abs_x / 8) + 16

  -- add objects only *once* per map tile
  if (self.spawn_x != self.prev_spawn_x) then
    self.prev_spawn_x = self.spawn_x

    foreach(all_e[CURRENT_STATE][self.spawn_x], function(e) add(self.curr_e, e)  end)
    foreach(all_i[CURRENT_STATE][self.spawn_x], function(i) add(self.curr_i, i)  end)
  end

  -- we need the absolute x-coordinate of the map (in pixels)
  -- for collision detection.
  w:update(abs(self.map_x))

  foreach(self.curr_e, function(e) e:update() end)
  foreach(self.curr_i, function(i) i:update() end)

  for e in all(self.curr_e) do
    if (collide(w, e) and w.iframes == 0) then
      sfx(0)
      w.hp -= 1
      if (w.hp <= 0) then
        change_state("GAME_OVER")
      end
      w.iframes = 60
    end
  end

  -- check for ingredient pick ups
  for i in all(self.curr_i) do
    if (collide(w, i)) then
      del(self.curr_i, i)
    end
  end

  self:update_map()
  self:check_next_state()
end

function draw_stage(self)
  self:draw_map()
  foreach(self.curr_e, function(e) e:draw() end)
  foreach(self.curr_i, function(i) i:draw() end)
  w:draw()
  draw_hp()
end

function init_gameloop()
  _update60 = game_update
  _draw = game_draw
end

function game_update()
  game_states[CURRENT_STATE]:update()
end

function game_draw()
  game_states[CURRENT_STATE]:draw()
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
  while i < 3 do
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

    local tmp_x = self.x
    local tmp_y = self.y
    local accel = 0.3
    local friction = 0.9

    if(btn(0)) then
      self.dx -= accel
    elseif(btn(1)) then
      self.dx += accel
    end

    if(btn(2)) then
      self.dy -= accel
    elseif(btn(3)) then
      self.dy += accel
    end

    self.dx *= friction
    self.dy *= friction
    tmp_x += self.dx
    tmp_y += self.dy

    -- we iterate over every map tile that's currently on screen
    -- and see if barbara collides with any of them that have
    -- our collision flag set.
    local map_collision = false
    local x_offset=flr(map_x/8)
    local y_offset = MAP_OFFSETS[CURRENT_STATE]

    for x=0,15 do
      for y=0,15 do
        local t = mget(x + x_offset, y + y_offset)
        local c = fget(t, f_collision)
        if (c) then
          if
            w.x + 6 > x*8 and
            w.y + 6 > y*8 and
            w.x < x*8 + 6 and
            w.y < y*8 + 6
          then
            -- did we also take damage?
            if (fget(t, f_damage)) then
              DEBUG_MSG = "DAMAGE"
            end
            map_collision = true
          end
        end
      end
    end

      -- TODO: Think about the bigger picture here:
      -- Maybe we need the direction of barbara
      -- to push her in the opposite one.
    if (not map_collision) then
      -- reset the velocity if we hit the edges
      if (tmp_x < 0 or tmp_x > 120) then
        self.dx = 0
      end

      if (tmp_y < 0 or tmp_y > 120) then
        self.dy = 0
      end
      -- don't stray outside the screenspace
      self.x = mid(0, tmp_x, 120)
      self.y = mid(8, tmp_y, 120)

    else
      -- we don't want to get stuck
      self.y -= 0.4
      -- TODO: Maybe dust particles?
    end
  end

  local draw_witch = function(self)
    -- make her sprite flicker if she got hit
    if (self.iframes % 2 == 0) then
      spr(self.sprites[self.frame], self.x, self.y)
    end
  end

  w = {
    x = 10,
    y = 50,
    dx = 0,
    dy = 0,
    accel = 0.5,
    sprites = {1, 2, 3},
    tick = 0,
    frame = 1,
    step = 8,
    hp = 3,
    iframes = 0,
    update = update_witch,
    draw = draw_witch,
  }
end

function init_ingredients()
  all_i = {}
  all_i["FORREST"] = {
    [20] = {make_ingredient(15, 80)},
    [30] = {make_ingredient(31, 96)}
  }

  all_i["CAVE"] = {
    [20] = {make_ingredient(15, 80)},
    [30] = {make_ingredient(31, 96)}
  }
end

function update_ingredient(self)
  if (self.x < 0) then
    del(curr_i, self)
  end
  -- change the state ever half a second
  if (self.ticks % 40 == 0) then
    self.highlight =  not self.highlight
  end
  self.x -= SCROLL_SPEED
  self.ticks += 1
end

function draw_ingredient(self)
  spr(self.spr, self.x, self.y)
  if (self.highlight) then
    circ(self.x+4, self.y+4, 8, 8)
  end
end

function make_ingredient(_spr, _y)
  return {
    x = 128,
    y = _y,
    spr = _spr,
    ticks = 0,
    highlight = false,
    update = update_ingredient,
    draw = draw_ingredient
  }
end

function init_enemies()
  all_e = {}
  all_e["FORREST"] = {
    [18] = {make_snake(96, 0.5)},
    [19] = {make_bat(55, 2), make_bat(75, 1)},
    [20] = {make_bird(25, 1.0)},
    [23] = {make_bird(55, 1.0), make_snake(96, 1.0)},
    [30] = {make_bird(55, 1.0)},
    -- [40] = {make_bat(55, 0.75), make_bird(75, 1.0)},
    -- [45] = {make_bat(55, 0.75), make_bird(75, 1.0)},
    -- [49] = {make_bat(55, 0.75), make_bird(75, 1.0)},
    -- [53] = {make_bat(55, 0.75), make_bird(75, 1.0)},
    -- [70] = {make_bat(55, 0.75), make_bird(75, 1.0)},
  }
  all_e["CAVE"] = {
    [40] = {make_bat(55, 0.75)},
    [45] = {make_bat(55, 0.75)},
    [49] = {make_bat(55, 0.75)},
    [53] = {make_bat(55, 0.75)},
    [70] = {make_bat(55, 0.75)},
  }
end

function update_bird(self)
  self.x -= self.speed
  if (self.x < - 8) then del(curr_e, self); return end
  animate(self)

  if (self.y_dir == "UP") then
    self.y -= self.speed
  end

  if (self.y_dir == "DOWN") then
    self.y += self.speed
  end

  if (self.y >= self.base_y + 10 ) then
    self.y_dir = "UP"
  end

  if (self.y <= self.base_y - 10) then
    self.y_dir = "DOWN"
  end
end

function draw_bird(self)
  spr(self.sprites[self.frame], self.x, self.y)
end

function make_bird(_y, _speed)
  return {
    tick = 0,
    frame = 1,
    step = 6,
    sprites = {64, 65, 66},
    base_y = _y,
    -- always spawn just outside the view port
    x = 128,
    y = _y,
    x_dir = 0,
    y_dir = "DOWN",
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

function make_bat(_y, _speed)
  return {
    tick = 0,
    frame = 1,
    step = 6,
    sprites = {80, 81, 82},
    x = 128,
    y = _y,
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

function make_snake(_y, _speed)
  return {
    tick = 0,
    frame = 1,
    step = 12,
    sprites = {96, 97, 98},
    x = 128,
    y = _y,
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
  animate(self)

  if (self.ticks % 60 == 0) then
    local tmp_x = self.x - (flr(rnd(20)) + 10)
    self.x = tmp_x

    local tmp_y
    repeat
      local up = flr(rnd(2))
      local distance = flr(rnd(8))

      if (up == 1) then
        tmp_y = self.y + distance
      else
        tmp_y = self.y - distance
      end
    until (tmp_y > 0 and tmp_y < 128)

    self.y = tmp_y
  end

  self.ticks += 1
end

function draw_ghost(self)
  -- we want solid black!
  palt(0, false)
  palt(15, true)
  spr(self.sprites[self.frame], self.x, self.y)
  palt()
end

function make_ghost(_y)
  return {
    ticks = 0,
    tick = 0,
    frame = 1,
    step = 6,
    sprites = {112, 113, 114},
    x = 128,
    y = _y,
    update = update_ghost,
    draw = draw_ghost
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

function change_state(next_state)
  -- clean up if a function is provided
  if(game_states[next_state].init) then
    game_states[next_state]:init()
  end
  CURRENT_STATE = next_state
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

__gfx__
000000000000eee00000eee00000eee0000000000000000000000000000000000000011100000000000000000000055500000000000000000000000000003000
00000000000eeff000eeeff000eeeff0000000000000000000000000000000000000111c00000000000000000000555600000000000000000000000000014100
0070070000eefff000eefff0000efff000000000000000000000000000000000001111cc00000000000000000055556600000000000000000000000000041400
00077000a0002200a0002200a00022000000000000000000000000000000000000011cc700000000000000000005566000000000000000000000000000014100
00077000aa022220aa022220aa022220000000000000000000000000000000000011ccc700000000000000000055666000000000000000000000000000041400
00000000aaa222faaaa222faaaa222fa00000000000000000000000110000000011ccc7700000005500000000556660000000000000000000000000000004000
00000000aa002200a9002200a900220000000000000000000000000c1100000111cc7c7700000006550000055566060000000000000000000000000000000000
00000000a00f2000900f2000a00f20000000000000000000000000ccc1000011ccc7777700000066650000556660000000000000000000000000000000000000
000000000000000000000000000000000000000000000111ccc00000110001c11c77777766600000550005655600000000000000000000000000000000000000
00000000000000000000000000000000000000000000111c11cc0c00c10001cccc77777755660600650005666600000000000000000000000000000000888700
0000000000000000000000000000000000000000001111cc711ccc00c11011c7c777777705566600655055606000000000000000000000000000000008878880
000000000000000000000000000000000000000000011cc07711ccc0cc101cc77777777700556660665056600000000000000000000000000000000087888788
00000000000000000000000000000000000000000011ccc077711cc07c111c777777777700055660065556000000000000000000000000000000000000077000
0000000000000000000000000000000000000000011ccc00771111cc7c111c777777777700555566065556000000000000000000000000000000000000077000
000000000000000000000000000000000000000011cc0c007777111c77c1cc777777777700005556006566000000000000000000000000000000000000077000
0000000000000000000000000000000000000000ccc0000077777111777cc7777777777700000555000660000000000000000000000000000000000000077000
0000000000000000000000000000000000000000ccc0000077777777777cc7771117777700000000000660005550000000000000000000000000000000000000
000000000000000000000000000000000000000011cc0c007777777777cc1c77c111777700000000006656006555000000000000000000000000000000000000
0000000000000000000000000000000000000000011ccc007777777777c111c7cc11117700000000006555606655550000000000000000000000000000000000
00000000000000000000000000000000000000000011ccc07777777777c111c70cc1177700000000006555600665500000000000000000000000000000000000
000000000000000000000000000000000000000000011cc0777777777cc101cc0ccc117700000000066505660666550000000000000000000000000000000000
0000000000000000000000000000000000000000001111cc7777777c7c11011c00ccc11700000006065505560066655000000000000000000000000000000000
00000000000000000000000000000000000000000000111c777777cccc10001c00c0cc1100000066665000560060665500000000000000000000000000000000
000000000000000000000000000000000000000000000111777777c11110001100000ccc00000065555000550000066600000000000000000000000000000000
f00f00fff00f00ff00000000000000000000000000000ccc77777ccc1100001ccc00000000000666550000566600000000000000000000000000000000000000
0880880f0660660f00000000000000000000000000c0cc1177c7cc1110000011c000000000606655500000556000000000000000000000000000000000000000
0888e80f0666760f00000000000000000000000000ccc11077ccc110000000011000000000666550000000055000000000000000000000000000000000000000
0888880f0666660f0000000000000000000000000ccc11007ccc1100000000000000000006665500000000000000000000000000000000000000000000000000
f08880fff06660ff0000000000000000000000000cc110007cc11000000000000000000006655000000000000000000000000000000000000000000000000000
ff080fffff060fff000000000000000000000000cc111100cc111100000000000000000066555500000000000000000000000000000000000000000000000000
fff0fffffff0ffff000000000000000000000000c1110000c1110000000000000000000065550000000000000000000000000000000000000000000000000000
ffffffffffffffff0000000000000000000000001110000011100000000000000000000055500000000000000000000000000000000000000000000000000000
00111000001110000011100000000000000000000000000000000000000000000000000000000000000000000000000044404440444000033300044404440444
01661001016610010166100100000000000000000000000000000000000000000000000000000000000000000000000044404440444400033300444404440444
96576116965761169657611600000000000000000000000000000000000000000000000000000000000000000000000044444444444440333304444444444444
01666666016666660166666600000000000000000000000000000000000000000000000000000000000000000000000044444444444440333304444444444444
00111111001116110011166100000000000000000000000000000000000000000000000000000000000000000000000004444444444493399339444444444440
00011610000011610000111600000000000000000000000000000000000000000000000000000000000000000000000000444444449933339333994444444400
00001610000001160000001100000000000000000000000000000000000000000000000000000000000000000000000000000000099333339333399000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000993333339933399900000000
77777777777070777770707700000000000000000000000000000000000000000000000000000000000000000000000000000009993333399933333990000000
77777777707808707778087700000000000000000000000000000000000000000000000000000000000000000000000000000099999333399933339999000000
77707077700000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000999999933999933339999900000
70780870700000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000999999999999993339999900000
70000000777000777070007000000000000000000000000000000000000000000000000000000000000000000000000000000990999999999999339909900000
70000000777707777777077700000000000000000000000000000000000000000000000000000000000000000000000000009990000999999999990009990000
70700070777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000009999000000999990000009990000
77770777777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000009999000000099900000099990000
77bbbbb77bbbbb777bbbbb7700000000000000000000000000000000000000000000000000000000000000000000000000559999900000099900000999995500
7bb0b0b3bb0b0b37bb0b0b3700000000000000000000000000000000000000000000000000000000000000000000000005559999990000099900000999995550
7bebbbe3bebbbe37bebbbe3700000000000000000000000000000000000000000000000000000000000000000000000055559999999900090900009999995555
77b333377b3333777b33337700000000000000000000000000000000000000000000000000000000000000000000000055509999999999900099999999995555
77bb0b7777bb0b777bb0b77700000000000000000000000000000000000000000000000000000000000000000000000055500999999999000009999999900555
7bb0bb377bb0bb37bb0bb37700000000000000000000000000000000000000000000000000000000000000000000000050500999999999000009999999900505
73b3333b73b3333b3b3333b700000000000000000000000000000000000000000000000000000000000000000000000000000999099999999999999099900000
77bbbbb377bbbbb37bbbbb3700000000000000000000000000000000000000000000000000000000000000000000000000000099000000009000000099000000
77777fff77777fff77777fff00000000000000000000000000000000000000000000000000000000000000000000000000000009900000000000000990000000
777777ff777777ff777777ff00000000000000000000000000000000000000000000000000000000000000000000000000000000990000000000009900000000
070077ff070077ff070077ff00000000000000000000000000000000000000000000000000000000000000000000000000000000099009000090099000000000
7777777f0700777f777777ff00000000000000000000000000000000000000000000000000000000000000000000000000000000059999999999995000000000
7777777777777777777777ff00000000000000000000000000000000000000000000000000000000000000000000000000000000550099999999055500000000
788e7777788e7777788e777f00000000000000000000000000000000000000000000000000000000000000000000000000000005555500000000555550000000
f7777777788e7777f777777700000000000000000000000000000000000000000000000000000000000000000000000000000050505050000005050505000000
fff77777f7777777fff7777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000005500000000000000660000000888888888888b8883b888888cccccccccccccccc0000000000000000000000000000000000000aaaaaaa000000000000
000000555500000000000066660000008888888188883888b3888888cc111c1111c111cc00000000000000000000000000000000000aaaaaaaaaaa0000000000
00000555555000000000066666600000888888138183b3881b388888cc151115511151cc000000000000000000000000000000000aaaa777aaaaaaa600000000
000055555555000000006666666600008888813b88333b83b3b38888cc155555555551cc00000000000000000000000000000000aaa7777aaaa6aaaa60000000
0005555555555000000666666666600088881313881333b8113b8888cc155115511551cc0000000000000000000000000000000aa77777aaaaaaaaaa66000000
00555555555555000066666666666600888131b888113b38b3b3b8881111511551151111000000000000000000000000000000aa77777aaaaaaaaaaaa6600000
055555555555555006666666666666608883b1818133338338313888155151111115155100000000000000000000000000000aa7777a77aaaaaaaaaaaa660000
55555555555555556666666666666666881b81331331133b13183b88155111155111155100000000000000000000000000000a7777aaaaaaa66aaaaa6a660000
0000000770000000cccccccddccccccc888888833131333b3b88888815d55555555555510000000000000000000000000000aa777aaaaaa666666aaaaaaa6000
0000007777000000ccccccddddcccccc8888813131133b33b3b888881555551111555d510000000000000000000000000000a7777777aa6666776aaaaa6a6000
0000077777700000cccccddddddccccc88881313133333bb1b3b88881555d111111555510000000000000000000000000000a77777aaaa666777aaaaa6a66000
0000777777770000ccccddddddddcccc8831313b333b1333b3b3b388155551111115d551000000000000000000000000000aa77aaaaaa66666aaaaaaaa6aa600
0007777777777000cccddddddddddccc831313133133333b113b3b381d55511111155551000000000000000000000000000aa77aa77aaaaaaaaaaaaa6aaa6600
0077777777777700ccddddddddddddcc8131313b333bb3b3b3b3b3b8155d511111155d51000000000000000000000000000aa777777aaaaaaaaaaaaaaa666600
0777777777777770cddddddddddddddc3813b1b11333bb333b3133331555511111155551000000000000000000000000000aa777aaaaaaaaaaaaaaaa6aa66600
7777777777777777dddddddddddddddd1b1b8133138333bb13183b8b1111111111111111000000000000000000000000000aa777aaaaaaaaaaaaaaaaaaa66600
555555556666666677777777dddddddd0000000088144488000000000000000000000000000000000000000000000000000a777aaaaa666666aaaaa6aa6a6600
555555556666666677777777dddddddd0000000088141488000000000000000000000000000000000000000000000000000aaaaaaaa6666aa666aaaa66a66600
555555556666666677777777dddddddd0000000088414488000000000000000000000000000000000000000000000000000aaa6aaaa666aa7766a6a666666000
555555556666666677777777dddddddd00000000881441880000000000000000000000000000000000000000000000000000aaaaaaa66aa777a6aa6a66a66000
555555556666666677777777dddddddd00000000881444880000000000000000000000000000000000000000000000000000aa777aa66a777aaaaa6a6a666000
555555556666666677777777dddddddd000000008841448800000000000000000000000000000000000000000000000000000a777aaa6666aaaaa6a6aa660000
555555556666666677777777dddddddd000000008811148800000000000000000000000000000000000000000000000000000aaa7a7aaaaaaaaaaa66a6660000
555555556666666677777777dddddddd0000000088144488000000000000000000000000000000000000000000000000000000aa7777aaaaaaa66aa666600000
4777777433bbb3b3444444440000000000000000881441880000000000000000000000000000000000000000000000000000000aaaa7aaaa6aaa66a666000000
70070077b33b3b3b4444449400000000000000008814448800000000000000000000000000000000000000000000000000000000aaa7aaaaa66a666660000000
70070077333b33b344444444000000000000000088414188000000000000000000000000000000000000000000000000000000000aaaaaa6aa6a666600000000
77777777434433b44444944400000000000000008814448800000000000000000000000000000000000000000000000000000000000aaaaaa666660000000000
7770777444443444944444440000000000000000814444180000000000000000000000000000000000000000000000000000000000000aaa6666000000000000
47777749444444494444494400000000000000008441414100000000000000000000000000000000000000000000000000000000000000000000000000000000
47070744449444444444444400000000000000004111444400000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000001881414100000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000000272700000000002727000036101010381035282736372800002727000000000000000000000000000000000000000000000000000000000000000000003900000000003a2b393a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2627363710280026273637102836253810101035101010101035283637372800000000000000000000000000000000000000000000000000000000000000000000000000000000392b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3625371010372836253710103710101010101010101010101010371010103528000000000000000000000000000000000000000000000000000000000000000000000000000039000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2510101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000156002f60035600326002e6002b600296002760024600236002360023600236001d60025600166000a600026000060000600006000160003600056000a600095000e6001260016600226000050000000

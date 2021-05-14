pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- BABARA
-- by GEBIRGE
function _init()
  game_init()
  DEBUG_MSG = ""
  SCROLL_SPEED = 0.5
  -- flag definitions
  f_floor = 0
  -- a negative position scrolls the map
  scroll_x = 0
  -- the current position on the map (in tiles, not pixels)
  -- takes scrolling into account.
  -- used for spawning enemies at specific points.
  spawn_x = 0
  prev_spawn_x = 0
  init_witch()
  init_enemies()
end

function game_init()
  _update60 = game_update
  _draw = game_draw
end

function menu_init()
  _update60 = menu_update
  _draw = menu_draw
end


function game_update()
  -- we calculate where the right edge of the screen
  -- would be if we would travel the map continously.
  spawn_x = flr(abs(scroll_x) / 8) + 16

  -- add enemies only *once* per map tile
  if (spawn_x != prev_spawn_x) then
    prev_spawn_x = spawn_x
    foreach(all_e[spawn_x], function(e) add(curr_e, e)  end)
  end

  w:update()
  foreach(curr_e, function(e) e:update() end)

  for e in all(curr_e) do
    if (collide(w, e) and w.iframes == 0) then
      sfx(0)
      w.hp -= 1
      w.iframes = 60
    end
  end

  update_map()
end

function game_draw()
  draw_map()
  foreach(curr_e, function(e) e:draw() end)
  w:draw()
  draw_hp()
  print(DEBUG_MSG)
end

-- updating
function update_map()
  scroll_x -= SCROLL_SPEED
end

-- drawing
function draw_map()
  cls(2)
  -- draw the moon
  map(0, 0, 90, 9, 8, 8)
  -- map(0, 0, 0, 9, 16, 16)
  map(0, 4, scroll_x, 4*8)
end

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
  local update_witch = function(self)
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

    tile = mget((tmp_x + 1) / 8, (tmp_y + 7) / 8)
    is_floor = fget(tile, f_floor)

    if (not is_floor) then
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
      self.y -= 0.2
      -- TODO: Maybe dust particles?
    end
  end

  local draw_witch = function(self)
    spr(self.sprites[self.frame], self.x, self.y)
  end

  w = {
    x = 10,
    y = 10,
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


function init_enemies()
  curr_e = {}

  all_e = {
    [20] = {make_bird(25, 0.5)},
    [23] = {make_bird(55, 0.5), make_bird(75, 1.0)},
    [30] = {make_bird(55, 0.5)},
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

-- utilities
function animate(self)
  self.tick=(self.tick+1)%self.step --tick fwd
  if (self.tick==0) self.frame=self.frame%#self.sprites+1
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

__gfx__
000000000000eee00000eee00000eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000eeff000eeeff000eeeff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000eefff000eefff0000efff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000a000cc00a000cc00a000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aa0cccc0aa0cccc0aa0cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaacccfaaaacccfaaaacccfa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aa00cc00a900cc00a900cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000a00fc000900fc000a00fc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f00f00fff00f00ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0880880f0660660f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0888e80f0666760f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0888880f0666660f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f08880fff06660ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff080fffff060fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff0fffffff0ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001110000011100000111000011c1100000000000000000000000000000000000000000000000000000000000000000044404440444000033300044404440444
01cc100101cc100101cc10011c1c1c10000000000000000000000000000000000000000000000000000000000000000044404440444400033300444404440444
9c07c11c9c07c11c9c07c11c1c1c1c10000000000000000000000000000000000000000000000000000000000000000044444444444440333304444444444444
01cccccc01cccccc01cccccc01cc1c10000000000000000000000000000000000000000000000000000000000000000044444444444440333304444444444444
0011111100111c1100111cc1001ccc10000000000000000000000000000000000000000000000000000000000000000004444444444493399339444444444440
00011c10000011c10000111c0001c110000000000000000000000000000000000000000000000000000000000000000000444444449933339333994444444400
00001c100000011c0000001100001100000000000000000000000000000000000000000000000000000000000000000000000000099333339333399000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000993333339933399900000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009993333399933333990000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099999333399933339999000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000999999933999933339999900000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000999999999999993339999900000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000990999999999999339909900000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009990000999999999990009990000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999000000999990000009990000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999000000099900000099990000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000559999900000099900000999995500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005559999990000099900000999995550
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055559999999900090900009999995555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055509999999999900099999999995555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055500999999999000009999999900555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050500999999999000009999999900505
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000999099999999999999099900000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099000000009000000099000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009900000000000000990000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000990000000000009900000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099009000090099000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000059999999999995000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000550099999999055500000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555500000000555550000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050505050000005050505000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaa000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaaaaa0000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa777aaaaaaa600000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaa7777aaaa6aaaa60000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa77777aaaaaaaaaa66000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa77777aaaaaaaaaaaa6600000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa7777a77aaaaaaaaaaaa660000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a7777aaaaaaa66aaaaa6a660000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa777aaaaaa666666aaaaaaa6000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a7777777aa6666776aaaaa6a6000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a77777aaaa666777aaaaa6a66000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa77aaaaaa66666aaaaaaaa6aa600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa77aa77aaaaaaaaaaaaa6aaa6600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa777777aaaaaaaaaaaaaaa666600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa777aaaaaaaaaaaaaaaa6aa66600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa777aaaaaaaaaaaaaaaaaaa66600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a777aaaaa666666aaaaa6aa6a6600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaa6666aa666aaaa66a66600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaa6aaaa666aa7766a6a666666000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaa66aa777a6aa6a66a66000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa777aa66a777aaaaa6a6a666000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a777aaa6666aaaaa6a6aa660000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaa7a7aaaaaaaaaaa66a6660000
447777440b30003094494444000000000000000000000000000000000000000000000000000000000000000000000000000000aa7777aaaaaaa66aa666600000
4777777403b0b333444444440000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa7aaaa6aaa66a666000000
70070077b33b3b304444449400000000000000000000000000000000000000000000000000000000000000000000000000000000aaa7aaaaa66a666660000000
70070077333b33b344444444000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaa6aa6a666600000000
77777777434433b44444944400000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaa666660000000000
7770777444443444944444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaa6666000000000000
47777749444444494444494400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
47070744449444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
8c8d8e8f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9c9d9e9f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
acadaeaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bcbdbebf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1
b2b0b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0b2b2b2b2b2b2b2b2b2b2b2b2b2
b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b0
__sfx__
00010000000003905024050200502f0502f0502e0502d0502c0502b0502a05029050280502805027050250500000024050220500e050200501f0501d0501c0501a05018050170500000000000000000000000000

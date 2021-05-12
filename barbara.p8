pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- BABARA
-- by GEBIRGE
function _init()
  game_init()
  DEBUG_MSG = ""
  SCROLL_SPEED = 1
  -- flag definitions
  map_x = 0
  init_witch()
end

function _update60()
end

function _draw()
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
  w:update()
end

function game_draw()
  cls(2)
  map()

  w:draw()
  draw_hp()
end


-- drawing
function draw_hp()
  -- set the right colors to transparent
  palt(0, false)
  palt(15, true)

  -- first draw the full hearts.
  local i = 0
  while i < w.hp do
    spr(48, i * 8 + 1, 1)
    i += 1
  end

  -- then draw the empty ones.
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

  end

  local draw_witch = function(self)
    spr(self.sprites[self.frame], 10, 10)
  end

  w = {
    sprites = {1, 2, 3},
    tick = 0,
    frame = 1,
    step = 6,
    hitbox = {x = 0, y = 0, w = 8, h = 8},
    hp = 3,
    iframes = 0,
    update = update_witch,
    draw = draw_witch,
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
  -- take their respective hitboxes into consideration
  if
    obj1.x+obj1.hitbox.x+obj1.hitbox.w > obj2.x+obj2.hitbox.x and
    obj1.y+obj1.hitbox.y+obj1.hitbox.h > obj2.y+obj2.hitbox.y and
    obj1.x+obj1.hitbox.x < obj2.x+obj2.hitbox.x+obj2.hitbox.w and
    obj1.y+obj1.hitbox.y < obj2.y+obj2.hitbox.y+obj2.hitbox.h
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
f00f00fff00f00ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0880880f0660660f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0888e80f0666760f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0888880f0666660f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f08880fff06660ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff080fffff060fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff0fffffff0ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
47777744444444444444494400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
47070749444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

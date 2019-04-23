pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function init_parallax()
	--tables to hold map pieces
	map_bg={} --bg layer 1
	map_mg={}	--mg layer 2
	map_fg={} --fg layer 3

	--spawn initial map. index i
	--creates copy of map at right
	--of screen, ready to move into
	--view.
	for i=0,1 do
		spawn_map(i*128,0,1)
		spawn_map(i*128,0,2)
		spawn_map(i*127,0,3)
	end
end

function update_parallax()
	foreach(map_bg,update_map)
	foreach(map_mg,update_map)
	foreach(map_fg,update_map)
end

function draw_parallax()
		foreach(map_bg,draw_map)
		foreach(map_mg,draw_map)
		foreach(map_fg,draw_map)
end

function update_map(m)
	m.x-=m.l --move map to left

	--if map off edge of screen
	if m.x<-126 then
		if m.l==1 then
			del(map_bg,m) --delete map
		end
		if m.l==2 then
			del(map_mg,m) --delete map
		end
		if m.l==3 then
			del(map_fg,m)
		end
		--add new map to right
		spawn_map(16*8,0,m.l)
	end
end

function spawn_map(x,y,l)
	local m={}
	m.x=x
	m.y=y
	m.l=l
	--add map bit to correct layer
	if l==1 then
		add(map_bg,m)
	end
	if l==2 then
		add(map_mg,m)
	end
	if l==3 then
		add(map_fg,m)
	end
end

function draw_map(m)
	if m.l==1 then
		map(0,0,m.x,m.y,16,16)
	end
	if m.l==2 then
		map(16,0,m.x,m.y,16,16)
	end
	if m.l==3 then
		map(32,0,m.x,m.y,16,16)
	end
end

-- scroll screen r->l

function translate_screen()
	if isgrid1 then
		thegrid = grid1
	else
		thegrid = grid2
	end
	for row in all(thegrid) do
		del(row, row[1])
		add(row, 0)
	end
end

-->8
-- player

function make_player()
 p = {} -- start player table
 p.x = 4  --position
 p.y = 63
 p.dx = 0 -- potential acceleration
 p.dy = 0 -- value
 p.sprite = 1
 p.health = phealthmax
 p.treatment = ptreatmax
 p.alive = true
 p.took_dmg = false
 p.points = 0
 p.thrust = 0.075 -- potential thrust value
end

function draw_player()
	if p.took_dmg then
		if mod(ctr, dmg_brate) == 0 then
			spr(64,p.x,p.y)
		elseif mod(ctr, dmg_brate+1) == 0 then
			spr(p.sprite+17,p.x,p.y)
		else
			spr(p.sprite,p.x,p.y)
		end
		blink_frames += 1
		if blink_frames > max_blink then
			blink_frames = 0
			p.took_dmg = false
		end
	else
		spr(p.sprite,p.x,p.y)
	end
end

function move_player()
 if (btn(⬅️)) then
  p.x -= 1.1*ship_mov_speed --left
  p.sprite = 1
 end

 if (btn(➡️)) then
  p.x += 1.3*ship_mov_speed --right
  p.sprite = 4
 end

 if (btn(⬆️)) then
  p.y -= ship_mov_speed --up
 	p.sprite = 2
 end

 if (btn(⬇️)) then
  p.y += ship_mov_speed --down
  p.sprite = 3
 end

 if (btn(❎)) and ctr - last_bull > fire_rate then
 	make_bullet()
 	sfx(04)
 	last_bull = ctr
 end

	stay_on_screen()
	check_e_collision()
end

function stay_on_screen()
	if (p.x<0) then --left bound
 	p.x = 0
	end
	if (p.x>119) then --right bound
 	p.x = 119
	end
	if (p.y<0) then --top bound
 	p.y = 0
	end
	if (p.y>119) then --bottom bound
	 p.y = 119
	end
end

function check_e_collision()
 	if isgrid1 then
	 	thegrid = grid1
 	else
	 	thegrid = grid2
	 end

		i = flr(p.x/chunk_size)+1
		j = flr((p.y-uih)/chunk_size)+1

		if i > 0 and i < n_chunks and j > 0 and j < n_chunks then
			if thegrid[j][i] == 1 then
				sfx(06)
				frames_in_e += 1
				p.took_dmg = true
				if frames_in_e > frames_to_d then
					p.health -= enemy_dmg
				end
			else -- got out of enemy, so stop the "countup"
				frames_in_e = 0
			end
	 end
end
-->8
-- game of life

uih = 16
boh = 16

bombs = {}
grid1 = {}
grid2 = {}
value_grid = {}
currentgrid = {}
nextgrid = {}
isgrid1 = true
chunk_size = 3
gridy = flr((128-uih-boh)/chunk_size)
gridx = flr(128/chunk_size)
chunk = chunk_size
n_chunks = gridy

---------

function empty_life()
 for i = 1, gridy do
  grid1[i] = {}
  grid2[i] = {}
  value_grid[i] = {}

  for j = 1, gridx do
   grid1[i][j] = 0 -- intialise all as dead to start
   grid2[i][j] = 0
   value_grid[i][j] = 0
  end
 end

 currentgrid = grid1
 nextgrid = grid2
end

---------

function choose_life()
 life_option = flr(rnd(4))
 -- life_option = 0 -- hardcoded for debugging
 spawn_x = flr(gridx/2+rnd(16)) -- how many chunks to the right life will spawn
	spawn_y = 5+flr(rnd(gridy-12))
end

---------

function spawn_bomb()
 local b = {}
 b.init = ctr -- global frame counter
 add(bombs, b)
 -- set/reset counter to next spawn
 spawn_wait = spawn_wait_min+flr(rnd(spawn_wait_max-spawn_wait_min))
	last_spawn = ctr
	more_life = false
end

---------

function check_spawn()
	if (ctr > last_spawn+spawn_wait) then
		more_life = true
	end
end

---------

function spawn_life()
	if isgrid1 then
		thegrid = grid1
	else
		thegrid = grid2
	end
 -- 3x3 glider
 if (life_option==0) then
  thegrid[0+spawn_y][0+spawn_x] = 0
	 thegrid[1+spawn_y][0+spawn_x] = 1
	 thegrid[2+spawn_y][0+spawn_x] = 0
	 thegrid[0+spawn_y][1+spawn_x] = 0
	 thegrid[1+spawn_y][1+spawn_x] = 0
	 thegrid[2+spawn_y][1+spawn_x] = 1
  thegrid[0+spawn_y][2+spawn_x] = 1
	 thegrid[1+spawn_y][2+spawn_x] = 1
	 thegrid[2+spawn_y][2+spawn_x] = 1
	-- 3x3 inverted t
 elseif (life_option==1) then
  thegrid[0+spawn_y][0+spawn_x] = 0
	 thegrid[1+spawn_y][0+spawn_x] = 1
	 thegrid[2+spawn_y][0+spawn_x] = 0
	 thegrid[0+spawn_y][1+spawn_x] = 0
	 thegrid[1+spawn_y][1+spawn_x] = 1
	 thegrid[2+spawn_y][1+spawn_x] = 0
  thegrid[0+spawn_y][2+spawn_x] = 1
	 thegrid[1+spawn_y][2+spawn_x] = 1
	 thegrid[2+spawn_y][2+spawn_x] = 1
	-- 3x4 inverted t
 elseif (life_option==2) then
		thegrid[0+spawn_y][0+spawn_x] = 0
	 thegrid[1+spawn_y][0+spawn_x] = 1
	 thegrid[2+spawn_y][0+spawn_x] = 0
	 thegrid[0+spawn_y][1+spawn_x] = 0
	 thegrid[1+spawn_y][1+spawn_x] = 1
	 thegrid[2+spawn_y][1+spawn_x] = 0
  thegrid[0+spawn_y][2+spawn_x] = 0
	 thegrid[1+spawn_y][2+spawn_x] = 1
	 thegrid[2+spawn_y][2+spawn_x] = 0
  thegrid[0+spawn_y][3+spawn_x] = 1
	 thegrid[1+spawn_y][3+spawn_x] = 1
	 thegrid[2+spawn_y][3+spawn_x] = 1
	-- 3x4 "small exploder"
 elseif (life_option==3) then
  thegrid[0+spawn_y][0+spawn_x] = 0
	 thegrid[1+spawn_y][0+spawn_x] = 1
	 thegrid[2+spawn_y][0+spawn_x] = 0
	 thegrid[0+spawn_y][1+spawn_x] = 1
	 thegrid[1+spawn_y][1+spawn_x] = 1
	 thegrid[2+spawn_y][1+spawn_x] = 1
  thegrid[0+spawn_y][2+spawn_x] = 1
	 thegrid[1+spawn_y][2+spawn_x] = 0
	 thegrid[2+spawn_y][2+spawn_x] = 1
  thegrid[0+spawn_y][3+spawn_x] = 0
	 thegrid[1+spawn_y][3+spawn_x] = 1
	 thegrid[2+spawn_y][3+spawn_x] = 0
 else -- 2x2 stable config for debugging
  thegrid[0+spawn_y][0+spawn_x] = 1
  thegrid[0+spawn_y][1+spawn_x] = 1
		thegrid[1+spawn_y][0+spawn_x] = 1
  thegrid[1+spawn_y][1+spawn_x] = 1
 end
end

function getnumneighbors(x, y)
 local result = 0
 local minx
 local miny
 local maxx
 local maxy
 -- check all neighbours are valid cells
 if (x-1 > 0) and (x+1 < gridx) and (y-1 > 1) and (y+1 < gridy) then
  minx = x-1
  maxx = x+1
  miny = y-1
  maxy = y+1
 	-- top left
  result = result+currentgrid[miny][minx]
  -- top middle
  result = result+currentgrid[miny][x]
  -- top right
  result = result+currentgrid[miny][maxx]
  -- left
  result = result+currentgrid[y][minx]
  -- right
  result = result+currentgrid[y][maxx]
  -- bottom left
  result = result+currentgrid[maxy][minx]
  -- bottom middle
  result = result+currentgrid[maxy][x]
  -- bottom right
  result = result+currentgrid[maxy][maxx]
 else
  -- border cells will die
 	result = 0
 end
 return result
end

---------

function update_life()
 if (isgrid1) then
  currentgrid = grid1
  nextgrid = grid2
 else
  currentgrid = grid2
  nextgrid = grid1
 end

 for i = 1, gridy do
  for j = 1, gridx do
   local numneighbors = getnumneighbors(j, i)
   -- currently live--
   if (currentgrid[i][j] == 1) then
   -- under population --
    	if (numneighbors < 2) then
     	nextgrid[i][j] = 0

    		-- live on --
    		elseif (numneighbors == 2 or numneighbors == 3) then
     		nextgrid[i][j] = 1

    		-- overpopulation --
    		elseif (numneighbors > 3) then
     		nextgrid[i][j] = 0
   		 end

    -- currently dead --
    else
     -- reproduction --
     if (numneighbors == 3) then
      if (i == 5 and j == 5) then
      end -- ks - what do these 2 previous lines do?
      nextgrid[i][j] = 1

      -- stays dead --
    	else
      nextgrid[i][j] = 0
     end
    end
   end
  end
 	isgrid1 = not isgrid1
end

function update_value()
	if isgrid1 then
		thegrid = grid1
	else
		thegrid = grid2
	end
	for i = 1, gridy do
  for j = 1, gridx do
  	if (thegrid[i][j]==1) then
  		value_grid[i][j] = 3
  	elseif (value_grid[i][j] > 0) then
			 value_grid[i][j] -= 1
  	end
  end
 end
end
---------

function update_bombs()
 for b in all(bombs) do
  if ctr-b.init==0 then
   -- draw first sprite
   b.sprite = 5
  elseif ctr-b.init==15 then
   -- drawn second sprite
   b.sprite = 6
  elseif ctr-b.init==30 then
   -- draw third sprite
   b.sprite = 7
  elseif (ctr-b.init > 40) then
   del(bombs,b)
	 sfx(05)
   spawn_life()
  end
 end
end

---------

function draw_bombs()
 for b in all(bombs) do
   spr(b.sprite,spawn_x*chunk,spawn_y*chunk+uih)
 end
end

function draw_life()
 for i = 1, gridy do
  for j = 1, gridx do
   --if currentgrid[i][j] == 1 then
   if (value_grid[i][j] > 0) then
    if value_grid[i][j] == 3 then
     spr(22,j*chunk, i*chunk+uih)
     --rectfill(i*chunk, j*chunk, i*chunk+chunk, j*chunk+chunk, 1)
    elseif value_grid[i][j] == 2 then
     spr(23,j*chunk, i*chunk+uih)
     --rectfill(i*chunk, j*chunk, i*chunk+chunk, j*chunk+chunk, 2)
				elseif value_grid[i][j] == 1 then
     spr(24,j*chunk, i*chunk+uih)
     --rectfill(i*chunk, j*chunk, i*chunk+chunk, j*chunk+chunk, 13)
			 end
   end
  end
 end
end
-->8
-- main loop

function _init()
	opening_init()
end

-- opening
game_name = "d-kay"
team_name = "by rasterz"
member_names = {"lup1n", "tinyrobots", "intox8907"}
opening_dur = 40
jitter_size = 0
pi = 22/7

function opening_init()
	music(13)
	_update=opening_update
	_draw=opening_draw
end

function opening_update()
	if (btnp(❎)) then
		game_init()
	end
end

function jitter(jitter_size)
	for y = 0, 127 do
		for x = 0, 126 do
			nextx = x+flr(jitter_size*rnd())
			if nextx > 127 then
				nextx = 126
			end
			c = pget(nextx, y)
			pset(x, y, c)
		end
	end
end

function opening_draw()
	cls()
	rectfill(0,0,128,128,14)
	if ctr < opening_dur then
		print(game_name,64-flr(#game_name*3/2),53,7)
		print(team_name,64-flr(#team_name*3/2),59,7)

		if ctr > opening_dur/2 then
			jitter(jitter_size)
			jitter_size += 1
		end
	elseif ctr < opening_dur*2 then
		name = member_names[1]
		print(name,64-flr(#name*3/2),59,7)

		if ctr > opening_dur+opening_dur/2 then
			jitter(jitter_size)
			jitter_size += 1
		end
	elseif ctr < opening_dur*3 then
		name = member_names[2]
		print(name,64-flr(#name*3/2),59,7)

		if ctr > opening_dur*2+opening_dur/2 then
			jitter(jitter_size)
			jitter_size += 1
		end
	elseif ctr < opening_dur*4 then
		name = member_names[3]
		print(name,64-flr(#name*3/2),59,7)

		if ctr > opening_dur*3+opening_dur/2 then
			jitter(jitter_size)
			jitter_size += 1
		end
	elseif ctr < opening_dur*5 then
		name = "press ❎ to start"
		print(name,64-flr(#name*3/2),59,7)
	end

	ctr += 1

	if mod(ctr, opening_dur) == 0 then
		jitter_size = 0
	end
end

function game_init()
	music(0)
	end_stage_music_started = false
	spawn_wait_min = 60
	spawn_wait_max = 90
	init_parallax()
	empty_life()
	make_player()
	choose_life()
	last_spawn = ctr
	spawn_wait = 45
	sfx(09)
	_update=game_update
	_draw=game_draw
end

function game_update()
	if p.treatment < 20*30 then
		if not end_stage_music_started then
			music(-1)
			music(16)
			end_stage_music_started = true
		end
		spawn_wait_min = 5
		spawn_wait_max = 10
	elseif p.treatment < 60*30 then
		spawn_wait_min = 15
		spawn_wait_max = 30
	elseif p.treatment < 80*30 then
		spawn_wait_min = 30
		spawn_wait_max = 60
	end

	if mod(ctr, e_translate_spd) == 0 then
		translate_screen()
	end
	p.sprite = 1
	move_player()
	move_bullets()
	if mod(ctr, e_translate_spd) == 0 then
		check_spawn()
		if more_life == true then
		 choose_life()
		 sfx(09)
	 	spawn_bomb()
		end
		update_life()
		update_value()
	end
	update_bombs()
	update_parallax()

	p.treatment -= 1
end

function game_draw()
	cls()
	rectfill(0,0,128,128,14)

	--draw static far bg starfield,
	--drawn twice with offset for
	--variation from parallax bg
	map(0,0,0,-64,16,16)
	map(0,0,0,64,16,16)
	draw_parallax()
	print(p.points,127-10,2,7)
	draw_health_bar()
	draw_treatment()
	draw_bullets()
	draw_life()
	draw_player()
	draw_bombs()

	if p.health <= 0 or p.treatment <= 0 then
		death_init()
	end

	-- print(thegrid[1][20],2,127-10,7)

	ctr += 1
end

function death_init()
 time_of_death = time()
 music(-1)
	music(10)
	death_ctr = 0
	_update=death_update
	_draw=death_draw
end

function death_update()
	jitter_size += 1
	if death_ctr > 35 and (btnp(❎)) then
		game_init()
	end
end

function death_draw()
	if death_ctr < 25 then
		jitter(jitter_size)
	else
		msg = "treatment over"
		points = "infection clear: "..tostr(p.points)
		restart = "press ❎ to retry"
		print(msg,64-flr(#msg*3/2),64)
		print(points,64-flr(#points*3/2),64+7)
		if death_ctr > 35 then
			print(restart,64-flr(#restart*3/2),64+14)
		end
	end
	death_ctr += 1
end
-->8
-- bullets

bullets = {}

function make_bullet()
	local b = {}
	b.x = p.x + 4
	b.y = p.y + 3
	b.dmg = 3
	b.spd = 4
	b.has_hit = false
	add(bullets, b)
end

function move_bullets()
	if isgrid1 then
		thegrid = grid1
	else
		thegrid = grid2
	end
	for b in all(bullets) do
		b.x += b.spd
		i = flr(b.x/chunk_size)+1
		j = flr((b.y-uih)/chunk_size)
		if i > 0 and i <= n_chunks and j > 0 and j <= n_chunks then
			if thegrid[j][i] == 1 then
				thegrid[j][i-1] = 0
				thegrid[j-1][i-1] = 0
				thegrid[j+1][i-1] = 0
				thegrid[j][i] = 0
				thegrid[j-1][i] = 0
				thegrid[j+1][i] = 0
				thegrid[j+1][i+1] = 0
				thegrid[j+1][i+1] = 0
				thegrid[j+1][i+1] = 0
				sfx(08)
				b.has_hit = true
				p.points += value_grid[j][i]
			end
		end
		if b.x > 128 then
			del(bullets, b)
		end
	end
end

function draw_bullets()
	for b in all(bullets) do
		if not b.has_hit then
			pset(b.x,b.y,10)
		else
			-- getting ready for drawing bullet blast
--			for x = -, do
--			 for y = -, do

--			 end
--			end
		end
	end
end

-->8
-- gamestate vars & util funcs --

ship_mov_speed = 1.4
e_translate_spd = 3 -- steps every x frames
ctr = 0
frames_in_e = 0 -- how long p was on an e square
frames_to_d = 1 -- start taking damage after this many frames
dmg_brate = 2
blink_frames = 0
max_blink = 30
phealthmax = 100
ptreatmax = 30*100
enemy_dmg = 5
last_bull = 0
fire_rate = 4
spawn_wait_min = 60 -- min frames between bombs
spawn_wait_max = 90 -- max frames between bombs

function mod(a, n)
	return a - (n * flr(a/n))
end
-->8
-- ui

bh = 5
bw = 50

-- yes, super sloppy
function draw_health_bar()
	rect(2,2,2+bw,2+bh,7)
	rectfill(2,2,2+p.health/2,2+bh,7)
	print("health ♥",50+bh,2,7)
end

function draw_treatment()
	rect(2,bh+4,2+bw,bh*2+4,12)
	rectfill(2,bh+4,2+flr(p.treatment/30/2),bh*2+4,12)
	print("time 🅾️",50+bh,bh+4,12)
end
__gfx__
0000000000770000000000000000000000770000000000000000000077777777888888888888888e000000000000e000222222228884e884008000e000000000
00000000aa7777000076668600000000aa77770000000000077777707aaaaaa7888e8888e8ef88880000e00000000f002222222208e0088000880e8000000000
000000000000770009c66770aa770000000077000077770007aaaa707abbbba788e8888e888888880000000000e00ef022222222080008000008880000000000
007007000166686000067000000670009c666870007aa70007abba707ab11ba7feeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22222222088088000088000000077000
0007700001666860aa77000009c667709c666870007aa70007abba707ab11ba7eeee0eeee8ef0ef0fee8ffeffeffe8ff22222222808000000e80000000077000
00077000000077000000000000766686000077000077770007aaaa707abbbba7000000000ff00e008e8888888f88f8882222222200e8040008000e0000000000
00700700aa7777000000000000000000aa77770000000000077777707aaaaaa700000000ff00efe088e888888888f88822222222000800000480048000000000
000000000077000000000000000000000077000000000000000000007777777700000000f000f0e088e88e888888888e22222222000880008884888800000000
0000000000000000000000000000000000000000000000001110000033300000ddd0000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000001010000031300000d3d0000000000000000000000000000000000000000000000000000000000000
0000000000000000022220000222200008888000022220001110000033300000ddd0000000000000000000000000000000000000000000000000000000000000
000cc000000880000288800002222000088880000288800000000000000000000000000000000000000000000000000000000000000000000000000000000000
000cc0000008800000188f80001888800018888000c88f8000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000188880001888800018888000c8888000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000288800008888000022220000288800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000222200008888000022220000222200000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
888888888888888888888888888e888888888888888e888888888888888e88888888888888888888888e888888888888888e88888888888888888888888e8888
8e8888888e8888e8ef88e8ef8888888e8888e8ef8888888e8888e8ef8888888e8888888e8888e8ef8888888e8888e8ef8888888e8888888e8888e8ef8888888e
e8777777777777777777777777777777777777777777777777777887878777e7778788e777878788888877e7788e8888888888e8888e88e8888e877787778777
ee777777777777777777777777777777777777777777777777ee7ee7e7e7fee7e7e7feee7ee7e7eeeeee77777eeeeeeeeeeefeeeeeeefeeeeeeeeee7eee7f7ee
ee777777777777777777777777777777777777777777777777ee78e777f77ee777e7eeee7ee777ef2ef277777eeee8ef2ef2eeee2eeeeeee2eeee8772777e777
22777777777777777777777777777777777777777777777777227ff72727222727272222722727f22e22277722222ff22e2222222222222222222ff727222227
22777777777777777777777777777777777777777777777777227f27e7e77727272777227227f722efe222722222ff22efe22222222222222222f777e7772777
22777777777777777777777777777777777777777777777777777222f2e22222222222222222f222f2e222222222f222f2e22222222222222222f222f2e22222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22ccccccccccccccccccccccccccccccccccccccccccccccccccc22ccc2ccc2ccc2ccc222222ccccc22222222222222222222222222222222222222222222222
22ccccccccccccccccccccccccc2222222222222222222222222c222c222c22ccc2c2222222cc222cc2222222222222222222222222222222222222222222222
22ccccccccccccccccccccccccc2222222222222222222222222c222c222c22c2c2cc222222cc2c2cc2222222222222222222222222222222222222222222222
22ccccccccccccccccccccccccc2222222222222222222222222c222c222c22c2c2c2222222cc222cc2222222222222222222222222222222222222222222222
22ccccccccccccccccccccccccc2222222222222222222222222c222c22ccc2c2c2ccc222222ccccc22222222222222222222222222222222222222222222222
22ccccccccccccccccccccccccccccccccccccccccccccccccccc222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
8884e8848884e8848884e88422222222222222222222222222222222222222228884e8848884e8848884e8848884e88422222222222222222222222222222222
e8eee88ee8eee88ee8eee88e2222222222222222222222222222222222222222e8eee88ee8eee88ee8eee88ee8eee88e22222222222222222222222222222222
e8eee8eee8eee8eee8eee8ee2222222222222222222222222222222222222222e8eee8eee8eee8eee8eee8eee8eee8ee22222222222222222222222222222222
e88e88eee88e88eee88e88ee2222222222222222222222222222222222222222e88e88eee88e88eee88e88eee88e88ee22222222222222222222222222222222
8e8eeeee8e8eeeee8e8eeeee22222222222222222222222222222222222222228e8eeeee8e8eeeee8e8eeeee8e8eeeee22222222222222222222222222222222
eee8e4eeeee8e4eeeee8e4ee2222222222222222222222222222222222222222eee8e4eeeee8e4eeeee8e4eeeee8e4ee22222222222222222222222222222222
eee8eeeeeee8eeeeeee8eeee2222222222222222222222222222222222222222eee8eeeeeee8eeeeeee8eeeeeee8eeee22222222222222222222222222222222
eee88eeeeee88eeeeee88eee2222222222222222222222222222222222222222eee88eeeeee88eeeeee88eeeeee88eee22222222222222222222222222222222
eeeeeeeeeeeeeeeeeeeeeeee8884e8848884e8848884e8848884e8848884e884eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8884e8848884e8848884e8848884e884
eeeeeeeeeeeeeeeeeeeeeeeee8eee88ee8eee88ee8eee88ee8eee88ee8eee88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8eee88ee8eee88ee8eee88ee8eee88e
eeeeeeeeeeeeeeeeeeeeeeeee8eee8eee8eee8eee8eee8eee8eee8eee8eee8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8eee8eee8eee8eee8eee8eee8eee8ee
eeeeeeeeeeeeeeeeeeeeeeeee88e88eee88e88eee88e88eee88e88eee88c88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88788eee88e88eee88e88eee88e88ee
eeeeeeeeeeeeeeeeeeeeeeee8e8eeeee8e8eeeee8e8eeeee8e8eeeee8e8cceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8e877eee8e8eeeee8e8eeeee8e8eeeee
eeeeeeeeeeeeeeeeeeeeeeeeeee8e4eeeee8e4eeeee8e4eeeee8e4eeeee8e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8e4eeeee8e4eeeee8e4eeeee8e4ee
eeeeeeeeeeeeeeeeeeeeeeeeeee8eeeeeee8eeeeeee8eeeeeee8eeeeeee8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8eeeeeee8eeeeeee8eeeeeee8eeee
eeeeeeeeeeeeeeeeeeeeeeeeeee88eeeeee88eeeeee88eeeeee88eeeeee88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88eeeeee88eeeeee88eeeeee88eee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee313eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111ddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1e11e11e1d3dd3deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111ddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333eeeeeeeeecceeeeeeeeeeeeee88eeeeee111eee77777777eeeeeeeeeeeeeee
eee88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee313eeeeeeeeecceeeeeeeeeeeeee88eeeeee1e1eee7aaaaaa7eeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111eee7a7777a7eeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111eeedddeeeeeeeeeeee111eeedddeeeeeeeeeeeeeee1111113331117a7aa7a7eeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1e11e11e1eeed3deeeeeeeeeeee1e1eeed3deeeeeeeeeeeeeee1e11e13131e17a7aa7a7eeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111eeedddeeeeeeeeeeee111eeedddeeeeeeeeeeeeeee1111113331117a7777a7eeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111333ddd111333eeeeeeeeeeee111333333eeeeeeeeeeeeeeeeeeeee111eee7aaaaaa7eeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1e11e1313d3d1e1313eeeeeeeeeeee1e1313313eeeeeeeeeeeeeeeeeeeee1e1eee77777777eeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111333ddd111333eeeeeeeeeeee111333333eeeeeeeeeeeeeeeeeeeee111eee333dddeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111333111333ddd333111eeeeeeeeeeee111eeedddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1e13131e1313d3d3131e1eeeeeeeeeeee1e1eeed3deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111333111333ddd333111eeeeeeeeeeee111eeedddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111333111eeeeee333111eeeeee333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee77eeeeeeeeeeeeeeee1e11e13131e1eeeeee3131e1eeeeee313eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeaa7777eeeeeeeeeeeeee111111333111eeeeee333111eeeeee333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee77eeeeeeeeeeeeeeeee111111333111333111333111111111ddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeee166686eeeeeeeeeeeeeeee1e11e13131e13131713131e11e11e1d3dd3deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88eeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeee166686eeeeeeeeeeeeeeee111111333111333111333111111111ddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88eeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee77eeeeeeeeeeeeeeeee111111333111333eeedddeeeeee333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeaa7777eeeeeeeeeeeeeeeee1e11e13131e1313eeed3deeeeee313eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee77eeeeeeeeeeeeeeeeeee111111333111333eeedddeeeeee333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee111111333dddeeeeeeeeeeeeeeeeeeeeedddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee1e11e1313d3deeeeeeeeeeeeeeeeeeeeed3deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee111111333dddeeeeeeeeeeeeeeeeeeeeedddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee111111333dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee1e11e1313d3deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee111111333dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee1e1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee111333dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee1e1313d3deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee111333dddeeeeeeeeeeeeeeeeeeeecceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee111333eeeeeeeeeeeeeeeeeeeecceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee1e1313eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee111333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee333111dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee3131e1d3deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee333111dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee333333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee313313eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee333333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeee111333eee111333111dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeee1e1313eee1e13131e1d3deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeee111333eee111333111dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee111333111333111eee333111333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee1e13131e13131e1eee3131e1313eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee111333111333111eee333111333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee111333111eeeddd111333111dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77eee
eeeeee1e13131e1eeed3d1e13131e1d3deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77eee
eeeeee111333111eeeddd111333111dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeee333dddddd111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeee313d3dd3d1e1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeee333dddddd111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeddd333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeed3d313eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeddd333eeeeeeeeeeeeeeeeeee88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeddddddeeeeeeeeeeeeeeeeeee88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeed3dd3deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee111333ddd333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee181313d3d313eeeee8eeeeeee8eeeeeeeeeeeeeeeeeeeeeee8eeeeeee8eeeeeeeeeeeeeeeeeeeeeee8eeeeeee8eeeeeee8eeeeeee8eeeeeeeeeeeee
eeeeeeeee111333ddd333e8eee88ee8eee88ee8eeeeeeeeeeeeeeeeeee88ee8eee88ee8eeeeeeeeeeeeeeeeeee88ee8eee88ee8eee88ee8eee88ee8eeeeeeeee
eeeeeeeee111111333e888eeeee888eeeee888eeeeeeeeeeeeeeeeeeeee888eeeee888eeeeeeeeeeeeeeeeeeeee888eeeee888eeeee888eeeee888eeeeeeeeee
eeeeeeeee1811e131388eeeeee888eeeee88eeeeeeeeeeeeeeeeeeeeee88eeeeee888eeeeeeeeeeeeeeeeeeeee88eeeeee88ceeeee88eeeeee88eeeeeeeeeeee
eeeeeeeee1111113338eeeeeee888eeeee8eeeeeeeeeeeeeeeeeeeeeee8eeeeeee888eeeeeeeeeeeeeeeeeeeee8eeeeeee8cceeeee8eeeeeee8eeeeeeeeeeeee
eeeeeeeee8eeeeeee8eeeeeee8eeeeeee8eeeeeeeeeeeeeeeeeeeeeee8eeeeeee8eeeeeeeeeeeeeeeeeeeeeee8eeeeeee8eeeeeee8eeeeeee8eeeeeeeeeeeeee
eeeeeeeee48ee48ee48ee48ee48ee48ee48ee48eeeeeeeeeeeeeeeeee48ee48ee48ee48eeeeeeeeeeeeeeeeee48ee48ee48ee48ee48ee48ee48ee48eeeeeeeee
eeeeeeee88848888888488888884888888848888eeeeeeeeeeeeeeee8884888888848888eeeeeeeeeeeeeeee88848888888488888884888888848888eeeeeeee
ee8eeeee22222222222222222222222222222222ee8eeeeeee8eeeee2222222222222222ee8eeeeeee8eeeee22222222222222222222222222222222ee8eeeee
ee88ee8e22222222222222222222222222222222ee88ee8eee88ee8e2222222222222222ee88ee8eee88ee8e22222222222222222222222222222222ee88ee8e
eee888ee22222222222222222222222222222222eee888eeeee888ee2222222222222222eee888eeeee888ee22222222222222222222222222222222eee888ee
ee88eeee22222222222222222222222222222222ee88eeeeee88eeee2222222222222222ee88eeeeee88eeee22222222222222222222222222222222ee88eeee
ee8eeeee22222222222222222222222222222222ee8eeeeeee8eeeee2222222222222222ee8eeeeeee8eeeee22222222222222222222222222222222ee8eeeee
e8eeeeee22222222222222222222222222222222e8eeeeeee8eeeeee2222222222222222e8eeeeeee8eeeeee22222222222222222222222222222222e8eeeeee
e48ee48e22222222222222222222222222222222e48ee48ee48ee48e2222222222222222e48ee48ee48ee48e22222222222222222222222222222222e48ee48e
88848888222222222222222222222222222222228884888888848888222222222222222288848888888488882222222222222222222222222222222288848888
2222222222e222222222222222222222e222222222222222e222222222222222e2222222e22222222222222222222222e22222222222222222222222e2222222
22e22222222f222222e22222e22222222f222222e22222222f222222e22222222f2222222f222222e2222222e22222222f222222e2222222e22222222f222222
22222222e22ef22222222222222222e22ef22222222222e22ef22222222222e22ef222e22ef2222222222222222222e22ef2222222222222222222e22ef22222
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e8ffeffeffe8fffee8fffee8ffeffeffe8fffee8ffeffeffe8fffee8ffeffeffe8fffeffe8fffee8ffeffee8ffeffeffe8fffee8ffeffee8ffeffeffe8fffee8
8888888f88f8888e88888e8888888f88f8888e8888888f88f8888e8888888f88f8888f88f8888e8888888e8888888f88f8888e8888888e8888888f88f8888e88
e888888888f88888e88888e888888888f88888e888888888f88888e888888888f8888888f88888e8888888e888888888f88888e8888888e888888888f88888e8
e88e888888888e88e88e88e88e888888888e88e88e888888888e88e88e888888888e8888888e88e88e8888e88e888888888e88e88e8888e88e888888888e88e8

__gff__
0000003030000000000000000000000000300000303000000030000000000000003030303000000000000000000000000030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000000000000000000000000c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c090809080908080908090808090808090808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001000000000000000000000000c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000d0d0c0c0c0c0d0d0d0c0c0c0c0c0d0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000001919000010001900000f00000d0d0d0d0000000d0d0d0d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000190000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001100000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000019000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000019000000000000000000190000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000019001100000000000e0e0e0e00000e0e0e0e00000e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000e0c0c0c0c0e0e0c0c0c0c0e0e0c0c0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002100000000000000000000000000000c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0a0b0a0b0a0b0b0a0a0b0a0a0b0a0b0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010e00000c0532821228422132633f615130631c063130630c0532821228422132633f615130631c063130630c0532821228422132633f6151c06428064130630c0532821228222132633f6151c0642806413063
010e000028354232442d3342b1542a4442b2342f15410054213541f2441e3341f15423444212341f1541c05428354232442d3342b1542a4442b2342f15410054213541f2441e3341f15423444212341f1541c054
010e00200c0530c2120c422102633f6150c063100630c0630c0530c2120c422102633f6150c063100630c0630c0530c2120c422102633f6150c0633f6150c0630c05304212044220c2633f6150c063346150c063
010e00102106421052217622175512700127001270012700180641805218762187550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200001527319276212662426623256282460c22500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300003761337613376133761337613016130161301613016130161301613016130161302613036130461306611086110a6110d6110e611116111361115611186111c6112131124311296112d6113361139611
01010000196501c3501d6501d3501c3501965023350203501e6501c3501a3501845022440204401e4401c4401b440194401844022440214401f4401e4401d4401d4301c4301b4301b4201b4201b4201a41000000
010d00002327323673232631f6631f2531f6531c2431c6431c6331c6331c6231c6161c6161c6261c6261c6361c6361c6361d6361f6362164622646246462a6462a6562a6562a6562a6662a6762a6762a6762a676
000400002b6431a522186150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00001f53618526125160051600307000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000
010d00002a6762a6762a6762a6762a6522a6522a6322a6322a6222a6222a6122a6122a6122a6122a6122a61500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000005500000000550000000000006000060000611006110061100611006110061100611006110061100611006110061100611006110061100000010550000001055000000000000000000000161101611
011000000161101611016110161101611016110161101611016110161101611016110161100000000000205500000020550000000000000000000002611026110261102611026110261102611026110261102611
011000000261102611026110261102611000000000003055000000305500000000000000000000036110361103611036110361103611036110361103611036110361103611036110361103611000000000000000
010500002821328423000002b2132b423000002f2132f423282002821328423000002b2132b423000003b2133b423000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000c0532821228422132633f615130631c063130630c0532821228422132633f615130631c063130630c0532821228422132633f6151c06428064130630c0532821228222132633f6151c0642806413063
010c000028354232442d3342b1542a4442b2342f15410054213541f2441e3341f15423444212341f1541c05428354232442d3342b1542a4442b2342f15410054213541f2441e3341f15423444212341f1541c054
010c00000c0530c2120c422102633f6150c063100630c0630c0530c2120c422102633f6150c063100630c0630c0530c2120c422102633f6150c0633f6150c0630c05304212044220c2633f6150c063346150c063
010c00102106421052217622175512700127001270012700180641805218762187550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00414344
00 02414344
00 00424344
00 02424344
00 00014344
00 02014344
00 00010344
00 02010344
00 00034344
02 01034344
01 07464344
00 0a424344
03 03424344
01 0b424344
00 0c424344
04 0d424344
01 0e424344
00 0f424344
00 11424344
00 0f424344
00 11424344
00 0f424344
00 10424344
00 11104344
00 0f101144
00 11101244
00 0f124344
04 10124344


pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
--init
// constants
fps=60.0
dt = 1.0 / fps
damp_x = 0.5
air_damp_x = 0.97
max_vel = 8.0 * fps
// move constants
mov = 7.5
max_mov = 75.0
jump_height = 22.0
jump_time = 0.38
fast_fall = 1.5
cling_speed = 7.0
walljump_velx = 150
max_coyote = 10

// derived constants
grav = (2.0*jump_height)/(jump_time*jump_time)
jump_vel = -(2.0*jump_height)/jump_time

// map pos
map_x1=0
map_x2=96
map_y1=16
map_y2=32
map_size_x=8*(map_x2-map_x1)
map_size_y=8*(map_y2-map_y1)

// dialog texts
dialog = {
{"this trick will help you!","press ❎ two times to","double jump! best luck!"},
{"beware of the soda and","the gummibears!", "do not touch them!"},
{"do a wall jump to reach","higher places! thats all","advice i can give you!"}
}
current_text = "debug"
// no.of frames before death screen
dead_anim_frames=30

function _init()
	// game state
	change_game_state("menu")
	frames_in_menu = 0
	frames_in_game = 0
	frames_in_win = 0
	frames_in_dead = 0
	// dialog state
	is_textbox = false
	// player
	p = {}
	// facing direction
	p.face_r = true
	// state managment
	p.state = "idle"
	p.fc = 0
	// player position
	p.x = 60.0
	p.y = 10.0 
	// player speed
	p.dx = 0.0
	p.dy = 0.0
	// move remainder
	p.rx = 0.0
	p.ry = 0.0
	// jump
	max_jumps = 0
	p.grounded = false
	p.falling = true
	p.hold_jump = false
	p.jumps = 0
	p.coyote = 0
	p.wall_coyote = 0
	p.has_walljump = false
	p.cling_right = false
	// collision
	// p.x,p.y is bottom middle
	p.coll = {}
	p.coll.x1 = -3.0
	p.coll.y1 = -6.0
	p.coll.x2 = 2.0
	p.coll.y2 = 0.0
	p.width = p.coll.x2 - p.coll.x1
	p.height = p.coll.y2 - p.coll.y1
	// kill box
	p.kill = {}
	p.kill.x1 = -3.0
	p.kill.y1 = -6.0
	p.kill.x2 = 2.0
	p.kill.y2 = -2.0
	// inputs
	inp = {}
	inp.left = false
	inp.right = false
	inp.jump = false
	// camera
	cam = {}
	cam.x = 0
	cam.y = 0
	// animated tiles
	candle_tiles_x={}
	candle_tiles_y={}
	candles_activated={}
	candle_count=0
	
	soda_tiles_x={}
	soda_tiles_y={}
	soda_count=0
	
	deep_soda_tiles_x={}
	deep_soda_tiles_y={}
	deep_soda_count=0
	
	roll_tiles_x={}
	roll_tiles_y={}
	roll_count=0

 // fill the tables
	find_animated_tiles()
end

// find animated tiles
function find_animated_tiles()
	for x=map_x1,map_x2 do
		for y=map_y1,map_y2 do
			// find candles
			if mget(x,y)==65 then
				add(candle_tiles_x,x)
				add(candle_tiles_y,y)
				add(candles_activated,false)
				candle_count+=1
			end
			// find soda top
			if mget(x,y)==127 then
					add(soda_tiles_x,x)
					add(soda_tiles_y,y)
					soda_count +=1
			end
			// find deep soda
			if mget(x,y)==111 then
				add(deep_soda_tiles_x,x)
				add(deep_soda_tiles_y,y)
				deep_soda_count +=1
			end
			// find talking rolls
			if mget(x,y)==25 then
				add(roll_tiles_x,x)
				add(roll_tiles_y,y)
				roll_count +=1
			end
		end
	end
end
-->8
--update
function _update60()
	if game_state == "menu" then
		update_menu()
	elseif game_state == "game" then
		update_game()
	elseif game_state == "win" then
		update_win()
	elseif game_state == "dead" then
		update_dead()
	end
end

function change_game_state(state)
	game_state = state
	if(state == "win") music(0)
	if(state == "dead") music(-1)
	if(state == "menu") music(-1)
	if(state == "game") music(4)
end

function update_win()
	frames_in_win +=1
	if btnp(❎) then
		_init()
	end
end

function update_dead()
	frames_in_dead +=1
	if btnp(❎) then
		_init()
	end
	// no inputs 
	inp.left = false
	inp.right = false
	inp.jump = false
	// animate some steps
	if frames_in_dead<=dead_anim_frames then 
		update_vel()
		update_pos()
		update_state()
	end
end

function update_menu()
	frames_in_menu +=1
	if btnp(❎) then
		change_game_state("game")
	end
end

function update_game()
 // update frame counter
 frames_in_game+=1
 // inputs
	update_inputs()
	// movement
	update_vel()
	update_pos()
	update_state()
	// check collision
	check_candle_touch()
	check_roll_touch()
	// check game end
	check_kill()
	check_game_end()
end

function update_inputs()
	if (btn(⬅️) and btn(➡️)) then
		inp.left = false
		inp.right = false
	else
		inp.left = btn(⬅️)
		inp.right = btn(➡️)
	end
	inp.jump = btn(❎)
	// hold jump
	p.hold_jump = inp.jump and p.hold_jump		
	// no inputs in dialog
	if is_textbox then
		inp.left = false
		inp.right = false
		inp.jump = false
		p.hold_jump = false
	end
end

function update_vel()
	// freeze player if in dialog
	if is_textbox then
		p.dx = 0
		p.dy = 0
		return
	end
	// horizontal movement
	if (inp.left) p.dx -= mov
	if (inp.right) p.dx += mov
	p.dx=mid(-max_mov, p.dx, max_mov)
	// slow down horizontally
	if (not inp.left 
		and not inp.right) then
		if p.grounded then
			p.dx *= damp_x
		else
			p.dx *= air_damp_x
		end
	end
	// determine gravity
	local eff_grav = grav
	if (not p.hold_jump) then
		eff_grav = grav*fast_fall
	end
	// apply gravity
	p.dy += eff_grav * dt
	// wallcling - overwrite gravity
	if p.state=="cling" then
		p.dy = min(cling_speed,p.dy)
	end
	// update coyote timers
	if (p.grounded) p.coyote=max_coyote
		if (p.state=="cling") p.wall_coyote=max_coyote
	if not p.grounded then
		p.coyote = max(0,p.coyote-1)
		p.wall_coyote = max(0,p.wall_coyote-1)
	end
	// all jumps
	if inp.jump and not p.hold_jump	then
		if can_ground_jump() then
			ground_jump()
		elseif can_wall_jump() then
			wall_jump()
		elseif can_air_jump() then
			air_jump()
		end
	end
	// clamp velocities
	local v = sqrt(p.dx*p.dx+p.dy*p.dy)
	if (v > max_vel) then
		local vs = max_vel/v
		p.dx*=vs
		p.dy*=vs
	end
end

function can_ground_jump()
	return p.grounded or p.coyote>0
end

function can_air_jump()
	return (p.jumps > 0 
		or p.coyote>0)
		and p.state!="cling"
end

function can_wall_jump()
	return p.has_walljump and
		(p.state == "cling" or p.wall_coyote>0) 
end

function ground_jump()
	p.dy = jump_vel
 p.hold_jump = true
 p.grounded = false
 sfx(0)
end

function air_jump()
	p.dy = jump_vel
 p.hold_jump = true
 p.grounded = false
 p.jumps -= 1
 sfx(0)
end

function wall_jump()
	if p.cling_right then
 	p.x-=1
 	p.dx = -walljump_velx
 else
 	p.x+=1
 	p.dx = walljump_velx
 end
	p.dy = jump_vel
 p.hold_jump = true
 p.grounded = false
 sfx(0)
end

// move player according to velocities
function update_pos()
	move_y(p.dy * dt)
	move_x(p.dx * dt)
end

function move_x(mx)
	mx+=p.rx
	local dir=sgn(mx)
	while abs(mx) > 1.0 do
		mx-=dir
		if player_collide(p.x+dir,p.y) then
			// horizontal collision
			if not p.grounded then
				change_state("cling")
				p.cling_right=p.dx>0
				p.grounded=false
			end
			p.dx=0.0
			p.rx=0.0
			return
		else
		// no collision - move
			p.x+=dir
		end
	end
	// got here without collision
	// save remainder
	p.rx = mx
end

function move_y(my)
	my+=p.ry
	local dir=sgn(my)
	while abs(my) > 1.0 do
		my-=dir
		if player_collide(p.x,p.y+dir) then
			// vertical collision
			p.dy=0.0
			p.ry=0.0
			if dir>0 then
				p.falling = false
				p.grounded = true
			end
			return
		else
			// no collision - move
			p.y+=dir
			// moved down - falling
			if dir>0 then
				p.falling = true
				p.grounded = false
			end
		end
	end
	// got here without collision
	// save remainder
	p.ry = my
end

function player_collide(nx,ny)
	// assumes the player rect is
	// at most a map cell (8x8)
	local ul = is_collide(
		nx+p.coll.x1,
		ny+p.coll.y1)
	local ur = is_collide(
		nx+p.coll.x2,
		ny+p.coll.y1)
	local bl = is_collide(
		nx+p.coll.x1,
		ny+p.coll.y2)
	local br = is_collide(
		nx+p.coll.x2,
		ny+p.coll.y2)
	return ul or ur or bl or br
end

function is_collide(x,y)
	// screen bounds
	if (x<0 or x>(map_x2-map_x1)*8) return true
	if (y<0 or y>(map_y2-map_y1)*8) return true
	// collision by map
	local cx = flr(x/8) + map_x1
	local cy = flr(y/8) + map_y1
	return fget(mget(cx,cy),0)
end

function change_state(new_state)
	if (p.state==new_state) return
	p.fc = 0
	p.state = new_state
	// replenish rejumps on land
	if (new_state == "land" or
		new_state == "walk" or
		new_state == "idle") then
		p.jumps = max_jumps
	end
	
	if (new_state == "fall") then
		p.grounded = false
	end
end

function update_state()
	// update frame count
	p.fc += 1
	// update facing direction
	p.face_r=inp.right or (p.face_r and not inp.left)
	// if dead, stay dead
	if (p.state == "dead")	return
	// update player state
	// dy-based changes
	if p.falling and p.state!="cling" then
		change_state("fall")
		return
	end
	if p.dy < 0 
	 and p.state!="jump" 
	 and p.state!="cling" then
		change_state("jump")
		return
	end
	// idle
	if p.state == "idle" then
		if inp.left or inp.right then
			change_state("walk")
		end
		return
	end
	// walk
	if p.state == "walk" then
		if not inp.left and not inp.right then
				change_state("idle")
		end
		return
	end
	// jump
	if p.state == "jump" then
		if p.grounded then
			change_state("land")
		end
		return
	end
	// fall
	if p.state == "fall" then
		if p.grounded then
			change_state("land")
		end
		return
	end	
	// land
	if p.state == "land" then
		// go to idle after animation is done
		if p.fc >= anim_speed_lnd[frames_lnd] then
			change_state("idle")
		end
		return
	end
	// cling
	if p.state == "cling" then
		// lose cling if wall is no longer there
		local cling_right = p.cling_right and not is_collide(p.x+p.coll.x2+1,p.y-p.height/2)
		local cling_left = not p.cling_right and not is_collide(p.x+p.coll.x1-1,p.y-p.height/2)
		if cling_right or cling_left then
				change_state("fall")
		end
		// lose cling if player moves from wall
		if (not inp.left and not p.cling_right)
			or (not inp.right and p.cling_right) then
			change_state("fall")
		end
		// lose cling if land
		if p.grounded then
			change_state("land")
		end
		return
	end	
end

// candle touching
function player_touches(x,y, marg)
	local touch_y = y<=p.y+marg and y>=p.y+p.coll.y1-marg 
	local touch_x = x>=p.x+p.coll.x1-marg and x<=p.x+p.coll.x2+marg
	return touch_y and touch_x
end

function check_candle_touch()
	for i=1,candle_count do
		local cx=8*(candle_tiles_x[i]-map_x1)+4
		local cy=8*(candle_tiles_y[i]-map_y1)+4
		if player_touches(cx,cy,2) and not candles_activated[i] then
			candles_activated[i]=true
			sfx(1)
		end
	end
end

function is_kill(x,y)
	// collision by map
	local cx = flr(x/8) + map_x1
	local cy = flr(y/8) + map_y1
	return fget(mget(cx,cy),2)
end

function player_kill(nx,ny)
	// assumes the player rect is
	// at most a map cell (8x8)
	local ul = is_kill(
		nx+p.kill.x1,
		ny+p.kill.y1)
	local ur = is_kill(
		nx+p.kill.x2,
		ny+p.kill.y1)
	local bl = is_kill(
		nx+p.kill.x1,
		ny+p.kill.y2)
	local br = is_kill(
		nx+p.kill.x2,
		ny+p.kill.y2)
	return ul or ur or bl or br
end

function check_kill()
	if player_kill(p.x,p.y) then
			change_game_state("dead")
			p.dy=jump_vel
			change_state("dead")
			sfx(2)
		end
end

// roll touching
function check_roll_touch()
	// check collision
	for i=1,roll_count do
		local cx=8*(roll_tiles_x[i]-map_x1)+4
		local cy=8*(roll_tiles_y[i]-map_y1)+4
		if player_touches(cx,cy,10) and btnp(🅾️)then
			// check which text needs to be loaded
			if is_textbox then
				is_textbox = false
			else
			// open dialogbox with text
				current_text = dialog[i]
				is_textbox = true
				sfx(4)
				if i == 1 then
					// change the max jump
					max_jumps=1
					p.jumps = max_jumps
					break
				end
				if i == 3 then
					p.has_walljump = true
					break
				end
			end
		end
	end
end

// check winning conditions
function check_game_end()
	local end_counter = 0
	for i=1, candle_count do
		if candles_activated[i] then
		 end_counter+=1
		end
		if end_counter >= candle_count then
			change_game_state("win")
		end
	end
end
-->8
--draw
// animation data
// walk animation
sprites_wlk={17,18,19,18}
frames_wlk=4
anim_speed_wlk={10,20,30,40}
// idle animation
sprites_idl={1,2}
frames_idl=2
anim_speed_idl={20,40}
// land animation
sprites_lnd={6,7,8,9,10,2}
frames_lnd = 6
anim_speed_lnd={3,13,16,19,22,25}
// jump animation
sprites_jmp={3,4}
frames_jmp = 2
anim_speed_jmp={10,20}
// fall animation
sprites_fll={5}
frames_fll = 1
anim_speed_fll={10}
// dead animation
sprites_dd={26}
frames_dd = 1
anim_speed_dd={10}
// cling animation
sprites_clng={20,21}
frames_clng = 2
anim_speed_clng={5,10}

function _draw()
	if game_state == "menu" then
		draw_menu()
	elseif game_state == "game" then
		draw_game()
	elseif game_state == "win" then
		draw_win_screen()
	elseif game_state == "dead" then
		if frames_in_dead>dead_anim_frames then
			draw_dead_screen()
		else
			draw_game()
		end
	end
end
	
function draw_game()
	cls(1)
	update_cam_pos()
	draw_map()	
	draw_sprite()
	draw_counter()
	//draw_coll_rects()
	if is_textbox then
		draw_textbox(current_text)
	end
end

function update_cam_pos()
	local cam_barr_x=12
	local cam_barr_y=32
 // camera never exceeds a max
 // distance to the player
 cam.x=mid(cam.x,-p.x+64-cam_barr_x,-p.x+64+cam_barr_x)
 cam.y=mid(cam.y,-p.y+64-cam_barr_y,-p.y+64+cam_barr_y)
	// clamp camera to map bounds
	cam.x=mid(0,cam.x,-map_size_x+128)
	cam.y=mid(0,cam.y,-map_size_y+128)
end

function draw_coll_rects()
	local col=8
	if (player_collide(p.x, p.y)) col=11
	// player sprite
	rect(
		cam.x+p.x+p.coll.x1,
		cam.y+p.y+p.coll.y1,
		cam.x+p.x+p.coll.x2,
		cam.y+p.y+p.coll.y2,
		col)
	// map cells
	for cx=map_x1,map_x2 do
		for cy=map_y1,map_y2 do
			// if that cell sprite has
			// first flag set then
			if fget(mget(cx,cy),0) then
				local sx=cam.x+(cx-map_x1)*8
				local sy=cam.y+(cy-map_y1)*8
				rect(sx,sy,sx+7,sy+7,8)
			end
		end
	end
end

function draw_counter()
	sspr(96,112,32,16,96,0,32,16,false,false)
	spr(82,98,4)
	local litc=0
	for lit in all(candles_activated) do
		if (lit) litc+=1
	end
	local tot=#candles_activated
	print(litc.."/"..tot, 107, 6, 8)
end

function draw_sprite()
	local spr_n = 36
	local spr_x = cam.x+p.x-4
	local spr_y = cam.y+p.y-7
	local frames = 1
	local anim_speed = {10}
	local sprites = {36}

	if (p.state == "walk") then
		frames = frames_wlk
		anim_speed = anim_speed_wlk
		sprites = sprites_wlk
	end
	
	if (p.state == "idle") then
		frames = frames_idl
		anim_speed = anim_speed_idl
		sprites = sprites_idl
	end
	
	if (p.state == "land") then
		frames = frames_lnd
		anim_speed = anim_speed_lnd
		sprites = sprites_lnd
	end
	
	if (p.state == "jump") then
		frames = frames_jmp
		anim_speed = anim_speed_jmp
		sprites = sprites_jmp
	end
	
	if (p.state == "fall") then
		frames = frames_fll
		anim_speed = anim_speed_fll
		sprites = sprites_fll
	end
	
		if (p.state == "cling") then
		frames = frames_clng
		anim_speed = anim_speed_clng
		sprites = sprites_clng
	end
	
	if (p.state == "dead") then
		frames = frames_dd
		anim_speed = anim_speed_dd
		sprites = sprites_dd
	end
	
	// find sprite to play
	local mod_fc = p.fc%anim_speed[frames]
	local pos = 1
	for k,v in pairs(anim_speed) do
		if (mod_fc < v) then
			pos = k
			break
		end
	end
	spr_n = sprites[pos]
	spr(spr_n, spr_x, spr_y, 1.0, 1.0, not p.face_r, false)	
end

function draw_map()
	// background
	local back_par=0.3
	local back_x=back_par*cam.x%128
	local back_y=back_par*cam.y%128
	map(16,0,back_x,back_y,16,16)
	map(16,0,back_x-128,back_y,16,16)
	map(16,0,back_x,back_y-128,16,16)
	map(16,0,back_x-128,back_y-128,16,16)
	// foreground
	map(map_x1,map_y1,cam.x,cam.y,map_size_x,map_size_y)
	// draw candles
	for x=1,candle_count do
		if candles_activated[x] then
			local candle_spr=80+(frames_in_game/15)%3
			spr(candle_spr,
							cam.x+8*(candle_tiles_x[x]-map_x1),
							cam.y+8*(candle_tiles_y[x]-map_y1))
		end
	end
	// draw soda
	for x=1,soda_count do
		local soda_spr=109+(frames_in_game/20)%2
		spr(soda_spr,
		cam.x+8*(soda_tiles_x[x]-map_x1),
		cam.y+8*(soda_tiles_y[x]-map_y1))
	end
	// draw deep_soda
	for x=1, deep_soda_count do
			local soda_spr2=94+(frames_in_game/20)%2
			spr(soda_spr2,
			cam.x+8*(deep_soda_tiles_x[x]-map_x1),
			cam.y+8*(deep_soda_tiles_y[x]-map_y1))
	end
	// draw animated  rolls
	for x=1,roll_count do
		local roll_animation = {13,76}
		local rolls = roll_animation[flr(frames_in_game/20)%2+1]
		spr(rolls,cam.x+8*(roll_tiles_x[x]-map_x1),
		cam.y+8*(roll_tiles_y[x]-map_y1),2,2)
	end
end

function draw_menu()
	cls(0)
	map(48,0,0,0,16,16)
	// blinking text
	if (frames_in_menu)%60>30then
		print("press ❎ to start",60,30,6)
	else
		print("press ❎ to start",60,30,15)
	end
	// small candle animation	
	local candle=80+(frames_in_menu/15)%3
	spr(candle,16,88)
	spr(candle,120,79)
	// big candle sprite
	spr(67,45,74,4,4)
	// tchuptchup animation
	local flame=103+(frames_in_menu/14)%4
	spr(flame,56,70)
end

function draw_win_screen()
	// background
	cls(1)
	map(0,0,0,0,16,16)
	// animated rolls
	local roll_animation = {13,76}
	local rolls = roll_animation[flr(frames_in_win/10)%2+1]
	spr(rolls,16,8,2,2)
	spr(rolls,96,8,2,2)
	// animated candles
	local candle=192+(frames_in_win/15)%3
	local candle2=192+(frames_in_win/14)%3
	spr(candle,32,36)
	spr(candle2,48,36)
	spr(candle,72,36)
	spr(candle2,88,36)
	spr(candle,16,60)
	spr(candle2,8,76)
	spr(candle,112,76)
	// animated tchuptchup
	local tchup=1+(frames_in_win/25)%2
	spr(tchup,60,48)
	// text
	print('congratulations!',35,1,7)
end

function draw_dead_screen()
	cls(0)
	map(32,0,0,0,16,16)
	for x=0,16 do
			local soda_sprite1 =94+(frames_in_dead/20)%2
			local soda_sprite2 =109+(frames_in_dead/20)%2
			spr(soda_sprite1,8*x,8*15)
			spr(127,8*x,8*14)
			spr(soda_sprite2,8*x,8*14)
			draw_textbox({"what a shame!", "press ❎ to enlight your", "fire again!"})
	end
end

function draw_textbox(text)
	sspr(32,96,64,32,10,0,112,40)
	print(text[1],16,10,4)
	print(text[2],16,17,4)
	print(text[3],16,24,4)
end
__gfx__
00000000000000000000000000aaaa0000aaaa00000000000000000000000000000000000000000000000000066666666666666000000008e0000000dddddddd
0000000000aaaa00000000000975a7500975a75000aaaa0000000000000000000000000000000000000000006000000000000006000077788777e800dddddddd
007007000975a75000aaaa0009aa88a009aa88a00975a75000aaaa000000000000000000000000000000000066000000000000660e87ee27777e8800dddddddd
0007700009aa88a00975a75009aaaaa009aaaaa009aa88a009aaaaa0000000000000000000aaaa0000aaaa006766666666666676088e22ee77e22e70dddddddd
0007700009aaaaa009aa88a0099aaaa0099aaaa0094aaa40094a88400000000000aaaa000a75a5700a75a5706777777fffff77760772666e7766628edddddddd
00700700099aaaa0099aaaa00099990000999900094999400949994040aaaa040a75a5700aaa88a009aa88a067777fffff4fff76777e757272757e88dddddddd
000000000099990009999990004004000400400000000000000000004aaaaaa44aaaaaa404aaaa400999999067774f4ffffffff6727e755eee755e72dddddddf
000000000440044004400440000000000000000000000000000000000999999049999994049999400440044067774fff4ffffff6727e2ee222ee2e72ddddddf7
7fdddddd00000000000000000000000000009aa000009aa0dddddddd777777777777777700000000000000006774fffffff4ffff72ee2e2eee2e2e7277777777
fddddddd00aaaa000000000000aaaa00000975a8000977a8dddddddd777777777777777700000000000000006774ff4ffffff4ff72ee2e2eee2e2ee277777777
dddddddd0975a75000aaaa000975a7500009778800097588dddddddd777777777777777700000000077707776774ffffffffffff72ee2ee222ee2ee277777777
dddddddd09aa88a00975a75009aa88a00009aa880009aa88dddddddd7777777777777777000000000757a7576774ffffff4fffff72eee2eeeee2eee277777777
dddddddd09aaaaa009aa88a009aaaaa00009aaa80009aaa8dddddddd7777777777777777000000000777a77767774fff4fff4ff60e2eee22222eee2e77777777
dddddddd099aaa40099aaaa00994aaa000009aa400009aa0dddddddd7777777777777777000000000aaa88a067774ffffffffff600e2eeeeeeeee2e077777777
dddddddf0099940009999aa0004999000000499400044994fdddddddffffffff777777770000000004aa8a400666644fffff4460000e22eeeee22e0077777777
ddddddf700440000004404400000044000040000000000047fdddddd1111111177777777000000020499994005555554444455500000ee22222ee000ffffffff
77777777dddddddddddddddddddddddd88888888ddddddf77fdddddd77777777777777777777777700000000000000000000000000000000f77777777777777f
ffffffffdddddddddddddddddddddddd88888888dddddddffddddddd777777777777777777777777005d5d0000cdcd0000d6d60000565600ff777777777777ff
dddddddddddddddddddddddddddddddd88888888dddddddddddddddd77777777777777777777777705d5d5d00cdcdcd00d6d6d60056565600ff7777777777ff0
dddddddddddddddddddddddddddddddd88888888ddddddddddddddddf77777777777777fffffffff0d5d5d500dcdcdc006d6d6d0065656500dffffffffffff50
dddddddd7ddddddddddddfdddddddddd88888888dddddddddddddddd0f777777777777f005d5d5d005d5d5d00cdcdcd00d6d6d600565656005d5d5d005d5d5d0
dddddddd7fdddddddddfffdddddddddd88888888dddddddddddddddd0dfff777777fffd00d5d5d500d5d5d500dcdcdc006d6d6d0065656500d5d5d500d5d5d50
dddddddf7fffffffffff77ffffffffff88888888dddddddddddddddd00d5dffffffd5d0000d5d50000d5d50000dcdc00006d6d000065650000d5d50000d5d500
ddddddf777777777777777777777777788888888dddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000
777777777777777777777777ddddddddddddddf70777777777777770ddddddf77fdddddd7777777777777777dddddddd7fdddddd777777770087880000000000
fffffffff777777ff7fff77fddddddddddddddf77777777777777777ddddddf77fdddddd777777777777777fdddddddd7fddddddffffffff0787878000000000
dddddddddf77777ff7fdf77fddddddddddddddf777f7777ff777fff7ddddddf77fddddddf77777fff7fffffddddddddd7fdddddddddddddd0870088000000000
dddddddddd7777fddfdddf7dddddddddddddddf77fdffffdd77fdff7ddddddf77fdddddddf777fddf7dddddddddddddd7fdddddddddddddd0880077000887800
ddddddddddffffddddddddfdddddddddddddddf77fddddddd77fddf7ddddddf77fddddddddfffdddf7dddddddddddddd7fdddddddddddddd0780088007887880
ddddddddddfddddddddddddd11111111dddddff77fddddddd7fdddf7ddddddf77fddddddddddddddf77ddddddddddddd7ffddddddddddddd0870000008700870
fddddddddddddddddddddddd1111111111111f777fdddddddfddddf7ddddddf77fddddddddddddddf77ddddddddddddd77111111dddddddd0880000008800780
7fdddddddddddddddddddddd11111111111111707fddddddddddddf7ddddddf77fdddddddddddddddffddddddddddddd01111111dddddddd0780000007700880
00000000000000007000000000000000000000000000000000000000777777777777ddd777777777777777777777777700000000000000000870000000000870
0007000000000000d7000000000000000000000000000000000000007dddddddd777ddd777777777777777777777777700000000000000000880000000000780
000fff0000000000dd70000000000000000000040000000000000000ddddddddd777fdd777777777777777777777777700000008e00000000780000000000880
00ff770000000000d0c7000000000000000000045000000000000000dddddddd77777dd7777777777777777777777777000077788777e8000870000000000870
077777f00004000000cc7000000ee2222222222452222222222ee000ffffddff77777fdd777777777777777d7dddd7770e87ee27777e88000880000000000780
0ffffff00eeeee0000c0e70000eeeeeeee2222222222eeeeeeeeee007777dd77dddd77dd77777dddd77ddd7ddddddd77088e22ee77e22e700780000000000880
7777777f0ee222000000ee7000eeeeeeeeeeeeeeeeeee22222eee1007777dd7ddddd77fdddd77dddd77ddf7ddfffdd770772666e77e6668e0870000000000870
ffffffff02e222000000e00700ee22ee222222222222222222eee100777ddd7ddffd777ddddd7ffdd77dd77dd777dd77777e7572722757880880000000000780
000a000000000000000a000000e2e22e2222222222222222222ee100777ddd7dd777777dd7ddd77dd77dd77dd777dd77727e755eeee755720a00000000000000
00a000000a0a00000000aa0000ee222ee222222222222222222ee10077dddd7dd777d77dd77dd77ddd7dd77ddddddd77727e2ee222ee2e72a0a000000a0000a0
0aaa000000a9a0000000aa0000e2e2eee222222222222222222e1100dddddd7dddddd77dd77dd77ddd7dd77ddddddf7772ee2e2eee2e2e720a0000a0a0a00a0a
0a99a000000aa00000aa9a0000ee22ee222222222222222222212100dddddf7fddddd77dd77dd77dddddd7dddffff77772ee2ee222ee2ee200000a0a0a0000a0
00a4900000a4a00000a4900000e2e2ee222222222222222222221100fffff777fffff77ff77dd77dddddf7ddf77777770e2ee2eeeee2ee2e000000a0000a0000
0eeeee000eeeee000eeeee0000ee22ee2222222222222222222121007777777777777777777fdd7fffff77dd7777777700e2ee22222ee2e000a0000000a0a000
0ee222000ee222000ee2220000e2e2ee22222222222222222222110077777777777777777777ff777777dddd77777777000e22eeeee22e000a0a0000000a0000
02e2220002e2220002e2220000ee22ee2222222222222222222121007777777777777777777777777ddddddf777777770000ee22222ee00000a0000000000000
02e22200022222000000000000e2e2ee2222222222222222222211000000a00000000a00000a000000000a00dd4444ddddddddddaaaaaa00a000aaaa99999999
02ee2200022222000000000000ee222222222222222222222221210000aa0000000aa00000000a00000aa000d4ffff4ddedddcdda0a00aaa0aaa00a099999999
02ee2200022222000000000000e2e2222222222222222222222211000a9aa00000aa9a000000a9a000aa9a004ff44ff4deddcddd0a0000a0a0a00a0a99999999
022e2200022222000000000000ee2222222222222222222222212100a7575a000a7575a00007575a0a7575a04f48e4f4dddddddd00000a0a0a0000a099999999
02222200022222000000000700e2e222222222222222222222221100aaa88a000aa988a000aa988a0aa988a04f4884f4ddbddddd000000a0000a000099999999
02222200022222000000007e00ee22222222222222222222222121000aa9aa000aa99aa000aaa9a00aa99aa04ff44ff4dddbddad00a0000000a0a00099999999
0222220002222200000007ee00e2e22222222222222222222222110000999000009999000009990000999900d4ffff4dddddddad0a0a0000000a000099999999
02222200022222000000700e00ee222222222222222222222221210000044000000440000004400000044000dd4444dddddddddd00a000000000000099999999
07777777777777777777777000e2e222222222222222222222221100ddddddf77fdddddd777777770033330000076000700000000000000000007c0000000000
77ffffffffffffffffffff7700ee2222222222222222222222212100dedddcf77edddcddffffffff03bbbb300007600027000000000000000007cc0000000000
7ffddddddddddddddddddff700e2e222222222222222222222221100deddcdf77eddcddddaddddde3bb33bb3000760002270000000000000007e0c0099999999
7fddddddddddddddddddddf700ee2222222222222222222222212100ddddddf77fddddddddaddded3b3bb3b30007600020c700000000000007ee000099999999
07ddddddddddddddddddddd000e2e222222222222222222222221100ddbdddf77fbdddddddddcddd33bb3bb30007600000cc777700000000720e000099999999
0dddddddddddddddddddddd0000e2222222222222222222222211000dddbdda77fdbddadddddcddd03bbbb300007600000c00eee777777772200000099999999
0ddd111111111111111dddd000001111111111111111111111110000dddddda77fddddad111111110033330000076000000000e0220cc0ee0200000099999999
01111111111111111111111000000000000000000000000000000000ddddddf77fdddddd111111110007600000076000000000000200c00e0000000099999999
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
0000a000000a000000aa00000000000000000000000000000000000000000000000000000000000000000000000000007fddddddddddddf70000000000000000
00000a00000aa000000a00000000000007777777777777777777777777777777777777777777777777777777777777707fddddddddddddf70000000000000000
000a00000000aa0000000aa00000000077744444777774444444444444444444444444444444444444444444777774777b3bd828db3bd8280000000000000000
0aa9a000000aaa000000aaa000000000774fffff47774fffffffffffffffffffffffffffffffffffffffffff47774f477bbbd888dbbbd8880000000000000000
a797aa0000a797a0000a797a00000000774ffffff444fffffffffffffffffffffffffffffffffffffffffffff444fff07333f222f333f2220000000000000000
a595aa000aa595a000aa595a0000000004fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00b3b78287b3b78280000000000000000
a98aa0000aa989a000aa989a000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff003330222033302220000000000000000
0aa99a0000a99a0000a99a00000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00b0b08080b0b08080000000000000000
01010101010101010d0d0d0d0d0d0d0d0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff082828877828288dd0000000000000000
01010101010101010d0d0d0d0d0d0d0d0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0022282ff022282dd0000000000000000
01010101010101010d0d0d0d0d0d0d0d0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0828288dd828288dd0000000000000000
01010101010101010d0d0d0d0d0d0d0d0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0007fdddd007fdddd0000000000000000
01010100010101010d0d0d0d0d0d0d000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0b3b3bbddb3b3bbdd0000000000000000
01010100010101010d0d0d0d0d0d0d000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00333b3dd0333b3dd0000000000000000
01000100010101010d0d0d0d0d000d000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0b3b3bbddb3b3bbff0000000000000000
01000000010101010d0d0d0d0d0000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0007fdddd000777770000000000000000
01010101ddddddddb0b080800d0d0d0d0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff077777777777777777777777777777777
01010101dddddddd333022200d0d0d0d0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff075555555555555555555555555555557
01010101db3bd828b3b782800d0d0d0d0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff075555555555555555555555555555557
01010101dbbbd888333f22270d0d0d0d0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff075555555555555555555555555555557
00010101f333f222bbbd8887000d0d0d0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff075555555555555555555555555555557
000101017b3b7828b3bd8287000d0d0d0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff075555555555555555555555555555557
0001000103330222ddddddf7000d000d0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff075555555555555555555555555555557
000000000b0b0808ddddddf7000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff075555555555555555555555555555557
ddddf700828288ddb0b08080b0b080800ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff075555555555555555555555555555557
ddbb3b3b022282dd33302220333022200ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff075555555555555555555555555555557
dd3b3330828288ddb3b78287b3b782870ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff075555555555555555555555555555557
ddbb3b3b007fdddd333f222f333f222f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff075555555555555555555555555555557
ddddf700b3b3bbddbbbd888dbbbd888d0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff075555555555555555555555555555557
dd8828280333b3ddb3bd828db3bd828d04ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4075555555555555555555555555555557
dd282220b3b3bbdddddddddd7fdddddd004444444444444444444444444444444444444444444444444444444444440075555555555555555555555555555557
dd882828007fdddddddddddd7fdddddd000000000000000000000000000000000000000000000000000000000000000077777777777777777777777777777777
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888eeeeee888777777888888888888888888888888888888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88ee88eee88778887788888888888888888888888888888888888888888888888888888ff888ff888222222888222822888882282888888222888
888eee8e8ee8eeee8eee87777787788888e88888888888888888888888888888888888888888888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8eeee8eee8777888778888eee8888888888888888888888888888888888888888888888ff888ff888222222888888222888228882888822288888
888eee8e8ee8eeee8eee87778777788888e88888888888888888888888888888888888888888888888ff888ff888822228888228222888882282888222288888
888eee888ee8eee888ee877788877888888888888888888888888888888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee8eeeeeeee877777777888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ddd11dd1ddd1ddd11dd1ddd11dd1d1d1dd11dd1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111d111d1d1d1d1d111d111d1d1d1d1d1d1d1d1d1d111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111dd11d1d1dd11dd11d111dd11d1d1d1d1d1d1d1d111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111d111d1d1d1d1d111d1d1d1d1d1d1d1d1d1d1d1d111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111d111dd11d1d1ddd1ddd1d1d1dd111dd1d1d1ddd111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11ee1eee1e1111111666116616661111161611111666111116161717166616661666111116661166166611111111111111111111111111111111111111111111
1e111e1e1e1111111611161616161111161617771616111116161171161616161616111116111616161611111111111111111111111111111111111111111111
1e111eee1e1111111661161616611111116111111666111111611777166616661661111116611616166111111111111111111111111111111111111111111111
1e111e1e1e1111111611161616161111161617771611111116161171161116161616111116111616161611111111111111111111111111111111111111111111
11ee1e1e1eee11111611166116161666161611111611117116161717161116161616166616111661161611111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1bbb11711ccc11111cc11c1111111666116616661111161611111cc11ccc1ccc11111ccc11111cc11c1111111cc11c1111711111111111111111111111111111
1b1b17111c1c111111c11c11111116111616161611111616117111c1111c1c1c11111c1c111111c11c11111111c11c1111171111111111111111111111111111
1bbb17111c1c111111c11ccc111116611616166111111161177711c11ccc1ccc11111c1c111111c11ccc111111c11ccc11171111111111111111111111111111
1b1117111c1c117111c11c1c117116111616161611111616117111c11c111c1c11711c1c117111c11c1c117111c11c1c11171111111111111111111111111111
1b1111711ccc17111ccc1ccc17111611166116161666161611111ccc1ccc1ccc17111ccc17111ccc1ccc17111ccc1ccc11711111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1bbb11711ccc11111cc11c1111111666116616661111161611111ccc11111cc11c1111111cc11c11117111111111111111111111111111111111111111111111
1b1b17111c1c111111c11c1111111611161616161111161611111c1c111111c11c11111111c11c11111711111111111111111111111111111111111111111111
1bbb17111c1c111111c11ccc11111661161616611111116111111c1c111111c11ccc111111c11ccc111711111111111111111111111111111111111111111111
1b1117111c1c117111c11c1c11711611161616161111161611711c1c117111c11c1c117111c11c1c111711111111111111111111111111111111111111111111
1b1111711ccc17111ccc1ccc17111611166116161666161617111ccc17111ccc1ccc17111ccc1ccc117111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11ee1eee1eee11ee1ee1111116611666166616161111166616661661161611711171111111111111111111111111111111111111111111111111111111111111
1e1111e111e11e1e1e1e111116161616161616161111166616111616161617111117111111111111111111111111111111111111111111111111111111111111
1e1111e111e11e1e1e1e111116161661166616161111161616611616161617111117111111111111111111111111111111111111111111111111111111111111
1e1111e111e11e1e1e1e111116161616161616661111161616111616161617111117111111111111111111111111111111111111111111111111111111111111
11ee11e11eee1ee11e1e111116661616161616661666161616661616116611711171111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11bb1171117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1b111711111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1bbb1711111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111b1711111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1bb11171117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1bbb11711c1c1ccc11111ccc11111ccc11111ccc11111cc11c1111111cc11c111171111111111111111111111111111111111111111111111111111111111111
1b1b17111c1c1c1c11111c1c11111c1c11111c1c111111c11c11111111c11c111117111111111111111111111111111111111111111111111111111111111111
1bbb17111ccc1ccc11111c1c11111c1c11111c1c111111c11ccc111111c11ccc1117111111111111111111111111111111111111111111111111111111111111
1b111711111c1c1c11711c1c11711c1c11711c1c117111c11c1c117111c11c1c1117111111111111111111111111111111111111111111111111111111111111
1b111171111c1ccc17111ccc17111ccc17111ccc17111ccc1ccc17111ccc1ccc1171111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1bbb1bb11bbb11711c1c1ccc1ccc1ccc11cc11cc11111c1c11111ccc11cc111111cc1ccc1ccc1ccc1ccc1c1c11111c111ccc11111ccc1ccc11111c1111711111
11b11b1b11b117111c1c1c1c1c1c1c111c111c1111111c1c111111c11c1c11111c1111c11c1c1c1c11c11c1c11111c111c1c1111111c1c1c11111c1111171111
11b11b1b11b1171111111ccc1cc11cc11ccc1ccc111111c1111111c11c1c11111ccc11c11ccc1cc111c1111111111ccc1c1c111111cc1c1c11111ccc11171111
11b11b1b11b1171111111c111c1c1c11111c111c11111c1c111111c11c1c1111111c11c11c1c1c1c11c1111111711c1c1c1c1171111c1c1c11711c1c11171111
1bbb1b1b11b1117111111c111c1c1ccc1cc11cc111111c1c111111c11cc111111cc111c11c1c1c1c11c1111117111ccc1ccc17111ccc1ccc17111ccc11711111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11ee1eee1e11111111661666166116611611166611111ccc1ccc111111711666166616661666166611661111166616611111166616661661161611171cc11ccc
1e111e1e1e11111116111616161616161611161117771c1c1c1c1171171116111616161616661611161111111161161611111666161116161616117111c11c11
1e111eee1e11111116111666161616161611166111111ccc1c1c1777171116611661166616161661166611111161161611111616166116161616117111c11ccc
1e111e1e1e11111116111616161616161611161117771c1c1c1c1171171116111616161616161611111611111161161611111616161116161616117111c1111c
11ee1e1e1eee111111661616161616661666166611111ccc1ccc111111711611161616161616166616611666166616161666161616661616116617111ccc1ccc
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1bbb117111661666166116611611166611111cc11c1111111ccc1ccc117111111111111111111111111111111111111111111111111111111111111111111111
1b1b1711161116161616161616111611111111c11c1111111c1c1c1c111711111111111111111111111111111111111111111111111111111111111111111111
1bb11711161116661616161616111661111111c11ccc11111ccc1ccc111711111111111111111111111111111111111111111111111111111111111111111111
1b1b1711161116161616161616111611117111c11c1c11711c1c1c1c111711111111111111111111111111111111111111111111111111111111111111111111
1b1b117111661616161616661666166617111ccc1ccc17111ccc1ccc117111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11ee1eee1e11111111661166161616611666166616661111111111111666166616661666166611661111166616611111166616661661161611171cc11ccc1111
1e111e1e1e111111161116161616161611611611161611111777111116111616161616661611161111111161161611111666161116161616117111c11c111111
1e111eee1e111111161116161616161611611661166111111111111116611661166616161661166611111161161611111616166116161616117111c11ccc1111
1e111e1e1e111111161116161616161611611611161611111777111116111616161616161611111611111161161611111616161116161616117111c1111c1111
11ee1e1e1eee111111661661116616161161166616161111111111111611161616161616166616611666166616161666161616661616116617111ccc1ccc1111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111888881111111111111111111111111111111
11ee1eee1e1111111666116616111611111111661666166616661666166611661111166611661611161117711171886681661616166116661666166617171ccc
1e111e1e1e111111161616161611161117771611161616161161116116111611111116161616161116111711171186888616161616161161161116161117111c
1e111eee1e1111111661161616111611111116661666166111611161166116661111166116161611161117111711868886161616161611611661166111711ccc
1e111e1e1e1111111616161616111611177711161611161611611161161111161111161616161611161117111711868886161616161611611611161617111c11
11ee1e1e1eee11111616166116661666111116611611161616661161166616611666161616611666166617711171886686611166161611611666161617171ccc
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1bbb1171166611661611161111111cc11ccc1c1c11111ccc1ccc11111ccc11111ccc117111111111111111111111111111111111111111111111111111111111
1b1b17111616161616111611111111c11c1c1c1c11111c1c1c1c1111111c1111111c111711111111111111111111111111111111111111111111111111111111
1bb117111661161616111611111111c11c1c1ccc11111ccc1ccc11111ccc11111ccc111711111111111111111111111111111111111111111111111111111111
1b1b17111616161616111611117111c11c1c111c11711c1c1c1c11711c1111711c11111711111111111111111111111111111111111111111111111111111111
1b1b1171161616611666166617111ccc1ccc111c17111ccc1ccc17111ccc17111ccc117111111111111111111111111111111111111111111711111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111771111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111777111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111777711111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111771111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822882828222888282288282822288888888888888888888888888888888888882288222822282228882822282288222822288866688
82888828828282888888882882828282882888288282888288888888888888888888888888888888888888288882888288828828828288288282888288888888
82888828828282288888882882228282882888288222822288888888888888888888888888888888888888288822882282228828822288288222822288822288
82888828828282888888882888828282882888288882828888888888888888888888888888888888888888288882888282888828828288288882828888888888
82228222828282228888822288828222828882228882822288888888888888888888888888888888888882228222822282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000010100000101000000000001000000000101000000010101010001010000000000000000000101010101010101010101010101000000020000000000000000000000000000000000000000000000000000000008080000000000000000000000000000000401010100000000010101000000000004
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000004040000000000000000000000000000040400000004040000000000000000000000000004040404000000000000000000000000
__map__
007a0000000000000000000000003f002b2a2a2a2d2a2a2a2b2a2a2a2a2a002dd2d2d2d2d1d1d2d2d2d2d1d1d2d2d2d21818181818181818181818181818181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007b00003e00002a0000000000004f2a002a2a2a2a002a2a2a2a2a2a2b2a2b2ad2d2d2d2d1d1d2d2d2d2d1d1d2d2d2d21818184748494a4b4748494a4b18181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b7b00004e2d0000002a004000004f002d2a2a2a2a2a2a2a2a2d2a2a002d2a2ad2d2d2d2d1d1d2d2d2d2d1d1d2d2d2d21818185758595a5b5758595a5b18181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070717972002c0000002b707179722c2a2a2b2a2a2c2a2a2a2a2a2a2a2a2a2ad2d2d2d2d1d1d2d2d2d2d1d1d2d2d2d21818181818181818181818181818181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002c7c7d7d7d7d7d7d7d7d7d7e002b00002a2a2a2a2a2b002a2a2b2a2a2a2c00d2d2d2d2d1d1d2d2d2d2d1d1d2d2d2d32929271f18181818181818181818181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c7d7d7e4100412a004100417c7d7d7e2a2b2a002a2a2a2a2a2a2c2a002a2a2ad2d2d2d3d1d1d2d2d2d3d1d1d2d2d2002c2a2a2d2e292929292929292929292f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d002a406140600000604061402a00002a002d2a2a2a002d002a2a2a2a2b2a2ae3d2d200d1d1e3d2d200d1d1e3d2d3002a2b2a2a2a2a2b2a2a2d2a2a2c2a2a2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002c00353a3d393d3d393d31367a002a2c2a002a002b2a2a2a2b2a002a2a2d0000e3d200d1d100e3d200e0d000e300002a2a2a2a2c2a2a2a2a2a2a2a2a2a2a2b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000041386b3b6c3b6c3b3b6b777b2d002d002b2c2a002a002a2a002a2a002a2a0000e300e0d00000d3000000000000002d2a2a2a2a2a2a2a2c2a2a2a2d2a2a2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c7d353a3d3d3d32313d3d3d3d367d7e2a2c002a002d2a002a2b2a002c002a00000000000000000000000000000000002a2c2a2a2a2a2a2a2a2a2a2a2a2a2a2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e41783b6c3b3b6b3b3b3b6c3b374100002a002a002a002a002a002d2a2a002a000000000000000000000000000000002a2a2a2a2a2a2b2a2a2a2b2a2a2a2a4100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4e353d3d3d393a3d3d31323d3d3d363f2a2b2a002d002a2b2a002a002a000000003e00003e0043444546003f3e0000000b0c412b2a2a2a2a2a2a2a2c3f0d0e6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4e786b6c3b3b3b3b6c3b3b6b3b3b774f2d0000000000002a00002c2a0000002d7a4e003f4e3f535455563e4f4e003f7a1b1c60402c2a2d2a2a2c2a404f1d1e6100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
35313d3d3d3d3d3d393a3d3d3d3d3d36002c002a000000000000002c000000007b4e7a4f4e4f636465664e4f4e7a4f7b353931323d3d3a393d323a393d3d3d3600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b6b6c3b3b6c3b6b3b3b3b6c3b3b6b6c000000000000000000000000000000007b4e7b4f4e4f737475764e4f4e7b4f7b386c6b3b3b6c3b3b3b3b6c3b6b3b3b7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6c3b3b3b6c3b3b3b6c3b3b6b3b6c3b3b000000000000000000000000000000006f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f3c33333333333333333333333333333400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
360000000000000000000000000000353d3220717171717179302071717171797171302071717171727c7d7d7d7d7d7e00410000000035323d313a3d3939393d3232393d3239323d39313a3d367c7d7d7d7d7d7d7d7e000000000000000000000000000000000000000000000000000000000000000000000000000000000000
370000000000000000000000000000786b3b777c7d7d7d7d7e38777c7d7d7d7e7c7e3877000000000000000000000000006000000000380f33333333160f3333333333160f3333333333331637000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7700000000000000000000000000003c331637000000000000383700000000000000383741000000000000000000352071720000000038370000410038777a4100000038370000003f00003877000000006040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37000000000000000000000000000000413837410000000000783741000000000000783760000000000000000000383700000000000038370000604078377b6100000038770000414f00007837000000353d36000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3700000000000000000000000000004061387760000000000038253600000000000038253600000000000000000038377c7d7d7d35392637000035392625313a36006238370000353600003837000000f10f34000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7700000019000000000000000000353d3d2625360000000000cce1cd000000000000cce1cd000000000041000000383741000000dd2316770000380f33333333347c7e78370062383700007837000000f13700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3741000000004000000000000000386c6b6c0f3400000000000000000000000000000000000000000070720000003825367d7d7d7d7e3837000038770000000000000038377c7e383700623877420062783700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37610000707172000000000000003c163b3bf0000000007a00000000000000000000000000000000000000000000380f340000000041783700003837000000400000003837000078377d7e38f0007c7e383700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
253600000000000000400000000000783b3bf0000000007b4000000000000000000000000000000000000000000078370000000000603837000038370000353d3600003c34420038377c7d38f000000038253d3d3d3d3d3600000000000000000000000000000000000000000000000000000000000000000000000000000000
0f347c7e7c7d7d7d7e70720000623e383b3b3700000000707971720000000000000000000000404100000000000038377c7d7d7d35322637000078370000386b7700000000007c383700003c340000003c3333163333333400000000000000000000000000000000000000000000000000000000000000000000000000000000
370000000000004100007c7d7d7e4e386b3b7740000000000000000000000000000000007079717200000000000038777c7d7d7e3c3333340000383700003c1637000000000000383700000000000000000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
770000000041006100410000000035263b6c253600000000000000000000000000000000000000000000000000003837000000000000000000003c343f0000383700000000000038770000000000007a000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
373e0000006040614060007a00003c3333333334000000000000000000000000007a0000000000000000000b0c0078370000000000000000003e19004f0000783700000000000038370000000040417b000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
374e3f004135313d3d36417b7a000000000000003f3e00001900000b0c003f00407b0000000000000000001b1c4038370000000000000040004e00004f00403837000000000000cccd00000000707971720000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
374e4f4035266b3b6c25367b7b400000000000004f4e00000000001b1c404f353d367f7f7f7f7f7f7f7f35393d3d2625367f7f7f7f35323d3d3d31323d3d3d26770000000000000000000000000000000000003c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
253d393d3d323d3d3d3d3d31323d3d3d31323d3d3d3d3d3d3231393a3d3d3d266c776f6f6f6f6f6f6f6f786b3b6c3b3b776f6f6f6f383b6b3b3b3b3b3b3b3b3b257f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f0000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000006120071200b1200e1201112013130141301614017140181501a1601c1001d10022100261002710000100001000010000100001000010000100001000010000100001000110000100001000010000100
000a000000610036200463005620046200261000610006000060008600096000960008600066000260001600006000660006600086000a6000a60007600026000060008600056000460004600046000360001600
000800000955009550095500655006550065500455004550045500455004500045000050009500065000450006500075000850009500085000650007500095000a5000a500095000950007500075000750007500
000e00000275105751057610275107701027610375103751017710077102751017510b701097010c7010c7010d7010e7010d7010c7010b7010b7010c7011270116701197011c7011e7011b701117010870109701
01090000265242754424524275342655426534245440252427524255542752424554055042b5040050428504245042650427504295042a5042a5042a5042a5042950428504265042350423504245042450427504
0014000003055030550506505065070550a0550a0550a05503055030550506505065070550a0550a0550a05503055030550506505065070550a0550a0550a05503055030550506505065070550a0550a0550a055
011400000f73211732137321673216732167321673213732117321173213732167321673216732167321673216732167322773227732277321b7321d7321d7322773224732227321f7321f7321b7322773227732
011400002973029730297302973029730297302e7302e7302b7302b7302b7302b7302b7302b7302e730307302e7302e7302e7302b730297302973029730297302b7302b7302b7302b7302b7302b730297002b700
01140000330153301530015300152e0152e0152e0152e0152e0152b0152e0152e01533015330153301533015300152e0152b0152b0152e0152e01530015300153301533015350153701535015330153001530015
011400001175011750117501175011750117501675016750137501375013750137501375013750167500c7501675016750167501375011750117501175011750137501375013750137501375013750297002b700
011400000f73211732137321673216732167321673213732117321173213732167321673216732167321673216732167322773227732277322e7322b73227732227322b7322e7322773227732277322773227732
171800000303303035030350303305035050330503307035050330503305033070350503505033050350703303033030350303505033030350303303033050350503305033070330503505033050350703505033
111800000c0550c0550c0550c0550c0050c0050c0050c0050a0550a0550a0550a055070051300511005130050c0550c0550c0550c0550c0550c0551d0051d0051d0051b0051b0051800516005130051300518005
a9180000007051d705117051f75522755167052475522755137052775529755297052e7552b7552b705307552e755297052e7551f7551f70522755247552770524755277552970527755247552b705227051f705
001000000a7510a7510a7520a75100701000010775107751077520775100701000010c7510c7510c7520c7510c7010c7010775107751077520775107701077010f7510f7510f7510f7510f7520f7510f70100001
b91800002b7152b7152b715297152e7152e7152e7152e7152b7152b7152b715297152e7152e7152e7152e7152b7152b7152b7152a7152e7152e7152e7152e7152b7152b7152b715297152b7152b7152b7152e715
b91800000000033754337503375033755007003075430750307503075500000357543575035750357550000030754307503075030755000003a7543a7503a7503a755000003c7543c7503c7503c7550000000000
__music__
01 05060844
00 050a0844
00 05070844
02 05090844
03 0b0c5044
03 0f104344


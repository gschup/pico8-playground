pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
// constants
dt = 1.0 / 60.0
damp_x = 0.9
max_vel = 500.0
// move constants
mov = 75.0
jump_height = 24.0
jump_time = 0.30
fast_fall = 2.0
max_rejumps = 1
// derived constants
grav = (2.0*jump_height)/(jump_time*jump_time)
jmp_vel = -(2*jump_height)/jump_time

// player states
state_idl = 0
state_wlk = 1
state_jmp = 2
state_fll = 3
state_lnd = 4

function _init()
	p = {}
	p.face_r = true
	// state managment
	p.state = state_idl
	p.fc = 0
	// player position
	p.x = 64.0
	p.y = 0.0 
	// player speed
	p.dx = 0.0
	p.dy = 0.0
	// jump
	p.hld_jmp = false
	p.rejumps = max_rejumps	
	
	// inputs
	inp = {}
	inp.left = false
	inp.right = false
	inp.jump = false
end
-->8
function _update60()
	update_inputs()
	update_vel()
	update_pos()
	collide()
	update_state()
end

function update_inputs()
	inp.left = false
	inp.right = false
	inp.jump = false
	if (not (btn(⬅️) and btn(➡️))) then
		if (btn(⬅️)) inp.left = true 
		if (btn(➡️)) inp.right = true
	end
	if (btn(❎)) inp.jump = true
end

function update_vel()
	// movement
	if (inp.left) p.dx = -mov
	if (inp.right) p.dx = mov
	// slow down horizontally
	if (not inp.left 
		and not inp.right) then
		p.dx *= damp_x
	end
	// grounded jump
	if ((p.state == state_idl
		or p.state == state_wlk)
		and inp.jump) then
		p.dy = jmp_vel
		p.hld_jmp = true
	end
	// hold jump
	if (inp.jump 
		and p.hld_jmp) then
		p.hld_jmp = true
	else
		p.hld_jmp = false
	end
	// rejump
	if ((p.state == state_jmp
		or p.state == state_fll)
		and not p.hld_jmp) then
		if (inp.jump
			and p.rejumps > 0) then
			p.dy = jmp_vel
			p.hld_jmp = true
			p.rejumps -= 1
		end
	end		
	//gravity
	local eff_grav = grav
	if (not p.hld_jmp) then
		eff_grav = grav*fast_fall
	end
	p.dy += eff_grav * dt	
	// clamp velocities
	local v = sqrt(p.dx*p.dx+p.dy*p.dy)
	if (v > max_vel) then
		local vs = max_vel/v
		p.dx*=vs
		p.dy*=vs
	end
end

function update_pos()
	p.x += p.dx * dt
	p.y += p.dy * dt
end

function collide()
	// bonk with screen bounds
	// todo: replace with 
	// intelligent collision
	if p.x < 0 then
		p.x = 0
		p.dx = 0
	end
	
	if p.x > 127 then
		p.x = 127
		p.dx = 0
	end
	
	if p.y < 0 then
		p.y = 0
		//p.dy = 0
	end
	
	if p.y > 127 then
		p.y = 127
		p.dy = 0
	end
end

function change_state(new_state)
	p.fc = 0
	p.state = new_state
	
	// replenish rejumps on land
	if (new_state == state_lnd) then
		p.rejumps = max_rejumps
	end
end

function update_state()
	// update frame count
	p.fc += 1
	// update facing direction
	if (p.face_r and inp.left) p.face_r=false
	if (not p.face_r and inp.right) p.face_r=true	
	
	// update player state
	// idle
	if (p.state == state_idl) then
		if (inp.left or inp.right) then
			change_state(state_wlk)
		end
		if (p.dy > 0) then
			change_state(state_fll)
		end
		if (p.dy < 0) then
			change_state(state_jmp)
		end
		return
	end
	// walk
	if (p.state == state_wlk) then
		if (not inp.left and not inp.right) then
				change_state(state_idl)
		end
		if (p.dy > 0) then
			change_state(state_fll)
		end
		if (p.dy < 0) then
			change_state(state_jmp)
		end
		return
	end
	// jump
	if (p.state == state_jmp) then
		if (p.dy > 0) then
			change_state(state_fll)
		end
		return
	end
	// fall
	if (p.state == state_fll) then
		if (p.dy == 0) then
			change_state(state_lnd)
		end
		return
	end	
	// land
	if (p.state == state_lnd) then
		// todo: fix anim_speed access
		if (p.fc >= anim_speed_lnd[frames_lnd]) then
			change_state(state_idl)
		end
		return
	end	
end
-->8
// walk
sprites_wlk={17,18,19,18}
frames_wlk=4
anim_speed_wlk={10,20,30,40}
// idle
sprites_idl={1,2}
frames_idl=2
anim_speed_idl={20,40}
// land
sprites_lnd={7,8,9,10,2}
frames_lnd = 5
anim_speed_lnd={10,13,16,19,22}
// jump
sprites_jmp={3,4}
frames_jmp = 2
anim_speed_jmp={10,20}
// fall
sprites_fll={5}
frames_fll = 1
anim_speed_fll={10}

function _draw()
	cls(1)
	//draw_map()	
	draw_sprite()
end

function draw_sprite()
	local spr_n = 36
	local spr_x = flr(p.x)-4
	local spr_y = flr(p.y)-7
	local frames = 1
	local anim_speed = {10}
	local sprites = {36}
	
	if (p.state == state_wlk) then
		frames = frames_wlk
		anim_speed = anim_speed_wlk
		sprites = sprites_wlk
	end
	
	if (p.state == state_idl) then
		frames = frames_idl
		anim_speed = anim_speed_idl
		sprites = sprites_idl
	end
	
	if (p.state == state_lnd) then
		frames = frames_lnd
		anim_speed = anim_speed_lnd
		sprites = sprites_lnd
	end
	
	if (p.state == state_jmp) then
		frames = frames_jmp
		anim_speed = anim_speed_jmp
		sprites = sprites_jmp
	end
	
	if (p.state == state_fll) then
		frames = frames_fll
		anim_speed = anim_speed_fll
		sprites = sprites_fll
	end
	
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
	//city
	local city_x=p.x*-0.3
	map(16,0,city_x+127,0,16,16)
	map(16,0,city_x,0,16,16)
	//candycanes
	local candy_x=p.x*-0.7
	map(32,0,candy_x+127,0,16,16)
	map(32,0,candy_x,0,16,16)
	//foreground
	local for_x=-p.x
	map(0,0,for_x+127,0,16,16)
	map(0,0,for_x,0,16,16)
end
__gfx__
00000000000000000000000000aaaa0000aaaa00000000000000000000000000000000000000000000000000cccccccc11111111dddddddddddddddd55555555
0000000000aaaa00000000000975a7500975a75000aaaa000000000000000000000000000000000000000000cccccccc11111111dddddddddddddccc55555555
007007000975a75000aaaa0009aa88a009aa88a00975a75000aaaa0000000000000000000000000000000000cccccccc11111111dddccccccccccccc55555550
0007700009aa88a00975a75009aaaaa009aaaaa009aa88a009aaaaa0000000000000000000aaaa0000aaaa00cccccccc11111111ccccc5cccccccccc05550555
0007700009aaaaa009aa88a0099aaaa0099aaaa0094aaa40094a88400000000000aaaa000a75a5700a75a570cccccccc11111111ccccc5cccccccccc55555555
00700700099aaaa0099aaaa00099990000999900094999400949994040aaaa040a75a5700aaa88a009aa88a0cccccccc11111111cccc555ccccccccc55055050
000000000099990009999990004004000400400000000000000000004aaaaaa44aaaaaa404aaaa4009999990cccccccc11111111cccc5555cccccccc55555555
0000000004400440044004400000000000000000000000000000000009999990499999940499994004400440cccccccc11111111ccc555c5cccccccc05550505
0000000000000000000000000000000000009aa000009aa00000000000000000bbbbbbbb0000000000000000dddddddd11111111ccc5c555ccc5cccc05505505
0000000000aaaa000000000000aaaa00000975a8000977a80000000000000000bbbbbbbb0000000000000000dddddddd11111111ccc55555ccc5cccc55555555
000000000975a75000aaaa000975a75000097788000975880000000000000000bbbbbbbb0000000000000000dddddddd11111111cc555555c5555c5c00500500
0000000009aa88a00975a75009aa88a00009aa880009aa880000000000300000555555550000000000000000dddddddd11111111cc555555c555555500000000
0000000009aaaaa009aa88a009aaaaa00009aaa80009aaa80b30000300b30000555555550000000000000000dddddddd111111dd55555c555555555500000000
00000000099aaa40099aaaa00994aaa000009aa400009aa00b3000b300b30030555555550000000000000000dddddddd111ddddd555555555555555500000000
000000000099940009999aa00049990000004994000449943bb333b33bbbb3b3555555550000000000000000dddddddd1ddddddd555555555555555500000000
000000000044000000440440000004400004000000000004bbbbbbbbbbbbbbbb555555550000000000000000dddddddddddddddd555555555555555500000000
00000000e2e9e2fee2e9e2fee2e9e2fe888888880000000000000000000000000000000000000000000000001111dddd11111111555555555050555550550550
000000009efe2ee29efe2ee29efe2ee288888888000000000000000000000000000000000000000900000000111ddddd11111111555555555555550005555555
000000002ee9ef9eeee9ef9eeee9ef9e888888880000000000000000000000000000000000000009000000001ddddddd11111111555555550550000000005055
0000000022e22222222222222222222288888888000000000000000000000000000000000000000900000000dddddddddd111111555555555000000000000555
0000000002200220000222020000000088888888000000000000000000000000000000000000000900000000dddddddddddd1111555555550000000000000005
0000000000000020000020000000000088888888000000000000000000000000000000000000000900000000dddddddddddddd11555555550000000000000000
0000000000000000000000000000000088888888000000000000000000000000000000000000000900000000ddddddddddddddd1555555550000000000000000
0000000000000000000000000000000088888888000000000000000000000000000000000000000000000000dddddddddddddddd555555550000000000000000
000000007700000000000077eeeeeeee777777770777777777777770eeeeeef77feeeeee7700000000000077eeeeeeee00000000777777770087880000000000
00000000ff7777777777777feeeeeeeeffffffff7777777777777777eeeeeef77feeeeeeff7777777777777feeeeeeee00000000ffffffff0787878000000000
00000000eefffffffffffffeeeeeeeeeeeeeeeee77f7777ff777fff7eeeeeef77feeeeeeeefffffffffffffeeeeeeeee00000000eeeeeeee0870088000000000
00000000eeeeeeeeeeeeeeeeefeefe9eefeeeefe7feffffee77feff7eeeeeef77feeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000eeeeeeee0880077000887800
00000000f9eeefe99ee9efeee9e9eeefe9feeee97feeeeeee77feef7eeeeeef77feeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000eeeeeeee0780088007887880
00000000eefeeefeeefefe9efefe9feefeee9f9e7feeeeeee7feeef7eeeeeef77feeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000eeeeeeee0870000008700870
00000000e9e2fee2f9e9e2f2e2eef2f2e292fefe7feeeeeeefeeeef7eeeeeef77feeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000eeeeeeee0880000008800780
000000002f2f29292f2f9f2f9f9f2f9f9f2f9f2f7feeeeeeeeeeeef7eeeeeef77feeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000eeeeeeee0780000007700880
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000870000000000870
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000880000000000780
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000780000000000880
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000870000000000870
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000880000000000780
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000780000000000880
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000870000000000870
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000880000000000780
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888777777888eeeeee888eeeeee888888888888888888888888888888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888778887788ee88eee88ee888ee88888888888888888888888888888888888888888888888888888ff888ff888222222888222822888882282888888222888
888777878778eeee8eee8eeeee8ee88888e88888888888888888888888888888888888888888888888ff888ff888282282888222888888228882888888288888
888777878778eeee8eee8eee888ee8888eee8888888888888888888888888888888888888888888888ff888ff888222222888888222888228882888822288888
888777878778eeee8eee8eee8eeee88888e88888888888888888888888888888888888888888888888ff888ff888822228888228222888882282888222288888
888777888778eee888ee8eee888ee888888888888888888888888888888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888777777778eeeeeeee8eeeeeeee888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111d111d111111dd11dd1dd111dd1ddd1ddd1dd11ddd11dd11111111111111111111111111111111111111111111111111111111111111111111111111111111
11d111d111111d111d1d1d1d1d1111d11d1d1d1d11d11d1111111111111111111111111111111111111111111111111111111111111111111111111111111111
11d111d111111d111d1d1d1d1ddd11d11ddd1d1d11d11ddd11111111111111111111111111111111111111111111111111111111111111111111111111111111
11d111d111111d111d1d1d1d111d11d11d1d1d1d11d1111d11111111111111111111111111111111111111111111111111111111111111111111111111111111
1d111d11111111dd1dd11d1d1dd111d11d1d1d1d11d11dd111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
166116661111111111111cc111111ccc1111111711111c111ccc11111ccc11111111111111111111111111111111111111111111111111111111111111111111
1616116111111777111111c111111c1c1111117111111c111c1c11111c1c11111111111111111111111111111111111111111111111111111111111111111111
1616116111111111111111c111111c1c1111117111111ccc1c1c11111c1c11111111111111111111111111111111111111111111111111111111111111111111
1616116111111777111111c111111c1c1111117111111c1c1c1c11111c1c11111111111111111111111111111111111111111111111111111111111111111111
166611611111111111111ccc11c11ccc1111171111111ccc1ccc11c11ccc11111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1661166616661666111116161111111111111ccc11111ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111
1616161616661616111116161111177711111c1c11111c1c11111111111111111111111111111111111111111111111111111111111111111111111111111111
1616166616161666111111611111111111111c1c11111ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111
1616161616161611111116161111177711111c1c1111111c11111111111111111111111111111111111111111111111111171111111111111111111111111111
1666161616161611166616161111111111111ccc11c1111c11111111111111111111111111111111111111111111111111177111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111177711111111111111111111111111
16661666161611111616166616111111111111111ccc1ccc1ccc11111ccc11111111111111111111111111111111111111177771111111111111111111111111
16661616161611111616161116111111177711111c111c1c1c1c11111c1c11111111111111111111111111111111111111177111111111111111111111111111
16161666116111111616166116111111111111111ccc1c1c1c1c11111c1c11111111111111111111111111111111111111111711111111111111111111111111
1616161616161111166616111611111117771111111c1c1c1c1c11111c1c11111111111111111111111111111111111111111111111111111111111111111111
16161616161616661161166616661111111111111ccc1ccc1ccc11c11ccc11111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111d111d11111ddd11dd1d1d1ddd111111dd11dd1dd111dd1ddd1ddd1dd11ddd11dd111111111111111111111111111111111111111111111111111111111111
11d111d111111ddd1d1d1d1d1d1111111d111d1d1d1d1d1111d11d1d1d1d11d11d11111111111111111111111111111111111111111111111111111111111111
11d111d111111d1d1d1d1d1d1dd111111d111d1d1d1d1ddd11d11ddd1d1d11d11ddd111111111111111111111111111111111111111111111111111111111111
11d111d111111d1d1d1d1ddd1d1111111d111d1d1d1d111d11d11d1d1d1d11d1111d111111111111111111111111111111111111111111111111111111111111
1d111d1111111d1d1dd111d11ddd111111dd1dd11d1d1dd111d11d1d1d1d11d11dd1111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1666116616161111111111111ccc1ccc11111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
166616161616111117771111111c1c1111111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
161616161616111111111111111c1ccc11111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
161616161666111117771111111c111c11111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
161616611161111111111111111c1ccc11c11ccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
166616161666166611111616166616661166161616661111111111111ccc11111ccc111111111111111111111111111111111111111111111111111111111111
116116161666161611111616161111611611161611611111177711111c1c11111c1c111111111111111111111111111111111111111111111111111111111111
116116161616166611111666166111611611166611611111111111111ccc11111c1c111111111111111111111111111111111111111111111111111111111111
116116161616161111111616161111611616161611611111177711111c1c11111c1c111111111111111111111111111111111111111111111111111111111111
166111661616161116661616166616661666161611611111111111111ccc11c11ccc111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1666161616661666111116661666166616661111111111111ccc11111cc11ccc1111111111111111111111111111111111111111111111111111111111111111
1161161616661616111111611161166616111111177711111c1c111111c11c111111111111111111111111111111111111111111111111111111111111111111
1161161616161666111111611161161616611111111111111c1c111111c11ccc1111111111111111111111111111111111111111111111111111111111111111
1161161616161611111111611161161616111111177711111c1c111111c1111c1111111111111111111111111111111111111111111111111111111111111111
1661116616161611166611611666161616661111111111111ccc11c11ccc1ccc1111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
166616661616111116161611166111111666166616661111111111111cc11ccc1111111111111111111111111111111111111111111111111111111111111111
1666161616161111161616111616111111611666161611111777111111c11c1c1111111111111111111111111111111111111111111111111111111111111111
1616166611611111166616111616111111611616166611111111111111c11c1c1111111111111111111111111111111111111111111111111111111111111111
1616161616161111161616111616111111611616161111111777111111c11c1c1111111111111111111111111111111111111111111111111111111111111111
161616161616166616161666166616661661161616111111111111111ccc1ccc1111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111d111d11111dd11ddd1ddd1ddd1d1d1ddd1dd1111111dd11dd1dd111dd1ddd1ddd1dd11ddd11dd111111111111111111111111111111111111111111111111
11d111d111111d1d1d111d1d11d11d1d1d111d1d11111d111d1d1d1d1d1111d11d1d1d1d11d11d11111111111111111111111111111111111111111111111111
11d111d111111d1d1dd11dd111d11d1d1dd11d1d11111d111d1d1d1d1ddd11d11ddd1d1d11d11ddd111111111111111111111111111111111111111111111111
11d111d111111d1d1d111d1d11d11ddd1d111d1d11111d111d1d1d1d111d11d11d1d1d1d11d1111d111111111111111111111111111111111111111111111111
1d111d1111111ddd1ddd1d1d1ddd11d11ddd1ddd111111dd1dd11d1d1dd111d11d1d1d1d11d11dd1111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
116616661666161611111111111111711ccc11111ccc171716661616166616661111161616661666116616161666117111171171166616161666166611111666
16111616161616161111177711111711111c11111c1c117111611616166616161111161616111161161116161161111711711711116116161666161611111161
161116611666161611111111111117111ccc11111c1c177711611616161616661111166616611161161116661161111711711711116116161616166611111161
161616161616166611111777111117111c1111111c1c117111611616161616111111161616111161161616161161111711711711116116161616161111111161
166616161616116111111111111111711ccc11c11ccc171716611166161616111666161616661666166616161161117117111171166111661616161116661161
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1666166616661111161616661611111111111111111111711ccc1717166616161666166611111616166616661166161616661171111716661616166616661111
116116661616111116161611161111111777111111111711111c1171116116161666161611111616161111611611161611611117117111611616166616161111
1161161616661111161616611611111111111111177717111ccc1777116116161616166611111666166111611611166611611117117111611616161616661111
1161161616111111166616111611111117771111111117111c111171116116161616161111111616161111611616161611611117117111611616161616111111
1661161616111666116116661666111111111111111111711ccc1717166111661616161116661616166616661666161611611171171116611166161616111666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111d111d11111ddd1d111ddd1d1d1ddd1ddd111111dd1ddd1ddd1ddd1ddd11dd1111111111111111111111111111111111111111111111111111111111111111
11d111d111111d1d1d111d1d1d1d1d111d1d11111d1111d11d1d11d11d111d111111111111111111111111111111111111111111111111111111111111111111
11d111d111111ddd1d111ddd1ddd1dd11dd111111ddd11d11ddd11d11dd11ddd1111111111111111111111111111111111111111111111111111111111111111
11d111d111111d111d111d1d111d1d111d1d1111111d11d11d1d11d11d11111d1111111111111111111111111111111111111111111111111111111111111111
1d111d1111111d111ddd1d1d1ddd1ddd1d1d11111dd111d11d1d11d11ddd1dd11111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1166166616661666166611111666166116111111111111111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111
1611116116161161161111111161161616111111177711111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111
1666116116661161166111111161161616111111111111111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111
1116116116161161161111111161161616111111177711111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111
1661116116161161166616661666166616661111111111111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1166166616661666166611111616161116161111111111111cc11111111111111111111111111111111111111111111111111111111111111111111111111111
16111161161611611611111116161611161611111777111111c11111111111111111111111111111111111111111111111111111111111111111111111111111
16661161166611611661111116161611166111111111111111c11111111111111111111111111111111111111111111111111111111111111111111111111111
11161161161611611611111116661611161611111777111111c11111111111111111111111111111111111111111111111111111111111111111111111111111
1661116116161161166616661666166616161111111111111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1166166616661666166611111666166616661111111111111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111
161111611616116116111111116116661616111117771111111c1111111111111111111111111111111111111111111111111111111111111111111111111111
1666116116661161166111111161161616661111111111111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111
1116116116161161161111111161161616111111177711111c111111111111111111111111111111111111111111111111111111111111111111111111111111
1661116116161161166616661661161616111111111111111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1166166616661666166611111666161116111111111111111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111
161111611616116116111111161116111611111117771111111c1111111111111111111111111111111111111111111111111111111111111111111111111111
16661161166611611661111116611611161111111111111111cc1111111111111111111111111111111111111111111111111111111111111111111111111111
111611611616116116111111161116111611111117771111111c1111111111111111111111111111111111111111111111111111111111111111111111111111
1661116116161161166616661611166616661111111111111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1166166616661666166611111611166116611111111111111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111
1611116116161161161111111611161616161111177711111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111
1666116116661161166111111611161616161111111111111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111
111611611616116116111111161116161616111117771111111c1111111111111111111111111111111111111111111111111111111111111111111111111111
166111611616116116661666166616161666111111111111111c1111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822888828282822288888888888888888888888888888888888888888888888888888288822282228882822282288222822288866688
82888828828282888888882888288282888288888888888888888888888888888888888888888888888888888288888288828828828288288282888288888888
82888828828282288888882888288222822288888888888888888888888888888888888888888888888888888222888282228828822288288222822288822288
82888828828282888888882888288882828888888888888888888888888888888888888888888888888888888282888282888828828288288882828888888888
82228222828282228888822282888882822288888888888888888888888888888888888888888888888888888222888282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000c0c0c0c0c0c0c0c0c1c2c0c0c0c0c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000c0c0c0c1c2c0c1c2b1b1b2c0c0c0c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000001c2c1c2b1b1b1b1b1b1b1b1b2c1c2c0c00003e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000001b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b00004e003f003e003f00003e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000035393d393a3d3d3d3600000d0e0d0e0b0b0e0d0d0b0b0e0e0d0e0b3f004e004f004e004f00004e003f3e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000383b3b3b3b3b3b3b3700001d1e1d1e1e1e1e1d1d1e1e1e1e1d1e1e4e174e164f174e164f17174e174f4e170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
343434313233333333333333333334320f2d2d2d2d2d2d2d2d2d0f2d2d2d2d2d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2123222123222121232322212222232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000110501405015050180501b0501e0502105024050270501505013050110501005015050160501b050220501b05020050280502c05019050200501a05015050120500d050090500605004050050500e050

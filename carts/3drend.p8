pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
--init
cam_speed=3.0

function _init()
	cam={}
	cam.dist=3.0
	cam.proj_dist=1.0
	cam.dx=0.0
	cam.dy=0.0
	// view matrix
	view_mat= {{1,0,0,0},
												{0,1,0,0},
												{0,0,1,cam.dist},
												{0,0,0,1}}
	view_mat.rows=4
	view_mat.cols=4
	
	// projection matrix
	proj_mat= {{1,0,0,0},
												{0,1,0,0},
												{0,0,1,0},
												{0,0,-1.0/cam.proj_dist,0}}
	proj_mat.rows=4
	proj_mat.cols=4
	
	// rotation matrix
	rot_mat= {{1,0,0,0},
											{0,1,0,0},
											{0,0,1,0},
											{0,0,0,1}}
	rot_mat.rows=4
	rot_mat.cols=4
	
	// vertex data
	hp=hom_points(points)
end
-->8
--update
function _update()
 // inputs
 cam.dy=0
 cam.dx=0
 if (btn(⬆️)) cam.dy=-cam_speed
 if (btn(⬇️)) cam.dy=cam_speed
 if (btn(⬅️)) cam.dx=-cam_speed
 if (btn(➡️)) cam.dx=cam_speed
	// update view matrix
	view_mat[3][4]=cam.dist
	// update projection matrix
	proj_mat[4][3]=-1.0/cam.proj_dist
	// update rotation matrix
	local dr=get_rot(cam.dx,cam.dy)
	rot_mat=matmul(dr,rot_mat)
end


-->8
--draw
function _draw()
 cls(0)
 local m=matmul(proj_mat, view_mat)
	m=matmul(m, rot_mat)
	render_list={}
	local pp=matmul(m,hp)
	local pix=hom_to_pix(pp)
	// render
	for p=1,#pix do
	 pset(pix[p][1],pix[p][2],7)
	end
end
-->8
--functions
function matmul(a,b)
	assert(a.cols==b.rows, "invalid dimensions")
	local prod={}
	prod.rows=a.rows
	prod.cols=b.cols
	for row=1,a.rows do
		prod[row]={}
		for col=1,b.cols do
			local sum=0
			for k=1,a.cols do
				sum += a[row][k] * b[k][col]
			end
			prod[row][col]=sum
		end
	end
 return prod
end

function hom_points(p)
	local hp={{},{},{},{}}
	for i=1,#p do
		add(hp[1],p[i][1])
		add(hp[2],p[i][2])
		add(hp[3],p[i][3])
		add(hp[4],1)
	end
	hp.rows=4
	hp.cols=#p
	return hp
end

function hom_to_pix(hp)
	local pix={}
	for i=1,hp.cols do
		local px=64+64*hp[1][i]/hp[4][i]
		local py=64+64*hp[2][i]/hp[4][i]
		add(pix,{px,py})
	end
	return pix
end

function get_rot(dx,dy)
	local rot={{},{},{},{}}
	rot.rows=4
	rot.cols=4
	local r=100.0
	local dr=sqrt(dx*dx+dy*dy)
	local coso=r/sqrt(r*r+dr*dr)
	local sino=dr/sqrt(r*r+dr*dr)
	local dxdr=dx/dr
	local dydr=dy/dr
	rot[1][1]=coso+dydr*dydr*(1-coso)
	rot[1][2]=-dxdr*dydr*(1-coso)
	rot[1][3]=dxdr*sino
	rot[1][4]=0
	rot[2][1]=-dxdr*dydr*(1-coso)
	rot[2][2]=coso+dxdr*dxdr*(1-coso)
	rot[2][3]=dydr*sino
	rot[2][4]=0
	rot[3][1]=-dxdr*sino
	rot[3][2]=-dydr*sino
	rot[3][3]=coso
	rot[3][4]=0
	rot[4][1]=0
	rot[4][2]=0
	rot[4][3]=0
	rot[4][4]=1	
	return rot
end
-->8
--vertex data
points={
  { -1, -1,  1 },
  {  1, -1,  1 },
  {  1,  1,  1 },
  { -1,  1,  1 },
  { -1, -1, -1 },
  {  1, -1, -1 },
  {  1,  1, -1 },
  { -1,  1, -1 }
}

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

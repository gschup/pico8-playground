pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
--init
rot_speed=3.0
move_speed=0.1

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
	hp,pn=read_vertices(points)
end
-->8
--update
function _update60()
 // inputs
 cam.dy=0
 cam.dx=0
 if (btn(⬆️)) cam.dy=-rot_speed
 if (btn(⬇️)) cam.dy=rot_speed
 if (btn(⬅️)) cam.dx=-rot_speed
 if (btn(➡️)) cam.dx=rot_speed
 if (btn(❎)) cam.dist+=move_speed
 if (btn(🅾️)) cam.dist-=move_speed
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
 // project vertices
 local m=matmul(proj_mat, view_mat)
	m=matmul(m, rot_mat)
	local php=matmul(m,hp)
	local pn=matmul(m,pn)
	local pp=hom_to_3d(php)
	// backface culling
	local fids=cull_faces(pp)
	// rasterize faces
	rasterize_faces(pp,fids)
	// render vertices
	render_vertices(pp)
	// fps info
	print("fps: "..stat(7).."/"..stat(8),0,0,7)
end

function render_vertices(pp)
	for p=1,#pp do
	 pset(pp[p][1],pp[p][2],7)
	end
end

function cull_faces(pp)
	local fids={}
 for i=1,#faces do
 	// backface culling
 	local v1=pp[faces[i][1]]
 	local v2=pp[faces[i][2]]
 	local v3=pp[faces[i][3]]
 	local a={
 		v1[1]-v2[1],
 		v1[2]-v2[2],
 		v1[3]-v2[3]}
 	local b={
 		v1[1]-v3[1],
 		v1[2]-v3[2],
 		v1[3]-v3[3]}
 	local n=crossprod(a,b)
 	if n[2]<0 then
 		add(fids,i) 		
 	end
 end
 return fids	
end

function rasterize_faces(pp,fids)
 for fid in all(fids) do
 	local face=faces[fid]
 	local v1=pp[face[1]]
 	local v2=pp[face[2]]
 	local v3=pp[face[3]]
 	
 	// bounding box
 	local xmin=min(min(v1[1],v2[1]),v3[1])
 	local xmax=max(max(v1[1],v2[1]),v3[1])
 	local ymin=min(min(v1[2],v2[2]),v3[2])
 	local ymax=max(max(v1[2],v2[2]),v3[2])
 	// clamp by canvas bounds
 	xmin=min(max(0,xmin),127)
 	ymin=min(max(0,ymin),127)
 	xmax=min(max(0,xmax),127)
 	ymax=min(max(0,ymax),127)
 	
 	
 	for x=flr(xmin),flr(xmax) do
 		for y=flr(ymin),flr(ymax) do
 			if is_inside(v1,v2,v3,x,y) then
 				pset(x,y,6)
 			end
 		end
 	end
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

function crossprod(a,b)
	assert(#a==3 and #b==3)
	local res={}
	res[1]=a[2]*b[3]-a[3]*b[2]
	res[2]=a[3]*b[1]-a[1]*b[3]
	res[3]=a[1]*b[2]-a[2]*b[1]
	return res
end

function read_vertices(p)
	// points in homogeneous coordinates
	local hp={{},{},{},{}}
	for i=1,#p do
		add(hp[1],p[i][1])
		add(hp[2],p[i][2])
		add(hp[3],p[i][3])
		add(hp[4],1)
	end
	hp.rows=4
	hp.cols=#p
	// vertex normals
	local n={{},{},{},{}}
	for i=1,#p do
		add(n[1],p[i][4])
		add(n[2],p[i][5])
		add(n[3],p[i][6])
		add(n[4],1)
	end
	n.rows=4
	n.cols=#p
	return hp,n
end

function hom_to_3d(hp)
	local v={}
	for i=1,hp.cols do
		local px=64+64*hp[1][i]/hp[4][i]
		local py=64+64*hp[2][i]/hp[4][i]
		local pz=64+64*hp[3][i]/hp[4][i]
		add(v,{px,py,py})
	end
	return v
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

function is_inside(v1,v2,v3,px,py)
	local x1=v1[1]
	local x2=v2[1]
	local x3=v3[1]
	local y1=v1[2]
	local y2=v2[2]
	local y3=v3[2]
	local t1=((y2-y3)*(px-x3)+(x3-x2)*(py-y3))/((y2-y3)*(x1-x3)+(x3-x2)*(y1-y3))
	local t2=((y3-y1)*(px-x3)+(x1-x3)*(py-y3))/((y2-y3)*(x1-x3)+(x3-x2)*(y1-y3))
	local t3=1-t1-t2
	return t1>=0 and t2>=0 and t3>=0
end
-->8
--vertex data
points={
{-1.000000,-1.000000,1.000000,-1.000000,0.000000,0.000000},
{-1.000000,1.000000,1.000000,-1.000000,0.000000,0.000000},
{-1.000000,1.000000,-1.000000,-1.000000,0.000000,0.000000},
{-1.000000,1.000000,1.000000,0.000000,1.000000,-0.000000},
{1.000000,1.000000,1.000000,0.000000,1.000000,-0.000000},
{1.000000,1.000000,-1.000000,0.000000,1.000000,-0.000000},
{1.000000,1.000000,1.000000,1.000000,0.000000,0.000000},
{1.000000,-1.000000,1.000000,1.000000,0.000000,0.000000},
{1.000000,-1.000000,-1.000000,1.000000,0.000000,0.000000},
{-1.000000,-1.000000,1.000000,-0.000000,-1.000000,0.000000},
{-1.000000,-1.000000,-1.000000,-0.000000,-1.000000,0.000000},
{1.000000,-1.000000,1.000000,-0.000000,-1.000000,0.000000},
{-1.000000,-1.000000,-1.000000,-0.000000,-0.000000,-1.000000},
{-1.000000,1.000000,-1.000000,-0.000000,-0.000000,-1.000000},
{1.000000,1.000000,-1.000000,-0.000000,-0.000000,-1.000000},
{1.000000,-1.000000,1.000000,-0.000000,0.000000,1.000000},
{1.000000,1.000000,1.000000,-0.000000,0.000000,1.000000},
{-1.000000,1.000000,1.000000,-0.000000,0.000000,1.000000},
{-1.000000,-1.000000,-1.000000,-1.000000,-0.000000,-0.000000},
{-1.000000,-1.000000,1.000000,-1.000000,-0.000000,-0.000000},
{-1.000000,1.000000,-1.000000,-1.000000,-0.000000,-0.000000},
{-1.000000,1.000000,-1.000000,0.000000,1.000000,0.000000},
{-1.000000,1.000000,1.000000,0.000000,1.000000,0.000000},
{1.000000,1.000000,-1.000000,0.000000,1.000000,0.000000},
{1.000000,1.000000,-1.000000,1.000000,-0.000000,0.000000},
{1.000000,1.000000,1.000000,1.000000,-0.000000,0.000000},
{1.000000,-1.000000,-1.000000,1.000000,-0.000000,0.000000},
{1.000000,-1.000000,1.000000,0.000000,-1.000000,0.000000},
{-1.000000,-1.000000,-1.000000,0.000000,-1.000000,0.000000},
{1.000000,-1.000000,-1.000000,0.000000,-1.000000,0.000000},
{1.000000,-1.000000,-1.000000,0.000000,-0.000000,-1.000000},
{-1.000000,-1.000000,-1.000000,0.000000,-0.000000,-1.000000},
{1.000000,1.000000,-1.000000,0.000000,-0.000000,-1.000000},
{-1.000000,-1.000000,1.000000,0.000000,0.000000,1.000000},
{1.000000,-1.000000,1.000000,0.000000,0.000000,1.000000},
{-1.000000,1.000000,1.000000,0.000000,0.000000,1.000000},
}

faces={
{1,2,3},
{4,5,6},
{7,8,9},
{10,11,12},
{13,14,15},
{16,17,18},
{19,20,21},
{22,23,24},
{25,26,27},
{28,29,30},
{31,32,33},
{34,35,36},
}

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
--init
rot_speed=4.0
move_speed=0.2
proj_dist=1.5
backface_culling=true

function _init()
 // cam
	cam={}
	cam.dx=0.0
	cam.dz=0.0
	cam.drx=0.0
	cam.dry=0.0
	
	// light
	light={}
	light.x = 10.0
	light.y = -10.0
	light.z = 10.0	
	// cam position matrix
	pos_mat= {
		{1,0,0,0.0},
		{0,1,0,-4.0},
		{0,0,1,10.0},
		{0,0,0,1}}
	pos_mat.rows=4
	pos_mat.cols=4
	
	// cam rotation matrix
	rot_mat= {
		{1,0,0,0},
		{0,1,0,0},
		{0,0,1,0},
		{0,0,0,1}}
	rot_mat.rows=4
	rot_mat.cols=4
	
	// cam projection matrix
	proj_mat= {
		{1,0,0,0},
		{0,1,0,0},
		{0,0,1,0},
		{0,0,-1.0/proj_dist,0}}
	proj_mat.rows=4
	proj_mat.cols=4
	
	// set model to display
	cur_vertices=read_vector_string(fox_v_string)
	cur_faces=read_face_string(fox_f_string)
	//cur_vertices=model_points
	//cur_faces=model_faces
end
-->8
--update
function _update()
	// inputs
	cam.dx=0.0
	cam.dz=0.0
	cam.drx=0.0
	cam.dry=0.0
	// rotate
	if (btn(⬆️)) cam.dry=-rot_speed
	if (btn(⬇️)) cam.dry=rot_speed
	if (btn(⬅️)) cam.drx=-rot_speed
	if (btn(➡️)) cam.drx=rot_speed
 // translate
	if (btn(❎)) cam.dz=-move_speed
	if (btn(🅾️)) cam.dz=move_speed

	// update position matrix
	local dp=get_mov(cam.dx,cam.dz)
	pos_mat=matmul(dp,pos_mat)
	// update rotation matrix
	local dr=get_rot(cam.drx,cam.dry)
	rot_mat=matmul(dr,rot_mat)
	
	// create hom coord matrix
	hom_v=hom_verts(cur_vertices)
end


-->8
--draw
function _draw()
	cls(0)
	// rotate, then translate
	local cam_mat=matmul(pos_mat, rot_mat)
	// projection
	local all_mat=matmul(proj_mat, cam_mat)
	// project vertices
	local proj_hom_v=matmul(all_mat,hom_v)
	// translate vertices back into 3d vectors
	local proj_v=hom_to_3d(proj_hom_v)
	// translate coordinates to screen size
	viewport_transform(proj_v)
	// generate faces
	local proj_f=generate_faces(proj_v, cur_faces)
	// render
	render_faces(proj_f)
	render_vertices(proj_v)
	// fps info
	print("fps: "..stat(7).."/"..stat(8),0,0,7)
end

function render_vertices(pp)
	for i=1,#pp do
		pset(pp[i][1],pp[i][2],8)
	end
end

function render_faces(faces)
	for i=1,#faces do
		// backface culling
		if (faces[i].nz>0 and backface_culling) goto cont
		local f=faces[i]
		// determine color
		local lv={
			}
		// draw the triangle
		fill_triangle(
			f.v1[1],f.v1[2],
			f.v2[1],f.v2[2],
			f.v3[1],f.v3[2],
			6,7)
		::cont::
	end
end

function generate_faces(pp, face_data)
	local faces={}
	for i=1,#face_data do
		add(faces, create_face(pp, face_data[i]))		
	end
	return faces
end

function create_face(pp, vlist)
	local face={}
	face.nx=0
	face.ny=0
	face.nz=0
	// normal
	local v1=pp[vlist[1]]
	local v2=pp[vlist[2]]
	local v3=pp[vlist[3]]
	local a={
		v1[1]-v2[1],
		v1[2]-v2[2],
		v1[3]-v2[3]}
	local b={
		v1[1]-v3[1],
		v1[2]-v3[2],
		v1[3]-v3[3]}
	local n=crossprod(a,b)
	face.nx=n[1]
	face.ny=n[2]
	face.nz=n[3]
	// vertices
	face.v1=v1
	face.v2=v2
	face.v3=v3
	return face
end

function fill_triangle(x1,y1,x2,y2,x3,y3,color1)

	local x1=x1&0xffff
	local x2=x2&0xffff
	local y1=y1&0xffff
	local y2=y2&0xffff
	local x3=x3&0xffff
	local y3=y3&0xffff
 
 local nsx,nex
 //sort points by y
 if(y1>y2)then
	y1,y2=y2,y1
	x1,x2=x2,x1
  end         
	if(y1>y3)then
		y1,y3=y3,y1
		x1,x3=x3,x1
	end  
	if(y2>y3)then
		y2,y3=y3,y2
		x2,x3=x3,x2          
	end
	
	// top part of triangle 
	if(y1!=y2)then          
		local delta_sx=(x3-x1)/(y3-y1)
		local delta_ex=(x2-x1)/(y2-y1)
	   
		if(y1>0)then
			nsx=x1
			nex=x1
			min_y=y1
		else //top edge clip
			nsx=x1-delta_sx*y1
			nex=x1-delta_ex*y1
			min_y=0
		end
	   
		max_y=min(y2,128)
	   
		for y=min_y,max_y-1 do
			rectfill(nsx,y,nex,y,color1)
			nsx+=delta_sx
			nex+=delta_ex
		end
	else // top edge is horizontal
		nsx=x1
		nex=x2
	end

	// bottom part of triangle
	if(y3!=y2)then
		local delta_sx=(x3-x1)/(y3-y1)
		local delta_ex=(x3-x2)/(y3-y2)
	   
		min_y=y2
		max_y=min(y3,128)
		if(y2<0)then
			nex=x2-delta_ex*y2
			nsx=x1-delta_sx*y1
			min_y=0
		end
	   
		 for y=min_y,max_y do
				rectfill(nsx,y,nex,y,color1)
				nex+=delta_ex
				nsx+=delta_sx
		 end
	   
	else //bottom edge is horizontal
		rectfill(nsx,y3,nex,y3,color1)
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

function dotprod(a,b)
	assert(#a==3 and #b==3)
	return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]
end

// transforms vertices into 
// homogeneous coordinate matrix
function hom_verts(p)
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

function viewport_transform(pp)
	for i=1,#pp do
		pp[i][1]=64+64*pp[i][1]
		pp[i][2]=64+64*pp[i][2]
		pp[i][3]=64+64*pp[i][3]
	end
end

function hom_to_3d(hp)
	local v={}
	for i=1,hp.cols do
		local px=hp[1][i]/hp[4][i]
		local py=hp[2][i]/hp[4][i]
		local pz=hp[3][i]/hp[4][i]
		add(v,{px,py,py})
	end
	return v
end

function get_mov(dx,dz)
	local mov={
		{1,0,0,dx},
		{0,1,0,0},
		{0,0,1,dz},
		{0,0,0,1}}
	mov.rows=4
	mov.cols=4
	return mov
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
--data
fox_v_string="fe7106e700c6fec605aeffebfe1404b600d8fe6605e001f9fe710734027dfe4404b701b1ff8b0a06ffabff0b099affedff870a590009ff1b0a7f0055ff3d03c6fd3dfedd0350fdbdff2004dbfe4403060356fda9027d0504fdf4029a04a7ffc5fd5d0041fdf7fd0100ccfefbfd4000e7fd49feb102d6fd21fe2101d9fe0afded028afe43fe9d03acffb9feda048effb8fdf408580070fe9b08b7ffeffefa073e0022fe6403060010fe98039a0038fed8028bff84fe5b022e008afe2c0344012bfd1b0162fe5ffd7509720219fdd50a210283fe5d0a870114fc8f081b016dfc3608fb01c4029f0154fd2702ba02cbfce9fdb00947010d004d0a860072013d09ac01b5015508a100af01e905af002cfdb90110fc4600430775ffbdff36086effccfdbb09ec00e5005e069cff2d012006acffd000fa05ecfdbefdbf005ffc21fe9300d0fb63ff05033ffcd5034d0271ff3203360143fd73ff600bb0ffd6ff550bd70064ff6c0aef012400560a970157000609a3ffe3015f0484fc970007050bfd1dffc70acbffd1ffce06c0ff77fdc7008dfc96feaa03daff3cfda401c0fff2fd96011f000eff440272fc65ff090585ff69ffac061eff0e01d0061a00da017e06ce00affe0b07b80232fdbc07f20102021f007afc8e01050051fb7f01cd0278fbeefe2701d4ff6afd84019efeaafea201bdfd13fd360054ff40fec5032efe91033a0116ff22ff7903a5fcfdfe6801acfc32fd9c016dfd6301a8072f015afc9908430266ff870168fc77fef90aef00df012103dffc3afea0053c027e005502ecfbf9ffff00e9fb2401a300e000ad020f0053012a024d005f0018ffa6009d02ccffaf00b8017cfee100ce0195fe9400e3007dfe8d00ee0124fe8901fd012eff7c0b7c03dbffe20a5203d600460ad1033200dc0816030bffaf09ca03d0ff3f09d70333fef608c203c4ff71093c03acfe3c08570313fee5fffd027afe4d00920213009d014afbae011d08e3029600dc076402cdfeae026f019fff8f01b50166ffd7031b0199002103c80234ffdb00f00219006e00d80249ff3f0aa9034bffa40a4e036f029603370018015c025100e8026f021100f8fdc80093fff7012b01c301d900e903a6026f0116005b0151032f02210007007206a402e0ffb707e70375ff62050702f6fde0092d02a801f7051800f900df04f902e6017a044801fffdb7002701beff5b0ab40236ff690bb70361ffd10052fb3aff6104160230ff1e0a8a028bfd75fffcff59fd48fffcff2afd59fffcfe94fdd0fffc0193fe03fffc015dfdddfffc01f2fee1fffc0276feb6fffc008ffec4fffcfbe4fe1cfffc022bfee2fffc02790257fffcfd84021afffc00c1023ffffcfd44026cfffcff880024fffc02efff72fffc0311ffdffffcfb6c0272fffcfdd2026dfffcfd8e02a1fffcff2bfdadfffcfceefd82fffcfda9fe3dfffcfc20fe6afffcfc08fe7dfffc006afe05fffc01410093fffc016f004bfffc02dc0060fffcfb88fe93fffcfc030179fffcfc2000cffffc013c011dfffcfbc101a1fffc0138fee4fffc0274fee8fffc0266fee9fffc026afeeafffc026ffef1fffc02870203fffc0129"
fox_f_string="01020301040504010306040307080909080a0b0c0d0e0f10111213141516170218191a1b1c1d1e1f201c21131222232425261927280e291a192a2b2c2d100f2e13212f1b30222431323334342d0f352e360c0b370e3839280f0e332d342a3a3b2a3c3d072a3e3e08073f40342a413a1926291b2f42400b0d35432e4417180a4109412a07451246470b40481b49021b484a2d4b014c4d3e30084e4f50270e39511c1e5115521e16511553525412111e4455284e5038563947570b160c144551521c2003200603322f333a410a582e59525859312408262229223129493234400d4902011b48490d2c2f3e2c5a4b4b332c1848441a301b01191b5b262532422f254d4c3d2b2a503f280c16550d44483e2f30440c55475c531453152152595116154b2d3303021717441e171e1d1c031d31081a301a081b4249014d1955161e180248332f2c4934405d3a0a3249424d25194c01053f340f3b3c2a2a2c3e29311a505e3f375747431113351143240a082112455f040628274e604740440d0c57370b475314471437525358461c45592e21140c3743132e283f0f4552215d3b3a171d03245d0a451c5161585361535c626364656667681f46696a686b6c6d6e6c6f707172057173746775766050776e78797a7b7c7d7e7f7080686a1f697567362e58380e10677a7969676a1f1c468182838468467e8586667a675b254c8782858883648446126774657d657e657d66898a8b058a715b738c8d5a8e775a2b108d818c232286858f857e87586136868f8e6287638287625688647569905e6040045f8b91926d7170238d828180706f614f9389788a8a058b8183886c6b802b6d6c6e728a828d8f56388894067b79206a7d7a66504f760941072b5a2c2391243d916d9123953d6d2b3d3c9171238c8c225b3881886b6d92957f6b956b9270726f6c806f6c6e776f726e7f9570952370718c738a786e8a72718b5f94867c7e764f61772b6c24915d5b4c735b2226785a778e5a894b5a4a5a8d4a8d2d4a8b05041254848f858247605c7b7d7c5d3c3b8382626a201f7b06790620796b7f80913c5d78895a06945f8e898b7c8e8b10813864836260765c8d8e8f947b7c8e7c86947c8b7b7a7d67796a5c76614c0573403f5e5e50602d8d10959291a09f9cb5b74fb54f4ea1a34ea14e27a9a127a92739989754985411aead35ae3536a79e93abac11ab1135a8a939a83956aaa856a3b54eac9811af9d68af6884bda665bd65749b9f759b7590a6a565b6b8879796849784549db068a2a464b09a69b06968b2b17e9a99909a90699fa0749f7475b3a793b3934f9eb4619e6193bea264be6463b4ae36b43661a4aa56a45664b1b687b1877e96af84999b90a5b27ea57e65b8be63b86387a09c74babb749cb974b9ba74adab35b7b34fbcbd74bbbc74"

// z-order test
--[[
model_points={
{-0.532615, -0.007205, 0.702320},
{0.985950, 0.097147, -0.445256},
{-0.428264, 1.511360, -0.445256},
{0.625486, 1.000000, 0.000000},
{-0.997431, 0.000000, 0.000000},
{0.625486, -1.000000, 0.000000}
}

model_faces={
{1,2,3},
{4,5,6}
}
]]--

// single triangle
model_points={
{0.625486, 1.000000, 0.000000},
{-0.997431, 0.000000, 0.000000},
{0.625486, -1.000000, 0.000000}
}

model_faces={
{1,2,3},
}
-->8
--decoding
hex_string_data = "0123456789abcdef"
char_to_hex = {}
for i=1,#hex_string_data do
	char_to_hex[sub(hex_string_data,i,i)]=i-1
end

cur_string=""
cur_string_index=1
function load_string(string)
	cur_string=string
 cur_string_index=1
end

function read_byte(string)
 return char_to_hex[sub(string,1,1)]*16+char_to_hex[sub(string,2,2)]
end

function read_2byte_fixed(string)
 local a=read_byte(sub(string,1,2))
 local b=read_byte(sub(string,3,4))
 local val =a*256+b
 return val/256
end

function read_vector()
 v={}
 for i=1,3 do
  text=sub(cur_string,cur_string_index,cur_string_index+4)
  value=read_2byte_fixed(text)
  v[i]=value
  cur_string_index+=4
 end
 return v
end

function read_face()
 f={}
 for i=1,3 do
  text=sub(cur_string,cur_string_index,cur_string_index+2)
  value=read_byte(text)
  f[i]=value
  cur_string_index+=2
 end
 return f
end       

function read_vector_string(string)
 vector_list={}
 load_string(string)
 while cur_string_index<#string do
  vector=read_vector()
  add(vector_list,vector)
 end
 return vector_list
end

function read_face_string(string)
 face_list={}
 load_string(string)
 while cur_string_index<#string do
  face=read_face()
  add(face_list,face)
 end
 return face_list
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

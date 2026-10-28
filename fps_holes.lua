-- Floor openings and pressure plates as world geometry.
-- Pits, open trapdoors and crawlspaces get inner walls and a bottom below the
-- floor (crawlspaces also their wooden ladder). Below-floor faces are clipped to the frustum through their opening
-- (camera + opening rectangle at z=0), so nothing ever shows through solid
-- floor even though they are painted after it. Pressure plates get a raised
-- disc that sinks when pressed. The native flat frames still render as decals.
local M={}

M.PIT_DEPTH=26
M.HOLE_DEPTH=22
M.HOLE_HALF=11      -- trapdoor/crawlspace opening half-size (native art ~26 px)
M.PLATE_RADIUS=8.5
M.PLATE_HEIGHT=4
M.PLATE_PRESSED=1.2

local PIT_WALL={.20,.16,.14,1}
local PIT_BOTTOM={.035,.03,.03,1}

local function vertex(x,y,z) return {x=x,y=y,z=z,u=0,v=0,cameraPoint={}} end

local function shaded(tint,n)
    -- Same fixed light direction as the obstacle and spike meshes.
    local light=math.max(0,-n.x*.36-n.y*.48+n.z*.80)
    local shade=.45+.55*light
    return {tint[1]*shade,tint[2]*shade,tint[3]*shade,tint[4] or 1}
end

local function face(points,color,n,worldX,worldY)
    local vertices,cx,cy,cz={},0,0,0
    for i,p in ipairs(points) do
        vertices[i]=vertex(p.x,p.y,p.z)
        cx,cy,cz=cx+p.x,cy+p.y,cz+p.z
    end
    local count=#points
    return {vertices=vertices,color=color,solid=true,normal=n,convex=true,
        center={x=cx/count,y=cy/count,z=cz/count},worldX=worldX,worldY=worldY,
        projection={points={},clipped={},intersections={}}}
end

-- Sutherland-Hodgman: keep the part of a convex polygon with n.(p-o) >= 0.
local function clip(poly,ox,oy,oz,nx,ny,nz)
    local out={}
    local count=#poly
    for i=1,count do
        local a,b=poly[i],poly[i%count+1]
        local da=(a.x-ox)*nx+(a.y-oy)*ny+(a.z-oz)*nz
        local db=(b.x-ox)*nx+(b.y-oy)*ny+(b.z-oz)*nz
        if da>=0 then out[#out+1]=a end
        if (da>=0)~=(db>=0) then
            local t=da/(da-db)
            out[#out+1]={x=a.x+(b.x-a.x)*t,y=a.y+(b.y-a.y)*t,z=a.z+(b.z-a.z)*t}
        end
    end
    return out
end

-- The part of a below-floor polygon visible from eye e through the opening
-- rectangle [x0,x1]x[y0,y1] at z=0; nil when nothing is visible.
local function portalClip(poly,e,corners,mx,my)
    for i=1,4 do
        local a,b=corners[i],corners[i%4+1]
        local ax,ay,az=a.x-e.x,a.y-e.y,a.z-e.z
        local bx,by,bz=b.x-e.x,b.y-e.y,b.z-e.z
        local nx,ny,nz=ay*bz-az*by,az*bx-ax*bz,ax*by-ay*bx
        if (mx-e.x)*nx+(my-e.y)*ny+(0-e.z)*nz<0 then nx,ny,nz=-nx,-ny,-nz end
        poly=clip(poly,e.x,e.y,e.z,nx,ny,nz)
        if #poly<3 then return nil end
    end
    return poly
end
function M.throughPortal(poly,e,x0,y0,x1,y1)
    if e.z<=0 then return nil end
    return portalClip(poly,e,{{x=x0,y=y0,z=0},{x=x1,y=y0,z=0},{x=x1,y=y1,z=0},{x=x0,y=y1,z=0}},(x0+x1)/2,(y0+y1)/2)
end

-- Inner walls (two shading bands) and bottom of one square opening.
-- edges: {dx,dy} outward directions that get a wall. Each piece is passed to
-- emit(points,color,normal).
local function shaft(x0,y0,x1,y1,depth,edges,e,emit,wall,bottom)
    local bands={{0,-depth*.35,1},{-depth*.35,-depth,.6}}
    for _,edge in ipairs(edges) do
        local dx,dy=edge[1],edge[2]
        local ax,ay,bx,by
        if dx==1 then ax,ay,bx,by=x1,y0,x1,y1
        elseif dx==-1 then ax,ay,bx,by=x0,y1,x0,y0
        elseif dy==1 then ax,ay,bx,by=x1,y1,x0,y1
        else ax,ay,bx,by=x0,y0,x1,y0 end
        -- The wall faces into the opening; only its camera side is drawn.
        local n={x=-dx,y=-dy,z=0}
        if (e.x-ax)*n.x+(e.y-ay)*n.y>.001 then
            local color=shaded(wall,n)
            for _,band in ipairs(bands) do
                local top,low,k=band[1],band[2],band[3]
                emit({{x=ax,y=ay,z=top},{x=bx,y=by,z=top},{x=bx,y=by,z=low},{x=ax,y=ay,z=low}},
                    {color[1]*k,color[2]*k,color[3]*k,color[4]},n)
            end
        end
    end
    emit({{x=x0,y=y0,z=-depth},{x=x1,y=y0,z=-depth},{x=x1,y=y1,z=-depth},{x=x0,y=y1,z=-depth}},
        bottom,{x=0,y=0,z=1})
end

local function cellRect(map,i)
    local x0=map.ox+(i%map.width)*40
    local y0=map.oy+math.floor(i/map.width)*40
    return x0,y0,x0+40,y0+40
end

local function isPit(map,i)
    local cell=map.cells[i]
    return cell~=nil and cell.pit==true and not map.outside[i]
end

local pitCache={}
-- Pit clipping is rebuilt as the eye moves. Reuse its temporary polygons and
-- final faces instead of allocating hundreds of vertex/projection tables each
-- render. Other portal callers keep the original owned-result API.
local pitFaces,pitFacePool={},{}
local clipA,clipB,clipPoints={},{},{}
local function pitPortalClip(poly,e,corners,mx,my)
    local used=0
    for plane=1,4 do
        local a,b=corners[plane],corners[plane%4+1]
        local ax,ay,az=a.x-e.x,a.y-e.y,a.z-e.z
        local bx,by,bz=b.x-e.x,b.y-e.y,b.z-e.z
        local nx,ny,nz=ay*bz-az*by,az*bx-ax*bz,ax*by-ay*bx
        if (mx-e.x)*nx+(my-e.y)*ny-e.z*nz<0 then nx,ny,nz=-nx,-ny,-nz end
        local out=plane%2==1 and clipA or clipB
        local count,n=#poly,0
        for i=1,count do
            local p,q=poly[i],poly[i%count+1]
            local dp=(p.x-e.x)*nx+(p.y-e.y)*ny+(p.z-e.z)*nz
            local dq=(q.x-e.x)*nx+(q.y-e.y)*ny+(q.z-e.z)*nz
            if dp>=0 then n=n+1;out[n]=p end
            if (dp>=0)~=(dq>=0) then
                local t=dp/(dp-dq)
                used=used+1
                local v=clipPoints[used]
                if not v then v={};clipPoints[used]=v end
                v.x,v.y,v.z=p.x+(q.x-p.x)*t,p.y+(q.y-p.y)*t,p.z+(q.z-p.z)*t
                n=n+1;out[n]=v
            end
        end
        for i=#out,n+1,-1 do out[i]=nil end
        if n<3 then return nil end
        poly=out
    end
    return poly
end

local function pitFace(index,points,color,normal,wx,wy)
    local f=pitFacePool[index]
    if not f then
        f={vertices={},color={},center={},solid=true,convex=true,
            projection={points={},clipped={},intersections={}}}
        pitFacePool[index]=f
    end
    local cx,cy,cz=0,0,0
    local vertices=f.vertices
    for i,p in ipairs(points) do
        local v=vertices[i]
        if not v then v=vertex(0,0,0);vertices[i]=v end
        v.x,v.y,v.z,v.u,v.v=p.x,p.y,p.z,0,0
        cx,cy,cz=cx+p.x,cy+p.y,cz+p.z
    end
    for i=#vertices,#points+1,-1 do vertices[i]=nil end
    local changed=false
    for i=1,4 do
        if f.color[i]~=color[i] then changed=true end
        f.color[i]=color[i]
    end
    if changed then f.nativeColor=nil end
    f.normal,f.worldX,f.worldY=normal,wx,wy
    f.center.x,f.center.y,f.center.z=cx/#points,cy/#points,cz/#points
    -- World vertices now change in place. Invalidate geometry-derived caches,
    -- including flattened shader pieces that otherwise assume immutable meshes.
    f.gpuSphere=nil
    if f.projected then
        f.projected.projectionEpoch=nil
        f.projected.gpuPieces,f.projected.gpuPiecesReverse=nil,nil
    end
    return f
end

-- Pit layout per map revision: connected pit cells merged into a few
-- rectangles (viewing openings and bottoms) and pit walls merged into long
-- straight runs. 0.5.43 F8 in the Mega Satan room (65 pit cells) showed the
-- old per-cell version spending 14 ms a frame clipping every cell's pieces
-- through up to 25 neighbouring cell openings whenever the camera moved.
local function pitLayout(map)
    local width=map.width
    local rects,walls={},{}
    local used={}
    local cells={}
    for i,cell in pairs(map.cells) do
        if cell.pit and not map.outside[i] then cells[#cells+1]=i end
    end
    table.sort(cells)
    for _,i in ipairs(cells) do
        if not used[i] then
            local col,row=i%width,math.floor(i/width)
            local w=1
            while col+w<width and isPit(map,i+w) and not used[i+w] do w=w+1 end
            local h=1
            while true do
                local start=i+h*width
                local ok=true
                for k=0,w-1 do
                    if not isPit(map,start+k) or used[start+k] then ok=false;break end
                end
                if not ok then break end
                h=h+1
            end
            for dy=0,h-1 do for dx=0,w-1 do used[i+dy*width+dx]=true end end
            local x0,y0=cellRect(map,i)
            local x1,y1=x0+w*40,y0+h*40
            -- Opening corners at z=0, made once per layout (0.5.131).
            rects[#rects+1]={x0=x0,y0=y0,x1=x1,y1=y1,mx=(x0+x1)/2,my=(y0+y1)/2,
                corners={{x=x0,y=y0,z=0},{x=x1,y=y0,z=0},{x=x1,y=y1,z=0},{x=x0,y=y1,z=0}}}
        end
    end
    -- Wall runs: cell edges between pit and non-pit, merged along a line.
    local runs={}
    local function addRun(dx,dy,line,from,to)
        local key=dx..':'..dy..':'..line
        local list=runs[key]
        if not list then list={dx=dx,dy=dy,line=line};runs[key]=list;runs[#runs+1]=list end
        list[#list+1]={from,to}
    end
    for _,i in ipairs(cells) do
        local col,row=i%width,math.floor(i/width)
        local x0,y0,x1,y1=cellRect(map,i)
        if col==width-1 or not isPit(map,i+1) then addRun(1,0,x1,y0,y1) end
        if col==0 or not isPit(map,i-1) then addRun(-1,0,x0,y0,y1) end
        if not isPit(map,i+width) then addRun(0,1,y1,x0,x1) end
        if row==0 or not isPit(map,i-width) then addRun(0,-1,y0,x0,x1) end
    end
    for _,list in ipairs(runs) do
        table.sort(list,function(a,b) return a[1]<b[1] end)
        local merged={}
        for _,span in ipairs(list) do
            local last=merged[#merged]
            if last and span[1]<=last[2]+1e-6 then last[2]=math.max(last[2],span[2])
            else merged[#merged+1]={span[1],span[2]} end
        end
        for _,span in ipairs(merged) do
            local dx,dy,line=list.dx,list.dy,list.line
            local ax,ay,bx,by
            -- Same vertex order as shaft(): the wall faces into the opening.
            if dx==1 then ax,ay,bx,by=line,span[1],line,span[2]
            elseif dx==-1 then ax,ay,bx,by=line,span[2],line,span[1]
            elseif dy==1 then ax,ay,bx,by=span[2],line,span[1],line
            else ax,ay,bx,by=span[1],line,span[2],line end
            walls[#walls+1]={ax=ax,ay=ay,bx=bx,by=by,n={x=-dx,y=-dy,z=0}}
        end
    end
    return {rects=rects,walls=walls,cells=#cells}
end

local layoutCache={}
M.stats={pitCells=0,pitRects=0,pitWalls=0,pitClips=0}
-- 0.5.131 (user: an empty big room still stutters; F8: ws_pits 10.6 ms and
-- 2.4 MB of garbage per frame with 68 pit cells = 21 openings, 60 wall
-- runs): every wall band and bottom was clipped through all 21 openings
-- whenever the camera moved (~1700 clips, each building tables), though
-- most pairs cannot see each other. A piece is seen through an opening only
-- where its projection from the eye onto the floor plane meets the opening,
-- so the projection's bounding box rejects the rest without allocating; the
-- clip result is unchanged (the test is conservative).
M.PREFILTER=true

-- Pit walls (two shading bands) and bottoms, each clipped through every
-- merged pit opening it can be seen through.
function M.pits(map,e)
    -- 0.5.52: keys compared field by field; the former string key built
    -- tostring(map) and float-to-string conversions every frame.
    local revision=map.revision or 0
    local c=pitCache
    if c.map==map and c.revision==revision and c.ex==e.x and c.ey==e.y and c.ez==e.z then return c.faces end
    if layoutCache.map~=map or layoutCache.revision~=revision then
        layoutCache={map=map,revision=revision,layout=pitLayout(map)}
        pitFaces,pitFacePool={},{}
    end
    local layout=layoutCache.layout
    M.stats.pitCells,M.stats.pitRects,M.stats.pitWalls=layout.cells,#layout.rects,#layout.walls
    local faces=pitFaces
    local faceCount=0
    local depth=M.PIT_DEPTH
    local rects,clips=layout.rects,0
    local function emit(points,color,n,wx,wy)
        if e.z<=0 then return end
        local bx0,by0,bx1,by1=math.huge,math.huge,-math.huge,-math.huge
        for i=1,#points do
            local q=points[i]
            local t=e.z/(e.z-q.z)
            local x,y=e.x+(q.x-e.x)*t,e.y+(q.y-e.y)*t
            if x<bx0 then bx0=x end
            if x>bx1 then bx1=x end
            if y<by0 then by0=y end
            if y>by1 then by1=y end
        end
        for k=1,#rects do
            local r=rects[k]
            if not M.PREFILTER or (bx1>=r.x0 and bx0<=r.x1 and by1>=r.y0 and by0<=r.y1) then
                clips=clips+1
                local visible=pitPortalClip(points,e,r.corners,r.mx,r.my)
                if visible then
                    faceCount=faceCount+1
                    faces[faceCount]=pitFace(faceCount,visible,color,n,wx,wy)
                end
            end
        end
    end
    local bands={{0,-depth*.35,1},{-depth*.35,-depth,.6}}
    for _,w in ipairs(layout.walls) do
        local n=w.n
        if (e.x-w.ax)*n.x+(e.y-w.ay)*n.y>.001 then
            local color=shaded(PIT_WALL,n)
            local wx,wy=(w.ax+w.bx)/2,(w.ay+w.by)/2
            for _,band in ipairs(bands) do
                local top,low,k=band[1],band[2],band[3]
                emit({{x=w.ax,y=w.ay,z=top},{x=w.bx,y=w.by,z=top},{x=w.bx,y=w.by,z=low},{x=w.ax,y=w.ay,z=low}},
                    {color[1]*k,color[2]*k,color[3]*k,color[4]},n,wx,wy)
            end
        end
    end
    local up={x=0,y=0,z=1}
    for _,r in ipairs(layout.rects) do
        emit({{x=r.x0,y=r.y0,z=-depth},{x=r.x1,y=r.y0,z=-depth},{x=r.x1,y=r.y1,z=-depth},{x=r.x0,y=r.y1,z=-depth}},
            PIT_BOTTOM,up,(r.x0+r.x1)/2,(r.y0+r.y1)/2)
    end
    M.stats.pitClips=clips
    for i=#faces,faceCount+1,-1 do faces[i]=nil end
    pitCache={map=map,revision=revision,ex=e.x,ey=e.y,ez=e.z,faces=faces}
    return faces
end

-- Trapdoor (17) / crawlspace (18): open unless the native animation is closed.
function M.holeOpen(kind,animation)
    local name=(animation or ''):lower()
    if kind==17 then return name=='opened' or name=='player exit' or name:find('open animation',1,true)~=nil
        or name=='openanimation' end
    if kind==18 then return not name:find('closed',1,true) end
    return false
end

-- Crawlspace ladder (native door_20_secrettrapdoor: a wooden ladder hangs
-- from the north edge of the opening into the dark). Two rails lean from
-- the north rim down to the bottom with rungs between them; trapdoors (17)
-- have no ladder, which is the visible difference between the two.
local LADDER_RAIL={.50,.31,.17,1}
local LADDER_RUNG={.62,.40,.22,1}
M.LADDER_HALF=6      -- rail centre offset from the opening centre
M.LADDER_RUNGS=5

local function ladder(x,y0,depth,e,emit)
    local half,rail=M.LADDER_HALF,1
    -- Top touches the north rim, the foot leans 5 units into the opening.
    local function at(t) return y0+.6+4.4*t,-.8-t*(depth-1.8) end
    local function slab(ax0,ax1,t0,t1,thick,tint)
        local ya,za=at(t0)
        local yb,zb=at(t1)
        -- Front (facing into the opening) and the two sides of a thin bar.
        local dy,dz=yb-ya,zb-za
        local len=math.sqrt(dy*dy+dz*dz)
        local n={x=0,y=-dz/len,z=dy/len}
        if n.y<0 then n={x=0,y=-n.y,z=-n.z} end
        local fy,fz=n.y*thick,n.z*thick
        emit({{x=ax0,y=ya+fy,z=za+fz},{x=ax1,y=ya+fy,z=za+fz},{x=ax1,y=yb+fy,z=zb+fz},{x=ax0,y=yb+fy,z=zb+fz}},tint,n)
        emit({{x=ax0,y=ya,z=za},{x=ax0,y=ya+fy,z=za+fz},{x=ax0,y=yb+fy,z=zb+fz},{x=ax0,y=yb,z=zb}},tint,{x=-1,y=0,z=0})
        emit({{x=ax1,y=ya+fy,z=za+fz},{x=ax1,y=ya,z=za},{x=ax1,y=yb,z=zb},{x=ax1,y=yb+fy,z=zb+fz}},tint,{x=1,y=0,z=0})
    end
    for _,side in ipairs({-1,1}) do
        local cx=x+side*half
        slab(cx-rail,cx+rail,0,1,1.6,LADDER_RAIL)
    end
    for i=1,M.LADDER_RUNGS do
        local t=(i-.4)/M.LADDER_RUNGS
        slab(x-half+rail,x+half-rail,t-.035,t+.035,2.4,LADDER_RUNG)
    end
end

function M.hole(x,y,e,depth,kind)
    local h=M.HOLE_HALF
    local faces={}
    local x0,y0,x1,y1=x-h,y-h,x+h,y+h
    depth=depth or M.HOLE_DEPTH
    shaft(x0,y0,x1,y1,depth,{{1,0},{-1,0},{0,1},{0,-1}},e,function(points,color,n)
        local visible=M.throughPortal(points,e,x0,y0,x1,y1)
        if visible then faces[#faces+1]=face(visible,color,n,x,y) end
    end,{.16,.13,.12,1},{.02,.02,.025,1})
    if kind==18 then
        ladder(x,y0,depth,e,function(points,tint,n)
            local cx,cy,cz=0,0,0
            for _,p in ipairs(points) do cx,cy,cz=cx+p.x,cy+p.y,cz+p.z end
            cx,cy,cz=cx/#points,cy/#points,cz/#points
            -- Only faces turned toward the camera.
            if (e.x-cx)*n.x+(e.y-cy)*n.y+(e.z-cz)*n.z<=.001 then return end
            local visible=M.throughPortal(points,e,x0,y0,x1,y1)
            if visible then faces[#faces+1]=face(visible,shaded(tint,n),n,x,y) end
        end)
    end
    return faces
end

-- Pressure plate state from its native animation: Off* raised, else pressed.
function M.platePressed(animation)
    local name=animation or ''
    if name:find('^Off') then return false end
    return true
end

function M.plateTint(animation)
    local name=animation or ''
    if name:find('Red',1,true) then return {.86,.24,.24,1} end
    if name:find('Pentagram',1,true) then return {.30,.20,.20,1} end
    return {.40,.39,.41,1}
end

local plateCache={}

-- Octagonal disc centred at (x,y); cached per grid index and state.
function M.plate(index,x,y,animation,tintScale)
    local pressed=M.platePressed(animation)
    local tint=M.plateTint(animation)
    local s=tintScale or {1,1,1,1}
    tint={tint[1]*s[1],tint[2]*s[2],tint[3]*s[3],tint[4]*s[4]}
    if pressed then tint={tint[1]*.7,tint[2]*.7,tint[3]*.7,tint[4]} end
    local height=pressed and M.PLATE_PRESSED or M.PLATE_HEIGHT
    local key=table.concat({x,y,height,tint[1],tint[2],tint[3],tint[4]},':')
    local old=plateCache[index]
    if old and old.key==key then return old.faces end
    local faces={}
    local ring={}
    local r=M.PLATE_RADIUS
    for i=1,8 do
        local t=(i-1)*math.pi/4+math.pi/8
        ring[i]={x=x+math.cos(t)*r,y=y+math.sin(t)*r*.8}
    end
    for i=1,8 do
        local a,b=ring[i],ring[i%8+1]
        local nx,ny=(a.y-b.y),(b.x-a.x)
        local len=math.sqrt(nx*nx+ny*ny)
        -- Ring runs counter-clockwise in screen space; flip to point outward.
        local mx,my=(a.x+b.x)/2-x,(a.y+b.y)/2-y
        if nx*mx+ny*my<0 then nx,ny=-nx,-ny end
        local n={x=nx/len,y=ny/len,z=0}
        faces[#faces+1]=face({{x=a.x,y=a.y,z=height},{x=b.x,y=b.y,z=height},
            {x=b.x,y=b.y,z=.25},{x=a.x,y=a.y,z=.25}},shaded(tint,n),n,x,y)
    end
    local top={}
    for i=8,1,-1 do top[#top+1]={x=ring[i].x,y=ring[i].y,z=height} end
    faces[#faces+1]=face(top,shaded(tint,{x=0,y=0,z=1}),{x=0,y=0,z=1},x,y)
    plateCache[index]={key=key,faces=faces}
    return faces
end

function M.reset() pitCache={};plateCache={};layoutCache={};pitFaces={};pitFacePool={} end

return M

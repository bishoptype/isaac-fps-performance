-- Keep Isaac's weapon/charge state machine; only adapt camera input and aim.
local maths=include('fps_math')
local geometry=include('fps_attack_geometry')
local melee=include('fps_melee')
local synergy=include('fps_gun_synergy')
local M={}

function M.nativeYaw(yaw) return math.floor(yaw/(math.pi/2)+.5)*(math.pi/2) end

-- 0.5.57: the direction the engine actually fired in. Our shoot actions aim
-- the nearest cardinal (nativeYaw), but the native Mouse Control option (on
-- during FPS since 0.5.37) fires a held left button toward the cursor, which
-- the FPS view keeps at the screen centre: an arbitrary top-down direction.
-- Rotating such a shot as if it were cardinal sent native tears off the
-- reticle. The player's aim direction covers both; the cardinal is the
-- fallback when it is unavailable or zero. c.fireBase (gun bullets) wins.
-- 0.5.68: a charged attack (Azazel's/Brimstone's beam) fires on release,
-- when the aim direction is already zero, so the last non-zero aim seen in a
-- player update (observeAim) is the base before falling back to the cardinal.
local lastAim={}
M.MUZZLE_AHEAD=12      -- 0.5.73: gun shots start this far along the muzzle ray
-- 0.5.73: the launch point of every gun attack: MUZZLE_AHEAD along the view
-- ray through the muzzle as drawn (c.muzzleAim: hip or ADS, any gun form),
-- aimed along yaw/c.pitch. Returns the horizontal offset from the player
-- and the height. Without muzzleAim, the old fixed muzzle (right 5, down 8).
-- side (or c.muzzleSide) -1: the left gun of a dual pair (0.5.78).
function M.gunMuzzle(c,yaw,side)
    side=side or c.muzzleSide or 1
    local a,b
    if c.muzzleAim then a,b=c.muzzleAim(side) end
    local D=M.MUZZLE_AHEAD
    if not a then a,b=5/D*side,-8/D end
    yaw=yaw or c.yaw
    local cp,sp=math.cos(c.pitch or 0),math.sin(c.pitch or 0)
    local fx,fy,rx,ry=math.cos(yaw),math.sin(yaw),-math.sin(yaw),math.cos(yaw)
    return D*(fx*cp+a*rx-b*fx*sp),D*(fy*cp+a*ry-b*fy*sp),c.eye+D*(sp+b*cp)
end
local function aimAngleOf(p)
    if not p or type(p.GetAimDirection)~='function' then return nil end
    local ok,aim=pcall(p.GetAimDirection,p)
    if ok and aim and aim.X*aim.X+aim.Y*aim.Y>.25 then return math.atan(aim.Y,aim.X) end
    return nil
end
function M.observeAim(p)
    local angle=aimAngleOf(p)
    if angle then lastAim[GetPtrHash(p)]=angle end
end
function M.resetAim() lastAim={} end
-- 0.5.69: user still saw native tears off the reticle. While the left
-- button is held two native aims coexist: our shoot action (the nearest
-- cardinal, which GetAimDirection may report) and Mouse Control's direction
-- toward the centred cursor, and either may be the one the engine fired
-- along. With the shot's actual angle given, the base is the candidate it
-- left closest to (aim, mouse-to-player, last aim, cardinal), so the
-- remaining difference is only the native spread/multi-shot offset.
local function mouseAngleOf(p)
    if not p or not Input or type(Input.GetMousePosition)~='function' then return nil end
    local ok,mouse=pcall(Input.GetMousePosition,true)
    if not ok or not mouse or not p.Position then return nil end
    local dx,dy=mouse.X-p.Position.X,mouse.Y-p.Position.Y
    if dx*dx+dy*dy<1 then return nil end
    return math.atan(dy,dx)
end
local function delta(a,b) return math.abs((a-b+math.pi)%(2*math.pi)-math.pi) end
-- 0.5.112 (friend: tears no longer go up or down): the native tear log
-- keeps up to AIM_LOG_PER_SIDE tears for each view quarter (east, south,
-- west, north) instead of the first 24, so every direction shows up.
M.AIM_LOG_PER_SIDE=8
local aimLogged={0,0,0,0}
local function viewQuarter(yaw)
    return math.floor(((yaw+math.pi/4)%(2*math.pi))/(math.pi/2))%4+1
end
M.viewQuarter=viewQuarter
-- 0.5.106 (user: native tears still miss the reticle at times, e.g. facing
-- away from the room centre): a native tear also carries the player's
-- movement (EntityPlayer:GetTearMovementInheritance for its shot direction),
-- which skews the launched angle toward another candidate base. With the
-- velocity given, each candidate is judged on the velocity minus the
-- inheritance that candidate direction would add.
function M.inheritance(p,angle)
    if not p or type(p.GetTearMovementInheritance)~='function' then return 0,0 end
    local ok,v=pcall(p.GetTearMovementInheritance,p,Vector(math.cos(angle),math.sin(angle)))
    if ok and v and v.X and v.Y then return v.X,v.Y end
    return 0,0
end
-- 0.5.108: set by fps_guns for the whole of a gun shot. The gun's native
-- calls (FireTear, FireTechLaser, FireBrimstone, FireBomb, FireKnife...) all
-- leave along this cardinal, and so does whatever other items add to that
-- shot (Loki's Horns, Mom's Eye...); their laser/bomb/knife init callbacks run
-- inside the call, before the gun can tag them, so they take this base
-- instead of a guessed one.
M.firingBase=nil
function M.fireBase(p,c,actual,vx,vy)
    if c and c.fireBase then return c.fireBase end
    if M.firingBase then return M.firingBase end
    local aim=aimAngleOf(p)
    local last=p and lastAim[GetPtrHash(p)]
    local cardinal=M.nativeYaw(c.yaw)
    if actual then
        local function residual(candidate)
            if not vx then return delta(actual,candidate) end
            local ix,iy=M.inheritance(p,candidate)
            local ax,ay=vx-ix,vy-iy
            if ax*ax+ay*ay<1e-6 then return delta(actual,candidate) end
            return delta(math.atan(ay,ax),candidate)
        end
        local best,bestDelta=cardinal,residual(cardinal)
        -- 0.5.109 (user: shots toward a 45-degree diagonal are reliably off):
        -- near a diagonal the nearest cardinal flips with the slightest turn
        -- between the shot and its conversion, so both cardinals around the
        -- view are candidates, not only the nearest one.
        local q=math.pi/2
        local lower=math.floor(c.yaw/q)*q
        for _,candidate in ipairs({aim or false,mouseAngleOf(p) or false,last or false,lower,lower+q}) do
            if candidate then
                local d=residual(candidate)
                if d<bestDelta then best,bestDelta=candidate,d end
            end
        end
        return best
    end
    return aim or last or cardinal
end

function M.input(action,hook,yaw,firing,triggered)
    local directions={[0]=ButtonAction.ACTION_SHOOTRIGHT,[1]=ButtonAction.ACTION_SHOOTDOWN,
        [2]=ButtonAction.ACTION_SHOOTLEFT,[3]=ButtonAction.ACTION_SHOOTUP}
    local isShoot=action==ButtonAction.ACTION_SHOOTLEFT or action==ButtonAction.ACTION_SHOOTRIGHT
        or action==ButtonAction.ACTION_SHOOTUP or action==ButtonAction.ACTION_SHOOTDOWN
    if not isShoot then return nil end
    local pressed=firing and action==directions[math.floor(yaw/(math.pi/2)+.5)%4]
    if hook==InputHook.GET_ACTION_VALUE then return pressed and 1 or 0 end
    if hook==InputHook.IS_ACTION_TRIGGERED then return pressed and (triggered or false) end
    return pressed or false
end

local function parentKnife(entity)
    if entity.Type~=EntityType.ENTITY_KNIFE then return nil end
    local knife=entity:ToKnife()
    if knife.SubType==4 then return knife:GetHitboxParentKnife() end
    for _,source in pairs({entity.Parent,entity.SpawnerEntity}) do
        if source and source.Type==EntityType.ENTITY_KNIFE then return source:ToKnife() end
    end
end

local function directlyOwned(entity,p)
    if not p then return false end
    for _,source in pairs({entity.Parent,entity.SpawnerEntity}) do
        if source and GetPtrHash(source)==GetPtrHash(p) then return true end
    end
    return false
end

function M.owned(entity,p,seen,depth)
    if not entity or not p then return false end
    seen,depth=seen or {},depth or 0
    local id=GetPtrHash(entity)
    if id==GetPtrHash(p) then return true end
    if seen[id] or depth>=8 then return false end
    seen[id]=true
    local parent=parentKnife(entity)
    if parent and M.owned(parent,p,seen,depth+1) then return true end
    for _,source in pairs({entity.Parent,entity.SpawnerEntity}) do
        if source and M.owned(source,p,seen,depth+1) then return true end
    end
    return false
end

local function rotate(v,angle)
    local ca,sa=math.cos(angle),math.sin(angle)
    return Vector(v.X*ca-v.Y*sa,v.X*sa+v.Y*ca)
end

-- Set by fps_guns around its own FireTear call: the gun converts its bullet
-- once after fixing a flat trajectory, so the generic callback must skip it.
-- 0.5.108 (log: player tears at exact cardinals, 33-45 degrees off the
-- view, never converted): items such as Loki's Horns or Mom's Eye fire extra
-- tears inside that same call. They are collected here and converted by the
-- gun after its bullet (same base), instead of flying unturned.
M.suppressFire=false
M.suppressed={}

function M.fireTear(tear,p,c)
    if M.suppressFire then
        M.suppressed[#M.suppressed+1]=tear
        return nil
    end
    -- A native tear the gun already dropped (fps_guns) is not converted.
    if type(tear.Exists)=='function' and not tear:Exists() then return nil end
    local data=tear:GetData()
    if not directlyOwned(tear,p) or data.IsaacFPSProbe3D then return nil end
    -- 0.5.71: the Ludovico tear is steered, not launched (steerLudovico).
    if M.isLudovico(tear) then return nil end
    local v0=tear.Velocity
    local launched=math.atan(v0.Y,v0.X)
    local gun=c.fireBase~=nil
    local nativeYaw=M.fireBase(p,c,launched,v0.X,v0.Y)
    -- Native tears: the movement inheritance comes off before the turn and
    -- is added back for the new direction (gun rounds carry none).
    local ix,iy,jx,jy=0,0,0,0
    if not gun then
        ix,iy=M.inheritance(p,nativeYaw)
        jx,jy=M.inheritance(p,c.yaw)
    end
    -- 0.5.69/0.5.106: the first native tears of a session are logged with
    -- every candidate base, the inheritance and the player velocity, so a
    -- remaining aim mismatch can be read from log.txt (gun rounds are not).
    local quarter=viewQuarter(c.yaw)
    if not gun and aimLogged[quarter]<M.AIM_LOG_PER_SIDE and Isaac and Isaac.DebugString then
        aimLogged[quarter]=aimLogged[quarter]+1
        local aim,mouse=aimAngleOf(p),mouseAngleOf(p)
        local last=lastAim[GetPtrHash(p)]
        local pv=p.Velocity
        Isaac.DebugString(string.format('[Isaac FPS Probe] native tear aim: side=%s launched=%.1f speed=%.2f aim=%s mouse=%s last=%s cardinal=%.1f base=%.1f yaw=%.1f inherit=(%.2f,%.2f) playerVel=(%.2f,%.2f) mouseBtn=%s',
            ({'E','S','W','N'})[quarter],math.deg(launched),math.sqrt(v0.X*v0.X+v0.Y*v0.Y),aim and string.format('%.1f',math.deg(aim)) or '-',
            mouse and string.format('%.1f',math.deg(mouse)) or '-',last and string.format('%.1f',math.deg(last)) or '-',
            math.deg(M.nativeYaw(c.yaw)),math.deg(nativeYaw),math.deg(c.yaw),ix,iy,pv and pv.X or 0,pv and pv.Y or 0,
            tostring(Input and Input.IsMouseBtnPressed and Input.IsMouseBtnPressed(0))))
    end
    local turned=rotate(Vector(v0.X-ix,v0.Y-iy),c.yaw-nativeYaw)
    local velocity=Vector(turned.X+jx,turned.Y+jy)
    local nfx,nfy,nrx,nry=maths.basis(nativeYaw)
    local dx,dy=tear.Position.X-p.Position.X,tear.Position.Y-p.Position.Y
    local forward,side=dx*nfx+dy*nfy,dx*nrx+dy*nry
    local fx,fy,rx,ry=maths.basis(c.yaw)
    local cp,sp=math.cos(c.pitch),math.sin(c.pitch)
    -- Move the native muzzle/spread offsets into the same launch plane as
    -- velocity. A planar forward offset at eye height misses pitched aim.
    tear.Position=Vector(p.Position.X+fx*forward*cp+rx*side,
        p.Position.Y+fy*forward*cp+ry*side)
    local height=c.eye+forward*sp
    -- 0.5.73: gun rounds leave the drawn muzzle (fps_guns sets fromMuzzle).
    if c.fromMuzzle then
        local sx,sy,z=M.gunMuzzle(c,c.yaw)
        tear.Position=Vector(p.Position.X+sx,p.Position.Y+sy)
        height=z
    end
    local speed=math.sqrt(velocity.X^2+velocity.Y^2)
    -- Gun rounds use a straight aim ray. The native FallingSpeed getter may
    -- retain a downward step even after the gun set it to zero (live log:
    -- near-level pitch +0.5 deg produced vz=-0.20 instead of +0.17).
    -- Only native tears inherit their original falling/lobbing component.
    local vz=sp*speed-(gun and 0 or tear.FallingSpeed)
    tear.Velocity=Vector(velocity.X*cp,velocity.Y*cp)
    tear.Height,tear.FallingSpeed=-height,-vz
    -- Preserve native FallingAcceleration (lobbed/charged tears still arc),
    -- damage, flags, size, multi-shot offsets and their exact native count.
    local pose={x=tear.Position.X,y=tear.Position.Y,z=height}
    data.IsaacFPSProbe3D={vz=vz,remaining=math.max(1,p.TearRange),
        x=pose.x,y=pose.y,z=pose.z,
        render={previous=pose,current=pose,time=c.now or Isaac.GetTime()}}
    return true
end

-- 0.5.104 (user: some tears ignore the reticle, e.g. facing away from the
-- room centre): familiars (Brother Bobby and the like) fire along the
-- player's native aim, which Mouse Control points at the centred cursor,
-- i.e. the room centre in the top-down view, and nothing turned their tears.
-- A familiar tear is turned like the player's (base from fireBase, spread
-- kept), staying a native flat shot. Gun-dropped Incubus shots are gone.
function M.fireFamiliarTear(tear,p,c)
    if not tear or not p or not c then return nil end
    if type(tear.Exists)=='function' and not tear:Exists() then return nil end
    local data=tear:GetData()
    if data.IsaacFPSProbe3D or data.IsaacFPSGunShot or data.IsaacFPSFamiliarAimed then return nil end
    local spawner=tear.SpawnerEntity or tear.Parent
    local familiar=spawner and spawner.ToFamiliar and spawner:ToFamiliar()
    local owner=familiar and familiar.Player
    if not owner or GetPtrHash(owner)~=GetPtrHash(p) then return nil end
    local v=tear.Velocity
    if not v or v.X*v.X+v.Y*v.Y<.0001 then return nil end
    local launched=math.atan(v.Y,v.X)
    local base=M.fireBase(p,{yaw=c.yaw},launched)
    tear.Velocity=rotate(v,c.yaw-base)
    data.IsaacFPSFamiliarAimed=true
    return true
end

-- 0.5.71 Ludovico Technique: with the left button held the big tear flies
-- toward what the reticle points at: the enemy nearest the aim ray (within
-- LUDO_CONE), else the floor point the view ray reaches (or LUDO_FAR ahead).
-- Released, the native drift takes over. Same with or without the gun.
M.LUDO_CONE,M.LUDO_FAR,M.LUDO_SPEED,M.LUDO_TURN=.15,300,7,.3
function M.isLudovico(tear)
    local flag=TearFlags and TearFlags.TEAR_LUDOVICO
    if not flag or type(tear.HasTearFlags)~='function' then return false end
    local ok,has=pcall(tear.HasTearFlags,tear,flag)
    return ok and has==true
end
function M.ludovicoTarget(c,enemies)
    local best,bestDiff
    for _,e in ipairs(enemies or {}) do
        local dx,dy=e.Position.X-c.x,e.Position.Y-c.y
        local d=math.sqrt(dx*dx+dy*dy)
        local vulnerable=type(e.IsVulnerableEnemy)~='function' or e:IsVulnerableEnemy()
        if d>1 and vulnerable then
            local diff=math.abs((math.atan(dy,dx)-c.yaw+math.pi)%(2*math.pi)-math.pi)
            local allowed=M.LUDO_CONE+math.atan((e.Size or 10),d)
            if diff<=allowed and (not bestDiff or diff<bestDiff) then best,bestDiff=e,diff end
        end
    end
    if best then return best.Position.X,best.Position.Y,best end
    local far=M.LUDO_FAR
    if (c.pitch or 0)<-.05 then far=math.max(40,math.min(M.LUDO_FAR,(c.eye or 32)/math.tan(-c.pitch))) end
    return c.x+math.cos(c.yaw)*far,c.y+math.sin(c.yaw)*far,nil
end
-- 0.5.78 (user: the tear sat locked in the room centre): with Mouse Control
-- on, the native update pulls a held Ludovico tear toward the cursor, which
-- the FPS view keeps in the window centre (the room centre in a one-screen
-- room), and it overrides any velocity set here. While steering, the tear
-- therefore moves from the position this function left it at (undoing that
-- native pull) by its own velocity, clamped inside the room.
-- main=true: the weapon's own main entity (a Ludovico laser ring, knife or
-- bomb, from Weapon:GetMainEntity), already matched to the player.
function M.steerLudovico(tear,p,c,held,enemies,clamp,main)
    if not p then return false end
    if not main and (not M.isLudovico(tear) or not directlyOwned(tear,p)) then return false end
    local data=tear:GetData()
    if not held then data.IsaacFPSLudovico=nil;return false end
    local steer=data.IsaacFPSLudovico
    local frame=tear.FrameCount
    local x,y,v
    if steer and frame and steer.frame==frame-1 then x,y,v=steer.x,steer.y,steer.v
    else x,y,v=tear.Position.X,tear.Position.Y,{X=tear.Velocity.X,Y=tear.Velocity.Y} end
    local tx,ty=M.ludovicoTarget(c,enemies)
    local dx,dy=tx-x,ty-y
    local d=math.sqrt(dx*dx+dy*dy)
    local speed=M.LUDO_SPEED*math.max(.6,tonumber(p.ShotSpeed) or 1)
    local vx,vy=0,0
    if d>.5 then local s=math.min(speed,d)/d;vx,vy=dx*s,dy*s end
    vx,vy=v.X+(vx-v.X)*M.LUDO_TURN,v.Y+(vy-v.Y)*M.LUDO_TURN
    x,y=x+vx,y+vy
    if clamp then x,y=clamp(x,y) end
    tear.Position=Vector(x,y)
    tear.Velocity=Vector(vx,vy)
    data.IsaacFPSLudovico={frame=frame,x=x,y=y,v={X=vx,Y=vy}}
    return true
end

function M.preTear(tear)
    local shot=tear:GetData().IsaacFPSProbe3D
    if not shot then return end
    local pos=tear.Position
    shot.x,shot.y,shot.z=pos.X,pos.Y,-tear.Height
end

local heightLogged=0
function M.postTear(tear,c)
    local shot=tear:GetData().IsaacFPSProbe3D
    if not shot then return end
    local z=-tear.Height
    -- 0.5.113 (user: pistol rounds fly parallel to the floor whatever the
    -- pitch; looking up/down only moves the muzzle; native tears are fine).
    -- The launch vertical speed is right (log: vz -14 at -44 degrees), but
    -- the engine left the round's Height alone. A gun round's height is
    -- therefore advanced here from its own last height by the launch
    -- vertical speed each update, whatever the engine did to Height.
    local gun=tear:GetData().IsaacFPSGunShot
    local gunVz=gun and (gun.vz or (gun.fallingSpeed and -gun.fallingSpeed)) or nil
    if gunVz and shot.z then
        local engineZ=z
        z=shot.z+gunVz
        tear.Height=-z
        -- First rounds per session: the engine's height against ours.
        if heightLogged<6 and tear.FrameCount==3 and Isaac and Isaac.DebugString then
            heightLogged=heightLogged+1
            Isaac.DebugString(string.format('[Isaac FPS Probe] gun bullet height: frame=3 engine=%.2f set=%.2f vz=%.2f fallingSpeed=%.2f',engineZ,z,gunVz,tear.FallingSpeed))
        end
    end
    local pos=tear.Position
    local px,py=pos.X,pos.Y
    local dx,dy,dz=px-shot.x,py-shot.y,z-shot.z
    -- Reused every update (a fresh pose table per tear per update was
    -- measurable garbage with Soy Milk's 100+ bullets).
    local render=shot.render
    if not render or render.previous==render.current then render={previous={},current={}};shot.render=render end
    local previous,current=render.previous,render.current
    previous.x,previous.y,previous.z=shot.x,shot.y,shot.z
    current.x,current.y,current.z=px,py,z
    render.time=c.now or Isaac.GetTime()
    -- Gun bullets fly straight: lobbing items (Ipecac, Haemolacria...) set
    -- FallingAcceleration/FallingSpeed every update; pin them to the launch
    -- ray. Tear flags stay native, so explosions/bursts still trigger on death.
    if gun and gun.fallingSpeed then
        tear.FallingAcceleration=0
        tear.FallingSpeed=gun.fallingSpeed
    end
    if gun and gun.skin then synergy.keepSkin(tear,gun) end
    shot.vz=gunVz or -tear.FallingSpeed
    shot.remaining=shot.remaining-math.sqrt(dx*dx+dy*dy+dz*dz)
    -- 0.5.52: this update's end is the next update's start (MC_PRE_TEAR_UPDATE
    -- is no longer registered; preTear stays for callers that still use it).
    shot.x,shot.y,shot.z=px,py,z
    if z<=0 or shot.remaining<=0 then tear:Die() end
end

local function angleDelta(a,b) return (a-b+180)%360-180 end

local function aimAngle(entity,field,c)
    local data=entity:GetData()
    local angle=entity[field]
    local previous=data.IsaacFPSProbeAngle
    local nativeOffset
    -- 0.5.109: a gun beam/knife carries the cardinal it was fired along
    -- (IsaacFPSGunShot.base). Its init/update callback runs after the shot,
    -- when the nearest cardinal of the current view may already be the
    -- other one (aiming at a 45-degree diagonal): that put it 90 degrees off.
    local gun=data.IsaacFPSGunShot
    local base=type(gun)=='table' and gun.base or nil
    if previous and math.abs(angleDelta(angle,previous.output))<.001 then nativeOffset=previous.offset
    elseif base then nativeOffset=angleDelta(angle,math.deg(base))
    else nativeOffset=angleDelta(angle,math.deg(M.fireBase(c.player,c,math.rad(angle)))) end
    local output=(math.deg(c.yaw)+nativeOffset)%360
    entity[field]=output
    data.IsaacFPSProbeAngle={output=output,offset=nativeOffset}
end

local heldKnifeTypes={[0]=true,[1]=true,[2]=true,[3]=true,[10]=true,[11]=true}
local directionAngles={[0]=180,[1]=270,[2]=0,[3]=90}
local heldKnives={}

local function playerKnifeAngle(p,c)
    local direction=p:GetFireDirection()
    if direction<0 then direction=p:GetHeadDirection() end
    return directionAngles[direction] or math.deg(M.nativeYaw(c.yaw))
end

local function heldKnife(knife,p)
    return heldKnifeTypes[knife.Variant] and knife.SubType~=1 and knife.SubType~=4
        and directlyOwned(knife,p) and not knife:IsFlying()
        and not knife:GetIsSwinging() and not knife:GetIsSpinAttack()
end

local function aimHeldKnife(knife,p,c,afterUpdate)
    local data=knife:GetData()
    local held=data.IsaacFPSProbeHeldKnifeAim
    if not held then
        held={offset=knife.RotationOffset}
        data.IsaacFPSProbeHeldKnifeAim=held
        heldKnives[GetPtrHash(knife)]={knife=knife,player=p}
    elseif held.outputOffset and math.abs(angleDelta(knife.RotationOffset,held.outputOffset))>.001 then
        -- Preserve real native/mod multishot changes, rather than recapturing
        -- the camera correction as a new spread angle on every walking turn.
        held.offset=knife.RotationOffset
    end
    local base=playerKnifeAngle(p,c)
    local rotation=(math.deg(c.yaw)+held.offset)%360
    local offset=angleDelta(rotation,base)
    knife.RotationOffset,knife.Rotation=offset,rotation
    held.outputOffset=offset
    data.IsaacFPSProbeAngle={output=rotation,offset=held.offset}
    -- Keep the engine's live hand/charge distance. PRE uses the previous
    -- distance so player movement cannot turn the already corrected position
    -- into a new radius; POST captures the distance the native update produced.
    if afterUpdate or held.distance==nil then
        local dx,dy=knife.Position.X-p.Position.X,knife.Position.Y-p.Position.Y
        held.distance=math.sqrt(dx*dx+dy*dy)
        held.nativeX,held.nativeY=knife.Position.X,knife.Position.Y
    end
    local angle=math.rad(rotation)
    knife.Position=Vector(p.Position.X+math.cos(angle)*held.distance,
        p.Position.Y+math.sin(angle)*held.distance)
end

local function releaseHeldKnife(knife,p,restorePosition)
    local data=knife:GetData()
    local held=data.IsaacFPSProbeHeldKnifeAim
    if not held then return end
    if not held.outputOffset or math.abs(angleDelta(knife.RotationOffset,held.outputOffset))<.001 then
        knife.RotationOffset=held.offset
    end
    if restorePosition then
        if p then
            local angle=math.rad(playerKnifeAngle(p,{yaw=0})+held.offset)
            knife.Rotation=math.deg(angle)%360
            knife.Position=Vector(p.Position.X+math.cos(angle)*(held.distance or 0),
                p.Position.Y+math.sin(angle)*(held.distance or 0))
        elseif held.nativeX then
            knife.Position=Vector(held.nativeX,held.nativeY)
        end
    end
    data.IsaacFPSProbeHeldKnifeAim=nil
    heldKnives[GetPtrHash(knife)]=nil
end

local function restoreHand(knife,p)
    local data=knife:GetData()
    local hand=data.IsaacFPSProbeKnifeHand
    if not hand then return end
    -- Native AI may already have replaced Position (including a launch).
    -- Only undo our own last output; never overwrite that new native result.
    if math.abs(knife.Position.X-hand.x)<.001 and math.abs(knife.Position.Y-hand.y)<.001 then
        local dx,dy=p and p.Position.X-hand.playerX or 0,p and p.Position.Y-hand.playerY or 0
        knife.Position=Vector(hand.nativeX+dx,hand.nativeY+dy)
    end
    data.IsaacFPSProbeKnifeHand=nil
end

local function projectHand(knife,p,c,pose)
    restoreHand(knife,p)
    local nativeX,nativeY=knife.Position.X,knife.Position.Y
    local fx,fy,rx,ry=maths.basis(c.yaw)
    local dx,dy=nativeX-p.Position.X,nativeY-p.Position.Y
    local forward,side=dx*fx+dy*fy,dx*rx+dy*ry
    local cp,sp=math.cos(c.pitch),math.sin(c.pitch)
    local down=c.bodyOffset or 4
    local ahead=forward*cp+down*sp
    knife.Position=Vector(p.Position.X+fx*ahead+rx*side,p.Position.Y+fy*ahead+ry*side)
    pose.z=c.eye+forward*sp-down*cp
    pose.pitchYaw=c.yaw
    knife:GetData().IsaacFPSProbeKnifeHand={nativeX=nativeX,nativeY=nativeY,
        x=knife.Position.X,y=knife.Position.Y,playerX=p.Position.X,playerY=p.Position.Y}
    heldKnives[GetPtrHash(knife)]=heldKnives[GetPtrHash(knife)] or {knife=knife,player=p}
end

-- Display-only hand history. Each logic frame advances it once; same-frame
-- collision/child/re-entry refreshes only the current sample. Render rebuilds
-- the world pose from these camera-relative values with its own live camera,
-- so the mesh never lags mouse look between 30 Hz updates. Nothing here is
-- written back to Position, Rotation, RotationOffset or collision poses.
local function recordDisplay(knife,c,pose)
    local data=knife:GetData()
    local hand=data.IsaacFPSProbeKnifeHand
    if not hand or pose.mode=='flight' then data.IsaacFPSProbeKnifeDisplay=nil;return end
    local fx,fy,rx,ry=maths.basis(c.yaw)
    local dx,dy=hand.nativeX-hand.playerX,hand.nativeY-hand.playerY
    local sample={forward=dx*fx+dy*fy,side=dx*rx+dy*ry,
        angle=angleDelta(math.deg(pose.yaw),math.deg(c.yaw)),
        pitchOffset=(pose.pitch or c.pitch)-c.pitch,down=c.bodyOffset or 4,
        key=tostring(pose.mode)..':'..tostring(pose.animation)}
    local history=data.IsaacFPSProbeKnifeDisplay
    local frame=c.frame or 0
    if not history or history.frame~=frame then
        local previous=history and history.current
        -- Never blend across a mode/animation change or a skipped update.
        if not previous or previous.key~=sample.key or frame-history.frame~=1 then previous=sample end
        data.IsaacFPSProbeKnifeDisplay={frame=frame,time=c.now,
            previous=previous,current=sample}
    else
        history.current=sample
        if history.previous.key~=sample.key then history.previous=sample end
    end
end
M.recordDisplay=recordDisplay

function M.releaseKnife(knife,p)
    restoreHand(knife,p)
    releaseHeldKnife(knife,p,true)
    local data=knife:GetData()
    data.IsaacFPSProbeKnifeDisplay=nil
    data.IsaacFPSProbeKnife3D=nil
    data.IsaacFPSProbeAngle=nil
    data.IsaacFPSProbeKnifeContacts=nil
    heldKnives[GetPtrHash(knife)]=nil
end

function M.releaseHeldKnives()
    -- Called once by the host's release path, including errors/death/room exit.
    -- Only the handful of adapted hands are tracked; never scan the room.
    local pending=heldKnives
    heldKnives={}
    for _,entry in pairs(pending) do
        if entry.knife:Exists() then
            local p=entry.player
            M.releaseKnife(entry.knife,p and p:Exists() and p or nil)
        end
    end
end

local function parentLaser(laser)
    for _,source in pairs({laser.Parent,laser.SpawnerEntity}) do
        if source and source.Type==EntityType.ENTITY_LASER then return source:ToLaser() end
    end
end

local function laserPose(laser,c,refresh,seen,depth)
    seen,depth=seen or {},depth or 0
    local id=GetPtrHash(laser)
    if seen[id] or depth>=8 then return nil end
    seen[id]=true
    local data=laser:GetData()
    local pose=data.IsaacFPSProbeLaser3D
    if data.IsaacFPSFixedLaser then
        if not pose then
            local z=data.IsaacFPSFixedLaser
            pose={originX=laser.Position.X,originY=laser.Position.Y,originZ=z,pitch=0,yaw=math.rad(laser.Angle),z=z}
            data.IsaacFPSProbeLaser3D=pose
        end
        return pose
    end
    if laser:IsCircleLaser() then
        if not pose then
            pose={originX=laser.Position.X,originY=laser.Position.Y,originZ=c.eye-4,
                pitch=c.pitch,yaw=c.yaw}
            if data.IsaacFPSGunShot then
                local _,_,z=M.gunMuzzle(c,c.yaw)
                pose.originZ=z
            end
            data.IsaacFPSProbeLaser3D=pose
        end
        -- Lift the whole ring along its locked launch plane, never its arc.
        pose.z=geometry.planeHeight(pose,laser.Position.X,laser.Position.Y)
    elseif not pose or refresh then
        local parent=parentLaser(laser)
        local inherited=parent and M.owned(parent,c.player)
            and laserPose(parent,c,false,seen,depth+1)
        local originZ,pitch=c.eye-4,c.pitch
        if inherited then
            local path=geometry.laserPath(parent)
            local closest=math.huge
            for i=2,#path do
                local a,b=path[i-1],path[i]
                local dx,dy=b.x-a.x,b.y-a.y
                local length2=dx*dx+dy*dy
                local t=length2>0 and maths.clamp(((laser.Position.X-a.x)*dx
                    +(laser.Position.Y-a.y)*dy)/length2,0,1) or 0
                local point=geometry.interpolate(a,b,t)
                local distance=(laser.Position.X-point.x)^2+(laser.Position.Y-point.y)^2
                if distance<closest then closest,originZ=distance,point.z end
            end
            pitch=inherited.pitch
        end
        pose={originX=laser.Position.X,originY=laser.Position.Y,
            originZ=originZ,pitch=pitch,yaw=math.rad(laser.Angle),z=originZ}
        -- 0.5.68: a gun beam leaves the pistol's muzzle like its bullets'
        -- knives do (right of and below the eye), not the player's eyes.
        if data.IsaacFPSGunShot and not inherited then
            -- 0.5.73: from the point MUZZLE_AHEAD along the view ray through the
            -- muzzle as drawn (hip or ADS, any gun form), so the beam leaves
            -- the gun on screen; the fixed offset never matched the model.
            local gun=data.IsaacFPSGunShot
            pose.shiftX,pose.shiftY,pose.originZ=M.gunMuzzle(c,math.rad(laser.Angle),type(gun)=='table' and gun.side or nil)
            pose.z=pose.originZ
        end
        data.IsaacFPSProbeLaser3D=pose
    end
    return pose
end

function M.aimLaser(laser,p,c)
    if not M.owned(laser,p) then return end
    c.player=p
    local data=laser:GetData()
    -- 0.5.78: radial lasers of an Epic Fetus blast keep their own angles.
    if M.fixedLaser and M.fixedLaser() and not data.IsaacFPSFixedLaser then data.IsaacFPSFixedLaser=M.fixedLaser() end
    if data.IsaacFPSFixedLaser then laserPose(laser,c,false);return end
    -- Gun beams (fps_gun_synergy) leave along the snapped cardinal plus the
    -- fan offset; with Mouse Control held the player's aim points at the
    -- centred cursor, so it must not be their base (0.5.58).
    if data.IsaacFPSGunShot then
        local gun=data.IsaacFPSGunShot
        c.fireBase=type(gun)=='table' and gun.base or M.nativeYaw(c.yaw)
    end
    -- 0.5.91: a detached gun beam (no native follow) keeps its origin on the player.
    if data.IsaacFPSDetached and data.IsaacFPSGunShot and c.x and c.y then laser.Position=Vector(c.x,c.y) end
    local direct=directlyOwned(laser,p) and not parentLaser(laser)
    if laser:IsCircleLaser() then
        if direct and not data.IsaacFPSProbeAimed then
            laser.Velocity=rotate(laser.Velocity,c.yaw-M.fireBase(p,c,math.atan(laser.Velocity.Y,laser.Velocity.X)))
            data.IsaacFPSProbeAimed=true
        end
    elseif direct and data.IsaacFPSProbeLaserAimFrame~=c.frame then
        aimAngle(laser,'Angle',c)
        data.IsaacFPSProbeLaserAimFrame=c.frame
    end
    laserPose(laser,c,true)
    -- Native MaxDistance/LaserLength and grid clipping remain untouched.
end

function M.postLaser(laser,p,c)
    c.player=p
    if M.owned(laser,p) then laserPose(laser,c,false) end
end

function M.aimBomb(bomb,p,c)
    local data=bomb:GetData()
    if not bomb.IsFetus or not directlyOwned(bomb,p) or data.IsaacFPSProbeAimed then return end
    bomb.Velocity=rotate(bomb.Velocity,c.yaw-M.fireBase(p,c,math.atan(bomb.Velocity.Y,bomb.Velocity.X)))
    data.IsaacFPSProbeAimed=true
    return true
end

local function knifePose(knife,p,c,seen,depth,keepNative)
    local id=GetPtrHash(knife)
    if seen[id] or depth>=8 then return nil end
    seen[id]=true
    local data=knife:GetData()
    local pose=data.IsaacFPSProbeKnife3D
    local swing=knife:GetIsSwinging() or knife:GetIsSpinAttack()
    local flight=knife.SubType==1 or (knife.SubType~=4 and knife:IsFlying() and not swing)
    local mode=flight and 'flight' or swing and 'swing' or 'held'
    local sprite=knife:GetSprite()
    local animation,animationFrame=sprite:GetAnimation(),sprite:GetFrame()
    local newSwing=mode=='swing' and pose and pose.mode=='swing'
        and (pose.animation~=animation or animationFrame<(pose.animationFrame or 0))
    local parent=parentKnife(knife)
    local lockedFlight=flight and pose and pose.mode=='flight'
    local inheritNow=knife.SubType==4 or not pose or pose.mode~=mode or newSwing
    local inherited=not lockedFlight and inheritNow and parent and M.owned(parent,p)
        and knifePose(parent,p,c,seen,depth+1,knife.SubType==4)
    if inherited then
        pose={originX=inherited.originX,originY=inherited.originY,originZ=inherited.originZ,
            pitch=inherited.pitch,yaw=inherited.yaw,mode=flight and 'flight' or inherited.mode}
    else
        if not pose or not flight or pose.mode~=mode or newSwing then
            pose={originX=c.x,originY=c.y,
                originZ=c.eye-(mode=='flight' and 4 or c.bodyOffset or 4),
                pitch=c.pitch,yaw=math.rad(knife.Rotation),mode=mode}
            -- Gun-fired knives launch from the gun muzzle, not the eye.
            local gunKnife=data.IsaacFPSGunKnife
            if gunKnife and mode=='flight' then
                pose.originX,pose.originY,pose.originZ=gunKnife.originX,gunKnife.originY,gunKnife.originZ
            end
        end
    end
    -- A flight's native offset is captured at launch; held/swing poses remain
    -- camera-relative. Returning knives retain this same launch height plane.
    if pose.mode=='flight' then
        pose.z=geometry.planeHeight(pose,knife.Position.X,knife.Position.Y)
    elseif not keepNative then
        projectHand(knife,p,c,pose)
    end
    pose.frame,pose.animation,pose.animationFrame=c.frame,animation,animationFrame
    if not keepNative then
        data.IsaacFPSProbeKnife3D=pose
        recordDisplay(knife,c,pose)
    end
    return pose
end

function M.aimKnife(knife,p,c,beforeUpdate)
    c.player=c.player or p
    if not M.owned(knife,p) then return end
    restoreHand(knife,p)
    local data=knife:GetData()
    local swing=knife:GetIsSwinging() or knife:GetIsSpinAttack()
    local flight=knife.SubType==1 or (knife.SubType~=4 and knife:IsFlying() and not swing)
    local previous=data.IsaacFPSProbeKnife3D
    local flightLocked=previous and previous.mode=='flight' and previous.rotation~=nil
    if knife.SubType~=4 then
        if heldKnife(knife,p) then
            aimHeldKnife(knife,p,c,true)
        elseif not flight then
            releaseHeldKnife(knife)
            aimAngle(knife,'Rotation',c)
        elseif not flightLocked then
            local held=data.IsaacFPSProbeHeldKnifeAim
            local nativeRotation=knife.Rotation
            releaseHeldKnife(knife)
            if held then
                -- Held RotationOffset already contains the camera correction.
                -- Native launch can replace Rotation as the moving player's
                -- direction changes; it is not a fresh multishot offset.
                local offset=knife.RotationOffset
                knife.Rotation=(math.deg(c.yaw)+offset)%360
                data.IsaacFPSProbeAngle={output=knife.Rotation,offset=offset}
                if not beforeUpdate then
                    -- A launch during native AI has already positioned the
                    -- knife on its native axis. Rotate that displacement once,
                    -- about the current owner, without rotating player motion
                    -- or changing the engine's charge/distance/return state.
                    local relative=Vector(knife.Position.X-p.Position.X,knife.Position.Y-p.Position.Y)
                    local aimed=rotate(relative,math.rad(angleDelta(knife.Rotation,nativeRotation)))
                    knife.Position=Vector(p.Position.X+aimed.X,p.Position.Y+aimed.Y)
                end
            else
                -- New projectile knives have no adapted hand; retain their
                -- native spread when converting the launch direction once.
                aimAngle(knife,'Rotation',c)
            end
            local homing=knife:HasTearFlags(TearFlags.TEAR_HOMING)
            if (knife.SubType==1 or homing) and type(knife.InitHomingPath)=='function' then
                local direction=Vector(math.cos(math.rad(knife.Rotation)),math.sin(math.rad(knife.Rotation)))
                knife:InitHomingPath(direction,knife.Parent or p)
            end
            local pose=knifePose(knife,p,c,{},0)
            pose.yaw=math.rad(knife.Rotation)
            pose.rotation=knife.Rotation
            pose.nativeOffset=data.IsaacFPSProbeAngle and data.IsaacFPSProbeAngle.offset or 0
            pose.homing=homing
            pose.z=geometry.planeHeight(pose,knife.Position.X,knife.Position.Y)
            return pose
        elseif not previous.homing then
            knife.Rotation=previous.rotation or math.deg(previous.yaw)
        end
    end
    return knifePose(knife,p,c,{},0)
end

function M.preKnife(knife,p,c)
    if not M.owned(knife,p) then return end
    restoreHand(knife,p)
    if knife.SubType==4 then
        local parent=parentKnife(knife)
        if parent and M.owned(parent,p) then
            -- Hitbox follow AI reads the main knife's live XY after its own
            -- collision callback. Keep that source native throughout AI.
            restoreHand(parent,p)
            heldKnives[GetPtrHash(knife)]={knife=knife,player=p,parent=parent}
        end
    end
    if heldKnife(knife,p) then
        aimHeldKnife(knife,p,c,false)
        return
    end
    local data=knife:GetData()
    local pose=data.IsaacFPSProbeKnife3D
    local swing=knife:GetIsSwinging() or knife:GetIsSpinAttack()
    local flight=knife.SubType==1 or (knife.SubType~=4 and knife:IsFlying() and not swing)
    if flight and not (pose and pose.mode=='flight' and pose.rotation~=nil) then
        -- Keep the held native offset until launch captures it. Projectile
        -- subtype knives can also begin flight before their first Update.
        M.aimKnife(knife,p,c,true)
        return
    end
    releaseHeldKnife(knife)
    if knife.SubType~=4 and flight and pose and pose.mode=='flight'
        and pose.rotation~=nil and not pose.homing then
        -- The engine's distance/velocity/return state machine runs on the same
        -- XY axis throughout this throw, even when shoot input changes direction.
        knife.Rotation=pose.rotation or math.deg(pose.yaw)
    elseif knife.SubType~=4 and not flight then
        aimAngle(knife,'Rotation',c)
    end
end

local function meleeOwned(knife,p,depth)
    if directlyOwned(knife,p) then return true end
    local parent=parentKnife(knife)
    return parent and (depth or 0)<8 and meleeOwned(parent,p,(depth or 0)+1) or false
end

local function knifeContact(knife,collider,c)
    local data=knife:GetData()
    local frame=c.frame or 0
    local contacts=data.IsaacFPSProbeKnifeContacts
    if not contacts or contacts.frame~=frame then
        contacts={frame=frame,targets={}}
        data.IsaacFPSProbeKnifeContacts=contacts
    end
    local id=GetPtrHash(collider)
    local contact=contacts.targets[id]
    if not contact then contact={};contacts.targets[id]=contact end
    return contact
end

local function meleeOverlap(knife,collider,pose,bounds)
    if not knife:GetCollisionCapsule():Collide(collider:GetCollisionCapsule(),Vector(0,0)) then return false end
    local bottom,top=melee.heightRange(knife,pose)
    return top>=0 and top>=bounds.bottom and bottom<=bounds.top
end

function M.postKnife(knife,p,c,bounds)
    local hand=heldKnives[GetPtrHash(knife)]
    local parent=hand and hand.parent
    local pose=M.aimKnife(knife,p,c)
    if parent then
        knifePose(parent,p,c,{},0)
        hand.parent=nil
    end
    if not pose or pose.mode=='flight' or not meleeOwned(knife,p) then return end
    -- Vanilla queries its unpitched hand inside AI, before POST. Query only
    -- the projected native capsule and enter the original native hit chain.
    local capsule=knife:GetCollisionCapsule()
    local radius=math.max(0,capsule:GetSize())+math.abs(capsule:GetSizeDifference())
    local reach=0
    for _,endpoint in ipairs({capsule:GetStartPoint(),capsule:GetEndPoint()}) do
        reach=math.max(reach,math.sqrt((endpoint.X-knife.Position.X)^2+(endpoint.Y-knife.Position.Y)^2))
    end
    for _,collider in ipairs(Isaac.FindInRadius(knife.Position,radius+reach,EntityPartition.ENEMY)) do
        if meleeOverlap(knife,collider,pose,bounds(collider)) then
            local contact=knifeContact(knife,collider,c)
            if not contact.done and not contact.inProgress then
                contact.inProgress=true
                local ok,err=pcall(collider.ForceCollide,collider,knife,false)
                contact.inProgress=false
                contact.done=true
                if not ok then error(err) end
            end
        end
    end
    return pose
end

function M.register(mod,ctx)
    local function callback(id,fn,label)
        mod:AddCallback(id,ctx.guard(function(_,entity)
            if ctx.trace then
                ctx.trace(label or id,entity and entity.Type or -1,entity and entity.Variant or -1)
            end
            local p=ctx.player()
            if ctx.active() then fn(entity,p,ctx.camera())
            elseif entity.Type==EntityType.ENTITY_KNIFE then
                -- PRE restores before vanilla AI/collisions; POST also covers
                -- deactivation between updates. No room-wide scan is needed.
                M.releaseKnife(entity:ToKnife(),p)
            end
        end, label or ('W:'..tostring(id))))
    end
    callback(ModCallbacks.MC_POST_FIRE_TEAR,M.fireTear,'W_FIRE_TEAR')
    if ModCallbacks.MC_POST_FAMILIAR_FIRE_PROJECTILE then
        callback(ModCallbacks.MC_POST_FAMILIAR_FIRE_PROJECTILE,M.fireFamiliarTear,'W_FAMILIAR_TEAR')
    end
    -- 0.5.68: remember the last non-zero aim for charged attacks (fireBase).
    if ModCallbacks.MC_POST_PLAYER_UPDATE then
        mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE,ctx.guard(function(_,player)
            if ctx.active() then M.observeAim(player) end
        end,'W_AIM'))
    end
    callback(ModCallbacks.MC_POST_LASER_INIT,M.aimLaser,'W_LASER_INIT')
    callback(ModCallbacks.MC_PRE_LASER_UPDATE,M.aimLaser,'W_LASER_PRE')
    callback(ModCallbacks.MC_POST_LASER_UPDATE,M.postLaser,'W_LASER_POST')
    callback(ModCallbacks.MC_POST_BOMB_UPDATE,M.aimBomb,'W_BOMB_UPDATE')
    callback(ModCallbacks.MC_PRE_KNIFE_UPDATE,M.preKnife,'W_KNIFE_PRE')
    callback(ModCallbacks.MC_POST_KNIFE_UPDATE,function(knife,p,c)
        return M.postKnife(knife,p,c,ctx.targetBounds)
    end,'W_KNIFE_POST')
    mod:AddPriorityCallback(ModCallbacks.MC_PRE_LASER_COLLISION,-100,ctx.guard(function(_,laser,collider)
        if ctx.trace then ctx.trace('W_LASER_COLL') end
        if not ctx.active() or not M.owned(laser,ctx.player()) then return end
        -- Collision must use the already aimed native path, without applying
        -- another direction change after the engine calculated its samples.
        local camera=ctx.camera()
        camera.player=ctx.player()
        laserPose(laser,camera,false)
        if not geometry.laserOverlaps(laser,collider,ctx.targetBounds(collider)) then return true end
        -- nil retains the original damage, flags and on-hit effects.
    end, 'W_LASER_COLL'))
    mod:AddPriorityCallback(ModCallbacks.MC_PRE_KNIFE_COLLISION,-100,ctx.guard(function(_,knife,collider)
        if ctx.trace then ctx.trace('W_KNIFE_COLL') end
        if not ctx.active() then return end
        local p=ctx.player()
        if not M.owned(knife,p) then return end
        local camera=ctx.camera()
        restoreHand(knife,p)
        if heldKnife(knife,p) then aimHeldKnife(knife,p,camera,false) end
        local pose=knifePose(knife,p,camera,{},0)
        if not pose then return end
        local bounds=ctx.targetBounds(collider)
        if pose.mode~='flight' then
            if not meleeOverlap(knife,collider,pose,bounds) then return true end
            local contact=knifeContact(knife,collider,camera)
            if contact.done and not contact.inProgress then return true end
            if not contact.inProgress then contact.done=true end
        elseif pose.z<0 or not maths.heightOverlap(pose.z,knife.Size,bounds.bottom,bounds.top) then
            return true
        end
    end, 'W_KNIFE_COLL'))
end

return M

-- Gun runtime glue: item ownership, input isolation, native bullet spawning,
-- aim-down-sights, recoil, real-hit feedback, persistence and the view model.
-- Bullets are native tears fired through EntityPlayer:FireTear, so damage,
-- flags and on-hit effects stay native; speed/range belong to the weapon.
local runtime=include('fps_weapon_runtime')
local model=include('fps_gun_model')
local synergy=include('fps_gun_synergy')
local maths=include('fps_math')
local json=require('json')
local M={runtime=runtime,model=model,synergy=synergy}
-- F8 activity counters (gun shots fired, native tears dropped).
M.stats={shots=0,dropped=0}

local SAVE_KEY='IsaacFPSWeapons'
local view={ads=0,adsTarget=0,kick=0,recoverLeft=0,time=nil,markers={},message=nil,messageUntil=0}
local itemIds={}
local modRef,ctx
local diagnosed=0

function M.view() return view end

local function itemId(key)
    local id=itemIds[key]
    if id==nil then
        local def=runtime.defs[key]
        id=-1
        if def and Isaac and Isaac.GetItemIdByName then
            local ok,value=pcall(Isaac.GetItemIdByName,def.item)
            if ok and type(value)=='number' and value>0 then id=value end
        end
        itemIds[key]=id
    end
    return id>0 and id or nil
end
M.itemId=itemId

local function hasItem(p,key)
    local id=itemId(key)
    return id~=nil and p:HasCollectible(id)
end

-- Input isolation while a gun owns the primary attack. Returns a value to
-- override the queried action, or nil to leave it native.
local shootActions
function M.blockInput(action,hook)
    if not ctx or not ctx.enabled() or not runtime.controlsAttack() then return nil end
    local p=ctx.player and ctx.player()
    if not shootActions then
        shootActions={}
        for _,name in ipairs({'ACTION_SHOOTLEFT','ACTION_SHOOTRIGHT','ACTION_SHOOTUP','ACTION_SHOOTDOWN'}) do
            if ButtonAction[name] then shootActions[ButtonAction[name]]=true end
        end
    end
    -- A lifted throwable item (or a character that cannot shoot) keeps the
    -- native shoot actions so the item can still be thrown.
    local shoot=shootActions[action] and not M.nativeShootNeeded(p)
    local rightDown=Input.IsMouseBtnPressed and Input.IsMouseBtnPressed(1)
    -- Tapping the reload key (default R) reloads; holding R still drives the
    -- native hold-to-restart, which is never blocked here.
    local blocked=shoot
        -- Right mouse aims (read live: the press frame and reloads included);
        -- it must not also trigger a mouse-bound active item. Space still does.
        or (action==ButtonAction.ACTION_ITEM and rightDown
            and not (Keyboard.KEY_SPACE and Input.IsButtonPressed(Keyboard.KEY_SPACE,0)))
    if not blocked then return nil end
    if hook==InputHook.GET_ACTION_VALUE then return 0 end
    return false
end

-- 0.5.62: Lilith never shoots herself; with the gun out her Incubus fires
-- the gun's rounds (see incubi below), so the gun owns her trigger.
-- Tainted Lilith's Gello is a thrown melee familiar: she keeps native.
local function lilith(p)
    return PlayerType and type(p.GetPlayerType)=='function' and p:GetPlayerType()==PlayerType.PLAYER_LILITH
end
local function taintedLilith(p)
    return PlayerType and type(p.GetPlayerType)=='function' and p:GetPlayerType()==PlayerType.PLAYER_LILITH_B
end
M.INCUBUS_DAMAGE=.75   -- Incubus copies the player's attack at 75% damage
M.TWISTED_DAMAGE=.375  -- 0.5.71: each Twisted Pair baby (wiki value, to verify)

-- The player's Incubus familiars (the item, or Lilith's own) as
-- {familiar=, share=} entries. 0.5.77: the damage share is kept here, not
-- written onto the familiar (REPENTOGON userdata rejects unknown members:
-- "no member named 'IsaacFPSShare'" stopped the mod with Twisted Pair).
local function incubi(p)
    local list={}
    if not (Isaac and Isaac.FindByType and EntityType and EntityType.ENTITY_FAMILIAR
        and FamiliarVariant and FamiliarVariant.INCUBUS) then return list end
    local owner=GetPtrHash(p)
    for _,kind in ipairs({{FamiliarVariant.INCUBUS,M.INCUBUS_DAMAGE},{FamiliarVariant.TWISTED_BABY,M.TWISTED_DAMAGE}}) do
        if kind[1] then
            local ok,found=pcall(Isaac.FindByType,EntityType.ENTITY_FAMILIAR,kind[1],-1,false,false)
            for _,entity in ipairs(ok and found or {}) do
                local familiar=entity.ToFamiliar and entity:ToFamiliar() or entity
                local player=familiar and familiar.Player
                if player and GetPtrHash(player)==owner then
                    list[#list+1]={familiar=familiar,share=kind[2]}
                end
            end
        end
    end
    return list
end
M.incubi=incubi

-- A native weapon charge in progress (no weapon API: assume charging).
local function nativeCharging(p)
    if type(p.GetWeapon)~='function' then return true end
    for slot=1,4 do
        local ok,weapon=pcall(p.GetWeapon,p,slot)
        if ok and weapon and type(weapon.GetCharge)=='function' and weapon:GetCharge()>0 then return true end
    end
    return false
end

-- 0.5.90 (user: Brimstone/lasers fought the native mouse position): with
-- Mouse Control on (FPS turns it on), a held left button drives the native
-- weapon past the blocked shoot actions, charging and firing at the centred
-- cursor. Tears were dropped one by one; native beams were not, so they fired
-- alongside the gun's beams in another direction. While the gun owns the
-- attack the native weapon keeps no charge and stays on cooldown.
M.HOLD_FIRE_DELAY=2
function M.holdNativeWeapon(p)
    if not p or type(p.GetWeapon)~='function' then return false end
    local ok,weapon=pcall(p.GetWeapon,p,1)
    if not ok or not weapon then return false end
    pcall(function()
        if weapon:GetCharge()>0 then weapon:SetCharge(0) end
        if weapon:GetFireDelay()<M.HOLD_FIRE_DELAY then weapon:SetFireDelay(M.HOLD_FIRE_DELAY) end
    end)
    return true
end

function M.nativeShootNeeded(p)
    if not p then return false end
    if type(p.IsHoldingItem)=='function' and p:IsHoldingItem() then return true end
    -- Brimstone and Technology own their attack shape: the gun fires the
    -- native beam for them (fps_gun_synergy). While that charge is in progress
    -- CanShoot() is false, so handing the trigger back to the engine there made
    -- the native charge and the gun fire at the same time.
    -- 0.5.58 review: only while a native charge is actually under way.
    local mode=synergy.mode(p)
    if (mode=='brimstone' or mode=='technology') and not taintedLilith(p) and nativeCharging(p) then return false end
    if lilith(p) then return false end
    -- 0.5.71: Ludovico (steered by fps_weapons), Urn of Souls and the
    -- umbilical whip keep their native attack with the gun out.
    if mode=='ludovico' or mode=='native' then return true end
    if type(p.CanShoot)=='function' and p:CanShoot()==false then return true end
    return false
end

-- Chocolate Milk: hold to charge, release fires one round whose damage
-- scales like the native item (0.25x tap to 4x at 2.5x the fire delay).
local CHARGE_MIN,CHARGE_MAX,CHARGE_DELAYS=.25,4,2.5
M.CHOCOLATE_BRIM_MAX=2.5  -- 0.5.78: Brimstone + Chocolate Milk tops out at 250%
local charge={holding=false,frames=0,release=false,mult=nil,full=1}
-- 0.5.71: follow-up rounds fired on later logic frames (Cursed Eye volley,
-- Neptunus' burst after a reload). They take no extra ammo.
local burst={remaining=0,next=0}
M.BURST_GAP=3          -- logic frames between follow-up rounds
M.NEPTUNUS_EXTRA=3     -- extra rounds of the first shot after a reload
M.CURSED_MAX=5
-- Native collectible by CollectibleType name (hasItem above is for guns).
local function owns(p,name)
    local id=CollectibleType and CollectibleType[name]
    return id~=nil and p~=nil and type(p.HasCollectible)=='function' and p:HasCollectible(id)==true
end

-- 0.5.78 (wiki): Epic Fetus + Monstro's Lung: 2-4 extra strikes around each.
function M.epicSatellites(p)
    return owns(p,'COLLECTIBLE_MONSTROS_LUNG') and math.random(2,4) or 0
end

-- 0.5.78 (user): 20/20 turns the one-handed gun forms into a pair, one gun
-- per hand. Both fire on every trigger pull, each from its own muzzle, so
-- the magazine doubles and a pull takes a round from each. They never aim
-- down the sights (right mouse still zooms the view). Long guns keep the
-- single gun and the multi-shot fan.
M.DUAL=true
M.DUAL_FORMS={pistol=true,laser=true,beam=true,flare=true}
function M.isDual(p,form)
    return M.DUAL and M.WEAPON_FORMS and M.DUAL_FORMS[form or runtime.form() or 'pistol']==true
        and owns(p,'COLLECTIBLE_20_20')
end
-- The gun pose's ADS amount: dual guns stay at the hip.
local function gunAds()
    return view.look and view.look.dual and 0 or view.ads
end

-- 0.5.71: hold-to-charge kinds. Chocolate Milk scales damage; Monstro's
-- Lung bursts into many rounds; Cursed Eye fires 1-5 rounds in a row.
local function chargeMode(p)
    if p==nil then return nil end
    local mode=synergy.mode(p)
    if mode=='lung' and not M.WEAPON_FORMS then return 'lung' end
    -- 0.5.78 (wiki): Brimstone + Chocolate Milk charges (25%-250% damage).
    if mode=='brimstone' and owns(p,'COLLECTIBLE_CHOCOLATE_MILK') then return 'chocolate' end
    -- Monstro's Lung + Chocolate Milk: every pellet is a charged Chocolate shot.
    if mode=='lung' and owns(p,'COLLECTIBLE_CHOCOLATE_MILK') then return 'chocolate' end
    if mode~='tears' and mode~='csection' then return nil end
    if owns(p,'COLLECTIBLE_CURSED_EYE') then return 'cursed' end
    if owns(p,'COLLECTIBLE_CHOCOLATE_MILK') then return 'chocolate' end
    return nil
end
M.chargeMode=chargeMode

-- Soy Milk: natively ~5.5x tears at 0.2x damage (the player's Damage stat
-- already carries the 0.2x). With a gun: full auto while the left button is
-- held at 5x the rate, a 5x magazine (same damage per magazine) shown as a
-- draining bar, and the usual reload when it runs dry.
local SOY_RATE,SOY_MAGAZINE=5,5
local function soyMode(p)
    -- 0.5.71: Almond Milk (the milder Soy Milk) also makes the gun full auto.
    return p~=nil and (owns(p,'COLLECTIBLE_SOY_MILK') or owns(p,'COLLECTIBLE_ALMOND_MILK'))
end
M.soyMode=soyMode
local function chargeFrames(p) return math.max(6,((p and p.MaxFireDelay) or 10)*CHARGE_DELAYS) end
function M.chargeLevel()
    if not charge.holding then return nil end
    return math.min(1,charge.frames/charge.full)
end

-- Render-time intents. edge(code) is the host's keyboard edge detector.
-- leftDown (optional) is the live left-button state for charge release.
-- Marked: natively the player fires on its own toward the red target. With
-- a gun the trigger stays pulled instead (one queued shot per frame, so the
-- gun fires at its own rate, reloads by itself and keeps firing).
function M.autoFire(p)
    local id=CollectibleType and CollectibleType.COLLECTIBLE_MARKED
    return id~=nil and p~=nil and type(p.HasCollectible)=='function' and p:HasCollectible(id)
end

function M.renderInput(now,live,edge,mouseEdge,rightDown,leftDown)
    -- Read every edge each frame so a key held through a pause cannot fire
    -- a stale edge on resume.
    local reloadCode=ctx and ctx.reloadKey and ctx.reloadKey() or Keyboard.KEY_R
    local reload=reloadCode and edge(reloadCode)
    local selected
    for i=1,9 do
        local code=Keyboard['KEY_'..i]
        if code and edge(code) then selected=selected or i end
    end
    if not live then
        runtime.clearInput()
        view.adsTarget=0
        charge.holding,charge.release=false,false
        return
    end
    if reload then runtime.requestReload() end
    if selected then runtime.select(selected) end
    if Input.GetMouseWheel then
        local ok,wheel=pcall(Input.GetMouseWheel)
        local y=ok and wheel and (type(wheel)=='number' and wheel or wheel.Y) or 0
        if y>0 then runtime.cycle(-1) elseif y<0 then runtime.cycle(1) end
    end
    local holder=ctx and ctx.player and ctx.player()
    if runtime.controlsAttack() and chargeMode(holder) then
        if mouseEdge then charge.holding,charge.frames=true,0 end
        if charge.holding and leftDown==false then charge.holding,charge.release=false,true end
    -- Holding LMB repeats at the weapon's normal cooldown, for every gun form.
    -- Charge weapons above retain their native hold/release behavior.
    elseif mouseEdge or (runtime.controlsAttack() and (M.autoFire(holder) or leftDown)) then
        runtime.click()
    elseif runtime.controlsAttack() then
        -- Do not leave a buffered repeat that fires after the button is released.
        runtime.state().pending=nil
    end
    view.adsTarget=(rightDown and runtime.controlsAttack() and not runtime.reloadProgress()) and 1 or 0
end

-- Smooth ADS, visual kick and partial camera recoil recovery. Returns the
-- view pitch change to apply this render (negative = recovery downward).
function M.step(now)
    local dt=view.time and math.max(0,math.min(100,now-view.time)) or 0
    view.time=now
    local rate=dt/110
    if view.ads<view.adsTarget then view.ads=math.min(view.adsTarget,view.ads+rate)
    else view.ads=math.max(view.adsTarget,view.ads-rate) end
    view.kick=view.kick*math.exp(-dt/70)
    local recover=view.recoverLeft*(1-math.exp(-dt/90))
    view.recoverLeft=view.recoverLeft-recover
    return -recover
end

function M.zoom() return 1+.45*view.ads end

-- Hip-fire cone (radians): base plus a movement share, none in full ADS.
local SPREAD_BASE,SPREAD_MOVE,ADS_SPEED=.035,.10,.65
local function topSpeed(p)
    local seen=view.walkMax or 0
    return seen>1 and seen or (p and p.MoveSpeed or 1)*4
end
local function moveRatio(p)
    local v=p and p.Velocity
    local speed=v and math.sqrt(v.X^2+v.Y^2) or 0
    return math.min(1,speed/topSpeed(p))
end
function M.spread(p)
    return (SPREAD_BASE+SPREAD_MOVE*moveRatio(p))*(1-view.ads)
end

-- ADS walks slower: cap speed at a share of the fastest observed hip speed
-- (empirical, so speed items and characters scale without engine formulas).
local function limitSpeed(p)
    if not p or not p.Velocity then return end
    local v=p.Velocity
    local speed=math.sqrt(v.X^2+v.Y^2)
    -- Knockback can briefly exceed walking speed; bound what gets recorded.
    if view.ads<.05 then view.walkMax=math.max(view.walkMax or 0,math.min(speed,(p.MoveSpeed or 1)*6));return end
    local cap=topSpeed(p)*(1-(1-ADS_SPEED)*view.ads)
    if speed>cap and speed>0 then p.Velocity=Vector(v.X*cap/speed,v.Y*cap/speed) end
end
M.limitSpeed=limitSpeed
function M.sensitivity() return 1-.35*view.ads end
function M.crosshairAlpha() return runtime.controlsAttack() and math.max(0,1-gunAds()*2.5) or 1 end

-- The gun fires at its own rate, so like the native high-rate weapons
-- (Brimstone, Technology, Tech X...) Ipecac's flat +40 damage drops to +2
-- (explosions scale from tear damage, so they follow).
local IPECAC_FLAT,IPECAC_HIGH_RATE=40,2
function M.damageScale(p)
    local id=CollectibleType and CollectibleType.COLLECTIBLE_IPECAC
    local damage=p and p.Damage or 0
    if not id or type(p.HasCollectible)~='function' or not p:HasCollectible(id)
        or damage<=IPECAC_FLAT then return 1 end
    return (damage-IPECAC_FLAT+IPECAC_HIGH_RATE)/damage
end

-- 0.5.91 (user: thrown melee range follows the panel and the gun): the
-- gun's own range (720 at the base Range stat, 6.5 tiles = 260 TearRange)
-- scales with the player's current TearRange, clamped to 0.5x..2.5x. Every
-- gun bullet and gun knife uses it, so a knife flies exactly as far as a
-- bullet would.
M.BASE_TEAR_RANGE=260
M.RANGE_MIN,M.RANGE_MAX=.5,2.5
function M.range(p,def)
    local base=def and def.range or 720
    local range=p and tonumber(p.TearRange)
    if not range or range~=range or range<=0 then return base end
    return base*math.max(M.RANGE_MIN,math.min(M.RANGE_MAX,range/M.BASE_TEAR_RANGE))
end

-- Hit-audio chain diagnostics: the first few events of each stage (fire,
-- contact, damage, play) per Lua session go to log.txt, so a silent hit can
-- be traced to the stage where it stops.
local AUDIO_LOG_LIMIT=8
local audioLog={}
local function audioLine(stage,text)
    local n=(audioLog[stage] or 0)+1
    if n>AUDIO_LOG_LIMIT or not (Isaac and Isaac.DebugString) then return end
    audioLog[stage]=n
    Isaac.DebugString('[Isaac FPS Probe] hit audio '..stage..': '..text)
end
M.audioLine=audioLine
-- 0.5.54: callers check this before formatting, so the strings are built
-- only while a stage is still under its limit (they ran on every shot/hit).
local function audioOpen(stage) return (audioLog[stage] or 0)<AUDIO_LOG_LIMIT end

-- 0.5.112 diagnostic: the first BULLET_LOG_PER_SIDE gun rounds of each view
-- quarter (E, S, W, N): the requested yaw, the direction FireTear actually
-- left along, and the final velocity and vertical speed.
M.BULLET_LOG_PER_SIDE=6
local bulletLogged={0,0,0,0}
local function logBullet(weapons,yaw,pitch,launched,tear)
    if not (Isaac and Isaac.DebugString) or type(weapons.viewQuarter)~='function' then return end
    local q=weapons.viewQuarter(yaw)
    if bulletLogged[q]>=M.BULLET_LOG_PER_SIDE then return end
    bulletLogged[q]=bulletLogged[q]+1
    local v=tear.Velocity
    local data=type(tear.GetData)=='function' and tear:GetData() or nil
    local shot=data and data.IsaacFPSProbe3D
    Isaac.DebugString(string.format('[Isaac FPS Probe] gun bullet aim: side=%s yaw=%.1f pitch=%.1f fired=%.1f final=%.1f speed=%.2f vz=%s height=%.1f',
        ({'E','S','W','N'})[q],math.deg(yaw),math.deg(pitch or 0),math.deg(launched),
        math.deg(math.atan(v.Y,v.X)),math.sqrt(v.X*v.X+v.Y*v.Y),
        shot and string.format('%.2f',shot.vz or 0) or '-',tear.Height or 0))
end

-- True only while the gun itself calls FireTear (see M.dropNativeTear).
local gunFiring=false

-- With the gun out, every native tear the player fires is dropped. The
-- shoot actions are blocked already, but the native Mouse Control option
-- (on during FPS since 0.5.37) fires from the eyes on a held left button
-- without going through them; Soy Milk made it obvious. Throwables and
-- characters that cannot shoot keep native firing.
function M.dropNativeTear(tear,p)
    if gunFiring or not ctx or not ctx.enabled() or not runtime.controlsAttack() then return false end
    if not p or M.nativeShootNeeded(p) then return false end
    local data=type(tear.GetData)=='function' and tear:GetData() or nil
    if data and data.IsaacFPSGunShot then return false end
    tear:Remove()
    M.stats.dropped=M.stats.dropped+1
    return true
end

-- A native shot an Incubus of this player fired while the gun owns the attack.
function M.dropNativeFamiliarShot(shot,p)
    if gunFiring or not ctx or not ctx.enabled() or not runtime.controlsAttack() then return false end
    if not p or M.nativeShootNeeded(p) or not shot then return false end
    local data=type(shot.GetData)=='function' and shot:GetData() or nil
    if data and data.IsaacFPSGunShot then return false end
    local spawner=shot.SpawnerEntity or shot.Parent
    local familiar=spawner and spawner.ToFamiliar and spawner:ToFamiliar()
    local owner=familiar and familiar.Player
    if not owner or GetPtrHash(owner)~=GetPtrHash(p) then return false end
    shot:Remove()
    M.stats.dropped=M.stats.dropped+1
    return true
end

-- One native bullet along the given (yaw, pitch) ray.
local function fireBullet(p,c,weapons,def,yaw,pitch,damage,mode,skin,volley,origin)
    -- 0.5.110: the round leaves along its exact yaw (the engine fires in any
    -- direction, as with Analog Stick); it was a cardinal turned afterwards,
    -- which near a 45-degree diagonal could be the other cardinal.
    local nativeYaw=yaw
    c=setmetatable({yaw=yaw,pitch=pitch,fireBase=nativeYaw,fromMuzzle=origin==nil},{__index=c})
    local velocity=Vector(math.cos(nativeYaw)*def.speed,math.sin(nativeYaw)*def.speed)
    -- The generic POST_FIRE_TEAR adapter must not convert it first: the gun
    -- sets its own flat trajectory, then converts once below.
    weapons.suppressFire=true
    weapons.suppressed={}
    gunFiring=true
    local ok,tear=pcall(p.FireTear,p,origin or p.Position,velocity,false,true,false,nil,damage)
    gunFiring=false
    weapons.suppressFire=false
    -- 0.5.112 (user: pistol rounds would not go up or down since 0.5.110):
    -- the turn starts from the direction FireTear actually left along, not
    -- the requested one, so whatever the engine did to it (snap, inheritance)
    -- the round still ends on the view yaw.
    local launched=nativeYaw
    if ok and tear and tear.Velocity then
        local v=tear.Velocity
        if v.X*v.X+v.Y*v.Y>1e-6 then launched=math.atan(v.Y,v.X) end
    end
    c.fireBase=launched
    -- 0.5.108: tears other items added to this shot (Loki's Horns, Mom's
    -- Eye...) left relative to the same cardinal: turned by the same base,
    -- from the player rather than the muzzle.
    local extra=weapons.suppressed
    weapons.suppressed={}
    if #extra>0 then
        local fromPlayer=setmetatable({fromMuzzle=false},{__index=c})
        for _,other in ipairs(extra) do
            if other~=tear and (type(other.Exists)~='function' or other:Exists()) then
                weapons.fireTear(other,p,fromPlayer)
            end
        end
    end
    if not ok then error(tear) end
    if not tear then return nil end
    tear.FallingSpeed,tear.FallingAcceleration=0,0
    local gunShot={owner=p.InitSeed,weapon=def.key}
    tear:GetData().IsaacFPSGunShot=gunShot
    if mode=='melee' and skin then synergy.applyMelee(tear,skin,gunShot)
    elseif TearVariant and TearVariant.METALLIC and (tear.Variant==0 or tear.Variant==1)
        and type(tear.ChangeVariant)=='function' then tear:ChangeVariant(TearVariant.METALLIC) end
    if mode=='epic' then synergy.applyEpic(tear,gunShot,volley) end
    weapons.fireTear(tear,p,c)
    logBullet(weapons,yaw,pitch,launched,tear)
    -- Launch vertical speed along the aim ray; postTear keeps it constant.
    gunShot.fallingSpeed=tear.FallingSpeed
    -- 0.5.114 (log: launch vz -9.09, but FallingSpeed read back ~0 and the
    -- 0.5.113 height step was 0): the vertical speed is the one fireTear
    -- computed for the aim ray, kept on the shot, not read back from the tear.
    local launch3D=tear:GetData().IsaacFPSProbe3D
    gunShot.vz=launch3D and launch3D.vz or -tear.FallingSpeed
    if audioOpen('fire') then audioLine('fire',string.format('tear=%s variant=%s gunData=%s',tostring(GetPtrHash and GetPtrHash(tear) or '?'),
        tostring(tear.Variant),tostring(tear:GetData().IsaacFPSGunShot==gunShot))) end
    local shot=tear:GetData().IsaacFPSProbe3D
    if shot then shot.remaining=M.range(p,def) end
    return tear
end

-- 0.5.78 (user: match the wiki's item interactions): native combinations
-- that one Fire* call does not carry, added around the main shot.
--   Brimstone + Monstro's Lung: 3-5 extra beams in random directions;
--     + C Section: 4 fetus tears with the beam; + Technology: x1.5 damage.
--   Technology + Lung: a 30-degree spread of lasers (charged pace);
--     + Dr. Fetus / Tech X / Mom's Knife: both fire (the laser as well).
--   Tech X + Lung: 3-5 extra rings in a 30-degree spread (50-100% damage).
--   Dr. Fetus + Tech X: a ring with the bomb; + Lung: a spread of 6 bombs.
--   C Section + Tech X: a ring with the fetus (half damage).
--   Mom's Knife + Tech X: a ring with the knife; + Brimstone: a barrage of
--     extra knives; + Lung: 3-5 extra knives in random directions.
M.COMBO={brimLung={3,5},brimFetuses=4,techLung=11,techLungSpread=math.rad(30),
    ringLung={3,5},ringLungSpread=math.rad(30),fetusLung=6,knifeBarrage=3,
    knifeLung={3,5},knifeLungSpread=math.rad(45),brimTech=1.5,techLungArcs={3,4}}
local function combos(p,c,weapons,def,mode,yaw,pitch,damage,shots)
    local function add(shot) if shot then shots[#shots+1]=shot end end
    local function muzzle(angle)
        local sx,sy=weapons.gunMuzzle(c,angle)
        return Vector(c.x+sx,c.y+sy)
    end
    local function between(range) return math.random(range[1],range[2]) end
    local tech=owns(p,'COLLECTIBLE_TECHNOLOGY')
    local ring=owns(p,'COLLECTIBLE_TECH_X')
    local lung=owns(p,'COLLECTIBLE_MONSTROS_LUNG')
    local K=M.COMBO
    if mode=='brimstone' then
        if lung then
            for _=1,between(K.brimLung) do
                add(synergy.fireBrimstone(p,weapons,c.yaw,c.yaw+(math.random()*2-1)*math.pi,damage))
            end
        end
        if owns(p,'COLLECTIBLE_C_SECTION') then
            for _,offset in ipairs(synergy.fan(K.brimFetuses)) do
                local tear=fireBullet(p,c,weapons,def,yaw+offset,pitch,damage,'tears')
                if tear then synergy.applyFetus(tear) end
                add(tear)
            end
        end
    elseif mode=='technology' then
        if lung then
            local n=K.techLung
            for i=1,n do
                local offset=(i-(n+1)/2)*K.techLungSpread/(n-1)
                if math.abs(offset)>1e-6 then add(synergy.fireTechLaser(p,weapons,c.yaw,yaw+offset,damage)) end
            end
            -- Each laser arcs 3-4 times (native chained lasers).
            for _,laser in ipairs(shots) do
                if type(laser.SetNumChainedLasers)=='function' then
                    pcall(laser.SetNumChainedLasers,laser,math.random(K.techLungArcs[1],K.techLungArcs[2]))
                end
            end
        end
    elseif mode=='techx' then
        if tech then add(synergy.fireTechLaser(p,weapons,c.yaw,yaw,damage)) end
        if lung then
            for _=1,between(K.ringLung) do
                local offset=(math.random()-.5)*K.ringLungSpread
                add(synergy.fireTechX(p,yaw+offset,damage*(.5+math.random()*.5),muzzle(yaw+offset)))
            end
        end
    elseif mode=='fetus' then
        if tech then add(synergy.fireTechLaser(p,weapons,c.yaw,yaw,damage)) end
        if ring then add(synergy.fireTechX(p,yaw,damage,muzzle(yaw))) end
        if lung then
            for _=2,K.fetusLung+synergy.shotCount(p)-1 do
                local offset=(math.random()*2-1)*synergy.LUNG_SPREAD
                add(synergy.fireBomb(p,yaw+offset,muzzle(yaw+offset)))
            end
        end
    elseif mode=='csection' then
        if ring then add(synergy.fireTechX(p,yaw,damage*.5,muzzle(yaw))) end
    elseif mode=='melee' then
        if tech then add(synergy.fireTechLaser(p,weapons,c.yaw,yaw,damage)) end
        if ring then add(synergy.fireTechX(p,yaw,damage,muzzle(yaw))) end
        local skin=synergy.meleeSkin(p)
        local function knife(offset)
            add(synergy.fireKnife(p,weapons,c.yaw,yaw+offset,pitch,skin,M.range(p,def),c,def.speed)
                or fireBullet(p,c,weapons,def,yaw+offset,pitch,damage,'melee',skin))
        end
        if owns(p,'COLLECTIBLE_BRIMSTONE') then
            for _=1,K.knifeBarrage do knife((math.random()*2-1)*.04) end
        end
        if lung then
            for _=1,between(K.knifeLung) do knife((math.random()-.5)*K.knifeLungSpread) end
        end
    end
end
M.combos=combos

-- One trigger pull: a projectile per native multi-shot tear, shaped by the
-- current attack-item synergy (fps_gun_synergy). Returns the first
-- projectile and the full list.
local fireShot
-- 0.5.108: every native entity the gun shot spawns is turned from the gun's
-- own cardinal (weapons.firingBase), cleared afterwards even on error.
function M.fire(p,c,weapons,multiplier,burst)
    local previous=weapons.firingBase
    weapons.firingBase=c.yaw
    local results=table.pack(pcall(fireShot,p,c,weapons,multiplier,burst))
    weapons.firingBase=previous
    if not results[1] then error(results[2],0) end
    return table.unpack(results,2,results.n)
end
fireShot=function(p,c,weapons,multiplier,burst)
    local def=runtime.currentDef()
    if not def then return nil end
    -- Random point in the current cone around the reticle ray, shared by
    -- the whole fan so multi-shot keeps its shape.
    local yaw,pitch=c.yaw,c.pitch
    local cone=M.spread(p)
    if cone>0 then
        local r,theta=cone*math.sqrt(math.random()),math.random()*math.pi*2
        yaw,pitch=yaw+r*math.cos(theta),pitch+r*math.sin(theta)
    end
    local mode=synergy.mode(p)
    local damage=def.damage*(multiplier or 1)*M.damageScale(p)
    -- Brimstone + Technology: the coiled beam's x1.5 (not with double Brimstone).
    local beamDamage=damage
    if mode=='brimstone' and owns(p,'COLLECTIBLE_TECHNOLOGY') and not (type(p.GetCollectibleNum)=='function'
        and CollectibleType and p:GetCollectibleNum(CollectibleType.COLLECTIBLE_BRIMSTONE)>1) then
        beamDamage=damage*M.COMBO.brimTech
    end
    local skin=mode=='melee' and synergy.meleeSkin(p) or nil
    local volley=mode=='epic' and synergy.newVolley() or nil
    local shots={}
    local fan=synergy.fan(synergy.shotCount(p))
    -- 0.5.71 Monstro's Lung: a released charge bursts into a random cone.
    if burst and burst>1 then
        fan={}
        for i=1,burst do fan[i]=(math.random()*2-1)*synergy.LUNG_SPREAD end
    end
    local function special(offset,share,origin,gc)
        local c=gc or c
        -- 0.5.73: the player's own bombs and rings leave the drawn muzzle.
        if not origin and (mode=='fetus' or mode=='techx') then
            local sx,sy=weapons.gunMuzzle(c,yaw+offset)
            origin=Vector(c.x+sx,c.y+sy)
        end
        if mode=='fetus' then return synergy.fireBomb(p,yaw+offset,origin) end
        if mode=='techx' then return synergy.fireTechX(p,yaw+offset,share,origin) end
        if mode=='csection' then
            local tear=fireBullet(p,c,weapons,def,yaw+offset,pitch,share,'tears',nil,volley,origin)
            if tear then synergy.applyFetus(tear) end
            return tear
        end
        return nil
    end
    -- 0.5.78: with dual guns the multi-shot tears are shared out between
    -- the two guns (20/20 alone: one each, straight from each muzzle).
    local pairOf={{c=c,fan=fan}}
    if M.isDual(p) and not (burst and burst>1) then
        local n=#fan
        pairOf={{c=c,fan=synergy.fan(math.max(1,math.ceil(n/2))),side=1},
            {c=setmetatable({muzzleSide=-1},{__index=c}),fan=synergy.fan(math.max(1,math.floor(n/2))),side=-1}}
    end
    local function tag(shot,side)
        if not side or not shot or type(shot.GetData)~='function' then return end
        local gun=shot:GetData().IsaacFPSGunShot
        if type(gun)=='table' then gun.side=side end
    end
    if not lilith(p) then
        for _,gun in ipairs(pairOf) do
        local c,fan=gun.c,gun.fan
        for _,offset in ipairs(fan) do
            local shot=special(offset,damage,nil,c)
            if shot then
            elseif mode=='brimstone' then shot=synergy.fireBrimstone(p,weapons,c.yaw,yaw+offset,beamDamage)
            elseif mode=='technology' then
                shot=synergy.fireTechLaser(p,weapons,c.yaw,yaw+offset,damage)
                    or fireBullet(p,c,weapons,def,yaw+offset,pitch,damage,mode,skin,volley)
            elseif mode=='melee' then
                -- Real thrown weapon; sword beams and failures fall back to a
                -- bullet carrying the weapon's look.
                shot=synergy.fireKnife(p,weapons,c.yaw,yaw+offset,pitch,skin,M.range(p,def),c,def.speed)
                    or fireBullet(p,c,weapons,def,yaw+offset,pitch,damage,mode,skin,volley)
            else shot=fireBullet(p,c,weapons,def,yaw+offset,pitch,damage,mode,skin,volley) end
            tag(shot,gun.side)
            if shot then shots[#shots+1]=shot end
        end
        end
        if not (burst and burst>1) then combos(p,c,weapons,def,mode,yaw,pitch,beamDamage,shots) end
    end
    -- 0.5.62: like the native item, every Incubus copies the trigger pull from
    -- its own position (Lilith: only her Incubus fires). Technology keeps its
    -- native laser from the Incubus; Brimstone, melee and Epic Fetus cannot be
    -- re-homed to a familiar through the API, so the Incubus fires gun bullets
    -- that carry the player's tear effects.
    for _,entry in ipairs(incubi(p)) do
        local origin=entry.familiar.Position
        local share=damage*(entry.share or M.INCUBUS_DAMAGE)
        for _,offset in ipairs(fan) do
            local shot=special(offset,share,origin)
            if not shot and mode=='technology' then
                shot=synergy.fireTechLaser(p,weapons,c.yaw,yaw+offset,share,origin)
            end
            shot=shot or fireBullet(p,c,weapons,def,yaw+offset,pitch,share,
                mode=='epic' and 'epic' or 'tears',nil,volley,origin)
            if shot then shots[#shots+1]=shot end
        end
    end
    return shots[1],shots
end

-- Weapon sounds from content/sounds.xml (sources in resources/sfx/CREDITS.txt).
local soundIds={}
local function soundId(name)
    local id=soundIds[name]
    if id==nil then
        local ok,value=pcall(Isaac.GetSoundIdByName,name)
        id=(ok and type(value)=='number' and value>0) and value or -1
        if id>0 then soundIds[name]=id end
    end
    return id>0 and id or nil
end

local function playSound(name,volume,pitch)
    local id=soundId(name)
    if id then SFXManager():Play(id,volume or 1,0,false,pitch or 1) end
    return id~=nil,id
end

-- Native game sound by SoundEffect name (hit feedback uses the vanilla bank).
local function playNative(name,volume,pitch)
    local id=SoundEffect and SoundEffect[name]
    if id and SFXManager then SFXManager():Play(id,volume or 1,2,false,pitch or 1) end
end

local function stopSound(name)
    local id=soundId(name)
    if id then SFXManager():Stop(id) end
end

local wasReloading=false

-- Called once per logic update with the live camera; returns 'fire'/'empty'.
local lastWeapons
function M.update(p,c,frame,now,weapons,applyKick)
    lastWeapons=weapons
    local acquired=runtime.syncOwnership(function(key) return hasItem(p,key) end)
    if acquired and ctx and ctx.text then
        view.message=ctx.text('weapon_pickup',ctx.text(runtime.defs[acquired].label))
        view.messageUntil=now+3000
    end
    -- Holding a throwable or a no-shoot character: native input owns the attack.
    if M.nativeShootNeeded(p) then runtime.clearInput()
    elseif runtime.controlsAttack() then M.holdNativeWeapon(p) end
    limitSpeed(p)
    charge.full=chargeFrames(p)
    if charge.holding then charge.frames=charge.frames+1 end
    if charge.release then
        charge.release=false
        local ratio=math.min(1,charge.frames/charge.full)
        charge.kind=chargeMode(p)
        charge.ratio=ratio
        if charge.kind=='chocolate' then
            local top=synergy.mode(p)=='brimstone' and M.CHOCOLATE_BRIM_MAX or CHARGE_MAX
            charge.mult=CHARGE_MIN+(top-CHARGE_MIN)*ratio
        else charge.mult=nil end
        runtime.click(now)
    end
    -- 0.5.72: the attack items and the tears stat pick the gun's form.
    local mode=synergy.mode(p)
    runtime.setForm(M.formFor(p,mode))
    local dual=M.isDual(p)
    view.look=M.look(dual)
    -- The tears stat paces the gun; Brimstone uses its own fire-rate CD.
    local soy=soyMode(p)
    local pace=mode=='technology' and owns(p,'COLLECTIBLE_MONSTROS_LUNG') and 'techlung' or mode
    runtime.intervalScale=synergy.intervalScale(pace,p,runtime.currentDef())/(soy and SOY_RATE or 1)
    runtime.shotCost=synergy.shotCost(mode,M.WEAPON_FORMS)*(dual and 2 or 1)
    runtime.magazineScale=(soy and SOY_MAGAZINE or 1)*(dual and 2 or 1)
    runtime.barAmmo=soy
    synergy.updateKnives()
    local result=runtime.update(frame,now)
    -- One reload sound per reload; cut it if the reload is cancelled.
    local reloading=runtime.reloadProgress()~=nil
    if reloading and not wasReloading then playSound('FPS USP Reload',.9)
    elseif not reloading and wasReloading then
        local def=runtime.currentDef()
        local finished=def and runtime.state().mags[def.key]==runtime.capacity(def)
        if not finished then stopSound('FPS USP Reload') end
    end
    wasReloading=reloading
    if result=='fire' then
        M.stats.shots=M.stats.shots+1
        playSound('FPS USP Shot',.8)
        if runtime.form()=='shotgun' then
            -- Multi-shot adds pellets like the native barrage (+2.4 of 14 per tear).
            local pellets=M.SHOTGUN_PELLETS+math.floor(M.SHOTGUN_PER_TEAR*(synergy.shotCount(p)-1)+.5)
            M.fire(p,c,weapons,(charge.mult or 1)*M.SHOTGUN_DAMAGE,math.min(50,pellets))
        else
            local lung=charge.kind=='lung' and synergy.lungCount(charge.ratio) or nil
            M.fire(p,c,weapons,charge.mult,lung)
        end
        -- Cursed Eye: 1-5 rounds by charge; Neptunus: the first shot after a
        -- reload is a short burst.
        local extra=0
        if charge.kind=='cursed' then extra=math.floor((M.CURSED_MAX-1)*(charge.ratio or 0)+.5) end
        -- Neptunus only works on tears (wiki: overridden by the other attacks).
        if runtime.lastFresh and owns(p,'COLLECTIBLE_NEPTUNUS') and (mode=='tears' or mode=='csection') then
            extra=extra+M.NEPTUNUS_EXTRA
        end
        if extra>0 then burst.remaining,burst.next=extra,frame+M.BURST_GAP end
        charge.mult,charge.kind,charge.ratio=nil,nil,nil
        -- Keep the gun's visual animation; firing never rotates the camera.
        view.kick=1
        view.recoverLeft=0
    end
    if result~='fire' and burst.remaining>0 and frame>=burst.next and runtime.controlsAttack()
        and not runtime.reloadProgress() then
        burst.remaining=burst.remaining-1
        burst.next=frame+M.BURST_GAP
        playSound('FPS USP Shot',.7)
        M.fire(p,c,weapons)
    end
    if not runtime.controlsAttack() then burst.remaining=0 end
    -- A charged click that expired unfired must not boost a later shot.
    if (charge.mult or charge.kind) and runtime.state().pending==nil then charge.mult,charge.kind,charge.ratio=nil,nil,nil end
    return result
end

-- 0.5.76 test command `fpsitems`: one pedestal of every item with special
-- gun handling (plus a few tears-ups to reach the rifle), placed on free
-- spots around the room centre. Names missing from this game build are
-- skipped. Returns the console message.
M.TEST_ITEMS={'COLLECTIBLE_BRIMSTONE','COLLECTIBLE_TECHNOLOGY','COLLECTIBLE_TECH_5','COLLECTIBLE_TECH_X',
    'COLLECTIBLE_DR_FETUS','COLLECTIBLE_EPIC_FETUS','COLLECTIBLE_MONSTROS_LUNG','COLLECTIBLE_C_SECTION',
    'COLLECTIBLE_LUDOVICO_TECHNIQUE','COLLECTIBLE_MOMS_KNIFE','COLLECTIBLE_SPIRIT_SWORD',
    'COLLECTIBLE_IPECAC','COLLECTIBLE_HAEMOLACRIA','COLLECTIBLE_CHOCOLATE_MILK','COLLECTIBLE_CURSED_EYE',
    'COLLECTIBLE_NEPTUNUS','COLLECTIBLE_SOY_MILK','COLLECTIBLE_ALMOND_MILK','COLLECTIBLE_MARKED',
    'COLLECTIBLE_INCUBUS','COLLECTIBLE_TWISTED_PAIR','COLLECTIBLE_20_20','COLLECTIBLE_INNER_EYE',
    'COLLECTIBLE_MUTANT_SPIDER','COLLECTIBLE_SAD_ONION','COLLECTIBLE_WIRE_COAT_HANGER','COLLECTIBLE_CRICKETS_BODY'}
function M.spawnTestItems(p)
    local game=Game()
    local room=game and game:GetRoom()
    if not p or not room or not CollectibleType or not EntityType or not Isaac.Spawn then return 'fpsitems: no room or player' end
    local ids={}
    local usp=itemId('usp')
    if usp then ids[#ids+1]=usp end
    for _,name in ipairs(M.TEST_ITEMS) do
        local id=CollectibleType[name]
        if id then ids[#ids+1]=id end
    end
    local center=room:GetCenterPos()
    local variant=PickupVariant and PickupVariant.PICKUP_COLLECTIBLE or 100
    local spawned=0
    for i,id in ipairs(ids) do
        -- Rings of eight around the centre; FindFreePickupSpawnPosition keeps
        -- pedestals off rocks, pits and each other.
        local ring=math.floor((i-1)/8)
        local angle=((i-1)%8)/8*math.pi*2+ring*.4
        local radius=80+ring*60
        local wanted=Vector(center.X+math.cos(angle)*radius,center.Y+math.sin(angle)*radius)
        local position=room:FindFreePickupSpawnPosition(wanted,0,true)
        local ok=pcall(Isaac.Spawn,EntityType.ENTITY_PICKUP,variant,id,position,Vector(0,0),nil)
        if ok then spawned=spawned+1 end
    end
    return string.format('fpsitems: spawned %d gun-compatibility test items',spawned)
end

-- Real accepted damage only (MC_POST_ENTITY_TAKE_DMG). Source must be a
-- bullet this player's gun fired.
local function gunShot(ref,ownerSeed)
    local bullet=ref and ref.Entity
    if not bullet or type(bullet.GetData)~='function' then return false end
    local shot=bullet:GetData().IsaacFPSGunShot
    if shot and shot.owner==ownerSeed then return shot end
    return nil
end


local function playHit(kill)
    -- Hit confirm: the bundled hit sound (kills louder and lower), or the
    -- vanilla impact when it is unavailable.
    local custom,id=playSound('FPS Hit',kill and 2.2 or 1.8,kill and .85 or 1)
    if not custom then
        id=SoundEffect and SoundEffect.SOUND_MEAT_IMPACTS
        playNative('SOUND_MEAT_IMPACTS',kill and 1.6 or 1.2,kill and 1.25 or 1.1)
    end
    local playing='?'
    if id and SFXManager then
        local ok,value=pcall(function() return SFXManager():IsPlaying(id) end)
        if ok then playing=tostring(value) end
    end
    if audioOpen('play') then audioLine('play',string.format('soundID=%s fallback=%s kill=%s playing=%s',
        tostring(id),tostring(not custom),tostring(kill),playing)) end
end

local function vulnerableEnemy(entity)
    if not entity or type(entity.IsVulnerableEnemy)~='function' or not entity:IsVulnerableEnemy() then return false end
    if EntityFlag and EntityFlag.FLAG_FRIENDLY and type(entity.HasEntityFlags)=='function'
        and entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then return false end
    return true
end

-- A gun bullet touching an enemy (called from PRE_TEAR_COLLISION once the
-- 3D shape agrees it hits). The hit sound plays here, at the contact itself,
-- instead of depending on how the later damage event reports its source;
-- one cue per bullet and target. onDamage still adds the marker and the
-- kill cue.
function M.onTearContact(tear,collider,ownerSeed)
    local data=tear and type(tear.GetData)=='function' and tear:GetData() or nil
    local gun=data and data.IsaacFPSGunShot
    if collider and collider.Type and collider.Type>=10 and collider.Type<1000 then
        if audioOpen('contact') then audioLine('contact',string.format('target=%s.%s gun=%s vulnerable=%s',tostring(collider.Type),
            tostring(collider.Variant),tostring(gun~=nil),tostring(vulnerableEnemy(collider)))) end
    end
    if not gun or gun.owner~=ownerSeed or not vulnerableEnemy(collider) then return false end
    local key=GetPtrHash and GetPtrHash(collider) or collider
    gun.cued=gun.cued or {}
    if gun.cued[key] then return false end
    local frame=Game():GetFrameCount()
    gun.cued[key]=frame
    playHit(false)
    -- The native tear impact sound plays when this bullet dies, in this or
    -- the next logic frame; PRE_SFX_PLAY carries no source entity, so the
    -- impact IDs are muted for that short window instead (see M.muteSfx).
    M.muteImpactFrom,M.muteImpactUntil=frame,frame+1
    return true
end

-- MC_PRE_SFX_PLAY: false cancels. Only the native tear impact/splatter
-- sounds, only in the frame window right after a gun bullet hit an enemy
-- (another tear landing in the same two frames is muted too).
-- Both ends are kept: the frame counter restarts with each run.
M.muteImpactFrom,M.muteImpactUntil=1,0
function M.muteSfx(id,frame)
    if frame<M.muteImpactFrom or frame>M.muteImpactUntil or not SoundEffect then return nil end
    if id~=SoundEffect.SOUND_TEARIMPACTS and id~=SoundEffect.SOUND_SPLATTER then return nil end
    if audioOpen('mute') then audioLine('mute',string.format('soundID=%s frame=%d',tostring(id),frame)) end
    return false
end

function M.onDamage(entity,amount,source,ownerSeed,now,extraSource)
    if not entity or (amount or 0)<=0 then return nil end
    local gun=gunShot(source,ownerSeed) or gunShot(extraSource,ownerSeed)
    local ref=source and source.Entity
    if audioOpen('damage') then audioLine('damage',string.format('target=%s.%s amount=%.2f srcType=%s ref=%s gun=%s',tostring(entity.Type),
        tostring(entity.Variant),amount or 0,tostring(source and source.Type),tostring(ref~=nil),tostring(gun~=nil))) end
    if not gun then return nil end
    local kill=(type(entity.HasMortalDamage)=='function' and entity:HasMortalDamage())
        or (entity.HitPoints and entity.HitPoints<=0) or false
    if type(entity.IsVulnerableEnemy)~='function' or not entity:IsVulnerableEnemy() then
        -- POST damage can already have cleared vulnerability on a killed
        -- enemy; being dead alone must not turn props or friends into hits.
        if not kill or type(entity.IsEnemy)~='function' or not entity:IsEnemy() then return nil end
        if EntityFlag and EntityFlag.FLAG_FRIENDLY and type(entity.HasEntityFlags)=='function'
            and entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then return nil end
    end
    -- Deduplicate callback reentry on this primary bullet and stable target
    -- identity in the same logic frame. Piercing targets, other bullets,
    -- and a later accepted contact each keep their own feedback.
    local frame=Game():GetFrameCount()
    local key=GetPtrHash and GetPtrHash(entity) or entity
    gun.hits=gun.hits or {}
    if gun.hits[key]==frame then return nil end
    -- Beams and thrown knives hit repeatedly; one hit cue per target each.
    if (gun.laser or gun.multi) and gun.hits[key] and not kill then return nil end
    gun.hits[key]=frame
    view.markers[#view.markers+1]={time=now,kill=kill}
    -- The contact already played the hit cue for this bullet and target;
    -- a kill still gets its own (louder, lower) cue.
    local cued=gun.cued and gun.cued[key]
    if kill or not cued then playHit(kill) end
    while #view.markers>6 do table.remove(view.markers,1) end
    return kill and 'kill' or 'hit'
end

-- Diagnostic for comparing hit frequency and speed of the native thrown
-- Mom's Knife with gun knives: every knife damage event and each flying
-- knife's per-frame travel are written to log.txt (bounded per run).
local KNIFE_LOG_LIMIT=400
local knifeLog={count=0,tracks={}}
local function knifeLine(text)
    if knifeLog.count>=KNIFE_LOG_LIMIT or not (Isaac and Isaac.DebugString) then return end
    knifeLog.count=knifeLog.count+1
    Isaac.DebugString('[Isaac FPS Probe] knife diag: '..text)
end
function M.resetKnifeLog() knifeLog={count=0,tracks={}} end

function M.logKnifeHit(entity,amount,source)
    local knife=source and source.Entity
    if not knife or not EntityType or knife.Type~=EntityType.ENTITY_KNIFE then return end
    local data=type(knife.GetData)=='function' and knife:GetData() or {}
    knifeLine(string.format('hit frame=%d knife=%s var=%d sub=%d gun=%s target=%s.%s idx=%s dmg=%.2f',
        Game():GetFrameCount(),tostring(GetPtrHash and GetPtrHash(knife) or '?'),knife.Variant or -1,
        knife.SubType or -1,tostring(data.IsaacFPSGunKnife~=nil),tostring(entity.Type),
        tostring(entity.Variant),tostring(entity.Index),amount or 0))
end

-- Called from the POST knife update: first 12 frames of each flying knife.
function M.logKnifeFlight(knife)
    local flying=knife.SubType==1 or (type(knife.IsFlying)=='function' and knife:IsFlying())
    if not flying then return end
    local key=GetPtrHash and GetPtrHash(knife) or knife
    local track=knifeLog.tracks[key]
    if not track then track={n=0};knifeLog.tracks[key]=track end
    if track.n>=12 then return end
    track.n=track.n+1
    local moved=track.x and math.sqrt((knife.Position.X-track.x)^2+(knife.Position.Y-track.y)^2) or 0
    track.x,track.y=knife.Position.X,knife.Position.Y
    knifeLine(string.format('move frame=%d knife=%s var=%d sub=%d gun=%s step=%.1f',
        Game():GetFrameCount(),tostring(key),knife.Variant or -1,knife.SubType or -1,
        tostring(knife:GetData().IsaacFPSGunKnife~=nil),moved))
end

-- Hit markers: four diagonal ticks around the reticle. Kills are red and longer.
function M.drawMarkers(sw,sh,now,line)
    local cx,cy=sw/2,sh/2
    for i=#view.markers,1,-1 do
        local marker=view.markers[i]
        local life=marker.kill and 420 or 200
        local age=now-marker.time
        if age>life or age<0 then table.remove(view.markers,i)
        else
            local a=1-age/life
            local r,g,b=1,1,1
            if marker.kill then r,g,b=1,.22,.18 end
            local inner,outer=4,marker.kill and 10 or 8
            for _,d in ipairs({{1,1},{-1,1},{1,-1},{-1,-1}}) do
                line(cx+d[1]*inner,cy+d[2]*inner,cx+d[1]*outer,cy+d[2]*outer,r,g,b,a)
            end
        end
    end
end

function M.drawMessage(sw,now,drawText,textWidth)
    if not view.message or now>view.messageUntil then view.message=nil;return end
    local width=textWidth(view.message)
    drawText(view.message,math.floor((sw-width)/2),20,1,.9,.6,1)
end

-- 0.5.72 weapon form from the attack mode and the tears stat. Tear-firing
-- modes are a pistol until the fire delay drops to RIFLE_DELAY, then a
-- full-auto rifle (back above RIFLE_BACK, no flicker).
-- 0.5.99 (user: two tears-up items should make the rifle): tears =
-- 30/(delay+1); base 2.73, common tears ups +0.5 to +0.7. Rifle from 3.7
-- tears (delay 7.1: two +0.5 items reach 3.73, one Sad Onion 3.43 does
-- not), back to the pistol below 3.3 (delay 8.1). Was 5.0 / 4.0.
M.RIFLE_DELAY,M.RIFLE_BACK=7.1,8.1
-- Off until the user approves the previews (art/weapon-forms-preview):
-- the gun stays the pistol, Dr. Fetus spends 4 rounds per bomb, Monstro's
-- Lung charges, and no reflex sight is mounted.
M.WEAPON_FORMS=true
M.SHOTGUN_PELLETS,M.SHOTGUN_DAMAGE=8,.5
M.SHOTGUN_PER_TEAR=2.4*8/14  -- 0.5.78: pellets per extra multi-shot tear
local FORM_BY_MODE={brimstone='laser',technology='beam',techx='beam',fetus='launcher',epic='flare',lung='shotgun'}
function M.formFor(p,mode)
    if not M.WEAPON_FORMS then return 'pistol' end
    local form=FORM_BY_MODE[mode]
    if form then return form end
    local delay=p and tonumber(p.MaxFireDelay) or 10
    local rifle=runtime.form()=='rifle'
    if rifle then rifle=delay<=M.RIFLE_BACK else rifle=delay<=M.RIFLE_DELAY end
    return rifle and 'rifle' or 'pistol'
end
-- View-model look: form and the optional reflex sight (settings).
local looks={}
-- dual (0.5.78): a mirrored pair; no reflex sight since it never aims.
function M.look(dual)
    local form=runtime.form() or 'pistol'
    dual=dual==true and M.DUAL_FORMS[form]==true
    local reflex=not dual and M.WEAPON_FORMS and ctx and ctx.reflexSight and ctx.reflexSight() and true or false
    local key=form..(reflex and '|reflex' or '')..(dual and '|dual' or '')
    local look=looks[key]
    if not look then
        look={form=form,reflex=reflex,dual=dual or nil,key=key}
        look.sightY=model.sightY(look)
        looks[key]=look
    end
    return look
end

-- 0.5.73: where the muzzle is on screen, as the view-ray slopes (right,
-- up per unit forward) of the WORLD camera (fov/zoom of the scene), so a
-- gun beam can start on the ray through the drawn muzzle at hip and in ADS.
-- side=-1: the left gun of a dual pair.
function M.muzzleAim(fov,zoom,side)
    local state=M.viewState()
    local muzzle=model.muzzle(state.look)
    if not muzzle then return nil end
    local x,y,depth=model.projectPoint(muzzle,{ads=state.ads,kick=0,look=state.look,sightY=state.sightY},
        {width=0,height=0,focal=1},side)
    if not depth or depth<=0 then return nil end
    local viewSlope=1/(math.tan(math.rad(68)/2))*(1+.25*state.ads)
    local worldSlope=1/(math.tan(math.rad(fov or 75)/2))*(zoom or 1)*M.zoom()
    local ratio=viewSlope/worldSlope
    return x*ratio,-y*ratio
end

function M.viewState()
    local look=view.look or M.look()
    return {ads=look.dual and 0 or view.ads,kick=view.kick,reload=runtime.reloadProgress(),look=look,sightY=look.sightY}
end

-- View-model faces with its own fixed 68-degree focal (zoomed with ADS).
-- A settled gun (no kick, no reload, ADS fully in or out) reuses the last
-- faces, so the common idle frames build no geometry and no garbage. While
-- only recoil kick differs from that settled pose, the same faces are
-- returned with a 2D affine (from three projected gun points) so the host
-- can move one cached image instead of rebuilding ~50 faces every shot.
local viewCache={}
-- 0.5.52: reload animation poses cached in RELOAD_STEPS steps (about 50 ms
-- each over the 1.2 s reload): rebuilding the model every reload frame was
-- 100-170 KiB of garbage per frame, and Soy Milk reloads often.
local RELOAD_STEPS=24
local reloadCache={steps={}}
-- At full ADS (no yaw) these project onto one vertical line: the affine is
-- degenerate there on purpose, since near the camera a 2D affine is 10-40 px
-- off at full kick; kicked ADS frames are rebuilt exactly (pooled, 0.5.95).
local KICK_POINTS={{0,-1,1.2},{0,-1,5.2},{0,1,1.2}}
M.KICK_POINTS=KICK_POINTS
-- Scratch point tables for the exact (uncached) builds.
local facePool={}
local function kickAffine(state,view)
    local settled={ads=state.ads,kick=0,look=state.look,sightY=state.sightY}
    local a,b={},{}
    for i,point in ipairs(KICK_POINTS) do
        local ax,ay,ad=model.projectPoint(point,settled,view)
        local bx,by,bd=model.projectPoint(point,state,view)
        if ad<=view.near or bd<=view.near then return nil end
        a[i],b[i]={ax,ay},{bx,by}
    end
    local a1x,a1y,a2x,a2y=a[2][1]-a[1][1],a[2][2]-a[1][2],a[3][1]-a[1][1],a[3][2]-a[1][2]
    local det=a1x*a2y-a2x*a1y
    if math.abs(det)<1e-9 then return nil end
    local b1x,b1y,b2x,b2y=b[2][1]-b[1][1],b[2][2]-b[1][2],b[3][1]-b[1][1],b[3][2]-b[1][2]
    -- M = [b1 b2] * inverse([a1 a2])
    local m11=(b1x*a2y-b2x*a1y)/det
    local m12=(b2x*a1x-b1x*a2x)/det
    local m21=(b1y*a2y-b2y*a1y)/det
    local m22=(b2y*a1x-b1y*a2x)/det
    return {m11=m11,m12=m12,m21=m21,m22=m22,
        tx=b[1][1]-(m11*a[1][1]+m12*a[1][2]),ty=b[1][2]-(m21*a[1][1]+m22*a[1][2])}
end
M.kickAffine=kickAffine

-- Returns faces, reusable (settled set), affine (kick on top of the settled
-- set, or nil). exact=true always rebuilds the current pose.
function M.viewFaces(sw,sh,exact)
    if not runtime.controlsAttack() then return {} end
    local state=M.viewState()
    local steady=not state.reload and (state.ads==0 or state.ads==1)
    local settled=steady and state.kick<.002
    local focal=sw/(2*math.tan(math.rad(68)/2))*(1+.25*state.ads)
    local viewInfo={width=sw,height=sh,focal=focal,near=2}
    local hit=viewCache.faces and viewCache.sw==sw and viewCache.sh==sh and viewCache.ads==state.ads
        and viewCache.look==state.look
    -- 0.5.95 (F8: aiming while shooting rebuilt the whole gun every frame):
    -- the settled set was only stored once the kick had died out, which
    -- never happens while firing a few shots a second, so ADS kept missing.
    -- A steady gun now builds its kick-free pose straight away; the kick is
    -- the affine on top of it.
    if not exact and steady and not hit and not settled then
        viewCache={faces=model.faces({ads=state.ads,kick=0,look=state.look,sightY=state.sightY},viewInfo),
            sw=sw,sh=sh,ads=state.ads,look=state.look}
        hit=true
    end
    if not exact and steady and hit then
        if settled then return viewCache.faces,true end
        -- One affine cannot move a mirrored pair: dual guns rebuild instead.
        local affine=not (state.look and state.look.dual) and kickAffine(state,viewInfo) or nil
        if affine then return viewCache.faces,true,affine end
    end
    if not exact and state.reload and state.kick<.002 and (state.ads==0 or state.ads==1) then
        if reloadCache.sw~=sw or reloadCache.sh~=sh or reloadCache.ads~=state.ads or reloadCache.look~=state.look then
            reloadCache={sw=sw,sh=sh,ads=state.ads,look=state.look,steps={}}
        end
        local step=math.floor(state.reload*RELOAD_STEPS+.5)
        local cached=reloadCache.steps[step]
        if not cached then
            cached=model.faces({ads=state.ads,kick=0,reload=step/RELOAD_STEPS,look=state.look,sightY=state.sightY},viewInfo)
            reloadCache.steps[step]=cached
        end
        return cached,false
    end
    -- A settled build is kept (viewCache); any other is drawn once and its
    -- point tables are reused by the next exact build.
    local faces=model.faces(state,viewInfo,not settled and facePool or nil)
    if settled then viewCache={faces=faces,sw=sw,sh=sh,ads=state.ads,look=state.look}
    elseif not steady then viewCache={} end
    return faces,settled
end

function M.status(nativeName,text)
    local label=ctx and ctx.reloadLabel and ctx.reloadLabel() or 'R'
    return runtime.status(nativeName,function(key,...)
        if key=='weapon_empty' then return text(key,label) end
        return text(key,...)
    end)
end

function M.release()
    if wasReloading then stopSound('FPS USP Reload') end
    wasReloading=false
    M.muteImpactFrom,M.muteImpactUntil=1,0
    runtime.clearInput()
    view.adsTarget,view.ads,view.kick,view.recoverLeft=0,0,0,0
    view.time=nil
    view.markers={}
    view.message=nil
end

local function loadDocument()
    if not modRef or type(modRef.LoadData)~='function' then return nil end
    local ok,raw=pcall(function() return modRef:LoadData() end)
    if not ok or type(raw)~='string' or raw=='' then return {} end
    local decoded,data=pcall(function() return json.decode(raw) end)
    return decoded and type(data)=='table' and data or {}
end

local function runSeed()
    local ok,seed=pcall(function() return Game():GetSeeds():GetStartSeed() end)
    return ok and seed or nil
end

function M.save()
    local document=loadDocument()
    if not document or type(modRef.SaveData)~='function' then return end
    -- Namespaced merge: camera settings and other keys stay untouched.
    document[SAVE_KEY]=runtime.serialize(runSeed())
    pcall(function() modRef:SaveData(json.encode(document)) end)
end

function M.load(continued)
    if not continued then runtime.reset();return end
    local document=loadDocument()
    runtime.restore(document and document[SAVE_KEY],runSeed())
end

-- Test helper: a fresh run places a USP pedestal next to the player.
local SPAWN_USP_ON_START=true

-- 0.5.105 (user: the pedestal beside the player sat under the centred
-- "Press F6" hint): it goes to the room centre, or above the centre when
-- the player stands within START_CLEAR of it (no instant pickup).
M.START_CLEAR,M.START_LIFT=60,80
function M.startPedestalTarget(center,player)
    local dx,dy=player.X-center.X,player.Y-center.Y
    if dx*dx+dy*dy<M.START_CLEAR*M.START_CLEAR then return Vector(center.X,center.Y-M.START_LIFT) end
    return Vector(center.X,center.Y)
end
local function spawnStartPedestal(p)
    local id=itemId('usp')
    if not id or p:HasCollectible(id) then return end
    local room=Game():GetRoom()
    local target=M.startPedestalTarget(room:GetCenterPos(),p.Position)
    local pos=room:FindFreePickupSpawnPosition(target,0,true)
    Isaac.Spawn(EntityType.ENTITY_PICKUP,PickupVariant.PICKUP_COLLECTIBLE,id,pos,Vector(0,0),nil)
end

function M.register(mod,context)
    modRef,ctx=mod,context
    local guard=context.guard
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,guard(function(_,continued)
        itemIds={}
        soundIds={}
        hitAudioDiagnosed={}
        synergy.resetEpic()
        synergy.resetKnives()
        M.resetKnifeLog()
        M.release()
        M.load(continued)
        view.runLoaded=true
        local p=context.player()
        if p then
            runtime.syncOwnership(function(key) return hasItem(p,key) end)
            runtime.applyRestoredCurrent()
            if SPAWN_USP_ON_START and not continued then spawnStartPedestal(p) end
        end
    end,'GUN_GAME_STARTED'))
    -- The game autosaves per room; mirror that so a crash cannot refill.
    -- Only between GAME_STARTED and PRE_GAME_EXIT: a continue may enter its
    -- first room before GAME_STARTED loads this run's data.
    if ModCallbacks.MC_POST_NEW_ROOM then
        mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,guard(function()
            synergy.resetEpic()
            synergy.resetKnives()
            if view.runLoaded and context.player() and #runtime.state().owned>1 then M.save() end
        end,'GUN_NEW_ROOM'))
    end
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,guard(function(_,shouldSave)
        if shouldSave and view.runLoaded then M.save() end
        view.runLoaded=false
        runtime.reset()
        M.release()
    end,'GUN_GAME_EXIT'))
    if ModCallbacks.MC_POST_FIRE_TEAR then
        -- Before the generic tear adapter: a dropped tear is never converted.
        mod:AddPriorityCallback(ModCallbacks.MC_POST_FIRE_TEAR,-200,guard(function(_,tear)
            local p=context.player()
            local spawner=tear and tear.SpawnerEntity
            if not p or not spawner or GetPtrHash(spawner)~=GetPtrHash(p) then return end
            M.dropNativeTear(tear,p)
        end,'GUN_DROP_NATIVE_TEAR'))
    end
    -- 0.5.62: with the gun out an Incubus fires the gun's rounds (M.fire);
    -- its own native shots (e.g. driven by Mouse Control) are dropped.
    for _,name in ipairs({'MC_POST_FAMILIAR_FIRE_PROJECTILE','MC_POST_FAMILIAR_FIRE_BRIMSTONE','MC_POST_FAMILIAR_FIRE_TECH_LASER'}) do
        local id=ModCallbacks[name]
        if id and FamiliarVariant and FamiliarVariant.INCUBUS then
            mod:AddCallback(id,guard(function(_,shot)
                local p=context.player()
                if p then M.dropNativeFamiliarShot(shot,p) end
            end,'GUN_DROP_INCUBUS_SHOT'),FamiliarVariant.INCUBUS)
        end
    end
    if ModCallbacks.MC_PRE_SFX_PLAY then
        mod:AddCallback(ModCallbacks.MC_PRE_SFX_PLAY,guard(function(_,id)
            if not context.enabled() then return end
            return M.muteSfx(id,Game():GetFrameCount())
        end,'GUN_MUTE_IMPACT'))
    end
    if ModCallbacks.MC_POST_ENTITY_TAKE_DMG then
        mod:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG,guard(function(_,entity,amount,_,source,_,extraSource)
            -- Knife hit timing diagnostic (native thrown knife vs gun knife).
            M.logKnifeHit(entity,amount,source)
            -- Gun knives re-hit at the wiki rate of Mom's Knife (20/s).
            if (amount or 0)>0 and source and source.Entity then
                synergy.knifeHit(source.Entity,entity,Game():GetFrameCount())
            end
            if not context.enabled() then return end
            local p=context.player()
            if not p then return end
            -- Epic Fetus: a bullet that hurt an enemy marks a missile strike.
            if (amount or 0)>0 and type(entity.IsEnemy)=='function' and entity:IsEnemy() then
                synergy.epicHit(source,extraSource,entity.Position,Game():GetFrameCount(),synergy.spawnTarget,M.epicSatellites(p))
            end
            local result=M.onDamage(entity,amount,source,p.InitSeed,Isaac.GetTime(),extraSource)
            -- Diagnostic (first few only): tear damage that was not matched
            -- to a gun bullet, to see what the engine reports as the source.
            local ref=source and source.Entity
            if not result and runtime.controlsAttack() and (diagnosed or 0)<5 and amount and amount>0
                and source and source.Type==EntityType.ENTITY_TEAR then
                diagnosed=(diagnosed or 0)+1
                local data=ref and type(ref.GetData)=='function' and ref:GetData() or nil
                Isaac.DebugString(string.format('[Isaac FPS Probe] hit diag: target=%s.%s srcType=%s ref=%s gunData=%s spawner=%s',
                    tostring(entity.Type),tostring(entity.Variant),tostring(source.Type),tostring(ref~=nil),
                    tostring(data and data.IsaacFPSGunShot~=nil),tostring(ref and ref.SpawnerType)))
            end
        end,'GUN_TAKE_DMG'))
    end
    -- Strikes land even if FPS is toggled off meanwhile; rooms clear them.
    if ModCallbacks.MC_POST_UPDATE then
        mod:AddCallback(ModCallbacks.MC_POST_UPDATE,guard(function()
            if #synergy.epicState().strikes==0 then return end
            synergy.updateStrikes(Game():GetFrameCount(),function(strike)
                synergy.explode(context.player(),strike,lastWeapons)
            end)
        end,'GUN_EPIC_STRIKES'))
    end
    -- Gun knives fly straight: hold the native path still and move them
    -- before native AI/collision (PRE) and again after it (POST).
    if ModCallbacks.MC_PRE_KNIFE_UPDATE then
        mod:AddCallback(ModCallbacks.MC_PRE_KNIFE_UPDATE,guard(function(_,knife)
            synergy.steerKnife(knife,Game():GetFrameCount(),true)
        end,'GUN_KNIFE_PRE'))
        mod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE,guard(function(_,knife)
            synergy.steerKnife(knife,Game():GetFrameCount(),false)
            M.logKnifeFlight(knife)
        end,'GUN_KNIFE_POST'))
    end
    if ModCallbacks.MC_POST_TEAR_INIT then
        mod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT,guard(function(_,tear)
            if synergy.epicState().volley>0 then synergy.inheritEpic(tear) end
        end,'GUN_EPIC_SPLIT'))
    end
    -- 0.5.78: a flare round calls its strike where it lands.
    if ModCallbacks.MC_POST_TEAR_DEATH then
        mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH,guard(function(_,tear)
            if synergy.epicState().volley==0 or not context.enabled() then return end
            synergy.epicLand(tear,Game():GetFrameCount(),synergy.spawnTarget,M.epicSatellites(context.player()))
        end,'GUN_EPIC_LAND'))
    end
    -- 0.5.78: native Epic Fetus targets/rockets (Mouse Control at the room
    -- centre) are dropped while the flare gun owns the attack.
    if ModCallbacks.MC_POST_EFFECT_UPDATE and EffectVariant then
        for _,variant in ipairs({EffectVariant.TARGET,EffectVariant.ROCKET}) do
            if variant then
                mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE,guard(function(_,effect)
                    if not context.enabled() or not runtime.controlsAttack() then return end
                    local p=context.player()
                    if not p or M.nativeShootNeeded(p) then return end
                    if synergy.nativeEpicEffect(effect,p) then
                        effect:Remove()
                        M.stats.dropped=M.stats.dropped+1
                    end
                end,'GUN_DROP_EPIC_TARGET'),variant)
            end
        end
    end
    if ModCallbacks.MC_EXECUTE_CMD then
        mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD,guard(function(_,command)
            if command=='fpsitems' then return M.spawnTestItems(context.player()) end
            if command~='fpsusp' then return end
            local p=context.player()
            local id=itemId('usp')
            if not p or not id then return 'USP item not registered' end
            p:AddCollectible(id)
            return 'USP Suppressed added'
        end,'GUN_CMD'))
    end
end

return M

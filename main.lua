-- ISAAC FPS MOD 0.5.132 (stable). Reload key: Mod Config Menu can restore the default R using its configured reset key on the option list. 0.5.131: Pits: a wall band or bottom is clipped only through openings its eye projection onto the floor overlaps (allocation-free bounding-box test; same faces), opening corners made once per layout, clip planes passed as numbers; F8 counts pitClips. 0.5.130: Door art: the strange door (Door_Mausoleum_Alt) leaf layers are whole stone slabs with a square front plaque; house/closet doors redrawn at normal-door width (thin wooden frame, one door with a knob); Mom's Heart redrawn (round flesh-lump frame, whole cracked flesh plug, flat red passage). 0.5.129's drawing of engine-hidden leaf layers is reverted (it showed the unused slab state). Door openings re-measured. 0.5.129: Door leaf layers (Door1/2/3) with a visible frame are drawn even when the layer is flagged hidden at run time, as the native door render does (Depths II strange door right leaf); other hidden layers stay hidden. 0.5.128: Doors draw their sprite overlay animation layers too (after the main ones): the strange door hides its right leaf in the main KeyClosed animation while the native view shows it. Door log adds the overlay animation, overlay layers (+) and ExtraSprite state. 0.5.127: Diagnostic: every built door state logs its animation and layers (visible, crop, mapped art or native, recessed), 24 lines per session, for the Depths II strange door that shows one leaf. 0.5.126: Alternate-stage lighting masks (Downpour/Dross/Mines/Ashpit/Mausoleum/Gehenna/Corpse) back on: the native opaque light maps are converted to black RGB with alpha = darkness, at most 56 like the original-chapter masks (art/room-light-overlays/convert_grey_light.py). 0.5.125: Alternate-stage lighting masks (Downpour/Dross/Mines/Ashpit/Mausoleum/Gehenna/Corpse) disabled: the 0.5.123 copies were opaque black over floor and walls; regular wall details read the Backdrop only in backdrop types that have them. 0.5.124: Health panel bottom 26 px above the screen edge (was 8), clear of the trinket slot. 0.5.123: Ordinary crawlspace native-grid rendering; regular walls/details, nine rock families, TNT/locks, fireplace fuel and alternate-stage lighting. 0.5.122: Grey laser animation copies use white frame tints: Brimstone frames tint 255,0,0 and the Beam renderer multiplies the frame tint last, which kept every colorized beam red. 0.5.121: Colorized lasers load a grey copy of their native animation (resources/gfx/fps_probe/laser-gray/007.*.anm2 naming the greyscale png) instead of replacing the spritesheet at run time, which still drew red; the Beam texture is read back into the log. Spritesheet-path lookup tables and the unused colorize approximation removed. 0.5.120: Fix: the grey laser sprite was never made (Sprite is a callable table, not a function); the texture also falls back to the native anm2 name; every attempt is logged with its reason. 0.5.119: Colorized lasers (Soy Milk) are drawn from greyscale copies of the native laser textures (resources/gfx/fps_probe/laser-gray, luma per texel) with luma(tint)*colorize as the point colour, matching the native shader; the Beam renderer ignored a sprite colorize. Laser draw states rebuild on any colorize change. 0.5.118: Laser colorize (Soy Milk Brimstone) is set on the Beam sprites for the engine beam shader (per texel) instead of approximated in point colours; a colorize change rebuilds the beam set. 0.5.117: Fix: the 0.5.116 look-spike log used %d on fractional screen deltas, which raised in RENDER_INPUT and turned FPS off after a quick turn; now %.1f inside pcall. 0.5.116: Look: the aim camera also sets the native camera focus to its snapped point (release: back to the player), so the engine camera update no longer eases it back between look reads; look spikes are logged with the camera shift since the frame tail. 0.5.115: Laser colours: the colorize part of a Color (REPENTOGON GetColorize) is read and applied to the beam like the native shader; a player laser with a plain colour takes the player laser colour (GetLaserColor/LaserColor); non-plain laser colours are logged. 0.5.114: Gun rounds rise/fall by the vertical speed fireTear computed for the aim ray (kept as IsaacFPSGunShot.vz); FallingSpeed read back 0 in game, so 0.5.113 stepped by 0. 0.5.113: Gun rounds follow the pitch in flight: their height is advanced by the launch vertical speed each update (the engine left Height unchanged, so they flew level); first rounds log engine vs set height. 0.5.112: Gun rounds are turned onto the view from the direction FireTear actually left along (not the requested one); gun rounds and native tears logged per view quarter. A collectible swapped on its pedestal is re-copied at once (SubType is a sprite-cache key). 0.5.111: Without REPENTOGON only a bilingual install notice is loaded (fps_need_repentogon: 30 s at run start, again on F6). 0.5.110: Native 360-degree aim: the native camera is snapped ahead of the player along the view (fps_aim_camera, clamping off) so Mouse Control's centred cursor and every native attack point along the view; no cardinal shoot action on top. Gun rounds, beams and knives are fired along the exact view yaw (base = view yaw at the shot). 0.5.109: 45-degree aim: gun beams/knives keep the cardinal they were fired along (IsaacFPSGunShot.base) and native shots consider both cardinals around the view (the nearest one flips near a diagonal between shot and conversion). Gun beams are drawn from the current muzzle and view every render. Lasers: frame-wide entry pool, Beam:Add(Vector) with one scratch Vector, longer far segments. 0.5.108: Aim: tears other items add inside the gun's FireTear (Loki's Horns, Mom's Eye) are turned with the bullet; every entity a gun shot spawns takes the gun's cardinal as its base (weapons.firingBase). Lasers: one draw state per laser kept across frames (no sprite copy per frame), entry tables reused, closure-free projection, 24-unit Beam segments, cached strip colours. 0.5.107: USP-S collectible icon v5 (USP body first, then a slim coaxial can; user-approved). 0.5.106: Native tears: the player-movement inheritance (GetTearMovementInheritance) is removed before choosing the native base and turning to the view, and added back for the view direction; the first 24 native tears are logged with every candidate, the inheritance and the player velocity. 0.5.105: The start USP pedestal spawns at the room centre (above it if the player stands there), clear of the "Press F6" hint. 0.5.104: Familiar tears (MC_POST_FAMILIAR_FIRE_PROJECTILE) are turned from the native aim (toward the centred cursor, i.e. the room centre) to the view; unconverted tears heading off the view are logged with their source; the Chinese weapon label for tears reads 眼泪. 0.5.103: Door gate overlays (double-lock chains, cracked/bar door bars) placed by the main sprite's Offset when the ExtraSprite has none: they line up with the frame instead of sitting 15 units above or below; door log includes the ExtraSprite offset. 0.5.102: GC: REPENTOGON's generational mode is kept (no longer switched to incremental at load); while FPS is on the automatic collector is stopped and one young collection runs at every frame tail; fpsgctest times those steps. 0.5.101: Door recess (passage, leaves, reveals) clipped on screen to the projected opening, so it no longer shows through the wall from the side; Mod Config Menu lists General first with the language as its first entry. 0.5.100: Big-room live heap: obstacle faces compacted after build (UV arrays, shared source vertices and build-only fields dropped; ~35% fewer tables per mesh), projection buffers and camera points created on first CPU use, GPU pieces one flat number array per orientation; per-face mesh pairing cache is a plain table. F8 gc_modeReset/gc_restarted. Health panel in the bottom-left corner beside the trinket slot. 0.5.99: Rifle from 3.7 tears (two common tears ups), back to the pistol below 3.3 (was 5.0 / 4.0). 0.5.98: Hit boxes include overlay animation layers (Gaper-style heads drawn over the walking body). 0.5.97: HUD: top line is version + sensitivity only; "Press F6" shows centred at the run start and goes once FPS is on or after 10 s (messages fade after 5 s); hearts start right of the native stat column. Doors: native screen-space Offset rotated into the door frame (side doors no longer slide 15 units along the wall). Big rooms: obstacles revalidate staggered and light (no layer reads unless something changed, full every 10th). F8 kb_panels/kb_teleport. 0.5.96: Big-room stutter probes: console command fpsgctest (timed frame-tail collection cycles, longest step per cycle with faces in view); F8 gcFreedKiB and vertexWrites. 0.5.95: Gun view model garbage: parts/muzzle cached per look (laserPose built the whole gun per beam per frame), rotation inlined, hip fire caches the kick-free pose at once (affine on top), kicked ADS rebuilds reuse their point tables; F8 ws_kb_* per world sub-stage. 0.5.94: Config menu and HUD auto-Chinese with the Chinese MCM fork (English game + Chinese patch); doors anchored on their grid cell centre, door placement logged. 0.5.93: Environment materials: 59 new walls, all native backdrop base routes, complementary big rocks and detailed mine props. Previous integrated release: Shots drawn with their entity colour; gun beams keep the native tint and are detached from the player aim (origin carried by aimLaser). 0.5.91: Gun bullets and thrown gun knives follow the panel Range stat; minimap dots outlined, bosses larger, pickups coloured by kind; USP-S icon v3. 0.5.90: Room light overlays from black-RGB copies (no white walls); Spirit Sword pose uses GetAnimationData; native weapon held while the gun owns the attack. 0.5.89: Big-room garbage cut again: enemy body entries (with their sort keys) reused per entity, off-screen arrows written into one table, billboards reuse scratch Scale/Offset/Render vectors, obstacle revalidation keeps the tint as numbers. 0.5.88: Big-room garbage halved: enemy shadows reuse one record per entity, vertices keep their camera points; shadows no longer share one projection scratch. 0.5.87: Chapter lighting overlays on the floor and walls (fps_room_light). 0.5.86: Door frame decorations (boss Eyes, arcade/exit Sign, frame Glow) stay on the wall plane. 0.5.85: Minecraft-style hurt (blinking hearts, lost half-hearts, low-health jiggle, red vignette from the damage callback); fallback scene draw before other mods' POST_RENDER overlays. 0.5.84: Teleport beam effect (fps_teleport); weapon object read only with Ludovico; one enemy query per frame for the visible-hit sweep. 0.5.83: Health and weapon panels always sit above the native trinket/pocket slots. 0.5.82: Visible hits: bullets crossing the drawn sprite hit (ForceCollide beyond the native circle); panels clear the trinket/pocket slots; our minimap follows the native map size. 0.5.81: Lasers drawn with the REPENTOGON Beam renderer: continuous texture, per-end width capped near the camera, additive glow and core. 0.5.80: Lasers drawn with their entity colour; gun lasers take the player LaserColor. 0.5.79: Epic Fetus + Mom's Knife blast knife ring; Tech X + Brimstone ring; Lung + Chocolate Milk charge; Tech + Lung chained lasers. 0.5.78: 20/20 dual guns (one-handed forms); flare strikes at the landing point, native Epic targets dropped; Ludovico (tear, ring, knife, bomb) steerable against the Mouse Control pull; wiki item combinations for the gun. 0.5.77: Crash fix: Incubus/Twisted Pair damage share is no longer written onto the familiar userdata. 0.5.76: Console command fpsitems spawns the gun-compatibility test items. 0.5.75: One round per shot for every gun form; laser gun 6, launcher 4, shotgun 8 (fire-rate CD), rifle 30. 0.5.74: Shotgun uses the CC0 Quaternius Shotgun_1 model (fps_gun_assets). 0.5.73: Every gun attack leaves the drawn muzzle (hip and ADS); minimap doors; pixel hearts; two-handed M870. 0.5.72: Weapon forms (pistol, rifle, laser, beam, launcher, flare, M870) and an optional reflex sight. 0.5.71: Gun follows the native weapon type: Dr. Fetus bombs, Tech X rings, C Section, Lung/Cursed Eye charge, Neptunus burst, ammo costs, tears-paced fire, Ludovico steering. 0.5.70: Flying raises the eye to the flyers; no native charge bar with the gun out. 0.5.69: Native shots turn from the base they actually left along (aim, cursor, last aim or cardinal). 0.5.68: Released Brimstone beams follow the reticle; gun beams leave the muzzle at a fire-rate CD. 0.5.67: Door recess follows the frame art's measured opening (was the whole door box). 0.5.66: Crash fix: the 0.5.63 SetRail hook is disabled (it modified the Room class metatable). 0.5.65: Recessed doorways: frame on the wall, passage and leaves set back with solid reveals. 0.5.64: Merge of 0.5.63 (wall artwork: Install approved Library wall, Shop/Devil sides and authored Basement wall sets) and the rail hook: Lua Room:SetRail writes are recorded (fps_rail_hook) so high-index rails follow them. 0.5.62: Incubus (the item and Lilith's own) copies every gun trigger pull from its position; Tainted Lilith keeps native. 0.5.60: merge of 0.5.58 (gun fires native Brimstone/Technology beams; billboards reuse one sprite copy per entity) and 0.5.59 (chapter-two wall-local supports/lanterns and bounded initial high-index rails). 0.5.57: Native tears fired by Mouse Control follow the reticle. 0.5.56: garbage collection at the frame tail while FPS is on (fps_gc). 0.5.55: native screen shake on the 3D view and every overlay. 0.5.54: big-room garbage cut: cached doors, throttled obstacle checks, per-frame NPC bounds. 0.5.53: native room shadows hidden; darkness light at screen centre. 0.5.52: lighter logic-update callbacks and less per-frame garbage. 0.5.51: bolder bullet streaks. 0.5.50: bullet streaks, ray-free occlusion in open rooms, mass-entity fast path and side cull, native mass draws skipped, F8 frame phases.
-- Native damage is retained; camera projection does not resize game entities.
local mod = RegisterMod("Isaac FPS Probe", 1)
-- 0.5.111: without REPENTOGON (no Isaac.CenterCursor, which every FPS path
-- needs) only a centred bilingual install notice is registered and the rest
-- of the mod is not loaded (fps_need_repentogon uses vanilla API only).
if not REPENTOGON and type(Isaac.CenterCursor)~="function" then
    include("fps_need_repentogon").register(mod)
    return
end
-- 0.5.48-0.5.101 switched the collector to incremental here; 0.5.102 keeps
-- REPENTOGON's generational mode (see fps_gc: one young collection per frame
-- while FPS is on). The mode found at load is written to log.txt when F8
-- recording starts.
local gcInfo
do
    local ok,previous=pcall(collectgarbage,'generational')
    gcInfo='[FPS Profile] GC: mode at load '..tostring(ok and previous or 'unknown')
        ..', kept generational (FPS: one young collection per frame)'
end
local game = Game()
local maths = include("fps_math")
local shots = include("fps_shots")
local hud = include("fps_hud")
local world = include("fps_world")
local maps = include("fps_map")
local crawlspace = include("fps_crawlspace")
local crawlspaceView = include("fps_crawlspace_view")
local doors = include("fps_doors")
local attacks = include("fps_attacks")
local weapons = include("fps_weapons")
local items = include("fps_items")
local settings = include("fps_settings")
local melee = include("fps_melee")
local targets = include("fps_targets")
local effects = include("fps_effects")
local locale = include("fps_locale")
local diagnostics = include("fps_diagnostics")
local minimapView = include("fps_minimap")
local pickups = include("fps_pickups")
local health = include("fps_health")
local guns = include("fps_guns")
local teleport = include("fps_teleport")
-- 0.5.78: Epic Fetus blast lasers keep their own angles (fps_gun_synergy).
weapons.fixedLaser = function() return guns.synergy.fixedLaserHeight end
local facing = include("fps_facing")
local procedural = include("fps_procedural")
local mcm = include("fps_mcm")
local cursor = include("fps_cursor")
local gunCache = include("fps_gun_cache")
local materials = include("fps_materials")
local gc = include("fps_gc")
local aimCamera = include("fps_aim_camera")
local spriteCache = include("fps_sprite_cache")
local railHook = include("fps_rail_hook")
local ready = type(Isaac.CenterCursor) == "function"
local state = {
    enabled = false, yaw = -math.pi / 2, pitch = 0, sensitivity = 0.001,
    cooldown = 0, map = nil, warmup = 0, keys = {},
    message = "", error = nil, shotHistory = {}, noPlayerFrames = 0,
    errorCount = 0, roomFrame = nil, roomTransition = false,
    renderSerial = 0, rectDraws = 0, roomSceneSerial = nil, transitionSceneSerial = nil, controlsSerial = nil,
}
local cfg = {
    fov = 75, columns = 200, eye = 32, zoom=1, minimap = true, heldSideWithGun = -12,
    shotScale = 0.3, obstacleHeight = 28, shotBelowEye = 12,
    enemyShotBelowEye = 4, hitboxWiden = true,
    ceiling = 160, maxPitch = math.rad(89),
}
local updateProfile={}
local rectangle, shadowSprite
local preferences=settings.init(mod)
-- The native HUD stays visible in FPS (item names, EID, active/pocket UI,
-- giant-book overlays). Only its heart row is replaced via 1118 below. This
-- restore path remains for sessions that hid it before this version.
local originalHUDVisibility
local healthState={}
local function setHUDHidden(hidden)
    if not game.GetHUD then return end
    local native=game:GetHUD()
    if hidden then
        if originalHUDVisibility==nil then originalHUDVisibility=native:IsVisible() end
        native:SetVisible(false)
    elseif originalHUDVisibility~=nil then
        native:SetVisible(originalHUDVisibility)
        originalHUDVisibility=nil
    end
end
local function applySettings()
    cfg.eye,cfg.fov,cfg.zoom,state.sensitivity=preferences.eye,preferences.fov,preferences.zoom,preferences.sensitivity
    locale.setLanguage(preferences.language)
    -- Rendering mode (Mod Config Menu): unified GPU scene (default) or legacy CPU.
    world.gpu=preferences.gpu~=false
end

-- 0.5.70: a flying player sees from the flyers' height (they float at
-- obstacleHeight+2 above the floor); the view eases there and back.
local FLY_EYE_ABOVE=10
-- 0.5.84: a teleport lifts the eye while it beams up and lowers it on arrival.
local function eyeHeight() return (state.eye or cfg.eye)+teleport.eyeOffset() end
local function updateEye(p,now)
    local target=cfg.eye
    if p and p.CanFly then target=math.max(cfg.eye,cfg.obstacleHeight+2+FLY_EYE_ABOVE) end
    local eye=state.eye or cfg.eye
    local dt=state.eyeTime and math.max(0,math.min(100,now-state.eyeTime)) or 0
    state.eyeTime=now
    if math.abs(target-eye)<.05 then eye=target
    else eye=eye+(target-eye)*math.min(1,dt/150) end
    state.eye=eye
end
applySettings()
-- Settings are edited in Mod Config Menu; apply each change immediately.
settings.onChange(applySettings)
mcm.register(settings,locale)
local function resetMouse()
    -- First Person v2.3: arm with a centred sample, then read displacement.
    state.warmup=1
    state.mouseDown,state.mouseFrame=false,nil
    if ready then Isaac.CenterCursor() end
end

local function rememberShot(entity,frame)
    if not state.enabled then return end
    local z = -entity.Height
    if not entity:GetData().IsaacFPSProbe3D then
        -- Enemy bullets keep the native arc; only their baseline sits a fixed
        -- distance below the player eye. Player tears are unchanged.
        if entity.Type==EntityType.ENTITY_PROJECTILE then
            z=shots.enemyShotBaseline(z,eyeHeight(),cfg.enemyShotBelowEye)
        else z=math.max(0,z-cfg.shotBelowEye) end
    end
    -- Reuse the record: this runs for every tear twice per logic update.
    local pos=entity.Position
    local record=state.shotHistory[entity.InitSeed]
    if not record then record={};state.shotHistory[entity.InitSeed]=record end
    record.x,record.y,record.z,record.type,record.frame=pos.X,pos.Y,z,entity.Type,frame or game:GetFrameCount()
end

local impactTypes = {[11]=9,[12]=2,[13]=2,[79]=2,[80]=2,[102]=9}

local function key(code)
    return Input.IsButtonPressed(code, 0)
end

local function edge(code)
    local down = key(code)
    local triggered = down and not state.keys[code]
    state.keys[code] = down
    return triggered
end

local function player()
    if ready and not Isaac.IsInGame() then return nil end
    if game:GetNumPlayers() == 0 then return nil end
    return Isaac.GetPlayer(0)
end

-- Ordinary crawlspaces use the native side-view gravity plane. Their display
-- has a separate XYZ transform; native movement/item rules keep ownership.
local function inCrawlspace()
    if state.crawlspace==nil then state.crawlspace=crawlspace.isRoom(game:GetRoom()) end
    return state.crawlspace
end
local function resetCrawlspace(p)
    state.crawlspace=crawlspace.isRoom(game:GetRoom())
    crawlspaceView.reset()
    if state.enabled and state.crawlspace then
        state.yaw,state.pitch=0,0
        weapons.releaseHeldKnives()
        guns.release()
        aimCamera.release(p)
    end
end
local function active()
    local p = player()
    return state.enabled and not game:IsPaused() and p
        and not p:IsDead() and p.ControlsEnabled and not inCrawlspace()
end

local function viewActive()
    local p=player()
    return state.enabled and p and not p:IsDead() and not game:IsPaused()
end

local function transitionActive()
    -- NEW_ROOM may run before the engine finishes compositing the incoming
    -- room. The engine mode is authoritative; lifecycle flags only support
    -- older runtimes without the RoomTransition API.
    if RoomTransition and type(RoomTransition.GetTransitionMode)=='function' then
        return RoomTransition.GetTransitionMode()>0
    end
    return state.roomTransition
end

local function pauseMenuOpen()
    -- IsPaused also covers native room transitions. Only the actual Esc menu
    -- owns the pause overlay; it has its own REPENTOGON query. The fallback
    -- supports older runtimes but cannot identify a menu during a transition.
    if game.IsPauseMenuOpen then return game:IsPauseMenuOpen() end
    return game:IsPaused() and not transitionActive()
end

-- REPENTOGON ItemOverlay: a giant-book (card/pill/active close-up) is playing.
-- Without that API, non-menu pauses keep the previous native-only behaviour.
local function overlayActive()
    if not ItemOverlay or type(ItemOverlay.GetSprite)~='function' then return false end
    local ok,sprite=pcall(ItemOverlay.GetSprite)
    if not ok or not sprite then return false end
    local animation=sprite:GetAnimation()
    if not animation or animation=='' then return false end
    return not sprite:IsFinished(animation)
end

local function bossIntroActive()
    return RoomTransition and type(RoomTransition.IsRenderingBossIntro)=='function'
        and RoomTransition.IsRenderingBossIntro()
end

-- 0.5.53: the native room shadow layer (FXParams.ShadowAlpha) is drawn
-- after MC_POST_ROOM_RENDER_ENTITIES, i.e. over the FPS scene, as top-down
-- dark patches. While the scene covers the view it is set to 0; the room's
-- own value is restored when FPS ends (each room loads its own FXParams).
local shadowRoom,shadowAlpha
local function roomFX()
    local room=game:GetRoom()
    if not room or type(room.GetFXParams)~='function' then return nil end
    local ok,fx=pcall(room.GetFXParams,room)
    return ok and fx or nil
end
local function roomKey()
    local level=game.GetLevel and game:GetLevel()
    return level and level.GetCurrentRoomIndex and level:GetCurrentRoomIndex() or 0
end
local function hideRoomShadows()
    local fx=roomFX()
    if not fx or fx.ShadowAlpha==nil then return end
    local key=roomKey()
    if shadowRoom~=key then shadowRoom,shadowAlpha=key,nil end
    if fx.ShadowAlpha~=0 then
        if shadowAlpha==nil then shadowAlpha=fx.ShadowAlpha end
        fx.ShadowAlpha=0
    end
end
local function restoreRoomShadows()
    if shadowAlpha==nil then return end
    local fx=roomFX()
    if fx and shadowRoom==roomKey() then fx.ShadowAlpha=shadowAlpha end
    shadowRoom,shadowAlpha=nil,nil
end

-- 0.5.97 (user): "Press F6" shows prominently at the start of a run and
-- disappears once FPS is on, or by itself after START_HINT_MS; messages
-- (mouse released, resume) fade after HINT_MESSAGE_MS. Both sit centred in
-- the lower middle, clear of the native HUD corners.
local START_HINT_MS,HINT_MESSAGE_MS,HINT_FADE_MS=10000,5000,1000
local function hintAlpha(untilTime,now)
    if not untilTime then return 0 end
    local left=untilTime-now
    if left<=0 then return 0 end
    return math.min(1,left/HINT_FADE_MS)
end
local function release(message)
    -- 0.5.110: the native camera follows the player again.
    aimCamera.release(Isaac.GetPlayer and Isaac.GetPlayer(0) or nil)
    restoreRoomShadows()
    diagnostics.suspend('release')
    setHUDHidden(false)
    weapons.releaseHeldKnives()
    guns.release()
    procedural.reset()
    crawlspaceView.reset()
    state.crawlspace=nil
    hud.resetCharge()
    settings.resetMenu()
    state.enabled, state.warmup = false, 0
    state.noPlayerFrames = 0
    state.roomTransition = false
    state.mouseDown,state.mouseFrame=false,nil
    state.message = message or ""
    state.messageUntil = message and Isaac.GetTime()+HINT_MESSAGE_MS or nil
end

-- Temporary v5 diagnostics: a C stack overflow loses the Lua call stack, so
-- every guarded callback pushes a (frame, name) pair into a ring buffer; an
-- error dumps the tail of that ring plus the engine context. The entry that
-- follows an overflow names the crashing callback. Removed with the probe.
local TRACE_MAX = 160
-- Raw values only: callbacks such as MC_INPUT_ACTION run dozens of times a
-- frame, so no string is built here. traceLines() formats on error dumps.
local traceFrame, traceName, traceA, traceB, traceC = {}, {}, {}, {}, {}
local traceHead, traceCount = 1, 0
-- Frame number cached once per update/render (0.5.50): tracePush runs for
-- every guarded callback, hundreds of times per frame.
local traceFrameNow = 0
local function tracePush(name, a, b, c)
    local i
    if traceCount < TRACE_MAX then
        traceCount = traceCount + 1
        i = traceCount
    else
        i = traceHead
        traceHead = traceHead % TRACE_MAX + 1
    end
    traceFrame[i], traceName[i] = traceFrameNow, name
    traceA[i], traceB[i], traceC[i] = a, b, c
end
local function traceLines()
    local lines = {}
    for n = 1, traceCount do
        local i = (traceHead + n - 2) % traceCount + 1
        local text = tostring(traceFrame[i]) .. ':' .. tostring(traceName[i])
        for _, value in ipairs({traceA[i], traceB[i], traceC[i]}) do text = text .. ' ' .. tostring(value) end
        lines[n] = text
    end
    return lines
end
local function debugString(message)
    if Isaac and Isaac.DebugString then Isaac.DebugString(message) end
end
local function context()
    local level, room = game:GetLevel(), game:GetRoom()
    local roomAge = state.roomFrame and (game:GetFrameCount() - state.roomFrame) or -1
    return string.format('frame=%s inGame=%s players=%s paused=%s roomType=%s stageType=%s roomAge=%s enabled=%s errors=%s',
        tostring(game:GetFrameCount()), tostring(Isaac.IsInGame()),
        tostring(game:GetNumPlayers()), tostring(game:IsPaused()),
        room and room.GetType and tostring(room:GetType()) or 'nil',
        level and tostring(level:GetStageType()) or 'nil',
        tostring(roomAge), tostring(state.enabled), tostring(state.errorCount or 0))
end
-- One shared xpcall handler: a closure per callback call was pure garbage.
local function errorHandler(message)
    message = tostring(message)
    -- A traceback separates a mod fault from an engine-level cascade
    -- (e.g. an unguarded callback restarting the room in a loop).
    -- Isaac's Lua sandbox does not expose the debug library.
    if debug and debug.traceback then
        local traced, trace = pcall(debug.traceback, message, 2)
        if traced and type(trace) == 'string' then
            return (trace:gsub('[\r\n]+', ' | '))
        end
    end
    return message
end
-- F8: time spent in our non-scene callbacks between two scene samples.
local sceneCallbacks = {RENDER_SCENE=true, ROOM_RENDER_LIFECYCLE=true, PAUSE_SCENE=true, RENDER_INPUT=true}
local callbackMs = 0
-- F8 detail: time and call count per callback name since the last scene.
local callbackByName, callbackCalls, callbackKb = {}, {}, {}
local function guard(fn, name)
    name = name or 'anon'
    local timed = not sceneCallbacks[name]
    return function(...)
        tracePush(name)
        local started = timed and diagnostics.enabled and diagnostics.clock()
        local heapBefore = started and diagnostics.detail and diagnostics.heap()
        local ok, result = xpcall(fn, errorHandler, ...)
        if started then
            local heapAfter = heapBefore and diagnostics.heap()
            if heapAfter then
                callbackKb[name] = (callbackKb[name] or 0) + math.max(0, heapAfter - heapBefore)
            end
            local spent = diagnostics.clock() - started
            callbackMs = callbackMs + spent
            callbackByName[name] = (callbackByName[name] or 0) + spent
            callbackCalls[name] = (callbackCalls[name] or 0) + 1
        end
        if not ok then
            release(locale.text("error_log"))
            state.error = tostring(result)
            state.errorCount = (state.errorCount or 0) + 1
            debugString('[Isaac FPS Probe] ' .. name .. ': ' .. state.error)
            local dumped, dumpError = pcall(function()
                local lines = traceLines()
                for i = 1, #lines, 8 do
                    local chunk = {}
                    for j = i, math.min(i + 7, #lines) do chunk[#chunk + 1] = lines[j] end
                    debugString('[FPS Probe trace] ' .. table.concat(chunk, ' '))
                end
                debugString('[FPS Probe ctx] ' .. context())
            end)
            if not dumped then
                debugString('[FPS Probe ctx] dump failed: ' .. tostring(dumpError))
            end
        else
            return result
        end
    end
end

effects.register(mod,guard,game,cfg.obstacleHeight)

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, guard(function(_, effect)
    local traceSource = effect.SpawnerEntity or effect.Parent
    tracePush('effect', effect.Variant, traceSource and traceSource.Type or -1)
    if not state.enabled then return end
    local kind=impactTypes[effect.Variant]
    if not kind then return end
    local source=effect.SpawnerEntity or effect.Parent
    if source and source.Type==kind then
        local shot=source:ToTear() or source:ToProjectile()
        if shot then
            local z=-shot.Height
            if not shot:GetData().IsaacFPSProbe3D then
                if shot.Type==EntityType.ENTITY_PROJECTILE then
                    z=shots.enemyShotBaseline(z,eyeHeight(),cfg.enemyShotBelowEye)
                else z=math.max(0,z-cfg.shotBelowEye) end
            end
            effect:GetData().IsaacFPSProbeImpact={z=z}
            return
        end
    end
    -- Native poofs often have no surviving projectile parent. Match a recent
    -- numeric snapshot rather than retaining an entity that the engine removed.
    local best, bestDistance=nil, 20*20
    local pos,frame=effect.Position,game:GetFrameCount()
    local ex,ey=pos.X,pos.Y
    for _,shot in pairs(state.shotHistory) do
        if shot.type==kind and frame-shot.frame<=1 then
            local dx,dy=ex-shot.x,ey-shot.y
            local d=dx*dx+dy*dy
            if d<bestDistance then best,bestDistance=shot,d end
        end
    end
    if best then effect:GetData().IsaacFPSProbeImpact={z=best.z} end
end, 'EFFECT_INIT'))

mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, guard(function(_, projectile)
    tracePush('proj')
    local frame=traceFrameNow
    rememberShot(projectile,frame)
    shots.remember(projectile,frame)
end, 'PROJECTILE_UPDATE'))

-- 0.5.52: the 2D helpers (HUD panels, warnings, minimap, strokes) reuse one
-- scratch Scale, position and Color: the engine copies them on assignment,
-- and a fresh Vector/Color pair per call was hundreds of finalizable
-- userdata per frame.
local drawScale,drawPos,drawColor
local function scratch()
    drawScale,drawPos,drawColor=Vector(1,1),Vector(0,0),Color(1,1,1,1,0,0,0)
end
-- 0.5.55 screen shake: 2D overlays drawn after the 3D scene are moved by
-- the native shake offset (set only while those overlays are drawn).
local uiX,uiY=0,0
local function paint(sx,sy,rotation,r,g,b,a,x,y)
    if not drawScale then scratch() end
    drawScale.X,drawScale.Y=sx,sy
    rectangle.Rotation=rotation
    rectangle.Scale=drawScale
    local c=drawColor
    c.R,c.G,c.B,c.A,c.RO,c.GO,c.BO=r,g,b,a,0,0,0
    rectangle.Color=c
    drawPos.X,drawPos.Y=x+uiX,y+uiY
    rectangle:Render(drawPos)
end
local function rect(x, y, w, h, r, g, b, a)
    if w <= 0 or h <= 0 then return end
    state.rectDraws=state.rectDraws+1
    paint(w,h,0,r,g,b,a or 1,x,y)
end

local function clippedRect(x, y, w, h, sw, sh, r, g, b)
    local x2, y2 = math.min(sw, x + w), math.min(sh, y + h)
    x, y = math.max(0, x), math.max(0, y)
    rect(x, y, x2 - x, y2 - y, r, g, b)
end

-- A room or floor load briefly invalidates the player reference. Painting a
-- full-screen backdrop in that window keeps the native view from showing
-- through; FPS state, input and the map rebuild are untouched.
local function paintBackdrop(sw, sh)
    if not rectangle then
        rectangle = Sprite()
        rectangle:Load("gfx/fps_probe/white.anm2", true)
        rectangle:Play("Idle", true)
    end
    rect(0, 0, sw, sh, 0, 0, 0)
end

local function drawStartHint(sw,sh)
    local now=Isaac.GetTime()
    local text,scale
    local alpha=hintAlpha(state.startHintUntil,now)
    if alpha>0 then text,scale=locale.text('fps_start'),2
    elseif state.message~='' then
        alpha=hintAlpha(state.messageUntil,now)
        if alpha>0 then text,scale=state.message,1 end
    end
    if not text then return end
    if not rectangle then
        rectangle = Sprite()
        rectangle:Load("gfx/fps_probe/white.anm2", true)
        rectangle:Play("Idle", true)
    end
    local w=locale.width(text)*scale
    local h=(locale.isChinese() and 12 or 10)*scale
    local x,y=math.floor((sw-w)/2),math.floor(sh*.68)
    rect(x-6,y-3,w+12,h+6,.03,.02,.03,.6*alpha)
    locale.drawScaled(text,x,y,scale,1,.9,.6,alpha)
end

local targetBounds
-- Temporary stage probes: a C stack overflow loses the Lua call stack, so each
-- render stage is pushed into the trace ring and dumped only when an error
-- fires. The missing entry after an overflow names the crashing stage; removed
-- once the root cause is fixed.
local function stage(name)
    tracePush(name)
end
local lineWidth=1.5
local function line(x1,y1,x2,y2,r,g,b,a)
    local dx,dy=x2-x1,y2-y1
    state.rectDraws=state.rectDraws+1
    paint(math.sqrt(dx*dx+dy*dy),lineWidth,math.deg(math.atan(dy,dx)),r,g,b,a,x1,y1)
    rectangle.Rotation=0
end

-- Centred stroke of any width (procedural lightning).
local function stroke(x1,y1,x2,y2,width,r,g,b,a)
    local dx,dy=x2-x1,y2-y1
    local length=math.sqrt(dx*dx+dy*dy)
    if length==0 then return end
    local ox,oy=dy*width/(2*length),-dx*width/(2*length)
    state.rectDraws=state.rectDraws+1
    paint(length,width,math.deg(math.atan(dy,dx)),r,g,b,a,x1+ox,y1+oy)
    rectangle.Rotation=0
end

local function minimapLine(x1,y1,x2,y2,r,g,b,a)
    local dx,dy=x2-x1,y2-y1
    local length=math.sqrt(dx*dx+dy*dy)
    if length==0 then return end
    -- white.anm2 has a zero pivot: move the stroke origin by half its width
    -- so its visible centerline, rather than one edge, follows the sector.
    local offset=lineWidth/(2*length)
    local ox,oy=dy*offset,-dx*offset
    line(x1+ox,y1+oy,x2+ox,y2+oy,r,g,b,a)
end

-- 0.5.89: the off-screen enemy arrow is written into one reused table.
local arrowScratch={}
local function warnings(p,sw,sh,focal,roomEntities)
    local camera={x=p.Position.X,y=p.Position.Y,eye=eyeHeight(),yaw=state.yaw,pitch=state.pitch,
        focal=focal,width=sw,height=sh,frame=game:GetFrameCount()}
    local function ring(x,y,radius)
        local dx,dy=x-p.Position.X,y-p.Position.Y
        local danger=dx*dx+dy*dy<(radius+p.Size)^2
        local green=danger and .12 or .55
        local alpha=.45+.18*math.sin(game:GetFrameCount()*.15)
        for _,v in ipairs(hud.ring(x,y,radius,camera)) do
            line(v.x1,v.y1,v.x2,v.y2,1,green,.08,alpha)
        end
    end
    for _,e in ipairs(roomEntities) do
        local radius=hud.explosionRadius(e)
        if radius then ring(e.Position.X,e.Position.Y,radius) end
        -- Only NPC types can be active enemies (skips hundreds of bullets).
        local t=e.Type
        if t>=10 and t<1000 and e:IsActiveEnemy(false) and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
            local bounds=targetBounds(e)
            local arrow=hud.enemyArrow(e.Position.X,e.Position.Y,(bounds.bottom+bounds.top)/2,camera,arrowScratch)
            if arrow then
                local ax,ay=math.cos(arrow.angle),math.sin(arrow.angle)
                local green=radius and .55 or .12
                for sign=-1,1,2 do
                    line(arrow.x,arrow.y,arrow.x-ax*9-ay*sign*5,
                        arrow.y-ay*9+ax*sign*5,1,green,.12,.9)
                end
            end
        end
    end
    for _,v in ipairs(state.map.explosives or {}) do ring(v.x,v.y,75) end
end

local function buildMap()
    hud.resetCharge()
    local room=game:GetRoom()
    state.map=maps.new(room,cfg.obstacleHeight,cfg.ceiling,nil,railHook)
    local stageType=game.GetLevel and game:GetLevel():GetStageType() or 'unknown'
    Isaac.DebugString(string.format('[Isaac FPS Probe Material] backdrop=%s roomType=%s stageType=%s',
        room:GetBackdropType(),room.GetType and room:GetType() or 'unknown',stageType))
end

local function mouseLook(sw, sh)
    if key(Keyboard.KEY_LEFT_ALT) or key(Keyboard.KEY_RIGHT_ALT)
        or key(Keyboard.KEY_GRAVE_ACCENT) then
        release(locale.text("mouse_released"))
        return
    end
    -- Discard cursor-warp/loading samples; a moving sample is never calibration.
    if state.warmup > 0 then
        state.warmup = state.warmup - 1
        Isaac.CenterCursor()
        return
    end
    -- Ported from firstperson_fps_local/fps_controls.lua (v2.3).
    -- Transform two window positions in the SAME camera snapshot: subtracting
    -- the origin cancels scrolling/shake, keeping the window-to-render scale.
    -- A cached world mouse position can otherwise turn camera motion into input.
    local raw=Input.GetMousePosition(false)
    local position=Isaac.WorldToScreen(Isaac.ScreenToWorld(raw))
    local origin=Isaac.WorldToScreen(Isaac.ScreenToWorld(Vector(0,0)))
    local dx=position.X-origin.X-Isaac.GetScreenWidth()/2
    local dy=position.Y-origin.Y-Isaac.GetScreenHeight()/2
    -- Same rounding tolerance as First Person; retain small deliberate motions.
    if math.abs(dx)<=0.15 then dx=0 end
    if math.abs(dy)<=0.15 then dy=0 end
    -- Large deltas can be fast mouse movement, not evidence of lost focus.
    -- Aiming down sights lowers the effective sensitivity; saved settings stay.
    -- 0.5.116 diagnostic (user: steady turning sometimes jumps): a delta
    -- well above the recent average is logged with how far the native
    -- camera moved on screen since the last frame tail (camRef) and whether
    -- a logic update ran in between.
    local magnitude=math.abs(dx)+math.abs(dy)
    local average=state.lookAverage or magnitude
    if magnitude>12 and magnitude>2.5*average and (state.lookSpikes or 0)<30 and state.camRef then
        state.lookSpikes=(state.lookSpikes or 0)+1
        -- 0.5.117: %.1f (screen deltas are fractional; %d raised and turned
        -- FPS off), and a diagnostic can never stop the look.
        pcall(function()
            local now=Isaac.WorldToScreen(Vector(0,0))
            Isaac.DebugString(string.format('[Isaac FPS Probe] look spike: d=(%.1f,%.1f) avg=%.1f cameraShift=(%.1f,%.1f) logicFrame=%s',
                dx,dy,average,now.X-state.camRef.X,now.Y-state.camRef.Y,tostring(game:GetFrameCount()~=state.camRefFrame)))
        end)
    end
    state.lookAverage=average*.8+magnitude*.2
    local sensitivity=state.sensitivity*guns.sensitivity()
    state.yaw = (state.yaw + dx * sensitivity) % (2 * math.pi)
    state.pitch = maths.clamp(state.pitch - dy * sensitivity, -cfg.maxPitch, cfg.maxPitch)
    Isaac.CenterCursor()
end

local function movement()
    local forward = (key(Keyboard.KEY_W) and 1 or 0) - (key(Keyboard.KEY_S) and 1 or 0)
    local strafe = (key(Keyboard.KEY_D) and 1 or 0) - (key(Keyboard.KEY_A) and 1 or 0)
    return maths.movement(state.yaw, forward, strafe)
end

-- Translate WASD into movement relative to our camera.
mod:AddPriorityCallback(ModCallbacks.MC_INPUT_ACTION, -100, guard(function(_, entity, hook, action)
    tracePush('input', action, entity and entity.Type or -1)
    -- A gun owns primary fire and right mouse while it is selected.
    if active() then
        local blocked=guns.blockInput(action,hook)
        if blocked~=nil then return blocked end
    end
    if not active() or not entity or entity.Type ~= EntityType.ENTITY_PLAYER
        or GetPtrHash(entity) ~= GetPtrHash(player()) then return end
    local value
    if action == ButtonAction.ACTION_LEFT or action == ButtonAction.ACTION_RIGHT
        or action == ButtonAction.ACTION_UP or action == ButtonAction.ACTION_DOWN then
        local x, y = movement()
        if action == ButtonAction.ACTION_LEFT then value = math.max(0, -x)
        elseif action == ButtonAction.ACTION_RIGHT then value = math.max(0, x)
        elseif action == ButtonAction.ACTION_UP then value = math.max(0, -y)
        else value = math.max(0, y) end
    elseif action == ButtonAction.ACTION_SHOOTLEFT or action == ButtonAction.ACTION_SHOOTRIGHT
        or action == ButtonAction.ACTION_SHOOTUP or action == ButtonAction.ACTION_SHOOTDOWN then
        local frame=game:GetFrameCount()
        local firing=Input.IsMouseBtnPressed(0)
        if state.mouseFrame~=frame then
            state.mouseTriggered=firing and not state.mouseDown
            state.mouseDown,state.mouseFrame=firing,frame
        end
        -- 0.5.110: with the native camera pointed along the view, Mouse
        -- Control fires every native attack exactly there; no cardinal shoot
        -- action is pressed on top of it (two aims fought before).
        if aimCamera.active then return nil end
        return weapons.input(action,hook,state.yaw,firing,state.mouseTriggered)
    else return end
    if hook == InputHook.GET_ACTION_VALUE then return value end
    return value > 0.001
end, 'INPUT_ACTION'))


targetBounds=function(entity)
    return targets.bounds(entity,game:GetFrameCount(),cfg.obstacleHeight)
end

local function weaponCamera()
    local p=player()
    return {yaw=state.yaw,pitch=state.pitch,eye=eyeHeight(),bodyOffset=cfg.shotBelowEye,
        enemyShotBelowEye=cfg.enemyShotBelowEye,
        ceiling=cfg.ceiling,now=Isaac.GetTime(),frame=game:GetFrameCount(),
        x=p and p.Position.X or 0,y=p and p.Position.Y or 0,obstacleHeight=cfg.obstacleHeight,
        -- 0.5.73: the drawn gun muzzle as view-ray slopes (gun beams).
        muzzleAim=function(side) return guns.muzzleAim(cfg.fov,cfg.zoom,side) end}
end
if ready then
    weapons.register(mod,{player=player,active=active,guard=guard,camera=weaponCamera,
        targetBounds=targetBounds,room=function() return game:GetRoom() end,trace=tracePush})
    guns.register(mod,{player=player,guard=guard,text=locale.text,
        enabled=function() return state.enabled and not inCrawlspace() end,
        reloadKey=settings.reloadKey,reloadLabel=function() return settings.keyLabel() end,
        reflexSight=function() return settings.get('reflexSight')~=false end})
    -- 0.5.52: no MC_PRE_TEAR_UPDATE. It re-recorded the position the previous
    -- post-update had already stored (nothing moves a tear between updates);
    -- postTear carries its own start position forward, and impact matching
    -- accepts the previous update's record (frame difference <= 1). One
    -- guarded dispatch less per tear per update.
    -- Keeps a steered Ludovico tear inside the room's walkable area.
    local function ludovicoClamp(x,y)
        local ok,pos=pcall(function() return game:GetRoom():GetClampedPosition(Vector(x,y),10) end)
        if ok and pos then return pos.X,pos.Y end
        return x,y
    end
    -- 0.5.82 (user: whatever is visible can be hit): the engine only reports
    -- a contact inside the body's native circle, so a bullet crossing the
    -- visible sprite beyond it never hit. After each tear update its movement
    -- is swept against the drawn billboards of nearby bodies; a crossing that
    -- the native circle misses is handed to the engine with ForceCollide, so
    -- damage, tear flags and on-hit effects stay native. Once per tear and
    -- body (piercing tears pass through each body once).
    local SWEEP_REACH=160
    local SWEEP_WORLD=4000
    local sweepEnemies={frame=-1,list={}}
    local sweeping=nil
    local function canBeHit(entity)
        if type(entity.Exists)=='function' and not entity:Exists() then return false end
        if type(entity.IsDead)=='function' and entity:IsDead() then return false end
        if EntityFlag and type(entity.HasEntityFlags)=='function' and entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then return false end
        local class=entity.EntityCollisionClass
        if EntityCollisionClass and class~=nil and class~=EntityCollisionClass.ENTCOLL_ALL
            and class~=EntityCollisionClass.ENTCOLL_PLAYEROBJECTS then return false end
        return type(entity.ForceCollide)=='function'
    end
    local function sweepVisibleHits(tear)
        local data=tear:GetData()
        if not data.IsaacFPSProbe3D then return end
        local frame=game:GetFrameCount()
        local x1,y1=tear.Position.X,tear.Position.Y
        local prev=data.IsaacFPSSweepPrev
        local x0,y0
        local v=tear.Velocity
        if prev and prev.frame==frame-1 then x0,y0=prev.x,prev.y
        elseif v then x0,y0=x1-v.X,y1-v.Y
        else x0,y0=x1,y1 end
        if prev then prev.x,prev.y,prev.frame=x1,y1,frame
        else data.IsaacFPSSweepPrev={x=x1,y=y1,frame=frame} end
        if not cfg.hitboxWiden or weapons.isLudovico(tear) then return end
        local p=player()
        if not p or not (Isaac.FindInRadius and EntityPartition) then return end
        local reach=SWEEP_REACH+math.sqrt((x1-x0)^2+(y1-y0)^2)
        local hits=data.IsaacFPSSweepHits
        -- 0.5.84: one enemy query per logic frame shared by every tear (was
        -- one engine query, and its result table, per tear per update).
        if sweepEnemies.frame~=frame then
            sweepEnemies.frame=frame
            sweepEnemies.list=Isaac.FindInRadius(p.Position,SWEEP_WORLD,EntityPartition.ENEMY) or {}
        end
        for _,entity in ipairs(sweepEnemies.list) do
            local ex,ey=entity.Position.X-x1,entity.Position.Y-y1
            local key=ex*ex+ey*ey<=reach*reach and GetPtrHash(entity)
            if key and not (hits and hits[key]) and canBeHit(entity)
                and not targets.insideNativeRadius(entity,tear)
                and targets.visibleHit(entity,p.Position.X,p.Position.Y,x0,y0,x1,y1,-tear.Height,
                    tear.Size or 0,frame,cfg.obstacleHeight) then
                if not hits then hits={};data.IsaacFPSSweepHits=hits end
                hits[key]=true
                tracePush('coll:sweep')
                sweeping=key
                local ok,err=pcall(entity.ForceCollide,entity,tear,false)
                sweeping=nil
                if not ok then error(err) end
                if type(tear.Exists)=='function' and not tear:Exists() then return end
                if type(tear.IsDead)=='function' and tear:IsDead() then return end
            end
        end
    end
    local diagnosticsUnconverted=0
    mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, guard(function(_, tear)
        if state.enabled and inCrawlspace() then return end
        tracePush('tear post')
        rememberShot(tear)
        -- One camera table per logic frame for all tears (postTear reads only
        -- its timestamp); building it per tear was hundreds of tables/frame.
        local frame=game:GetFrameCount()
        if not state.tearCamera or state.tearCameraFrame~=frame then
            state.tearCamera,state.tearCameraFrame=weaponCamera(),frame
        end
        weapons.postTear(tear,state.tearCamera)
        -- 0.5.104 diagnostic (user: some tears still ignore the reticle, e.g.
        -- when facing away from the room centre): a tear in its first frames
        -- that was never converted to the view (no IsaacFPSProbe3D) flies the
        -- native way, toward the centred cursor, i.e. the room centre. Log
        -- its source when it heads more than 30 degrees off the view.
        -- 0.5.112: from frame 1 on (POST_TEAR_UPDATE can run before
        -- POST_FIRE_TEAR at frame 0, which logged tears converted right after).
        if active() and (tear.FrameCount or 0)>=1 and (tear.FrameCount or 0)<=2 and diagnosticsUnconverted<16 then
            local data=tear:GetData()
            local v=tear.Velocity
            if not data.IsaacFPSProbe3D and not data.IsaacFPSUnconvertedSeen and v and v.X*v.X+v.Y*v.Y>.01 then
                data.IsaacFPSUnconvertedSeen=true
                local angle=math.atan(v.Y,v.X)
                local off=math.abs((angle-state.yaw+math.pi)%(2*math.pi)-math.pi)
                if off>math.rad(30) then
                    diagnosticsUnconverted=diagnosticsUnconverted+1
                    local spawner=tear.SpawnerEntity
                    local parent=tear.Parent
                    Isaac.DebugString(string.format('[Isaac FPS Probe] unconverted tear: variant=%s velocity=%.1f yaw=%.1f off=%.1f spawner=%s parent=%s frame=%s',
                        tostring(tear.Variant),math.deg(angle),math.deg(state.yaw),math.deg(off),
                        spawner and (tostring(spawner.Type)..'.'..tostring(spawner.Variant)..'.'..tostring(spawner.SubType)) or '-',
                        parent and (tostring(parent.Type)..'.'..tostring(parent.Variant)) or '-',tostring(tear.FrameCount)))
                end
            end
        end
        -- 0.5.71: hold the left button to fly the Ludovico tear at the reticle.
        if active() and weapons.isLudovico(tear) then
            local enemies=Isaac.FindInRadius and EntityPartition
                and Isaac.FindInRadius(tear.Position,1000,EntityPartition.ENEMY) or nil
            weapons.steerLudovico(tear,player(),state.tearCamera,Input.IsMouseBtnPressed(0),enemies,ludovicoClamp)
        end
        -- A sweep failure is logged once and skipped, never stopping the mod.
        if active() then
            local ok,err=pcall(sweepVisibleHits,tear)
            if not ok and not state.sweepErrorLogged then
                state.sweepErrorLogged=true
                Isaac.DebugString('[Isaac FPS Probe] visible hit sweep error: '..tostring(err))
            end
        end
    end, 'POST_TEAR_UPDATE'))

    -- 0.5.78: a Ludovico laser ring, knife or bomb (the weapon's main entity
    -- with Brimstone, Technology, Mom's Knife or Dr. Fetus) is steered the
    -- same way after its own update.
    local function steerLudovicoMain(entity)
        if not active() then return end
        local p=player()
        if not p or type(p.GetWeapon)~='function' then return end
        local ok,weapon=pcall(p.GetWeapon,p,1)
        if not ok or not weapon or type(weapon.GetMainEntity)~='function' then return end
        local okMain,main=pcall(weapon.GetMainEntity,weapon)
        if not okMain or not main or GetPtrHash(main)~=GetPtrHash(entity) then return end
        if guns.synergy.mode(p)~='ludovico' then return end
        local frame=game:GetFrameCount()
        if not state.tearCamera or state.tearCameraFrame~=frame then
            state.tearCamera,state.tearCameraFrame=weaponCamera(),frame
        end
        local enemies=Isaac.FindInRadius and EntityPartition
            and Isaac.FindInRadius(entity.Position,1000,EntityPartition.ENEMY) or nil
        weapons.steerLudovico(entity,p,state.tearCamera,Input.IsMouseBtnPressed(0),enemies,ludovicoClamp,true)
    end
    for _,id in ipairs({ModCallbacks.MC_POST_LASER_UPDATE,ModCallbacks.MC_POST_KNIFE_UPDATE,ModCallbacks.MC_POST_BOMB_UPDATE}) do
        if id then mod:AddCallback(id,guard(function(_,entity) steerLudovicoMain(entity) end,'LUDOVICO_MAIN')) end
    end

    -- A visible sprite can exceed the native planar circle. Force one
    -- collide per tear per collider per frame instead of widening the
    -- native check by hand; tears inside the native radius keep the
    -- vanilla chain untouched.
    local function forcedCollisionState(tear,collider,frame)
        local data=tear:GetData()
        local forced=data.IsaacFPSProbeForcedCollide
        if not forced then forced={};data.IsaacFPSProbeForcedCollide=forced end
        -- Key on the stable pointer hash, never the wrapper table: every
        -- callback dispatch pushes a fresh userdata for the same entity, so
        -- the re-entry that ForceCollide itself triggers would miss a
        -- wrapper-keyed mark and cycle until the C stack overflows.
        local key=GetPtrHash and GetPtrHash(collider) or collider
        local collision=forced[key]
        if not collision or collision.frame~=frame then
            collision={frame=frame}
            forced[key]=collision
        end
        return collision
    end
    -- Gun bullet hit sound at the contact itself (see guns.onTearContact).
    local function gunContact(tear,collider)
        local p=state.enabled and player()
        if p then guns.onTearContact(tear,collider,p.InitSeed) end
    end
    mod:AddPriorityCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, -100, guard(function(_, tear, collider)
        if state.enabled and inCrawlspace() then return end
        tracePush('tear coll', tear.Variant, collider and collider.Type or -1, collider and collider.Variant or -1)
        rememberShot(tear)
        if not tear:GetData().IsaacFPSProbe3D then gunContact(tear,collider);return end
        -- A contact the visible sweep handed over: the engine takes it as is.
        if sweeping and collider and GetPtrHash(collider)==sweeping then gunContact(tear,collider);return end
        local frame=game:GetFrameCount()
        tracePush('coll:hitsBody')
        local p=player()
        if not targets.tearHitsBody(collider,tear,frame,cfg.obstacleHeight,p and p.Position.X,p and p.Position.Y) then
            return true -- Skip the original planar hit when the 3D shape misses.
        end
        gunContact(tear,collider)
        -- nil retains vanilla damage, tear flags and on-hit effects.
        if cfg.hitboxWiden and type(collider.ForceCollide)=='function'
            and collider.Type~=EntityType.ENTITY_LASER
            and not targets.insideNativeRadius(collider,tear) then
            tracePush('coll:force')
            -- Force=false retains native collision-class and death checks;
            -- height overlap has already been checked above.
            -- One collide per tear per collider per frame keeps a repeated
            -- callback from applying the same damage twice.
            local collision=forcedCollisionState(tear,collider,frame)
            -- ForceCollide re-enters this callback before native effects run.
            -- That nested call must reach the engine; later repeats must not.
            if collision.inProgress then return end
            if not collision.done then
                tracePush('coll:ForceCollide')
                collision.inProgress=true
                local ok,err=pcall(collider.ForceCollide,collider,tear,false)
                collision.inProgress=false
                collision.done=true
                if not ok then error(err) end -- Keep the existing guard/release path.
            end
            return true -- The visible-shape collide already ran the vanilla effects.
        end
    end, 'PRE_TEAR_COLLISION'))

    mod:AddPriorityCallback(ModCallbacks.MC_PRE_TEAR_GRID_COLLISION, -100, guard(function(_, tear, index)
        if state.enabled and inCrawlspace() then return end
        tracePush('tear grid', tear.Type, tear.Variant, index)
        rememberShot(tear)
        if not tear:GetData().IsaacFPSProbe3D then return end
        local collision = game:GetRoom():GetGridCollision(index)
        if collision == GridCollisionClass.COLLISION_SOLID
            or collision == GridCollisionClass.COLLISION_OBJECT then
            if -tear.Height - tear.Size > cfg.obstacleHeight then return true end
        end
        -- Room walls remain solid; lower contacts retain native grid effects.
    end, 'PRE_TEAR_GRID_COLLISION'))
end

local renderOrder=include('fps_order')
-- 0.5.50 occlusion shortcut (fps_math.wallFreeRect); one cached rectangle.
local freeRectCache={}
local function drawEntities(p, sw, sh, focal, obstacles, roomEntities)
    local entities = obstacles or {}
    local held={}
    local prices={}
    local listedStains={}
    local camera={x=p.Position.X,y=p.Position.Y,eye=eyeHeight(),yaw=state.yaw,pitch=state.pitch,
        focal=focal,width=sw,height=sh,shotScale=cfg.shotScale,bodyOffset=cfg.shotBelowEye,
        enemyShotBelowEye=cfg.enemyShotBelowEye,
        now=Isaac.GetTime(),frame=game:GetFrameCount(),obstacleHeight=cfg.obstacleHeight,
        -- With the gun out, the always-present held melee weapon moves left
        -- of the gun view model (display only).
        heldSide=guns.runtime.controlsAttack() and cfg.heldSideWithGun or nil}
    -- 0.5.109: gun beams are drawn from the current muzzle and view
    -- (fps_attacks.followView); one laser entry pool per frame.
    if attacks.beginFrame then attacks.beginFrame() end
    if guns.runtime.controlsAttack() then
        local muzzleCamera={yaw=state.yaw,pitch=state.pitch,eye=camera.eye,
            muzzleAim=function(side) return guns.muzzleAim(cfg.fov,cfg.zoom,side) end}
        camera.gunMuzzle=function(yaw,side) return weapons.gunMuzzle(muzzleCamera,yaw,side) end
    end
    local counts=diagnostics.enabled and {entities=#roomEntities,npcs=0,tears=0,projectiles=0,
        effects=0,floorEffects=0,stainEntries=0,melee=0,wallRays=0,rayCacheHits=0,rayFree=0,billboards=0} or nil
    spriteCache.stats.copies,spriteCache.stats.reuses=0,0
    -- F8 per-entity and per-ray timers run on every 8th frame only (0.5.50):
    -- thousands of clock reads per frame inflated the stages they measured.
    local detail=counts and diagnostics.detail
    if detail then diagnostics.metric('occlusion_raycast',0) end
    local ppos=p.Position
    local ppx,ppy=ppos.X,ppos.Y
    local free=state.map and maths.wallFreeRect(state.map,ppx,ppy,freeRectCache)
    local fMinX,fMaxX,fMinY,fMaxY
    if free then fMinX,fMaxX,fMinY,fMaxY=free.minX,free.maxX,free.minY,free.maxY end
    local halfW,wide,tall=sw/2,sw*1.5,sh*2
    local memoX,memoY,memoResult
    local function visible(x,y,depth,worldX,worldY,worldOnly)
        if not worldOnly and (x < -halfW or x > wide or y < -sh or y > tall) then return false end
        -- Occlude against the actual horizontal ray to the world point. A
        -- pitched camera changes screen columns, but does not move the walls.
        if worldX then
            -- Inside the wall-free rectangle around the camera the ray can
            -- only meet a wall beyond the point: always visible, no ray.
            if fMinX and worldX>=fMinX and worldX<=fMaxX and worldY>=fMinY and worldY<=fMaxY then
                if counts then counts.rayFree=counts.rayFree+1 end
                return true
            end
            if worldX==memoX and worldY==memoY then
                if counts then counts.rayCacheHits=counts.rayCacheHits+1 end
                return memoResult
            end
            local dx,dy=worldX-ppx,worldY-ppy
            local distance=math.sqrt(dx*dx+dy*dy)
            local result=true
            if distance>=1 then
                if counts then counts.wallRays=counts.wallRays+1 end
                local started=detail and diagnostics.clock()
                local wall=maths.cast(state.map,ppx,ppy,dx/distance,dy/distance,true)
                if started then diagnostics.elapsed('occlusion_raycast',started) end
                result=distance<wall+2
            end
            memoX,memoY,memoResult=worldX,worldY,result
            return result
        end
        return true
    end
    -- Behind-camera cull for the mass entities (tears, enemy bullets,
    -- effects): Soy Milk fights hold 150+ of them and most of the frame went
    -- to projecting things the camera cannot see. Conservative: the nearest
    -- point within CULL_RADIUS horizontally and anywhere from the floor to
    -- the ceiling must still be behind the near plane. Enemies, bosses,
    -- items, knives and lasers are never culled here.
    local CULL_RADIUS=160
    local cfx,cfy=math.cos(state.yaw),math.sin(state.yaw)
    local ccp,csp=math.cos(state.pitch),math.sin(state.pitch)
    local verticalBest=math.max(-eyeHeight()*csp,((cfg.ceiling or 160)-eyeHeight())*csp)
    -- 0.5.50 side cull: a mass entity whose nearest point (SIDE_MARGIN for
    -- bullets, EFFECT_MARGIN for effects) lies outside the horizontal view
    -- at its most favourable depth is skipped before projection.
    local tanHalf=halfW/focal
    local SIDE_MARGIN,EFFECT_MARGIN=48,96
    local TEAR,PROJECTILE,EFFECT=EntityType.ENTITY_TEAR,EntityType.ENTITY_PROJECTILE,EntityType.ENTITY_EFFECT
    local frameCount=game:GetFrameCount()
    for _,entity in ipairs(roomEntities) do
        local etype=entity.Type
        if etype==EFFECT and entity.Variant==7 then
            listedStains[GetPtrHash(entity)]=entity.Visible
        end
        if etype~=EntityType.ENTITY_PLAYER and entity.Visible then
            if counts then
                if etype==TEAR then counts.tears=counts.tears+1
                    -- F8 detail: gun bullets vs other (native/familiar) tears.
                    if entity:GetData().IsaacFPSGunShot then counts.gunTears=(counts.gunTears or 0)+1
                    else counts.otherTears=(counts.otherTears or 0)+1 end
                elseif etype==PROJECTILE then counts.projectiles=counts.projectiles+1
                elseif etype==EFFECT then counts.effects=counts.effects+1
                    -- F8 detail: effects by variant (effV_<variant>).
                    local key='effV_'..entity.Variant
                    counts[key]=(counts[key] or 0)+1
                else
                    local key='entT_'..etype
                    counts[key]=(counts[key] or 0)+1
                end
            end
            local mass=etype==TEAR or etype==PROJECTILE or etype==EFFECT
            local culled=false
            if mass then
                local epos=entity.Position
                local ex,ey=epos.X-ppx,epos.Y-ppy
                local forward=ex*cfx+ey*cfy
                if (forward+CULL_RADIUS)*ccp+verticalBest<4 then
                    culled=true
                    if counts then counts.culledBehind=(counts.culledBehind or 0)+1 end
                else
                    local margin=etype==EFFECT and EFFECT_MARGIN or SIDE_MARGIN
                    local lateral=math.abs(ey*cfx-ex*cfy)
                    if lateral-margin>((forward+margin)*ccp+verticalBest)*tanHalf then
                        culled=true
                        if counts then counts.culledSide=(counts.culledSide or 0)+1 end
                    end
                end
                -- Procedural trackers still see a culled effect every frame.
                if culled and etype==EFFECT and procedural.handles(entity) then
                    procedural.observe(entity,frameCount)
                end
            end
            if not culled then
            local timer=detail and diagnostics.clock()
            local kind='ent_other'
            if mass and not (etype==EFFECT and items.matches(entity)) then
                -- 0.5.50 fast path: tears, enemy bullets and effects are never
                -- active enemies, priced pickups or knives, so they skip those
                -- classifiers (about 16-20 native calls each).
                kind=etype==TEAR and 'ent_tear' or etype==PROJECTILE and 'ent_projectile' or 'ent_effect'
                -- Engine-drawn procedural effects are rebuilt below.
                if etype==EFFECT and procedural.handles(entity) then procedural.observe(entity,frameCount) end
                local entry=shots.project(entity,camera)
                if entry then
                    if counts and entry.floor then counts.floorEffects=counts.floorEffects+1 end
                    entry.shot=true; entities[#entities+1]=entry
                end
            else
            local spriteOverride,spriteAnchor
            if etype==EntityType.ENTITY_FIREPLACE then
                spriteOverride,spriteAnchor=world.fireplaceEntity(entity,camera,entities)
            end
            if entity:IsActiveEnemy(false) then
                if counts then counts.npcs=counts.npcs+1 end
                targetBounds(entity) -- The floor shadow reuses these visible body bounds.
                local shadow=world.enemyShadow(entity,camera)
                if shadow then entities[#entities+1]=shadow end
            end
            local price=hud.price(entity,camera)
            if price then prices[#prices+1]=price end
            if timer then diagnostics.elapsed('ent_shadow_price',timer);timer=diagnostics.clock() end
            local knifeClass=melee.classify(entity,p)
            if counts and (knifeClass=='held' or knifeClass=='world') then counts.melee=counts.melee+1 end
            if knifeClass=='held' then
                kind='ent_knife'
                held[#held+1]=entity
                local entry=melee.projectHeld(entity,camera)
                if entry then entities[#entities+1]=entry end
            elseif knifeClass=='hidden' then
                -- A club hitbox has no weapon image to submit.
            elseif knifeClass=='world' then
                kind='ent_knife'
                local entry=melee.project(entity,camera)
                if entry then entry.melee=true;entities[#entities+1]=entry end
            elseif items.matches(entity) then
                kind='ent_item'
                local entry=items.project(entity,camera)
                if entry then entities[#entities+1]=entry end
            elseif etype==965 and world.gridPropEntity(entity,camera,entities) then
                kind='ent_grid_prop'
            elseif etype==EntityType.ENTITY_LASER then
                kind='ent_laser'
                for _,entry in ipairs(attacks.project(entity:ToLaser(),camera)) do entities[#entities+1]=entry end
            else
                kind='ent_body'
                local bounds=targets.renderBounds(entity,frameCount,cfg.obstacleHeight)
                local position=entity.Position
                local sx,sy,depth,forward=maths.project3D(position.X,position.Y,spriteAnchor or bounds.anchor,
                    ppx,ppy,eyeHeight(),state.yaw,state.pitch,focal,sw,sh)
                if sx then
                    -- 0.5.89: one body entry per entity, rewritten in full
                    -- each frame (as fps_shots does for bullets); its sort
                    -- key (entry.__orderKey) is reused with it. A new entry
                    -- and key per enemy per frame was the largest share of
                    -- a big room's remaining garbage (bench_bigroom).
                    local data=entity:GetData()
                    local entry=data.IsaacFPSProbeBodyEntry
                    if not entry then entry={};data.IsaacFPSProbeBodyEntry=entry end
                    entry.entity,entry.x,entry.y,entry.depth,entry.worldDepth=entity,sx,sy,depth,forward
                    entry.worldX,entry.worldY=position.X,position.Y
                    entry.flying,entry.nativeTransform=bounds.flying,bounds.nativeTransform
                    entry.spriteOverride=spriteOverride
                    entities[#entities+1]=entry
                end
            end
            end
            if timer then diagnostics.elapsed(kind,timer) end
            end
        end
    end
    diagnostics.mark('entity_project')
    for _,entry in ipairs(effects.entries(nil,camera,listedStains)) do
        entities[#entities+1]=entry
        if counts then counts.stainEntries=counts.stainEntries+1 end
    end
    if counts then
        local bs=effects.bakeStats
        counts.stainBakes,counts.stainAppends=bs.bakes-(state.stainBakes or 0),bs.appends-(state.stainAppends or 0)
        counts.stainBakeImages,counts.stainBakeOff=bs.images,bs.disabled and 1 or 0
        counts.stainBakeExhausted=bs.exhausted
        state.stainBakes,state.stainAppends=bs.bakes,bs.appends
    end
    diagnostics.mark('stains')
    -- Procedural effects: ground cracks as floor decals, lightning bolts.
    do
        local frame=game:GetFrameCount()
        state.renderTick=(state.renderTick or 0)+1
        local crackImage
        for _,crack in ipairs(procedural.crackFaces(frame)) do
            local points=world.projectFace(crack.vertices,camera)
            if #points>=3 then
                crackImage=crackImage or world.image('gfx/fps_probe/white.png')
                local depth,sx,sy=0,0,0
                for _,v in ipairs(points) do depth,sx,sy=depth+v.depth,sx+v.x,sy+v.y end
                entities[#entities+1]={surface=true,floor=true,groundDecal=true,solid=true,points=points,vertices=crack.vertices,
                    image=crackImage,color={.07,.05,.04,.85*crack.alpha},depth=depth/#points,
                    x=sx/#points,y=sy/#points,worldX=crack.worldX,worldY=crack.worldY}
            end
        end
        for _,path in ipairs(procedural.boltPaths(frame,state.renderTick)) do
            local entry=procedural.projectBolt(path,camera)
            if entry then entities[#entities+1]=entry end
        end
    end
    for _,face in ipairs(doors.surfaces(game:GetRoom(),state.map,camera,world)) do entities[#entities+1]=face end
    diagnostics.mark('doors')
    renderOrder.sort(entities,world.profileEnabled)
    diagnostics.mark('sort')
    world.stats.staticSortFaces=renderOrder.stats.staticFaces
    world.stats.dynamicSortEntries=renderOrder.stats.dynamicEntries
    world.stats.staticSortCacheHit=renderOrder.stats.staticCacheHit
    world.stats.sortMs=renderOrder.stats.sortMs
    local surfaceCache=world.surfaceCache
    local cacheStats=surfaceCache.stats
    local cacheHitsBefore=counts and cacheStats and cacheStats.hits or 0
    local cacheBuildsBefore=counts and cacheStats and cacheStats.builds or 0
    surfaceCache.beginFrame(camera,sw,sh)
    local visibleSurfaces={}
    local function isSurfaceVisible(entry)
        local cached=visibleSurfaces[entry]
        if cached~=nil then return cached end
        local result=(not entry.obstacle and not entry.door and not entry.groundDecal and not entry.shadow)
            or visible(entry.x,entry.y,entry.depth,entry.worldX,entry.worldY,true)
        visibleSurfaces[entry]=result
        return result
    end
    local function drawRange(entries,first,last)
        local i=first
        while i<=last do
            if i<last and world.drawPair(entries[i],entries[i+1]) then i=i+2
            else world.draw(entries[i]);i=i+1 end
        end
    end
    -- 0.5.89: billboards reuse scratch Scale, Offset and Render vectors (the
    -- engine copies them on assignment, see paint), four new engine Vectors
    -- per visible body per frame before; one/zero are read-only fallbacks.
    local bb=state.billboardScratch
    if not bb then
        bb={scale=Vector(1,1),offset=Vector(0,0),pos=Vector(0,0),one=Vector(1,1),zero=Vector(0,0)}
        state.billboardScratch=bb
    end
    local drawIndex=1
    while drawIndex<=#entities do
        local entry=entities[drawIndex]
        local consumed=surfaceCache.tryDraw(entities,drawIndex,isSurfaceVisible,drawRange)
        if consumed then
            -- These are Lua native Image submissions, not GPU draw/FPS counts.
            world.stats.submissions=world.stats.submissions+1
            drawIndex=drawIndex+consumed
        else
        if entry.surface then
            if isSurfaceVisible(entry) then
                local nextEntry=entities[drawIndex+1]
                if nextEntry and nextEntry.surface and entry.obstacle and nextEntry.obstacle
                    and entry.meshOwner and entry.meshOwner==nextEntry.meshOwner
                    and isSurfaceVisible(nextEntry)
                    and world.drawPair(entry,nextEntry) then drawIndex=drawIndex+1
                else world.draw(entry) end
            end
        elseif entry.grid then
            if visible(entry.x,entry.y,entry.depth,entry.worldX,entry.worldY) then
                local grid=entry.entity
                local index=type(grid.GetGridIndex)=='function' and grid:GetGridIndex() or nil
                local sprite=spriteCache.copy(index and ('g'..index),0,grid:GetSprite(),game:GetFrameCount())
                local spriteScale,v=sprite.Scale,bb.scale
                v.X,v.Y=spriteScale.X*entry.scale,spriteScale.Y*entry.scale
                sprite.Scale=v
                v=bb.pos;v.X,v.Y=entry.x,entry.y
                sprite:Render(v)
            end
        elseif entry.object then
            clippedRect(entry.x,entry.y,entry.w,entry.h,sw,sh,entry.r,entry.g,entry.b)
        elseif entry.item then items.draw(entry,visible)
        elseif entry.attack then attacks.draw(entry,visible)
        elseif entry.shot then shots.draw(entry,shadowSprite,visible,camera)
        elseif entry.melee then melee.drawWorld(entry,visible)
        elseif entry.procedural then procedural.drawBolt(entry,visible,stroke)
        elseif visible(entry.x,entry.y,entry.worldDepth or entry.depth,entry.worldX,entry.worldY) then
            if counts then counts.billboards=counts.billboards+1 end
            -- 0.5.58: one reused copy per entity (fps_sprite_cache), not a new
            -- engine Sprite every frame.
            local billboard=entry.entity
            local sprite=entry.spriteOverride or spriteCache.copy(GetPtrHash and GetPtrHash(billboard),billboard.InitSeed,billboard:GetSprite(),game:GetFrameCount(),billboard.SubType)
            -- Directional bodies show the side the viewer actually sees.
            if not entry.spriteOverride and facing.applies(entry.entity) then facing.apply(sprite,entry.entity,p.Position.X,p.Position.Y) end
            local scale=focal/entry.depth
            -- Fireplace's private flame already has the native Sprite transform.
            -- Entity SpriteScale/Offset alias that transform; apply them once.
            local entityScale=entry.nativeTransform and not entry.spriteOverride and entry.entity.SpriteScale or bb.one
            entityScale=entityScale or bb.one
            local spriteScale,v=sprite.Scale,bb.scale
            v.X,v.Y=spriteScale.X*entityScale.X*scale,spriteScale.Y*entityScale.Y*scale
            sprite.Scale=v
            local offset=entry.nativeTransform and not entry.spriteOverride and entry.entity.SpriteOffset or bb.zero
            offset=offset or bb.zero
            if entry.nativeTransform then
                local spriteOffset=sprite.Offset or bb.zero
                v=bb.offset;v.X,v.Y=spriteOffset.X*scale,spriteOffset.Y*scale
                sprite.Offset=v
            end
            if entry.flying then
                for _,layer in ipairs(sprite:GetAllLayers()) do
                    if layer:GetName():lower():find('shadow',1,true) then layer:SetVisible(false) end
                end
            end
            v=bb.pos;v.X,v.Y=entry.x+offset.X*scale,entry.y+offset.Y*scale
            sprite:Render(v)
        end
        drawIndex=drawIndex+1
        end
    end
    for _,entry in ipairs(prices) do hud.drawPrice(entry,visible) end
    diagnostics.mark('submit_and_occlusion')
    if counts then
        counts.renderEntries=#entities
        counts.faces=world.stats.faces or 0
        counts.submissions=world.stats.submissions or 0
        counts.staticSortFaces=world.stats.staticSortFaces or 0
        counts.dynamicSortEntries=world.stats.dynamicSortEntries or 0
        counts.staticSortCacheHits=renderOrder.stats.staticCacheHit and 1 or 0
        counts.staticOrderRepaired=renderOrder.stats.staticOrderRepaired and 1 or 0
        counts.projectionHits=world.stats.projectionHits or 0
        counts.spriteCopies=spriteCache.stats.copies
        counts.spriteReuses=spriteCache.stats.reuses
        counts.meshesCulled=world.stats.meshesCulled or 0
        counts.backdropDecorInstances=world.stats.backdropDecorInstances or 0
        counts.backdropDecorFaces=world.stats.backdropDecorFaces or 0
        local stats=surfaceCache.stats or {}
        counts.cacheHits=(stats.hits or 0)-cacheHitsBefore
        counts.cacheBuilds=(stats.builds or 0)-cacheBuildsBefore
        counts.prepareRemaining=world.stats.prepareRemaining or 0
        -- 0.5.26: rendering mode, GPU work and Lua heap (GC spikes).
        counts.gpuMode=world.gpuFrame and 1 or 0
        counts.gpuFaces=world.stats.gpuFaces or 0
        counts.gpuSubmissions=world.stats.gpuSubmissions or 0
        local heapOk,heap=pcall(collectgarbage,'count')
        counts.luaKiB=heapOk and heap or 0
        -- Heap growth since the previous sample (allocation pressure; a
        -- drop means a collection ran and reads as 0).
        counts.luaGrowKiB=heapOk and state.lastHeap and math.max(0,heap-state.lastHeap) or 0
        -- A heap drop means a garbage collection cycle finished this frame.
        counts.gcDrop=heapOk and state.lastHeap and heap<state.lastHeap and 1 or 0
        -- 0.5.96 (why only big rooms stutter): KiB a collection freed since the
        -- previous sample, and persistent vertex tables rewritten this frame.
        counts.gcFreedKiB=heapOk and state.lastHeap and math.max(0,state.lastHeap-heap) or 0
        counts.vertexWrites=world.vertexWrites-(state.lastVertexWrites or world.vertexWrites)
        state.lastVertexWrites=world.vertexWrites
        -- F8 player activity: what the player was doing in this frame.
        counts.ups=state.ups or 0
        local v=p.Velocity
        counts.moveSpeed=v and math.sqrt(v.X*v.X+v.Y*v.Y) or 0
        counts.fireHeld=(Input.IsMouseBtnPressed and Input.IsMouseBtnPressed(0)) and 1 or 0
        counts.ads=guns.view().ads or 0
        counts.reloading=guns.runtime.reloadProgress() and 1 or 0
        counts.gunOut=guns.runtime.controlsAttack() and 1 or 0
        local gs=guns.stats
        counts.gunShots=gs.shots-(state.lastGunShots or gs.shots)
        counts.nativeTearsDropped=gs.dropped-(state.lastDropped or gs.dropped)
        state.lastGunShots,state.lastDropped=gs.shots,gs.dropped
        local has=function(name) local id=CollectibleType and CollectibleType[name]
            return id and p:HasCollectible(id) and 1 or 0 end
        counts.soyMilk,counts.marked,counts.chocolateMilk=has('COLLECTIBLE_SOY_MILK'),has('COLLECTIBLE_MARKED'),has('COLLECTIBLE_CHOCOLATE_MILK')
        counts.fireDelay=p.MaxFireDelay or 0
        counts.nativeSkips=state.nativeSkips or 0
        -- 0.5.50: Sprite renders issued this frame by bullet drawing and the
        -- 2D overlay helpers (each is queued and executed at frame end).
        local ss=shots.stats
        local draws=state.lastDraws or {}
        counts.bodyDraws=ss.bodyDraws-(draws.body or ss.bodyDraws)
        counts.trailDraws=ss.trailDraws-(draws.trail or ss.trailDraws)
        counts.shadowDraws=ss.shadowDraws-(draws.shadow or ss.shadowDraws)
        counts.rectDraws=state.rectDraws-(draws.rect or state.rectDraws)
        draws.body,draws.trail,draws.shadow,draws.rect=ss.bodyDraws,ss.trailDraws,ss.shadowDraws,state.rectDraws
        state.lastDraws=draws
        -- Sprite size measurements this frame (0.5.46 caches keep this low).
        local measures=shots.stats.tearMeasures+shots.stats.effectMeasures
        counts.sizeMeasures=measures-(state.lastMeasures or measures)
        state.lastMeasures=measures
        state.lastHeap=heapOk and heap or nil
        local ws=world.stats
        counts.groundGrids,counts.groundBuilds,counts.groundHits=ws.groundGrids or 0,ws.groundBuilds or 0,ws.groundHits or 0
        counts.objects,counts.pitCells=ws.objects or 0,ws.pitCells or 0
        counts.pitRects,counts.pitWalls=ws.pitRects or 0,ws.pitWalls or 0
        counts.pitClips=ws.pitClips or 0
        for name,n in pairs(state.callbackCalls or {}) do counts['cbn_'..name]=n end
        diagnostics.metric('map_refresh',updateProfile.mapRefreshMs or 0)
    end
    return held,counts
end

-- Panels clear the native trinket (left) and pocket item (right) rows.
local PANEL_BOTTOM=40
-- 0.5.83 (user: no dodging, just sit where nothing covers them): both
-- panels always stand above the native trinket (left) and pocket (right)
-- slots; the HUD offset option moves those slots inward and up, so it lifts
-- the panels with them.
local SLOT_LIFT,OFFSET_LIFT=22,12
-- 0.5.97 (user screenshot: the hearts covered the last rows of the native
-- stat column, which stat mods lengthen); 0.5.100 (user: too close to the
-- centre, put it in the bottom-left corner clear of the trinket): the
-- health panel sits at the bottom edge just right of the native trinket
-- slot (about 0-40 px), below the stat column; the HUD offset moves the
-- slot inward and up, and the panel with it.
-- 0.5.124 (user screenshot: still low, level with the trinket slot): the
-- panel's bottom edge is 26 px above the screen edge, above the trinket
-- icon (top near 23 px) and still below the stat column.
local HEALTH_X,HEALTH_BOTTOM,OFFSET_SHIFT=44,26,20
local function hudOffset()
    local ok,value=pcall(function() return Options and Options.HUDOffset end)
    return ok and type(value)=='number' and math.max(0,math.min(1,value)) or 0
end
local function panelBottom(sh)
    return sh-PANEL_BOTTOM-SLOT_LIFT-hudOffset()*OFFSET_LIFT
end
local function textAt(text,x,y,r,g,b,a) locale.draw(text,x+uiX,y+uiY,r,g,b,a) end
local function nativeAttackName(p)
    local weapon=p.GetWeapon and p:GetWeapon(1)
    local kind=weapon and weapon.GetWeaponType and weapon:GetWeaponType()
    if kind then
        local key='weapon_type_'..tostring(kind)
        local name=locale.text(key)
        if name~=key then return name end
    end
    return locale.text('weapon_native')
end
local function weaponStatus(p)
    -- Native attacks have no magazine: the panel shows infinite ammunition.
    return guns.status(nativeAttackName(p),locale.text)
end
local function drawPanels(p,sw,sh,nativeControls)
    local now=Isaac.GetTime()
    local level=game.GetLevel and game:GetLevel()
    local curses=level and level.GetCurses and level:GetCurses() or 0
    local model=health.forPlayer(p,curses)
    health.track(healthState,model,p.InitSeed,now)
    local bottom=panelBottom(sh)
    local x=HEALTH_X+hudOffset()*OFFSET_SHIFT
    local healthWidth=health.draw(model,x,sh-HEALTH_BOTTOM-hudOffset()*OFFSET_LIFT,rect,textAt,healthState,now)
    state.healthPanelRight=x+(healthWidth or 0)
    if not nativeControls then hud.drawWeaponPanel(weaponStatus(p),sw-8,bottom,rect,textAt,locale.width) end
end

-- 0.5.73: the room's doors for the minimap (open state and target kind).
local DOOR_KINDS
local doorList,doorFrame={},nil
local function minimapDoors()
    local frame=game:GetFrameCount()
    if doorFrame==frame then return doorList end
    doorFrame=frame
    if not DOOR_KINDS and RoomType then
        DOOR_KINDS={[RoomType.ROOM_TREASURE or -1]='treasure',[RoomType.ROOM_BOSS or -1]='boss',
            [RoomType.ROOM_SHOP or -1]='shop',[RoomType.ROOM_SECRET or -1]='secret',
            [RoomType.ROOM_SUPERSECRET or -1]='secret',[RoomType.ROOM_CURSE or -1]='curse',
            [RoomType.ROOM_DEVIL or -1]='devil',[RoomType.ROOM_ANGEL or -1]='angel'}
    end
    local room=game:GetRoom()
    local n=0
    for slot=0,7 do
        local door=room and room.GetDoor and room:GetDoor(slot)
        if door then
            n=n+1
            local entry=doorList[n] or {}
            doorList[n]=entry
            entry.x,entry.y=door.Position.X,door.Position.Y
            entry.open=type(door.IsOpen)=='function' and door:IsOpen() or false
            entry.kind=DOOR_KINDS and DOOR_KINDS[door.TargetRoomType] or 'normal'
        end
    end
    for i=n+1,#doorList do doorList[i]=nil end
    return doorList
end

local function minimap(p, sw, sh, roomEntities)
    if not cfg.minimap then return end
    local ox,oy=uiX,uiY
    uiX,uiY=0,0
    -- Effective horizontal view angle (zoom and ADS narrow the cone).
    local fov=2*math.atan(math.tan(math.rad(cfg.fov)/2)/(cfg.zoom*guns.zoom()))
    minimapView.draw(state.map,p,state.yaw,sw,sh,roomEntities,rect,fov,minimapLine,ox,oy,minimapDoors())
    -- Collected items as small icons under the minimap (replaces the native
    -- right-side recent-items strip, which overlaps other UI in FPS).
    local x0,y0,size=minimapView.origin(state.map,sw,sh)
    pickups.drawList(x0+ox,y0+oy+state.map.height*size+5,state.map.width*size)
    uiX,uiY=ox,oy
end

local shakeX,shakeY,shakeYaw,shakePitch=0,0,nil,nil
local function drawScene(p, sw, sh)
    local sceneRoom=game:GetRoom()
    local nativeScene=crawlspace.isRoom(sceneRoom)
    state.crawlspace=nativeScene
    diagnostics.begin(pauseMenuOpen() and 'pause' or transitionActive() and 'transition'
        or game:IsPaused() and 'pause' or nativeScene and 'crawlspace' or 'play')
    -- 0.5.84: teleport progress from the player's native teleport animation.
    local level=game.GetLevel and game:GetLevel()
    local roomIndex=level and level.GetCurrentRoomIndex and level:GetCurrentRoomIndex()
    teleport.update(p,Isaac.GetTime(),roomIndex,transitionActive())
    -- Our logic/entity callbacks since the previous scene sample.
    if diagnostics.enabled and diagnostics.metric then
        diagnostics.metric('callbacks',callbackMs)
        for name,ms in pairs(callbackByName) do diagnostics.metric('cb_'..name,ms) end
        for name,kb in pairs(callbackKb) do diagnostics.metric('kbcb_'..name,kb) end
    end
    state.callbackCalls=callbackCalls
    callbackMs,callbackByName,callbackCalls,callbackKb=0,{},{},{}
    stage('scene')
    if not rectangle then
        rectangle = Sprite()
        rectangle:Load("gfx/fps_probe/white.anm2", true)
        rectangle:Play("Idle", true)
        shadowSprite=Sprite()
        shadowSprite:Load("gfx/fps_probe/shadow.anm2",true)
        shadowSprite:Play("Idle",true)
    end
    stage('sprites')
    if not nativeScene and not state.map then buildMap() end
    diagnostics.mark('scene_setup')
    stage('map')
    if viewActive() and not nativeScene then
        -- ADS easing and partial recoil recovery advance only while playing.
        state.pitch=maths.clamp(state.pitch+guns.step(Isaac.GetTime()),-cfg.maxPitch,cfg.maxPitch)
    end
    updateEye(p,Isaac.GetTime())
    local focal = sw / (2 * math.tan(math.rad(cfg.fov) / 2))*cfg.zoom*guns.zoom()
    if shakeX~=0 or shakeY~=0 then
        -- Turn the camera so the world point under the crosshair moves by
        -- exactly the native offset, as every native sprite does.
        shakeYaw,shakePitch=state.yaw,state.pitch
        state.yaw,state.pitch=maths.shakeView(state.yaw,state.pitch,shakeX/focal,shakeY/focal)
    end
    local horizon = sh / 2 + math.tan(state.pitch) * focal
    rect(0, 0, sw, sh, 0, 0, 0)
    clippedRect(0, horizon, sw, sh - horizon, sw, sh, 0.25, 0.21, 0.18)
    local roomEntities=Isaac.GetRoomEntities()
    diagnostics.mark('snapshot')
    local held,counts,surfaces
    if nativeScene then
        -- Do not feed the side-view native XY plane into top-down walls,
        -- floor occlusion, weapon elevation or the normal minimap sector.
        world.gpuFrame=false
        counts=crawlspaceView.draw(sceneRoom,p,{yaw=state.yaw,pitch=state.pitch,
            focal=focal,width=sw,height=sh,frame=game:GetFrameCount(),eyeOffset=cfg.eye},world,roomEntities)
        held={}
        diagnostics.mark('crawlspace_scene')
        stage('crawlspace')
    else
        local camera={x=p.Position.X,y=p.Position.Y,eye=eyeHeight(),yaw=state.yaw,pitch=state.pitch,
            focal=focal,width=sw,height=sh,frame=game:GetFrameCount()}
        world.subProfile=diagnostics.enabled
        surfaces=world.surfaces(sceneRoom,state.map,camera)
        diagnostics.mark('world_surfaces')
        if diagnostics.enabled and world.stats.sub then
            for name,ms in pairs(world.stats.sub) do diagnostics.metric('ws_'..name,ms) end
        end
        stage('surfaces')
        held,counts=drawEntities(p,sw,sh,focal,surfaces,roomEntities)
        stage('entities')
    end
    if not nativeScene then warnings(p,sw,sh,focal,roomEntities) end
    diagnostics.mark('warnings')
    stage('warnings')
    uiX,uiY=shakeX,shakeY
    if not nativeScene and not guns.runtime.controlsAttack() then melee.drawHeld(held,sw,sh,uiX,uiY) end
    diagnostics.mark('held_overlay')
    stage('melee')
    local gunTimer=counts and diagnostics.clock()
    local gunFaces,gunSettled,gunAffine={}
    if not nativeScene then gunFaces,gunSettled,gunAffine=guns.viewFaces(sw,sh) end
    if #gunFaces>0 then
        local white=materials.image('gfx/fps_probe/white.png')
        -- A settled gun is drawn from one cached render target; recoil moves
        -- that image with a 2D affine instead of rebuilding the model.
        local cached=gunSettled and gunCache.draw(gunFaces,function(face,dx,dy)
            local shifted={}
            for i,p in ipairs(face.points) do shifted[i]={x=p.x+dx,y=p.y+dy,depth=p.depth} end
            world.draw({points=shifted,image=white,color=face.color,solid=true})
        end,sw,sh,gunAffine,uiX,uiY)
        -- Without the cache, a kicked pose must be rebuilt exactly.
        if not cached and gunAffine then gunFaces=guns.viewFaces(sw,sh,true) end
        if not cached then
            for _,face in ipairs(gunFaces) do
                -- Cached faces keep their draw table (and its native color).
                local drawFace=face.drawFace
                if not drawFace then
                    drawFace={points=face.points,image=white,color=face.color,solid=true}
                    face.drawFace=drawFace
                end
                if uiX~=0 or uiY~=0 then
                    -- Shaking: a shifted copy, the cached face stays put.
                    local shifted={}
                    for i,q in ipairs(face.points) do shifted[i]={x=q.x+uiX,y=q.y+uiY,depth=q.depth} end
                    drawFace={points=shifted,image=white,color=face.color,solid=true}
                end
                world.draw(drawFace)
            end
        end
    end
    if gunTimer then diagnostics.elapsed('gun_model',gunTimer) end
    stage('gun')
    local crosshair=guns.crosshairAlpha()
    if crosshair>0 then
        rect(sw / 2 - 4, sh / 2, 9, 1, 0.95, 0.95, 0.95, crosshair)
        rect(sw / 2, sh / 2 - 4, 1, 9, 0.95, 0.95, 0.95, crosshair)
    end
    if not nativeScene then guns.drawMarkers(sw,sh,Isaac.GetTime(),line) end
    local chargeLevel=not nativeScene and guns.chargeLevel()
    if chargeLevel then
        rect(sw/2-12,sh/2+9,24,3,.1,.1,.1,.7)
        rect(sw/2-12,sh/2+9,24*chargeLevel,3,1,chargeLevel>=1 and .35 or .85,.3,1)
    end
    pickups.drawHand(sw,sh,Isaac.GetTime(),rect,state.healthPanelRight,uiX,uiY)
    guns.drawMessage(sw,Isaac.GetTime(),textAt,locale.width)
    -- 0.5.70: with the gun out the native charge (e.g. Brimstone under Mouse
    -- Control) never fires, so its bar is not shown.
    if nativeScene or guns.runtime.controlsAttack() and not guns.nativeShootNeeded(p) then hud.resetCharge()
    else hud.drawCharge(p,sw,sh,Isaac.GetTime(),rect) end
    diagnostics.mark('hud')
    stage('hud')
    local minimapStats=counts and minimapView.stats
    local minimapBuilds=minimapStats and minimapStats.builds
    local minimapHits=minimapStats and minimapStats.hits
    local minimapFallbacks=minimapStats and minimapStats.fallbacks
    if not nativeScene then minimap(p, sw, sh,roomEntities) end
    if minimapStats then
        counts.minimapBuilds=minimapStats.builds-minimapBuilds
        counts.minimapCacheHits=minimapStats.hits-minimapHits
        counts.minimapFallbacks=minimapStats.fallbacks-minimapFallbacks
        counts.minimapImages=minimapStats.images
        counts.minimapBytes=minimapStats.bytes
    end
    diagnostics.mark('minimap')
    stage('minimap')
    -- 0.5.85: the hurt vignette sits under the HUD panels.
    do
        local ox,oy=uiX,uiY
        uiX,uiY=0,0
        health.drawHurtScreen(sw,sh,rect,healthState,Isaac.GetTime())
        uiX,uiY=ox,oy
    end
    drawPanels(p,sw,sh,nativeScene)
    -- 0.5.97 F8: the HUD tail split (text_and_settings was ~35 KiB/frame).
    diagnostics.mark('panels')
    stage('panels')
    -- 0.5.84: the teleport beam covers the view and the HUD.
    local ox,oy=uiX,uiY
    uiX,uiY=0,0
    teleport.draw(sw,sh,rect,Isaac.GetTime())
    uiX,uiY=ox,oy
    diagnostics.mark('teleport')
    stage('teleport')
    -- 0.5.97 (user: the long Chinese line ran under the native minimap): the
    -- top line shows only the version and sensitivity; F6 is announced at the
    -- run start.
    local hint=locale.text("hud_sens","0.5.132",state.sensitivity)
    local hintWidth=locale.width(hint)
    local hintX=math.floor((sw-hintWidth)/2)
    rect(hintX-4,1,hintWidth+8,13,0.05,0.04,0.05,0.55)
    locale.draw(hint,hintX+uiX,2+uiY,1,1,1,0.85)
    stage('locale')
    diagnostics.mark('text_and_settings')
    diagnostics.finish(counts)
    stage('end')
end

-- Stable FPS camera: native shake from shots/explosions is not reproduced
-- in the 3D view or its HUD. The native game effects remain untouched.
local function screenShake()
    return 0,0
end
local function renderScene(p, sw, sh)
    shakeX,shakeY=screenShake()
    shakeYaw,shakePitch=nil,nil
    local ok,result=xpcall(drawScene,errorHandler,p,sw,sh)
    if shakeYaw then state.yaw,state.pitch=shakeYaw,shakePitch end
    shakeYaw,shakePitch,uiX,uiY=nil,nil,0,0
    if not ok then error(result,0) end
end

local function renderControls(p,sw,sh)
    if state.controlsSerial==state.renderSerial then return end
    state.controlsSerial=state.renderSerial
    if transitionActive() or bossIntroActive() then
        -- Discard the cursor sample accumulated by native sliding/room loads.
        -- Resume through resetMouse without changing the selected view angle.
        state.mouseSuspended=true
        state.mouseDown,state.mouseFrame=false,nil
        return
    end
    if not viewActive() then return end
    local keys=state.frameKeys or {}
    -- Mod Config Menu is open: no mouse look; resume cleanly when it closes.
    if mcm.isOpen() then
        state.mouseSuspended=true
        state.mouseDown,state.mouseFrame=false,nil
        return
    end
    -- Archived F10 panel: settings.isOpen()/capturing() stay false because
    -- nothing opens it any more (settings live in Mod Config Menu).
    if settings.capturing() then
        -- Rebinding: the next key pressed after capture began becomes the
        -- reload key. Raw state against a snapshot, because other readers
        -- may already have consumed this frame's edges.
        local held=state.captureHeld
        local first=not held
        if first then held={};state.captureHeld=held end
        local chosen
        for name,code in pairs(Keyboard) do
            if type(code)=='number' then
                local down=key(code)
                if first then held[code]=down or nil
                elseif not down then held[code]=nil
                elseif not held[code] and not chosen then chosen=name end
            end
        end
        if chosen then settings.capture(chosen);state.captureHeld=nil end
    elseif settings.isOpen() then
        settings.handle(keys.up,keys.down,keys.left,keys.right,keys.reset,
            key(Keyboard.KEY_LEFT_SHIFT) or key(Keyboard.KEY_RIGHT_SHIFT))
        applySettings()
    end
    if keys.lower then settings.changeSensitivity(1/1.2);applySettings() end
    if keys.higher then settings.changeSensitivity(1.2);applySettings() end
    if keys.recenter then resetMouse() end
    if p.ControlsEnabled then
        if state.mouseSuspended then resetMouse();state.mouseSuspended=false end
        mouseLook(sw,sh)
    else state.mouseSuspended=true end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, guard(function()
    traceFrameNow=game:GetFrameCount()
    stage('update')
    -- F8: real game logic updates per second (30 normally; fewer means the
    -- game itself runs in slow motion even when the render rate looks fine).
    if diagnostics.enabled then
        local t=Isaac.GetTime()
        if not state.upsStart or t-state.upsStart>5000 then state.upsStart,state.upsCount=t,0 end
        state.upsCount=state.upsCount+1
        if t-state.upsStart>=1000 then
            state.ups=state.upsCount*1000/(t-state.upsStart)
            state.upsStart,state.upsCount=t,0
        end
    end
    local started=diagnostics.clock()
    if active() then
        if not state.map then buildMap() else maps.refresh(game:GetRoom(),state.map,cfg.obstacleHeight,cfg.ceiling) end
    end
    if started then updateProfile.mapRefreshMs=diagnostics.clock()-started end
    stage('update-refresh')
    local frame=game:GetFrameCount()
    if active() then
        local p=player()
        guns.update(p,weaponCamera(),frame,Isaac.GetTime(),weapons,function(kick,yawKick)
            state.pitch=maths.clamp(state.pitch+kick,-cfg.maxPitch,cfg.maxPitch)
            state.yaw=(state.yaw+yawKick)%(2*math.pi)
        end)
    end
    for seed,shot in pairs(state.shotHistory) do
        if frame-shot.frame>2 then state.shotHistory[seed]=nil end
    end
    -- Track acquisitions in every view so FPS shows only genuinely new items.
    local holder=player()
    if holder then pickups.update(holder,frame,Isaac.GetTime()) end
end, 'POST_UPDATE'))


local inputCallback=ModCallbacks.MC_PRE_RENDER or ModCallbacks.MC_POST_RENDER
mod:AddPriorityCallback(inputCallback, -1000, guard(function()
    state.renderSerial=state.renderSerial+1
    traceFrameNow=game:GetFrameCount()
    diagnostics.detail=diagnostics.enabled and state.renderSerial%8==0
    -- Native drawing of tears, enemy bullets and effects is skipped in frames
    -- where the FPS scene covers the whole native view (0.5.50, see below).
    state.hideNativeMass=viewActive() and not transitionActive() and not bossIntroActive() or false
    if state.hideNativeMass then hideRoomShadows() elseif not state.enabled then restoreRoomShadows() end
    if diagnostics.enabled then state.nativeSkips=0 end
    -- Upper/forward thumb button; independent press edge, also with F6 held.
    local sideDown=Input.IsMouseBtnPressed and Input.IsMouseBtnPressed(
        Mouse and Mouse.MOUSE_BUTTON_5 or 4) or false
    local sideEdge=sideDown and not state.fpsSideDown
    state.fpsSideDown=sideDown
    local toggle = edge(Keyboard.KEY_F6) or sideEdge
    local recenter = edge(Keyboard.KEY_F9)
    local lower = edge(Keyboard.KEY_LEFT_BRACKET)
    local higher = edge(Keyboard.KEY_RIGHT_BRACKET)
    local menuToggle=edge(Keyboard.KEY_F10)
    if Keyboard.KEY_F8 and edge(Keyboard.KEY_F8) then
        diagnostics.setEnabled(not diagnostics.enabled)
        -- Deltas restart with the recording (the first frame used to report
        -- all growth since F8 was last on).
        state.lastHeap,state.lastMeasures,state.lastGunShots,state.lastDropped=nil,nil,nil,nil
        state.lastDraws,state.lastVertexWrites=nil,nil
        if diagnostics.enabled and gcInfo then Isaac.DebugString(gcInfo) end
    end
    local up,down,left,right,reset=edge(Keyboard.KEY_PAGE_UP),edge(Keyboard.KEY_PAGE_DOWN),
        edge(Keyboard.KEY_MINUS),edge(Keyboard.KEY_EQUAL),edge(Keyboard.KEY_HOME)
    state.frameKeys={recenter=recenter,lower=lower,higher=higher,menuToggle=menuToggle,
        up=up,down=down,left=left,right=right,reset=reset}
    local p = player()
    -- Room transitions briefly invalidate player/input state. Keep the mode
    -- selected until an explicit exit or MC_PRE_GAME_EXIT.
    if not p then
        diagnostics.suspend('no_player')
        if state.enabled then resetMouse() end
        return
    end
    if game:IsPaused() then state.mouseSuspended=true end
    if not ready then
        locale.render("requires_repentogon",10,45,1,.4,.3,1)
        return
    end
    if toggle and not p:IsDead() and (not game:IsPaused()
        or (state.enabled and transitionActive() and not pauseMenuOpen())) then
        if state.enabled then release()
        elseif game:GetNumPlayers() ~= 1 then state.message = locale.text("single_player_only")
        else
            state.enabled, state.cooldown = true, 0
            state.startHintUntil = nil
            state.error, state.map, state.noPlayerFrames = nil, nil, 0
            resetCrawlspace(p)
            world.reset()
            settings.resetMenu()
            resetMouse()
        end
    end
    if state.enabled and p:IsDead() then release(locale.text("resume_fps")) end
    local gunLive=state.enabled and not inCrawlspace() and viewActive() and p.ControlsEnabled and not settings.isOpen() and not mcm.isOpen()
        and not transitionActive()
    local leftDown=Input.IsMouseBtnPressed and Input.IsMouseBtnPressed(0) or false
    local gunClick=leftDown and not state.gunMouseDown
    state.gunMouseDown=leftDown
    guns.renderInput(Isaac.GetTime(),gunLive,edge,gunClick,
        Input.IsMouseBtnPressed and Input.IsMouseBtnPressed(1) or false,leftDown)
    renderControls(p,Isaac.GetScreenWidth(),Isaac.GetScreenHeight())
end, 'RENDER_INPUT'))

-- 0.5.85: any damage the player actually takes starts the heart blink and
-- the hurt vignette, also when a curse hides the health.
if ModCallbacks.MC_POST_ENTITY_TAKE_DMG then
    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG,guard(function(_,entity)
        if not state.enabled then return end
        local p=player()
        if p and GetPtrHash(entity)==GetPtrHash(p) then health.hurt(healthState,Isaac.GetTime()) end
    end,'PLAYER_HURT'),EntityType.ENTITY_PLAYER)
end

-- Process camera controls before submitting our scene and HUD.
-- 0.5.85 (user: EID and other mods' overlays on top of ours): this fallback
-- scene draw runs before every other mod's POST_RENDER (EID, Mod Config Menu
-- use the default priority), as the usual room-render path already does.
local SCENE_PRIORITY=-500
mod:AddPriorityCallback(ModCallbacks.MC_POST_RENDER, SCENE_PRIORITY, guard(function()
    local p=player()
    local sw, sh = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
    if not ready then return end
    if pauseMenuOpen() or (state.enabled and bossIntroActive()) then return end
    if game:IsPaused() and (transitionActive() or not state.enabled or not overlayActive()) then return end
    if not p then
        -- A room or floor load briefly invalidates the player reference. The
        -- mask keeps the native view from showing through while the engine
        -- finishes the transition; FPS state, input and the map rebuild are
        -- untouched, and the mode releases after ten seconds regardless.
        if state.enabled then
            state.noPlayerFrames = state.noPlayerFrames + 1
            if state.noPlayerFrames > 300 then
                -- Ten seconds without a player is not a transition anymore.
                release(locale.text("resume_fps"))
                return
            end
            if state.roomSceneSerial~=state.renderSerial then paintBackdrop(sw, sh) end
        end
        return
    end
    state.noPlayerFrames = 0
    -- A successful room draw already includes the HUD. Avoid submitting a
    -- second full scene in the late global callback.
    if state.roomSceneSerial==state.renderSerial then return end
    if game:IsPaused() then
        -- Non-menu pauses (item/card/active giant-book overlays) run native
        -- HUD and ItemOverlay after this callback. Keep the frozen FPS view
        -- beneath them instead of exposing the native top-down room.
        if not p:IsDead() then
            renderScene(p,sw,sh)
            state.roomSceneSerial=state.renderSerial
        end
        return
    end
    if not viewActive() then
        state.mouseSuspended=true
        drawStartHint(sw,sh)
        return
    end
    if transitionActive() then return end
    renderControls(p,sw,sh)
    if viewActive() then renderScene(p, sw, sh) end
end, 'RENDER_SCENE'))

-- FPS turns on the native Mouse Control option (so the engine draws its own
-- cursor instead of the Windows arrow) and restores the player's value when
-- FPS ends; that cursor sprite is hidden while the view owns the mouse
-- (menus keep it).
mod:AddPriorityCallback(ModCallbacks.MC_POST_RENDER, 99999, guard(function()
    cursor.mouseControl(state.enabled)
    cursor.update(state.enabled and not pauseMenuOpen() and not mcm.isOpen() and not settings.isOpen())
end, 'CURSOR'))

-- Off-screen builds (gun pose cache, stain bake) run here, after the whole
-- frame including the native HUD, never inside the room render: switching
-- render targets mid-scene coincided with the native active item/stat HUD
-- disappearing (0.5.31). Their results are used from the next frame.
mod:AddPriorityCallback(ModCallbacks.MC_POST_RENDER, 100000, guard(function()
    gunCache.flush()
    effects.flushBake()
end, 'OFFSCREEN_BUILDS'))

-- 0.5.50 F8 frame phases: first player update, last post-update, first
-- pre-render and the very last post-render callback mark one main-loop
-- iteration (fps_diagnostics.frameEnd). Unguarded: they only read a flag.
if ModCallbacks.MC_PRE_PLAYER_UPDATE then
    mod:AddPriorityCallback(ModCallbacks.MC_PRE_PLAYER_UPDATE,-1000000,function() if diagnostics.enabled then diagnostics.stampOnce('updStart') end end)
    -- 0.5.110: right before the player reads its aim, the native camera (and
    -- so the centred Mouse Control cursor) is put on the view direction.
    mod:AddPriorityCallback(ModCallbacks.MC_PRE_PLAYER_UPDATE,-999999,guard(function(_,entity)
        local p=player()
        if not p or not entity or GetPtrHash(entity)~=GetPtrHash(p) then return end
        if active() then
            if aimCamera.aim(p,state.yaw) then
                local level=game:GetLevel()
                aimCamera.logCheck(p,state.yaw,level and level:GetCurrentRoomIndex() or 0)
            end
        else aimCamera.release(p) end
    end,'AIM_CAMERA'))
end
mod:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE,1000000,function() if diagnostics.enabled then diagnostics.stamp('updEnd') end end)
if ModCallbacks.MC_PRE_RENDER then
    mod:AddPriorityCallback(ModCallbacks.MC_PRE_RENDER,-1000000,function() if diagnostics.enabled then diagnostics.stampOnce('preRender') end end)
end
-- 0.5.56: while FPS is on, garbage collection runs here, after the whole
-- frame (fps_gc), instead of inside whichever callback allocates.
mod:AddPriorityCallback(ModCallbacks.MC_POST_RENDER,1000000000,function()
    -- 0.5.110: keep the native camera on the view after this frame's look.
    local aimPlayer=active() and player() or nil
    if aimPlayer then
        pcall(aimCamera.aim,aimPlayer,state.yaw)
        if type(Isaac.WorldToScreen)=='function' then
            state.camRef,state.camRefFrame=Isaac.WorldToScreen(Vector(0,0)),game:GetFrameCount()
        end
    end
    gc.frame(state.enabled,diagnostics.clock,world.stats.gpuFaces)
    if diagnostics.enabled then
        local s=gc.stats
        diagnostics.metric('gc_tail',s.ms)
        diagnostics.metric('gc_step_max',s.maxStep)
        diagnostics.metric('gc_steps',s.steps)
        diagnostics.metric('gc_cycle',s.cycles)
        diagnostics.metric('gc_modeReset',s.modeReset or 0)
        diagnostics.metric('gc_restarted',s.restarted or 0)
        diagnostics.frameEnd()
    end
end)

-- 0.5.96 console command fpsgctest: timed collection cycles (fps_gc).
if ModCallbacks.MC_EXECUTE_CMD then
    mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD,guard(function(_,command)
        if command=='fpsgctest' then
            if not state.enabled then return 'fpsgctest: turn the FPS view on (F6) first' end
            return gc.startTest()
        end
    end,'EXECUTE_CMD_GC'))
end

-- The pause screen replaces the normal room render. Paint the custom scene
-- immediately before the native pause overlay so its interaction remains
-- intact on top of the FPS view.
if ModCallbacks.MC_PRE_PAUSE_SCREEN_RENDER then
    mod:AddCallback(ModCallbacks.MC_PRE_PAUSE_SCREEN_RENDER, guard(function()
        -- Only the Esc menu owns this background. Other pauses already drew
        -- beneath native HUD/ItemOverlay; covering them would hide overlays.
        if not state.enabled or not pauseMenuOpen() then return end
        if state.roomSceneSerial==state.renderSerial then return end
        local p=player()
        if not p or p:IsDead() then
            paintBackdrop(Isaac.GetScreenWidth(),Isaac.GetScreenHeight())
            return
        end
        state.noPlayerFrames=0
        renderScene(p,Isaac.GetScreenWidth(),Isaac.GetScreenHeight())
    end, 'PAUSE_SCENE'))
end

-- Keep normal room captures in FPS, including captures before PRE_ROOM_EXIT.
-- During native transitions the engine composites those captures later; the
-- dedicated post-transition hook below owns the final full-screen submission.
if ModCallbacks.MC_POST_ROOM_RENDER_ENTITIES then
    mod:AddCallback(ModCallbacks.MC_POST_ROOM_RENDER_ENTITIES, guard(function()
        if not state.enabled or pauseMenuOpen() then return end
        -- Giant-book pauses still render the room; draw the frozen FPS view so
        -- native HUD/ItemOverlay keep their own later layers above it. Other
        -- non-menu pauses (nightmares, cutscenes) stay native.
        if game:IsPaused() and not transitionActive() and not overlayActive() then return end
        -- The same Room::Render hook runs for snapshot targets in Update or
        -- ChangeRoom and for on-screen mode 1/4 frames. Each target needs its
        -- own scene; only the later 1272 screen submission is deduplicated.
        if bossIntroActive() then return end
        local sw, sh = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
        local p = player()
        if p and not p:IsDead() then
            state.noPlayerFrames = 0
            renderControls(p,sw,sh)
            if not state.enabled then return end
            renderScene(p, sw, sh)
        else
            paintBackdrop(sw, sh)
        end
        state.roomSceneSerial=state.renderSerial
    end, 'ROOM_RENDER_LIFECYCLE'))
end

if ModCallbacks.MC_POST_ROOM_TRANSITION_RENDER then
    mod:AddCallback(ModCallbacks.MC_POST_ROOM_TRANSITION_RENDER, guard(function()
        -- This callback is dispatched AFTER RoomTransition::Render. Its mode
        -- is a callback filter, not a Lua argument; query the global dot API.
        if not state.enabled or pauseMenuOpen() or not transitionActive() or bossIntroActive() then return end
        if state.transitionSceneSerial==state.renderSerial then return end
        local sw,sh=Isaac.GetScreenWidth(),Isaac.GetScreenHeight()
        local p=player()
        if p and not p:IsDead() then
            state.noPlayerFrames=0
            renderScene(p,sw,sh)
        else
            paintBackdrop(sw,sh)
        end
        state.transitionSceneSerial=state.renderSerial
        state.roomSceneSerial=state.renderSerial
    end, 'ROOM_TRANSITION_COMPOSITE'))
end

-- 0.5.50: the engine drew every tear, enemy bullet and effect natively and
-- the full-screen FPS scene then covered all of it; with 200+ of them that
-- was wasted engine time each frame. Skip those native draws while the
-- scene covers the view (the FPS scene renders them itself through their
-- sprites, which these callbacks do not see). Blood stains (effect 7) keep
-- their native render: their POST_EFFECT_RENDER captures the stain frame.
-- Plain callbacks (no guard): called hundreds of times per frame and they
-- only read one flag.
do
    local function skip()
        if state.hideNativeMass then
            if state.nativeSkips then state.nativeSkips=state.nativeSkips+1 end
            return false
        end
    end
    if ModCallbacks.MC_PRE_TEAR_RENDER then mod:AddCallback(ModCallbacks.MC_PRE_TEAR_RENDER,skip) end
    if ModCallbacks.MC_PRE_PROJECTILE_RENDER then mod:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_RENDER,skip) end
    -- NPCs/bombs were still drawn by the native top-down renderer underneath
    -- the opaque FPS view. Our sprite renderer draws them independently; keep
    -- their logic/collision and skip only this invisible duplicate draw.
    if ModCallbacks.MC_PRE_NPC_RENDER then mod:AddCallback(ModCallbacks.MC_PRE_NPC_RENDER,skip) end
    if ModCallbacks.MC_PRE_BOMB_RENDER then mod:AddCallback(ModCallbacks.MC_PRE_BOMB_RENDER,skip) end
    if ModCallbacks.MC_PRE_EFFECT_RENDER then
        mod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER,function(_,effect)
            if effect.Variant==EffectVariant.BLOOD_SPLAT then return end
            return skip()
        end)
    end
end

-- 0.5.53 Curse of Darkness and dark rooms: the native lighting pass draws
-- each entity's light at its top-down screen position, so the player's
-- light circle wandered with the character. While the FPS scene covers the
-- view the player's light is offset to the screen centre (REPENTOGON:
-- a returned Vector overrides the render offset) and every other entity
-- and grid light, meaningless in first person, is not drawn (false).
if ModCallbacks.MC_PRE_RENDER_ENTITY_LIGHTING then
    mod:AddCallback(ModCallbacks.MC_PRE_RENDER_ENTITY_LIGHTING,function(_,entity)
        if not state.hideNativeMass then return end
        local p=player()
        if p and entity and entity.Type==EntityType.ENTITY_PLAYER and GetPtrHash(entity)==GetPtrHash(p) then
            local screen=Isaac.WorldToScreen(entity.Position)
            return Vector(Isaac.GetScreenWidth()/2-screen.X,Isaac.GetScreenHeight()/2-screen.Y)
        end
        return false
    end)
end
if ModCallbacks.MC_PRE_RENDER_GRID_LIGHTING then
    mod:AddCallback(ModCallbacks.MC_PRE_RENDER_GRID_LIGHTING,function()
        if state.hideNativeMass then return false end
    end)
end

-- The native collected-items list (right side) is replaced by our own HUD.
if ModCallbacks.MC_PRE_HISTORYHUD_RENDER then
    mod:AddCallback(ModCallbacks.MC_PRE_HISTORYHUD_RENDER, guard(function()
        if state.enabled then return false end
    end, 'PRE_HISTORYHUD'))
end

-- Replace only the native heart row; the rest of the player HUD stays native.
if ModCallbacks.MC_PRE_PLAYERHUD_RENDER_HEARTS then
    mod:AddCallback(ModCallbacks.MC_PRE_PLAYERHUD_RENDER_HEARTS, guard(function()
        if state.enabled then return true end
    end, 'PRE_HUD_HEARTS'))
end

-- Room/frame lifecycles run inside guard as well: an unguarded Lua error can
-- make the engine restart the room in a loop instead of surfacing one message.
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, guard(function()
    -- Look along native travel on entry; later mouse look remains free.
    resetCrawlspace(player())
    spriteCache.reset()
    shadowRoom,shadowAlpha=nil,nil
    diagnostics.suspend('new_room')
    state.roomFrame = game:GetFrameCount()
    state.roomTransition = false
    hud.resetCharge()
    settings.resetMenu()
    world.reset()
    state.map,state.cooldown,state.shotHistory=nil,0,{}
    if state.enabled then resetMouse() end
end, 'NEW_ROOM'))
if ModCallbacks.MC_PRE_ROOM_EXIT then
    mod:AddCallback(ModCallbacks.MC_PRE_ROOM_EXIT, guard(function()
        railHook.clear()
        if state.enabled then state.roomTransition = true end
    end, 'PRE_ROOM_EXIT'))
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, guard(function()
    if items.reset then items.reset() end
    spriteCache.reset()
    -- Mod Config Menu may load after this mod; register when a run starts.
    mcm.register(settings,locale)
    state.roomFrame = game:GetFrameCount()
    world.reset()
    release()
    state.yaw, state.pitch, state.cooldown, state.map, state.shotHistory = -math.pi / 2, 0, 0, nil, {}
    -- 0.5.97: the F6 hint shows at the start of a run, not permanently.
    state.startHintUntil = Isaac.GetTime()+START_HINT_MS
end, 'GAME_STARTED'))
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, guard(function() release();pickups.reset();cursor.update(false);cursor.mouseControl(false);gc.setActive(false) end, 'PRE_GAME_EXIT'))
-- A luamod reload or disabling the mod must not leave Mouse Control forced on.
if ModCallbacks.MC_PRE_MOD_UNLOAD then
    mod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, guard(function(_,unloaded)
        if unloaded==mod then cursor.update(false);cursor.mouseControl(false);gc.setActive(false) end
    end, 'PRE_MOD_UNLOAD'))
end

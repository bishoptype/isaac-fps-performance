-- Persistent camera settings. Since 0.5.26 they are edited in Mod Config
-- Menu (fps_mcm.lua) through get/set; the old F10 panel below (handle,
-- draw, capture) is archived and no longer opened by main.lua.
local maths=include('fps_math')
local locale=include('fps_locale')
local json=require('json')
local M={}
-- User's saved First Person sensitivity: 0.40 degrees per render pixel.
-- This renderer stores angles in radians; retain its existing settings controls.
local defaults={eye=32,fov=75,zoom=1,language='auto',sensitivity=math.rad(.40),reloadKey='KEY_R',gpu=true,reflexSight=true}
local values={eye=defaults.eye,fov=defaults.fov,zoom=defaults.zoom,language=defaults.language,sensitivity=defaults.sensitivity,
    reloadKey=defaults.reloadKey,gpu=defaults.gpu,reflexSight=defaults.reflexSight}
local ROWS=7
local capturing=false
local languages={'auto','zh','en'}
local languageNames={auto='自动 / Auto',zh='中文',en='English'}
local menu=false
local selected=1
local modRef

local function finite(value,fallback)
    if type(value)~='number' or value~=value or value==math.huge or value==-math.huge then return fallback end
    return value
end
local function clamp()
    values.eye=maths.clamp(finite(values.eye,defaults.eye),8,64)
    values.fov=maths.clamp(finite(values.fov,defaults.fov),40,130)
    values.zoom=maths.clamp(finite(values.zoom,defaults.zoom),.25,4)
    if not languageNames[values.language] then values.language=defaults.language end
    locale.setLanguage(values.language)
    values.sensitivity=maths.clamp(finite(values.sensitivity,defaults.sensitivity),.0002,.03)
    if type(values.reloadKey)~='string' or not (Keyboard and Keyboard[values.reloadKey])
        or values.reloadKey=='KEY_ESCAPE' then values.reloadKey=defaults.reloadKey end
    if type(values.gpu)~='boolean' then values.gpu=defaults.gpu end
    if type(values.reflexSight)~='boolean' then values.reflexSight=defaults.reflexSight end
end
local function loadDocument()
    if not modRef or type(modRef.LoadData)~='function' then return {} end
    local ok,raw=pcall(function() return modRef:LoadData() end)
    if not ok or type(raw)~='string' or raw=='' then return {} end
    local decodedOk,data=pcall(function() return json.decode(raw) end)
    return decodedOk and type(data)=='table' and data or {}
end

local function save()
    if not modRef or type(modRef.SaveData)~='function' or not json or type(json.encode)~='function' then return end
    local document=loadDocument()
    document.IsaacFPSProbeSettings={eye=values.eye,fov=values.fov,zoom=values.zoom,
        language=values.language,sensitivity=values.sensitivity,reloadKey=values.reloadKey,gpu=values.gpu,
        reflexSight=values.reflexSight}
    pcall(function() modRef:SaveData(json.encode(document)) end)
end

function M.init(mod)
    modRef=mod
    values={eye=defaults.eye,fov=defaults.fov,zoom=defaults.zoom,language=defaults.language,sensitivity=defaults.sensitivity,
        reloadKey=defaults.reloadKey,gpu=defaults.gpu,reflexSight=defaults.reflexSight}
    local document=loadDocument()
    local data=document.IsaacFPSProbeSettings
    if type(data)=='table' then
        values.eye=data.eye or values.eye
        values.fov=data.fov or values.fov
        values.zoom=data.zoom or values.zoom
        values.language=data.language or values.language
        values.sensitivity=data.sensitivity or values.sensitivity
        values.reloadKey=data.reloadKey or values.reloadKey
        if data.gpu~=nil then values.gpu=data.gpu end
        if data.reflexSight~=nil then values.reflexSight=data.reflexSight end
    end
    clamp()
    return values
end

local listeners={}
-- Called with the values table after every accepted change.
function M.onChange(fn) listeners[#listeners+1]=fn end
function M.get(name) return values[name] end
function M.values() return values end
-- Set one setting, clamp/validate it, save, and notify listeners.
function M.set(name,value)
    if values[name]==nil and name~='gpu' then return false end
    values[name]=value
    clamp();save()
    for _,fn in ipairs(listeners) do fn(values) end
    return true
end
M.defaults=defaults

function M.isOpen() return menu end
function M.close() menu=false;capturing=false end
function M.resetMenu() menu=false;selected=1;capturing=false end
function M.openOrClose()
    menu=not menu
    capturing=false
    return menu
end

-- Reload key binding (Keyboard enum name, default KEY_R).
function M.reloadKey() return Keyboard and Keyboard[values.reloadKey] or nil end
function M.keyLabel(name)
    name=name or values.reloadKey
    return (name:gsub('^KEY_',''):gsub('_',' '))
end
-- While capturing, the host feeds the next pressed key name here.
function M.capturing() return menu and capturing end
function M.capture(name)
    capturing=false
    if name and name~='KEY_ESCAPE' and Keyboard and Keyboard[name] then
        values.reloadKey=name;clamp();save()
    end
end
function M.changeSensitivity(factor)
    values.sensitivity=values.sensitivity*factor
    clamp();save()
end

function M.handle(up,down,left,right,reset,fine)
    if not menu then return end
    if capturing then return end
    if up then selected=(selected-2)%ROWS+1 end
    if down then selected=selected%ROWS+1 end
    if reset then
        if selected==1 then values.eye=defaults.eye
        elseif selected==2 then values.fov=defaults.fov
        elseif selected==3 then values.zoom=defaults.zoom
        elseif selected==4 then values.language=defaults.language
        elseif selected==5 then values.sensitivity=defaults.sensitivity
        elseif selected==7 then values.gpu=defaults.gpu
        else values.reloadKey=defaults.reloadKey end
        clamp();save()
    elseif left or right then
        local sign=right and 1 or -1
        if selected==1 then values.eye=values.eye+sign
        elseif selected==2 then values.fov=values.fov+sign*(fine and 1 or 5)
        elseif selected==3 then values.zoom=values.zoom+sign*(fine and .01 or .05)
        elseif selected==4 then
            for i,value in ipairs(languages) do
                if value==values.language then values.language=languages[(i-1+sign)%#languages+1];break end
            end
        elseif selected==6 then capturing=true;return
        elseif selected==7 then values.gpu=not values.gpu
        else
            local factor=fine and 1.05 or 1.2
            values.sensitivity=values.sensitivity*(sign>0 and factor or 1/factor)
        end
        clamp();save()
    end
end

function M.draw(width,height,drawRect)
    if not menu then return end
    local w,h=math.min(390,width-24),268
    local x,y=width/2-w/2,height/2-h/2
    drawRect(x,y,w,h,.03,.04,.06,.78)
    drawRect(x,y,w,1,.55,.8,.95,.6);drawRect(x,y+h-1,w,1,.55,.8,.95,.6)
    locale.render('settings_title',x+16,y+12,1,1,1,1)
    local rows={
        locale.text('settings_height',math.floor(values.eye+.5)),
        locale.text('settings_fov',values.fov),
        locale.text('settings_zoom',values.zoom),
        locale.text('settings_language',languageNames[values.language]),
        locale.text('settings_sensitivity',values.sensitivity),
        capturing and locale.text('settings_reload_wait') or locale.text('settings_reload',M.keyLabel()),
        locale.text('settings_render',locale.text(values.gpu and 'render_gpu' or 'render_cpu')),
    }
    for i,text in ipairs(rows) do
        local mark=i==selected and '> ' or '  '
        locale.draw(mark..text,x+22,y+38+(i-1)*24,1,1,1,1,i==4)
    end
    locale.render('settings_select',x+16,y+h-38,.75,.85,.95,1)
    locale.render('settings_adjust',x+16,y+h-20,.75,.85,.95,1)
end

return M

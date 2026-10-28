-- Lower-left half-heart grid. Display only: reads native health values each
-- render and never adds, removes or reorders hearts or changes damage rules.
-- Each heart is two cells (half hearts); special hearts keep their shell.
local M={}

-- REPENTOGON HealthType values; PlayerType fallbacks cover older runtimes.
local RED,SOUL,LOST,COIN,BONE=0,1,2,3,4
local typeHealth={[4]=SOUL,[10]=LOST,[12]=SOUL,[14]=COIN,[16]=BONE,[17]=SOUL,
    [25]=SOUL,[31]=LOST,[33]=COIN,[35]=BONE,[40]=SOUL}
local BETHANY,TAINTED_BETHANY=18,36
local CURSE_OF_THE_UNKNOWN=1<<3

local function call(object,name,...)
    local fn=object and object[name]
    if type(fn)~='function' then return nil end
    local ok,value=pcall(fn,object,...)
    if ok then return value end
    return nil
end

local function number(object,name,...)
    local value=call(object,name,...)
    return type(value)=='number' and value or 0
end

function M.healthType(p)
    local value=call(p,'GetHealthType')
    if type(value)=='number' then return value end
    return typeHealth[number(p,'GetPlayerType')] or RED
end

-- Build the ordered heart list. Cells hold 'red', 'rotten', 'soul', 'black',
-- 'coin' or 'empty'; a missing second cell marks a half container.
function M.model(p,curses)
    if not p then return {kind='none',hearts={}} end
    local health=M.healthType(p)
    local result={kind='hearts',health=health,hearts={},playerType=number(p,'GetPlayerType')}
    if type(curses)=='number' and (math.floor(curses) & CURSE_OF_THE_UNKNOWN)~=0 then
        result.kind='unknown'
        return result
    end
    if health==LOST then
        result.kind='lost'
        return result
    end
    local maxRed=math.max(0,number(p,'GetMaxHearts'))
    local red=math.max(0,number(p,'GetHearts'))
    local soul=math.max(0,number(p,'GetSoulHearts'))
    local blackMask=math.floor(number(p,'GetBlackHearts'))
    local bones=math.max(0,number(p,'GetBoneHearts'))
    local broken=math.max(0,number(p,'GetBrokenHearts'))
    local rotten=math.max(0,number(p,'GetRottenHearts'))
    local golden=math.max(0,number(p,'GetGoldenHearts'))
    local eternal=math.max(0,number(p,'GetEternalHearts'))
    local hearts=result.hearts
    local fillKind=health==COIN and 'coin' or 'red'
    -- Red-capable hearts in display order: containers, then bones by slot.
    local redSlots={}
    local containers=math.ceil(maxRed/2)
    for i=1,containers do
        local half=(i==containers and maxRed%2==1)
        local heart={shell=health==COIN and 'coin' or 'red',cells={'empty',not half and 'empty' or nil}}
        hearts[#hearts+1]=heart
        redSlots[#redSlots+1]=heart
    end
    -- Soul/bone slots interleave in native slot order when it is queryable.
    local soulHearts=math.ceil(soul/2)
    local slots=soulHearts+bones
    local order={}
    local counted=0
    if type(p.IsBoneHeart)=='function' then
        for slot=0,slots-1 do
            local isBone=call(p,'IsBoneHeart',slot)==true
            order[#order+1]=isBone
            if isBone then counted=counted+1 end
        end
    end
    if #order~=slots or counted~=bones then
        order={}
        for i=1,soulHearts do order[i]=false end
        for i=1,bones do order[soulHearts+i]=true end
    end
    local soulIndex,soulLeft=0,soul
    for _,isBone in ipairs(order) do
        if isBone then
            local heart={shell='bone',cells={'empty','empty'}}
            hearts[#hearts+1]=heart
            redSlots[#redSlots+1]=heart
        else
            -- GetSoulHearts already includes black hearts; the mask marks which.
            local black=((blackMask>>soulIndex)&1)==1
            local kind=black and 'black' or 'soul'
            local heart={shell=kind,cells={kind,soulLeft>=2 and kind or nil}}
            soulLeft=soulLeft-2
            soulIndex=soulIndex+1
            hearts[#hearts+1]=heart
        end
    end
    -- GetHearts counts red inside bone hearts too: fill containers, then bones.
    local left=red
    for _,heart in ipairs(redSlots) do
        for c=1,2 do
            if heart.cells[c] and left>0 then heart.cells[c]=fillKind;left=left-1 end
        end
    end
    -- Rotten hearts are whole hearts at the end of the red health.
    local rottenLeft=math.min(rotten,math.floor(red/2))
    for i=#redSlots,1,-1 do
        if rottenLeft<=0 then break end
        local heart=redSlots[i]
        if heart.cells[1]==fillKind and heart.cells[2]==fillKind and fillKind=='red' then
            heart.cells[1],heart.cells[2]='rotten','rotten'
            heart.rotten=true
            rottenLeft=rottenLeft-1
        end
    end
    -- Eternal marks the last filled red container (otherwise the first heart).
    if eternal>0 and #hearts>0 then
        local owner
        for i=containers,1,-1 do
            if hearts[i].cells[1]~='empty' then owner=hearts[i];break end
        end
        (owner or hearts[1]).eternal=true
    end
    -- Golden overlays sit on the rightmost filled hearts.
    local goldLeft=golden
    for i=#hearts,1,-1 do
        if goldLeft<=0 then break end
        if hearts[i].cells[1]~='empty' then hearts[i].gold=true;goldLeft=goldLeft-1 end
    end
    for _=1,broken do hearts[#hearts+1]={shell='broken',cells={'broken','broken'}} end
    local playerType=result.playerType
    if playerType==BETHANY then result.soulCharge=number(p,'GetSoulCharge') end
    if playerType==TAINTED_BETHANY then result.bloodCharge=number(p,'GetBloodCharge') end
    return result
end

-- Forgotten/Soul pairs: the other form is shown as a separate, dimmed row.
local paired={[16]=true,[17]=true,[35]=true,[40]=true}
function M.forPlayer(p,curses)
    local model=M.model(p,curses)
    if model.kind=='hearts' and paired[model.playerType] then
        local sub=call(p,'GetSubPlayer')
        if sub then model.sub=M.model(sub,curses) end
    end
    return model
end

-- Total half-hearts of actual health; used for a damage flash only.
function M.total(model)
    local total=0
    for _,heart in ipairs(model.hearts or {}) do
        for c=1,2 do
            local cell=heart.cells[c]
            if cell and cell~='empty' and cell~='broken' then total=total+1 end
        end
    end
    return total
end

local palette={
    red={.86,.1,.13},rotten={.48,.56,.24},soul={.36,.58,.96},black={.22,.16,.28},
    coin={.96,.76,.2},empty={.22,.08,.09},broken={.38,.38,.4},
}
-- Outline colour per heart container.
local shells={red={.08,.02,.03},bone={.92,.89,.8},soul={.06,.1,.22},black={.5,.28,.68},
    coin={.45,.3,.05},broken={.62,.62,.64}}

-- 0.5.73 pixel hearts (user: the boxes looked ugly). A 9x8 heart bitmap;
-- the left half (columns 0-4) and right half (4-8) take the two cells, so a
-- half heart fills one side. Drawn as horizontal runs: the outline is the
-- shape grown by one pixel, then the fill, then a highlight.
local HEART={
    '.XX...XX.',
    'XXXX.XXXX',
    'XXXXXXXXX',
    'XXXXXXXXX',
    '.XXXXXXX.',
    '..XXXXX..',
    '...XXX...',
    '....X....',
}
local HW,HH=#HEART[1],#HEART
local function filled(x,y)
    local row=HEART[y+1]
    return row~=nil and x>=0 and x<HW and row:sub(x+1,x+1)=='X'
end
-- Runs per row as {y,x1,x2} (inclusive), for the shape and its outline.
local fillRuns,outlineRuns={},{}
for y=0,HH-1 do
    local x=0
    while x<HW do
        if filled(x,y) then
            local x2=x
            while filled(x2+1,y) do x2=x2+1 end
            fillRuns[#fillRuns+1]={y,x,x2}
            x=x2+1
        else x=x+1 end
    end
end
for y=-1,HH do
    local x=-1
    while x<=HW do
        local function near(px)
            return filled(px,y) or filled(px-1,y) or filled(px+1,y) or filled(px,y-1) or filled(px,y+1)
        end
        if near(x) then
            local x2=x
            while x2+1<=HW and near(x2+1) do x2=x2+1 end
            outlineRuns[#outlineRuns+1]={y,x,x2}
            x=x2+1
        else x=x+1 end
    end
end
local MID=4                 -- the shared centre column
M.HEART_W,M.HEART_H=HW,HH

-- 0.5.85 (user: hearts should flash like Minecraft): a hurt blinks the
-- outlines white for HURT_MS (BLINK_MS on/off), the half-hearts just lost
-- show white and blink until then, and at LOW_HEALTH half-hearts or less the
-- hearts jiggle by a pixel.
M.HURT_MS,M.BLINK_MS,M.LOW_HEALTH,M.JIGGLE_MS=1000,120,2,90
local WHITE_SHELL={1,1,1}
local GHOST={1,1,1}

local function drawHeartRaw(rect,hx,hy,cells,shell,heart,ghost)
    for _,run in ipairs(outlineRuns) do
        rect(hx+run[2],hy+run[1],run[3]-run[2]+1,1,shell[1],shell[2],shell[3],1)
    end
    for _,run in ipairs(fillRuns) do
        local y,x1,x2=run[1],run[2],run[3]
        for side=1,2 do
            local a,b=side==1 and x1 or math.max(x1,MID+1),side==1 and math.min(x2,MID) or x2
            -- A single-cell heart (one half) is drawn full width.
            local cell=cells[side] or cells[1]
            if a<=b and cell then
                local c=palette[cell] or palette.empty
                if ghost and ghost[side] and (cell=='empty' or cell=='ghost') then c=GHOST end
                rect(hx+a,hy+y,b-a+1,1,c[1],c[2],c[3],1)
            end
        end
    end
    -- Shine on the upper left lobe (not on empty hearts).
    if cells[1] and cells[1]~='empty' and cells[1]~='broken' then
        rect(hx+1,hy+1,2,1,1,1,1,.55)
    end
    if heart.shell=='broken' or cells[1]=='broken' then
        for i=0,HH-2 do rect(hx+MID+((i%2==0) and 0 or 1)-((i%4==2) and 1 or 0),hy+i,1,1,.12,.12,.13,1) end
    end
    if heart.gold then
        for _,run in ipairs(outlineRuns) do
            if run[1]<=0 then rect(hx+run[2],hy+run[1],run[3]-run[2]+1,1,1,.85,.2,1) end
        end
    end
    if heart.eternal then rect(hx+HW-3,hy+1,2,2,1,1,1,1) end
end

-- Compile static heart styles once, joining adjacent equal-colour rectangles.
-- This keeps every pixel/blink/gold/broken overlay while reducing native draw
-- calls. Cache relative coordinates so low-health jiggle still moves freely.
local heartRecipes,recipeCount={},0
local function sameColor(a,b)
    return a[5]==b[5] and a[6]==b[6] and a[7]==b[7] and a[8]==b[8]
end
local function drawHeart(rect,hx,hy,cells,shell,heart,ghost)
    local key=table.concat({cells[1] or '',cells[2] or '',shell[1],shell[2],shell[3],
        heart.shell or '',heart.gold and 1 or 0,heart.eternal and 1 or 0,
        ghost and ghost[1] and 1 or 0,ghost and ghost[2] and 1 or 0},':')
    local recipe=heartRecipes[key]
    if not recipe then
        local rows={}
        drawHeartRaw(function(x,y,w,h,r,g,b,a)
            local v={x,y,w,h,r,g,b,a}
            local last=rows[#rows]
            if last and sameColor(last,v) and last[2]==y and last[4]==h and last[1]+last[3]==x then
                last[3]=last[3]+w
            else rows[#rows+1]=v end
        end,0,0,cells,shell,heart,ghost)
        recipe={}
        for _,v in ipairs(rows) do
            local last=recipe[#recipe]
            if last and sameColor(last,v) and last[1]==v[1] and last[3]==v[3] and last[2]+last[4]==v[2] then
                last[4]=last[4]+v[4]
            else recipe[#recipe+1]=v end
        end
        if recipeCount>=128 then heartRecipes={};recipeCount=0 end
        heartRecipes[key]=recipe;recipeCount=recipeCount+1
    end
    for _,v in ipairs(recipe) do
        rect(hx+v[1],hy+v[2],v[3],v[4],v[5],v[6],v[7],v[8])
    end
end

M.layout={heartGap=2,perRow=10,rowGap=3,pad=4}

function M.size(model)
    local L=M.layout
    local count=math.max(1,#(model.hearts or {}))
    if model.kind~='hearts' then count=3 end
    local perRow=math.min(L.perRow,count)
    local rows=math.ceil(count/L.perRow)
    local width=perRow*(HW+L.heartGap)-L.heartGap
    local height=rows*HH+(rows-1)*L.rowGap
    return width,height
end

-- Draw the grid with its bottom-left corner at (x,bottom). rect(x,y,w,h,r,g,b,a).
function M.draw(model,x,bottom,rect,text,state,now)
    local L=M.layout
    local width,height=M.size(model)
    local extra=(model.soulCharge or model.bloodCharge) and 10 or 0
    local top=bottom-height-extra
    local hurt=state and state.hurtUntil and now and now<state.hurtUntil
    local blink=hurt and math.floor((state.hurtUntil-now)/M.BLINK_MS)%2==0
    rect(x-L.pad,top-L.pad,width+L.pad*2,height+extra+L.pad*2,.03,.02,.03,.45)
    if model.kind=='lost' or model.kind=='unknown' then
        local label=model.kind=='lost' and 'LOST' or '?'
        text(label,x,top-1,.85,.85,.9,1)
        return width+L.pad*2,height+extra+L.pad*2
    end
    local lost=hurt and blink and state.lostCells or nil
    local low=M.total(model)<=M.LOW_HEALTH
    local tick=now and math.floor(now/M.JIGGLE_MS) or 0
    local count=#model.hearts
    -- Lost soul/black hearts are gone from the model: their ghosts stay.
    if lost then count=math.max(count,#lost) end
    for index=1,count do
        local heart=model.hearts[index] or {cells={'ghost','ghost'},shell='soul'}
        local column=(index-1)%L.perRow
        local row=math.floor((index-1)/L.perRow)
        local hx=x+column*(HW+L.heartGap)
        local hy=top+row*(HH+L.rowGap)
        if low then hy=hy+((tick*7+index*13)%3)-1 end
        local shell=shells[heart.rotten and 'red' or heart.shell] or shells.red
        if blink then shell=WHITE_SHELL end
        local cells={heart.cells[1],heart.cells[2]}
        if heart.rotten and cells[1]=='red' then cells[1]='rotten' end
        local ghost=lost and lost[index]
        if model.hearts[index] or ghost then drawHeart(rect,hx,hy,cells,shell,heart,ghost) end
    end
    if model.sub and model.sub.kind=='hearts' then
        -- Other form: compact one-row strip above the main grid.
        local sx=x
        for _,heart in ipairs(model.sub.hearts) do
            for c=1,2 do
                local cell=heart.cells[c]
                if cell then
                    local color=palette[cell] or palette.empty
                    rect(sx,top-L.pad-4,2,3,color[1],color[2],color[3],.75)
                    sx=sx+3
                end
            end
            sx=sx+1
        end
    end
    if model.soulCharge then text(string.format('%d',model.soulCharge),x,bottom-9,.55,.75,1,1) end
    if model.bloodCharge then text(string.format('%d',model.bloodCharge),x,bottom-9,1,.35,.35,1) end
    return width+L.pad*2,height+extra+L.pad*2
end

local function filledCell(cell) return cell~=nil and cell~='empty' and cell~='broken' end
local function snapshot(model)
    local cells={}
    for index,heart in ipairs(model.hearts or {}) do cells[index]={heart.cells[1],heart.cells[2]} end
    return cells
end

-- A hurt (from the damage callback, or a drop in the visible total) starts
-- the blink and marks the half-hearts that were full before it.
function M.hurt(state,now)
    state.hurtUntil=now+M.HURT_MS
    state.hurtAt=now
    state.pendingLoss=true
end

-- Track health per owner; reset on owner change.
function M.track(state,model,owner,now)
    local total=M.total(model)
    if state.owner~=owner then
        state.owner,state.total,state.hurtUntil,state.lostCells=owner,total,nil,nil
        state.cells=snapshot(model)
    end
    if state.total and total<state.total and not (state.hurtUntil and now<state.hurtUntil and not state.pendingLoss) then
        M.hurt(state,now)
    end
    local current=snapshot(model)
    if state.pendingLoss and state.cells and total<(state.total or total) then
        local lost={}
        for index,before in ipairs(state.cells) do
            local after=current[index] or {}
            local mark
            for c=1,2 do
                if filledCell(before[c]) and not filledCell(after[c]) then mark=mark or {};mark[c]=true end
            end
            lost[index]=mark or false
        end
        state.lostCells=lost
        state.pendingLoss=false
    end
    if state.hurtUntil and now>=state.hurtUntil then state.lostCells,state.pendingLoss=nil,false end
    state.cells=current
    state.total=total
end

-- 0.5.85 (user: a hurt needs a visible cue even when a curse hides the
-- health): a red vignette from the screen edges that fades over SCREEN_MS.
M.SCREEN_MS,M.SCREEN_BANDS,M.SCREEN_DEPTH=450,8,.16
function M.drawHurtScreen(sw,sh,rect,state,now)
    local since=state and state.hurtAt and now and now-state.hurtAt
    if not since or since<0 or since>=M.SCREEN_MS then return 0 end
    local a=(1-since/M.SCREEN_MS)^1.5
    local depth=math.min(sw,sh)*M.SCREEN_DEPTH
    local band=depth/M.SCREEN_BANDS
    local draws=0
    for i=0,M.SCREEN_BANDS-1 do
        local alpha=a*.42*(1-i/M.SCREEN_BANDS)^2
        local o=i*band
        rect(o,o,sw-2*o,band,.75,0,0,alpha)
        rect(o,sh-o-band,sw-2*o,band,.75,0,0,alpha)
        rect(o,o+band,band,sh-2*o-2*band,.75,0,0,alpha)
        rect(sw-o-band,o+band,band,sh-2*o-2*band,.75,0,0,alpha)
        draws=draws+4
    end
    rect(0,0,sw,sh,.6,0,0,a*.1)
    return draws+1
end

return M

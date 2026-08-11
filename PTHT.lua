
local CREDIT = "RPS"
local FOUNDER_ROLE = 1000
local ALLOWED_ROLES = {
    998,    
    777,    
    1000,   
}

local BGL_ID = 7188
local DL_ID  = 1796
local UGL_ID = 8470
local DEF_ICON      = 5640
local PROVIDER_ICON = 3044

local DEF_COST     = 0
local DEF_COSTTYPE = "none"
local K_CFG_COST     = "PTHT2_CFG_COST"
local K_CFG_COSTTYPE = "PTHT2_CFG_COSTTYPE"
local K_CFG_ICON     = "PTHT2_CFG_ICON"
local K_CFG_DELAY    = "PTHT2_CFG_DELAY"
local DEF_DELAY      = 0        
local K_CFG_BATCH    = "PTHT2_CFG_BATCH"
local DEF_BATCH      = 400      
local SPRAY_ID       = 5926     

local function stripColors(s)
    if type(s) ~= "string" then return "" end
    return (s:gsub("`.", ""))
end
local function normName(s)
    s = stripColors(s or "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s:upper()
end
local function getGrowID(player)
    local cand = { "getRawName", "getLoginName", "getGrowID", "getName" }
    for _, m in ipairs(cand) do
        local ok, v = pcall(function() return player[m](player) end)
        if ok and type(v) == "string" and v ~= "" then return normName(v) end
    end
    return ""
end
local function isWhitelisted(player)
    local gid = getGrowID(player)
    if gid == "" then return false end
    return loadDataFromServer("PTHT2_WL_" .. gid) == "1"
end

local K_WL_INDEX = "PTHT2_WL_INDEX"
local function getPremiumList()
    local raw = loadDataFromServer(K_WL_INDEX)
    if type(raw) ~= "string" or raw == "" then return {} end
    local t = {}
    for gid in string.gmatch(raw, "[^\n]+") do
        if gid ~= "" then t[#t + 1] = gid end
    end
    return t
end
local function savePremiumList(list)
    saveDataToServer(K_WL_INDEX, table.concat(list, "\n"))
end
local function indexOfGid(list, gid)
    for i, v in ipairs(list) do if v == gid then return i end end
    return 0
end
local function ensureIndexed(gid)
    if gid == "" then return end
    local list = getPremiumList()
    if indexOfGid(list, gid) == 0 then
        table.insert(list, gid)
        savePremiumList(list)
    end
end
local function addPremium(gid)
    if gid == "" then return end
    saveDataToServer("PTHT2_WL_" .. gid, "1")
    ensureIndexed(gid)
end
local function removePremium(gid)
    if gid == "" then return end
    saveDataToServer("PTHT2_WL_" .. gid, "0")
    local list = getPremiumList()
    local i = indexOfGid(list, gid)
    if i > 0 then
        table.remove(list, i)
        savePremiumList(list)
    end
end

local function canUsePTHT(player)
    local r = player:getRole()
    for _, id in ipairs(ALLOWED_ROLES) do
        if r == id then return true end
    end
    if player:hasRole(1000) then return true end
    if isWhitelisted(player) then
        ensureIndexed(getGrowID(player))
        return true
    end
    return false
end
local function denyMsg(player)
    player:onConsoleMessage("`4[PTHT2] Access denied! Only Red Staff, Give, Founder, or whitelisted players.")
end

local function getCost()
    local v = tonumber(loadDataFromServer(K_CFG_COST))
    if not v or v < 0 then v = DEF_COST end
    return math.floor(v)
end
local function getCostType()
    local v = loadDataFromServer(K_CFG_COSTTYPE)
    if v == "gems" or v == "bgl" or v == "dl" or v == "ugl" or v == "none" then return v end
    return DEF_COSTTYPE
end
local function getIconId()
    local v = tonumber(loadDataFromServer(K_CFG_ICON))
    if not v or v <= 0 then v = DEF_ICON end
    return math.floor(v)
end
local function getDelaySec()
    local v = tonumber(loadDataFromServer(K_CFG_DELAY))
    if not v or v < 0 then v = DEF_DELAY end
    return math.floor(v)
end
local function lockInfo(ct)
    if ct == "bgl" then return BGL_ID, "BGL"
    elseif ct == "dl" then return DL_ID, "DL"
    elseif ct == "ugl" then return UGL_ID, "UGL" end
    return 0, ""
end
local function costLabel()
    local ct = getCostType()
    if ct == "none" then return "Free" end
    if ct == "gems" then return getCost() .. " Gems" end
    local _, nm = lockInfo(ct)
    return getCost() .. " " .. nm
end
local function gemsOf(player)
    local ok, g = pcall(function() return player:getGems() end)
    if ok and type(g) == "number" then return g end
    return 0
end
local function itemAmount(player, id)
    local ok, n = pcall(function() return player:getItemAmount(id) end)
    if ok and type(n) == "number" then return n end
    return 0
end
local function bankKey(gid) return "MYBANK_" .. gid end
local function getBank(gid)
    if gid == "" then return 0 end
    local n = tonumber(loadDataFromServer(bankKey(gid)))
    if not n then n = 0 end
    return math.floor(n)
end
local function setBank(gid, n)
    if gid == "" then return end
    n = math.floor(n)
    if n < 0 then n = 0 end
    saveDataToServer(bankKey(gid), tostring(n))
end
local function chargeCost(player)
    local ct = getCostType()
    if ct == "none" then return true end
    local cost = getCost()
    if cost <= 0 then return true end
    if ct == "gems" then
        local have = gemsOf(player)
        local gid  = getGrowID(player)
        local bank = getBank(gid)
        if have + bank < cost then
            player:onConsoleMessage("`4[PTHT2] Not enough Gems + Bank! Need `e" .. cost .. "`4.")
            return false
        end
        local fromBank = 0
        if have < cost then
            fromBank = cost - have
            pcall(function() player:addGems(fromBank) end)
            setBank(gid, bank - fromBank)
        end
        local ok = pcall(function() player:removeGems(cost, 1, 0) end)
        if not ok then
            if fromBank > 0 then setBank(gid, getBank(gid) + fromBank) end
            player:onConsoleMessage("`4[PTHT2] Failed to deduct gems.")
            return false
        end
        return true
    end
    local id, nm = lockInfo(ct)
    local have = itemAmount(player, id)
    if have < cost then
        player:onConsoleMessage("`4[PTHT2] Not enough " .. nm .. "! Need `e" .. cost .. "`4.")
        return false
    end
    local ok = pcall(function() player:changeItem(id, -cost) end)
    if not ok then
        player:onConsoleMessage("`4[PTHT2] Failed to take " .. nm .. ".")
        return false
    end
    return true
end

local session = {}
local function getState(player)
    local uid = player:getUserID()
    if not session[uid] then
        session[uid] = { plantedCount = 0, harvestCount = 0, loop = 0,
                         providerID = 0, autoProv = false, providerHarvest = 0,
                         autoSpray = false, lastUse = 0 }
    end
    local s = session[uid]
    if s.providerID == nil then s.providerID = 0 end
    if s.autoProv == nil then s.autoProv = false end
    if s.providerHarvest == nil then s.providerHarvest = 0 end
    if s.autoSpray == nil then s.autoSpray = false end
    if s.lastUse == nil then s.lastUse = 0 end
    return s
end

local function delayRemain(player)
    local d = getDelaySec()
    if d <= 0 then return 0 end
    local st = getState(player)
    local rem = d - (os.time() - (st.lastUse or 0))
    if rem < 0 then rem = 0 end
    return rem
end
local function checkDelay(player)
    if player:hasRole(FOUNDER_ROLE) then return true end
    local rem = delayRemain(player)
    if rem > 0 then
        player:onConsoleMessage("`4[PTHT2] Please wait `e" .. rem .. "s`4 before using /ptht2 again.")
        return false
    end
    return true
end
local function markUse(player)
    getState(player).lastUse = os.time()
end

local schedulerAvailable =
    (type(timer) == "table" and type(timer.setTimeout) == "function")
    or (type(setTimeout) == "function")

local function schedule(fn, sec)
    if type(timer) == "table" and type(timer.setTimeout) == "function" then
        pcall(function() timer.setTimeout(sec, fn) end)
    elseif type(setTimeout) == "function" then
        pcall(function() setTimeout(sec, fn) end)
    end
end

local AUTO_INTERVAL_SEC = 5
local autoProvPlayers = {}
local autoSprayPlayers = {}
local autoLoopRunning = false

local function doPlantAll(world, player)
    if not world:hasAccess(player) then
        player:onConsoleMessage("`4[PTHT2] You don't have access here.")
        return
    end
    local seed = world:getMagplantSeed(player)
    if seed == 0 then
        player:onConsoleMessage("`4[PTHT2] Take your Magplant Remote first!")
        return
    end
    local st, planted = getState(player), 0
    for _, t in ipairs(world:getTiles()) do
        if world:getMagplantStock(player) <= 0 then break end
        if t:getTileForeground() == 0 then
            if world:plantFromMagplant(player, t) then planted = planted + 1 end
        end
    end
    st.plantedCount = st.plantedCount + planted
    player:onConsoleMessage("`2[PTHT2] `oPlanted `2" .. planted .. "`o seeds (ID " .. seed .. ") | stock left: `2" .. world:getMagplantStock(player))
end

local function getBatch()
    local v = tonumber(loadDataFromServer(K_CFG_BATCH))
    if v == nil or v < 0 then v = DEF_BATCH end
    return math.floor(v)
end
local harvestJobs = {}             

local function harvestPass(world, player, seed, limit)
    local hits = 0
    for _, t in ipairs(world:getTiles()) do
        if limit and hits >= limit then break end
        local fg = t:getTileForeground()
        if fg ~= 0 and (seed == 0 or fg == seed) then
            if world:punchTile(t, player) then hits = hits + 1 end
        end
    end
    return hits
end

local function finishHarvest(player, job)
    getState(player).harvestCount = getState(player).harvestCount + job.total
    player:onConsoleMessage("`2[PTHT2] `oHarvest done: `2" .. job.total .. "`o tiles cleared.")
    if job.andPlant then
        local ok, world = pcall(function() return player:getWorld() end)
        if ok and world then doPlantAll(world, player) end
    end
end

local function harvestStep(player)
    local uid = player:getUserID()
    local job = harvestJobs[uid]
    if not job then return end
    local ok, world = pcall(function() return player:getWorld() end)
    if not ok or not world or not world:hasAccess(player) then
        harvestJobs[uid] = nil
        return
    end
    local batch = getBatch()
    if batch <= 0 then batch = nil end   
    local hits = harvestPass(world, player, job.seed, batch)
    job.total = job.total + hits
    if hits > 0 then
        schedule(function() harvestStep(player) end, 1)   
    else
        harvestJobs[uid] = nil
        finishHarvest(player, job)
    end
end

local function doHarvestAll(world, player, andPlant)
    if not world:hasAccess(player) then
        player:onConsoleMessage("`4[PTHT2] You don't have access here.")
        return
    end
    local seed = world:getMagplantSeed(player)
    if seed == 0 then
        player:onConsoleMessage("`4[PTHT2] Take your Magplant Remote first!")
        return
    end
    local uid = player:getUserID()
    if harvestJobs[uid] then
        player:onConsoleMessage("`e[PTHT2] Harvest is already running, please wait...")
        return
    end
    if schedulerAvailable then
        harvestJobs[uid] = { seed = seed, total = 0, andPlant = andPlant }
        player:onConsoleMessage("`2[PTHT2] `oHarvesting... `8(batched)")
        harvestStep(player)
    else
        local st, harvested, passes = getState(player), 0, 0
        repeat
            local hits = harvestPass(world, player, seed, nil)
            harvested = harvested + hits
            passes = passes + 1
        until hits == 0 or passes >= 30
        st.harvestCount = st.harvestCount + harvested
        player:onConsoleMessage("`2[PTHT2] `oHarvested `2" .. harvested .. "`o tiles (`2" .. passes .. "`o passes).")
        if andPlant then doPlantAll(world, player) end
    end
end

local function harvestProviders(world, player, id, silent)
    if not world:hasAccess(player) then
        if not silent then player:onConsoleMessage("`4[PTHT2] You don't have access here.") end
        return 0
    end
    if not id or id <= 0 then
        if not silent then player:onConsoleMessage("`4[PTHT2] Set a Provider ID first.") end
        return 0
    end
    local got = 0
    for _, t in ipairs(world:getTiles()) do
        if t:getTileForeground() == id then
            if world:punchTile(t, player) then got = got + 1 end
        end
    end
    local st = getState(player)
    st.providerHarvest = (st.providerHarvest or 0) + got
    if not silent and got > 0 then
        player:onConsoleMessage("`2[PTHT2] `oProvider harvested `2" .. got .. "`o blocks (ID " .. id .. ").")
    end
    return got
end

local function useUltraSpray(world, player, silent)
    local have = itemAmount(player, SPRAY_ID)
    if have <= 0 then
        if not silent then player:onConsoleMessage("`4[PTHT2] No Ultra World Spray (5926) in your inventory.") end
        return false
    end
    local applied = false
    local cands = {
        function() return world:useItem(player, SPRAY_ID) end,
        function() return player:useItem(SPRAY_ID) end,
        function() return world:applyWorldSpray(player, SPRAY_ID) end,
        function() return world:useWorldSpray(player) end,
        function() return world:spray(player, SPRAY_ID) end,
    }
    for _, fn in ipairs(cands) do
        local ok, res = pcall(fn)
        if ok and res ~= false and res ~= nil then applied = true break end
    end
    if not applied then
        pcall(function() player:changeItem(SPRAY_ID, -1) end)
    end
    if not silent then
        player:onConsoleMessage("`2[PTHT2] `oUsed Ultra World Spray. Left: `2" .. itemAmount(player, SPRAY_ID))
    end
    return true
end

local function providerTick()
    for uid, player in pairs(autoSprayPlayers) do
        local st = session[uid]
        if st and st.autoSpray then
            local ok, world = pcall(function() return player:getWorld() end)
            if ok and world then
                pcall(function() useUltraSpray(world, player, true) end)
            end
        else
            autoSprayPlayers[uid] = nil
        end
    end
    for uid, player in pairs(autoProvPlayers) do
        local st = session[uid]
        if st and st.autoProv and st.providerID and st.providerID > 0 then
            local ok, world = pcall(function() return player:getWorld() end)
            if ok and world then
                pcall(function() harvestProviders(world, player, st.providerID, true) end)
            end
        else
            autoProvPlayers[uid] = nil
        end
    end
    schedule(providerTick, AUTO_INTERVAL_SEC)
end

local function ensureAutoLoop()
    if autoLoopRunning then return end
    if not schedulerAvailable then return end
    autoLoopRunning = true
    schedule(providerTick, AUTO_INTERVAL_SEC)
end

local function showPanel(world, player)
    local st    = getState(player)
    local seed  = world:getMagplantSeed(player)
    local stock = world:getMagplantStock(player)
    local icon  = getIconId()
    local d = ""
    d = d .. "set_default_color|`o\n"
    d = d .. "add_label_with_icon|big|`ePTHT2 - Auto Farm``|left|" .. icon .. "|\n"
    d = d .. "add_smalltext|`oMass Plant & Harvest + Harvest Provider. Cost per action: `2" .. costLabel() .. "`o.``|left|\n"
    d = d .. "add_smalltext|`6Hold your Magplant Remote to link a seed first.``|left|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_label_with_icon|small|`oSeed: `2" .. seed .. " `o| Stock: `2" .. stock .. "|left|" .. icon .. "|\n"
    d = d .. "add_label_with_icon|small|`oPlanted: `2" .. st.plantedCount .. " `o| Harvested: `2" .. st.harvestCount .. "|left|" .. icon .. "|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_label_with_icon|small|`oPlant from Magplant|left|" .. icon .. "|\n"
    d = d .. "add_button|ptht_plant|`2MASS PLANT|noflags|0|0|\n"
    d = d .. "add_label_with_icon|small|`oHarvest from Magplant|left|" .. icon .. "|\n"
    d = d .. "add_button|ptht_harvest|`2MASS HARVEST|noflags|0|0|\n"
    d = d .. "add_button|ptht_both|`5PLANT + HARVEST (LOOP)|noflags|0|0|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_label_with_icon|small|`oAuto Ultra World Spray (5926)|left|" .. SPRAY_ID .. "|\n"
    d = d .. "add_button|ptht_spray_now|`2USE ULTRA SPRAY (Once)|noflags|0|0|\n"
    d = d .. "add_button|ptht_spray_auto|" .. (st.autoSpray and "`4AUTO SPRAY: ON (tap = OFF)" or "`2AUTO SPRAY: OFF (tap = ON)") .. "|noflags|0|0|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_button|ptht_reset|`eRESET STATS|noflags|0|0|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_label_with_icon|small|`oHarvest Provider|left|" .. PROVIDER_ICON .. "|\n"
    d = d .. "add_smalltext|`oEnter the Provider block ID, then SET.``|left|\n"
    d = d .. "add_smalltext|`6Provider ID reference:``|left|\n"
    d = d .. "add_label_with_icon|small|`o872 = Chicken|left|872|\n"
    d = d .. "add_label_with_icon|small|`o866 = Cow|left|866|\n"
    d = d .. "add_label_with_icon|small|`o928 = Science|left|928|\n"
    d = d .. "add_label_with_icon|small|`o3044 = Tackle|left|3044|\n"
    d = d .. "add_label_with_icon|small|`o6212 = Surgical Tool Bag|left|6212|\n"
    d = d .. "add_text_input|prov_id|Enter Provider ID|" .. tostring(st.providerID or 0) .. "|8|\n"
    d = d .. "add_button|ptht_prov_set|`bSET PROVIDER ID|noflags|0|0|\n"
    d = d .. "add_button|ptht_prov_now|`2HARVEST PROVIDER (Once)|noflags|0|0|\n"
    d = d .. "add_button|ptht_prov_auto|" .. (st.autoProv and "`4AUTO PROVIDER: ON (click = OFF)" or "`2AUTO PROVIDER: OFF (click = ON)") .. "|noflags|0|0|\n"
    d = d .. "add_label_with_icon|small|`6Provider ID: `2" .. tostring(st.providerID or 0) .. " `o| Auto: " .. (st.autoProv and "`2ON" or "`4OFF") .. " `o| Total: `2" .. tostring(st.providerHarvest or 0) .. "|left|" .. PROVIDER_ICON .. "|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_label_with_icon|small|`6" .. CREDIT .. "``|left|" .. icon .. "|\n"
    d = d .. "end_dialog|ptht_panel|Close||\n"
    player:onDialogRequest(d)
end

local function showManage(player)
    local icon = getIconId()
    local d = "set_default_color|`o\n"
    d = d .. "add_label_with_icon|big|`eManage PTHT2``|left|" .. icon .. "|\n"
    d = d .. "add_smalltext|`oCurrent cost: `2" .. costLabel() .. "`o. Pick a cost type:``|left|\n"
    d = d .. "add_button|mptht2_ct_gems|`2Cost: GEMS|noflags|0|0|\n"
    d = d .. "add_button|mptht2_ct_bgl|`9Cost: BGL (7188)|noflags|0|0|\n"
    d = d .. "add_button|mptht2_ct_dl|`bCost: Diamond Lock (1796)|noflags|0|0|\n"
    d = d .. "add_button|mptht2_ct_ugl|`eCost: UGL (8470)|noflags|0|0|\n"
    d = d .. "add_button|mptht2_ct_none|`8Cost: NONE (Free)|noflags|0|0|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_text_input|mp_cost|Cost Amount:|" .. getCost() .. "|10|\n"
    d = d .. "add_text_input|mp_icon|Magplant Icon ID:|" .. icon .. "|8|\n"
    d = d .. "add_text_input|mp_delay|Use Delay (seconds, 0 = none):|" .. getDelaySec() .. "|6|\n"
    d = d .. "add_text_input|mp_batch|Harvest Speed (tiles/sec, 0 = all at once):|" .. getBatch() .. "|6|\n"
    d = d .. "add_button|mptht2_save|`2SAVE SETTINGS|noflags|0|0|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_button|mptht2_listprem|`bList Premium|noflags|0|0|\n"
    d = d .. "add_label_with_icon|small|`6" .. CREDIT .. "``|left|" .. icon .. "|\n"
    d = d .. "end_dialog|mptht2_panel|Close||\n"
    player:onDialogRequest(d)
end

local function showPremiumList(player)
    local icon = getIconId()
    local list = getPremiumList()
    local d = "set_default_color|`o\n"
    d = d .. "add_label_with_icon|big|`ePremium Players``|left|" .. icon .. "|\n"
    if #list == 0 then
        d = d .. "add_smalltext|`oNo premium players yet. Use `2/addptht2 <GrowID>`o.``|left|\n"
    else
        d = d .. "add_smalltext|`oCheck a player, then press APPLY to remove them.``|left|\n"
        d = d .. "add_spacer|small|\n"
        for i, gid in ipairs(list) do
            d = d .. "add_checkbox|prem_" .. i .. "|`o" .. gid .. "|0|\n"
        end
    end
    d = d .. "add_spacer|small|\n"
    d = d .. "add_button|ptht2_prem_apply|`4APPLY (Delete Selected)|noflags|0|0|\n"
    d = d .. "add_button|ptht

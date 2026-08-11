-- ============================================================
--  AUCTION HOUSE - PRO
--  Commands: /auction (home: Auction + Manage) | /manageauction (Founder: tax) | /bl (Founder)
--  BrightVerse-native. Currency: DL(1796) BGL(7188) GGL(8470).
--  Escrow: item held on list, currency held on bid, refunded on outbid.
--  Failed delivery (offline / backpack full / >200) -> MyBank Extra Inventory.
--  SC by SALWA x WONYPS
-- ============================================================

local CREDIT  = "ResidenPS"
local VERSION = "v8 | ResidenPS"

local DL_ID  = 1796
local BGL_ID = 7188
local GGL_ID = 8470
local RDL_ID = 2950
local ICON   = 1796
local MIN_DUR = 10
local MAX_STACK = 200
local FOUNDER  = (FOUNDER_ROLE or 1000)
local BL_ROLE  = FOUNDER

local DEF_TAX = 5
local K_TAX   = "AUC_CFG_TAX"
local K_CREATE = "AUC_CFG_CREATE"
local K_BIDDELAY = "AUC_CFG_BIDDELAY"

local MBINV_MAX_SLOTS = 50

local UNTRADE_IDS = { }
local UNTRADE_BIT = 8

local function load(k) return loadDataFromServer(k) end
local function save(k, v) saveDataToServer(k, tostring(v)) end

-- ---------- shared community logs (CLOGS, shared with mybank.lua) ----------
local K_CLOGS = "CLOGS"
local CLOGS_MAX = 50
local function nowStr() local ok, r = pcall(function() return os.date("%m-%d %H:%M") end) if ok and r then return r end return "" end
local function logEvent(text)
    local raw = load(K_CLOGS); if type(raw) ~= "string" then raw = "" end
    local lines = { "`7[" .. nowStr() .. "]`o " .. text }
    for line in (raw .. "\n"):gmatch("(.-)\n") do if line ~= "" and #lines < CLOGS_MAX then lines[#lines+1] = line end end
    save(K_CLOGS, table.concat(lines, "\n"))
end

local function stripColors(s) if type(s) ~= "string" then return "" end return (s:gsub("`.", "")) end
local function trim(s) s = s or ""; return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local function uidOf(p) local ok,u = pcall(function() return p:getUserID() end) if ok then return u end return nil end
local function nameOf(p) local ok,n = pcall(function() return p:getName() end) if ok and n then return stripColors(n) end return "?" end
local function itemAmount(p,id) local ok,n = pcall(function() return p:getItemAmount(id) end) if ok and type(n)=="number" then return n end return 0 end
local function takeItem(p,id,n) pcall(function() p:changeItem(id,-n,0) end) end
local function giveItem(p,id,n) pcall(function() p:changeItem(id,n,0) end) end
local function isCurrency(id) id = tonumber(id); return id == DL_ID or id == BGL_ID or id == GGL_ID or id == RDL_ID end
local function onlinePlayer(uid) local ok,p = pcall(function() return getPlayer(uid) end) if ok and p then return p end return nil end
local function itemName(id)
    local ok,n = pcall(function() local it = getItem(id) return it and it:getName() end)
    if ok and n then return stripColors(n) end
    return "Item#" .. tostring(id)
end

local function isFounder(player)
    local ok,r = pcall(function() return player:hasRole(FOUNDER) end)
    if ok then return r and true or false end
    return false
end

local function getTax()
    local v = tonumber(load(K_TAX))
    if not v then v = DEF_TAX end
    v = math.floor(v + 0.5)
    if v < 0 then v = 0 end
    if v > 100 then v = 100 end
    return v
end

local function getCreateMode() local v = load(K_CREATE); if v == "all" then return "all" end return "founder" end
local function canManage(player) return isFounder(player) or getCreateMode() == "all" end
local function getBidDelay()
    local v = tonumber(load(K_BIDDELAY))
    if not v then v = 0 end
    v = math.floor(v + 0.5)
    if v < 0 then v = 0 end
    return v
end

-- ---------- MyBank Extra Inventory (SHARED with mybank.lua) ----------
-- Keyed by player UID. Items may stack beyond MAX_STACK here. Max 50 distinct slots.
--   MBINV_<uid>_IDX  : newline list of item ids
--   MBINV_<uid>_<id> : amount
local function invIdxKey(uid) return "MBINV_" .. tostring(uid) .. "_IDX" end
local function invAmtKey(uid, id) return "MBINV_" .. tostring(uid) .. "_" .. tostring(id) end
local function invIndex(uid)
    local raw = load(invIdxKey(uid)); local out = {}
    if type(raw) == "string" and raw ~= "" then
        for line in (raw.."\n"):gmatch("(.-)\n") do line = trim(line) if line ~= "" then out[#out+1] = line end end
    end
    return out
end
local function invHas(uid, id) id = tostring(id) for _,v in ipairs(invIndex(uid)) do if v == id then return true end end return false end
local function invAmount(uid, id) return tonumber(load(invAmtKey(uid, id))) or 0 end
local function invAdd(uid, id, amount)
    id = tostring(id); amount = tonumber(amount) or 0
    if amount <= 0 then return true end
    if not invHas(uid, id) then
        local idx = invIndex(uid)
        if #idx >= MBINV_MAX_SLOTS then return false end
        idx[#idx+1] = id
        save(invIdxKey(uid), table.concat(idx, "\n"))
    end
    save(invAmtKey(uid, id), tostring(invAmount(uid, id) + amount))
    return true
end

-- ---------- blacklist ----------
local K_BL = "AUC_BLACKLIST"
local function getBL()
    local raw = load(K_BL); local out = {}
    if type(raw) == "string" and raw ~= "" then
        for line in (raw.."\n"):gmatch("(.-)\n") do line = trim(line) if line ~= "" then out[#out+1] = line end end
    end
    return out
end
local function isBlacklisted(itemId)
    if UNTRADE_IDS[tonumber(itemId)] then return true end
    itemId = tostring(itemId)
    for _,v in ipairs(getBL()) do if v == itemId then return true end end
    return false
end
local function addBL(itemId)
    itemId = tostring(itemId)
    for _,v in ipairs(getBL()) do if v == itemId then return end end
    local l = getBL() l[#l+1] = itemId save(K_BL, table.concat(l, "\n"))
end
local function removeBL(itemId)
    itemId = tostring(itemId)
    local o = {} for _,v in ipairs(getBL()) do if v ~= itemId then o[#o+1] = v end end save(K_BL, table.concat(o, "\n"))
end

-- ---------- sidebar button ----------
local K_SBICON = "AUC_SBICON"
local SIDEBAR_ICON_DEFAULT = 1796
local function getSidebarIcon() return tonumber(load(K_SBICON)) or SIDEBAR_ICON_DEFAULT end
local function setSidebarIcon(id) save(K_SBICON, tostring(id)) end
local function addAuctionButton()
    if type(addSidebarButton) ~= "function" or type(json) ~= "table" then return end
    local btn = {
        active = true,
        buttonAction = "auction",
        buttonTemplate = "BaseEventButton",
        counter = 0, counterMax = 0,
        itemIdIcon = getSidebarIcon(),
        name = "AuctionButton",
        order = 0,
        rcssClass = "clash-event",
        text = "Auction"
    }
    pcall(function() addSidebarButton(json.encode(btn)) end)
end

local function isTradable(itemId)
    if isBlacklisted(itemId) then return false end
    local ok,res = pcall(function()
        local it = getItem(itemId)
        if not it then return true end
        if type(it.isTradeable) == "function" then return it:isTradeable() and true or false end
        if type(it.getFlags) == "function" and bit and bit.band then
            local f = it:getFlags() or 0
            return bit.band(f, UNTRADE_BIT) == 0
        end
        return true
    end)
    if ok then return res end
    return true
end

local function curId(c) if c=="dl" then return DL_ID elseif c=="ggl" then return GGL_ID elseif c=="rdl" then return RDL_ID end return BGL_ID end
local function curName(c) if c=="dl" then return "DL" elseif c=="ggl" then return "GGL" elseif c=="rdl" then return "RDL" end return "BGL" end
local function curOK(c) return c=="dl" or c=="bgl" or c=="ggl" or c=="rdl" end

local function fmtTime(sec)
    if sec < 0 then sec = 0 end
    local h = math.floor(sec/3600); local m = math.floor((sec%3600)/60); local s = sec%60
    if h > 0 then return h.."h "..m.."m" end
    if m > 0 then return m.."m "..s.."s" end
    return s.."s"
end

-- ---------- auction registry ----------
local K_INDEX = "AUC_INDEX"
local function afk(id, f) return "AUC_" .. id .. "_" .. f end
local function getIndex()
    local raw = load(K_INDEX); local out = {}
    if type(raw) == "string" and raw ~= "" then
        for line in (raw.."\n"):gmatch("(.-)\n") do line = trim(line) if line ~= "" then out[#out+1] = line end end
    end
    return out
end
local function indexHas(id) id = tostring(id) for _,v in ipairs(getIndex()) do if v == id then return true end end return false end
local function addIndex(id) id = tostring(id) if indexHas(id) then return end local l = getIndex() l[#l+1] = id save(K_INDEX, table.concat(l, "\n")) end
local function removeIndex(id) id = tostring(id) local o = {} for _,v in ipairs(getIndex()) do if v ~= id then o[#o+1] = v end end save(K_INDEX, table.concat(o, "\n")) end
local function nextId() local n = (tonumber(load("AUC_NEXTID")) or 0) + 1 save("AUC_NEXTID", tostring(n)) return n end

-- ---------- delivery (backpack -> MyBank inventory -> legacy claim) ----------
local function addClaim(uid, itemId, amount)
    local k = "AUCCLAIM_" .. tostring(uid)
    local raw = load(k); if type(raw) ~= "string" then raw = "" end
    save(k, raw .. itemId .. ":" .. amount .. "\n")
end
local function deliver(uid, itemId, amount)
    amount = tonumber(amount) or 0
    if not itemId or amount <= 0 then return end
    local p = onlinePlayer(uid)
    if p then
        if isCurrency(itemId) then giveItem(p, itemId, amount); return end
        local space = MAX_STACK - itemAmount(p, itemId)
        if space >= amount then
            giveItem(p, itemId, amount)
            return
        end
        if invAdd(uid, itemId, amount) then
            pcall(function() p:onConsoleMessage("`6[AUC] Backpack full - `e" .. amount .. "x " .. itemName(itemId) .. "`6 sent to /MyBank Inventory.") end)
        else
            addClaim(uid, itemId, amount)
            pcall(function() p:onConsoleMessage("`6[AUC] MyBank Inventory full - `e" .. amount .. "x " .. itemName(itemId) .. "`6 kept as pending claim.") end)
        end
    else
        if not invAdd(uid, itemId, amount) then addClaim(uid, itemId, amount) end
    end
end
local function processClaims(player)
    local uid = uidOf(player)
    local k = "AUCCLAIM_" .. tostring(uid)
    local raw = load(k)
    if type(raw) ~= "string" or raw == "" then return end
    local got = 0
    for line in (raw.."\n"):gmatch("(.-)\n") do
        local id, amt = line:match("^(%d+):(%d+)$")
        if id and amt then
            id = tonumber(id); amt = tonumber(amt)
            local space = MAX_STACK - itemAmount(player, id)
            if space < 0 then space = 0 end
            local give = math.min(amt, space)
            if give > 0 then giveItem(player, id, give); got = got + 1 end
            local rest = amt - give
            if rest > 0 then invAdd(uid, id, rest) end
        end
    end
    save(k, "")
    if got > 0 then player:onConsoleMessage("`2[AUC] Delivered pending reward(s) (overflow goes to /MyBank Inventory).") end
end

-- ---------- currency conversion & cross-denomination payment (100 DL = 1 BGL, 100 BGL = 1 GGL) ----------
local CUR_MULT = { dl = 1, bgl = 100, ggl = 10000, rdl = 1000000 }
local function convertPayout(cur, net)
    net = tonumber(net) or 0
    local total = net * (CUR_MULT[cur] or 100)
    local rdl = math.floor(total / 1000000); total = total % 1000000
    local ggl = math.floor(total / 10000);   total = total % 10000
    local bgl = math.floor(total / 100);      total = total % 100
    local dl  = total
    local out = {}
    if rdl > 0 then out[#out+1] = { RDL_ID, rdl } end
    if ggl > 0 then out[#out+1] = { GGL_ID, ggl } end
    if bgl > 0 then out[#out+1] = { BGL_ID, bgl } end
    if dl  > 0 then out[#out+1] = { DL_ID,  dl  } end
    return out
end
local function giveChange(player, id, n)
    if n <= 0 then return end
    if isCurrency(id) then giveItem(player, id, n); return end
    local space = MAX_STACK - itemAmount(player, id); if space < 0 then space = 0 end
    if space >= n then giveItem(player, id, n) else if space > 0 then giveItem(player, id, space) end invAdd(uidOf(player), id, n - space) end
end
-- Pay `amount` of currency `cur` using DL/BGL/GGL as fungible; deducts across denominations, returns change.
local function takeCurrency(player, cur, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    local costDL = amount * (CUR_MULT[cur] or 100)
    local aDL, aBGL = itemAmount(player, DL_ID), itemAmount(player, BGL_ID)
    local aGGL, aRDL = itemAmount(player, GGL_ID), itemAmount(player, RDL_ID)
    if aDL + aBGL * 100 + aGGL * 10000 + aRDL * 1000000 < costDL then return false end
    local rem = costDL
    local tR = math.min(aRDL, math.floor(rem / 1000000)); rem = rem - tR * 1000000
    local tG = math.min(aGGL, math.floor(rem / 10000)); rem = rem - tG * 10000
    local tB = math.min(aBGL, math.floor(rem / 100)); rem = rem - tB * 100
    local tD = math.min(aDL, rem); rem = rem - tD
    local changeDL = 0
    if rem > 0 then
        if aBGL - tB > 0 then tB = tB + 1; changeDL = 100 - rem; rem = 0
        elseif aGGL - tG > 0 then tG = tG + 1; changeDL = 10000 - rem; rem = 0
        elseif aRDL - tR > 0 then tR = tR + 1; changeDL = 1000000 - rem; rem = 0 end
    end
    if tR > 0 then takeItem(player, RDL_ID, tR) end
    if tG > 0 then takeItem(player, GGL_ID, tG) end
    if tB > 0 then takeItem(player, BGL_ID, tB) end
    if tD > 0 then takeItem(player, DL_ID, tD) end
    if changeDL > 0 then
        for _, dv in ipairs(convertPayout("dl", changeDL)) do giveChange(player, dv[1], dv[2]) end
    end
    return true
end

-- ---------- sold claims (seller manual claim) ----------
local function soldKey(uid) return "AUCSOLD_" .. tostring(uid) end
local function getSold(uid)
    local raw = load(soldKey(uid)); local out = {}
    if type(raw) == "string" and raw ~= "" then
        for line in (raw.."\n"):gmatch("(.-)\n") do line = trim(line) if line ~= "" then out[#out+1] = line end end
    end
    return out
end
local function addSold(uid, id)
    id = tostring(id)
    local l = getSold(uid)
    for _, v in ipairs(l) do if v == id then return end end
    l[#l+1] = id; save(soldKey(uid), table.concat(l, "\n"))
end
local function removeSold(uid, id)
    id = tostring(id); local o = {} for _, v in ipairs(getSold(uid)) do if v ~= id then o[#o+1] = v end end save(soldKey(uid), table.concat(o, "\n"))
end

-- ---------- finalize / sweep ----------
local function finalizeAuction(id)
    if load(afk(id,"FINALIZED")) == "1" then return end
    if not indexHas(id) then return end
    save(afk(id,"FINALIZED"), "1")
    removeIndex(id)
    local itemId = tonumber(load(afk(id,"ITEM")))
    local amount = tonumber(load(afk(id,"AMOUNT"))) or 0
    local sellerUID = tonumber(load(afk(id,"SELLERUID")))
    local cur = load(afk(id,"CUR")); if not curOK(cur) then cur = "bgl" end
    local bid = tonumber(load(afk(id,"BID"))) or 0
    local bidderUID = tonumber(load(afk(id,"BIDDERUID")))
    if bid > 0 and bidderUID and bidderUID > 0 then
        deliver(bidderUID, itemId, amount)
        local tax = math.floor(bid * getTax() / 100)
        save(afk(id,"NET"), tostring(bid - tax))
        addSold(sellerUID, id)
        logEvent("`bAuction`o #" .. id .. " WON by `e" .. (load(afk(id,"BIDDER")) or "?") .. "`o - `2" .. bid .. " " .. curName(cur) .. "`o (" .. amount .. "x " .. itemName(itemId) .. ")")
        local sp = onlinePlayer(sellerUID)
        if sp then pcall(function() sp:onConsoleMessage("`2[AUC] Auction #" .. id .. " sold! Claim it in /auction > Manage Auction.") end) end
    else
        deliver(sellerUID, itemId, amount)
    end
    removeIndex(id)
end
local function sweep()
    local now = os.time()
    for _, id in ipairs(getIndex()) do
        if now >= (tonumber(load(afk(id,"END"))) or 0) then finalizeAuction(id) end
    end
end
if type(timer) == "table" and type(timer.setTimeout) == "function" then
    local function loop() sweep(); timer.setTimeout(30, loop) end
    timer.setTimeout(30, loop)
end

-- ---------- forward declarations ----------
local showHome, showManage, showAdd, showList, showBid, showBL, showTax

local function showLogs(player)
    local d = ""
    d = d .. "add_label_with_icon|big|`2Community Logs``|left|" .. ICON .. "|\n"
    d = d .. "add_smalltext|`7Recent MyBank & Auction activity.|left|\n"
    local raw = load(K_CLOGS); local any = false
    if type(raw) == "string" and raw ~= "" then
        for line in (raw .. "\n"):gmatch("(.-)\n") do
            if line ~= "" then d = d .. "add_smalltext|" .. line .. "|left|\n"; any = true end
        end
    end
    if not any then d = d .. "add_smalltext|`7No logs yet.|left|\n" end
    d = d .. "add_button|clogs_refresh|`2Refresh|noflags|0|0|\n"
    d = d .. "add_button|clogs_clear|`4Clear Logs (Founder)|noflags|0|0|\n"
    d = d .. "add_label_with_icon|small|`6" .. CREDIT .. "``|left|" .. ICON .. "|\n"
    d = d .. "end_dialog|clogs_panel|Close||\n"
    player:onDialogRequest(d)
end

registerLuaCommand{
    command = "auction", roleRequired = 0,
    description = "Open the Auction House",
    callback = function(player, args) showList(player) end
}
registerLuaCommand{
    command = "clogs", roleRequired = 0,
    description = "View community logs",
    callback = function(player, args) showLogs(player) end
}
registerLuaCommand{
    command = "manageauction", roleRequired = FOUNDER,
    description = "Auction tax config (Founder)",
    callback = function(player, args)
        if not isFounder(player) then player:onConsoleMessage("`4[AUC] Founder only.") return end
        showTax(player)
    end
}
registerLuaCommand{
    command = "bl", roleRequired = BL_ROLE,
    description = "Auction blacklist manager (admin)",
    callback = function(player, args)
        local id = tonumber(trim(tostring(args or "")))
        if id and id > 0 then
            if isBlacklisted(id) then logEvent("`bAuction`o blacklist - " .. itemName(id)); removeBL(id); player:onConsoleMessage("`2[BL] " .. itemName(id) .. " removed from blacklist.")
            else logEvent("`bAuction`o blacklist + " .. itemName(id)); addBL(id); player:onConsoleMessage("`4[BL] " .. itemName(id) .. " (ID " .. id .. ") blacklisted.") end
        end
        showBL(player)
    end
}

-- ---------- add-form draft ----------
local addDraft = {}
local function mergeDraft(player, data)
    local uid = uidOf(player)
    local d = addDraft[uid] or {}
    local it = tonumber(data.au_item)
    if it and it > 0 then
        if isBlacklisted(it) or not isTradable(it) then
            d.warn = itemName(it) .. " is untradable / blacklisted."
        else
            d.item = it; d.warn = nil
        end
    end
    if data.au_amount and data.au_amount ~= "" then d.amount = data.au_amount end
    if data.au_start and data.au_start ~= "" then d.start = data.au_start end
    if data.au_step ~= nil and data.au_step ~= "" then d.step = data.au_step end
    if data.au_time and data.au_time ~= "" then d.time = data.au_time end
    if data.au_cur and data.au_cur ~= "" then d.cur = data.au_cur end
    addDraft[uid] = d
    return d
end
local function clearDraft(player) addDraft[uidOf(player)] = nil end

-- ---------- actions ----------
local function createAuction(player)
    if not canManage(player) then player:onConsoleMessage("`4[AUC] Only Founder can create auctions right now.") return end
    local uid = uidOf(player)
    local dft = addDraft[uid] or {}
    local itemId = tonumber(dft.item)
    if not itemId or itemId <= 0 then player:onConsoleMessage("`4[AUC] Select an item first.") showAdd(player) return end
    if itemId == DL_ID or itemId == BGL_ID or itemId == GGL_ID or itemId == RDL_ID then player:onConsoleMessage("`4[AUC] Currency locks cannot be auctioned.") showAdd(player) return end
    if isBlacklisted(itemId) or not isTradable(itemId) then player:onConsoleMessage("`4[AUC] Untradable / blacklisted item cannot be added.") clearDraft(player) showAdd(player) return end
    local amount = math.floor(tonumber(dft.amount) or 0)
    if amount <= 0 then player:o

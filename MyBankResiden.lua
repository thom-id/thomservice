-- MyBank | ResidenPS
-- Gem bank: auto-bank, BGL/GGL exchange, transfer, 50-slot Extra Inventory (shared with auction.lua).
local CREDIT = "ResidenPS"

local FOUNDER_ROLE = 1000
local GEMS_CAP     = 2000000000
local BGL_ID       = 7188
local GGL_ID       = 8470
local RDL_ID       = 2950

local DEF_THRESHOLD = 950000000
local DEF_RATE_BGL  = 30000000
local DEF_RATE_GGL  = 3000000000
local DEF_RATE_RDL  = 300000000000

local K_THRESHOLD = "MYBANK_CFG_THRESHOLD"
local K_RATE_BGL  = "MYBANK_CFG_RBGL"
local K_RATE_GGL  = "MYBANK_CFG_RGGL"
local K_RATE_RDL  = "MYBANK_CFG_RRDL"

-- Extra Inventory (SHARED with auction.lua). Keyed by player UID.
--   MBINV_<uid>_IDX  : newline list of item ids (max 50 distinct)
--   MBINV_<uid>_<id> : amount (may exceed 200)
local MBINV_MAX_SLOTS = 50
local INV_MAX_STACK   = 200

local function num(v, d)
    local n = tonumber(v)
    if not n then return d end
    return n
end

-- ---------- shared community logs (CLOGS, shared with auction.lua) ----------
local K_CLOGS = "CLOGS"
local CLOGS_MAX = 50
local function nowStr() local ok, r = pcall(function() return os.date("%m-%d %H:%M") end) if ok and r then return r end return "" end
local function logEvent(text)
    local raw = loadDataFromServer(K_CLOGS); if type(raw) ~= "string" then raw = "" end
    local lines = { "`7[" .. nowStr() .. "]`o " .. text }
    for line in (raw .. "\n"):gmatch("(.-)\n") do if line ~= "" and #lines < CLOGS_MAX then lines[#lines+1] = line end end
    saveDataToServer(K_CLOGS, table.concat(lines, "\n"))
end

-- config (Founder set via /managemybank)
local function getThreshold()
    local n = math.floor(num(loadDataFromServer(K_THRESHOLD), DEF_THRESHOLD))
    if n < 0 then n = 0 end
    if n > GEMS_CAP then n = GEMS_CAP end
    return n
end
local function getRateBGL()
    local n = math.floor(num(loadDataFromServer(K_RATE_BGL), DEF_RATE_BGL))
    if n < 1 then n = DEF_RATE_BGL end
    return n
end
local function getRateGGL()
    local n = math.floor(num(loadDataFromServer(K_RATE_GGL), DEF_RATE_GGL))
    if n < 1 then n = DEF_RATE_GGL end
    return n
end

local function getRateRDL()
    local n = math.floor(num(loadDataFromServer(K_RATE_RDL), DEF_RATE_RDL))
    if n < 1 then n = DEF_RATE_RDL end
    return n
end

-- player identity (same as ptht1)
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
local function uidOf(p)
    local ok, u = pcall(function() return p:getUserID() end)
    if ok then return u end
    return nil
end

local function gemsOf(player)
    local ok, g = pcall(function() return player:getGems() end)
    if ok and type(g) == "number" then return math.floor(g) end
    return 0
end
local function setGemsSafe(player, n)
    n = math.floor(n)
    if n < 0 then n = 0 end
    if n > GEMS_CAP then n = GEMS_CAP end
    pcall(function() player:setGems(n) end)
end

-- item helpers
local function itemAmount(p, id)
    local ok, n = pcall(function() return p:getItemAmount(id) end)
    if ok and type(n) == "number" then return n end
    return 0
end
local function takeItem(p, id, n) pcall(function() p:changeItem(id, -n, 0) end) end
local function giveItem(p, id, n) pcall(function() p:changeItem(id, n, 0) end) end
local function isCurrency(id) id = tonumber(id); return id == 1796 or id == BGL_ID or id == GGL_ID or id == RDL_ID end
local function itemName(id)
    local ok, n = pcall(function() local it = getItem(id) return it and it:getName() end)
    if ok and n then return stripColors(n) end
    return "Item#" .. tostring(id)
end

-- bank storage (shared with ptht1: MYBANK_<growid>)
local function bankKey(gid) return "MYBANK_" .. gid end
local function getBank(gid)
    if gid == "" then return 0 end
    return math.floor(num(loadDataFromServer(bankKey(gid)), 0))
end
local function setBank(gid, n)
    if gid == "" then return end
    n = math.floor(n)
    if n < 0 then n = 0 end
    saveDataToServer(bankKey(gid), tostring(n))
end
local function addBank(gid, delta)
    setBank(gid, getBank(gid) + delta)
end

-- Extra Inventory storage
local function invIdxKey(uid) return "MBINV_" .. tostring(uid) .. "_IDX" end
local function invAmtKey(uid, id) return "MBINV_" .. tostring(uid) .. "_" .. tostring(id) end
local function invIndex(uid)
    local raw = loadDataFromServer(invIdxKey(uid)); local out = {}
    if type(raw) == "string" and raw ~= "" then
        for line in (raw.."\n"):gmatch("(.-)\n") do
            line = (line:gsub("^%s+", ""):gsub("%s+$", ""))
            if line ~= "" then out[#out+1] = line end
        end
    end
    return out
end
local function invHas(uid, id) id = tostring(id) for _, v in ipairs(invIndex(uid)) do if v == id then return true end end return false end
local function invAmount(uid, id) return math.floor(num(loadDataFromServer(invAmtKey(uid, id)), 0)) end
local function invSaveIndex(uid, idx) saveDataToServer(invIdxKey(uid), table.concat(idx, "\n")) end
local function invSetAmount(uid, id, amount)
    id = tostring(id); amount = math.floor(amount)
    if amount <= 0 then
        saveDataToServer(invAmtKey(uid, id), "0")
        local o = {} for _, v in ipairs(invIndex(uid)) do if v ~= id then o[#o+1] = v end end
        invSaveIndex(uid, o)
    else
        if not invHas(uid, id) then
            local idx = invIndex(uid); idx[#idx+1] = id; invSaveIndex(uid, idx)
        end
        saveDataToServer(invAmtKey(uid, id), tostring(amount))
    end
end

local function fmt(n)
    local s = tostring(math.floor(n))
    local sign = ""
    if s:sub(1, 1) == "-" then sign = "-"; s = s:sub(2) end
    while true do
        local k
        s, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return sign .. s
end

-- bank actions
local function doDeposit(player, amount)
    local gid = getGrowID(player)
    if gid == "" then player:onConsoleMessage("`4[BANK] Could not read GrowID."); return end
    amount = math.floor(amount or 0)
    if amount <= 0 then player:onConsoleMessage("`4[BANK] Invalid amount."); return end
    local have = gemsOf(player)
    if amount > have then amount = have end
    if amount <= 0 then player:onConsoleMessage("`4[BANK] You have no gems."); return end
    setGemsSafe(player, have - amount)
    addBank(gid, amount)
    logEvent("`9MyBank`o deposit `2" .. fmt(amount) .. "`o gems by `e" .. gid)
    player:onConsoleMessage("`2[BANK] `oDeposit `2" .. fmt(amount) .. "`o gems. Bank balance: `2" .. fmt(getBank(gid)))
end

local function doWithdraw(player, amount)
    local gid = getGrowID(player)
    if gid == "" then player:onConsoleMessage("`4[BANK] Could not read GrowID."); return end
    amount = math.floor(amount or 0)
    if amount <= 0 then player:onConsoleMessage("`4[BANK] Invalid amount."); return end
    local bank = getBank(gid)
    if amount > bank then amount = bank end
    if amount <= 0 then player:onConsoleMessage("`4[BANK] Bank balance is empty."); return end
    local have = gemsOf(player)
    local room = GEMS_CAP - have
    if room <= 0 then player:onConsoleMessage("`4[BANK] Your gems are already full (2B)."); return end
    if amount > room then amount = room end
    setGemsSafe(player, have + amount)
    setBank(gid, bank - amount)
    logEvent("`9MyBank`o withdraw `2" .. fmt(amount) .. "`o gems by `e" .. gid)
    player:onConsoleMessage("`2[BANK] `oWithdraw `2" .. fmt(amount) .. "`o gems. Bank balance: `2" .. fmt(getBank(gid)))
end

local function doExchange(player, kind, qty)
    local gid = getGrowID(player)
    if gid == "" then player:onConsoleMessage("`4[BANK] Could not read GrowID."); return end
    qty = math.floor(qty or 0)
    if qty <= 0 then player:onConsoleMessage("`4[BANK] Invalid lock amount."); return end
    local itemId, rate, name
    if kind == "bgl" then itemId = BGL_ID; rate = getRateBGL(); name = "BGL"
    elseif kind == "rdl" then itemId = RDL_ID; rate = getRateRDL(); name = "RDL"
    else itemId = GGL_ID; rate = getRateGGL(); name = "GGL" end
    local total = rate * qty
    local bank = getBank(gid)
    if bank < total then
        player:onConsoleMessage("`4[BANK] Not enough bank balance. Need `e" .. fmt(total) .. "`4 gems for `e" .. qty .. " " .. name .. "`4 (balance `e" .. fmt(bank) .. "`4).")
        return
    end
    local ok = pcall(function() return player:changeItem(itemId, qty, 0) end)
    if not ok then player:onConsoleMessage("`4[BANK] Failed to give item (inventory full?)."); return end
    setBank(gid, bank - total)
    logEvent("`9MyBank`o exchange `2" .. qty .. " " .. name .. "`o by `e" .. gid)
    player:onConsoleMessage("`2[BANK] `oExchanged `2" .. qty .. " " .. name .. "`o (-" .. fmt(total) .. " gems from bank). Balance: `2" .. fmt(getBank(gid)))
end

-- auto-bank: move gems above threshold to bank (idempotent, safe to call anytime)
local function autoBankPlayer(player)
    if not player then return end
    local thr = getThreshold()
    local ok, g = pcall(function() return gemsOf(player) end)
    if not ok or type(g) ~= "number" then return end
    if g > thr then
        local gid = getGrowID(player)
        if gid == "" then return end
        setGemsSafe(player, 0)
        addBank(gid, g)
        pcall(function() player:onConsoleMessage("`2[BANK] `oGems exceeded `2" .. fmt(thr) .. "`o -> all `2" .. fmt(g) .. "`o gems moved to bank, backpack now `20`o. Balance: `2" .. fmt(getBank(gid))) end)
    end
end

local function doTransfer(player, targetRaw, amount)
    local from = getGrowID(player)
    if from == "" then player:onConsoleMessage("`4[BANK] Could not read your GrowID.") return end
    local target = normName(targetRaw)
    if target == "" then player:onConsoleMessage("`4[BANK] Enter a target GrowID first.") return end
    if target == from then player:onConsoleMessage("`4[BANK] You cannot transfer to yourself.") return end
    if type(amount) ~= "number" or amount ~= amount then player:onConsoleMessage("`4[BANK] Invalid amount.") return end
    amount = math.floor(amount)
    if amount <= 0 then player:onConsoleMessage("`4[BANK] Amount must be greater than 0.") return end
    local bal = getBank(from)
    if amount > bal then player:onConsoleMessage("`4[BANK] Not enough bank balance. Your balance: `2" .. fmt(bal)) return end
    setBank(from, bal - amount)
    addBank(target, amount)
    logEvent("`9MyBank`o transfer `2" .. fmt(amount) .. "`o gems `e" .. from .. "`o -> `e" .. target)
    player:onConsoleMessage("`2[BANK] `oTransferred `2" .. fmt(amount) .. "`o gems to `e" .. target .. "`o. Your balance: `2" .. fmt(getBank(from)))
    pcall(function()
        local ok, list = pcall(function() return getServerPlayers() end)
        if ok and type(list) == "table" then
            for _, p in ipairs(list) do
                if getGrowID(p) == target then
                    p:onConsoleMessage("`2[BANK] `oYou received `2" .. fmt(amount) .. "`o gems from `e" .. from .. "`o (into /mybank). Balance: `2" .. fmt(getBank(target)))
                    break
                end
            end
        end
    end)
end

-- ---------- Extra Inventory actions ----------
local invDraft = {}
local invWdSel = {}

local function invDeposit(player, itemId, amount)
    local uid = uidOf(player)
    itemId = tonumber(itemId)
    amount = math.floor(tonumber(amount) or 0)
    if not itemId or itemId <= 0 then player:onConsoleMessage("`4[INV] Select an item first."); return end
    if amount <= 0 then player:onConsoleMessage("`4[INV] Invalid amount."); return end
    local have = itemAmount(player, itemId)
    if amount > have then player:onConsoleMessage("`4[INV] Access Denied - you only have `e" .. have .. "x " .. itemName(itemId) .. "`4."); return end
    if not invHas(uid, itemId) and #invIndex(uid) >= MBINV_MAX_SLOTS then
        player:onConsoleMessage("`4[INV] Inventory full (max " .. MBINV_MAX_SLOTS .. " slots)."); return
    end
    takeItem(player, itemId, amount)
    invSetAmount(uid, itemId, invAmount(uid, itemId) + amount)
    logEvent("`9Inventory`o store `2" .. amount .. "x " .. itemName(itemId) .. "`o by `e" .. getGrowID(player))
    player:onConsoleMessage("`2[INV] `oStored `2" .. amount .. "x " .. itemName(itemId) .. "`o. Total: `2" .. fmt(invAmount(uid, itemId)))
end

local function invWithdraw(player, itemId, amount)
    local uid = uidOf(player)
    itemId = tonumber(itemId)
    amount = math.floor(tonumber(amount) or 0)
    if not itemId or itemId <= 0 then return end
    if amount <= 0 then player:onConsoleMessage("`4[INV] Invalid amount."); return end
    local stored = invAmount(uid, itemId)
    if stored <= 0 then player:onConsoleMessage("`4[INV] Item not in inventory."); return end
    if amount > stored then player:onConsoleMessage("`4[INV] Access Denied - inventory only has `e" .. stored .. "x " .. itemName(itemId) .. "`4."); return end
    local have = itemAmount(player, itemId)
    if not isCurrency(itemId) and have + amount > INV_MAX_STACK then
        player:onConsoleMessage("`4[INV] Backpack full! (`e" .. have .. "`4 + `e" .. amount .. "`4 > max `e" .. INV_MAX_STACK .. "`4)."); return
    end
    giveItem(player, itemId, amount)
    invSetAmount(uid, itemId, stored - amount)
    logEvent("`9Inventory`o withdraw `2" .. amount .. "x " .. itemName(itemId) .. "`o by `e" .. getGrowID(player))
    player:onConsoleMessage("`2[INV] `oWithdrew `2" .. amount .. "x " .. itemName(itemId) .. "`o. Left: `2" .. fmt(invAmount(uid, itemId)))
end

-- ---------- dialogs ----------
local function showBank(player)
    autoBankPlayer(player)
    local gid  = getGrowID(player)
    local have = gemsOf(player)
    local bank = getBank(gid)
    local rb, rg, rr = getRateBGL(), getRateGGL(), getRateRDL()
    local d = "set_default_color|`o\n"
    d = d .. "add_label_with_icon|big|`eMy Bank``|left|18|\n"
    d = d .. "add_button|tab_bank|`2>> MY BANK|noflags|0|0|\n"
    d = d .. "add_button|tab_inv|`9EXTRA INVENTORY|noflags|0|0|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_label_with_icon|small|`oGems: `2" .. fmt(have) .. "|left|18|\n"
    d = d .. "add_label_with_icon|small|`oBank: `2" .. fmt(bank) .. "|left|18|\n"
    d = d .. "add_text_input|mb_amount|Gems amount:||18|\n"
    d = d .. "add_button|mb_deposit|`2DEPOSIT|noflags|0|0|\n"
    d = d .. "add_button|mb_withdraw|`6WITHDRAW|noflags|0|0|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_label_with_icon|small|`o1 BGL = `2" .. fmt(rb) .. "`o gems|left|" .. BGL_ID .. "|\n"
    d = d .. "add_label_with_icon|small|`o1 GGL = `2" .. fmt(rg) .. "`o gems|left|" .. GGL_ID .. "|\n"
    d = d .. "add_label_with_icon|small|`o1 RDL = `2" .. fmt(rr) .. "`o gems|left|" .. RDL_ID .. "|\n"
    d = d .. "add_text_input|mb_qty|Number of locks:||6|\n"
    d = d .. "add_button|mb_bgl|`9EXCHANGE BGL|noflags|0|0|\n"
    d = d .. "add_button|mb_ggl|`eEXCHANGE GGL|noflags|0|0|\n"
    d = d .. "add_button|mb_rdl|`cEXCHANGE RDL|noflags|0|0|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_text_input|mb_target|Transfer to GrowID:||18|\n"
    d = d .. "add_button|mb_transfer|`5TRANSFER|noflags|0|0|\n"
    d = d .. "add_label_with_icon|small|`6" .. CREDIT .. "``|left|32|\n"
    d = d .. "end_dialog|mybank_panel|Close||\n"
    player:onDialogRequest(d)
end

local function showInv(player)
    local uid = uidOf(player)
    local sel = invDraft[uid]
    local d = "set_default_color|`o\n"
    d = d .. "add_label_with_icon|big|`eExtra Inventory``|left|" .. (sel or 18) .. "|\n"
    d = d .. "add_button|tab_bank|`2MY BANK|noflags|0|0|\n"
    d = d .. "add_button|tab_inv|`9>> EXTRA INVENTORY|noflags|0|0|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_smalltext|`7Slots: `2" .. #invIndex(uid) .. "`7/" .. MBINV_MAX_SLOTS .. "``|left|\n"
    local pl = sel and ("`2" .. itemName(sel) .. "`o (change)") or "Pick item from backpack"
    d = d .. "add_item_picker|inv_item|" .. pl .. "|Select item|\n"
    d = d .. "add_text_input|inv_dep_amt|Deposit amount:|1|9|\n"
    d = d .. "add_button|inv_deposit|`2DEPOSIT|noflags|0|0|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_smalltext|`oClick an item to withdraw:``|left|\n"
    local idx = invIndex(uid)
    if #idx == 0 then
        d = d .. "add_smalltext|`7Inventory is empty.``|left|\n"
    else
        for _, ids in ipairs(idx) do
            local iid = tonumber(ids) or 0
            d = d .. "add_label_with_icon|small|`2" .. fmt(invAmount(uid, iid)) .. "``|left|" .. iid .. "|\n"
            d = d .. "add_button|invwd_" .. iid .. "|`6" .. itemName(iid) .. "|noflags|0|0|\n"
        end
    end
    d = d .. "add_label_with_icon|small|`6" .. CREDIT .. "``|left|32|\n"
    d = d .. "end_dialog|mybank_inv|Close||\n"
    player:onDialogRequest(d)
end

local function showInvWd(player)
    local uid = uidOf(player)
    local iid = invWdSel[uid]
    if not iid then showInv(player) return end
    local stored = invAmount(uid, iid)
    local d = "set_default_color|`o\n"
    d = d .. "add_label_with_icon|big|`6Withdraw``|left|" .. iid .. "|\n"
    d = d .. "add_label_with_icon|small|`w" .. itemName(iid) .. "`o - stored `2" .. fmt(stored) .. "|left|" .. iid .. "|\n"
    d = d .. "add_smalltext|`7Backpack max `2" .. INV_MAX_STACK .. "`7 per item.``|left|\n"
    d = d .. "add_text_input|iwd_amt|Amount:|1|9|\n"
    d = d .. "add_button|iwd_confirm|`2WITHDRAW|noflags|0|0|\n"
    d = d .. "add_button|iwd_back|`oBACK|noflags|0|0|\n"
    d = d .. "end_dialog|mybank_invwd|Close||\n"
    player:onDialogRequest(d)
end

local function showManage(player)
    local thr = getThreshold()
    local rb, rg, rr = getRateBGL(), getRateGGL(), getRateRDL()
    local d = "set_default_color|`o\n"
    d = d .. "add_label_with_icon|big|`eManage MyBank``|left|18|\n"
    d = d .. "add_text_input|mmb_threshold|Auto-bank above (gems):|" .. thr .. "|13|\n"
    d = d .. "add_text_input|mmb_rbgl|Gems per 1 BGL:|" .. rb .. "|13|\n"
    d = d .. "add_text_input|mmb_rggl|Gems per 1 GGL:|" .. rg .. "|13|\n"
    d = d .. "add_text_input|mmb_rrdl|Gems per 1 RDL:|" .. rr .. "|13|\n"
    d = d .. "add_button|mmb_save|`2SAVE SETTINGS|noflags|0|0|\n"
    d = d .. "add_spacer|small|\n"
    d = d .. "add_text_input|mmb_gid|GrowID:||24|\n"
    d = d .. "add_text_input|mmb_bal|Set bank balance:||18|\n"
    d = d .. "add_button|mmb_setbank|`6SET BALANCE|noflags|0|0|\n"
    d = d .. "add_label_with_icon|small|`6" .. CREDIT .. "``|left|32|\n"
    d = d .. "end_dialog|managemybank_panel|Close||\n"
    player:onDialogRequest(d)
end

registerLuaCommand{
    command      = "mybank",
    roleRequired = 0,
    description  = "Open MyBank",
    callback = function(player, args)
        showBank(player)
    end
}

registerLuaCommand{
    command      = "managemybank",
    roleRequired = FOUNDER_ROLE,
    description  = "MyBank config (Founder)",
    callback = function(player, args)
        if not player:hasRole(FOUNDER_ROLE) then player:onConsoleMessage("`4[BANK] Founder only."); return end
        showManage(player)
    end
}

onPlayerDialogCallback(function(world, player, data)
    local dn = data.dialog_name
    if dn == "mybank_panel" then
        local b = data.buttonClicked
        if b == "tab_inv" then invDraft[uidOf(player)] = nil; showInv(player); return true end
        if b == "tab_bank" then showBank(player); return true end
        if b == "mb_deposit" then doDeposit(player, tonumber(data.mb_amount))
        elseif b == "mb_withdraw" then doWithdraw(player, tonumber(data.mb_amount))
        elseif b == "mb_bgl" then doExchange(player, "bgl", tonumber(data.mb_qty))
        elseif b == "mb_ggl" then doExchange(player, "ggl", tonumber(data.mb_qty))
  

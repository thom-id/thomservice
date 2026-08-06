-- ============================================
-- SELL SYSTEM - GTPS CLOUD
-- FULL WORKING VERSION WITH WL CONVERT
-- ============================================

print("Loading Sell System...")

-- ============================================
-- KONFIGURASI
-- ============================================

local CONFIG = {
    categories = {
        "Chemical", "Cooking", "Egg", "Ghost", 
        "Milk", "Miner", "Startopia", "Surgery", "Wool"
    },
    prices = {
        Chemical = 10,
        Cooking = 15,
        Egg = 20,
        Ghost = 25,
        Milk = 12,
        Miner = 18,
        Startopia = 30,
        Surgery = 50,
        Wool = 8
    },
    maxSellPerDay = 50,
    iconId = 3033,  -- Icon pot
    wlRate = 100    -- 1 WL = 100 BGL
}

-- ============================================
-- FUNGSI STORAGE PLAYER
-- ============================================

local function getBGL(player)
    local val = player:getStorage("sell_bgl")
    if not val then
        val = 0
        player:setStorage("sell_bgl", val)
    end
    return tonumber(val)
end

local function addBGL(player, amount)
    local current = getBGL(player)
    local newTotal = current + amount
    player:setStorage("sell_bgl", newTotal)
    return newTotal
end

local function getDailyCount(player)
    local val = player:getStorage("sell_daily")
    if not val then
        val = 0
        player:setStorage("sell_daily", val)
    end
    return tonumber(val)
end

local function addDailyCount(player)
    local current = getDailyCount(player)
    local newCount = current + 1
    player:setStorage("sell_daily", newCount)
    return newCount
end

local function resetDailyCount(player)
    player:setStorage("sell_daily", 0)
end

-- ============================================
-- FUNGSI INVENTORY
-- ============================================

local function getItemCount(player, itemName)
    local val = player:getStorage("inv_" .. itemName)
    return tonumber(val) or 0
end

local function removeItem(player, itemName, amount)
    amount = amount or 1
    local current = getItemCount(player, itemName)
    if current >= amount then
        player:setStorage("inv_" .. itemName, current - amount)
        return true
    end
    return false
end

local function addItem(player, itemName, amount)
    amount = amount or 1
    local current = getItemCount(player, itemName)
    player:setStorage("inv_" .. itemName, current + amount)
end

-- ============================================
-- FUNGSI KONVERSI BGL KE WL
-- ============================================

local function bglToWL(bgl)
    local wl = math.floor(bgl / CONFIG.wlRate)
    local sisa = bgl % CONFIG.wlRate
    return wl, sisa
end

local function formatBGL(bgl)
    local wl, sisa = bglToWL(bgl)
    if wl > 0 then
        return wl .. " WL " .. sisa .. " BGL"
    else
        return sisa .. " BGL"
    end
end

-- ============================================
-- MENU UTAMA
-- ============================================

local function showMenu(player)
    local bgl = getBGL(player)
    local daily = getDailyCount(player)
    local remaining = CONFIG.maxSellPerDay - daily
    local wl, sisa = bglToWL(bgl)
    
    local msg = ""
    msg = msg .. "`2# SELL SYSTEM`w\n"
    msg = msg .. "━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    msg = msg .. "Klik kategori di bawah:\n"
    msg = msg .. "━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    
    for _, cat in ipairs(CONFIG.categories) do
        local price = CONFIG.prices[cat]
        local count = getItemCount(player, cat)
        msg = msg .. "`2" .. cat .. "`w - `6" .. price .. " BGL`w (`3" .. count .. "x`w)\n"
    end
    
    msg = msg .. "━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    msg = msg .. "`6BGL:`w " .. string.format("%.0f", bgl) .. " BGL\n"
    if wl > 0 then
        msg = msg .. "`6WL:`w " .. wl .. " WL `3(" .. sisa .. " BGL sisa)`w\n"
    end
    msg = msg .. "`6Sisa jual hari ini:`w " .. remaining .. "\n"
    msg = msg .. "━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    msg = msg .. "Ketik: `/sell [kategori]`\n"
    msg = msg .. "Contoh: `/sell chemical`\n"
    msg = msg .. "━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    msg = msg .. "`6/wl`w - Cek konversi BGL ke WL\n"
    msg = msg .. "`4/close`w - Tutup"
    
    player:onConsoleMessage(msg)
end

-- ============================================
-- FUNGSI JUAL
-- ============================================

local function sellItem(player, category)
    -- Validasi kategori
    local price = CONFIG.prices[category]
    if not price then
        player:onConsoleMessage("`4Error:`w Kategori '" .. category .. "' tidak ditemukan!")
        return false
    end
    
    -- Cek daily limit
    local daily = getDailyCount(player)
    if daily >= CONFIG.maxSellPerDay then
        player:onConsoleMessage("`4Error:`w Batas jual hari ini habis! (" .. CONFIG.maxSellPerDay .. "/hari)")
        return false
    end
    
    -- Cek item
    local count = getItemCount(player, category)
    if count <= 0 then
        player:onConsoleMessage("`4Error:`w Kamu tidak punya " .. category .. "!")
        return false
    end
    
    -- Proses jual
    removeItem(player, category, 1)
    local newBGL = addBGL(player, price)
    local newDaily = addDailyCount(player)
    local wl, sisa = bglToWL(newBGL)
    
    -- Notifikasi
    player:onConsoleMessage("")
    player:onConsoleMessage("`2✓ Sukses!`w Menjual `2" .. category .. "`w")
    player:onConsoleMessage("`6+ " .. price .. " BGL`w")
    player:onConsoleMessage("`6Total BGL:`w " .. string.format("%.0f", newBGL) .. " BGL")
    if wl > 0 then
        player:onConsoleMessage("`6Total WL:`w " .. wl .. " WL `3(" .. sisa .. " BGL sisa)`w")
    end
    player:onTalkBubble(player:getNetID(), "💰 +" .. price .. " BGL", 1)
    
    -- Sisa jual
    local remaining = CONFIG.maxSellPerDay - newDaily
    if remaining <= 5 then
        player:onConsoleMessage("`3⚠️ Sisa jual hari ini: `w" .. remaining .. " item")
    end
    player:onConsoleMessage("")
    
    return true
end

-- ============================================
-- REGISTER COMMANDS
-- ============================================

-- Command utama
registerLuaCommand({
    command = "sell",
    roleRequired = 0,
    description = "Buka menu Sell System"
})

registerLuaCommand({
    command = "mybgl",
    roleRequired = 0,
    description = "Cek BGL dan WL kamu"
})

registerLuaCommand({
    command = "wl",
    roleRequired = 0,
    description = "Cek konversi BGL ke WL"
})

registerLuaCommand({
    command = "close",
    roleRequired = 0,
    description = "Tutup menu"
})

-- Command kategori (alternatif)
for _, cat in ipairs(CONFIG.categories) do
    registerLuaCommand({
        command = "sell" .. cat:lower(),
        roleRequired = 0,
        description = "Jual " .. cat
    })
end

-- Admin command
registerLuaCommand({
    command = "giveitem",
    roleRequired = 2,
    description = "/giveitem [player] [item] [amount]"
})

registerLuaCommand({
    command = "resetdaily",
    roleRequired = 2,
    description = "/resetdaily [player] - Reset daily limit"
})

registerLuaCommand({
    command = "givebgl",
    roleRequired = 2,
    description = "/givebgl [player] [amount] - Give BGL to player"
})

-- ============================================
-- COMMAND HANDLER
-- ============================================

onPlayerCommandCallback(function(world, player, fullCommand)
    local parts = {}
    for word in fullCommand:gmatch("%S+") do
        table.insert(parts, word)
    end
    
    local cmd = parts[1]
    if not cmd then return false end
    
    -- /sell
    if cmd == "sell" then
        local arg = parts[2]
        if arg then
            -- Coba jual langsung
            local category = arg:gsub("^%l", string.upper)
            if CONFIG.prices[category] then
                sellItem(player, category)
            else
                player:onConsoleMessage("`4Error:`w Kategori '" .. arg .. "' tidak ada!")
                player:onConsoleMessage("Gunakan `/sell` untuk lihat daftar")
            end
        else
            showMenu(player)
        end
        return true
    end
    
    -- /mybgl
    if cmd == "mybgl" then
        local bgl = getBGL(player)
        local wl, sisa = bglToWL(bgl)
        player:onConsoleMessage("")
        player:onConsoleMessage("`6╔══════════════════════╗`w")
        player:onConsoleMessage("`6║    MY BALANCE       ║`w")
        player:onConsoleMessage("`6╚══════════════════════╝`w")
        player:onConsoleMessage("`6BGL:`w " .. string.format("%.0f", bgl))
        if wl > 0 then
            player:onConsoleMessage("`6WL:`w " .. wl .. " WL `3(" .. sisa .. " BGL sisa)`w")
        else
            player:onConsoleMessage("`6WL:`w 0 WL")
        end
        player:onConsoleMessage("`6Rate:`w 1 WL = " .. CONFIG.wlRate .. " BGL")
        player:onConsoleMessage("")
        return true
    end
    
    -- /wl
    if cmd == "wl" then
        local bgl = getBGL(player)
        local wl, sisa = bglToWL(bgl)
        local needForNextWL = CONFIG.wlRate - sisa
        
        player:onConsoleMessage("")
        player:onConsoleMessage("`6╔══════════════════════╗`w")
        player:onConsoleMessage("`6║   BGL TO WL         ║`w")
        player:onConsoleMessage("`6╚══════════════════════╝`w")
        player:onConsoleMessage("`6BGL Kamu:`w " .. string.format("%.0f", bgl))
        player:onConsoleMessage("`6WL Kamu:`w " .. wl .. " WL")
        player:onConsoleMessage("`6Sisa BGL:`w " .. sisa .. " BGL")
        if sisa > 0 then
            player:onConsoleMessage("`3Butuh `w" .. needForNextWL .. " BGL `3lagi untuk 1 WL`w")
        end
        player:onConsoleMessage("`6Rate:`w 1 WL = " .. CONFIG.wlRate .. " BGL")
        player:onConsoleMessage("")
        return true
    end
    
    -- /close
    if cmd == "close" then
        player:onConsoleMessage("`4Menu ditutup.`w Ketik `/sell` untuk buka lagi")
        return true
    end
    
    -- /sell[category] (contoh: /sellchemical)
    for _, cat in ipairs(CONFIG.categories) do
        if cmd == "sell" .. cat:lower() then
            sellItem(player, cat)
            return true
        end
    end
    
    -- ADMIN: /giveitem
    if cmd == "giveitem" and #parts >= 3 then
        local targetName = parts[2]
        local itemName = parts[3]:gsub("^%l", string.upper)
        local amount = tonumber(parts[4]) or 1
        
        -- Cari target
        local target = nil
        for _, p in pairs(getAllPlayers()) do
            if p:getDisplayName():lower() == targetName:lower() then
                target = p
                break
            end
        end
        
        if not target then
            player:onConsoleMessage("`4Error:`w Player tidak ditemukan!")
            return true
        end
        
        if not CONFIG.prices[itemName] then
            player:onConsoleMessage("`4Error:`w Item '" .. itemName .. "' tidak valid!")
            player:onConsoleMessage("Item yang tersedia: Chemical, Cooking, Egg, Ghost, Milk, Miner, Startopia, Surgery, Wool")
            return true
        end
        
        addItem(target, itemName, amount)
        player:onConsoleMessage("`2✓ Memberikan `w" .. amount .. "x `2" .. itemName .. "`w ke `6" .. targetName .. "`w")
        target:onConsoleMessage("`2Kamu menerima `w" .. amount .. "x `2" .. itemName .. "`w dari admin!")
        return true
    end
    
    -- ADMIN: /givebgl
    if cmd == "givebgl" and #parts >= 3 then
        local targetName = parts[2]
        local amount = tonumber(parts[3]) or 0
        
        if amount <= 0 then
            player:onConsoleMessage("`4Error:`w Jumlah BGL harus lebih dari 0!")
            return true
        end
        
        -- Cari target
        local target = nil
        for _, p in pairs(getAllPlayers()) do
            if p:getDisplayName():lower() == targetName:lower() then
                target = p
                break
            end
        end
        
        if not target then
            player:onConsoleMessage("`4Error:`w Player tidak ditemukan!")
            return true
        end
        
        addBGL(target, amount)
        local newBGL = getBGL(target)
        local wl, sisa = bglToWL(newBGL)
        
        player:onConsoleMessage("`2✓ Memberikan `w" .. amount .. " BGL`w ke `6" .. targetName .. "`w")
        target:onConsoleMessage("")
        target:onConsoleMessage("`2Kamu menerima `w" .. amount .. " BGL`w dari admin!")
        target:onConsoleMessage("`6Total BGL:`w " .. string.format("%.0f", newBGL))
        if wl > 0 then
            target:onConsoleMessage("`6Total WL:`w " .. wl .. " WL `3(" .. sisa .. " BGL sisa)`w")
        end
        target:onConsoleMessage("")
        return true
    end
    
    -- ADMIN: /resetdaily
    if cmd == "resetdaily" then
        local targetName = parts[2]
        if not targetName then
            -- Reset sendiri
            resetDailyCount(player)
            player:onConsoleMessage("`2✓ Daily limit direset!")
            return true
        end
        
        -- Reset player lain
        local target = nil
        for _, p in pairs(getAllPlayers()) do
            if p:getDisplayName():lower() == targetName:lower() then
                target = p
                break
            end
        end
        
        if not target then
            player:onConsoleMessage("`4Error:`w Player tidak ditemukan!")
            return true
        end
        
        resetDailyCount(target)
        player:onConsoleMessage("`2✓ Daily limit `6" .. targetName .. "`w direset!")
        target:onConsoleMessage("`2Daily limit kamu direset oleh admin!")
        return true
    end
    
    return false
end)

-- ============================================
-- SIDEBAR BUTTON
-- ============================================

local function createButton()
    local btn = {
        active = true,
        buttonAction = "open_sell_menu",
        buttonTemplate = "BaseEventButton",
        counter = 0,
        counterMax = 0,
        itemIdIcon = CONFIG.iconId,
        name = "SellSystemButton",
        order = 0,
        rcssClass = "clash-event",
        text = "💰 Sell"
    }
    addSidebarButton(json.encode(btn))
    print("✅ Sell button created!")
end

createButton()

-- ============================================
-- BUTTON ACTION HANDLER
-- ============================================

onPlayerActionCallback(function(world, player, data)
    -- Debug (uncomment untuk cek)
    -- print("Action data:", json.encode(data))
    
    if data.action == "open_sell_menu" then
        showMenu(player)
        return true
    end
    
    -- Cek juga kemungkinan lain
    if data.buttonAction == "open_sell_menu" then
        showMenu(player)
        return true
    end
    
    return false
end)

-- ============================================
-- AUTO GIVE STARTING ITEMS (Optional)
-- ============================================

onPlayerLoginCallback(function(player)
    -- Beri 5 item gratis untuk starter (optional)
    -- addItem(player, "Chemical", 5)
    -- addItem(player, "Milk", 3)
    -- addItem(player, "Wool", 2)
    
    local bgl = getBGL(player)
    local wl, sisa = bglToWL(bgl)
    
    player:onConsoleMessage("")
    player:onConsoleMessage("`6╔══════════════════════════════╗`w")
    player:onConsoleMessage("`6║      SELL SYSTEM v3.0       ║`w")
    player:onConsoleMessage("`6╚══════════════════════════════╝`w")
    player:onConsoleMessage("")
    player:onConsoleMessage("Klik tombol `2💰 Sell`w di sidebar")
    player:onConsoleMessage("atau ketik `2/sell`w untuk membuka menu!")
    player:onConsoleMessage("`3Info:`w Setiap player punya BGL sendiri!")
    if wl > 0 then
        player:onConsoleMessage("`6BGL Kamu:`w " .. string.format("%.0f", bgl) .. " BGL `3(" .. wl .. " WL)`w")
    else
        player:onConsoleMessage("`6BGL Kamu:`w " .. string.format("%.0f", bgl) .. " BGL")
    end
    player:onConsoleMessage("`6Rate:`w 1 WL = " .. CONFIG.wlRate .. " BGL")
    player:onConsoleMessage("")
end)

-- ============================================
-- AUTO RESET DAILY (Setiap hari)
-- ============================================

-- Reset daily setiap jam 00:00 (sesuaikan dengan server)
-- Atau bisa dijalankan manual dengan /resetdaily

print("")
print("╔══════════════════════════════════════════╗")
print("║         SELL SYSTEM v3.0 LOADED!        ║")
print("╠══════════════════════════════════════════╣")
print("║                                         ║")
print("║  📋 COMMANDS:                           ║")
print("║  /sell         - Open menu              ║")
print("║  /mybgl        - Check BGL & WL         ║")
print("║  /wl           - Check WL conversion    ║")
print("║  /close        - Close menu             ║")
print("║                                         ║")
print("║  🔧 ADMIN COMMANDS:                     ║")
print("║  /giveitem     - Give item to player    ║")
print("║  /givebgl      - Give BGL to player     ║")
print("║  /resetdaily   - Reset daily limit      ║")
print("║                                         ║")
print("║  🎯 RATE: 1 WL = " .. CONFIG.wlRate .. " BGL        ║")
print("║                                         ║")
print("║  📱 Sidebar button: 💰 Sell             ║")
print("╚══════════════════════════════════════════╝")
print("")

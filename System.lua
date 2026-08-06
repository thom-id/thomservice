-- ============================================
-- SELL SYSTEM - GTPS Cloud Script
-- Menu jual item dengan berbagai kategori
-- ============================================

print("(Loaded) Sell System")

-- ============================================
-- KONFIGURASI
-- ============================================

local sellConfig = {
    bankBGL = 6261,  -- Total BGL di bank
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
    }
}

-- ============================================
-- FUNGSI UTAMA
-- ============================================

-- Fungsi untuk menampilkan menu utama (format seperti gambar)
local function showMainMenu(player)
    local menu = ""
    menu = menu .. "`2# Sell System`w\n"
    menu = menu .. "━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu = menu .. "Jual item kamu dan dapatkan\n"
    menu = menu .. "BGL langsung ke BANK!\n"
    menu = menu .. "━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu = menu .. "`2- Chemical`w\n"
    menu = menu .. "`2- Cooking`w\n"
    menu = menu .. "`2- Egg`w\n"
    menu = menu .. "`2- Ghost`w\n"
    menu = menu .. "`2- Milk`w\n"
    menu = menu .. "`2- Miner`w\n"
    menu = menu .. "`2- Startopia`w\n"
    menu = menu .. "`2- Surgery`w\n"
    menu = menu .. "`2- Wool`w\n"
    menu = menu .. "━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu = menu .. "`6Bank BGL:`w " .. string.format("%.0f", sellConfig.bankBGL) .. " BGL\n"
    menu = menu .. "━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu = menu .. "Pilih kategori di atas untuk\n"
    menu = menu .. "mulai jual item!\n"
    menu = menu .. "━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu = menu .. "`4/close`w - Tutup menu"
    
    player:onConsoleMessage(menu)
end

-- Fungsi untuk menjual item berdasarkan kategori
local function sellItem(player, category)
    local price = sellConfig.prices[category]
    if not price then
        player:onConsoleMessage("`4Error:`w Kategori tidak ditemukan!")
        return
    end
    
    -- Cek item di inventory (contoh sederhana)
    -- Anda perlu sesuaikan dengan API inventory server Anda
    local itemCount = 1  -- Ganti dengan logika pengecekan inventory
    
    if itemCount <= 0 then
        player:onConsoleMessage("`4Error:`w Kamu tidak memiliki item " .. category .. "!")
        return
    end
    
    -- Proses jual
    sellConfig.bankBGL = sellConfig.bankBGL + price
    player:onConsoleMessage("`2Sukses!`w Kamu menjual " .. category .. " seharga `6" .. price .. " BGL`w!")
    player:onConsoleMessage("`6Bank BGL:`w " .. string.format("%.0f", sellConfig.bankBGL) .. " BGL")
    
    -- Hapus item dari inventory (sesuaikan dengan API)
    -- player:removeItem(category, 1)
    
    -- Notifikasi bubble
    player:onTalkBubble(player:getNetID(), "💰 +" .. price .. " BGL", 1)
end

-- ============================================
-- REGISTRASI COMMAND
-- ============================================

-- Register semua command kategori
for _, category in ipairs(sellConfig.categories) do
    registerLuaCommand({
        command = category:lower(),
        roleRequired = 0,
        description = "Jual item " .. category
    })
end

-- Register command tambahan
registerLuaCommand({
    command = "sell",
    roleRequired = 0,
    description = "Tampilkan menu Sell System"
})

registerLuaCommand({
    command = "close",
    roleRequired = 0,
    description = "Tutup menu"
})

-- ============================================
-- HANDLER COMMAND
-- ============================================

onPlayerCommandCallback(function(world, player, fullCommand)
    local cmd = fullCommand:match("^(%S+)")
    if not cmd then return false end
    
    -- Command /sell - Tampilkan menu utama
    if cmd == "sell" then
        showMainMenu(player)
        return true
    end
    
    -- Command /close - Tutup menu
    if cmd == "close" then
        player:onConsoleMessage("`4Menu ditutup.`w Ketik `/sell`w untuk membuka kembali.")
        return true
    end
    
    -- Command kategori
    for _, category in ipairs(sellConfig.categories) do
        if cmd == category:lower() then
            sellItem(player, category)
            return true
        end
    end
    
    return false
end)

-- ============================================
-- SIDEBAR BUTTON - ICON POT (ID: 3033)
-- ============================================

local function addSellButton()
    local btn = {
        active = true,
        buttonAction = "opensellmenu",
        buttonTemplate = "BaseEventButton",
        counter = 0,
        counterMax = 0,
        itemIdIcon = 3033,  -- Icon Pot
        name = "SellSystemButton",
        order = 0,
        rcssClass = "clash-event",
        text = "💰 Sell"
    }
    addSidebarButton(json.encode(btn))
end

addSellButton()

-- Ketika button ditekan, langsung tampilkan menu
onPlayerActionCallback(function(world, player, data)
    if data.action == "opensellmenu" then
        showMainMenu(player)
        return true
    end
    return false
end)

-- ============================================
-- AUTO WELCOME
-- ============================================

onPlayerLoginCallback(function(player)
    player:onConsoleMessage("`6=== SELAMAT DATANG ===`w")
    player:onConsoleMessage("Klik tombol `2💰 Sell`w di sidebar")
    player:onConsoleMessage("untuk membuka Sell System!")
end)

print("(Loaded) Sell System ready!")

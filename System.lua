-- ============================================
-- SELL SYSTEM + AUCTION INTEGRATION
-- GTPS Cloud Script
-- Menu jual item + akses auction
-- ============================================

print("`2(Loaded) Sell System + Auction Integration`o")

-- ============================================
-- KONFIGURASI
-- ============================================

local sellConfig = {
    -- Key untuk save bank BGL
    BANK_KEY = "SELL_SYSTEM_BANK",
    
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
    itemIDs = {
        Chemical = 1234,  -- Ganti dengan ID item sebenarnya
        Cooking = 1235,
        Egg = 1236,
        Ghost = 1237,
        Milk = 1238,
        Miner = 1239,
        Startopia = 1240,
        Surgery = 1241,
        Wool = 1242
    }
}

-- ============================================
-- FUNGSI BANK BGL (Persistent)
-- ============================================

local function getBankBGL()
    local raw = loadDataFromServer(sellConfig.BANK_KEY)
    local amount = tonumber(raw)
    if not amount then amount = 0 end
    return amount
end

local function setBankBGL(amount)
    saveDataToServer(sellConfig.BANK_KEY, tostring(amount))
end

local function addBankBGL(amount)
    local current = getBankBGL()
    setBankBGL(current + amount)
end

-- ============================================
-- FUNGSI UTAMA
-- ============================================

-- Format menu dengan dialog (lebih keren!)
local function showMainMenu(player)
    local menu = ""
    menu = menu .. "add_label_with_icon|big|`2💰 Sell System``|left|3033|\n"
    menu = menu .. "add_smalltext|`7Jual item kamu dan dapatkan BGL langsung ke BANK!``|left|\n"
    menu = menu .. "add_spacer|small|\n"
    
    -- Tampilkan semua kategori dengan harga
    for _, category in ipairs(sellConfig.categories) do
        local price = sellConfig.prices[category]
        local itemID = sellConfig.itemIDs[category]
        local amount = player:getItemAmount(itemID) or 0
        menu = menu .. "add_label_with_icon|small|`2" .. category .. "`w - `6" .. price .. " BGL`w (`7" .. amount .. "x`w)|left|" .. itemID .. "|\n"
        menu = menu .. "add_button|sell_" .. category:lower() .. "|`2JUAL " .. category:upper() .. "|noflags|0|0|\n"
    end
    
    menu = menu .. "add_spacer|small|\n"
    menu = menu .. "add_smalltext|`6Bank BGL:`w " .. string.format("%.0f", getBankBGL()) .. " BGL|left|\n"
    menu = menu .. "add_spacer|small|\n"
    
    -- Button ke Auction
    menu = menu .. "add_button|go_auction|`9🏪 BUKA AUCTION|noflags|0|0|\n"
    
    menu = menu .. "end_dialog|sell_main|Close||\n"
    
    player:onDialogRequest(menu)
end

-- Fungsi jual item
local function sellItem(player, category)
    local price = sellConfig.prices[category]
    local itemID = sellConfig.itemIDs[category]
    
    if not price or not itemID then
        player:onConsoleMessage("`4Error:`w Kategori tidak ditemukan!")
        return
    end
    
    -- Cek item di inventory
    local itemCount = player:getItemAmount(itemID) or 0
    if itemCount <= 0 then
        player:onConsoleMessage("`4Error:`w Kamu tidak memiliki item " .. category .. "!")
        player:onTalkBubble(player:getNetID(), "❌ No " .. category, 1)
        showMainMenu(player)
        return
    end
    
    -- Proses jual (1 item per klik)
    player:changeItem(itemID, -1, 0)
    addBankBGL(price)
    
    -- Notifikasi
    player:onConsoleMessage("`2Sukses!`w Kamu menjual " .. category .. " seharga `6" .. price .. " BGL`w!")
    player:onConsoleMessage("`6Bank BGL:`w " .. string.format("%.0f", getBankBGL()) .. " BGL")
    player:onTalkBubble(player:getNetID(), "💰 +" .. price .. " BGL", 1)
    
    -- Refresh menu
    showMainMenu(player)
end

-- ============================================
-- FUNGSI BUKA AUCTION
-- ============================================

local function openAuction(player)
    -- Coba panggil auction system
    local auctionOpened = false
    
    -- Method 1: Panggil showList dari Auction.lua
    if type(showList) == "function" then
        showList(player)
        auctionOpened = true
    end
    
    -- Method 2: Panggil command /auction
    if not auctionOpened then
        player:onConsoleMessage("/auction")
        auctionOpened = true
    end
    
    -- Method 3: Fallback
    if not auctionOpened then
        player:onConsoleMessage("`4Auction system tidak tersedia. Gunakan /auction manual.`o")
    end
end

-- ============================================
-- REGISTRASI COMMAND
-- ============================================

-- Register command kategori
for _, category in ipairs(sellConfig.categories) do
    registerLuaCommand({
        command = "jual" .. category:lower(),
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
    command = "jual",
    roleRequired = 0,
    description = "Tampilkan menu Sell System (alias)"
})

registerLuaCommand({
    command = "auction",
    roleRequired = 0,
    description = "Buka Auction House"
})

-- ============================================
-- HANDLER COMMAND
-- ============================================

onPlayerCommandCallback(function(world, player, fullCommand)
    local cmd = fullCommand:match("^(%S+)")
    if not cmd then return false end
    
    -- Command /sell atau /jual
    if cmd == "sell" or cmd == "jual" then
        showMainMenu(player)
        return true
    end
    
    -- Command /auction
    if cmd == "auction" then
        openAuction(player)
        return true
    end
    
    -- Command jual kategori (format: /jualchemical)
    for _, category in ipairs(sellConfig.categories) do
        if cmd == "jual" .. category:lower() then
            sellItem(player, category)
            return true
        end
    end
    
    return false
end)

-- ============================================
-- SIDEBAR BUTTONS
-- ============================================

-- Button 1: Sell System (Pot Icon)
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

-- Button 2: Auction (DL Icon)
local function addAuctionButton()
    local btn = {
        active = true,
        buttonAction = "openauctionmenu",
        buttonTemplate = "BaseEventButton",
        counter = 0,
        counterMax = 0,
        itemIdIcon = 1796,  -- Icon DL
        name = "AuctionButton",
        order = 1,
        rcssClass = "clash-event",
        text = "🏪 Auction"
    }
    addSidebarButton(json.encode(btn))
end

-- Add kedua button
addSellButton()
addAuctionButton()

-- ============================================
-- SIDEBAR HANDLERS
-- ============================================

onPlayerActionCallback(function(world, player, data)
    -- Handler Sell
    if data.action == "opensellmenu" then
        showMainMenu(player)
        return true
    end
    
    -- Handler Auction
    if data.action == "openauctionmenu" then
        openAuction(player)
        return true
    end
    
    return false
end)

-- ============================================
-- DIALOG HANDLER
-- ============================================

onPlayerDialogCallback(function(world, player, data)
    if data.dialog_name == "sell_main" then
        -- Cek button jual kategori
        for _, category in ipairs(sellConfig.categories) do
            if data.buttonClicked == "sell_" .. category:lower() then
                sellItem(player, category)
                return true
            end
        end
        
        -- Button buka auction
        if data.buttonClicked == "go_auction" then
            openAuction(player)
            return true
        end
        
        return true
    end
    return false
end)

-- ============================================
-- ADMIN COMMAND - CEK BANK
-- ============================================

registerLuaCommand({
    command = "bankbgl",
    roleRequired = 1000,  -- Founder/Admin
    description = "Cek total BGL di bank"
})

onPlayerCommandCallback(function(world, player, fullCommand)
    local cmd = fullCommand:match("^(%S+)")
    if cmd == "bankbgl" then
        player:onConsoleMessage("`6Bank BGL:`w " .. string.format("%.0f", getBankBGL()) .. " BGL")
        return true
    end
    return false
end)

-- ============================================
-- AUTO WELCOME
-- ============================================

onPlayerLoginCallback(function(player)
    player:onConsoleMessage("`6=== SELAMAT DATANG ===`w")
    player:onConsoleMessage("Klik tombol `2💰 Sell`w atau `9🏪 Auction`w di sidebar")
    player:onConsoleMessage("Gunakan `/sell`w atau `/auction`w untuk membuka menu!")
end)

-- ============================================
-- LOADING COMPLETE
-- ============================================

print("`2(Loaded) Sell System + Auction Integration ready!`o")
print("`7- /sell atau /jual : Buka menu sell`o")
print("`7- /auction : Buka auction`o")
print("`7- Sidebar: 💰 Sell & 🏪 Auction`o")

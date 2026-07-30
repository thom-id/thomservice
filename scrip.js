/**
 * ============================================
 * BLAZETOPIA - Shop Roles & Items
 * Complete JavaScript
 * ============================================
 */

// ============================================
// SHOP DATA - Based on your list
// ============================================

const shopItems = [
    // ===== RESELLER =====
    {
        id: 1,
        name: '👑 Reseller',
        icon: '💼',
        price: 500000,
        priceType: 'IDR',
        category: 'role',
        badge: '⭐ Popular',
        badgeClass: 'badge-popular',
        stock: 5,
        sold: 0,
        features: [
            'Role: Super Developer, Developer, Moderator, Cheater, VIP',
            'Trusted SELLER BGL/GGL',
            'Get title [RESELLER] in game',
            'Buy lock price below regular players',
            'Special promotion channel for Resellers',
            'Verified in game'
        ],
        commands: []
    },
    
    // ===== UNLIMITED BLOCK =====
    {
        id: 2,
        name: '♾️ Unlimited Block',
        icon: '🧱',
        price: 250000,
        priceType: 'IDR',
        category: 'role',
        badge: '🔥 Hot',
        badgeClass: 'badge-popular',
        stock: 10,
        sold: 0,
        features: [
            'Role: Developer, Moderator, VIP',
            'Get title [MIDMAN] in game',
            'Get untradable box',
            'Access to world verif midman',
            'Special promotion channel for Middlemans'
        ],
        commands: []
    },
    
    // ===== MIDDLEMAN =====
    {
        id: 3,
        name: '🤝 Middleman',
        icon: '⚖️',
        price: 300000,
        priceType: 'IDR',
        category: 'role',
        badge: '💎 Premium',
        badgeClass: 'badge-role',
        stock: 8,
        sold: 0,
        features: [
            'Role: Moderator, Cheater, VIP',
            'Get title [UNLI BLOCK] in game',
            'In-game name color: Yellow',
            'Can sell blocks on vend'
        ],
        commands: []
    },
    
    // ===== SUPER DEVELOPER =====
    {
        id: 4,
        name: '⚡ Super Developer',
        icon: '👨‍💻',
        price: 150000,
        priceType: 'IDR',
        category: 'command',
        badge: '🔥 Popular',
        badgeClass: 'badge-popular',
        stock: 15,
        sold: 0,
        features: [
            'Role: Developer, Moderator, Cheater, VIP',
            'In-game name color: Dark Orange',
            'Access to private Moderator channels'
        ],
        commands: [
            '/color', '/e', '/entereffect', '/freezeall', '/killall',
            '/p', '/sdsb', '/trollnick', '/vernick', '/warn'
        ]
    },
    
    // ===== DEVELOPER =====
    {
        id: 5,
        name: '🛠️ Developer',
        icon: '💻',
        price: 75000,
        priceType: 'IDR',
        category: 'command',
        badge: '💎 Premium',
        badgeClass: 'badge-role',
        stock: 20,
        sold: 0,
        features: [
            'Role: Moderator, Cheater, VIP',
            'In-game name color: Yellow',
            'Access to private Moderator channels'
        ],
        commands: [
            '/1hit', '/banall', '/block', '/curse', '/door', '/dsb',
            '/hide', '/longmode', '/mute', '/nick', '/pullall',
            '/ssb', '/uncurse', '/unmute', '/weather'
        ]
    },
    
    // ===== MODERATOR =====
    {
        id: 6,
        name: '🔨 Moderator',
        icon: '🛡️',
        price: 50000,
        priceType: 'IDR',
        category: 'command',
        badge: '🛡️ Mod',
        badgeClass: 'badge-role',
        stock: 25,
        sold: 0,
        features: [
            'Role: Cheater, VIP',
            'In-game name color: Purple',
            'Access to private Moderator channels'
        ],
        commands: [
            '/find', '/g', '/info', '/invis', '/magic',
            '/nuke', '/snuke', '/summon', '/togglemods'
        ]
    },
    
    // ===== VIP + CHEATER =====
    {
        id: 7,
        name: '⭐ VIP + Cheater',
        icon: '👑',
        price: 25000,
        priceType: 'IDR',
        category: 'feature',
        badge: '👑 VIP',
        badgeClass: 'badge-vip',
        stock: 50,
        sold: 0,
        features: [
            'Role: Cheater, VIP',
            'In-game name color: White'
        ],
        commands: [
            '/rainbow', '/tpclick', '/v', '/valentine', '/vsb'
        ]
    }
];

// ============================================
// PLAYER DATA
// ============================================

let playerData = {
    username: 'Guest',
    balance: 0,
    isLoggedIn: false,
    inventory: []
};

// ============================================
// DOM REFS
// ============================================

const DOM = {
    shopGrid: document.getElementById('shopGrid'),
    searchInput: document.getElementById('searchInput'),
    tabs: document.querySelectorAll('.tab'),
    usernameDisplay: document.getElementById('usernameDisplay'),
    playerBalance: document.getElementById('playerBalance')
};

// ============================================
// RENDER SHOP
// ============================================

function renderShop(category = 'all', searchQuery = '') {
    if (!DOM.shopGrid) return;

    let filtered = shopItems;

    // Filter by category
    if (category !== 'all') {
        filtered = filtered.filter(item => item.category === category);
    }

    // Filter by search
    if (searchQuery && searchQuery.trim() !== '') {
        const query = searchQuery.toLowerCase().trim();
        filtered = filtered.filter(item => 
            item.name.toLowerCase().includes(query) ||
            item.features.some(f => f.toLowerCase().includes(query)) ||
            item.commands.some(c => c.toLowerCase().includes(query))
        );
    }

    if (filtered.length === 0) {
        DOM.shopGrid.innerHTML = `
            <div class="empty-state" style="grid-column: 1/-1; text-align:center; padding:50px 20px; color:#666;">
                <div style="font-size:48px; margin-bottom:15px;">🔍</div>
                <p style="font-size:18px; font-weight:600; color:#888;">No items found</p>
                <p style="font-size:14px; margin-top:5px;">Try adjusting your search or filter</p>
            </div>
        `;
        return;
    }

    DOM.shopGrid.innerHTML = filtered.map(item => {
        const isSoldOut = item.stock - item.sold <= 0;
        const priceDisplay = item.priceType === 'IDR' 
            ? `Rp ${formatRupiah(item.price)}` 
            : `${item.price} ${item.priceType}`;

        const featuresHTML = item.features.length > 0 ? `
            <ul class="features-list">
                ${item.features.map(f => `<li>${f}</li>`).join('')}
            </ul>
        ` : '';

        const commandsHTML = item.commands.length > 0 ? `
            <div class="commands-list">
                ${item.commands.map(cmd => `<code>${cmd}</code>`).join('')}
            </div>
        ` : '';

        return `
            <div class="shop-item ${isSoldOut ? 'sold-out' : ''}" data-id="${item.id}">
                <span class="icon">${item.icon}</span>
                <div class="name">${item.name}</div>
                <div class="price">${priceDisplay}</div>
                <div class="badge-container">
                    <span class="badge ${item.badgeClass}">${item.badge}</span>
                    ${item.stock - item.sold <= 3 && !isSoldOut ? 
                        `<span class="badge badge-popular" style="font-size:9px;">🔥 Low Stock</span>` : ''}
                </div>
                ${featuresHTML}
                ${commandsHTML}
                <button class="buy-btn" 
                        onclick="buyItem(${item.id})"
                        ${isSoldOut ? 'disabled' : ''}>
                    ${isSoldOut ? '❌ Sold Out' : '🛒 Buy Now - ' + priceDisplay}
                </button>
            </div>
        `;
    }).join('');
}

// ============================================
// FILTER SHOP
// ============================================

function filterShop(category, button) {
    // Update active tab
    DOM.tabs.forEach(tab => tab.classList.remove('active'));
    if (button) button.classList.add('active');

    const searchQuery = DOM.searchInput ? DOM.searchInput.value : '';
    renderShop(category, searchQuery);
}

// ============================================
// SEARCH ITEMS
// ============================================

function searchItems(query) {
    const activeTab = document.querySelector('.tab.active');
    const category = activeTab ? activeTab.dataset.category : 'all';
    renderShop(category, query);
}

// ============================================
// BUY ITEM
// ============================================

function buyItem(itemId) {
    const item = shopItems.find(i => i.id === itemId);
    if (!item) {
        showToast('❌ Item not found!', 'error');
        return;
    }

    if (item.stock - item.sold <= 0) {
        showToast('❌ This item is sold out!', 'error');
        return;
    }

    // Confirmation
    const priceDisplay = item.priceType === 'IDR' 
        ? `Rp ${formatRupiah(item.price)}` 
        : `${item.price} ${item.priceType}`;

    if (!confirm(`Are you sure you want to buy ${item.name} for ${priceDisplay}?`)) {
        return;
    }

    // Process purchase
    processPurchase(item);
}

function processPurchase(item) {
    const btn = document.querySelector(`.shop-item[data-id="${item.id}"] .buy-btn`);
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner"></span> Processing...';
    }

    // Simulate payment processing
    setTimeout(() => {
        item.sold += 1;
        playerData.inventory.push({
            id: item.id,
            name: item.name,
            price: item.price,
            priceType: item.priceType,
            purchasedAt: new Date().toISOString()
        });

        showToast(`✅ Success! ${item.icon} ${item.name} purchased!`, 'success');

        if (btn) {
            btn.innerHTML = '✅ Purchased';
            btn.disabled = true;
        }

        // Re-render to update stock
        const activeTab = document.querySelector('.tab.active');
        const category = activeTab ? activeTab.dataset.category : 'all';
        const searchQuery = DOM.searchInput ? DOM.searchInput.value : '';
        renderShop(category, searchQuery);
    }, 2000);
}

// ============================================
// TOGGLE LOGIN
// ============================================

function toggleLogin() {
    if (playerData.isLoggedIn) {
        playerData.isLoggedIn = false;
        playerData.username = 'Guest';
        document.querySelector('.btn-login').textContent = '🔑 Login';
        showToast('👋 Logged out successfully!', 'info');
    } else {
        const username = prompt('Enter your Growtopia username:');
        if (username && username.trim()) {
            playerData.isLoggedIn = true;
            playerData.username = username.trim();
            document.querySelector('.btn-login').textContent = '🚪 Logout';
            showToast(`✅ Welcome back, ${playerData.username}!`, 'success');
        }
    }
    updateBalanceDisplay();
}

// ============================================
// UPDATE BALANCE DISPLAY
// ============================================

function updateBalanceDisplay() {
    if (DOM.usernameDisplay) {
        DOM.usernameDisplay.textContent = `👤 ${playerData.username}`;
    }
    if (DOM.playerBalance) {
        DOM.playerBalance.textContent = `💎 ${playerData.balance} Gems | 🔒 0 WL`;
    }
}

// ============================================
// TOAST NOTIFICATION
// ============================================

function showToast(message, type = 'info') {
    const oldToast = document.querySelector('.toast');
    if (oldToast) oldToast.remove();

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;
    document.body.appendChild(toast);

    setTimeout(() => {
        toast.classList.add('toast-out');
        setTimeout(() => toast.remove(), 400);
    }, 4000);
}

// ============================================
// UTILITY FUNCTIONS
// ============================================

function formatRupiah(amount) {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
}

// ============================================
// EXPOSE TO GLOBAL
// ============================================

window.buyItem = buyItem;
window.filterShop = filterShop;
window.searchItems = searchItems;
window.toggleLogin = toggleLogin;

// ============================================
// INIT
// ============================================

document.addEventListener('DOMContentLoaded', () => {
    renderShop('all');
    updateBalanceDisplay();
});

console.log('%c🔥 BlazeTopia Shop Loaded!', 'color: #ff3030; font-size: 20px; font-weight: bold;');
console.log('%cTotal items: ' + shopItems.length, 'color: #ff8800;');
console.log('%cType shopItems to see all items', 'color: #888;');

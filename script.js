// ===== Sembunyikan loading =====
document.getElementById('loading').style.display = 'none';

// ===== Fungsi Scroll ke FAQ =====
function goToFAQ() {
    document.querySelectorAll('.container').forEach(el => {
        el.classList.remove('active');
    });
    document.getElementById('page-home').classList.add('active');

    setTimeout(() => {
        const faqSection = document.getElementById('faqSection');
        if (faqSection) {
            faqSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }, 100);
}

// ===== Fungsi pindah halaman =====
function showPage(pageId, paket) {
    document.querySelectorAll('.container').forEach(el => {
        el.classList.remove('active');
    });
    document.getElementById(pageId).classList.add('active');

    if (pageId === 'page-order' && paket) {
        document.getElementById('paket').value = paket;
        updateQRIS();
        toggleCustomRequest();
        updateTerms();
        updateQRISVisibility();
    }
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// ===== Tampilkan/Sembunyikan Custom Request =====
function toggleCustomRequest() {
    const paket = document.getElementById('paket').value;
    const wrapper = document.getElementById('customRequestWrapper');
    const textarea = document.getElementById('custom_request');

    if (paket === 'B') {
        wrapper.style.display = 'none';
        textarea.value = '';
    } else if (paket === 'A') {
        wrapper.style.display = 'block';
    } else {
        wrapper.style.display = 'none';
        textarea.value = '';
    }
}

// ===== Update Informasi Penting =====
function updateTerms() {
    const paket = document.getElementById('paket').value;
    const termsList = document.getElementById('termsList');

    termsList.innerHTML = '';

    let terms = [];
    if (paket === 'A') {
        terms.push('Free Revisi 1x');
    }
    terms.push('No Refund / Pengembalian Dana');
    terms.push('Proses pengerjaan sesuai antrian');

    terms.forEach(term => {
        const li = document.createElement('li');
        li.textContent = term;
        li.style.marginBottom = '4px';
        termsList.appendChild(li);
    });
}

// ===== Tampilkan/Sembunyikan QRIS =====
function updateQRISVisibility() {
    const paket = document.getElementById('paket').value;
    const qrisSection = document.getElementById('qrisSection');
    const placeholder = document.getElementById('qrisPlaceholder');

    if (paket === 'B' || paket === 'A') {
        qrisSection.style.display = 'block';
        placeholder.style.display = 'none';
        updateQRIS();
    } else {
        qrisSection.style.display = 'none';
        placeholder.style.display = 'block';
    }
}

// ===== Update total harga =====
function updateQRIS() {
    const paket = document.getElementById('paket').value;
    const hargaMap = { B: 'Rp15.000', A: 'Rp25.000' };
    document.getElementById('totalDisplay').textContent = 'Total: ' + (hargaMap[paket] || 'Rp0');
}

// ===== Submit Order =====
async function submitOrder(event) {
    event.preventDefault();

    const form = document.getElementById('orderForm');
    const formData = new FormData(form);

    const paket = formData.get('paket');
    const nama_server = formData.get('nama_server');
    const custom_request = formData.get('custom_request') || '-';
    const logo_server = formData.get('logo_server');
    const bukti = formData.get('bukti');
    const discord_id = formData.get('discord_id');

    if (!paket) {
        alert('⚠️ Silakan pilih paket terlebih dahulu!');
        return;
    }

    if (!bukti || bukti.size === 0) {
        alert('⚠️ Silakan upload bukti pembayaran!');
        return;
    }

    const hargaMap = { B: 'Rp15.000', A: 'Rp25.000' };
    const total_harga = hargaMap[paket] || 'Rp0';

    const WEBHOOK_URL = 'https://discord.com/api/webhooks/1545504866653446204/teWMxRPPTjyj1wXvtjfE2QreBr1l_kVUB43lGLbFteG7Bh7zVHfrJpmXx0JlO4yqmzGG';

    const reader = new FileReader();
    reader.readAsDataURL(bukti);
    reader.onload = async function() {
        let mentionText = '';
        if (discord_id && discord_id.trim() !== '') {
            let cleanInput = discord_id.trim().replace(/^@/, '');
            if (/^\d{17,19}$/.test(cleanInput)) {
                mentionText = `<@${cleanInput}>`;
            } else {
                mentionText = `@${cleanInput}`;
            }
        }

        let fields = [
            { name: '- Paket', value: `Paket ${paket} - ${total_harga}`, inline: true },
            { name: '- Nama Server', value: nama_server, inline: true }
        ];

        if (paket === 'A' && custom_request && custom_request !== '-') {
            fields.push({ name: '• Custom Request', value: custom_request, inline: false });
        }

        fields.push({ name: '• Bukti Bayar', value: 'Lihat lampiran di bawah ↓', inline: false });

        if (logo_server && logo_server.size > 0) {
            fields.splice(2, 0, { name: '• Logo Server', value: 'Terdapat lampiran logo', inline: true });
        }

        let content = `**PESANAN BARU DARI WEBSITE!**`;
        
        if (mentionText) {
            content += `\n${mentionText} pesanan kamu sedang diproses!`;
        }

        const payload = {
            content: content,
            embeds: [{
                title: 'Detail Pesanan',
                color: 16766720,
                fields: fields,
                footer: { text: `How To Service | ${new Date().toLocaleString('id-ID')}` }
            }]
        };

        try {
            const res1 = await fetch(WEBHOOK_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            const formDataFile = new FormData();
            formDataFile.append('file', bukti);
            const res2 = await fetch(WEBHOOK_URL + '?wait=true', {
                method: 'POST',
                body: formDataFile
            });

            let res3 = { ok: true };
            if (logo_server && logo_server.size > 0) {
                const formDataLogo = new FormData();
                formDataLogo.append('file', logo_server);
                res3 = await fetch(WEBHOOK_URL + '?wait=true', {
                    method: 'POST',
                    body: formDataLogo
                });
            }

            if (res1.ok && res2.ok && res3.ok) {
                showPage('page-success');
            } else {
                alert('⚠️ Gagal mengirim ke Discord. Coba lagi nanti.');
            }
        } catch (error) {
            alert('⚠️ Error: ' + error.message);
        }
    };

    reader.onerror = function() {
        alert('⚠️ Gagal membaca file bukti.');
    };
}

// ===== URL Parameter =====
(function() {
    const params = new URLSearchParams(window.location.search);
    const paket = params.get('paket');
    if (paket && ['B', 'A'].includes(paket)) {
        showPage('page-order', paket);
    }
})();

// ===== Inisialisasi =====
updateQRIS();
toggleCustomRequest();
updateTerms();
updateQRISVisibility();

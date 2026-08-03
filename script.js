// Navbar shadow saat scroll
const header = document.querySelector("header");

window.addEventListener("scroll", () => {
    if (window.scrollY > 50) {
        header.style.background = "rgba(8,8,15,.95)";
        header.style.boxShadow = "0 8px 25px rgba(0,0,0,.35)";
    } else {
        header.style.background = "rgba(10,10,18,.85)";
        header.style.boxShadow = "none";
    }
});

// Animasi muncul saat scroll
const elements = document.querySelectorAll(
".feature-card,.price-card,.faq-item,.stat-box,.hero-card"
);

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = "1";
            entry.target.style.transform = "translateY(0)";
        }
    });
}, {
    threshold: 0.15
});

elements.forEach(el => {
    el.style.opacity = "0";
    el.style.transform = "translateY(30px)";
    el.style.transition = "all .6s ease";
    observer.observe(el);
});

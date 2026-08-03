// Navbar Effect

const header = document.querySelector("header");

window.addEventListener("scroll", () => {

    if (window.scrollY > 40) {

        header.style.background = "rgba(8,8,8,.95)";
        header.style.boxShadow = "0 10px 30px rgba(0,0,0,.35)";

    } else {

        header.style.background = "rgba(0,0,0,.65)";
        header.style.boxShadow = "none";

    }

});




// Scroll Animation

const cards = document.querySelectorAll(
".service-card,.price-card,.step,.review-card,.template-box"
);


const observer = new IntersectionObserver((entries)=>{

    entries.forEach(entry=>{

        if(entry.isIntersecting){

            entry.target.style.opacity="1";
            entry.target.style.transform="translateY(0)";

        }

    });

},{

    threshold:0.15

});



cards.forEach(card=>{

    card.style.opacity="0";
    card.style.transform="translateY(40px)";
    card.style.transition=".6s ease";

    observer.observe(card);

});




// Smooth Button Hover

document.querySelectorAll(".btn,.btn2").forEach(btn=>{


    btn.addEventListener("mouseenter",()=>{

        btn.style.transform="translateY(-3px)";

    });


    btn.addEventListener("mouseleave",()=>{

        btn.style.transform="translateY(0)";

    });


});




// Simple Loading Animation

window.addEventListener("load",()=>{

    document.body.style.opacity="1";

});// Order Form System

const orderForm = document.getElementById("orderForm");


if(orderForm){


orderForm.addEventListener("submit", function(e){


    e.preventDefault();



    const discord = document.getElementById("discordName").value;

    const server = document.getElementById("serverName").value;

    const invite = document.getElementById("inviteLink").value;

    const pack = document.getElementById("package").value;




    const orderMessage =

`🔥 NEW ORDER THOM SERVICE


👤 Discord:
${discord}


🏠 Server:
${server}


🔗 Invite:
${invite}


📦 Package:
${pack}`;





    console.log(orderMessage);





    alert(

"✅ Order berhasil dibuat!\n\nSilahkan lanjut ke Discord THOM SERVICE untuk pembayaran dan proses setup."

    );





    window.open(

"https://discord.gg/WpTvRdcu5",

"_blank"

    );



});


}

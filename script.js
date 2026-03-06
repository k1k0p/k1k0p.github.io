document.addEventListener("DOMContentLoaded", () => {

    /* =========================
    SCROLL ANIMATION
    ========================= */

    const sections = document.querySelectorAll("section:not(.hero)");

    const observer = new IntersectionObserver((entries) => {

        entries.forEach(entry => {

            if (entry.isIntersecting) {

                entry.target.classList.add("visible");

            }

        });

    }, { threshold: 0.15 });

    sections.forEach(section => observer.observe(section));


    /* =========================
    TYPING EFFECT
    ========================= */

    function typeEffect(id, text, speed = 150) {

        const el = document.getElementById(id);

        if (!el) return;

        let i = 0;

        function type() {

            if (i <= text.length) {

                el.innerHTML =
                    `<span class="highlight">${text.slice(0, i)}</span><span class="cursor">|</span>`;

                i++;

                setTimeout(type, speed);

            }

        }

        type();

    }

    /* CALL */

    typeEffect("typing-name", "Pandeirada", 140);
    typeEffect("typing-2048", "2048");
    typeEffect("typing-redes", "Redes");
    typeEffect("typing-fitnow", "Now");
    typeEffect("typing-ihc", "Computador");
    typeEffect("typing-bd", "Dados");
    typeEffect("typing-poo", "Objetos");
    typeEffect("typing-pweb", "Web");
    typeEffect("typing-logica", "Lógica");


    /* =========================
    CARD LIGHT FOLLOW CURSOR
    ========================= */

    const cards = document.querySelectorAll(".project-card");

    cards.forEach(card => {

        card.addEventListener("mousemove", e => {

            const rect = card.getBoundingClientRect();

            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;

            card.style.setProperty("--x", x + "px");
            card.style.setProperty("--y", y + "px");

        });

    });

});

document.addEventListener("DOMContentLoaded", () => {

    const navbar = document.querySelector(".navbar");

    let lastScroll = 0;

    window.addEventListener("scroll", () => {

        const currentScroll = window.scrollY;

        const pageHeight = document.documentElement.scrollHeight;
        const windowHeight = window.innerHeight;

        const nearBottom = currentScroll + windowHeight >= pageHeight - 80;
        const nearTop = currentScroll <= 10;


        /* sempre mostrar no topo */

        if (nearTop) {
            navbar.classList.remove("hidden");
            lastScroll = currentScroll;
            return;
        }


        /* scroll para baixo */

        if (currentScroll > lastScroll && !nearBottom) {

            navbar.classList.add("hidden");

        }

        /* scroll para cima */

        else if (currentScroll < lastScroll) {

            navbar.classList.remove("hidden");

        }

        lastScroll = currentScroll;

    });

});
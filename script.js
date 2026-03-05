document.addEventListener("DOMContentLoaded", () => {

  /* =========================
     SCROLL ANIMATION
  ========================== */

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
     TYPING FUNCTION
  ========================== */

  function typeEffect(elementId, text, speed = 160) {

    const el = document.getElementById(elementId);

    if (!el) return;

    let index = 0;

    function type() {

      if (index <= text.length) {

        el.innerHTML =
          `<span class="highlight">${text.slice(0,index)}</span><span class="cursor">|</span>`;

        index++;

        setTimeout(type, speed);

      }

    }

    type();

  }

  /* =========================
     CALL EFFECTS
  ========================== */

  typeEffect("typing-name","Pandeirada",140);
  typeEffect("typing-2048","2048",180);
  typeEffect("typing-redes","Redes",180);
  typeEffect("typing-fitnow","Now",160);     // fica "FitNow" se escreveres "Fit" no HTML
  typeEffect("typing-ihc","Computador",160);
  typeEffect("typing-bd","Dados",160);
  typeEffect("typing-poo","Objetos",160);
  typeEffect("typing-pweb","Web",160);
  typeEffect("typing-logica","Lógica",160);

});
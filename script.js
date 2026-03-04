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
     HOMEPAGE NAME TYPING
  ========================== */

  const nameEl = document.getElementById("typing-name");

  if (nameEl) {

    const lastName = "Pandeirada";

    let index = 0;

    function typeName() {

      if (index <= lastName.length) {

        nameEl.innerHTML =
          `<span class="highlight">${lastName.slice(0,index)}</span><span class="cursor">|</span>`;

        index++;

        setTimeout(typeName, 160);
      }

    }

    typeName();
  }


  /* =========================
     PROJECT 2048 TYPING
  ========================== */

  const projectEl = document.getElementById("typing-2048");

  if (projectEl) {

    const text = "2048";

    let index = 0;

    function typeProject() {

      if (index <= text.length) {

        projectEl.innerHTML =
          `<span class="highlight">${text.slice(0,index)}</span><span class="cursor">|</span>`;

        index++;

        setTimeout(typeProject, 180);
      }

    }

    typeProject();
  }

});

  /* =========================
     REDES NAME TYPING
  ========================== */

  const redesEl = document.getElementById("typing-redes");

if (redesEl) {

  const text = "Redes";
  let index = 0;

  function typeRedes() {

    if (index <= text.length) {

      redesEl.innerHTML =
        '<span class="highlight">' + text.slice(0, index) + '</span><span class="cursor">|</span>';

      index++;

      setTimeout(typeRedes, 180);
    }
  }

  typeRedes();
}
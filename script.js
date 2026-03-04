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
     TYPING EFFECT
  ========================== */

  const typingEl = document.getElementById("typing");

  if (typingEl) {
    const firstName = "Francisco ";
    const lastName = "Pandeirada";
    const fullName = firstName + lastName;

    let index = 0;

    function typeWriter() {
      if (index <= fullName.length) {

        const currentText = fullName.slice(0, index);
        const lastIndex = currentText.indexOf(lastName);

        if (lastIndex >= 0) {
          const before = currentText.slice(0, lastIndex);
          const lastPart = currentText.slice(lastIndex);
          typingEl.innerHTML =
            `${before}<span class="highlight">${lastPart}</span>`;
        } else {
          typingEl.textContent = currentText;
        }

        index++;
        setTimeout(typeWriter, 70);
      }
    }

    typeWriter();
  }

});
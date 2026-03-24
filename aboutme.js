document.addEventListener("DOMContentLoaded", () => {
  const revealElements = document.querySelectorAll(".reveal");

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
        }
      });
    },
    {
      threshold: 0.18,
      rootMargin: "0px 0px -8% 0px"
    }
  );

  revealElements.forEach((element) => {
    observer.observe(element);
  });

  updateBackgroundShift();
  window.addEventListener("scroll", updateBackgroundShift, { passive: true });
});

function updateBackgroundShift() {
  const shift = window.scrollY * -0.08;
  document.documentElement.style.setProperty("--bg-shift", `${shift}px`);
}

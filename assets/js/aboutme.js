document.addEventListener("DOMContentLoaded", () => {
  setupMobileNav();
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

function setupMobileNav() {
  const topbar = document.querySelector(".chapter-topbar");
  const toggle = document.querySelector(".mobile-nav-toggle");
  const nav = document.querySelector(".chapter-nav");

  if (!topbar || !toggle || !nav) {
    return;
  }

  const closeNav = () => {
    topbar.classList.remove("is-nav-open");
    toggle.setAttribute("aria-expanded", "false");
  };

  toggle.addEventListener("click", () => {
    const isOpen = topbar.classList.toggle("is-nav-open");
    toggle.setAttribute("aria-expanded", String(isOpen));
  });

  nav.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", closeNav);
  });

  document.addEventListener("click", (event) => {
    if (!topbar.contains(event.target)) {
      closeNav();
    }
  });

  window.addEventListener("resize", () => {
    if (window.innerWidth > 575.98) {
      closeNav();
    }
  });
}

document.addEventListener("DOMContentLoaded", () => {
  setupMobileNav();
  const revealElements = document.querySelectorAll(".reveal");

  if (!revealElements.length) {
    return;
  }

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
        }
      });
    },
    {
      threshold: 0.16,
      rootMargin: "0px 0px -8% 0px"
    }
  );

  revealElements.forEach((element) => {
    observer.observe(element);
  });
});

function setupMobileNav() {
  const topbar = document.querySelector(".content-topbar");
  const toggle = document.querySelector(".mobile-nav-toggle");
  const nav = document.querySelector(".content-nav");

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

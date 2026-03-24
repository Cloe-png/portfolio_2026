document.addEventListener("DOMContentLoaded", () => {
  setupMobileNav();
  setupStageShowcase();
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

function setupStageShowcase() {
  const showcase = document.querySelector(".stage-showcase");
  const slides = Array.from(document.querySelectorAll(".stage-slide"));
  const dots = Array.from(document.querySelectorAll("#stagePagination button"));
  const prevButton = document.querySelector("#prevStage");
  const nextButton = document.querySelector("#nextStage");

  if (!showcase || !slides.length) {
    return;
  }

  let activeIndex = 0;
  let touchStartX = 0;
  let touchStartY = 0;
  let touchDeltaX = 0;
  let touchDeltaY = 0;

  const setActiveSlide = (index) => {
    activeIndex = (index + slides.length) % slides.length;

    slides.forEach((slide, slideIndex) => {
      slide.classList.toggle("is-active", slideIndex === activeIndex);
    });

    dots.forEach((dot, dotIndex) => {
      dot.classList.toggle("is-active", dotIndex === activeIndex);
    });

    showcase.dataset.stageTheme = slides[activeIndex].dataset.stageTheme || "orange";
  };

  prevButton?.addEventListener("click", () => {
    setActiveSlide(activeIndex - 1);
  });

  nextButton?.addEventListener("click", () => {
    setActiveSlide(activeIndex + 1);
  });

  dots.forEach((dot, dotIndex) => {
    dot.addEventListener("click", () => {
      setActiveSlide(dotIndex);
    });
  });

  window.addEventListener("keydown", (event) => {
    if (event.key === "ArrowLeft") {
      setActiveSlide(activeIndex - 1);
    }

    if (event.key === "ArrowRight") {
      setActiveSlide(activeIndex + 1);
    }
  });

  showcase.addEventListener("touchstart", (event) => {
    const touch = event.changedTouches[0];
    touchStartX = touch.clientX;
    touchStartY = touch.clientY;
    touchDeltaX = 0;
    touchDeltaY = 0;
  }, { passive: true });

  showcase.addEventListener("touchmove", (event) => {
    const touch = event.changedTouches[0];
    touchDeltaX = touch.clientX - touchStartX;
    touchDeltaY = touch.clientY - touchStartY;
  }, { passive: true });

  showcase.addEventListener("touchend", () => {
    const minSwipeDistance = 50;
    const isHorizontalSwipe = Math.abs(touchDeltaX) > Math.abs(touchDeltaY);

    if (!isHorizontalSwipe || Math.abs(touchDeltaX) < minSwipeDistance) {
      return;
    }

    if (touchDeltaX < 0) {
      setActiveSlide(activeIndex + 1);
      return;
    }

    setActiveSlide(activeIndex - 1);
  });

  setActiveSlide(0);
}

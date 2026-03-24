document.addEventListener("DOMContentLoaded", () => {
  const slider = document.querySelector(".chapter-slider");
  const slides = Array.from(document.querySelectorAll(".chapter-slide"));
  const dots = Array.from(document.querySelectorAll(".chapter-pagination button"));
  const prevButton = document.querySelector("#prevChapter");
  const nextButton = document.querySelector("#nextChapter");
  const hasEntryTransition = getEntryTransitionState();

  if (!slider || !slides.length) {
    return;
  }

  if (hasEntryTransition) {
    document.body.classList.add("is-entering-chapters");
    window.setTimeout(() => {
      document.body.classList.remove("is-entering-chapters");
    }, 1100);
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

    slider.dataset.activeTheme = slides[activeIndex].dataset.theme || "emerald";
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

  slider.addEventListener("touchstart", (event) => {
    const touch = event.changedTouches[0];
    touchStartX = touch.clientX;
    touchStartY = touch.clientY;
    touchDeltaX = 0;
    touchDeltaY = 0;
  }, { passive: true });

  slider.addEventListener("touchmove", (event) => {
    const touch = event.changedTouches[0];
    touchDeltaX = touch.clientX - touchStartX;
    touchDeltaY = touch.clientY - touchStartY;
  }, { passive: true });

  slider.addEventListener("touchend", () => {
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
});

function getEntryTransitionState() {
  try {
    const value = window.sessionStorage.getItem("chapter-entry");
    if (value === "from-index") {
      window.sessionStorage.removeItem("chapter-entry");
      return true;
    }
  } catch (error) {
    return false;
  }

  return false;
}

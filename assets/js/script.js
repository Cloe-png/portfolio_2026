document.addEventListener("DOMContentLoaded", () => {
  const enterButton = document.querySelector("#enterButton");
  let isTransitioning = false;

  if (enterButton) {
    enterButton.addEventListener("click", async (event) => {
      event.preventDefault();

      if (isTransitioning) {
        return;
      }

      isTransitioning = true;
      enterButton.classList.add("is-locked");
      document.body.classList.add("is-transitioning");

      await playArcadeSequence();

      const targetUrl = enterButton.getAttribute("href") || "chapters.html";
      window.location.href = targetUrl;
    });
  }
});

async function playArcadeSequence() {
  playAmbientSound();
  markChapterArrival();
  await wait(1850);
}

function markChapterArrival() {
  try {
    window.sessionStorage.setItem("chapter-entry", "from-index");
  } catch (error) {
    // Ignore storage failures and keep the redirect flow working.
  }
}

function wait(duration) {
  return new Promise((resolve) => {
    window.setTimeout(resolve, duration);
  });
}

function playAmbientSound() {
  const AudioContextClass = window.AudioContext || window.webkitAudioContext;

  if (!AudioContextClass) {
    return;
  }

  const audioContext = new AudioContextClass();
  const now = audioContext.currentTime;
  const masterGain = audioContext.createGain();

  masterGain.gain.setValueAtTime(0.0001, now);
  masterGain.gain.exponentialRampToValueAtTime(0.08, now + 0.18);
  masterGain.gain.exponentialRampToValueAtTime(0.0001, now + 1.75);
  masterGain.connect(audioContext.destination);

  createTone(audioContext, masterGain, now + 0.00, 261.63, 0.7, "sine");
  createTone(audioContext, masterGain, now + 0.18, 329.63, 0.86, "sine");
  createTone(audioContext, masterGain, now + 0.42, 392.0, 0.92, "triangle");
  createTone(audioContext, masterGain, now + 0.86, 523.25, 0.62, "sine");

  window.setTimeout(() => {
    audioContext.close().catch(() => {});
  }, 2100);
}

function createTone(audioContext, destination, startTime, frequency, duration, type) {
  const oscillator = audioContext.createOscillator();
  const gainNode = audioContext.createGain();

  oscillator.type = type;
  oscillator.frequency.setValueAtTime(frequency, startTime);
  oscillator.frequency.exponentialRampToValueAtTime(Math.max(80, frequency * 0.92), startTime + duration);

  gainNode.gain.setValueAtTime(0.0001, startTime);
  gainNode.gain.exponentialRampToValueAtTime(0.14, startTime + 0.08);
  gainNode.gain.exponentialRampToValueAtTime(0.0001, startTime + duration);

  oscillator.connect(gainNode);
  gainNode.connect(destination);
  oscillator.start(startTime);
  oscillator.stop(startTime + duration + 0.02);
}

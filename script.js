const modeButtons = document.querySelectorAll('.mode-item');
const infoCards = document.querySelectorAll('.info-card');
const backBtn = document.getElementById('backBtn');
const backToStagesBtn = document.getElementById('backToStagesBtn');
const settingsBtn = document.getElementById('settingsBtn');
const avatarCard = document.querySelector('.avatar-card');
const pressStartBtn = document.getElementById('pressStartBtn');
const pageRoutes = {
  presentation: 'chapitres.html#presentation',
  stage: 'chapitres.html#stage',
  veille: 'chapitres.html#veille',
  projet: 'chapitres.html#projet',
  futur: 'chapitres.html#futur',
  year2024: 'stages_2024.html',
  year2025: 'stages_2025.html',
  year2026: 'stages_2026.html'
};

function activateMode(targetId) {
  modeButtons.forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.target === targetId);
  });

  infoCards.forEach((card) => {
    card.classList.toggle('active', card.id === targetId);
  });
}

modeButtons.forEach((btn) => {
  btn.addEventListener('click', () => {
    const target = btn.dataset.target;
    activateMode(target);

    if (pageRoutes[target]) {
      window.location.href = pageRoutes[target];
    }
  });
});

if (backBtn) {
  backBtn.addEventListener('click', () => {
    window.location.href = 'index.html';
  });
}

if (backToStagesBtn) {
  backToStagesBtn.addEventListener('click', () => {
    window.location.href = 'stages.html';
  });
}

if (settingsBtn) {
  settingsBtn.addEventListener('click', () => {
    const introTag = document.querySelector('.intro-tag');
    introTag.classList.toggle('muted');
    introTag.style.opacity = introTag.classList.contains('muted') ? '0.72' : '1';
  });
}

if (avatarCard) {
  avatarCard.addEventListener('mousemove', (event) => {
    const bounds = avatarCard.getBoundingClientRect();
    const x = (event.clientX - bounds.left) / bounds.width - 0.5;
    const y = (event.clientY - bounds.top) / bounds.height - 0.5;
    avatarCard.style.transform = `rotateY(${x * 7}deg) rotateX(${y * -7}deg)`;
  });

  avatarCard.addEventListener('mouseleave', () => {
    avatarCard.style.transform = 'rotateY(0) rotateX(0)';
  });
}

if (pressStartBtn) {
  pressStartBtn.addEventListener('click', () => {
    window.location.href = 'chapitres.html';
  });
}

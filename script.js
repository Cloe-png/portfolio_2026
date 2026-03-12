const modeButtons = document.querySelectorAll('.mode-item');
const infoCards = document.querySelectorAll('.info-card');
const backBtn = document.getElementById('backBtn');
const backToStagesBtn = document.getElementById('backToStagesBtn');
const settingsBtn = document.getElementById('settingsBtn');
const avatarCard = document.querySelector('.avatar-card');
const pressStartBtn = document.getElementById('pressStartBtn');
const caseCards = document.querySelectorAll('.case-card');
const detailPanels = document.querySelectorAll('.detail-panel');
const backToChaptersBtn = document.getElementById('backToChaptersBtn');
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

if (backToChaptersBtn) {
  backToChaptersBtn.addEventListener('click', () => {
    window.location.href = 'chapitres.html';
  });
}

function openDetailPanel(panel) {
  const body = panel.querySelector('.detail-body');
  if (!body) return;
  body.classList.add('is-open');
  panel.classList.add('is-open');
  const origin = panel.dataset.origin;
  panel.classList.toggle('from-left', origin === 'left');
  panel.classList.toggle('from-right', origin === 'right');
}

function closeDetailPanel(panel) {
  const body = panel.querySelector('.detail-body');
  if (!body) return;
  body.classList.remove('is-open');
  panel.classList.remove('is-open', 'from-left', 'from-right');
}

function openByHash(hash) {
  if (!hash) return;
  const id = hash.replace('#', '');
  const panel = document.getElementById(id);
  if (panel) {
    openDetailPanel(panel);
    panel.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
}

if (caseCards.length) {
  caseCards.forEach((card) => {
    card.addEventListener('click', (event) => {
      const href = card.getAttribute('href');
      if (!href || !href.startsWith('#')) return;
      event.preventDefault();
      let panel = card.nextElementSibling;
      while (panel && !panel.classList.contains('detail-panel')) {
        panel = panel.nextElementSibling;
      }
      if (!panel) return;
      const body = panel.querySelector('.detail-body');
      if (!body) return;
      const isOpen = body.classList.contains('is-open');
      if (isOpen) {
        closeDetailPanel(panel);
      } else {
        openDetailPanel(panel);
        panel.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
      history.replaceState(null, '', href);
    });
  });
}

window.addEventListener('load', () => {
  openByHash(window.location.hash);
});

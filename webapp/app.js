// ==========================================
// TAP COUNTER PWA (iOS & Web)
// ==========================================

// MARK: - State & Storage
const STORAGE_KEYS = {
  ACTIVE: 'tap_counter_active_sessions',
  TEMPLATES: 'tap_counter_templates',
  HISTORY: 'tap_counter_history'
};

const DEFAULT_TEMPLATES = [
  { id: 't-1', name: 'Free Count', mode: 'Simple' },
  { id: 't-2', name: 'Daily 108', mode: 'Target', targetCount: 108 },
  { id: 't-3', name: '5 Min Focus', mode: 'Timer', timerDuration: 300 }
];

let activeSessions = [];
let templates = [];
let history = [];
let currentSession = null;
let timerInterval = null;

// MARK: - Web Audio API (Authentic Mechanical Keyboard Click)
let audioCtx = null;

function initAudio() {
  if (!audioCtx) {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (AudioContext) {
      audioCtx = new AudioContext();
    }
  }
  if (audioCtx && audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
}

function playMechanicalClick() {
  try {
    initAudio();
    if (!audioCtx) return;

    const t = audioCtx.currentTime;

    // Transient oscillator (Sharp high-frequency snap)
    const osc = audioCtx.createOscillator();
    const oscGain = audioCtx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(3600, t);
    osc.frequency.exponentialRampToValueAtTime(300, t + 0.014);

    oscGain.gain.setValueAtTime(0.7, t);
    oscGain.gain.exponentialRampToValueAtTime(0.001, t + 0.015);

    osc.connect(oscGain);
    oscGain.connect(audioCtx.destination);
    osc.start(t);
    osc.stop(t + 0.016);

    // Subtle bottom body thump
    const subOsc = audioCtx.createOscillator();
    const subGain = audioCtx.createGain();
    subOsc.type = 'sine';
    subOsc.frequency.setValueAtTime(190, t);
    subOsc.frequency.exponentialRampToValueAtTime(40, t + 0.02);

    subGain.gain.setValueAtTime(0.4, t);
    subGain.gain.exponentialRampToValueAtTime(0.001, t + 0.022);

    subOsc.connect(subGain);
    subGain.connect(audioCtx.destination);
    subOsc.start(t);
    subOsc.stop(t + 0.023);
  } catch (e) {
    console.warn('Audio click error:', e);
  }
}

function playHaptic() {
  if ('vibrate' in navigator) {
    try {
      navigator.vibrate(15);
    } catch (_) {}
  }
}

function playCelebrationHaptic() {
  if ('vibrate' in navigator) {
    try {
      navigator.vibrate([40, 60, 80]);
    } catch (_) {}
  }
}

// MARK: - Persistence Helpers
function loadStorage() {
  try {
    const act = localStorage.getItem(STORAGE_KEYS.ACTIVE);
    activeSessions = act ? JSON.parse(act) : [];

    const tmpl = localStorage.getItem(STORAGE_KEYS.TEMPLATES);
    templates = tmpl ? JSON.parse(tmpl) : DEFAULT_TEMPLATES.slice();

    const hist = localStorage.getItem(STORAGE_KEYS.HISTORY);
    history = hist ? JSON.parse(hist) : [];
  } catch (e) {
    console.error('Failed to load storage:', e);
    templates = DEFAULT_TEMPLATES.slice();
  }
}

function saveStorage() {
  try {
    localStorage.setItem(STORAGE_KEYS.ACTIVE, JSON.stringify(activeSessions));
    localStorage.setItem(STORAGE_KEYS.TEMPLATES, JSON.stringify(templates));
    localStorage.setItem(STORAGE_KEYS.HISTORY, JSON.stringify(history));
  } catch (e) {
    console.error('Failed to save storage:', e);
  }
}

// MARK: - DOM Elements
const homeScreen = document.getElementById('home-screen');
const counterScreen = document.getElementById('counter-screen');
const inProgressSection = document.getElementById('in-progress-section');
const inProgressList = document.getElementById('in-progress-list');
const templatesSection = document.getElementById('templates-section');
const templatesList = document.getElementById('templates-list');
const historySection = document.getElementById('history-section');
const historyList = document.getElementById('history-list');
const emptyState = document.getElementById('empty-state');

const counterSessionName = document.getElementById('counter-session-name');
const counterNumber = document.getElementById('counter-number');
const counterModeInfo = document.getElementById('counter-mode-info');
const progressRingBar = document.getElementById('progress-ring-bar');
const centerContent = document.querySelector('.center-content');

// Modal Elements
const newSessionModal = document.getElementById('new-session-modal');
const inputSessionName = document.getElementById('input-session-name');
const targetOptions = document.getElementById('target-options');
const inputTargetCount = document.getElementById('input-target-count');
const timerOptions = document.getElementById('timer-options');
const pickerHours = document.getElementById('picker-hours');
const pickerMins = document.getElementById('picker-mins');
const pickerSecs = document.getElementById('picker-secs');
const toggleSaveTemplate = document.getElementById('toggle-save-template');

let selectedMode = 'Simple';

// MARK: - Navigation
function showScreen(screen) {
  if (screen === 'home') {
    counterScreen.classList.remove('active');
    homeScreen.classList.add('active');
    stopTimer();
    renderHome();
  } else if (screen === 'counter') {
    homeScreen.classList.remove('active');
    counterScreen.classList.add('active');
    renderCounter();
  }
}

// MARK: - Home Rendering
function renderHome() {
  loadStorage();

  // 1. In Progress List
  if (activeSessions.length > 0) {
    inProgressSection.style.display = 'block';
    inProgressList.innerHTML = activeSessions.map((session) => {
      const modeClass = session.mode.toLowerCase();
      let modeIcon = '⚡';
      if (session.mode === 'Target') modeIcon = '🎯';
      if (session.mode === 'Timer') modeIcon = '⏱️';

      let subtitle = 'Free tap count';
      if (session.mode === 'Target' && session.targetCount) {
        const pct = Math.min(Math.round((session.count / session.targetCount) * 100), 100);
        subtitle = `Goal: ${session.targetCount} (${pct}%)`;
      } else if (session.mode === 'Timer' && session.timerDuration) {
        const remaining = Math.max(session.timerDuration - (session.elapsedTime || 0), 0);
        const mins = Math.floor(remaining / 60);
        const secs = Math.floor(remaining % 60);
        subtitle = `Remaining: ${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
      }

      return `
        <div class="list-row" onclick="openActiveSession('${session.id}')">
          <div class="row-icon-circle ${modeClass}">${modeIcon}</div>
          <div class="row-info">
            <div class="row-title">${escapeHtml(session.name)}</div>
            <div class="row-subtitle">${subtitle}</div>
          </div>
          <div class="row-trailing">
            <div class="row-badge">${session.count}</div>
            <button class="row-delete-btn" onclick="event.stopPropagation(); deleteActiveSession('${session.id}')" title="Delete">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
            </button>
          </div>
        </div>
      `;
    }).join('');
  } else {
    inProgressSection.style.display = 'none';
  }

  // 2. Templates List
  if (templates.length > 0) {
    templatesSection.style.display = 'block';
    templatesList.innerHTML = templates.map((tmpl) => {
      const modeClass = tmpl.mode.toLowerCase();
      let modeIcon = '👆';
      if (tmpl.mode === 'Target') modeIcon = '🎯';
      if (tmpl.mode === 'Timer') modeIcon = '⏱️';

      let subtitle = 'Tap to start';
      if (tmpl.mode === 'Target' && tmpl.targetCount) {
        subtitle = `Goal: ${tmpl.targetCount} taps`;
      } else if (tmpl.mode === 'Timer' && tmpl.timerDuration) {
        const mins = Math.floor(tmpl.timerDuration / 60);
        subtitle = `Duration: ${mins} minutes`;
      }

      return `
        <div class="list-row" onclick="startFromTemplate('${tmpl.id}')">
          <div class="row-icon-circle ${modeClass}">${modeIcon}</div>
          <div class="row-info">
            <div class="row-title">${escapeHtml(tmpl.name)}</div>
            <div class="row-subtitle">${subtitle}</div>
          </div>
          <div class="row-trailing">
            <button class="row-delete-btn" onclick="event.stopPropagation(); deleteTemplate('${tmpl.id}')" title="Delete">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
            </button>
          </div>
        </div>
      `;
    }).join('');
  } else {
    templatesSection.style.display = 'none';
  }

  // 3. History List
  if (history.length > 0) {
    historySection.style.display = 'block';
    historyList.innerHTML = history.slice(0, 20).map((session) => {
      const modeClass = session.mode.toLowerCase();
      let modeIcon = '✓';
      const dateStr = new Date(session.completedAt || Date.now()).toLocaleDateString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });

      return `
        <div class="list-row">
          <div class="row-icon-circle ${modeClass}">${modeIcon}</div>
          <div class="row-info">
            <div class="row-title">${escapeHtml(session.name)}</div>
            <div class="row-subtitle">${dateStr}</div>
          </div>
          <div class="row-trailing">
            <div class="row-badge">${session.count}</div>
            <button class="row-delete-btn" onclick="deleteHistoryItem('${session.id}')" title="Delete">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
            </button>
          </div>
        </div>
      `;
    }).join('');
  } else {
    historySection.style.display = 'none';
  }

  // 4. Empty State
  if (activeSessions.length === 0 && templates.length === 0 && history.length === 0) {
    emptyState.style.display = 'block';
  } else {
    emptyState.style.display = 'none';
  }
}

// MARK: - Counter Rendering
function renderCounter() {
  if (!currentSession) return;

  counterSessionName.textContent = currentSession.name;
  counterNumber.textContent = currentSession.count;

  // Ring Circumference = 2 * PI * 126 ≈ 791.68
  const circumference = 791.68;
  progressRingBar.style.strokeDasharray = `${circumference}`;

  if (currentSession.mode === 'Target' && currentSession.targetCount) {
    const progress = Math.min(currentSession.count / currentSession.targetCount, 1.0);
    const offset = circumference - (progress * circumference);
    progressRingBar.style.strokeDashoffset = `${offset}`;
    progressRingBar.style.stroke = 'var(--accent-green)';
    counterModeInfo.textContent = `${currentSession.count} / ${currentSession.targetCount}`;
    counterModeInfo.style.color = 'var(--label-secondary)';
  } else if (currentSession.mode === 'Timer' && currentSession.timerDuration) {
    const elapsed = currentSession.elapsedTime || 0;
    const progress = Math.min(elapsed / currentSession.timerDuration, 1.0);
    const offset = circumference - (progress * circumference);
    progressRingBar.style.strokeDashoffset = `${offset}`;
    progressRingBar.style.stroke = 'var(--accent-orange)';

    const remaining = Math.max(currentSession.timerDuration - elapsed, 0);
    const mins = Math.floor(remaining / 60);
    const secs = Math.floor(remaining % 60);
    counterModeInfo.textContent = `⏱️ ${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    counterModeInfo.style.color = 'var(--accent-orange)';
  } else {
    // Simple Mode
    progressRingBar.style.strokeDashoffset = `${circumference}`;
    progressRingBar.style.stroke = 'var(--accent-blue)';
    counterModeInfo.textContent = 'Simple Count';
    counterModeInfo.style.color = 'var(--label-secondary)';
  }

  // Timer runner
  if (currentSession.mode === 'Timer' && !timerInterval) {
    startTimer();
  }
}

// MARK: - Actions (Tap, Subtract, Reset, End, Delete)
function tapCounter() {
  if (!currentSession) return;
  if (currentSession.mode === 'Timer' && currentSession.elapsedTime >= currentSession.timerDuration) return;

  currentSession.count += 1;
  playMechanicalClick();
  playHaptic();

  // Visual tap bounce
  centerContent.classList.add('tapped');
  setTimeout(() => centerContent.classList.remove('tapped'), 80);

  // Check Target reached
  if (currentSession.mode === 'Target' && currentSession.targetCount && currentSession.count >= currentSession.targetCount) {
    playCelebrationHaptic();
    showTargetCelebration();
    saveActiveSessions();
    renderCounter();
    return;
  }

  saveActiveSessions();
  renderCounter();
}

function subtractCounter() {
  if (!currentSession || currentSession.count <= 0) return;
  currentSession.count -= 1;
  playMechanicalClick();
  playHaptic();
  saveActiveSessions();
  renderCounter();
}

function resetCounter() {
  if (!currentSession) return;
  currentSession.count = 0;
  playHaptic();
  saveActiveSessions();
  renderCounter();
}

function endCounterSession() {
  if (!currentSession) return;
  stopTimer();

  // Move to history
  currentSession.completedAt = Date.now();
  history.unshift(currentSession);
  activeSessions = activeSessions.filter((s) => s.id !== currentSession.id);
  currentSession = null;
  saveStorage();
  showScreen('home');
}

function deleteCurrentSession() {
  if (!currentSession) return;
  if (confirm('Delete this counting session?')) {
    stopTimer();
    activeSessions = activeSessions.filter((s) => s.id !== currentSession.id);
    currentSession = null;
    saveStorage();
    showScreen('home');
  }
}

function deleteActiveSession(id) {
  activeSessions = activeSessions.filter((s) => s.id !== id);
  saveStorage();
  renderHome();
}

function deleteTemplate(id) {
  templates = templates.filter((t) => t.id !== id);
  saveStorage();
  renderHome();
}

function deleteHistoryItem(id) {
  history = history.filter((h) => h.id !== id);
  saveStorage();
  renderHome();
}

function clearAllHistory() {
  if (confirm('Clear all session history?')) {
    history = [];
    saveStorage();
    renderHome();
  }
}

// MARK: - Timer Logic
function startTimer() {
  stopTimer();
  timerInterval = setInterval(() => {
    if (!currentSession || currentSession.mode !== 'Timer') {
      stopTimer();
      return;
    }

    currentSession.elapsedTime = (currentSession.elapsedTime || 0) + 1;

    if (currentSession.elapsedTime >= currentSession.timerDuration) {
      stopTimer();
      playCelebrationHaptic();
      showTimerCelebration();
    }

    saveActiveSessions();
    renderCounter();
  }, 1000);
}

function stopTimer() {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }
}

function showTargetCelebration() {
  const overlay = document.getElementById('overlay-target-reached');
  const msg = document.getElementById('overlay-target-msg');
  msg.textContent = `You hit your goal of ${currentSession.targetCount} taps!`;
  overlay.style.display = 'flex';

  setTimeout(() => {
    overlay.style.display = 'none';
    endCounterSession();
  }, 1600);
}

function showTimerCelebration() {
  const overlay = document.getElementById('overlay-timer-expired');
  const msg = document.getElementById('overlay-timer-msg');
  msg.textContent = `You counted ${currentSession.count} taps!`;
  overlay.style.display = 'flex';

  setTimeout(() => {
    overlay.style.display = 'none';
    endCounterSession();
  }, 1800);
}

// MARK: - Session Creation
function openActiveSession(id) {
  const session = activeSessions.find((s) => s.id === id);
  if (session) {
    currentSession = session;
    showScreen('counter');
  }
}

function startFromTemplate(id) {
  const tmpl = templates.find((t) => t.id === id);
  if (tmpl) {
    const newSession = {
      id: 'session-' + Date.now(),
      name: tmpl.name,
      mode: tmpl.mode,
      targetCount: tmpl.targetCount || null,
      timerDuration: tmpl.timerDuration || null,
      count: 0,
      elapsedTime: 0,
      createdAt: Date.now()
    };
    activeSessions.unshift(newSession);
    currentSession = newSession;
    saveStorage();
    showScreen('counter');
  }
}

function saveActiveSessions() {
  if (currentSession) {
    const idx = activeSessions.findIndex((s) => s.id === currentSession.id);
    if (idx >= 0) {
      activeSessions[idx] = currentSession;
    } else {
      activeSessions.unshift(currentSession);
    }
  }
  saveStorage();
}

function startNewSession() {
  let name = inputSessionName.value.trim();
  if (!name) {
    name = `${selectedMode} Session`;
  }

  let targetCount = null;
  let timerDuration = null;

  if (selectedMode === 'Target') {
    targetCount = parseInt(inputTargetCount.value, 10) || 100;
  } else if (selectedMode === 'Timer') {
    const hrs = parseInt(pickerHours.value, 10) || 0;
    const mins = parseInt(pickerMins.value, 10) || 0;
    const secs = parseInt(pickerSecs.value, 10) || 0;
    timerDuration = (hrs * 3600) + (mins * 60) + secs;
    if (timerDuration <= 0) timerDuration = 300; // fallback 5 mins
  }

  const newSession = {
    id: 'session-' + Date.now(),
    name: name,
    mode: selectedMode,
    targetCount: targetCount,
    timerDuration: timerDuration,
    count: 0,
    elapsedTime: 0,
    createdAt: Date.now()
  };

  // Optional: save as template
  if (toggleSaveTemplate.checked) {
    templates.push({
      id: 'tmpl-' + Date.now(),
      name: name,
      mode: selectedMode,
      targetCount: targetCount,
      timerDuration: timerDuration
    });
  }

  activeSessions.unshift(newSession);
  currentSession = newSession;
  saveStorage();

  // Reset modal fields
  inputSessionName.value = '';
  toggleSaveTemplate.checked = false;
  closeNewSessionModal();

  showScreen('counter');
}

// MARK: - Modal Controls
function openNewSessionModal() {
  newSessionModal.style.display = 'flex';
}

function closeNewSessionModal() {
  newSessionModal.style.display = 'none';
}

function setMode(mode) {
  selectedMode = mode;
  document.querySelectorAll('.segment-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.mode === mode);
  });

  if (mode === 'Target') {
    targetOptions.style.display = 'block';
    timerOptions.style.display = 'none';
  } else if (mode === 'Timer') {
    targetOptions.style.display = 'none';
    timerOptions.style.display = 'block';
  } else {
    targetOptions.style.display = 'none';
    timerOptions.style.display = 'none';
  }
}

// MARK: - Helper Functions
function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

// MARK: - Event Listeners
document.addEventListener('DOMContentLoaded', () => {
  loadStorage();
  renderHome();

  // Open / Close sheet
  document.getElementById('btn-open-new-sheet').addEventListener('click', openNewSessionModal);
  document.getElementById('btn-close-new-sheet').addEventListener('click', closeNewSessionModal);
  document.getElementById('btn-start-session').addEventListener('click', startNewSession);

  // Mode segments
  document.querySelectorAll('.segment-btn').forEach((btn) => {
    btn.addEventListener('click', () => setMode(btn.dataset.mode));
  });

  // Target quick chips
  document.querySelectorAll('.chip').forEach((chip) => {
    chip.addEventListener('click', () => {
      inputTargetCount.value = chip.dataset.target;
    });
  });

  // Tap zone
  document.getElementById('tap-zone').addEventListener('pointerdown', (e) => {
    e.preventDefault();
    tapCounter();
  });

  // Counter Utility Buttons
  document.getElementById('btn-counter-back').addEventListener('click', () => showScreen('home'));
  document.getElementById('btn-counter-subtract').addEventListener('click', subtractCounter);
  document.getElementById('btn-counter-reset').addEventListener('click', resetCounter);
  document.getElementById('btn-counter-end').addEventListener('click', endCounterSession);
  document.getElementById('btn-counter-delete').addEventListener('click', deleteCurrentSession);

  // Clear all history
  document.getElementById('btn-clear-history').addEventListener('click', clearAllHistory);

  // Register Service Worker for offline PWA
  if ('serviceWorker' in navigator && window.location.protocol.startsWith('http')) {
    navigator.serviceWorker.register('sw.js').catch((err) => {
      console.log('SW registration error:', err);
    });
  }
});

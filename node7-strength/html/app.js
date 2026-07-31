const card = document.getElementById('strength-card');
const popup = document.getElementById('xp-popup');
const trainingPop = document.getElementById('training-pop');

const brand = document.getElementById('brand');
const title = document.getElementById('title');
const closeBtn = document.getElementById('close');
const level = document.getElementById('level');
const rank = document.getElementById('rank');
const xpText = document.getElementById('xpText');
const dailyText = document.getElementById('dailyText');
const xpBar = document.getElementById('xpBar');
const brawlBonus = document.getElementById('brawlBonus');
const carryBonus = document.getElementById('carryBonus');
const staminaBonus = document.getElementById('staminaBonus');
const resistBonus = document.getElementById('resistBonus');

const xpReason = document.getElementById('xpReason');
const xpAmount = document.getElementById('xpAmount');
const levelUp = document.getElementById('levelUp');

const trainingLabel = document.getElementById('trainingLabel');
const trainingFill = document.getElementById('trainingFill');

let xpTimer = null;
let trainingTimer = null;

function nuiClose() {
    card.classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    });
}

function pct(value) {
    const bonus = Math.max(0, (Number(value) || 1) - 1);
    return `+${Math.round(bonus * 100)}%`;
}

function flatPct(value) {
    return `+${Math.round((Number(value) || 0) * 100)}%`;
}

function renderStats(stats) {
    if (!stats) return;

    const lvl = Number(stats.level) || 1;
    const xp = Number(stats.xp) || 0;
    const needed = Number(stats.xp_needed) || 0;
    const daily = Number(stats.daily_xp) || 0;

    level.textContent = lvl;
    rank.textContent = stats.title || 'Greenhorn';
    xpText.textContent = needed > 0 ? `${xp} / ${needed} XP` : 'MAX LEVEL';
    dailyText.textContent = `${daily} daily`;
    xpBar.style.width = needed > 0 ? `${Math.min(100, Math.max(0, (xp / needed) * 100))}%` : '100%';

    brawlBonus.textContent = pct(stats.brawl_multiplier);
    carryBonus.textContent = pct(stats.carry_multiplier);
    staminaBonus.textContent = pct(stats.stamina_multiplier);
    resistBonus.textContent = flatPct(stats.knockdown_resist);
}

function openCard(config, stats) {
    brand.textContent = config?.Brand || 'NODE7';
    title.textContent = config?.Title || 'PLAYER STRENGTH';
    renderStats(stats);
    card.classList.remove('hidden');
}

function showXP(payload, timeout) {
    const amount = Number(payload?.amount) || 0;

    xpReason.textContent = payload?.reason || 'Strength XP';
    xpAmount.textContent = `+${amount} Strength XP`;

    if (payload?.leveled) {
        levelUp.classList.remove('hidden');
        levelUp.textContent = `LEVEL UP • ${payload?.stats?.level || ''}`;
    } else {
        levelUp.classList.add('hidden');
    }

    if (payload?.stats) renderStats(payload.stats);

    popup.classList.remove('hidden');

    if (xpTimer) clearTimeout(xpTimer);
    xpTimer = setTimeout(() => {
        popup.classList.add('hidden');
    }, timeout || 4500);
}

function showTraining(data) {
    const duration = Number(data?.duration) || 8000;

    trainingLabel.textContent = data?.label || 'Strength Drill';
    trainingFill.style.transition = 'none';
    trainingFill.style.width = '0%';
    trainingPop.classList.remove('hidden');

    requestAnimationFrame(() => {
        trainingFill.style.transition = `width ${duration}ms linear`;
        trainingFill.style.width = '100%';
    });

    if (trainingTimer) clearTimeout(trainingTimer);
    trainingTimer = setTimeout(() => {
        trainingPop.classList.add('hidden');
        trainingFill.style.transition = 'none';
        trainingFill.style.width = '0%';
    }, duration + 250);
}

window.addEventListener('message', (event) => {
    const msg = event.data || {};

    if (msg.action === 'open') {
        openCard(msg.config || {}, msg.data || {});
    }

    if (msg.action === 'close') {
        card.classList.add('hidden');
    }

    if (msg.action === 'stats') {
        renderStats(msg.data || {});
    }

    if (msg.action === 'xp') {
        showXP(msg.data || {}, msg.timeout);
    }

    if (msg.action === 'training') {
        showTraining(msg.data || {});
    }
});

closeBtn.addEventListener('click', nuiClose);

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        nuiClose();
    }
});

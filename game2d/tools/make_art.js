// Renders the ink-style art for the 2D prototype from SVG into PNG files.
// Each Benika body part is drawn in the same 240x262 "draft" space so the parts
// line up; trim_art.py then crops them and records each part's pivot.
// Run: node tools/make_art.js  (needs Playwright + Chromium)  then  python3 tools/trim_art.py
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const INK = '#1E1A17', SKIN = '#FBEFE2', CLOTH = '#F6EEDC', RED = '#C8322B', EMBER = '#F2B8A8';
const OUT = path.join(__dirname, '..', 'art');

const inkFilter = (seed) => `<filter id="ink" x="-20%" y="-20%" width="140%" height="140%">
  <feTurbulence type="fractalNoise" baseFrequency="0.045" numOctaves="2" seed="${seed}"/>
  <feDisplacementMap in="SourceGraphic" scale="3.2"/></filter>`;

// The draft space: x -40..260, y -40..280. Pivots are listed in trim_art.py.
const part = (body, seed = 3) => `<svg xmlns="http://www.w3.org/2000/svg" width="300" height="320" viewBox="-40 -40 300 320">
  <defs>${inkFilter(seed)}</defs><g filter="url(#ink)" stroke-linejoin="round">${body}</g></svg>`;

const arm = (sx, sy, front) => `
  <path d="M${sx},${sy} L${sx},${sy + 38}" stroke="${INK}" stroke-width="16" stroke-linecap="round"/>
  <path d="M${sx},${sy} L${sx},${sy + 38}" stroke="${front ? CLOTH : '#E9DFC8'}" stroke-width="10" stroke-linecap="round"/>
  <circle cx="${sx}" cy="${sy + 46}" r="12" fill="${RED}" stroke="${INK}" stroke-width="2.5"/>
  <path d="M${sx - 6},${sy + 42} q6,4 12,0" stroke="${INK}" stroke-width="1.6" fill="none" opacity=".6"/>`;

const leg = (hx, front) => `
  <rect x="${hx - 6}" y="196" width="12" height="36" fill="${front ? CLOTH : '#E9DFC8'}" stroke="${INK}" stroke-width="3"/>
  <path d="M${hx - 8},232 Q${hx - 6},224 ${hx + 6},226 Q${hx + 16},228 ${hx + 16},236 Q${hx + 4},244 ${hx - 8},238Z" fill="${INK}"/>`;

const parts = {
  // Behind the head: ponytail and headband tails. Pivot at the tie (148,48).
  ponytail: part(`
    <path d="M140,44 Q186,16 204,58 Q188,46 178,60 Q186,36 152,52Z" fill="${INK}"/>
    <path d="M190,40 Q200,48 204,58 M184,52 Q186,56 186,62" stroke="${RED}" stroke-width="4" fill="none" stroke-linecap="round"/>
    <path d="M150,58 Q172,72 182,96 M152,62 Q166,82 168,102" stroke="${RED}" stroke-width="4" fill="none" stroke-linecap="round"/>`, 5),
  // Head facing right (3/4 view). Pivot at the neck (110,122).
  head: part(`
    <ellipse cx="110" cy="84" rx="46" ry="42" fill="${SKIN}" stroke="${INK}" stroke-width="3.5"/>
    <ellipse cx="102" cy="92" rx="7.5" ry="10.5" fill="${INK}"/><ellipse cx="103" cy="95" rx="5" ry="6.6" fill="${RED}"/>
    <circle cx="100" cy="88" r="2.8" fill="#fff"/><circle cx="105" cy="98" r="1.3" fill="#fff"/>
    <ellipse cx="134" cy="92" rx="6.5" ry="10" fill="${INK}"/><ellipse cx="135" cy="95" rx="4.4" ry="6.4" fill="${RED}"/>
    <circle cx="132.5" cy="88" r="2.5" fill="#fff"/>
    <path d="M94,78 Q102,74 110,78 M127,77 Q134,73 141,77" stroke="${INK}" stroke-width="2.4" fill="none" stroke-linecap="round"/>
    <path d="M114,110 Q120,115 127,109" stroke="${INK}" stroke-width="2.4" fill="none" stroke-linecap="round"/>
    <ellipse cx="90" cy="105" rx="6.5" ry="3" fill="${RED}" opacity=".28"/><ellipse cx="144" cy="104" rx="5" ry="3" fill="${RED}" opacity=".28"/>
    <path d="M60,94 Q50,34 110,28 Q170,34 160,94 L152,74 L148,94 L140,66 L130,86 L122,58 L112,82 L102,56 L94,84 L84,62 L78,88 L70,70 Z" fill="${INK}"/>
    <path d="M140,66 L136,76 M122,58 L120,68 M102,56 L102,66 M84,62 L86,72" stroke="${RED}" stroke-width="4" stroke-linecap="round"/>
    <path d="M62,62 Q110,40 158,62" stroke="${RED}" stroke-width="7" fill="none" stroke-linecap="round"/>`, 7),
  // Jacket and sash. Pivot at the hips (110,198).
  torso: part(`
    <rect x="103" y="114" width="14" height="12" fill="${SKIN}" stroke="${INK}" stroke-width="2.5"/>
    <path d="M86,122 Q110,114 134,122 L142,202 Q110,210 78,202 Z" fill="${CLOTH}" stroke="${INK}" stroke-width="3.5"/>
    <path d="M100,122 L114,162 L126,122" stroke="${RED}" stroke-width="6" fill="none"/>
    <rect x="80" y="160" width="60" height="11" fill="${RED}" stroke="${INK}" stroke-width="2"/>
    <path d="M84,166 L66,182" stroke="${RED}" stroke-width="5" stroke-linecap="round"/>
    <circle cx="88" cy="194" r="2.4" fill="${RED}"/><circle cx="102" cy="198" r="2" fill="${RED}"/><circle cx="126" cy="196" r="2.6" fill="${RED}"/>`, 9),
  // Arms hang straight down from the shoulder. Pivots (96,132) and (124,132).
  arm_back: part(arm(96, 132, false), 11),
  arm_front: part(arm(124, 132, true), 13),
  // Legs. Pivots at the hip joints (102,198) and (118,198).
  leg_back: part(leg(102, false), 15),
  leg_front: part(leg(118, true), 17),
};

// World art.
const W = {
  // A flame splash for the punch. Pivot at the left middle.
  flame: `<svg xmlns="http://www.w3.org/2000/svg" width="160" height="120" viewBox="0 0 160 120">
    <defs><filter id="w" x="-30%" y="-30%" width="160%" height="160%"><feTurbulence type="fractalNoise" baseFrequency="0.03" numOctaves="3" seed="4"/><feDisplacementMap in="SourceGraphic" scale="22"/><feGaussianBlur stdDeviation="1"/></filter></defs>
    <g filter="url(#w)"><path d="M10,60 Q50,20 100,30 Q130,10 150,40 Q120,50 140,64 Q110,70 146,96 Q100,96 80,90 Q40,100 10,60Z" fill="${RED}" opacity=".9"/>
    <path d="M24,60 Q60,40 96,52 Q80,64 100,78 Q60,80 24,60Z" fill="${EMBER}"/></g>
    <g fill="${INK}"><circle cx="150" cy="22" r="4"/><circle cx="140" cy="108" r="3"/><circle cx="118" cy="14" r="2"/></g></svg>`,
  // Far mountains, drawn as grey ink washes. One wide picture, so there is no seam.
  mountains: `<svg xmlns="http://www.w3.org/2000/svg" width="3000" height="500" viewBox="0 0 3000 500">
    <defs><filter id="m" x="-20%" y="-20%" width="140%" height="160%"><feTurbulence type="fractalNoise" baseFrequency="0.012" numOctaves="4" seed="2"/><feDisplacementMap in="SourceGraphic" scale="40"/><feGaussianBlur stdDeviation="3"/></filter></defs>
    <g filter="url(#m)">
      <path d="M-200,520 L-200,320 Q-100,260 0,320 Q120,150 260,280 Q380,90 560,260 Q700,180 820,300 Q980,110 1160,270 Q1300,160 1440,290 Q1560,200 1700,300 Q1860,120 2040,280 Q2200,170 2340,300 Q2500,100 2700,270 Q2850,190 3200,300 L3200,520Z" fill="#1E1A17" opacity=".16"/>
      <path d="M-200,520 L-200,400 Q-100,360 0,400 Q160,280 340,380 Q520,260 720,390 Q900,300 1080,400 Q1260,310 1440,400 Q1620,300 1800,390 Q1980,290 2160,400 Q2360,300 2560,390 Q2760,320 3200,400 L3200,520Z" fill="#1E1A17" opacity=".26"/>
    </g>
    <circle cx="1240" cy="110" r="56" fill="${RED}" opacity=".85"/></svg>`,
  // A brush-stroke platform. Stretched to each platform's width in the game.
  platform: `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="56" viewBox="0 0 512 56">
    <defs><filter id="p" x="-5%" y="-40%" width="110%" height="180%"><feTurbulence type="fractalNoise" baseFrequency="0.06 0.3" numOctaves="3" seed="8"/><feDisplacementMap in="SourceGraphic" scale="9"/></filter></defs>
    <g filter="url(#p)"><path d="M6,12 Q256,2 506,10 L500,30 Q256,40 10,32Z" fill="${INK}"/>
    <path d="M30,34 Q200,46 380,38 L360,46 Q200,54 40,44Z" fill="${INK}" opacity=".35"/></g></svg>`,
};

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ deviceScaleFactor: 2 });
  const render = async (svg, file) => {
    const m = svg.match(/width="(\d+)" height="(\d+)"/);
    await page.setViewportSize({ width: +m[1], height: +m[2] });
    await page.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);
    await page.screenshot({ path: file, omitBackground: true, clip: { x: 0, y: 0, width: +m[1], height: +m[2] } });
  };
  for (const [name, svg] of Object.entries(parts)) await render(svg, path.join(OUT, 'benika', name + '.png'));
  for (const [name, svg] of Object.entries(W)) await render(svg, path.join(OUT, 'world', name + '.png'));
  await browser.close();
})();

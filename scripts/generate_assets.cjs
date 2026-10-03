const fs = require('fs');
const path = require('path');

const PRODUCTS = {
  iron_pipe: { name: 'Liatinová rúra', color: '#9baea3', finished: false },
  clean_iron_pipe: { name: 'Očistená liatinová rúra', source: 'iron_pipe', color: '#c7e2e8', finished: true },
  ring: { name: 'Oceľový prstenec', color: '#a7cadc', finished: false },
  clean_ring: { name: 'Očistený oceľový prstenec', source: 'ring', color: '#c7e2e8', finished: true },
  steel_pipe: { name: 'Oceľová rúra', color: '#b9d3df', finished: false },
  clean_steel_pipe: { name: 'Očistená oceľová rúra', source: 'steel_pipe', color: '#c7e2e8', finished: true },
  bronze_bushing: { name: 'Bronzové puzdro', color: '#d7aa66', finished: false },
  clean_bronze_bushing: { name: 'Očistené bronzové puzdro', source: 'bronze_bushing', color: '#c7e2e8', finished: true }
};

function productIcon(id) {
  const p = PRODUCTS[id];
  const source = p.source || id;
  const pipe = source.endsWith('_pipe');
  const bronze = source === 'bronze_bushing';
  const light = bronze ? '#f4d49b' : (source === 'iron_pipe' ? '#d5ded0' : '#d6edf5');
  const dark = bronze ? '#805331' : '#45616c';
  const shape = pipe
    ? `<path d="M12 23 35 12Q43 10 47 17L24 29Z" fill="${light}"/>
  <path d="m24 29 23-12v17L24 46Z" fill="${p.color}"/>
  <path d="m25 38 20-10v6L24 46Z" fill="${dark}" opacity=".7"/>
  <ellipse cx="18" cy="34" rx="11" ry="14" fill="${p.color}" stroke="${light}" stroke-width="2"/>
  <ellipse cx="18" cy="34" rx="6" ry="9" fill="#152c36"/>
  <path d="M14 27q-3 6 0 12" fill="none" stroke="${dark}" stroke-width="2"/>
  <path d="m28 24 15-7" stroke="${light}" stroke-width="2"/>`
    : `<path d="M10 25v${bronze ? 16 : 9}c0 14 36 14 36 0V25" fill="${dark}"/>
  <ellipse cx="28" cy="25" rx="18" ry="13" fill="${p.color}" stroke="${light}" stroke-width="2"/>
  <ellipse cx="28" cy="25" rx="10" ry="7" fill="#172f38" stroke="${dark}" stroke-width="3"/>
  <path d="M13 34q14 12 30 0" fill="none" stroke="${light}" opacity=".45"/>`;

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 56 56">
  <ellipse cx="28" cy="49" rx="20" ry="3" fill="#081820" opacity=".5"/>
  ${shape}
${p.finished ? `  <path d="m43 2 2.5 6.5L52 11l-6.5 2.5L43 20l-2.5-6.5L34 11l6.5-2.5Z" fill="#e0ffff"/>
  <path d="m8 8 1 3 3 1-3 1-1 3-1-3-3-1 3-1Z" fill="#91d7e8"/>
` : ''}</svg>`;
}

const prodDir = path.join('godot', 'assets', 'textures', 'products');
fs.mkdirSync(prodDir, { recursive: true });
for (const id of Object.keys(PRODUCTS)) {
  fs.writeFileSync(path.join(prodDir, id + '.svg'), productIcon(id), 'utf8');
}
console.log('Product SVGs generated:', Object.keys(PRODUCTS).length);

const MATERIALS = {
  iron: { short: 'Fe', color: '#a5b6b4' },
  steel: { short: 'OC', color: '#98c8e0' },
  copper: { short: 'Cu', color: '#e6a171' },
  tin: { short: 'Sn', color: '#d0d7d5' },
  zinc: { short: 'Zn', color: '#b9cbd8' }
};

const matDir = path.join('godot', 'assets', 'textures', 'materials');
fs.mkdirSync(matDir, { recursive: true });
for (const [id, m] of Object.entries(MATERIALS)) {
  const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40">
  <rect width="40" height="40" rx="6" fill="#172a32" stroke="#718e9055" stroke-width="1.5"/>
  <text x="20" y="25" fill="${m.color}" font-family="Arial, sans-serif" font-size="16" font-weight="bold" text-anchor="middle">${m.short}</text>
</svg>`;
  fs.writeFileSync(path.join(matDir, id + '.svg'), svg, 'utf8');
}
console.log('Material SVGs generated:', Object.keys(MATERIALS).length);

const iconSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <rect width="32" height="32" rx="7" fill="#101b22"/>
  <circle cx="16" cy="16" r="10" fill="#ffa259"/>
  <circle cx="16" cy="16" r="5" fill="#101b22"/>
</svg>`;
const iconDir = path.join('godot', 'assets', 'textures');
fs.mkdirSync(iconDir, { recursive: true });
fs.writeFileSync(path.join(iconDir, 'icon.svg'), iconSvg, 'utf8');
console.log('icon.svg generated');

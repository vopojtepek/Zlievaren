const fs = require('fs');
const path = require('path');

const charDir = path.join('godot', 'assets', 'textures', 'characters');
const machDir = path.join('godot', 'assets', 'textures', 'machines');
fs.mkdirSync(charDir, { recursive: true });
fs.mkdirSync(machDir, { recursive: true });

// 1. Foreman Mišo (Day shift - Black hoodie, thorn print, long hair, beard)
const misoSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-40 -80 80 90">
  <defs>
    <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
      <feDropShadow dx="0" dy="2" stdDeviation="2" flood-color="#10222a" flood-opacity="0.6"/>
    </filter>
  </defs>
  <!-- Ground Shadow -->
  <ellipse cx="0" cy="3" rx="24" ry="7" fill="#10222a" opacity="0.45"/>

  <!-- Legs & Boots -->
  <line x1="-6" y1="-21" x2="-8" y2="0" stroke="#11151b" stroke-width="9" stroke-linecap="round"/>
  <line x1="6" y1="-21" x2="8" y2="0" stroke="#171b21" stroke-width="9" stroke-linecap="round"/>
  <line x1="-8" y1="-19" x2="-9" y2="-4" stroke="#363b43" stroke-width="1.2"/>
  <line x1="8" y1="-19" x2="9" y2="-4" stroke="#363b43" stroke-width="1.2"/>
  <rect x="-15" y="-2" width="15" height="6" rx="2" fill="#0a1016"/>
  <rect x="3" y="-2" width="15" height="6" rx="2" fill="#0a1016"/>
  <line x1="-14" y1="3" x2="-1" y2="3" stroke="#617078" stroke-width="1"/>
  <line x1="4" y1="3" x2="17" y2="3" stroke="#617078" stroke-width="1"/>

  <!-- Arms & Sleeves -->
  <line x1="-13" y1="-39" x2="-16" y2="-19" stroke="#10141a" stroke-width="9" stroke-linecap="round"/>
  <line x1="13" y1="-39" x2="17" y2="-20" stroke="#20252d" stroke-width="9" stroke-linecap="round"/>
  <circle cx="-16" cy="-17" r="3" fill="#c29d7c"/>
  <circle cx="17" cy="-18" r="3" fill="#c29d7c"/>

  <!-- Torso & Black Hoodie -->
  <rect x="-14" y="-43" width="29" height="28" rx="6" fill="#12161c"/>
  <line x1="-13" y1="-36" x2="-12" y2="-20" stroke="#4b535d" stroke-width="1"/>
  <line x1="14" y1="-36" x2="13" y2="-20" stroke="#49515a" stroke-width="1"/>
  <rect x="-10" y="-21" width="20" height="3" rx="2" fill="#242b34"/>
  <ellipse cx="0" cy="-43" rx="16" ry="10" fill="#292c32" stroke="#535862" stroke-width="1"/>
  <ellipse cx="0" cy="-44" rx="11" ry="6" fill="#101419"/>

  <!-- Silver Thorn Black-Metal Print -->
  <line x1="-2" y1="-33" x2="-11" y2="-37" stroke="#c4c9ca" stroke-width="1"/>
  <line x1="2" y1="-33" x2="11" y2="-37" stroke="#c4c9ca" stroke-width="1"/>
  <line x1="-4" y1="-31" x2="-11" y2="-30" stroke="#e2e6df" stroke-width="1"/>
  <line x1="4" y1="-31" x2="11" y2="-30" stroke="#e2e6df" stroke-width="1"/>
  <line x1="-7" y1="-35" x2="-10" y2="-41" stroke="#c4c9ca" stroke-width="0.8"/>
  <line x1="7" y1="-35" x2="10" y2="-41" stroke="#c4c9ca" stroke-width="0.8"/>
  <line x1="-7" y1="-32" x2="-11" y2="-27" stroke="#c4c9ca" stroke-width="0.8"/>
  <line x1="7" y1="-32" x2="11" y2="-27" stroke="#c4c9ca" stroke-width="0.8"/>
  <line x1="-5" y1="-24" x2="5" y2="-24" stroke="#979f9f" stroke-width="1"/>
  <line x1="-6" y1="-40" x2="-7" y2="-34" stroke="#b5b9b9" stroke-width="0.8"/>
  <line x1="7" y1="-40" x2="8" y2="-34" stroke="#b5b9b9" stroke-width="0.8"/>

  <!-- Long Hair over Shoulders -->
  <ellipse cx="0" cy="-51" rx="13" ry="14" fill="#201c1c"/>
  <polygon points="-12,-53 -14,-37 -10,-30 -6,-34 -6,-55" fill="#292020"/>
  <polygon points="8,-55 13,-51 15,-32 10,-29 6,-40" fill="#231e1f"/>
  <ellipse cx="1" cy="-49" rx="8" ry="10" fill="#c6a182"/>
  <polygon points="-9,-57 -2,-64 8,-60 12,-53 7,-51 4,-57 -4,-51 -8,-45" fill="#211d1e"/>
  <line x1="-11" y1="-52" x2="-11" y2="-35" stroke="#49352e" stroke-width="1.3"/>
  <line x1="11" y1="-51" x2="12" y2="-34" stroke="#49362e" stroke-width="1"/>
  <line x1="-5" y1="-50" x2="-1" y2="-50" stroke="#171d24" stroke-width="1.4"/>
  <line x1="4" y1="-50" x2="8" y2="-50" stroke="#171d24" stroke-width="1.4"/>
  <line x1="2" y1="-49" x2="3" y2="-45" stroke="#987758" stroke-width="1"/>

  <!-- Full Chest Beard -->
  <polygon points="-7,-46 -3,-44 2,-45 6,-44 10,-46 9,-35 5,-25 1,-22 -4,-29 -8,-36" fill="#0b1016"/>
  <line x1="-4" y1="-39" x2="-1" y2="-27" stroke="#2c3036" stroke-width="1"/>
  <line x1="6" y1="-40" x2="4" y2="-30" stroke="#2d3036" stroke-width="1"/>
  <line x1="-4" y1="-44" x2="1" y2="-45" stroke="#0a1016" stroke-width="2"/>
  <line x1="1" y1="-45" x2="7" y2="-43" stroke="#0a1016" stroke-width="2"/>
</svg>`;

// 2. Foreman Miro (Night shift - Blue hoodie, bald clean-shaven face)
const miroSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-40 -80 80 90">
  <!-- Ground Shadow -->
  <ellipse cx="0" cy="3" rx="24" ry="7" fill="#10222a" opacity="0.45"/>

  <!-- Legs & Boots -->
  <line x1="-7" y1="-21" x2="-9" y2="0" stroke="#727b85" stroke-width="10" stroke-linecap="round"/>
  <line x1="7" y1="-21" x2="9" y2="0" stroke="#939aa1" stroke-width="10" stroke-linecap="round"/>
  <line x1="-9" y1="-18" x2="-11" y2="-5" stroke="#b0b5b8" stroke-width="1"/>
  <line x1="9" y1="-18" x2="10" y2="-5" stroke="#c3c6c6" stroke-width="1"/>
  <rect x="-16" y="-2" width="16" height="6" rx="2" fill="#1d2933"/>
  <rect x="4" y="-2" width="16" height="6" rx="2" fill="#182730"/>
  <line x1="-15" y1="3" x2="-2" y2="3" stroke="#8a999f" stroke-width="1"/>
  <line x1="5" y1="3" x2="18" y2="3" stroke="#8a999f" stroke-width="1"/>

  <!-- Arms & Blue Sleeves -->
  <line x1="-15" y1="-38" x2="-18" y2="-19" stroke="#35699b" stroke-width="10" stroke-linecap="round"/>
  <line x1="15" y1="-38" x2="19" y2="-20" stroke="#568fc1" stroke-width="10" stroke-linecap="round"/>
  <circle cx="-18" cy="-17" r="3.5" fill="#dbb395"/>
  <circle cx="19" cy="-18" r="3.5" fill="#dbb395"/>

  <!-- Blue Hoodie Body -->
  <rect x="-17" y="-44" width="35" height="30" rx="7" fill="#397bae"/>
  <line x1="-15" y1="-36" x2="-14" y2="-20" stroke="#83b8d7" stroke-width="1.3"/>
  <line x1="16" y1="-36" x2="15" y2="-20" stroke="#639ec7" stroke-width="1.3"/>
  <rect x="-12" y="-19" width="25" height="4" rx="2" fill="#2c6697"/>
  <ellipse cx="0" cy="-43" rx="17" ry="10" fill="#558cb6" stroke="#89b8d4" stroke-width="1"/>
  <ellipse cx="0" cy="-44" rx="11" ry="6" fill="#24577f"/>

  <!-- Kangaroo Pocket & Drawstrings -->
  <polygon points="-9,-28 -5,-33 6,-33 10,-28 9,-22 -8,-22" fill="#306a9b" stroke="#689ac0" stroke-width="1"/>
  <line x1="-6" y1="-41" x2="-7" y2="-33" stroke="#d0d9d3" stroke-width="1"/>
  <line x1="7" y1="-41" x2="8" y2="-33" stroke="#d0d9d3" stroke-width="1"/>

  <!-- Bald Clean-Shaven Head & Facial Contours -->
  <rect x="-5" y="-44" width="12" height="7" rx="3" fill="#cda587"/>
  <ellipse cx="-12" cy="-50" rx="3" ry="5" fill="#c59a80"/>
  <ellipse cx="13" cy="-50" rx="3" ry="5" fill="#d4ad90"/>
  <ellipse cx="0" cy="-52" rx="13" ry="15" fill="#deb596"/>
  <ellipse cx="-8" cy="-46" rx="6" ry="7" fill="#deb194"/>
  <ellipse cx="8" cy="-46" rx="6" ry="7" fill="#e6ba9b"/>
  <ellipse cx="-3" cy="-61" rx="6" ry="3" fill="#edc9a9"/>
  <line x1="-8" y1="-55" x2="-3" y2="-55" stroke="#8f715d" stroke-width="1.3"/>
  <line x1="3" y1="-55" x2="8" y2="-55" stroke="#8f715d" stroke-width="1.3"/>
  <circle cx="-5" cy="-52" r="1.1" fill="#303c43"/>
  <circle cx="6" cy="-52" r="1.1" fill="#303c43"/>
  <line x1="1" y1="-51" x2="2" y2="-47" stroke="#b68c71" stroke-width="1.2"/>
  <ellipse cx="2" cy="-46" rx="2.5" ry="1.5" fill="#d3a287"/>
  <ellipse cx="-8" cy="-47" rx="3.5" ry="2" fill="#dfa88e"/>
  <ellipse cx="8" cy="-47" rx="3.5" ry="2" fill="#e4ab8f"/>
  <line x1="-3" y1="-42" x2="5" y2="-42" stroke="#a77565" stroke-width="1.1"/>
  <ellipse cx="1" cy="-39" rx="5" ry="2" fill="#e3bb9d"/>
</svg>`;

// 3. Worker (Uniform with helmet, visor, jacket and boots)
function createWorkerSvg(crewColor, helmetColor) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-30 -70 60 80">
  <ellipse cx="0" cy="4" rx="17" ry="6" fill="#142a2c" opacity="0.33"/>
  <line x1="-6" y1="-19" x2="-8" y2="0" stroke="#203938" stroke-width="8" stroke-linecap="round"/>
  <line x1="6" y1="-19" x2="8" y2="0" stroke="#203938" stroke-width="8" stroke-linecap="round"/>
  <rect x="-13" y="-2" width="12" height="6" rx="2" fill="#172e30"/>
  <rect x="3" y="-2" width="12" height="6" rx="2" fill="#172e30"/>
  <rect x="-12" y="-38" width="25" height="25" rx="5" fill="${crewColor}"/>
  <rect x="-15" y="-37" width="6" height="18" rx="3" fill="${crewColor}"/>
  <line x1="13" y1="-34" x2="16" y2="-18" stroke="#d1a465" stroke-width="6" stroke-linecap="round"/>
  <rect x="-10" y="-27" width="22" height="3" fill="#e9d6a9"/>
  <rect x="-3" y="-37" width="6" height="23" fill="#d0a66b"/>
  <circle cx="1" cy="-45" r="10" fill="#cab995"/>
  <rect x="-12" y="-50" width="27" height="6" rx="3" fill="${helmetColor}"/>
  <circle cx="1" cy="-52" r="10" fill="${helmetColor}"/>
  <rect x="-9" y="-49" width="21" height="3" fill="#f1d17a"/>
  <rect x="-5" y="-45" width="14" height="4" rx="2" fill="#425850"/>
</svg>`;
}

// 4. Centrifugal Casting Machine (Centra MK I)
const machineCentraSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-90 -210 180 230">
  <defs>
    <radialGradient id="boreHeat" cx="30%" cy="30%" r="70%">
      <stop offset="0%" stop-color="#fff5c9"/>
      <stop offset="50%" stop-color="#ff983f"/>
      <stop offset="100%" stop-color="#647f76"/>
    </radialGradient>
  </defs>
  <!-- Floor Footprint Shadow -->
  <ellipse cx="16" cy="14" rx="80" ry="20" fill="#0b2528" opacity="0.32"/>
  <!-- Mounting Feet -->
  <rect x="-51" y="-7" width="15" height="22" rx="3" fill="#253d3c"/>
  <rect x="37" y="-7" width="15" height="22" rx="3" fill="#253d3c"/>
  <rect x="-50" y="-5" width="13" height="4" fill="#a1ab8c"/>
  <rect x="38" y="-5" width="13" height="4" fill="#a1ab8c"/>

  <!-- 3D Casing Geometry (Side, Top, Front) -->
  <polygon points="55,-151 80,-169 80,-13 55,5" fill="#3c5957" stroke="#172e31" stroke-width="1"/>
  <polygon points="-55,-151 -30,-169 80,-169 55,-151" fill="#8ca195" stroke="#48605a" stroke-width="1"/>
  <rect x="-55" y="-151" width="110" height="156" rx="4" fill="#647e78"/>
  <line x1="-53" y1="-148" x2="51" y2="-148" stroke="#c5cfaa" stroke-opacity="0.47" stroke-width="2"/>

  <!-- Interior Chamber Cutout -->
  <rect x="-43" y="-133" width="73" height="105" rx="4" fill="#344b49"/>
  <rect x="-39" y="-129" width="65" height="98" rx="3" fill="#12292d"/>
  <rect x="-35" y="-124" width="57" height="87" rx="4" fill="#1b3437"/>

  <!-- Rotating Mould / Cylinder Drum -->
  <circle cx="-7" cy="-82" r="30" fill="#14282c" stroke="#799387" stroke-width="1"/>
  <circle cx="-7" cy="-82" r="27" fill="#59706b"/>
  <circle cx="-7" cy="-82" r="25" fill="url(#boreHeat)"/>
  <circle cx="-7" cy="-82" r="15" fill="#122d32"/>
  <circle cx="-6" cy="-80" r="11" fill="#112b30"/>

  <!-- Mould Spoke Marks -->
  <circle cx="14" cy="-82" r="2.4" fill="#ffefbb"/>
  <line x1="11" y1="-82" x2="17" y2="-82" stroke="#ffe9b1" stroke-width="2"/>

  <!-- Open Hinged Door -->
  <polygon points="-43,-134 -78,-144 -78,-40 -43,-29" fill="#718980" stroke="#c3cba3" stroke-opacity="0.4" stroke-width="1"/>
  <polygon points="-48,-124 -72,-131 -72,-53 -48,-44" fill="#263e3f" stroke="#a3b99a" stroke-opacity="0.25" stroke-width="1"/>
  <line x1="-69" y1="-91" x2="-69" y2="-78" stroke="#b8c9ac" stroke-width="3"/>
  <rect x="-47" y="-117" width="6" height="13" rx="2" fill="#a8b599"/>
  <rect x="-47" y="-51" width="6" height="13" rx="2" fill="#a8b599"/>

  <!-- Machine Badge & Indicators -->
  <rect x="36" y="-133" width="13" height="45" rx="2" fill="#2c4849"/>
  <rect x="38" y="-128" width="9" height="15" rx="2" fill="#102e32"/>
  <circle cx="42" cy="-101" r="4" fill="#94b495"/>
  <circle cx="42" cy="-77" r="6" fill="#2b4444" stroke="#a5b69c" stroke-width="1"/>
  <rect x="-44" y="-20" width="64" height="10" rx="2" fill="#254443"/>
  <rect x="27" y="-20" width="21" height="10" rx="1" fill="#bdad6b"/>
  <text x="37" y="-12" font-family="Arial" font-size="9" text-anchor="middle" fill="#393e2a">⚡</text>
  <text x="-12" y="-12" font-family="Arial" font-size="8" font-weight="bold" text-anchor="middle" fill="#b5c6af">CENTRA · I</text>
</svg>`;

// 5. Washer Enclosure (Pieskovač)
const washerSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="350 190 400 340">
  <!-- 3D Perspective Roof & Right Wall -->
  <polygon points="372,231 406,202 724,202 690,231" fill="#4b8da8" stroke="#92b9c9" stroke-width="1"/>
  <polygon points="690,231 724,202 724,422 690,452" fill="#154e71" stroke="#3b7690" stroke-width="1"/>

  <!-- Main Blue Enclosure -->
  <rect x="372" y="231" width="318" height="221" rx="5" fill="#28698f"/>
  <line x1="377" y1="233" x2="687" y2="233" stroke="#85b8cc" stroke-width="2"/>
  <rect x="381" y="241" width="300" height="42" rx="3" fill="#1d4868"/>
  <text x="397" y="268" font-family="Arial, sans-serif" font-size="22" font-weight="bold" fill="#f0f5e6">PIESKOVAČ</text>
  <text x="397" y="278" font-family="Arial, sans-serif" font-size="9" fill="#a6cbdc">VODNÉ ČISTENIE / UZAVRETÁ KOMORA</text>

  <!-- Service Doors -->
  <rect x="384" y="294" width="204" height="136" rx="3" fill="#235a80"/>
  <rect x="390" y="300" width="192" height="124" rx="3" fill="#2c7198"/>
  <line x1="487" y1="302" x2="487" y2="421" stroke="#163f5d" stroke-width="3"/>
  <rect x="476" y="347" width="5" height="24" rx="2" fill="#c4d4d3"/>
  <rect x="497" y="347" width="5" height="24" rx="2" fill="#c4d4d3"/>

  <!-- Control Panel & Pressure Gauge -->
  <rect x="604" y="296" width="66" height="118" rx="4" fill="#153c55"/>
  <rect x="612" y="305" width="50" height="31" rx="2" fill="#0c2535"/>
  <circle cx="624" cy="351" r="7" fill="#4f7274"/>
  <circle cx="649" cy="351" r="7" fill="#932f37"/>
  <circle cx="636" cy="387" r="18" fill="#96b4c2"/>
  <circle cx="636" cy="387" r="14" fill="#e2e7d8"/>
  <line x1="636" y1="387" x2="627" y2="394" stroke="#a44d42" stroke-width="2"/>

  <!-- Lower Base & Recirculating Filtration Tank -->
  <rect x="371" y="436" width="320" height="17" rx="2" fill="#142d41"/>
  <rect x="479" y="466" width="141" height="54" rx="5" fill="#25495c"/>
  <polygon points="479,466 490,457 630,457 619,466" fill="#6a98ab"/>
  <rect x="487" y="476" width="8" height="31" rx="2" fill="#7bc2d2"/>
  <text x="557" y="492" font-family="Arial, sans-serif" font-size="10" fill="#c1d8dd">VODA · FILTRÁCIA</text>
  <circle cx="642" cy="482" r="14" fill="#397d96"/>
  <circle cx="642" cy="482" r="7" fill="#142f45"/>
  <line x1="643" y1="467" x2="643" y2="448" stroke="#7aafbd" stroke-width="5"/>
</svg>`;

// Write Files
fs.writeFileSync(path.join(charDir, 'foreman_miso.svg'), misoSvg, 'utf8');
fs.writeFileSync(path.join(charDir, 'foreman_miro.svg'), miroSvg, 'utf8');
fs.writeFileSync(path.join(charDir, 'worker_furnace.svg'), createWorkerSvg('#9b4834', '#e29d42'), 'utf8');
fs.writeFileSync(path.join(charDir, 'worker_operator.svg'), createWorkerSvg('#385f57', '#d9a842'), 'utf8');
fs.writeFileSync(path.join(charDir, 'worker_washer.svg'), createWorkerSvg('#2e566d', '#58a0be'), 'utf8');
fs.writeFileSync(path.join(charDir, 'worker_storekeeper.svg'), createWorkerSvg('#4f5847', '#97aa68'), 'utf8');
console.log('Character SVGs generated.');

fs.writeFileSync(path.join(machDir, 'centra_mk1.svg'), machineCentraSvg, 'utf8');
fs.writeFileSync(path.join(machDir, 'washer_enclosure.svg'), washerSvg, 'utf8');
console.log('Machine SVGs generated.');

# 05. Zvukový dizajn a vizuálne efekty (Audio & VFX)

Tento dokument definuje implementáciu zvukového dizajnu a pokročilých vizuálnych efektov v hernom engine **Godot 4.7**, ktoré posunú atmosféru priemyselného závodu na novú úroveň.

---

## 1. Architektúra zvukového systému (`AudioManager`)

Hra využíva systém zvukových zberníc (Audio Buses) v Godote pre vyvážené mixovanie a ovládanie hlasitosti:

```text
Master Bus
├── Ambient Bus (Hluk hál, hučanie pece, ventilácia)
├── Machines Bus (Motory odstrediviek, žeriav, pieskovač)
├── SFX Bus (Nalievanie, para, dopad rúry na paletu, havárie)
└── UI Bus (Kliky tlačidiel, cinknutie mincí, poplašný bzučiak)
```

### 1.1 Katalóg zvukových efektov

| Kategória | Udalosť / Názov | Zvukový charakter |
| :--- | :--- | :--- |
| **Ambient** | `furnace_hum` | Hlboký nízkofrekvenčný hluk pece (loop), praskanie plameňa |
| **Ambient** | `hall_ambience` | Hutnícka hala, ventilátory, vzdialené údery kladív |
| **Stroje** | `motor_spinup` | Zrýchľujúce pískanie elektromotora odstredivky (0 až 1.6 s) |
| **Stroje** | `motor_loop` | Rýchle rotačné hučanie formy počas odlievania |
| **Stroje** | `crane_move` | Kvílenie lán a posun žeriavového vozíka po koľajnici |
| **Výroba** | `metal_pour` | Syčanie a bublanie tekutého kovu nalievaného do formy |
| **Výroba** | `water_cooling` | Intenzívne syčanie vody dopadajúcej na žeravý kov, únik pary |
| **Výroba** | `pallet_drop` | Kovový dutý úder hotovej rúry odloženej na paletu |
| **Havária** | `cast_fail_burst` | Prasknutie kovu, ohlušujúci výstrel, prskanie stoviek iskier |
| **Pieskovač** | `washer_spray` | Hukot vysokotlakového vodného čerpadla pri 120 bar |
| **Obchod** | `coin_cash` | Cinknutie starých mincí / registračnej pokladnice pri predaji |
| **Varovanie** | `alarm_buzzer` | Priemyselný bzučiak pri zmeškanom termíne alebo absencii |

---

## 2. Časticové systémy (VFX)

Pôvodný engine počítal v JavaScripte 720 jednotlivých častíc v slučke na CPU. V Godote použijeme hardvérovo akcelerované uzly `GPUParticles2D` s nasledujúcim nastavením:

### 2.1 Havária rúry (`RejectSparks.tscn`)
- **Počet častíc**: 720.
- **Dĺžka trvania**: 2.5 s (one-shot).
- **Emisný tvar**: Bodový z ústia rotujúcej formy.
- **Rýchlosť**: 105 až 275 px/s, kužeľový rozptyl s počiatočným uhlom.
- **Gravitácia**: $94\ \text{px/s}^2$ (balistický pád).
- **Farebná rampa (`ColorRamp`)**:
  - 0.0 s: Bielo-žltá (`#FFF5C9`, extrémny žiar)
  - 0.3 s: Oranžovo-žltá (`#FFC266`)
  - 0.8 s: Tmavočervená (`#FF6B2E`)
  - 2.0 s: Dymovo sivá až priehľadná (vyhasínajúci kov)
- **Torn Chips (Horúce úlomky)**:
  - 12 väčších polygónov s rotáciou, ktoré simulujú odtrhnuté časti odliatku.

### 2.2 Parné ventilátory chladenia (`SteamVent.tscn`)
- **Počet častíc**: 32 častíc za sekundu.
- **Emisný tvar**: Obdĺžnik pozdĺž horného výduchu komína.
- **Pohyb**: Stúpanie nahor s tlmeným horizontálnym vírením.
- **Materiál**: Textúra mäkkého dymu, miešanie `BlendMode: Add` s polopriehľadnou azúrovo-bielou farbou (`#D8F2F4`).

### 2.3 Tlaková voda v pieskovači (`WaterSpray.tscn`)
- **Počet častíc**: 128 kvapiek za sekundu.
- **Rýchlosť**: Vysoká počiatočná rýchlosť z trysiek, odraz od stien komory.
- **Farba**: Svetlomodrá vodná emulzia (`#B8F2FA`).

---

## 3. GLSL Canvas Shadery

### 3.1 Shader žeravenia taveniny (`res://assets/shaders/heat_glow.gdshader`)
Tento shader riadi farbu a vyžarovanie formy a panvy podľa simulovanej teploty (20 °C až 1700 °C):

```glsl
shader_type canvas_item;

uniform float temperature : hint_range(20.0, 1700.0) = 20.0;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;

vec3 get_heat_color(float temp) {
    if (temp <= 400.0) {
        float f = (temp - 20.0) / 380.0;
        return mix(vec3(0.32, 0.40, 0.42), vec3(0.43, 0.24, 0.20), f);
    } else if (temp <= 650.0) {
        float f = (temp - 400.0) / 250.0;
        return mix(vec3(0.43, 0.24, 0.20), vec3(0.72, 0.21, 0.13), f);
    } else if (temp <= 900.0) {
        float f = (temp - 650.0) / 250.0;
        return mix(vec3(0.72, 0.21, 0.13), vec3(0.97, 0.38, 0.15), f);
    } else if (temp <= 1150.0) {
        float f = (temp - 900.0) / 250.0;
        return mix(vec3(0.97, 0.38, 0.15), vec3(1.00, 0.62, 0.26), f);
    } else if (temp <= 1450.0) {
        float f = (temp - 1150.0) / 300.0;
        return mix(vec3(1.00, 0.62, 0.26), vec3(1.00, 0.91, 0.64), f);
    } else {
        return vec3(1.00, 0.95, 0.75);
    }
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    vec3 heat = get_heat_color(temperature);
    COLOR = vec4(mix(tex_color.rgb, heat, intensity), tex_color.a);
}
```

# 02. Simulačný engine a 100% parita pravidiel

Tento dokument detailne špecifikuje portovanie simulačného enginu z `dist/engine.js` do GDScriptu (`res://src/simulation/FoundryEngine.gd`) s garanciou matematickej parity a zhodného správania.

---

## 1. Časový model a determinizmus

### 1.1 Časové konštanty
- **1 deň** = `180.0` sekúnd.
- **1 týždeň** = 7 dní = `1260.0` sekúnd.
- **Aktualizácia burzy (Quote Interval)** = každých `15.0` sekúnd.
- **Smeny**: 3 smeny za deň (po 60 sekundách = 8 herných hodín):
  - Ranná smena (Miči): `06:00 – 14:00`
  - Popoludňajšia smena (Maslo): `14:00 – 22:00`
  - Nočná smena (Matino): `22:00 – 06:00` (+50 % mzdový príplatok)
- **Majstri**: 2 dvanásťhodinové smeny (po 90 sekundách = 12 herných hodín):
  - Mišo: `06:00 – 18:00` (12 hodín denná sadzba)
  - Miro: `18:00 – 06:00` (4 hodiny denná sadzba, 8 hodín nočná sadzba s príplatkom)

### 1.2 Deterministický generátor náhodných čísel (LCG)
Pôvodný engine používa lineárny kongruentný generátor (Numerical Recipes LCG). V GDScript 2.0 ho implementujeme tak, aby produkoval identickú postupnosť:

```gdscript
class_name FoundryRNG
extends RefCounted

static func roll(state: Dictionary) -> float:
    # 32-bit unsigned celočíselná aritmetika: (seed * 1664525 + 1013904223) & 0xFFFFFFFF
    var next_seed: int = (state.rng * 1664525 + 1013904223) & 0xFFFFFFFF
    state.rng = next_seed
    return float(next_seed) / 4294967296.0

static func personnel_roll(state: Dictionary) -> float:
    var hr: Dictionary = state.hr
    var next_seed: int = (hr.rng * 1664525 + 1013904223) & 0xFFFFFFFF
    hr.rng = next_seed
    return float(next_seed) / 4294967296.0
```

---

## 2. Katalóg surovín a výrobkov

### 2.1 Suroviny (5 druhov)
| ID | Názov | Skratka | Základná cena (₵) | Kapacita zásobníka (kg) | Odomknutie skladu (₵) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `iron` | Surové železo | Železo | 4 | 60 | 0 (odomknutý) |
| `zinc` | Zinok | Zinok | 3 | 40 | 0 (odomknutý) |
| `steel` | Oceľová vsádzka | Oceľ | 7 | 40 | 180 |
| `copper` | Meď | Meď | 11 | 30 | 240 |
| `tin` | Cín | Cín | 15 | 20 | 180 |

### 2.2 Výrobky a technologické parametre
| ID | Výrobok | Recept | Čas cyklu (MK I/II/III) | Teplota | Odomknutie | Očistený ekvivalent |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `iron_pipe` | Liatinová rúra | 6 Fe + 1 Zn | 28 s / 22 s / 17 s | 1700 °C | 0 (v základe) | `clean_iron_pipe` |
| `ring` | Oceľový prstenec | 5 OC + 1 Zn | 24 s / 18 s / 13 s | 1700 °C | 0 (v základe) | `clean_ring` |
| `steel_pipe` | Oceľová rúra | 5 Fe + 3 OC + 2 Zn | 34 s / 28 s / 23 s | 1700 °C | 280 ₵ | `clean_steel_pipe` |
| `bronze_bushing` | Bronzové puzdro | 4 Cu + 1 Sn + 1 Zn | 26 s / 20 s / 15 s | 1700 °C | 520 ₵ | `clean_bronze_bushing` |

> [!IMPORTANT]
> **Pravidlo predaja**: Všetky odliatky musia pred predajom na burze alebo dodaním do zákaziek prejsť vodným čistením v pieskovači (`WASH`). Neočistené kusy nie sú predajné!

---

## 3. Výrobný cyklus a stavy odstredivky

### 3.1 Časová os dávky (Flow Timeline)
Priebeh odliatia riadi striktná časová postupnosť:
1. `spinup` (0.0 – 1.6 s): Roztáčanie formy.
2. `waiting`: Čakanie vo fronte na uvoľnenie jedinej zdieľanej panvy.
3. `loading` (1.6 – 3.2 s): Plnenie zavesenej panvy taveninou z pece.
4. `carrying` (3.2 – 7.4 s): Preprava žeravého kovu pojazdným závesom ku stroju.
5. `pouring` (7.4 – 10.2 s): Nalievanie kovu z panvy do rotujúcej formy.
6. `spinning` (10.2 – 12.2 s): Odstredivé tvarovanie kovu.
7. `cooling` (12.2 s – koniec): Vodné chladenie tryskami (závisí od úrovne MK stroja).
8. `ready`: Odliatok je hotový, čaká na vyloženie obsluhou.
9. `unloading` (4.0 s): Obsluha odoberá kus a odnáša ho na železnú paletu pri stroji.
10. `failed` (4.0 s): Havária / nepodarok rúry. Unikajúci kov a vyčistenie stroja.

### 3.2 Riziko nepodarku rúry (Failure Risk Formula)
$$\text{Riziko nepodarku} = \text{Základné riziko stroja} + \frac{\text{Riziko obsluhy}}{100}$$
- Základné riziko odstredivky pre rúry:
  - MK I = `30.0 %` (0.30)
  - MK II = `20.0 %` (0.20)
  - MK III = `10.0 %` (0.10)
- Riziko obsluhy: hodnota `defect` (1 až 15 %) konkrétneho zamestnanca prideleného na danú zmenu a stroj.
- Prstence (`ring`) a puzdrá (`bronze_bushing`) riziko nepodarku nemajú.

---

## 4. Pieskovač (Vodné čistenie)
- **Cyklus**: 14 sekúnd (3 s nábeh sprava, 7 s tlakové čistenie pri 120 bar, 4 s vysunutie vľavo).
- **Náklady**: 6 ₵ za každý kus (spotreba vody a energie).
- **Podmienky**: Prítomná obsluha pieskovača (`washer`), prítomný skladník (`warehouse`), žiadny mzdový dlh.

---

## 5. Personálny systém a mzdové účtovníctvo

### 5.1 Výpočet mzdy uchádzača
Základné sadzby profesií na 8-hodinovú zmenu:
- Panvár (`ladle`): 18 ₵
- Tavič (`furnace`): 14 ₵
- Skladník (`warehouse`): 12 ₵
- Obsluha pieskovača (`washer`): 16 ₵
- Obsluha odstredivky (`operator`): 16 ₵
- Majster (`foreman`): 20 ₵

Vzorec pre dohodnutú mzdu uchádzača:
```gdscript
func calculate_candidate_salary(role: String, defect: int, absence: float) -> float:
    var base: float = WAGES[role]
    var quality_factor: float = 0.225
    if has_defect(role):
        quality_factor = 0.45 * (15.0 - defect) / 14.0
    var reliability_factor: float = 0.45 * (10.0 - absence) / 9.5
    var salary: float = base * (0.65 + quality_factor + reliability_factor)
    return round(salary * 10.0) / 10.0
```

### 5.2 Absencie a nadčasy
- Na začiatku každej zmeny sa vyhodnotí účasť zamestnanca náhodným hodom proti jeho percentu absencie (`e.absence`).
- Ak pracovník nepríde, stroj/úsek stojí, kým hráč manuálne v Kancelárii nezavolá zastúpenie z inej voľnej zmeny.
- Sadzba za nadčas: **+50 %** (v noci sa násobí nočným príplatkom: $1.5 \times 1.5 = 2.25\times$).

### 5.3 Odstupné pri prepustení (Severance Pay)
- 0 až 27 dní zamestnania: 0 týždňov.
- 1 mesiac (28–55 dní): 1 týždenná mzda.
- 2 mesiace (56–83 dní): 2 týždenné mzdy.
- 3+ mesiace (84+ dní): 4 týždenné mzdy.

---

## 6. Burza a Zákazky

### 6.1 Harmonické cenové vlny
Cena každej položky na burze osciluje podľa trigonometrických funkcií v závislosti od herného času a dennej trhovej udalosti (`EVENTS`):
$$\text{Hodnota}(t) = \max\left(1, \text{round}\left(\text{Base} \times (1 + \text{EventFactor} + 0.14 \sin(0.83 t + 1.7 n) + 0.07 \sin(0.37 t + 0.91 n))\right)\right)$$
- **Ask (Nákup suroviny)**: $\text{Hodnota}$
- **Bid (Predaj)**: $\lfloor \text{Hodnota} \times 0.78 \rfloor$ (suroviny) alebo $\lfloor \text{Hodnota} \times 0.88 \rfloor$ (výrobky)

### 6.2 Vzťahy s odberateľmi (Relationships)
- Úspešné dodanie v termíne: skóre vzťahu **+10**, reputácia **+2**.
- Zmeškanie termínu (135 s): skóre vzťahu **-15**, reputácia **-1**.
- Lepšie vzťahy zvyšujú objemy zákaziek a poskytujú bonus k výplate až **+30 %**.

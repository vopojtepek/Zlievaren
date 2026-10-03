# 03. Haly, scény a 2D vykresľovanie

Tento dokument špecifikuje transformáciu vizuálneho vykresľovania z HTML5 Canvas (`dist/renderer.js`) do scén a uzlov herného enginu **Godot 4.7**.

---

## 1. Koncepcia vizuálneho štýlu

Pôvodná hra využíva charakteristickú pseudo-izometrickú technickú kresbu s dôrazom na priemyselnú atmosféru, dym, paru, žeravý kov a detailnú animáciu mechanických súčastí.

V Godote zachováme tento vizuálny štýl s nasledujúcim rozdelením:
1. **Základná geometria a maľba**: Využitie `Polygon2D`, `Line2D` a vlastných `_draw()` procedurálnych uzlov pre ostrú vektorovú estetiku bez rozmazania textúr.
2. **Časticové systémy (VFX)**: Nahradenie softvérových slučiek výkonnými časticovými uzlami `GPUParticles2D` (alebo `CPUParticles2D` pre Web export).
3. **Svetlo a atmosféra**: `CanvasModulate` v kombinácii s `PointLight2D` pre realistický nočný a denný cyklus.

---

## 2. Architektúra miestností a prepínanie pohľadov

Hlavná scéna `res://src/scenes/Main.tscn` obsahuje `RoomContainer` (`Node2D`), v ktorom je aktívna práve jedna z piatich hál:

```text
Main.tscn
├── Camera2D (1920x1080 zameraná na stred)
├── RoomContainer (Node2D)
│   ├── FoundryHall.tscn    # Hala 01
│   ├── WarehouseHall.tscn  # Hala 02
│   ├── WasherHall.tscn     # Hala 03
│   ├── CncHall.tscn        # Hala 04
│   └── OfficeRoom.tscn     # Miestnosť 05
├── LightingEnvironment (CanvasModulate + smerové svetlá)
└── UILayer (CanvasLayer)
    ├── HUD
    ├── MachineInspector
    ├── ManagementPanel
    └── DialogLayer
```

---

## 3. Podrobná špecifikácia jednotlivých hál

### 3.1 Hala 01: Taviareň a Odlievacia hala (`FoundryHall.tscn`)
- **Pec 01 (Furnace)**:
  - Masívne šamotové teleso s naklápacou sopúchovou hubicou.
  - Vnútro pece žiari teplotou 1700 °C.
  - Pri plnení panvy sa hubica nakláňa (`furnaceTilt`) a prúd tekutého kovu preteká do pristavenej panvy.
- **Pojazdný záves a panva (Overhead Ladle)**:
  - Žeriavový vozík jazdiaci po stropnej koľajnici (žltý nosník).
  - Dvojité nosné oceľové laná s pevnou traverzou a naklápacou panvou.
  - Panva sleduje presnú trasu (`deliveryRoute`): Pec $\to$ hlavná ulička $\to$ zvolená odstredivka $\to$ návrat.
  - Nalievanie žeravého kovu s dynamickým prúdom a iskrením.
- **Stanovištia odstrediviek 1–6 (Centrifugal Machines)**:
  - 3 stanice v hornom rade, 3 stanice v dolnom rade.
  - Masívny oceľový plášť (farba podľa úrovne MK I sivá, MK II modrastá, MK III zelenkavá).
  - Rotujúca forma s vŕtaním, obvodovými značkami a farebnou teplotnou žiarou (od 20 °C do 1700 °C).
  - Otváranie servisných dverí pri chladnutí a vykladaní.
  - Dve vnútorné trysky vodného chladenia s vejárom jemnej vodnej hmly a zbernou vaňou.
  - Horný komín odvádzajúci stúpajúce parné oblaky.
  - **Efekt havárie rúry**: 720 balistických iskier a horiacich šupín vystreľujúcich z rotujúceho otvoru pri nepodarku.
- **Postavy v hale**:
  - **Tavič (Furnace Worker)** pri peci.
  - **Panvár (Ladle Worker)** sprevádzajúci zavesenú panvu.
  - **Obsluha odstredivky (Operator)** pri každom aktívnom stroji odnášajúca hotové výrobky na paletu (4 s).
  - **Majster (Foreman)**: hliadkuje po centrálnej lávke. Vizuálne rozlíšenie:
    - *Mišo (deň)*: tmavá mikina s kapucňou, dlhé hnedé vlasy, hustá brada.
    - *Miro (noc)*: modrá mikina, sivé nohavice, holohlavá tvár.

---

### 3.2 Hala 02: Sklad a Príjem surovín (`WarehouseHall.tscn`)
- **Príjmová rampa**:
  - Vykladacia brána a žlto pruhovaný vykládkový priestor.
  - Zobrazenie paliet s dovezenými surovinami čakajúcimi na naskladnenie.
- **5 Zásobníkov surovín**:
  - Železo (Fe), Zinok (Zn), Oceľ (OC), Meď (Cu), Cín (Sn).
  - Vizuálne zobrazenie výšky naplnenia zásobníka (hromady vsádzky).
  - Vizuálny stav: zamknutý sklad s reťazou/cenovkou vs. odomknutý rozšírený sklad (úrovne 1 až 8).
- **Regály hotových výrobkov**:
  - Regálová konštrukcia s uloženými očistenými výrobkami rozdelenými podľa typu.
- **Skladník (Warehouse Worker)**:
  - Pohyb s paletovým vozíkom medzi rampou a konkrétnym zásobníkom pri uskladnení materiálu.

---

### 3.3 Hala 03: Pieskovač / Vodné čistenie (`WasherHall.tscn`)
- **Modrá uzavretá čistiaca komora**:
  - Rozmery 318 × 221 px s nápisom PIESKOVAČ.
  - Tlakový manometer (0 až 120 bar) s animovanou ručičkou.
  - LED kontrolky stavu (RUN / STANDBY).
  - Recirkulačná nádrž s filtráciou a potrubím.
- **Dopravníky**:
  - Vstupný valčekový dopravník sprava (neočistené odliatky).
  - Výstupný valčekový dopravník vľavo (čisté odliatky zbavené emulzie).
  - Viditeľný posun rúry do komory a vysunutie po očistení.
- **Obsluha pieskovača**:
  - Robotník kontrolujúci proces na vstupe.

---

### 3.4 Hala 04: CNC Hala (`CncHall.tscn`)
- **Linka CNC 1 až 6**:
  - 4 stroje hore, 2 stroje vpravo dole.
  - Zelené/červené LED signalizačné majáky.
  - Chladiace emulzné stopy a dopravník špon s odpadovým kontajnerom.
  - Klikateľné stanice umožňujúce nákup alebo zapnutie stroja.
- **AMADA**:
  - Moderný červený laserový/rezací CNC stroj vľavo dole (zatiaľ zamknutý pre budúce rozšírenia).
- **Pracovisko programátora**:
  - Stôl s monitorom, klávesnicou a otočnou kancelárskou stoličkou.

---

### 3.5 Miestnosť 05: Kancelária (`OfficeRoom.tscn`)
- Reprezentácia riaditeľne a personálneho oddelenia.
- Industriálny stôl majstra s telefónom, mzdovou knihou, výkresmi na stene a nástenkou dochádzky.
- Poskytuje plynulý prechod do komplexného rozhrania personálneho riadenia.

---

## 4. Denný a nočný svetelný cyklus

Vykresľovanie plynule reaguje na čas dňa pomocou `Foundry.daylight(state)`:
$$\text{Daylight} = \text{clamp}\left(\frac{\sin\left(\frac{\text{Hour} - 6}{24} \times 2\pi\right) + 0.2}{1.2}, 0.0, 1.0\right)$$

- **Deň**: Okná a svetlíky prepúšťajú modré/biele denné svetlo, haly sú prirodzene jasné.
- **Zotmenie a Noc**: `CanvasModulate` stmaví prostredie do hlbokého priemyselného modro-sivého tónu (`#081223`).
- **Umelé osvetlenie**: Zopnú sa halové halogénové lampy (kužele svetla zavesené pod stropom) a rozžiaria sa pece a odliatky.

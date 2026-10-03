# 04. Používateľské rozhranie a HUD systém

Tento dokument definuje implementáciu kompletného používateľského rozhrania (UI), inšpektorov hál a personálnej Kancelárie pomocou `Control` uzlov v hernom engine **Godot 4.7**.

---

## 1. Štruktúra rozhrania a adaptívny layout

Používateľské rozhranie je navrhnuté pre základné rozlíšenie **1920 × 1080 px** v režime roztiahnutia `canvas_items` s ukotvením (anchors) do troch hlavných zón:

```text
Root Viewport (1920x1080)
├── TopHUD (PanelContainer, Top Anchor)
│   ├── FinancialBar (Peniaze, Tržby, Reputácia)
│   ├── ClockAndCalendar (Hodiny, Deň, Týždeň, Fáza dňa)
│   ├── ShiftAndForeman (Aktuálna smena, Majster v službe)
│   └── GoalMilestoneBar (Aktívny míľnik a odmena)
│
├── MainWorkspace (HBoxContainer)
│   ├── HallViewportContainer (SubViewportContainer, Expand=True)
│   │   └── RoomScene (Aktuálna 2D hala)
│   └── SideInspector (PanelContainer, Šírka 420 px)
│       ├── MachineInspector (pre Zlievareň)
│       ├── WarehouseInspector (pre Sklad)
│       ├── WasherInspector (pre Pieskovač)
│       └── CncInspector (pre CNC halu)
│
└── BottomManagement (PanelContainer, Bottom Anchor)
    └── ManagementTabContainer
        ├── TabStock (Zásoby a sklady)
        ├── TabMarket (Burza a predajné pokyny)
        ├── TabContracts (Firemné zákazky a termíny)
        └── TabDevelopment (Výskum a technologické vylepšenia)
```

---

## 2. Inšpektory jednotlivých hál

### 2.1 Inšpektor odstredivky (Zlievareň)
- **Prepínač stanovišťa (Taby 1–6)**: Indikácia stavu (voľný, v práci, hotový, nepodarok).
- **Stav stroja**: Textový popis fázy (`Pripravená`, `Roztáčanie`, `Čaká na panvu`, `Nalievanie`, `Chladenie vodou`, `Hotový výrobok`, `Nepodarená rúra`).
- **Výber receptu (`OptionButton`)**: Zoznam odomknutých odliatkov a ich suroviny (zelená / červená farba pri nedostatku na sklade).
- **Ukazovateľ teploty a tepla**: Teplomer od 20 do 1700 °C, dynamická farba textu.
- **Riziko nepodarku**:
  - Výpočet celkového rizika (odstredivka MK + priradená obsluha smeny).
- **Primárne akčné tlačidlo**:
  - `Kúpiť odstredivku` (pri prázdnom stanovišti).
  - `Vyrobiť 1 kus` (odoberie suroviny zo skladu).
  - `Odniesť na paletu` (po dokončení cyklu).
- **Automatická séria (`CheckButton`)**: Nepretržitá výroba, pokiaľ je na sklade surovina a obsluha v práci.
- **Vylepšenie stroja (MK I $\to$ MK II $\to$ MK III)**: Skrátenie času výroby a zníženie rizika nepodarku.

### 2.2 Inšpektor skladu
- **Prepínač zásobníkov**: Surové železo (Fe), Zinok (Zn), Oceľ (OC), Meď (Cu), Cín (Sn), Hotové výrobky.
- **Prehľad kapacity**: Vizuálny ukazovateľ `ProgressBar` naplnenia zásobníka.
- **Materiál na príjmovej rampe**: Tovar čakajúci na naskladnenie.
- **Akcie**:
  - `Uskladniť X kg` (skladník presunie tovar z rampy do zásobníka).
  - `Odomknúť sklad` (pre oceľ, meď, cín).
  - `Rozšíriť zásobník` (zvýšenie kapacity o základný objem).
  - `Prejsť na burzu` (skok do nákupu danej suroviny).

### 2.3 Inšpektor pieskovača
- **Výber programu čistenia**: Výber typu odliatku (liatinová rúra, oceľová rúra, prstenec, bronzové puzdro).
- **Stav čistenia**: Ukazovateľ tlaku (120 bar) a zostávajúci čas cyklu (14 s).
- **Surové vs. Opracované kusy**: Počet kusov na sklade čakajúcich na čistenie vs. hotové čisté odliatky.
- **Akcie**:
  - `Naložiť a vyčistiť · 6 ₵`.
  - `Automatické čistenie` (séria).

---

## 3. Manažérsky spodný panel

### 3.1 Burza a trh (`TabMarket`)
- **Graf a cenový kurz**: Zobrazenie aktuálnej nákupnej ceny (Ask) a výkupnej ceny (Bid) s percentuálnou zmenou.
- **Okamžitý obchod**:
  - Nákup surovín s automatickým dodaním na príjmovú rampu.
  - Predaj očistených výrobkov s priamym pripísaním peňazí do pokladne.
- **Limitné predajné pokyny (Limit Orders)**:
  - Rezervácia tovaru na sklade s minimálnou predajnou cenou.
  - Automatické vykonanie pri prekročení cieľovej ceny na burze (až 5 paralelných pokynov).

### 3.2 Zákazky a odberatelia (`TabContracts`)
- **Zoznam firiem**: Mestské vodárne, Strojárne Hron, Severné stavby, Ložiská Tatry, Nový odberateľ.
- **Dôvera a reputácia**: Vzťahové skóre ovplyvňujúce objemy a finančné bonusy (+30 % až -30 %).
- **Ponuky (`offer`)**: Denné ponuky s odpočtom lehoty na prijatie (90 s).
- **Aktívne zákazky (`active`)**: Zákazky s lehotou na dodanie (135 s / 18 herných hodín). Tlačidlo `Expedovať zákazku`.

### 3.3 Rozvoj a výskum (`TabDevelopment`)
- Odomykanie nových výrobkov: Oceľová rúra (280 ₵), Bronzové puzdro (520 ₵).
- Zvýšenie rýchlosti žeriavového závesu s panvou (+25 % na úroveň).
- Zväčšenie skladových priestorov.

---

## 4. Personálna Kancelária (`OfficeView`)

Kancelária má k dispozícii samostatný celoobrazovkový režim s tromi podstránkami:

### 4.1 Dochádzka a pracovníci
- Zoznam všetkých pracovných pozícií pre aktuálnu smenu:
  - Tavič, Panvár, Skladník, Obsluha pieskovača, Majster, Obsluha odstrediviek 1–6.
- Karta absencie: Upozornenie na neprítomného pracovníka s možnosťou zavolať zastúpenie z inej smeny s príplatkom **+50 %**.
- Karta zamestnanca: Meno, zmena, odpracovaný čas, zarobená mzda, riziko nepodarku, riziko absencie, tlačidlo `Prepustiť`.

### 4.2 Nábor zamestnancov
- Ponuka uchádzačov pre každú neobsadenú pozíciu (2 až 5 kandidátov na miesto).
- Mená a priezviská generované z historického slovenského zoznamu (`candidateNames`, `candidateSurnames`).
- Porovnanie zručností: riziko nepodarku (1–15 %), spoľahlivosť / absencia (0.5–10 %) a vypočítaná mzda.
- Tlačidlo `Prijať uchádzača`.

### 4.3 Mzdy a história
- Aktuálne mzdové nároky v prebiehajúcom týždni (základná mzda, nadčasy, odstupné).
- Odpočet do týždennej výplaty (každých 7 herných dní o polnoci).
- Varovanie pred mzdovým dlhom: Pokiaľ pokladňa nemá dostatok prostriedkov na výplatu, vzniká dlh a výroba nových dávok sa zastaví, kým hráč nedoplatí mzdy predajom tovaru.
- Archív predchádzajúcich výplat.

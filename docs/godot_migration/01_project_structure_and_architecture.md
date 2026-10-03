# 01. Architektúra a štruktúra Godot projektu

Tento dokument definuje adresárovú štruktúru, pravidlá pre GDScript 2.0, Autoload singletony a architektúru riadenia udalostí v Godot 4.7+.

---

## 1. Adresárová štruktúra projektu (`res://`)

Podľa osvedčených postupov (skills `godot-project-setup` a `godot-gdscript-patterns`) použijeme **Split Layout** rozdelený na logické komponenty:

```text
res://
├── project.godot                     # Hlavná konfigurácia projektu
├── default_env.tres                  # Predvolené prostredie
├── .gitignore                        # Špecifikácia ignorovania .godot/, exportov
│
├── assets/                           # Statické a vizuálne suroviny
│   ├── audio/                        # Zvuky a hudba
│   │   ├── ambient/                  # Priemyselný šum, pec, hala
│   │   ├── sfx/                      # Roztáčanie motora, nalievanie, voda, mince
│   │   └── ui/                       # Kliky, prepínače, varovné bzučiaky
│   ├── fonts/                        # DM Sans, industriálne písma
│   ├── shaders/                      # GLSL Canvas shadery (kov, para, žeravenie)
│   ├── textures/                     # Podklady hál, referencie, ikony
│   └── ui/                           # Témy (.tres), StyleBoxy, vektorové SVG ikony
│
├── src/                              # Zdrojový kód (GDScript 2.0)
│   ├── autoload/                     # Globálne singletony
│   │   ├── EventBus.gd               # Centrálna zbernica signálov
│   │   ├── GameManager.gd            # Stav hry a prepínanie režimov
│   │   ├── SimulationClock.gd        # Časovač a zmennosť (180 s/deň)
│   │   ├── SaveManager.gd            # JSON ukladanie, načítanie a migrácia
│   │   └── AudioManager.gd           # Prehrávanie zvukov a mixovanie busov
│   │
│   ├── core/                         # Dátové štruktúry a konštanty
│   │   ├── Constants.gd              # Konštanty, recepty, časy, rýchlosti
│   │   └── Types.gd                  # Enumy, dátové triedy a pomocné typy
│   │
│   ├── resources/                    # Vlastné Resource triedy
│   │   ├── MaterialData.gd           # Surovina (železo, oceľ, meď, cín, zinok)
│   │   ├── ProductData.gd            # Výrobok (liatinová/oceľová rúra, prstenec, puzdro)
│   │   ├── EmployeeData.gd           # Záznam zamestnanca (mzda, zručnosti, dochádzka)
│   │   └── ContractData.gd           # Zákazka (odberateľ, termíny, odmena)
│   │
│   ├── simulation/                   # Čistá simulačná logika (100% parita s engine.js)
│   │   ├── FoundryEngine.gd          # Koordinátor celého stavu závodu
│   │   ├── MachineSimulation.gd      # Odstredivky 1–6 a fronta panvy
│   │   ├── WasherSimulation.gd       # Pieskovač a vodné čistenie
│   │   ├── WarehouseSimulation.gd    # Zásobníky surovín a palety
│   │   ├── MarketSimulation.gd       # Cenové krivky, nákup/predaj, limity
│   │   ├── PersonnelSimulation.gd    # Nábor, dochádzka, absencie, mzdy
│   │   └── ContractSimulation.gd     # Zákazky a firemné vzťahy
│   │
│   ├── ui/                           # Používateľské rozhranie (Control uzly)
│   │   ├── hud/                      # Horný informačný pás a indikátory
│   │   ├── inspectors/               # Bočné inšpektory (stroj, sklad, pieskovač, CNC)
│   │   ├── panels/                   # Spodné manažérske taby (burza, zákazky, rozvoj)
│   │   ├── office/                   # Obrazovka personálneho oddelenia
│   │   └── dialogs/                  # Modálne dialógy (pomoc, novinky, prepustenie)
│   │
│   └── scenes/                       # Vizuálne scény hál
│       ├── Main.tscn                 # Hlavná riadiaca scéna hry
│       ├── Main.gd                   # Lepidlo medzi simuláciou a rozhraním
│       ├── rooms/                    # Jednotlivé miestnosti
│       │   ├── FoundryHall.tscn      # Taviareň a odlievacia hala
│       │   ├── WarehouseHall.tscn    # Skladová hala a rampa
│       │   ├── WasherHall.tscn       # Pieskovač
│       │   ├── CncHall.tscn          # CNC hala
│       │   └── OfficeRoom.tscn       # Kancelária
│       └── entities/                 # Komponenty v halách
│           ├── CentrifugalMachine.tscn # Odstredivka MK I–III
│           ├── Furnace.tscn          # Tavná pec 01
│           ├── OverheadLadle.tscn    # Pojazdný záves s panvou
│           └── Worker2D.tscn         # Animovaný robotník a majster
│
└── tests/                            # Testovacia sada (parita s Node.js testami)
    ├── RunTests.gd                   # Headless test runner pre CLI
    ├── TestSimulation.gd             # 25 testov behu simulácie
    ├── TestPersonnel.gd              # 18 testov personálneho systému
    ├── TestRejects.gd                # 8 testov nepodarkov a rizík
    ├── TestOperators.gd              # 10 testov obsluhy a paliet
    ├── TestContracts.gd              # 9 testov zákaziek a firiem
    ├── TestWasher.gd                 # 7 testov pieskovača
    ├── TestWeekly.gd                 # 6 testov týždenných miezd a dlhu
    └── TestMigrations.gd             # Testy ukladania a migrácie schém
```

---

## 2. Autoload Singletony

V projekte budú zaregistrované nasledujúce globálne autoloady v `project.godot`:

```ini
[autoload]

EventBus="*res://src/autoload/EventBus.gd"
SimulationClock="*res://src/autoload/SimulationClock.gd"
GameManager="*res://src/autoload/GameManager.gd"
SaveManager="*res://src/autoload/SaveManager.gd"
AudioManager="*res://src/autoload/AudioManager.gd"
```

### EventBus (`res://src/autoload/EventBus.gd`)
Zabezpečuje **voľnú väzbu (loose coupling)** medzi simulačným enginom a používateľským rozhraním na princípe **"Signal Up, Call Down"**:

```gdscript
extends Node

# Signály zmeny stavu simulácie
signal tick_processed(state: Dictionary, delta: float)
signal shift_changed(new_shift: int, crew_name: String)
signal foreman_changed(foreman_index: int, foreman_name: String)
signal day_passed(new_day: int, event_title: String)
signal week_passed(new_week: int)
signal money_changed(new_balance: int, delta: int)

# Signály strojov a výroby
signal machine_state_changed(slot: int, new_state: String)
signal batch_finished(slot: int, product_id: String)
signal reject_occurred(slot: int, product_id: String)
signal material_unloaded_to_pallet(slot: int, product_id: String)

# Signály pieskovača
signal washer_cycle_started(product_id: String)
signal washer_cycle_finished(product_id: String)

# Signály personálu a kancelárie
signal worker_hired(employee: Dictionary)
signal worker_dismissed(employee: Dictionary, severance: int)
signal worker_absent(employee: Dictionary, position_key: String)
signal overtime_called(employee: Dictionary, position_key: String)
signal wages_paid(paid_amount: int, debt_remaining: int)

# Signály obchodu a zákaziek
signal trade_executed(item: String, side: String, quantity: int, total_price: int)
signal contract_accepted(contract_id: String)
signal contract_fulfilled(contract_id: String, reward: int)
signal contract_expired(contract_id: String)

# Signály navigácie
signal room_change_requested(room_name: String)
signal toast_requested(message: String, is_error: bool)
```

---

## 3. Pravidlá pre GDScript 2.0

Všetok kód bude spĺňať striktné pravidlá kvality zo skillu `godot-gdscript-patterns`:
1. **Statické typovanie**: Všetky premenné, parametre a návratové hodnoty funkcií musia mať explicitne deklarovaný typ (`var count: int = 0`, `func get_price() -> int:`).
2. **Bezpečné volania a `class_name`**: Každá entita, model a komponent bude mať `class_name`, čo umožňuje bezpečný `is` checking a autocomplete.
3. **Determinizmus**: Matematika simulácie nepoužíva vstavaný `randf()` enginu, ale implementuje identický LCG generátor ako pôvodný JavaScript (`Math.imul(1664525, seed) + 1013904223`), aby bolo zaručené presné správanie ako v pôvodnej hre.

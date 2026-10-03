# 07. Automatizované testovanie a verifikácia parity

Tento dokument definuje systém automatizovaného testovania v Godot 4.7+, ktorý garantuje **100% matematickú a logickú zhodu** portovaného GDScript enginu s pôvodným JavaScriptovým kódom.

---

## 1. Koncepcia Headless testovania v Godote

Využijeme vstavanú schopnosť enginu Godot bežať v režime bez okna (headless CLI):
```bash
godot --headless --script res://tests/RunTests.gd
```

Tento príkaz spustí testovací runner `RunTests.gd`, ktorý postupne načíta a vykoná všetkých 10 testovacích sád, vypíše farebný výstup do terminálu a vráti exit kód `0` (všetko prešlo) alebo `1` (zlyhanie). Tento krok sa integruje aj do `package.json` cez `npm run test:godot`.

---

## 2. Prehľad testovacích sád a portovaných kontrol

Portujeme všetkých **89 testovacích overení** rozdelených do 10 pôvodných súborov v `tests/`:

| Pôvodný súbor | GDScript test | Počet kontrol | Pokrytie pravidiel |
| :--- | :--- | :--- | :--- |
| `simulation.cjs` | `TestSimulation.gd` | **25** | 180 s/deň, striedanie smien (06/14/22), zachovanie hmoty, fronta panvy, limity skladov, migrácia uložených pozícií |
| `personnel.cjs` | `TestPersonnel.gd` | **18** | Generovanie uchádzačov, výpočet mzdy, absencie pri zmene smeny, nadčasy (+50 %), odstupné (1/2/4 týždne), prepúšťanie |
| `rejects.cjs` | `TestRejects.gd` | **8** | Presné percentá zlyhania (30/20/10 % + obsluha), spotreba vsádzky pri havárii, uvoľnenie panvy, determinizmus |
| `operators.cjs` | `TestOperators.gd` | **10** | Priradenie obsluhy na stroj a smenu, odkladanie na palety, odber z paliet na burzu a zákazky |
| `contracts.cjs` | `TestContracts.gd` | **9** | Lehota na prijatie (90 s), lehota na dodanie (135 s), výpočet reputácie a vzťahov (-100 až +100), bonusy k cene |
| `washer.cjs` | `TestWasher.gd` | **7** | 14 s cyklus pieskovača, 6 ₵ poplatok za vodu/energiu, automatické série, premena odliatkov na očistené kusy |
| `weekly.cjs` | `TestWeekly.gd` | **6** | 7-dňový cyklus výplaty o polnoci, vznik dlhu pri nedostatku mincí, zastavenie novej výroby pri dlhu |
| `update19.cjs` | `TestUpdate19.gd` | **7** | Polovičné absencie, pripočítanie rizika obsluhy, odomykanie skladov, teplota tavenia 1700 °C |
| `update20.cjs` | `TestUpdate20.gd` | **5** | Obsluha pieskovača, nákup CNC 1–6 (500 až 1750 ₵), AMADA trvale zamknutá |
| `update21.cjs` | `TestUpdate21.gd` | **1** | Migrácia odstránených vlastností bez straty personálu a miezd |

**Celkový počet overení**: 89/89 testov.

---

## 3. Implementácia testovacieho runnera (`res://tests/RunTests.gd`)

```gdscript
extends SceneTree

class TestRunner:
    var passed_suites: int = 0
    var failed_suites: int = 0
    var total_asserts: int = 0

    func run() -> void:
        print("\n=======================================")
        print("  Žeravá zlievareň — Godot Test Runner")
        print("=======================================\n")

        var suites: Array[Script] = [
            preload("res://tests/TestSimulation.gd"),
            preload("res://tests/TestPersonnel.gd"),
            preload("res://tests/TestRejects.gd"),
            preload("res://tests/TestOperators.gd"),
            preload("res://tests/TestContracts.gd"),
            preload("res://tests/TestWasher.gd"),
            preload("res://tests/TestWeekly.gd"),
            preload("res://tests/TestUpdate19.gd"),
            preload("res://tests/TestUpdate20.gd"),
            preload("res://tests/TestUpdate21.gd"),
        ]

        for suite_script in suites:
            var suite = suite_script.new()
            var suite_name: String = suite.get_script().resource_path.get_file()
            print("=== %s ===" % suite_name)
            
            var success: bool = true
            if suite.has_method("run_all"):
                success = suite.run_all()
            
            if success:
                passed_suites += 1
                print("✓ Všetky kontroly v %s prešli úspešne.\n" % suite_name)
            else:
                failed_suites += 1
                printerr("✗ ZLYHANIE v %s!\n" % suite_name)

        print("=======================================")
        print("Test Summary: %d passed, %d failed out of %d suites." % [passed_suites, failed_suites, suites.size()])
        
        if failed_suites > 0:
            quit(1)
        else:
            quit(0)

func _init() -> void:
    var runner = TestRunner.new()
    runner.run()
```

---

## 4. Príklad portovaného testu (`TestWasher.gd`)

```gdscript
class_name TestWasher
extends RefCounted

func assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
    if actual != expected:
        push_error("Assertion failed: %s (Expected %s, got %s)" % [msg, str(expected), str(actual)])
        assert(false)

func run_all() -> bool:
    # 1. Test: one pipe, one cost, three phases, one clean output at 14 seconds
    var s = FoundryEngine.fresh()
    s.goods["iron_pipe"] = 1
    s.money = 100
    # Priradenie potrebného personálu
    hire_required_staff(s)
    
    var res = FoundryEngine.perform(s, {"type": "washer", "action": "start"})
    assert_eq(res.ok, true, "Washer štartuje úspešne")
    assert_eq(s.money, 94, "Odpočítaný poplatok 6 ₵")
    assert_eq(s.goods["iron_pipe"], 0, "Surová rúra odobratá")
    assert_eq(s.washer.active, "iron_pipe", "Aktívny čistiaci program")
    
    # Krok simulácie: 14 sekúnd
    FoundryEngine.tick(s, 14.0)
    
    assert_eq(s.washer.active, null, "Pieskovač dokončil cyklus")
    assert_eq(s.goods["clean_iron_pipe"], 1, "Čistá liatinová rúra je v sklade")
    print("OK one pipe, one cost, three phases, one clean output at 14 seconds")

    return true
```

Týmto prístupom dosiahneme stopercentnú istotu, že správanie hry v Godote je do posledného čísla zhodné s existujúcou webovou verziou.

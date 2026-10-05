class_name Constants
extends RefCounted

const SLOTS: int = 6
const DAY: float = 180.0
const WEEK: float = 7.0 * DAY
const QUOTE_INTERVAL: float = 15.0
const EPS: float = 1e-8
const FAILURE_SECONDS: float = 4.0
const UNLOAD_SECONDS: float = 4.0
const OFFER_SECONDS: float = 90.0
const DELIVERY_SECONDS: float = 135.0
const MONTH: float = 4.0 * WEEK

const FLOW: Dictionary = {
	"spinup": 1.6,
	"loadEnd": 3.2,
	"carryEnd": 7.4,
	"pourEnd": 10.2,
	"castEnd": 12.2,
	"returnTime": 3.0
}

const STAGES: Dictionary = {
	"unloading": "Odnášanie na paletu",
	"idle": "Pripravená",
	"spinup": "Roztáčanie",
	"waiting": "Čaká na panvu",
	"loading": "Plnenie panvy",
	"carrying": "Preprava kovu",
	"pouring": "Nalievanie",
	"spinning": "Odlievanie",
	"cooling": "Chladenie vodou",
	"ready": "Hotový výrobok",
	"failed": "Nepodarená rúra",
	"empty": "Voľné miesto"
}

const MATERIALS: Dictionary = {
	"iron": { "name": "Surové železo", "short": "Železo", "base": 4, "color": "#a5b6b4" },
	"steel": { "name": "Oceľová vsádzka", "short": "Oceľ", "base": 7, "color": "#98c8e0" },
	"copper": { "name": "Meď", "short": "Meď", "base": 11, "color": "#e6a171" },
	"tin": { "name": "Cín", "short": "Cín", "base": 15, "color": "#d0d7d5" },
	"zinc": { "name": "Zinok", "short": "Zinok", "base": 3, "color": "#b9cbd8" }
}

const BASE_PRODUCTS: Dictionary = {
	"iron_pipe": {
		"name": "Liatinová rúra",
		"short": "Liatinové rúry",
		"code": "LI",
		"base": 112,
		"recipe": { "iron": 6, "zinc": 1 },
		"seconds": 28,
		"temp": 1700,
		"unlock": 0,
		"color": "#9baea3",
		"size": "Ø 180 × 800 mm",
		"description": "Základný odliatok pre vodárne a stavebníctvo."
	},
	"ring": {
		"name": "Oceľový prstenec",
		"short": "Oceľové prstence",
		"code": "PR",
		"base": 154,
		"recipe": { "steel": 5, "zinc": 1 },
		"seconds": 24,
		"temp": 1700,
		"unlock": 0,
		"color": "#a7cadc",
		"size": "Ø 260 × 90 mm",
		"description": "Krátky dutý odliatok pre strojárstvo."
	},
	"steel_pipe": {
		"name": "Oceľová rúra",
		"short": "Oceľové rúry",
		"code": "OC",
		"base": 196,
		"recipe": { "iron": 5, "steel": 3, "zinc": 2 },
		"seconds": 34,
		"temp": 1700,
		"unlock": 280,
		"color": "#b9d3df",
		"size": "Ø 160 × 1 000 mm",
		"description": "Dlhší výrobný cyklus, vyššia obchodná hodnota."
	},
	"bronze_bushing": {
		"name": "Bronzové puzdro",
		"short": "Bronzové puzdrá",
		"code": "BR",
		"base": 256,
		"recipe": { "copper": 4, "tin": 1, "zinc": 1 },
		"seconds": 26,
		"temp": 1700,
		"unlock": 520,
		"color": "#d7aa66",
		"size": "Ø 120 × 180 mm",
		"description": "Drahšia vsádzka pre puzdrá klzných ložísk."
	}
}

const WASH: Dictionary = {
	"load": 3.0,
	"washEnd": 10.0,
	"total": 14.0,
	"cost": 6,
	"outputs": {
		"iron_pipe": "clean_iron_pipe",
		"steel_pipe": "clean_steel_pipe",
		"ring": "clean_ring",
		"bronze_bushing": "clean_bronze_bushing"
	}
}

static var PRODUCTS: Dictionary = _init_products()

static func _init_products() -> Dictionary:
	var dict: Dictionary = {}
	for k: String in BASE_PRODUCTS.keys():
		dict[k] = BASE_PRODUCTS[k].duplicate(true)
		dict[k]["finished"] = false
	
	for input_id: String in WASH.outputs.keys():
		var out_id: String = WASH.outputs[input_id]
		var p: Dictionary = BASE_PRODUCTS[input_id]
		var prefix: String = "Očistený " if input_id == "ring" else ("Očistené " if input_id == "bronze_bushing" else "Očistená ")
		var base_val: int = int(round(p.base * 1.3)) if input_id.ends_with("_pipe") else int(p.base)
		dict[out_id] = {
			"name": prefix + p.name.to_lower(),
			"short": "Očistené " + p.short.to_lower(),
			"code": p.code + "+",
			"base": base_val,
			"finished": true,
			"source": input_id,
			"color": "#c7e2e8",
			"description": "Výrobok zbavený emulzie v hale Pieskovač.",
			"recipe": p.recipe,
			"seconds": p.seconds,
			"temp": p.temp,
			"unlock": p.unlock,
			"size": p.size
		}
	return dict

const OPERATORS: Array = [
	["Boris", "Dávid", "Emil"],
	["Filip", "Gabriel", "Henrich"],
	["Igor", "Jakub", "Karol"],
	["Lukáš", "Martin", "Norbert"],
	["Oliver", "Patrik", "Radoslav"],
	["Samuel", "Tibor", "Vlado"]
]

const CREWS: Array = [
	{ "name": "Miči", "shift": "Ranná smena", "hours": "06:00 – 14:00", "color": "#c99255", "helmet": "#e9c568" },
	{ "name": "Maslo", "shift": "Poobedná smena", "hours": "14:00 – 22:00", "color": "#648fbb", "helmet": "#d6e2db" },
	{ "name": "Matino", "shift": "Nočná smena", "hours": "22:00 – 06:00", "color": "#839967", "helmet": "#f2b965" }
]

const FURNACE_CREWS: Array = [
	{ "name": "Ivan", "color": "#b67b60", "helmet": "#bfd3d5" },
	{ "name": "Palo", "color": "#6f9d99", "helmet": "#f0c271" },
	{ "name": "Adino", "color": "#8a86aa", "helmet": "#c9dce0" }
]

const WAREHOUSE_CREWS: Array = [
	{ "name": "Roman", "color": "#ae8d42", "helmet": "#edc763" },
	{ "name": "Tomáš", "color": "#588d87", "helmet": "#d6ddd7" },
	{ "name": "Dušan", "color": "#767cb1", "helmet": "#dfc087" }
]

const FOREMEN: Array = [
	{ "name": "Mišo (Majster)", "short": "Mišo", "hours": "06:00 – 18:00", "color": "#17191e", "dayHours": 12, "nightHours": 0 },
	{ "name": "Miro (Majster)", "short": "Miro", "hours": "18:00 – 06:00", "color": "#508dcc", "dayHours": 4, "nightHours": 8 }
]

const WAGES: Dictionary = {
	"ladle": 18,
	"furnace": 14,
	"warehouse": 12,
	"washer": 16,
	"foreman": 20,
	"operator": 16
}

const BIN_BASE: Dictionary = {
	"iron": 60,
	"steel": 40,
	"copper": 30,
	"tin": 20,
	"zinc": 40
}

const BIN_UNLOCK: Dictionary = {
	"iron": 0,
	"zinc": 0,
	"steel": 180,
	"copper": 240,
	"tin": 180
}

const EVENTS: Array = [
	{ "title": "Vyrovnaný trh", "text": "Bežný dopyt. Sleduj rozdiel medzi nákupom a predajom.", "factors": {} },
	{ "title": "Stavebná sezóna", "text": "Stavby zvyšujú dopyt po liatinových a oceľových rúrach.", "factors": { "iron_pipe": 0.22, "steel_pipe": 0.18 } },
	{ "title": "Obmedzené dodávky zinku", "text": "Zinok je dnes drahší. Skontroluj náklady na vsádzku.", "factors": { "zinc": 0.35 } },
	{ "title": "Dopyt po ložiskách", "text": "Výrobcovia strojov hľadajú bronzové puzdrá.", "factors": { "bronze_bushing": 0.26, "copper": 0.1 } },
	{ "title": "Slabší priemyselný odbyt", "text": "Ceny prstencov a oceľových rúr klesajú.", "factors": { "ring": -0.19, "steel_pipe": -0.14 } }
]

const GOALS: Array = [
	{ "id": "sales", "name": "Prvých 12 predaných výrobkov", "target": 12, "reward": 350, "field": "sold" },
	{ "id": "contracts", "name": "Splň 3 zákazky", "target": 3, "reward": 450, "field": "completedContracts" },
	{ "id": "machines", "name": "Rozbehni 4 odstredivky", "target": 4, "reward": 500 },
	{ "id": "turnover", "name": "Dosiahni tržby 5 000 ₵", "target": 5000, "reward": 800, "field": "revenue" },
	{ "id": "output", "name": "Vyrob 60 odliatkov", "target": 60, "reward": 1000, "field": "made" }
]

const COMPANIES: Array = [
	"Mestské vodárne",
	"Strojárne Hron",
	"Severné stavby",
	"Ložiská Tatry",
	"Nový odberateľ"
]

const JOBS: Dictionary = {
	"ladle": "Panvár",
	"furnace": "Tavič",
	"warehouse": "Skladník",
	"washer": "Obsluha pieskovača",
	"operator": "Obsluha odstredivky",
	"foreman": "Majster"
}

const CANDIDATE_NAMES: Array = [
	"Andrej", "Daniel", "Erik", "František", "Gabo",
	"Henrich", "Juraj", "Karol", "Lukáš", "Marcel",
	"Norbert", "Ondrej", "Patrik", "Radoslav", "Stanislav",
	"Tomáš", "Vladimír", "Zdeno", "Štefan", "Milan"
]

const CANDIDATE_SURNAMES: Array = [
	"Kováč", "Tóth", "Varga", "Horváth", "Novák",
	"Bartoš", "Kozák", "Vojtek", "Koleno", "Majtán",
	"Zvak", "Šimko", "Hruška", "Polák", "Krajčír",
	"Švec", "Kováčik", "Belička", "Urban", "Lacko",
	"Mikuš", "Hudec", "Černák", "Sýkora", "Moravčík",
	"Baláž", "Kmeť", "Kučera"
]

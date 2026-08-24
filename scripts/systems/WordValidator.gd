extends Node

## WordValidator.gd - Dictionary validation, letter scoring, and elemental categorization

signal word_validated(word: String, is_valid: bool, category: String, score: int)

# Special / Rare letters that give bonus points and effects
const RARE_LETTERS: Array[String] = ["Q", "X", "Z", "J", "K", "V"]

# Themed Elemental Word Categories
const ELEMENTAL_CATEGORIES: Dictionary = {
	"NATURE": [
		"TREE", "TREES", "LEAF", "LEAVES", "ROOT", "ROOTS", "VINE", "VINES",
		"FOREST", "FORESTS", "PLANT", "PLANTS", "SEED", "SEEDS", "BRANCH", "BRANCHES",
		"BARK", "FLOWER", "FLOWERS", "MOSS", "JUNGLE", "JUNGLES", "WOOD", "WOODS",
		"PALM", "PALMS", "FERN", "FERNS", "HERB", "HERBS", "SHRUB", "SHRUBS",
		"GROVE", "GROVES", "BUSH", "BUSHES", "FLORA", "STEM", "STEMS", "BLOOM",
		"BLOOMS", "GRASS", "GRASSES", "GREEN", "SPROUT", "SPROUTS", "NATURE", "CANOPY",
		"TIMBER", "TWIG", "TWIGS", "FOLIAGE", "WILD", "BAMBOO", "SWAMP", "SWAMPS",
		"PETAL", "PETALS", "ORCHID", "SAP", "BUD", "BUDS", "FRUIT", "FRUITS", "VINES"
	],
	"WATER": [
		"RAIN", "RAINS", "WAVE", "WAVES", "RIVER", "RIVERS", "OCEAN", "OCEANS",
		"TIDE", "TIDES", "STREAM", "STREAMS", "LAKE", "LAKES", "CORAL", "CORALS",
		"SPRAY", "SPRAYS", "DROP", "DROPS", "FLOW", "FLOWS", "SURF", "SURFS",
		"SEA", "SEAS", "FLOOD", "FLOODS", "AQUA", "FOAM", "FOAMS", "SPLASH",
		"REEF", "REEFS", "POND", "PONDS", "WATER", "WATERS", "CURRENT", "CURRENTS",
		"MIST", "MISTS", "DEW", "SPRING", "SPRINGS", "CREEK", "CREEKS", "LAGOON",
		"SHORE", "SHORES", "COAST", "COASTS", "DOCK", "DOCKS", "BAY", "BAYS", "ISLE"
	],
	"FIRE": [
		"FIRE", "FIRES", "FLAME", "FLAMES", "BURN", "BURNS", "EMBER", "EMBERS",
		"ASH", "ASHES", "HEAT", "HEATS", "BLAZE", "BLAZES", "SPARK", "SPARKS",
		"GLOW", "GLOWS", "INFERNO", "TORCH", "TORCHES", "COAL", "COALS", "FLARE",
		"FLARES", "PYRE", "PYRES", "SMOKE", "SMOKES", "WARM", "WARMS", "LAVA",
		"VOLCANO", "IGNITE", "CHAR", "CHARS", "SEAR", "SEARS", "FURNACE", "SUN",
		"SUNS", "SOLAR", "BOIL", "BOILS", "SCORCH", "KINDLE", "BLAST", "BLASTS"
	],
	"ANCIENT": [
		"RUIN", "RUINS", "STONE", "STONES", "TEMPLE", "TEMPLES", "RELIC", "RELICS",
		"SHRINE", "SHRINES", "RUNE", "RUNES", "ALTAR", "ALTARS", "IDOL", "IDOLS",
		"MYTH", "MYTHS", "TOMB", "TOMBS", "ROCK", "ROCKS", "MONOLITH", "VAULT",
		"VAULTS", "ARTIFACT", "ARTIFACTS", "GLYPH", "GLYPHS", "TOTEM", "TOTEMS",
		"ANCIENT", "PILLAR", "PILLARS", "MAGIC", "MAGICS", "CRYSTAL", "CRYSTALS",
		"ORB", "ORBS", "ARCANE", "MYSTIC", "ELDER", "ELDERS", "SECRET", "SECRETS",
		"HERITAGE", "PEARL", "PEARLS", "SACRED", "STATUE", "STATUES", "GOLD", "TREASURE"
	],
	"WIND": [
		"WIND", "WINDS", "GUST", "GUSTS", "BREEZE", "BREEZES", "STORM", "STORMS",
		"GALE", "GALES", "AIR", "AIRS", "DRAFT", "DRAFTS", "BLOW", "BLOWS",
		"WHIRL", "WHIRLS", "ZEPHYR", "CYCLONE", "CYCLONES", "TYPHOON", "TYPHOONS",
		"FLIGHT", "FLY", "WING", "WINGS", "SOAR", "SOARS", "DRIFT", "DRIFTS",
		"FLOAT", "FLOATS", "HOWL", "HOWLS", "SWIFT", "SWIFTLY", "TEMPEST"
	]
}

# Letter distribution frequency weights for natural, balanced word creation
const LETTER_FREQUENCIES: Dictionary = {
	"E": 12, "A": 10, "I": 9, "O": 8, "N": 7, "R": 7, "T": 7, "L": 6,
	"S": 6, "U": 6, "D": 5, "G": 4, "B": 3, "C": 3, "M": 3, "P": 3,
	"F": 2, "H": 2, "V": 2, "W": 2, "Y": 2, "K": 1, "J": 1, "X": 1,
	"Q": 1, "Z": 1
}

# Letter score table
const LETTER_SCORES: Dictionary = {
	"A": 1, "B": 3, "C": 3, "D": 2, "E": 1, "F": 4, "G": 2, "H": 4,
	"I": 1, "J": 8, "K": 5, "L": 1, "M": 3, "N": 1, "O": 1, "P": 3,
	"Q": 10, "R": 1, "S": 1, "T": 1, "U": 1, "V": 4, "W": 4, "X": 8,
	"Y": 4, "Z": 10
}

# Fast Hash Set of valid words
var _dictionary: Dictionary = {}
var _is_loaded: bool = false

func _ready() -> void:
	_load_dictionary()

func _load_dictionary() -> void:
	if _is_loaded:
		return
	
	# Load base common English dictionary words + elemental words
	var word_list: PackedStringArray = _get_embedded_lexicon()
	for w in word_list:
		var clean: String = w.strip_edges().to_upper()
		if clean.length() >= 2:
			_dictionary[clean] = true
	
	# Also ensure all category words are explicitly in the dictionary
	for cat in ELEMENTAL_CATEGORIES:
		for w in ELEMENTAL_CATEGORIES[cat]:
			_dictionary[w.to_upper()] = true
			
	_is_loaded = true
	print("[WordValidator] Lexicon loaded with %d words." % _dictionary.size())

func is_valid_word(word: String) -> bool:
	var clean: String = word.strip_edges().to_upper()
	if clean.length() < 2:
		return false
	return _dictionary.has(clean)

func get_word_category(word: String) -> String:
	var clean: String = word.strip_edges().to_upper()
	for cat in ELEMENTAL_CATEGORIES:
		if ELEMENTAL_CATEGORIES[cat].has(clean):
			return cat
	return "NONE"

func get_word_score(word: String) -> int:
	var clean: String = word.strip_edges().to_upper()
	var score: int = 0
	for i in range(clean.length()):
		var char_letter: String = clean.substr(i, 1)
		score += LETTER_SCORES.get(char_letter, 1)
	return score

func get_rare_letter_count(word: String) -> int:
	var clean: String = word.strip_edges().to_upper()
	var count: int = 0
	for i in range(clean.length()):
		var char_letter: String = clean.substr(i, 1)
		if RARE_LETTERS.has(char_letter):
			count += 1
	return count

func generate_letter_pool(count: int = 16) -> Array[String]:
	var vowels: Array[String] = ["A", "E", "I", "O", "U"]
	var pool: Array[String] = []
	
	# Ensure at least 4-5 vowels for high playability
	var vowel_count: int = int(round(count * 0.35))
	for i in range(vowel_count):
		pool.append(vowels[randi() % vowels.size()])
		
	# Build weighted consonant list
	var weighted_letters: Array[String] = []
	for letter in LETTER_FREQUENCIES:
		var weight: int = LETTER_FREQUENCIES[letter]
		for w in range(weight):
			weighted_letters.append(letter)
			
	while pool.size() < count:
		var letter: String = weighted_letters[randi() % weighted_letters.size()]
		pool.append(letter)
		
	pool.shuffle()
	return pool

func _get_embedded_lexicon() -> PackedStringArray:
	# Rich vocabulary containing high-frequency words, adventure terms, nature, animals, and gameplay nouns/verbs
	var words: PackedStringArray = [
		# Short / 2-letter
		"AM", "AN", "AS", "AT", "BE", "BY", "DO", "GO", "HE", "HI", "IF", "IN", "IS", "IT", "ME", "MY", "NO", "OF", "OK", "ON", "OR", "SO", "TO", "UP", "US", "WE",
		# 3-letter
		"ACT", "ADD", "AGE", "AGO", "AID", "AIM", "AIR", "ALE", "ALL", "AND", "ANT", "ANY", "APE", "APT", "ARC", "ARK", "ARM", "ART", "ASH", "ASK", "ATE", "AWE", "AXE",
		"BAD", "BAG", "BAN", "BAR", "BAT", "BAY", "BED", "BEE", "BEG", "BET", "BID", "BIG", "BIN", "BIT", "BOA", "BOG", "BOW", "BOX", "BOY", "BUD", "BUG", "BUS", "BUT", "BUY",
		"CAB", "CAN", "CAP", "CAR", "CAT", "COW", "CRY", "CUP", "CUT",
		"DAM", "DAY", "DEN", "DEW", "DID", "DIE", "DIG", "DIM", "DIP", "DOG", "DOT", "DRY", "DUE", "DUG",
		"EAR", "EAT", "EGG", "EGO", "ELK", "ELM", "END", "EON", "ERA", "EYE",
		"FAN", "FAR", "FAT", "FEW", "FIG", "FIN", "FIR", "FIT", "FIX", "FLY", "FOG", "FOR", "FOX", "FRY", "FUN", "FUR",
		"GAP", "GAS", "GEL", "GEM", "GET", "GIG", "GIN", "GLO", "GNU", "GOD", "GOT", "GUM", "GUN", "GUT", "GUY", "GYM",
		"HAD", "HAM", "HAS", "HAT", "HAY", "HEM", "HEN", "HER", "HEX", "HID", "HIM", "HIP", "HIS", "HIT", "HOG", "HOP", "HOT", "HOW", "HUB", "HUE", "HUG", "HUM", "HUT",
		"ICE", "ICY", "ILL", "IMP", "INK", "INN", "ION", "IRE", "IVY",
		"JAB", "JAM", "JAR", "JAW", "JAY", "JET", "JIG", "JOB", "JOG", "JOY", "JUG", "JUT",
		"KEG", "KEY", "KID", "KIN", "KIT",
		"LAB", "LAD", "LAG", "LAP", "LAW", "LAY", "LED", "LEG", "LET", "LID", "LIE", "LIP", "LIT", "LOG", "LOT", "LOW",
		"MAD", "MAN", "MAP", "MAT", "MAY", "MEN", "MET", "MUD", "MUG",
		"NAG", "NAP", "NET", "NEW", "NIP", "NOD", "NOT", "NOW", "NUT",
		"OAK", "OAR", "OAT", "ODD", "OFF", "OIL", "OLD", "ONE", "OPT", "ORB", "ORE", "OUR", "OUT", "OWL", "OWN",
		"PAD", "PAN", "PAT", "PAY", "PEA", "PEG", "PEN", "PET", "PIE", "PIG", "PIN", "PIT", "PLY", "POD", "POP", "POT",
		"RAG", "RAM", "RAN", "RAP", "RAT", "RAW", "RAY", "RED", "RIB", "RID", "RIM", "RIP", "ROB", "ROD", "ROW", "RUB", "RUG", "RUN", "RUT", "RYE",
		"SAD", "SAG", "SAP", "SAT", "SAW", "SAY", "SEA", "SEE", "SET", "SEW", "SHY", "SIN", "SIP", "SIR", "SIT", "SIX", "SKI", "SKY", "SLY", "SOB", "SOD", "SON", "SOW", "SPY", "SUM", "SUN",
		"TAB", "TAG", "TAN", "TAP", "TAR", "TEA", "TEN", "TIE", "TIN", "TIP", "TOE", "TOP", "TOW", "TOY", "TRY", "TUB", "TUG", "TWO",
		"URN", "USE",
		"VAN", "VAT", "VET", "VIA", "VOW",
		"WAR", "WAS", "WAY", "WEB", "WET", "WHO", "WHY", "WIG", "WIN", "WIT", "WOE", "WON", "WOW",
		"YAK", "YAM", "YAP", "YEA", "YES", "YET", "YOU",
		"ZAP", "ZEN", "ZIP", "ZOO",

		# 4-letter
		"ACID", "AGED", "AIDE", "AIDS", "AIRS", "ALLY", "ALMS", "ALTO", "ARCH", "AREA", "ARMY", "ARTS", "AUNT", "AURA", "AUTO", "AXES",
		"BABY", "BACK", "BAIT", "BAKE", "BALD", "BALL", "BAND", "BANE", "BANK", "BARE", "BARK", "BARN", "BASE", "BASS", "BATH", "BEAK", "BEAM", "BEAN", "BEAR", "BEAT", "BEEF", "BEEN", "BEER", "BELL", "BELT", "BEND", "BENT", "BEST", "BETA", "BIKE", "BILL", "BIND", "BIRD", "BITE", "BLOW", "BLUE", "BOAR", "BOAT", "BODY", "BOIL", "BOLD", "BOLT", "BOMB", "BOND", "BONE", "BOOK", "BOOM", "BOOT", "BORE", "BORN", "BOSS", "BOTH", "BOWL", "BRAG", "BRED", "BREW", "BRIM", "BULL", "BUMP", "BURN", "BURY", "BUSH", "BUSY", "BUZZ",
		"CAFE", "CAGE", "CAKE", "CALL", "CALM", "CAMP", "CANE", "CAPE", "CARD", "CARE", "CART", "CASE", "CASH", "CAST", "CAVE", "CHEF", "CHIN", "CHIP", "CHOP", "CLAP", "CLAW", "CLAY", "CLIP", "CLUB", "COAL", "COAT", "COCK", "CODE", "COIL", "COIN", "COLD", "COLT", "COMB", "COME", "COOK", "COOL", "COPE", "CORD", "CORE", "CORK", "CORN", "COST", "COVE", "CRAB", "CRAG", "CRAM", "CREW", "CROP", "CROW", "CURE", "CURL",
		"DARE", "DARK", "DART", "DASH", "DATE", "DAWN", "DAYS", "DEAD", "DEAF", "DEAL", "DEAR", "DECK", "DEED", "DEEP", "DEER", "DEMO", "DESK", "DIAL", "DICE", "DIET", "DINT", "DIRT", "DISC", "DISH", "DISK", "DIVE", "DOCK", "DOME", "DONE", "DOOR", "DOSE", "DOVE", "DOWN", "DRAG", "DRAW", "DREW", "DRIP", "DROP", "DRUG", "DRUM", "DUAL", "DUCK", "DUDE", "DUST", "DUTY",
		"EACH", "EARN", "EASE", "EAST", "EASY", "ECHO", "EDGE", "ELSE", "EMIT", "EPIC", "EVEN", "EVER", "EVIL", "EXAM", "EXIT",
		"FACE", "FACT", "FADE", "FAIL", "FAIR", "FALL", "FAME", "FANG", "FARM", "FAST", "FATE", "FEAR", "FEAT", "FEED", "FEEL", "FELL", "FELT", "FERN", "FEUD", "FILE", "FILL", "FILM", "FIND", "FINE", "FIRE", "FIRM", "FISH", "FIST", "FIVE", "FLAG", "FLAP", "FLAT", "FLAW", "FLED", "FLEE", "FLEW", "FLEX", "FLIP", "FLOW", "FOAM", "FOIL", "FOLD", "FOLK", "FOND", "FONT", "FOOD", "FOOL", "FOOT", "FORD", "FORK", "FORM", "FORT", "FOUL", "FOUR", "FOWL", "FREE", "FROG", "FROM", "FUEL", "FULL", "FUME", "FUND", "FURY", "FUSE",
		"GAIN", "GALE", "GAME", "GANG", "GATE", "GAVE", "GEAR", "GIFT", "GILD", "GILL", "GIRL", "GIVE", "GLAD", "GLEN", "GLOW", "GOAL", "GOAT", "GOLD", "GOLF", "GONE", "GOOD", "GRAB", "GROW", "GULF", "GULL", "GUST",
		"HAIL", "HAIR", "HALF", "HALL", "HALT", "HAND", "HANG", "HARD", "HARE", "HARM", "HATE", "HAVE", "HAWK", "HAZE", "HEAD", "HEAL", "HEAP", "HEAR", "HEAT", "HEED", "HEEL", "HELD", "HELM", "HELP", "HERB", "HERD", "HERO", "HIDE", "HIGH", "HIKE", "HILL", "HINT", "HIRE", "HIVE", "HOLD", "HOLE", "HOLY", "HOME", "HOOD", "HOOK", "HOPE", "HORN", "HOSE", "HOST", "HOUR", "HOWL", "HUGE", "HUNT", "HURT", "HYMN",
		"ICON", "IDEA", "IDLE", "IDOL", "INCH", "INFO", "INTO", "IRON", "ISLE", "ITEM",
		"JADE", "JAIL", "JAZZ", "JEAN", "JEEP", "JOIN", "JOKE", "JOLT", "JUMP", "JUNE", "JURY", "JUST", "JUTE",
		"KEEN", "KEEP", "KELP", "KEPT", "KICK", "KILL", "KILN", "KIND", "KING", "KISS", "KITE", "KNEE", "KNOT", "KNOW",
		"LACE", "LACK", "LAKE", "LAMB", "LAMP", "LAND", "LANE", "LAST", "LATE", "LAVA", "LAWN", "LEAD", "LEAF", "LEAK", "LEAN", "LEAP", "LEFT", "LEND", "LENS", "LENT", "LESS", "LIFT", "LIKE", "LIME", "LIMB", "LINE", "LINK", "LION", "LIPS", "LIVE", "LOAD", "LOAF", "LOAM", "LOAN", "LOCK", "LONE", "LONG", "LOOK", "LOOM", "LOOP", "LORD", "LORE", "LOSE", "LOSS", "LOST", "LOUD", "LOVE", "LUCK", "LUMP", "LUNG", "LURE", "LURK", "LUSH", "LUTE",
		"MADE", "MAGE", "MAID", "MAIL", "MAIN", "MAKE", "MALE", "MALL", "MANE", "MANY", "MAPS", "MARK", "MARS", "MARV", "MASK", "MASS", "MAST", "MATE", "MATH", "MAZE", "MEAL", "MEAN", "MEAT", "MEET", "MELT", "MEND", "MENU", "MESA", "MESH", "MESS", "MILD", "MILE", "MILK", "MILL", "MIND", "MINE", "MINT", "MISS", "MIST", "MOAT", "MOCK", "MODE", "MOLD", "MOLE", "MONK", "MOOD", "MOON", "MOOR", "MOSS", "MOST", "MOTH", "MOVE", "MUCH", "MULE", "MUST", "MUTE", "MYTH",
		"NAIL", "NAME", "NEAR", "NEAT", "NECK", "NEED", "NEST", "NEWS", "NEXT", "NICE", "NINE", "NODE", "NOON", "NORM", "NOSE", "NOTE", "NOVA",
		"OAKS", "OARS", "OATH", "OBEY", "ODOR", "OGRE", "OILS", "OILY", "OKRA", "OMEN", "ONCE", "ONLY", "ONTO", "OPAL", "OPEN", "ORAL", "ORBS", "ORES", "OVAL", "OVEN", "OVER", "OWED", "OWLS",
		"PACE", "PACK", "PACT", "PAGE", "PAID", "PAIN", "PAIR", "PALE", "PALM", "PANE", "PARK", "PART", "PASS", "PAST", "PATH", "PEAK", "PEAL", "PEAR", "PEAT", "PEEK", "PEEL", "PEER", "PELT", "PIER", "PIKE", "PILE", "PILL", "PINE", "PINK", "PINT", "PIPE", "PITY", "PLAN", "PLAY", "PLEA", "PLOT", "PLOW", "PLUG", "PLUM", "POEM", "POET", "POKE", "POLE", "POLL", "POND", "POOL", "POOR", "PORK", "PORT", "POSE", "POST", "POUR", "PRAY", "PREY", "PROD", "PROP", "PROW", "PUFF", "PULL", "PULP", "PUMP", "PURE", "PUSH",
		"QUAD", "QUAY", "QUIT", "QUIZ",
		"RACE", "RAFT", "RAGE", "RAID", "RAIL", "RAIN", "RAKE", "RAMP", "RANG", "RANK", "RARE", "RASH", "RATE", "RAVE", "RAYS", "READ", "REAL", "REAP", "REAR", "REED", "REEF", "REEL", "RELY", "RENT", "REST", "RICE", "RICH", "RIDE", "RIFE", "RIFT", "RING", "RINK", "RIOT", "RIPE", "RISE", "RISK", "RITE", "ROAD", "ROAM", "ROAR", "ROBE", "ROCH", "ROCK", "RODE", "ROLE", "ROLL", "ROOF", "ROOK", "ROOM", "ROOT", "ROPE", "ROSE", "ROTE", "ROVE", "RUBY", "RUIN", "RULE", "RUSH", "RUST",
		"SACK", "SAFE", "SAGE", "SAID", "SAIL", "SAKE", "SALT", "SAME", "SAND", "SANE", "SANG", "SANK", "SAVE", "SCAN", "SCAR", "SEAL", "SEAM", "SEAS", "SEAT", "SEED", "SEEK", "SEEM", "SEEN", "SELF", "SELL", "SEND", "SENT", "SHED", "SHIN", "SHIP", "SHOE", "SHOP", "SHOT", "SHOW", "SHUT", "SICK", "SIDE", "SIGH", "SIGN", "SILK", "SILT", "SINK", "SITE", "SIZE", "SKIN", "SKIP", "SKIT", "SLAB", "SLAM", "SLAP", "SLID", "SLIM", "SLIP", "SLIT", "SLOT", "SLOW", "SNAP", "SNOW", "SOAK", "SOAP", "SOAR", "SOCK", "SOFA", "SOIL", "SOLD", "SOLE", "SOLO", "SOME", "SONG", "SOON", "SOOT", "SORE", "SOUL", "SOUP", "SOUR", "SPAN", "SPAR", "SPEC", "SPED", "SPIN", "SPIT", "SPOT", "SPUR", "STAB", "STAR", "STAY", "STEM", "STEP", "STEW", "STIR", "STOP", "SUCH", "SUIT", "SULK", "SUNG", "SUNK", "SURE", "SURF", "SWAN", "SWAP", "SWAY", "SWIM",
		"TALE", "TALK", "TALL", "TAME", "TANK", "TAPE", "TASK", "TEAM", "TEAR", "TELL", "TENT", "TERM", "TEST", "TEXT", "THAN", "THAT", "THAW", "THEM", "THEN", "THEY", "THIN", "THIS", "THOU", "THUD", "TICK", "TIDE", "TIDY", "TIED", "TIER", "TILE", "TILL", "TILT", "TIME", "TINT", "TINY", "TIRE", "TOAD", "TOIL", "TOLL", "TOMB", "TONE", "TOOK", "TOOL", "TOOT", "TOPS", "TORE", "TORN", "TOSS", "TOUR", "TOWN", "TRAP", "TREE", "TREK", "TRIM", "TRIP", "TRUE", "TUBE", "TUCK", "TUFT", "TUNA", "TUNE", "TURF", "TURN", "TUSK", "TWIG", "TWIN", "TYPE",
		"UNIT", "UPON", "URGE", "USED", "USER",
		"VAIN", "VALE", "VANE", "VARY", "VAST", "VEIL", "VEIN", "VENT", "VERB", "VERY", "VEST", "VIAL", "VIEW", "VINE", "VOID", "VOLT", "VOTE",
		"WADE", "WAGE", "WAIT", "WAKE", "WALK", "WALL", "WAND", "WANT", "WARD", "WARM", "WARN", "WARP", "WARS", "WASH", "WASP", "WAVE", "WAVY", "WAYS", "WEAK", "WEAR", "WEED", "WEEK", "WEEP", "WELL", "WENT", "WEPT", "WEST", "WHAT", "WHEN", "WHIP", "WIDE", "WIFE", "WILD", "WILL", "WIND", "WING", "WINK", "WIPE", "WIRE", "WISE", "WISH", "WITH", "WOLF", "WOOD", "WOOL", "WORD", "WORE", "WORK", "WORM", "WORN", "WRAP", "WREN",
		"YARD", "YARN", "YEAR", "YELL", "YOGA", "YOKE", "YOUR",
		"ZEAL", "ZERO", "ZINC", "ZONE",

		# 5-letter
		"ABOVE", "ACORN", "ACTOR", "ADAPT", "ADEPT", "ADOBE", "ADOPT", "AGILE", "AGREE", "AHEAD", "ALARM", "ALBUM", "ALERT", "ALIEN", "ALIVE", "ALLEY", "ALLOW", "ALONG", "ALOUD", "ALPHA", "ALTAR", "ALTER", "AMBER", "AMBLE", "AMEND", "AMONG", "AMPLE", "ANGEL", "ANGER", "ANGLE", "ANGRY", "ANKLE", "APPLE", "APPLY", "APRON", "ARENA", "ARMOR", "ARROW", "ASCOT", "ASHES", "ASIDE", "AUDIO", "AUDIT", "AVOID", "AWAIT", "AWAKE", "AWARD", "AWARE",
		"BADGE", "BAGEL", "BAKER", "BASIC", "BASIN", "BATCH", "BATON", "BEACH", "BEAST", "BEGIN", "BEING", "BELOW", "BENCH", "BERRY", "BIRCH", "BIRTH", "BLACK", "BLADE", "BLAZE", "BLEED", "BLEND", "BLESS", "BLIND", "BLINK", "BLOCK", "BLOOD", "BLOOM", "BLOWN", "BLUFF", "BOARD", "BOAST", "BONUS", "BOOST", "BOUND", "BOWER", "BRAID", "BRAIN", "BRAKE", "BRAND", "BRASS", "BRAVE", "BREAD", "BREAK", "BREED", "BRIAR", "BRICK", "BRIDE", "BRIEF", "BRING", "BRISK", "BROAD", "BROOK", "BROOM", "BROTH", "BROWN", "BRUNT", "BRUSH", "BUDDY", "BUILD", "BUILT", "BUNCH", "BURST",
		"CABIN", "CABLE", "CAMEL", "CANAL", "CANDY", "CANOE", "CARVE", "CATCH", "CAUSE", "CEDAR", "CHAIN", "CHAIR", "CHALK", "CHAMP", "CHANT", "CHAOS", "CHARM", "CHART", "CHASE", "CHEAP", "CHECK", "CHEEK", "CHEEP", "CHEER", "CHEST", "CHIEF", "CHILD", "CHILL", "CHIME", "CHIRP", "CHOIR", "CHOKE", "CHORE", "CHUCK", "CHUNK", "CHUTE", "CIDER", "CIVIL", "CLAIM", "CLANG", "CLASH", "CLASP", "CLASS", "CLEAN", "CLEAR", "CLEAT", "CLEVER", "CLIFF", "CLIMB", "CLING", "CLOAK", "CLOCK", "CLONE", "CLOSE", "CLOTH", "CLOUD", "CLOVE", "CLOWN", "CLUMP", "COACH", "COAST", "COBRA", "CORAL", "COUNT", "COURT", "COVER", "CRACK", "CRAFT", "CRANE", "CRASH", "CRATE", "CRAWL", "CRAZE", "CREAK", "CREAM", "CREEK", "CREEP", "CREST", "CRISP", "CROOK", "CROSS", "CROWD", "CROWN", "CRUDE", "CRUSH", "CRUST", "CRYPT", "CUBIC", "CUPID", "CURSE", "CURVE",
		"DAILY", "DAISY", "DANCE", "DREAM", "DRIFT", "DRILL", "DRINK", "DRIVE", "DENSE", "DEPTH", "DEVIL", "DIARY", "DINER", "DIRTY", "DITCH", "DIVER", "DODGE", "DRAFT", "DRAKE", "DRAMA", "DRANK", "DREAD", "DRESS", "DRIER", "DRONE", "DROOL", "DROOP", "DROSS", "DROVE", "DROWN", "DRUID", "DUSKY", "DWARF",
		"EAGER", "EAGLE", "EARTH", "EASLE", "EBONY", "ECHOES", "ELBOW", "ELDER", "EMBER", "EMPTY", "ENACT", "ENEMY", "ENJOY", "ENTER", "ENTRY", "EQUAL", "EQUIP", "ERODE", "ERROR", "EVENT", "EVERY", "EXACT", "EXERT", "EXILE", "EXIST", "EXTRA",
		"FABLE", "FACET", "FAINT", "FAITH", "FALSE", "FANCY", "FEAST", "FIBER", "FIELD", "FIEND", "FIERY", "FIFTH", "FIGHT", "FINAL", "FINCH", "FIRST", "FLAIR", "FLAKE", "FLAME", "FLANK", "FLARE", "FLASH", "FLASK", "FLEET", "FLESH", "FLING", "FLINT", "FLOAT", "FLOCK", "FLOOD", "FLOOR", "FLORA", "FLOUR", "FLUTE", "FOCUS", "FOGGY", "FORCE", "FORGE", "FORTH", "FOUND", "FRAME", "FRANK", "FRESH", "FRIAR", "FRIED", "FROST", "FROTH", "FROWN", "FRUIT",
		"GALLE", "GEARS", "GECKO", "GHOST", "GIANT", "GIRTH", "GLADE", "GLAND", "GLARE", "GLASS", "GLAZE", "GLEAM", "GLIDE", "GLINT", "GLOOM", "GLORY", "GLOVE", "GNOME", "GOING", "GOLEM", "GOOSE", "GORGE", "GRACE", "GRADE", "GRAIN", "GRAND", "GRANT", "GRAPE", "GRASP", "GRASS", "GRAVE", "GREAT", "GREED", "GREEK", "GREEN", "GREET", "GRIEF", "GRILL", "GRIND", "GROVE", "GROWL", "GUARD", "GUEST", "GUIDE", "GUILD", "GULLY",
		"HABIT", "HASTE", "HATCH", "HAVEN", "HAVOC", "HAZEL", "HEART", "HEAVY", "HEDGE", "HEIST", "HELLO", "HELMET", "HERON", "HIKER", "HONEY", "HORSE", "HOUND", "HOUSE", "HOVER", "HUMAN", "HUMID", "HUNTER", "HYDRO",
		"IMAGE", "INCUR", "INDEX", "INERT", "INFER", "INGOT", "INLET", "INNER", "INPUT", "IVORY",
		"JADED", "JEWEL", "JOINT", "JOKER", "JUDGE", "JUICE", "JUMBO", "JUNGLE",
		"KAYAK", "KEEPER", "KNEEL", "KNIFE", "KNIGHT", "KNOCK",
		"LABEL", "LABOR", "LANCE", "LARGE", "LASER", "LATCH", "LAYER", "LEADER", "LEMON", "LEVEL", "LEVER", "LIGHT", "LILAC", "LIMIT", "LINEN", "LODGE", "LOGIC", "LUNAR",
		"MAGIC", "MAGMA", "MAJOR", "MANOR", "MAPLE", "MARCH", "MARSH", "MATCH", "MEDAL", "MELON", "MERCY", "MERIT", "METAL", "MIGHT", "MINER", "MINOR", "MIRTH", "MODEL", "MOIST", "MONEY", "MONTH", "MORAL", "MOTIF", "MOTOR", "MOUNT", "MOUSE", "MOUTH", "MUSIC", "MYSTIC",
		"NIGHT", "NOBLE", "NORTH", "NOTCH", "NOVEL",
		"OASIS", "OCEAN", "OCTET", "ONION", "OPERA", "ORBIT", "ORCHID", "ORDER", "OTHER", "OUTER", "OZONE",
		"PAGAN", "PANIC", "PANEL", "PAPER", "PARCH", "PATCH", "PEACE", "PEACH", "PEARL", "PETAL", "PHASE", "PIANO", "PILOT", "PITCH", "PIVOT", "PIXEL", "PLACE", "PLAIN", "PLANK", "PLANT", "PLATE", "PLAZA", "PLUME", "POINT", "POLAR", "POPPY", "POWER", "PRIDE", "PRIME", "PRIZE", "PROUD", "PULSE", "PUPIL", "PURSE",
		"QUEEN", "QUEST", "QUICK", "QUIET", "QUOTA",
		"RABBIT", "RADAR", "RADIO", "RAVEN", "REALM", "REBEL", "RECON", "RELAX", "RELIC", "RIDER", "RIDGE", "RIVER", "ROBOT", "ROCKY", "ROUND", "ROYAL", "RUBLE", "RULER", "RUMOR", "RUSTY",
		"SABER", "SAILOR", "SALON", "SANDY", "SATIN", "SCALE", "SCALP", "SCARE", "SCARF", "SCENE", "SCENT", "SCOOP", "SCORE", "SCOUT", "SCRAP", "SCREW", "SERUM", "SHACK", "SHADE", "SHADOW", "SHAFT", "SHAKE", "SHARD", "SHARE", "SHARK", "SHARP", "SHEET", "SHELF", "SHELL", "SHIFT", "SHINE", "SHORE", "SHRUB", "SIGHT", "SILVER", "SIREN", "SKILL", "SKULL", "SLASH", "SLATE", "SMART", "SMOKE", "SNAKE", "SOLAR", "SONAR", "SOUND", "SOUTH", "SPACE", "SPARK", "SPEAR", "SPELL", "SPICE", "SPIKE", "SPINE", "SPIRIT", "SPLIT", "SPORE", "STAFF", "STAGE", "STAMP", "STAND", "STEAM", "STEEL", "STEEP", "STERN", "STICK", "STONE", "STORM", "STORY", "STRIP", "SUITE", "SWAMP", "SWIFT", "SWORD",
		"TALON", "TANGLE", "TASTE", "TEMPO", "THIEF", "THORN", "TIDAL", "TIGER", "TIMBER", "TITAN", "TOKEN", "TORCH", "TOTAL", "TOUCH", "TOWER", "TRACK", "TRAIL", "TRAIN", "TRAIT", "TRAMP", "TRANCE", "TRASH", "TREAT", "TRIBE", "TRICK", "TROOP", "TULIP", "TUNER", "TUTOR",
		"UNCLE", "UNDER", "UNITY", "UPPER", "URBAN",
		"VALLEY", "VALOR", "VALVE", "VAPOR", "VAULT", "VIPER", "VIRUS", "VISOR", "VIVID", "VOICE", "VORTEX",
		"WATER", "WAVE", "WEALTH", "WHALE", "WHEAT", "WHIRL", "WHITE", "WIDOW", "WINDY", "WITCH", "WORLD", "WOUND", "WRATH", "WRIST",
		"YACHT", "YIELD", "YOUTH",
		"ZEBRA", "ZENITH", "ZEPHYR",

		# 6+ letter adventure and tropical words
		"ADVENTURE", "ARCHIPELAGO", "ARTIFACT", "BARRIER", "BLOSSOM", "BOULDER", "CANOPY", "CASCADE", "CHAMPION", "COCONUT", "CRYSTAL", "CURRENT", "CYCLONE", "DEFEAT", "DIAMOND", "DISCOVER", "DOLPHIN", "ELEMENT", "EMERALD", "EXPLORE", "EXPLORER", "FEATHER", "FESTIVAL", "FLAMINGO", "FOLIAGE", "FOREST", "FORTRESS", "FREEDOM", "GLACIER", "GLIMMER", "GLOWING", "GUARDIAN", "HARBOR", "HARVEST", "HEAVEN", "HERITAGE", "HORIZON", "HUNTER", "HURRICANE", "ISLAND", "JOURNEY", "JUNGLE", "KINGDOM", "LAGOON", "LANTERN", "LEGEND", "LIZARD", "MONSOON", "MONUMENT", "MOUNTAIN", "MYSTERIOUS", "NATURE", "NAVIGATE", "OBELISK", "ODYSSEY", "ORCHARD", "PARADISE", "PASSAGE", "PEBBLE", "PELICAN", "PIRATE", "PIRATES", "POTION", "PROTECT", "RAINBOW", "RAVINE", "REEF", "RELIC", "RIPPLE", "ROARING", "SANCTUARY", "SAPPHIRE", "SAVANNA", "SCARLET", "SEASHELL", "SECRET", "SERPENT", "SHADOW", "SHAMAN", "SHRINE", "SOLITARY", "SPARKLE", "SPELLBOUND", "STALWART", "STREAM", "SUNBURST", "SUNLIGHT", "SUNRISE", "SUNSET", "SURVIVE", "TALISMAN", "TEMPEST", "THUNDER", "TIMBER", "TITANIC", "TORRENT", "TREASURE", "TROPICAL", "TSUNAMI", "TYPHOON", "VALIANT", "VIBRANT", "VICTORY", "VILLAGE", "VOLCANO", "VOYAGE", "WARRIOR", "WATERFALL", "WEATHER", "WHISPER", "WILDERNESS", "WOODLAND"
	]
	return words

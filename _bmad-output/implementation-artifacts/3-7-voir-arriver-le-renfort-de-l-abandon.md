# Story 3.7 : Voir arriver le renfort de l'abandon

Status: ready-for-dev

## Story

En tant que joueur,
je veux qu'un ennemi de plus soit annoncé quand je tombe en Abandon,
afin que l'aggravation reste lisible.

Exigences : FR19 (renfort), AR14 (premier flux `combat`) (epics.md, Story 3.7). Architecture : D8 (`RunRng`), P1 (renfort), ADR-002.

**Dépend de : 3.6** (`DangerProfile.reinforcement`, `Lucidity.room_danger_raised`, `Arena.begin_room()` / `Arena.danger`, `ring_pulse`) et **3.2** (`begin_room()` par vague). 3.8 s'en sert pour `cosmetic` (tremblement d'écran).

Hors périmètre : salles de cauchemar réelles (epic 6 : ici seulement un drapeau d'exception), autres flux de `RunRng` (`layout`, `rooms`, `drops`… : le flux existe par nom mais seul `combat` est utilisé), persistance de l'état des flux dans `run.json` (epic 6, P3).

## Critères d'acceptation

1. **`RunRng`** : à la création du nœud `Run`, il porte un `RunRng` (`core/run_rng.gd`, `RefCounted`) avec une seed de run tirée **sans le RNG global**, journalisée (`Log.info("run", "seed ABCD2345")`), et un flux `combat` (`RandomNumberGenerator` dont la seed dérive de `(seed de run, nom du flux, étage)`).
2. **Marqueurs** : l'arène porte des marqueurs `ReinforcementSpawn` (`Marker2D`, groupe `reinforcement_spawn`), 4 au minimum, loin des emplacements de départ.
3. **Déclenchement** : quand `room_tier` atteint Abandon pour la première fois dans la vague (aggravation en pleine vague, ou vague qui **commence** en Abandon), un renfort est programmé : une copie du type d'ennemi le plus présent dans la vague (une égalité est départagée par le flux `combat`). L'emplacement est tiré dans `combat` parmi les marqueurs situés à 3 tuiles ou plus du joueur au moment du tirage.
4. **Annonce** : 0,6 s avant l'apparition, un signe visuel sur l'emplacement et un son. L'ennemi apparaît à la fin du compte, par `Arena.spawn_enemy()` (mêmes règles : jamais à moins de 3 tuiles du joueur, sans recouvrir un ennemi).
5. **Un seul renfort par vague** : aucun second renfort si le palier redescend jusqu'à Abandon total ou si la vague repasse par Abandon. Il se réarme à la vague suivante (`begin_room()`).
6. **Salle de cauchemar** : une arène marquée `is_nightmare` ne déclenche aucun renfort.
7. **Salle vidée** : une vague dont le dernier ennemi meurt pendant l'annonce n'est pas « vidée » tant que le renfort n'a pas paru, mort (ou échoué).
8. **Lisibilité** : le renfort figure dans le journal (`Log.info("room", "reinforcement …")`) ; pas de télégraphe d'attaque supplémentaire.
9. **Déterminisme** : la même seed et les mêmes actions donnent le même type et le même emplacement (test).

## Tâches

- [ ] `core/run_rng.gd` : `RunRng.new(seed: int)` ; `static func draw_seed() -> int` (via `Crypto.generate_random_bytes`, 40 bits) ; `stream(name: StringName, floor_index: int = 0) -> RandomNumberGenerator` (cache par nom et étage) ; `seed_code() -> String` (8 caractères Crockford base32) ; `static func code_to_seed(code)`. Seed d'un flux : 8 premiers octets de `sha256_buffer("%d:%s:%d")`.
- [ ] `Run` : `var rng: RunRng` créé au début de `_ready()` ; journalise la seed ; `arena.setup(_player, rng)` (paramètre facultatif : sans lui, l'arène fabrique une `RunRng` fixe pour les scènes de vérification).
- [ ] `arena.tscn` : nœud `ReinforcementSpawns` avec 4 `Marker2D` (coins éloignés, hors `spawn_slots`) ; `Arena.is_nightmare` (`@export`, faux).
- [ ] `Arena` : `begin_room(wave_defs: Array[EnemyDef])` mémorise la composition de la vague, réarme le renfort ; écoute `room_danger_raised` et `begin_room` : `_maybe_schedule_reinforcement()` ; file d'attente des renforts (`_pending`), décompte en ticks, signe visuel ; compte `_pending` dans la condition de `emptied`.
- [ ] `WaveRunner._start_next_wave()` passe la liste des définitions prévues à `begin_room`.
- [ ] `vfx/reinforcement_sign.gd` (signe placeholder : cercle qui se resserre sur 0,6 s, couleur dédiée, via `ring_pulse` inversé ou dessin propre) ; son `sfx_reinforcement.wav`.
- [ ] `LucidityTuning.reinforcement_warning` (0,6 s) ; `reinforcement_min_player_distance` = `CombatTuning.min_spawn_distance` (3 tuiles, pas de nouvelle valeur).
- [ ] `t_reinforcement` ; `run_all.sh` une fois à la fin.

## État du code concerné

- `Arena` : `spawn_enemy(def, requested)` est l'unique entrée de création ; il résout la position (distance de 3 tuiles, bornes, recouvrement) et compte `_alive`, `emptied` part à `_alive == 0` quand le dernier quitte l'arbre (`_on_enemy_tree_exited`). `WaveRunner` écoute `emptied` : **état `FIGHTING` -> `room_cleared`**.
- `Arena.begin_room()` (3.2, 3.6) : appelé avant les apparitions ; `Arena.danger` et `_on_room_danger_raised` (3.6). `danger.reinforcement` est vrai dès Abandon.
- `WaveRunner._start_next_wave()` : `defs: Array` d'`EnemyDef` de la vague (un par ennemi). `MAX_WAVE_ENEMIES = 12` plafonne les vagues, pas les renforts (+1).
- `Run` (nœud de run) : `_ready()` crée l'arène avec `arena.setup(_player)`, journalise `run started`, émet `run_started`. Détruit et recréé à chaque nouvelle partie : une `RunRng` neuve par run.
- Aucun `randf`, `randi`, `shuffle`, `pick_random`, `randomize` dans le code de jeu (revue) : tout passe par `RunRng`. Le flux `cosmetic` sera utilisé en 3.8.
- `Telegraph` n'est pas utilisé pour le renfort (pas une attaque) ; le signe est une annonce d'apparition (AR7 : toute attaque est télégraphiée ; l'apparition n'est pas une attaque).

## Pièges

- **`emptied` pendant l'annonce** : `_alive` peut tomber à 0 alors qu'un renfort est en file : si l'on émet `emptied`, `WaveRunner` déclare la vague vidée et lance `room_cleared` + pause, puis le renfort paraît dans une salle « finie ». Compter `_pending` : `emptied` part quand `_alive == 0 and _pending == 0`, aussi quand un renfort **échoue** à apparaître (`spawn_enemy` renvoie `null`) et qu'il ne reste personne.
- **Fin de vague / run pendant l'annonce** : la file se vide à `begin_room()` (nouvelle vague), à `Events.run_ended` et à `_exit_tree()` (l'arène détruite ne doit pas appeler `spawn_enemy`) ; libérer les signes visuels avec elle.
- **Décompte en ticks** : pas de `Timer` ni `SceneTreeTimer` (règle D7) ; décrémenter dans `Arena._physics_process` avec `GameClock.scale(GameClock.Group.ENEMIES)` (figé en pause et pendant l'écran de réveil).
- **Type le plus présent** : compter par `def.id` sur la composition **prévue** (`wave_defs`), morts compris ; trier les égalités par `id` avant le tirage (ordre d'un `Dictionary` = insertion, mais ne pas en dépendre) ; ne tirer dans `combat` **que** s'il y a égalité, et toujours le même nombre de tirages pour la même situation (déterminisme).
- **Marqueurs** : `Marker2D.position` est locale à `ReinforcementSpawns` ; convertir en coordonnées de salle (`to_global` puis `Arena.to_local`) avant `spawn_enemy`. Si aucun marqueur n'est à 3 tuiles ou plus, prendre les plus éloignés (jamais zéro candidat, jamais de renfort perdu) et le laisser à `spawn_enemy` de corriger la distance.
- Le joueur bouge pendant 0,6 s : la distance de 3 tuiles est testée au **tirage** ; `spawn_enemy` la re-vérifie à l'apparition et déplace au besoin (règle de 2.3). Documenter, ne pas rejouer le tirage.
- **Seed** : `RandomNumberGenerator.seed` assigne et réinitialise l'état ; ne jamais appeler `randomize()` sur un flux. `Crypto.generate_random_bytes(5)` ne passe pas par le RNG global. `hash()` n'est pas garanti stable d'une version à l'autre : utiliser `sha256_buffer`.
- `Array[EnemyDef]` typé : `begin_room(defs)` reçoit un tableau typé (`Array[EnemyDef]`), `WaveRunner` stocke `Array[Array]` : convertir en construisant un tableau typé.
- `Enemy.name` : `Arena` nomme `<id>_<n>` ; le renfort suit la même règle (`spawn_enemy` s'en charge).
- Le renfort doit apparaître dans `_enemies` et compter dans `_alive` comme les autres : jamais en direct dans l'arbre.

## Vérifications prévues (`.scratch/t_reinforcement.gd`)

- `RunRng` pur : même seed -> mêmes flux (10 tirages identiques) ; deux noms -> séquences différentes ; deux étages -> différentes ; `seed_code` fait 8 caractères et revient à la même seed ; `draw_seed` n'altère pas l'état du RNG global (seed globale posée avant, tirage identique après).
- Jeu : une `Run` a une `rng` et une seed journalisée ; vague de Somnambules + 1 Mouton + `set_value(20)` -> un renfort Somnambule annoncé (signe présent, ennemis +0), puis apparu après 36 ticks (0,6 s), `alive` +1 ; marqueur à 3 tuiles ou plus du joueur ; égalité (1 Mouton, 1 Somnambule) départagée par `combat` : même résultat sur deux essais à seed égale, résultat éventuellement différent selon la seed.
- Un seul : `set_value(0)` ensuite -> pas de second ; vague suivante : rearmé et, si le palier est encore Abandon au début, nouveau renfort.
- `is_nightmare = true` : rien. Vague qui commence en Abandon : renfort programmé.
- Vague dont tous les ennemis meurent pendant l'annonce : pas de `room_cleared` avant le renfort ; renfort tué -> `room_cleared` ; renfort impossible (aucune place) -> `room_cleared` quand même.
- Pause pendant l'annonce : le compte s'arrête ; `run_ended` pendant l'annonce : rien n'apparaît.

## Fichiers prévus

`game/core/run_rng.gd`, `game/core/lucidity_tuning.gd`, `game/data/tuning/lucidity_tuning.tres`, `game/run/run.gd`, `game/rooms/arena/arena.gd`, `game/rooms/arena/arena.tscn`, `game/rooms/waves/wave_runner.gd`, `game/vfx/reinforcement_sign.gd`, `game/audio/sfx/sfx_reinforcement.wav`, `game/.scratch/t_reinforcement.*` (scènes existantes qui créent une `Arena` seule : sans `rng`, valeur par défaut).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Seed de run = 40 bits affichés en 8 caractères Crockford base32** — Raison : l'architecture dit « 64 bits » et « 8 caractères » (incompatibles) ; 40 bits tiennent dans le code court à saisir, ce qui sert plus que 64 bits.
2. **Le type le plus présent se compte sur la vague prévue, morts compris** — Raison : GDD « le type le plus présent dans la salle » ; stable quel que soit le moment de l'aggravation.
3. **Une vague qui commence en Abandon reçoit son renfort aussitôt** — Raison : GDD « 1 ennemi supplémentaire par salle de combat » en Abandon ; l'AC dit « atteint Abandon pour la première fois dans la vague ».
4. **Les renforts retardent `room_cleared` (`_pending` compte comme vivant)** — Raison : sinon la vague est « vidée » avant son dernier ennemi.
5. **Distance de 3 tuiles testée au tirage, recorrigée à l'apparition par `spawn_enemy`** — Raison : une seule règle de position pour tous les ennemis.
6. **4 marqueurs, un par coin éloigné, posés dans `arena.tscn`** — Raison : le GDD prévoit des emplacements de renfort propres à chaque salle ; les salles peintes (epic 4) les remplaceront.
7. **Le signe est un cercle qui se resserre, sans flash ; son dédié** — Raison : lisibilité et photosensibilité.
8. **`is_nightmare` : simple booléen exporté** — Raison : pas de salle de cauchemar avant l'epic 6 ; le drapeau suffit pour l'AC.
9. **Le renfort ne compte pas dans `MAX_WAVE_ENEMIES`** — Raison : plafond technique de la composition ; +1 reste dans la marge du pool de projectiles.

## Dev Agent Record

### Agent Model Used

### Completion Notes

### File List

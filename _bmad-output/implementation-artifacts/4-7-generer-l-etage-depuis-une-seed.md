# Story 4.7 : Générer l'étage depuis une seed

Status: review

## Story

En tant que joueur,
je veux qu'un étage différent soit assemblé à chaque run, et identique pour une même seed,
afin de rejouer sans cesse et de partager une run intéressante.

Exigences : FR37, FR43 (déterminisme), NFR5, AR14, AR17 (epics.md, Story 4.7). Architecture : D8 (seeds et flux), D10/D11 (salles et génération), AR26 (test sur 10 seeds obligatoire). GDD : « Génération procédurale » (16 salles : 1 départ, 12 combats, 1 trésor, 1 boutique, 1 cauchemar ; chemin garanti ; cauchemar au bout d'au moins 4 salles ; jamais deux fois la même salle ; disposition indépendante des choix du joueur).

**Dépend de : 4.1** (tests), **4.2** (`RoomInfo`, `Room`, pool, validateur) ; les tailles de salle de la 4.6 ne comptent pas ici. **4.8** consomme `FloorLayout` ; 4.9 le dessine ; 4.10 remplit le pool réel ; 4.11 pilote la seed.

Hors périmètre : jouer l'étage (4.8), contenu du trésor et de la boutique (epic 5), cauchemar réel (epic 6), plusieurs étages (l'indice d'étage vaut 0 ; il est déjà dans le hachage des flux).

## Critères d'acceptation

1. **`RunRng` (déjà livré en 3.7, 40 bits, 8 caractères base32)** : ajouter les noms de flux en constantes (`RunRng.LAYOUT`, `ROOMS`, `TREASURE`, `SHOP`, `DROPS`, `COMBAT`, `COSMETIC`) et vérifier par test : flux indépendants, hachage de `(seed, flux, étage)`, aller-retour du code de seed. **La seed reste de 40 bits** (le texte de l'epic dit 64 bits ; 8 caractères en base32 n'en portent que 40 : GDD et architecture imposent les 8 caractères).
2. **`RunState`** (`run/run_state.gd`, `RefCounted`) : `run_seed`, `seeded` (faux par défaut), `floor_index` (0). `Run` le porte ; `Run.setup(options)` accepte `RunOptions.seed_value` (−1 = tirage par `RunRng.draw_seed()`), `seeded`.
3. **`FloorDef`** (`generation/floor_def.gd`, `Resource`, `data/floors/onset.tres`) : `phase`, `pool_dir`, composition (`combat_rooms` = 12, `treasure_rooms` = 1, `shop_rooms` = 1, `nightmare_rooms` = 1), `min_nightmare_distance` = 4, bornes de la grille, `loop_chance`, `max_attempts`. Aucune valeur en dur dans le générateur.
4. **`FloorGenerator.generate(def, pool: Array[RoomInfo], rng: RunRng, floor_index) -> FloorLayout`** (`RefCounted`, sans nœud ni autoload) : 16 salles (1 départ, 12 combats, 1 trésor, 1 boutique, 1 cauchemar) sur une grille de cellules **une salle = une cellule**, étendue depuis le départ ; une arête relie deux cellules adjacentes dont les deux salles ont une porte de ce côté ; chaque salle est atteignable depuis le départ. Cauchemar, trésor et boutique sont des **impasses** (une seule connexion), le cauchemar à **4 salles ou plus** (distance en connexions) du départ. Une salle prédessinée n'apparaît jamais deux fois. Échec des contraintes (pas assez d'impasses, pas de salle avec les portes voulues) : **nouveau tirage dans le flux `layout`**, jusqu'à `max_attempts` ; au-delà, un `FloorLayout` invalide (`valid = false`) et `Log.error`, jamais de boucle infinie.
5. **Flux utilisés** : forme de la grille et impasses dans `layout` ; choix des salles dans `rooms` (avec le tri des candidats par identifiant avant tirage) ; rien d'autre. Aucun appel au RNG global dans `generation/` : test GUT qui lit les sources (`tests/unit/test_code_rules.gd`) et refuse `randi()`, `randf()`, `randomize`, `randi_range(` hors méthode d'un générateur, `.shuffle(`, `.pick_random(`.
6. **Test des 10 seeds (obligatoire, versionné)** : pour 10 seeds fixes, deux générations avec deux `RunRng` neufs donnent la même disposition et les mêmes salles (`FloorLayout.signature()` identique) ; les 10 signatures ne sont pas toutes égales ; chaque étage vérifie les invariants du critère 4. Les tests utilisent un **pool factice** (`tests/support/fake_pool.gd`, des `RoomInfo` construits à la main : départs, trésors, boutiques, cauchemars, 20 combats dont des grandes salles, des salles à portes partielles).
7. **Salles provisoires** : `onset_start_001` (calme, sans ennemi), `onset_treasure_001` et `onset_shop_001` (vides), `onset_boss_001` (type NIGHTMARE, combat renforcé : 2 vagues, plus d'ennemis, `is_nightmare = true` donc aucun renfort) ; plus `onset_combat_009` à `012` simples pour que le pool réel compte **au moins 12 salles de combat** et que 4.8 soit jouable avant 4.10. Le validateur de la 4.2 les accepte.
8. **`RoomCatalog`** (`generation/room_catalog.gd`) : parcourt `pool_dir`, trie les chemins, construit les `RoomInfo` (`RoomInfo.from_scene`), garde un cache ; accepte les suffixes `.remap` (builds exportés). Paramètre `unlocks: Array[StringName]` (vide au MVP) : `RoomInfo.requires_unlock` filtre le pool, pour que « mêmes déblocages » donne la même run.
9. **Journal et outil** : `Log.info("gen", "floor generated seed=%s attempts=%d")` quand une `Run` génère ; F1 « afficher la disposition » écrit la carte ASCII (`FloorLayout.to_text()`) dans le journal ; `Events.run_requested` (4.2) porte déjà seed et `seeded`.

## Tâches

- [x] `RunState`, `RunOptions` (champs `seed_value`, `seeded`, mode `FLOOR` ajouté à l'enum ; le mode n'est branché qu'en 4.8), `Run.setup`, `Room.setup(player, rng, floor_index)` : le flux `combat` de la salle utilise `floor_index` (deferred-work 3.7 « flux `combat` toujours à l'étage 0 »).
- [x] `FloorDef`/`onset.tres`, `FloorLayout` (cellules `Vector2i → Placement`, arêtes, `start`, `neighbors`, `door_sides(cell)`, `distance(a, b)`, `to_text()`, `signature()`), `FloorGenerator`, `RoomCatalog`, `RoomInfo.requires_unlock`.
- [x] Salles provisoires et `onset_combat_009..012` par l'outil ASCII ; `RoomValidator` sans changement de règle.
- [x] Tests : `tests/unit/generation/test_floor_generator.gd` (invariants, 10 seeds, échec propre d'un pool trop petit, retries), `test_floor_layout.gd`, `test_room_catalog.gd` (pool réel : ≥ 12 combats, ordre trié), `tests/unit/core/test_run_rng.gd` (flux), `tests/unit/test_code_rules.gd`.
- [x] F1 : commande « disposition » (journal) ; panneau F1 : relance avec une seed donnée arrive en 4.11.

## État du code concerné

- `core/run_rng.gd` : `stream(name, floor_index)` crée à la demande et **garde** le générateur (les appels suivants continuent la séquence), `seed_code()`, `code_to_seed()` statique, `draw_seed()` par `Crypto`. `Run._ready` : `rng = RunRng.new(RunRng.draw_seed())` ; journalise `seed XXXXXXXX` puis `run started`.
- `Arena` : `FALLBACK_RUN_SEED = 1`, flux `combat` (reflets du renfort) et `cosmetic` sans indice d'étage.
- `RoomInfo.from_scene` (4.2) instancie la salle puis la libère ; il lit les `Door` et les métadonnées.
- Le pool réel contient au moins 001 à 008 (4.2 à 4.6) ; la 4.10 en ajoute jusqu'à 30+ sans renuméroter.

## Pièges

- **Déterminisme** : ne jamais itérer un `Dictionary` dont l'ordre dépend d'insertions variables sans trier ; trier les cellules (y puis x) et les salles (identifiant) avant chaque tirage ; pas de `Array.shuffle()`, pas de `pick_random()` (RNG global) ; tirer par `rng.randi_range(0, n - 1)` sur `RunRng.stream(...)`.
- Un `RunRng` **neuf** par génération dans les tests : ses flux gardent leur état, une seconde génération sur le même objet donne autre chose. Dans le jeu, l'étage est généré une seule fois par `Run`.
- `DirAccess.get_files_at()` n'est pas ordonné et, en build exporté, liste des `.tscn.remap` : trier et retirer le suffixe (`RoomCatalog`).
- Comparer deux dispositions par une chaîne canonique (`signature()`), pas par égalité d'objets.
- La grille est bornée (ex. 9×7) : l'extension ne tire que des cases libres adjacentes à **une seule** case occupée (arbre), les boucles ne sont ajoutées qu'entre salles de combat/départ (jamais sur une impasse spéciale) avec `loop_chance` ; un tirage « bloqué » (aucune case libre) relance.
- Les types `Array[RoomInfo]`, `Dictionary[Vector2i, Placement]` typés : les assigner par `assign()` quand ils viennent d'un `Array` non typé.
- `RoomInfo.from_scene` instancie ~40 scènes au premier appel : le faire une fois (cache) et pas dans le test des 10 seeds (pool factice).

## Fichiers prévus

`core/run_rng.gd`, `run/run_state.gd`, `run/run_options.gd`, `run/run.gd`, `rooms/room.gd` (`setup`), `generation/{floor_def,floor_layout,floor_generator,room_catalog,room_info}.gd`, `data/floors/onset.tres`, `rooms/pool/onset/onset_{start,treasure,shop,boss}_001.tscn`, `onset_combat_009..012.tscn`, `art_source/rooms/*.txt`, `debug/debug_panel.gd`, `tests/**`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Une salle = une cellule de grille**, y compris les grandes salles (la 4.6 ne change pas la grille) : la génération ignore la taille ; la carte (4.9) peut marquer une grande salle.
2. **Seed de 40 bits** (écart avec « 64 bits » de l'epic, conforme au GDD « 8 caractères »).
3. **Étage = arbre étendu puis boucles facultatives** entre salles non spéciales : chemin garanti, impasses abondantes pour trésor, boutique et cauchemar.
4. **Distance = nombre de connexions** (« 4 salles ou plus » du GDD).
5. **Salles tirées dans `rooms`, forme dans `layout`** : changer le pool ne change pas la forme de l'étage pour une seed donnée tant que les contraintes tiennent ; la disposition reste indépendante des actes du joueur.
6. **Pool factice pour les tests**, pool réel testé seulement pour le comptage et l'ordre.
7. **`Room.setup` reçoit l'indice d'étage** (clôt le deferred-work du flux `combat`).
8. **Cauchemar provisoire = combat renforcé** (comme l'epic), sans renfort.
9. **La seed dans `run started` du télémétrie reste à la 4.11** ; ici seulement le journal de génération.

10. **Nouvelles décisions du développement** : (a) `FloorGenerator` ne journalise pas (reste sans autoload, conforme à sa signature) : il renseigne `FloorLayout.failure` et `Run.ensure_floor()` fait le `Log.error` ; (b) croissance de l'arbre : une case libre est éligible avec 1 ou 2 voisines occupées (sinon aucune boucle ne pourrait exister), la boucle est ensuite tirée par paire à `loop_chance` ; (c) les impasses spéciales se greffent sur un départ ou un combat, dans l'ordre cauchemar, trésor, boutique ; (d) départ au centre de la grille ; (e) `is_nightmare` supprimé : `Room.is_nightmare()` dérive de `room_type` ; (f) `RoomBuilder` valide (RoomValidator) toute salle de pool écrite sans sortie explicite, pas les fixtures de test ; (g) F1 touche G (carte dans le journal) ; `Run.ensure_floor()` génère à la demande, `Mode.FLOOR` ne fait que générer (la salle jouée reste l'arène jusqu'à la 4.8) ; (h) `RunOptions.seed_value` vaut -1 par défaut, une seed négative avec `seeded` est ignorée ; (i) `onset_combat_009` à `012` ont les quatre portes pour que le pool réel (12 combats) remplisse toujours un étage.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Completion Notes

- Tous les critères sont couverts. Flux nommés (`RunRng.LAYOUT`...), `RunState`, `FloorDef`/`onset.tres`, `FloorLayout`, `FloorGenerator`, `RoomCatalog`, `RoomInfo.requires_unlock`, salles provisoires, journal `gen`, touche F1 G.
- Déterminisme : 10 seeds fixes, deux `RunRng` neufs, même `signature()` ; l'ordre du pool (permuté) ne change rien ; deux étages de référence figés par hachage de leur signature ; `tests/unit/test_code_rules.gd` interdit le RNG global dans `generation/`.
- Sur 300 seeds, le pool factice comme le pool réel donnent un étage valide à la première tentative ; le test de relance utilise un cauchemar à 6 connexions.
- Dettes 4.7 traitées : flux `combat` par étage (`Room.setup(player, rng, floor_index)`), valeurs de référence de `RunRng`, `is_nightmare` en double, outil ASCII (ids stables, `phase`, sortie atomique et validée, en-têtes, plage de `wave`).
- Vérifications : `tools/run_tests.sh` vert (GUT, 27 scripts), `run_all.sh` en mode normal, `--quit-after 120` propre. NON ÉVALUÉ (humain) : forme et variété des étages (voir `deferred-work.md`).

### Change Log

- 2026-11-24 : implémentation de la story 4.7.

### File List

`game/core/run_rng.gd`, `game/core/constants.gd`, `game/run/{run,run_options,run_state}.gd`, `game/rooms/room.gd`, `game/rooms/validator/{room_builder,room_validator}.gd`, `game/generation/{floor_def,floor_layout,floor_generator,room_catalog,room_info}.gd`, `game/data/floors/onset.tres`, `game/rooms/pool/onset/onset_{start,treasure,shop,boss}_001.tscn`, `onset_combat_009..012.tscn`, `art_source/rooms/*.txt`, `game/debug/debug_panel.gd`, `tools/build_room.sh`, tests : `tests/support/fake_pool.gd`, `tests/unit/generation/*`, `tests/unit/test_code_rules.gd`, `tests/unit/core/test_run_rng.gd`, `tests/unit/rooms/{test_room_builder,test_room_validator}.gd`, `tests/integration/run/test_run_floor.gd`.

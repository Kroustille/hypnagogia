# Story 4.5 : Des ennemis qui contournent les obstacles

Status: in-progress

## Story

En tant que joueur,
je veux que les ennemis me poursuivent intelligemment entre les obstacles,
afin que les salles dessinées ne les piègent pas bêtement.

Exigences : AR23 (`AStarGrid2D`) (epics.md, Story 4.5). Architecture : D17 (pathfinding au jalon B), « Création d'entités ».

**Dépend de : 4.2** (`Room`, couches de tuiles) et **4.3** (trous) ; lit aussi les meubles de **4.4** (`Furniture.destroyed`). Les salles de 4.6 (grandes) agrandissent la grille sans autre changement.

Hors périmètre : lignes de vue des tireuses (elles tirent toujours à toute distance, un obstacle haut sur l'axe gâche le tir : décision 2.4, à juger au jeu), évitement entre ennemis, contournement du joueur par le Mouton (il charge toujours en ligne droite).

## Critères d'acceptation

1. **Grille de navigation** : `RoomNav` (`rooms/room_nav.gd`, `RefCounted`, sans nœud) enveloppe une `AStarGrid2D` de la taille du cadre de la salle (murs compris), une cellule = une tuile, cases solides = cellules de `Walls`, `HighObstacles`, `LowObstacles`, `Pits` et corps de meubles vivants. Construite par `Room._ready()` après les tuiles (l'arène du jalon A en reçoit une aussi). `set_blocked(cell, bool)` met à jour une cellule (meuble détruit).
2. **Chemin** : `RoomNav.path(from_px, to_px) -> PackedVector2Array` (points au centre des cellules, coordonnées de salle). Diagonales permises seulement si aucun des deux voisins n'est bloqué (pas de coin coupé). Départ ou arrivée sur une cellule bloquée : repli sur la cellule libre la plus proche (anneau croissant), jamais d'erreur. Aucun chemin : tableau vide.
3. **Ligne directe** : `RoomNav.is_line_clear(a_px, b_px, half_width_px)` échantillonne le segment (pas ≤ 4 px) et ses deux bords décalés de la demi-largeur du corps ; faux si une cellule bloquée est touchée.
4. **Somnambule et Berceuse** : `Enemy._chase(point, speed_px, clock_scale)` (nouveau, dans la base) : ligne directe libre → `_move_toward` comme aujourd'hui ; sinon suit le chemin, waypoint par waypoint. Sans cible valide, `_chase` ne bouge pas (règle gardée dans l'appelant, deferred-work 4.5). L'accélération du Somnambule (RUSH) reste directe.
5. **Recalcul borné** : le chemin d'un ennemi est recalculé au plus toutes les `Tuning.COMBAT.path_refresh_interval` secondes (0,4 s), décalé par ennemi (numéro d'apparition) pour que tous ne calculent pas au même tick ; `RoomNav` refuse au-delà de `max_paths_per_tick` (4) par tick, l'ennemi garde alors son chemin précédent. Jamais de recalcul « à chaque frame pour tous ». `RoomNav.path_requests` (compteur) sert aux tests.
6. **Mouton** : charge toujours en ligne droite. `Sheep.STUNNING_LAYERS` gagne `LAYER_HIGH_OBSTACLES` : un obstacle haut l'arrête et l'étourdit comme un mur ; un obstacle bas (ou un meuble) l'arrête sans étourdissement, comme un ennemi (retour au repos).
7. **Salle de test** `onset_combat_006` : mur central avec deux ouvertures, obstacle en U, un trou en travers d'un couloir, 2 vagues (Somnambule, Berceuse, Mouton).
8. **Pas de régression de l'arène** : les scènes `.scratch` passent ; si l'une suppose qu'un ennemi reste collé derrière un obstacle, l'ajuster seulement à cet endroit.

## Tâches

- [x] `RoomNav` pur (construit à partir d'une taille et d'une liste de cellules bloquées, + une fabrique `from_room(room)`), compteurs et budget par tick.
- [x] `Enemy.setup(..., nav: RoomNav = null)` (6e paramètre optionnel, après `room_danger`) ; `Room.spawn_enemy` le donne ; `Enemy._chase()`, état de chemin (`PackedVector2Array`, index, tick du prochain calcul) ; remplacer les 4 appels directs du Somnambule (poursuite) et de la Berceuse.
- [x] `CombatTuning.path_refresh_interval`, `max_paths_per_tick` ; `Sheep.STUNNING_LAYERS` ; lien meuble détruit → `set_blocked`.
- [x] Salle 006 (ASCII) ; validateur : rien de nouveau (l'accessibilité est celle de la 4.3).
- [x] F2 (`CollisionDrawer`) : tracer le chemin de l'ennemi sélectionné n'est pas exigé ; un `Log.debug` par recalcul suffit.
- [x] Tests GUT : `tests/unit/rooms/test_room_nav.gd` (contournement, pas de coin coupé, murs/trous/meubles bloqués, mise à jour d'une cellule, inatteignable, départ bloqué, ligne directe avec demi-largeur), `tests/integration/enemies/test_enemy_pathing.gd` (un Somnambule derrière le mur central atteint le joueur en un nombre de ticks borné ; le nombre de calculs sur 120 ticks avec 8 ennemis reste ≤ budget × ticks ; la Berceuse contourne ; la cible disparue arrête l'ennemi), `test_sheep_stun.gd` (haut : étourdi ; bas : repos sans étourdissement).

### Review Findings

Revue complète (3 couches, passes isolées) du 2026-11-24 sur `dfc8283..83e109d`. Numéros de ligne à `83e109d`. GUT de la story verts (12 + 7 + 3), suite GUT 159/159 hors sondes. Deux sondes GUT jetables (`game/.scratch/review45/`) confirment les deux actions. 2 actions, 2 reportés, une dizaine d'écartés (coin d'un corps carré en diagonale : 6 px testés contre 7,07 px, la physique glisse ; budget de 4 par tick : capacité 96 calculs par intervalle, aucune famine possible sous ~96 ennemis ; portes toujours bloquées : leurs cellules sont dans le cadre, inatteignables de toute façon ; garde de contact : la fuite de la Berceuse, la charge du Mouton et `knock_back` ne sont pas affectées ; salle 006 : sondes passage d'une tuile sous le trou et U dans les deux sens atteints en < 400 ticks).

- [ ] [Review][Patch] **Chemin périmé repris après une interruption de la poursuite** [`game/enemies/enemy.gd:238-249`] : `_plan_ticks_left` et `_path` ne bougent pas tant que `_chase()` n'est pas appelée (éblouissement, télégraphe et ruée du Somnambule, Berceuse entrée dans sa bande de distance) ; à la reprise l'ennemi suit un chemin vieux de plusieurs secondes jusqu'à l'échéance (piège « ne pas conserver un chemin plus d'un intervalle »). Sonde : Somnambule ébloui 2 s pendant que le joueur passe de son côté, il repart à l'opposé du joueur (cos −0,36) pendant ~14 ticks. Correctif : `var _last_chase_frame: int = -2` ; dans `_chase()`, après le test `_nav == null` : `var frame: int = Engine.get_physics_frames()` ; `if frame != _last_chase_frame + 1: _plan_ticks_left = 0.0; _path = PackedVector2Array(); _path_index = 0` ; `_last_chase_frame = frame`. Test : le scénario de la sonde (déplacement vers le joueur, cos > 0,9 sur 20 ticks après l'éblouissement).
- [ ] [Review][Patch] **Le Somnambule télégraphie à travers un mur et boucle** [`game/enemies/sleepwalker/sleepwalker.gd:68`] : la portée de déclenchement (2 tuiles) est une distance à vol d'oiseau ; joueur collé de l'autre côté d'un mur d'une tuile, le Somnambule enchaîne TELEGRAPH → RUSH (dans le mur) → CHASE → TELEGRAPH sans jamais contourner (sonde `nav_wall` : joueur (394, 168), Somnambule (424, 168), 44 changements d'état en 900 ticks, jamais passé) : critère 4 mis en échec et exploitable par le joueur. Correctif : extraire la demi-largeur de `_plan_path` dans `Enemy._path_half_width() -> float`, ajouter `Enemy._has_clear_line(point: Vector2) -> bool` (`return _nav == null or _nav.is_line_clear(global_position - _nav.origin, point - _nav.origin, _path_half_width())`), et dans `_process_chase` : `if _distance_to_target() < _trigger_range_px and _has_clear_line(_target_position()):`. Segment court (≤ 2 tuiles), hors budget. Test : la sonde (le Somnambule passe du côté du joueur en ≤ 900 ticks). Décision 12.
- [x] [Review][Defer] **`RoomNav.origin` lu une seule fois dans `Room._ready()`** [`game/rooms/room_nav.gd:41`] — reporté à la 4.8 (si une salle est placée ailleurs qu'à l'origine ou déplacée après son `_ready()`).
- [x] [Review][Defer] **Aucune mesure de coût du pathing** [`game/enemies/enemy.gd`, `game/rooms/room_nav.gd`] — reporté à la 4.6 (grandes salles, vagues de 7 + renfort ; une cible inatteignable coûte un A* complet en échec par ennemi toutes les 0,4 s).

## État du code concerné

- `Enemy._move_toward(point, speed_px, clock_scale)` approche un point sans test de cible (depuis la 2.5) ; `_move_in_direction(dir, ...)` ; `_target_position()` renvoie la position de l'ennemi si la cible a disparu. Les appels : `Sleepwalker._process_chase` et `_process_rush`, `Lullaby` (déplacement hors inspiration). Veilleuse : immobile.
- Corps des ennemis : rectangle de `EnemyDef.body_size` (10×10 px, 0,625 tuile) ; masque = murs, joueur, ennemis, obstacles hauts et bas (+ meubles depuis la 4.4) ; `MOTION_MODE_FLOATING`.
- `Sheep._process_charge` : sort sur collision ; `_is_stunning(collision)` lit la couche du collisionneur ; `STUNNING_LAYERS = LAYER_WALLS` ; `max_charge_distance` posé par la 4.3.
- Arène : obstacles bas et hauts construits en code (`_place_blocks`) ; `Room` les expose par les mêmes couches `LowObstacles`/`HighObstacles`.

## Pièges

- `AStarGrid2D` : appeler `update()` après `region`, `cell_size`, `offset`, `diagonal_mode` et **avant** `set_point_solid` ; sans `offset = cell_size / 2` les chemins visent le coin des cellules ; changer `region` plus tard invalide les points. `get_id_path` ne dit rien d'un point solide d'arrivée : traiter soi-même le repli (critère 2).
- `DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES` (pas `NEVER`, trop anguleux) ; `heuristic` octile.
- Les coordonnées de `get_point_path` sont celles de la grille × `cell_size` + `offset` : repère de la **salle** ; convertir par `to_global` avant de s'en servir comme cible de `_move_toward`.
- Une cellule de corps d'ennemi n'est jamais bloquée (les ennemis se bloquent par la physique) : un seul ennemi dans un couloir étroit n'empêche pas les autres de calculer.
- Un ennemi entre deux waypoints qui se fait pousser : critère d'arrivée en distance < 2 px **ou** passage du point (produit scalaire), sinon il oscille ; ne pas conserver un chemin plus d'un intervalle.
- Le corps de 10 px passe entre deux obstacles séparés d'une tuile ; ne pas bloquer les cellules voisines « par prudence » (les tests l'attendent).
- `PackedVector2Array` renvoyé par `get_point_path` est une copie : ne pas le réécrire en boucle sur chaque tick.

## Fichiers prévus

`rooms/room_nav.gd`, `rooms/room.gd`, `enemies/enemy.gd`, `enemies/sleepwalker/sleepwalker.gd`, `enemies/lullaby/lullaby.gd`, `enemies/sheep/sheep.gd`, `core/combat_tuning.gd`, `data/tuning/combat_tuning.tres`, `rooms/pool/onset/onset_combat_006.tscn`, `art_source/rooms/onset_combat_006.txt`, `tests/**`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Grille = une tuile par cellule**, cadre complet : simple à tester, la même pour toutes les tailles de salle.
2. **Accélération du Somnambule directe**, poursuite pathée : l'accélération dure 0,6 s (≈ 3 tuiles), la contourner changerait sa lecture.
3. **Obstacle bas : arrête le Mouton sans l'étourdir** (le texte de l'epic ne parle que des hauts).
4. **Les trous sont des cellules bloquées pour les ennemis** (ils les évitent) alors qu'ils n'y tombent pas.
5. **Budget de 4 calculs par tick et 0,4 s d'intervalle** (réglables dans `CombatTuning`) : valeurs de départ, aucune mesure de performance faite.
6. **Pas de ligne de vue pour les tireuses** : hors périmètre, NON ÉVALUÉ au jeu.
8. **Cellules de portes toujours bloquées** dans la grille (une porte est un mur pendant le combat, personne ne la franchit avant la fin) ; évite d avoir à écouter l état des portes.
9. **Le test de ligne directe est planifié comme le chemin** (toutes les 0,4 s, sous le budget) : coût borné, au prix d un frottement d au plus 0,4 s contre un coin si la cible bouge.
10. **La garde « ne pas avancer dans la cible » devient la règle de `_move_toward`** (Somnambule, Berceuse, recul du Mouton) ; la charge du Mouton et la poussée de `knock_back` n en dépendent pas.
11. **Retour de chute sur un ennemi (deferred 4.3)** : non traité, ce n est pas une tâche de la story et touche `PitGuard`/le joueur ; reste dans `deferred-work.md`.
12. **(revue) Le Somnambule ne télégraphie qu'avec une ligne libre vers le joueur** : sinon il boucle télégraphe/ruée contre un mur d'une tuile ; alternative écartée : ruée pathée (change la lecture, décision 2). Coût : un test de ligne court par tick dans la portée.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Completion Notes

- `RoomNav` (`rooms/room_nav.gd`) : `AStarGrid2D` d une tuile par cellule, cadre complet ; `from_room()` bloque murs, obstacles hauts et bas, trous, cellules de portes et meubles vivants (le signal `destroyed` libère les cellules). `path()`, `nearest_free_cell()`, `is_line_clear()`, `take_path_slot()` (budget par tick via `Engine.get_physics_frames()`), `path_requests`.
- `Enemy._chase()` : ligne directe testée puis chemin, planifiés au plus toutes les 0,4 s ; première planification immédiate, les suivantes décalées par le numéro d apparition (`RoomNav.next_stagger()`). Le test de ligne directe est lui aussi compté dans la planification (jamais à chaque tick).
- Gardes factorisées dans `Enemy` : `_move_toward` et `_move_in_direction(..., spare_target)` n avancent jamais dans le corps de la cible touchée (ancien `_advance` du Somnambule, désormais aussi la poursuite pathée, la Berceuse et le recul du Mouton : deferred 4.3).
- `Sheep.STUNNING_LAYERS` gagne les obstacles hauts ; un obstacle bas ou un meuble termine la charge sans étourdissement.
- Salle `onset_combat_006` (mur central à deux ouvertures dont une avec un trou et un passage d une tuile, U d obstacles hauts, 2 vagues). Validateur inchangé : 6 salles valides.
- Tests : GUT `test_room_nav` (12), `test_enemy_pathing` (7), `test_sheep_stun` (3) ; `test_room_validator` compte 6 salles. GUT 155 verts, scratch FAST ok (seul `t_shooters` son échoue en FAST, attendu).
- NON ÉVALUÉ (humain) : fluidité des contournements et de la poursuite à plusieurs au jeu ; charge `F5` (`Bullets 400 | refused 0`) non rejouée (fenêtre requise), le code des balles n est pas touché.
- Non traité (hors tâches de la story) : retour de chute sur un corps ennemi (`PitGuard`), laissé dans `deferred-work.md`.

### File List

- `game/rooms/room_nav.gd` (+ `.uid`), `game/rooms/room.gd`, `game/enemies/enemy.gd`, `game/enemies/sleepwalker/sleepwalker.gd`, `game/enemies/lullaby/lullaby.gd`, `game/enemies/sheep/sheep.gd`
- `game/core/combat_tuning.gd`, `game/data/tuning/combat_tuning.tres`
- `art_source/rooms/onset_combat_006.txt`, `game/rooms/pool/onset/onset_combat_006.tscn`
- `game/tests/unit/rooms/test_room_nav.gd`, `game/tests/integration/enemies/test_enemy_pathing.gd`, `game/tests/integration/enemies/test_sheep_stun.gd`, `game/tests/fixtures/rooms/nav_wall.*`, `sheep_blocks.*`, `game/tests/unit/rooms/test_room_validator.gd`

### Change Log

- 2026-11-24 : implémentation de la story 4.5.
- 2026-11-24 : revue de code (2 actions, 2 reportés) ; retour en `in-progress`.

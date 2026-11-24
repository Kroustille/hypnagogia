# Story 4.5 : Des ennemis qui contournent les obstacles

Status: ready-for-dev

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

- [ ] `RoomNav` pur (construit à partir d'une taille et d'une liste de cellules bloquées, + une fabrique `from_room(room)`), compteurs et budget par tick.
- [ ] `Enemy.setup(..., nav: RoomNav = null)` (6e paramètre optionnel, après `room_danger`) ; `Room.spawn_enemy` le donne ; `Enemy._chase()`, état de chemin (`PackedVector2Array`, index, tick du prochain calcul) ; remplacer les 4 appels directs du Somnambule (poursuite) et de la Berceuse.
- [ ] `CombatTuning.path_refresh_interval`, `max_paths_per_tick` ; `Sheep.STUNNING_LAYERS` ; lien meuble détruit → `set_blocked`.
- [ ] Salle 006 (ASCII) ; validateur : rien de nouveau (l'accessibilité est celle de la 4.3).
- [ ] F2 (`CollisionDrawer`) : tracer le chemin de l'ennemi sélectionné n'est pas exigé ; un `Log.debug` par recalcul suffit.
- [ ] Tests GUT : `tests/unit/rooms/test_room_nav.gd` (contournement, pas de coin coupé, murs/trous/meubles bloqués, mise à jour d'une cellule, inatteignable, départ bloqué, ligne directe avec demi-largeur), `tests/integration/enemies/test_enemy_pathing.gd` (un Somnambule derrière le mur central atteint le joueur en un nombre de ticks borné ; le nombre de calculs sur 120 ticks avec 8 ennemis reste ≤ budget × ticks ; la Berceuse contourne ; la cible disparue arrête l'ennemi), `test_sheep_stun.gd` (haut : étourdi ; bas : repos sans étourdissement).

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
7. **Pas de contournement des ennemis entre eux** : ils se bloquent par la physique comme depuis la 2.3.

## Dev Agent Record

### Agent Model Used

### Completion Notes

### File List

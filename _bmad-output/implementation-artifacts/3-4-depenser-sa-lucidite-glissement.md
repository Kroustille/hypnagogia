# Story 3.4 : Dépenser sa lucidité : Glissement

Status: review

## Story

En tant que joueur,
je veux me téléporter vers le point visé à travers les projectiles,
afin de traverser un mur de tirs au prix de ma jauge.

Exigences : FR21, FR24 (sans les trous), AR29 (rayon) (epics.md, Story 3.4). Architecture : D5, D6, hit zones et couches de collision (`high_obstacles`, `low_obstacles`).

**Dépend de : 3.3** (`try_spend`, `PowerCooldown`, `ring_pulse`, son de refus, motif de lecture des pouvoirs dans `Player`) et **3.2** (l'invulnérabilité d'arrivée passe par `Player.is_invulnerable()` : pas de graze ; ce n'est pas `is_evading()` : pas de dash parfait).

Hors périmètre : trous (epic 4, « un trou est une destination valide » viendra avec eux), portes fermées (epic 4), bonus de palier (3.5), danger (3.6).

## Critères d'acceptation

1. **Obstacles de l'arène** : l'arène contient quelques obstacles bas (`LowObstacles` : bloquent le joueur et les ennemis, pas les tirs) et hauts (`HighObstacles` : bloquent aussi les tirs, joueur et ennemis). Ils n'occupent aucun emplacement d'apparition (`arena_waves.tres`), ni l'apparition du joueur, ni ses abords (3 tuiles du centre).
2. **Activation** : jauge à 20 ou plus et Glissement prêt, Maj ou LB (`power_2`) : `try_spend(20, &"glide")`, téléportation vers le point visé à 6 tuiles au plus, à travers les projectiles et les obstacles bas, invulnérabilité de 0,1 s à l'arrivée, recharge de 1 s.
3. **Destination libre** : si le point visé, ou la ligne de visée, croise un mur, un obstacle haut ou un ennemi, le joueur arrive au dernier point libre sur la ligne : `intersect_ray` contre `WALLS | HIGH_OBSTACLES | ENEMIES`, puis recul jusqu'à une position où le corps du joueur ne recouvre ni mur, ni obstacle (haut ou bas), ni ennemi. Jamais hors de la salle, jamais dans un mur.
4. **Souris** : curseur à plus de 6 tuiles -> destination ramenée à 6 tuiles dans la direction du curseur ; plus près, la destination est le curseur.
5. **Manette** : la distance suit l'inclinaison du stick droit, de 2 tuiles (juste au-delà de la zone morte) à 6 tuiles (à fond), dans la direction du stick. Stick relâché au moment de l'appui : 2 tuiles dans la dernière direction de visée.
6. **Refus** : jauge sous 20, ou recharge en cours, ou trajet utile inférieur à `min_travel` (0,5 tuile) : rien n'est consommé, son de refus de 3.3. Pause : aucun effet.
7. **Données** : coût, recharge, distance maximale/minimale, invulnérabilité d'arrivée, `min_travel` dans `GlideTuning` (`Tuning.GLIDE`). Dépense journalisée comme en 3.3 (`&"glide"`).
8. **Retour** : anneau (`ring_pulse`) au départ et à l'arrivée, son de glissement, sprite du joueur teinté pendant l'invulnérabilité d'arrivée (comme `DASH_TINT`).

## Tâches

- [x] `core/glide_tuning.gd` + `data/tuning/glide_tuning.tres` (`cost` 20, `cooldown` 1.0, `max_distance` 6.0, `min_stick_distance` 2.0, `arrival_invulnerability` 0.1, `min_travel` 0.5), `Tuning.GLIDE`.
- [x] `project.godot` : `power_2` = Maj gauche (`KEY_SHIFT`) + bouton manette 9 (`JOY_BUTTON_LEFT_SHOULDER` ; le dash est sur 10).
- [x] `Arena._build_tiles()` : deux `TileMapLayer` `HighObstacles` et `LowObstacles` (physique 0 : couches `LAYER_HIGH_OBSTACLES` / `LAYER_LOW_OBSTACLES`, mêmes collisions carrées que les murs), `Z_INDEX_DECOR` ; tuiles de quelques blocs 2x2 (3 bas, 2 hauts) posées loin des emplacements ; dessin distinct (bas : plus clair et bas ; haut : sombre).
- [x] `BulletManager` du joueur et des ennemis : `setup([Walls, HighObstacles])` (les bas n'y sont pas).
- [x] `Player` : masque de collision `WALLS | ENEMIES | HIGH | LOW` ; `Enemy` : `... | HIGH | LOW` ; `Arena._is_valid_spawn` refuse une position qui recouvre une cellule d'obstacle.
- [x] `player/powers/glide.gd` (`RefCounted` + requête physique passée en paramètre, ou fonction statique pure `resolve_destination(...)`) : calcule la destination ; `Player` exécute (position, `reset_physics_interpolation()`, invulnérabilité, signaux).
- [x] `Player.is_invulnerable()` inclut l'invulnérabilité d'arrivée (compteur de ticks du groupe `PLAYER`) ; teinte.
- [x] Sons `sfx_glide.wav` ; `t_glide` ; `run_all.sh` une fois à la fin.

## État du code concerné

- `Player` : `CharacterBody2D` en `MOTION_MODE_FLOATING`, masque `WALLS | ENEMIES`. Corps de mouvement = `_hitbox` (`CollisionShape2D` `RectangleShape2D` de `PlayerTuning.hitbox_size`, 6x6 px). La hurtbox est un nœud à part. `aim_direction()`, `aim_source()` et le calcul de visée existent (`Aim`). Le curseur : `get_global_mouse_position()` ; le stick : `Input.get_vector(&"aim_left", …)`.
- `Dash` (RefCounted, ticks) est le modèle de cooldown ; en 3.3 `PowerCooldown` est factorisé. `Dash` n'est pas annulable : Glissement pendant un dash est autorisé, le dash continue depuis la nouvelle position (décision 5).
- `Arena._build_tiles()` crée `Floor` et `Walls` (nœuds de `arena.tscn` + `TileSet` construit en code, source mur = carré plein) ; `Const.LAYER_HIGH_OBSTACLES` et `LAYER_LOW_OBSTACLES` existent déjà. `arena_waves.tres` : `spawn_slots` en tuiles `(4,4) (34,4) (4,17) (34,17) (19,3) (19,18) (3,10) (35,10)` ; le joueur apparaît au centre `(19,10)` environ.
- Après 3.3 : `Player` lit `power_1` via `_update_powers()` ; ajouter `power_2` à côté, pas dans `_physics_process`.
- Plus tard : l'epic 4 remplace ces obstacles par des salles peintes (mêmes noms de nœuds) et ajoute `Pits` ; 3.5 réduit la hurtbox, pas `_hitbox` (voir 3.5) donc la géométrie de Glissement ne change pas avec le palier.

## Algorithme de destination

1. `dir` et `distance` : souris `min(|curseur - joueur|, max)` ; stick `lerp(min_stick, max, t)` avec `t = inverse_lerp(deadzone, 1, longueur du stick)` ; stick relâché `min_stick` vers la dernière visée.
2. `target = origin + dir * distance`. `intersect_ray(origin, target)` avec masque `WALLS | HIGH | ENEMIES`, `exclude = [self]`, `collide_with_areas = false` ; touche -> `target = hit_position - dir * (demi-diagonale du corps + 1 px)`.
3. Depuis `target`, reculer par pas de 1 px vers `origin` tant que `intersect_shape` (la forme du corps, masque `WALLS | HIGH | LOW | ENEMIES`, sans soi) trouve un recouvrement (au plus `distance` itérations : 96 px). Un obstacle bas sur le trajet ne bloque pas, mais on n'y atterrit pas.
4. Si `origin.distance_to(target) < min_travel` -> refus sans dépense. Sinon `try_spend`, déplacement, anneaux.

## Pièges

- `intersect_ray` / `intersect_shape` s'appellent dans `_physics_process` (état de l'espace consistant), jamais dans un `_process`. `PhysicsRayQueryParameters2D.create(from, to, mask, [rid])` ; `exclude` prend des `RID` (`get_rid()`).
- Les requêtes d'espace lisent les positions du dernier pas de physique : un ennemi poussé au même tick peut être un tick en retard (négligeable).
- Un rayon qui part depuis l'intérieur d'un corps ne le détecte pas par défaut (`hit_from_inside = false`) : sans conséquence ici, le joueur n'est jamais dans un obstacle.
- Le rayon ne voit que les formes de collision : les obstacles doivent être des tuiles avec polygone de collision (comme les murs) ; les `TileMapLayer` doivent avoir `collision_enabled` (par défaut) et une position nulle.
- Les projectiles des deux camps n'utilisent pas la physique : un obstacle haut n'arrête les tirs que s'il est dans `solid_layers` du manager ; un oubli le rendrait traversable (test explicite).
- Les ennemis avancent en ligne droite (`_move_toward`) : ils se coincent derrière un obstacle. Obstacles peu nombreux, petits, et écartés ; le contournement est un sujet d'epic 4 (`deferred`). Les `spawn_slots` ne doivent pas être derrière un obstacle haut dans l'axe d'un tireur au point de départ (à vérifier à l'oeil au playtest).
- Réinitialiser l'interpolation après la téléportation (`reset_physics_interpolation()` sur le joueur) : sinon le sprite traverse l'écran en un tick ; le reticle fils suit.
- Ne pas téléporter sur un projectile ennemi : l'invulnérabilité de 0,1 s couvre le cas ; au-delà, c'est le joueur qui choisit.
- Pause : `clock_scale <= 0` -> aucune action (comme le dash). Cooldown et invulnérabilité en ticks du groupe `PLAYER`, jamais en `Timer`.

## Vérifications prévues (`.scratch/t_glide.gd`)

- Destination (fonction pure + vraie physique d'une arène réduite) : ligne libre 6 tuiles ; curseur à 3 tuiles -> 3 ; curseur à 10 -> 6 ; mur à 2 tuiles -> arrêt contre le mur sans le recouvrir ; obstacle haut -> arrêt ; obstacle bas sur le trajet -> traversé ; destination dans un obstacle bas -> reculée devant ; ennemi sur le trajet -> arrêt devant lui ; jamais hors de la salle.
- Stick : inclinaison à peine hors zone morte -> ~2 tuiles ; à fond -> 6 ; stick relâché -> 2 vers la dernière visée.
- Jeu : jauge 100 -> 80, invulnérable 6 ticks (`is_invulnerable()`), pas de graze ni de dash parfait pendant ; recharge 60 ticks ; refus sous 20, en recharge, trajet de moins de 0,5 tuile (rien consommé) ; projectile qui recouvre l'arrivée ne touche pas pendant 6 ticks.
- Obstacles : un tir ne traverse pas un obstacle haut, traverse un obstacle bas ; le joueur et les ennemis ne traversent ni l'un ni l'autre ; aucun `spawn_slot` ni le centre recouvert ; `Arena._is_valid_spawn` refuse une cellule d'obstacle.

## Fichiers prévus

`game/core/glide_tuning.gd`, `game/data/tuning/glide_tuning.tres`, `game/core/tuning.gd`, `game/player/powers/glide.gd`, `game/player/player.gd`, `game/enemies/enemy.gd`, `game/rooms/arena/arena.gd`, `game/rooms/arena/arena.tscn`, `game/project.godot`, `game/audio/sfx/sfx_glide.wav`, `game/.scratch/t_glide.*`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Obstacles : 3 blocs bas et 2 blocs hauts de 2x2 tuiles, posés en code** (nœuds `LowObstacles` / `HighObstacles`) — Raison : l'AC demande « quelques » obstacles pour tester Glissement ; les salles réelles viennent en epic 4.
2. **Atterrissage : recul au pas de 1 px jusqu'à un point où le corps ne recouvre rien** — Raison : `intersect_ray` ne tient pas compte de la taille du corps ; ce recul garde l'AC (`intersect_ray`) et évite d'entrer dans un mur.
3. **Trajet inférieur à 0,5 tuile = refus sans dépense** — Raison : le GDD ne dit rien ; payer 20 pour ne pas bouger serait un piège.
4. **Stick relâché : 2 tuiles vers la dernière visée** — Raison : l'AC donne 2 tuiles juste au-delà de la zone morte ; c'est le minimum sûr.
5. **Glissement autorisé pendant un dash ; le dash continue depuis l'arrivée** — Raison : `Dash` n'est pas annulable et le GDD ne l'interdit pas.
6. **L'invulnérabilité d'arrivée est invulnérabilité ordinaire** (pas de graze, pas de dash parfait) — Raison : GDD : le dash parfait est celui de l'invulnérabilité du dash.
7. **Maj gauche et LB** pour `power_2` — Raison : AC de l'epic ; le dash est sur Espace et RB.
8. **Les ennemis aussi sont bloqués par les obstacles bas et hauts** — Raison : cohérence ; ils ne contournent pas (limite connue, epic 4).

9. **Atterrissage : `Glide.resolve_destination` est une fonction statique pure** (espace physique, forme du corps et exclusions passés en paramètres) ; `Player._try_glide` exécute. Le trajet utile est mesuré après le recul, avant la dépense : un refus ne consomme rien. – Raison : testable sans scène, et c'est l'option que la story laissait ouverte.
10. **Stick : la longueur renvoyée par `Input.get_vector` (zone morte 0,2 déjà retirée et rééchelonnée) sert de `t`** ; un stick à peine hors zone morte donne donc environ 2 tuiles (2,25 mesurées avec 0,25 d'axe). Stick actif au moment de l'appui = stick ; sinon, si la dernière source de visée est le stick, 2 tuiles vers la dernière visée ; sinon souris. – Raison : suit exactement le code de visée existant.
11. **Obstacles : deux `TileSet` distincts** (un par couche de collision, la couche physique d'un `TileSet` étant unique), blocs en code (`LOW_OBSTACLE_CELLS`, `HIGH_OBSTACLE_CELLS` dans `Arena`). `_is_valid_spawn` refuse tout corps qui recouvre une cellule d'obstacle ; conséquence : un ennemi à corps géant (cas de `t_invalid23`) ne peut plus apparaître tant que les obstacles existent, le test les vide pour ce cas. – Raison : AC 1 ; le cas géant est artificiel.
12. **Anneaux de Glissement** : rayon 1 tuile, 0,25 s, au départ et à l'arrivée (constantes visuelles placeholders dans `Arena`, via le nouveau `_add_ring`) ; F3 affiche aussi « Glide n% ». – Raison : AC 8 ne donne pas de valeurs.

## Dev Agent Record

### Agent Model Used

### Completion Notes

### File List

### Agent Model Used

Agent : Claude Sonnet 5.5 (dev-story, mode lean).

### Completion Notes

- Toutes les tâches faites. `GlideTuning` (`Tuning.GLIDE`), `power_2` (Maj gauche + LB, bouton 9), `Glide` (distance et destination, fonctions statiques pures), `Player._try_glide()` appelé depuis `_update_powers()` : `try_spend(20, &"glide")`, téléportation, `reset_physics_interpolation()`, recharge `PowerCooldown` de 1 s, invulnérabilité d'arrivée de 6 ticks (`is_arrival_invulnerable()`, incluse dans `is_invulnerable()` : pas de graze, pas de dash parfait ; teinte `DASH_TINT`), signal `glided(from, to)` -> deux `RingPulse` dans `Arena`. Son `sfx_glide.wav` généré (provisoire, 7.7). Aucune chaîne joueur.
- Arène : nœuds `HighObstacles` / `LowObstacles` (3 blocs bas, 2 hauts de 2x2), masques du joueur et des ennemis étendus, `BulletManager`s : `[Walls, HighObstacles]`, `_is_valid_spawn` refuse les cellules d'obstacle.
- Vérifications : `t_glide` (48 ok) ajoutée à `run_all.sh` ; `t_awakening` (tir de test déplacé hors d'un bloc) et `t_invalid23` (obstacles vidés pour le cas du corps géant) adaptés ; `run_all.sh` en mode normal : ALL PASS (916 ok) ; `--quit-after 120` propre.
- NON ÉVALUÉ (humain) : sensation de Glissement (distance, recharge d'1 s, invulnérabilité de 0,1 s), lisibilité des anneaux, teinte et son provisoires, disposition des obstacles et ennemis qui s'y coincent (limite connue, epic 4), manette réelle (stick droit : 2 à 6 tuiles, LB).

### File List

Nouveaux : `game/core/glide_tuning.gd`, `game/data/tuning/glide_tuning.tres`, `game/player/powers/glide.gd`, `game/audio/sfx/sfx_glide.wav` (+ `.import`, `.uid`).
Modifiés : `game/core/tuning.gd`, `game/project.godot`, `game/player/player.gd`, `game/enemies/enemy.gd`, `game/rooms/arena/arena.gd`, `game/rooms/arena/arena.tscn`, `game/debug/perf_overlay.gd`.

### Change Log

- 2026-11-24 : implémentation de la story 3.4 (Glissement), passée en review.

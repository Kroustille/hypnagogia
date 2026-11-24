# Story 4.4 : Jouer avec la salle : meubles et éléments déclenchables

Status: done

## Story

En tant que joueur,
je veux des meubles qui arrêtent les tirs et des éléments à déclencher d'un tir,
afin de me servir de la salle comme d'une arme.

Exigences : FR41 (epics.md, Story 4.4). GDD : « Jouer avec la salle » (meubles 30 PV, lampe : 3 tuiles, 1 s). Architecture : couches `furniture` et `triggers`, `Hurtbox`, `HitPoints`, règle « Resources en lecture seule ».

**Dépend de : 4.2** (marqueurs `Furniture` et `Trigger`, créés vides, `RoomValidator`, outil ASCII) ; 4.3 (salle de test sans trous suffit, mais le validateur d'accessibilité s'applique aux meubles). Touche les mêmes classes que la 4.5 (grille de chemin) : la 4.5 lit l'état des meubles par `Furniture.destroyed`.

Hors périmètre : les autres éléments déclenchables (un seul : la lampe), sons et sprites définitifs (7.x), objets qui exploitent les meubles (epic 5).

## Critères d'acceptation

1. **Meuble** : un marqueur `Furniture` (`def: FurnitureDef`, position en tuiles) crée à l'entrée de la salle un corps solide (`StaticBody2D`, `LAYER_FURNITURE`, rectangle de `def.size` tuiles) avec les `PV` de `def.max_hp` (30 pour lit, chaise, pupitre ; `FurnitureDef` en `.tres` dans `data/furniture/`, lecture seule). Visuel provisoire : rectangle coloré par genre.
2. **Il arrête les projectiles des deux camps** : un tir du joueur et un tir ennemi qui le touchent disparaissent, et le meuble perd les PV du coup (dégâts de la balle ; 1 demi-cœur d'un tir ennemi vaut 1 PV). Un meuble ne touche personne.
3. **Il bloque les corps** : joueur, ennemis et Glissement (rayon et recul) le traitent comme un obstacle haut. Les masques de collision du joueur et des ennemis, `Glide` et la validité d'une apparition (`_overlaps_obstacle`) en tiennent compte.
4. **Destruction** : à 0 PV le meuble est détruit : signal `destroyed`, corps et hurtboxes désactivés, plus rien ne bloque (tirs, corps, Glissement), visuel retiré (provisoire : disparition). Les tirs en vol dans le même tick ne le touchent plus.
5. **Lampe** : un marqueur `Trigger` de genre `LAMP` (réglages dans `Tuning.ROOM` : `lamp_radius_tiles` = 3, `lamp_dazzle_duration` = 1 s) est touché par un tir **du joueur** (les tirs ennemis la traversent) : les ennemis vivants à moins de 3 tuiles (centre à centre) sont éblouis 1 s. Le tir est consommé. La lampe ne se déclenche qu'une fois par salle (visuel « éteint » ensuite, tirs suivants ignorés).
6. **Ébloui** : l'ennemi n'avance pas, ne tire pas et ne commence aucune attaque ; son télégraphe en cours est **annulé** (`Telegraph.cancel()`, nouveau : plus d'attaque à venir, le visuel d'annonce disparaît, une ligne `Log.debug`) ; l'attaque en cours (accélération du Somnambule, charge du Mouton) s'arrête. Il reprend ensuite son état de départ (poursuite, repos). Son contact reste actif (le contact n'est pas une attaque, GDD). Le compte à rebours suit `GameClock` (groupe ENEMIES).
7. **Renfort et lampe** : un ennemi pas encore apparu n'est pas ébloui ; un renfort annoncé continue de paraître.
8. **Validateur** : refuse un `Furniture` sans `def`, hors zone jouable, sur un mur ou un trou, qui chevauche un autre meuble ou un obstacle, ou qui coupe l'accessibilité d'une porte ou d'un `EnemySpawn` (le meuble compte comme obstacle dans le flood fill de la 4.3, vu qu'il est destructible mais ne doit pas être indispensable à détruire pour sortir) ; refuse un `Trigger` sans genre.
9. **Salle de test** `onset_combat_005` : lit, chaise, pupitre, une lampe, deux vagues.

## Tâches

- [x] `FurnitureDef`, `data/furniture/{bed,chair,desk}.tres`, `RoomTuning` (lampe), `Furniture` (marqueur → corps + `HitPoints` + deux `Hurtbox`), `Trigger` (marqueur → `Hurtbox` + logique lampe), `Const` : masques inchangés (les couches existent).
- [x] Deux `Hurtbox` par meuble : `camp = ENEMY` inscrite au `BulletManager` du joueur, `camp = PLAYER` inscrite à celui des ennemis (`register_hurtbox` refuse le même camp). Les deux écoutent `damage_received` et appliquent à un seul `HitPoints`. La lampe n'a que la hurtbox ENEMY.
- [x] Masques : `Player.collision_mask`, `Enemy.collision_mask`, `Glide` (rayon et requête de forme) gagnent `LAYER_FURNITURE` ; `Sheep.STUNNING_LAYERS` : le meuble arrête la charge comme un obstacle bas (sans étourdissement, la 4.5 décide des hauts).
- [x] `Telegraph.cancel()`, `Enemy.dazzle(seconds)`, `Enemy.is_dazzled()`, point d'entrée `_tick_dazzle()` appelé en tête du `_physics_process` de chaque sous-classe (Somnambule, Veilleuse, Berceuse, Mouton), `_on_dazzled()` surchargé : `_enter(<état de départ>)` (la règle `.scratch` n'autorise l'écriture de `_state` que dans `_enter`).
- [x] Enregistrement des meubles et lampes à l'entrée de salle, après les `BulletManager` (ordre d'`Arena._ready`). `Room.enemies_within(point, radius_px)` (ennemis vivants du nœud `Enemies`).
- [x] Salle `onset_combat_005` (ASCII) ; validateur (critère 8).
- [x] Tests GUT : `tests/integration/rooms/test_furniture.gd` (tir joueur, tir ennemi, 30 PV, destruction, déblocage, Glissement), `test_lamp.gd` (portée exacte, une fois, télégraphe annulé, éblouissement 1 s en ticks, contact actif, tir ennemi sans effet), `tests/unit/combat/test_telegraph_cancel.gd`, validateur.

### Review Findings

Revue complète (3 couches) du 2026-11-24 sur `d411e2c..c3ca891`. Numéros de ligne à `c3ca891` (un correctif de la 4.3 touche le validateur en parallèle). 22 constats après dédoublonnage : 4 actions (3 constats), 5 reportés, 14 écartés.

- [x] [Review][Patch] **Commentaire et nom de test faux sur les tirs du tick de destruction** [`game/rooms/furniture.gd:127`, `game/tests/integration/rooms/test_furniture.gd:72`] : `BulletManager` lit `is_hittable()` une fois par tick (`_refresh_target_rects`), donc les autres tirs du même manager qui touchent le meuble dans le tick de sa destruction sont consommés sans effet (le test l'affirme : « all 31 shots were consumed »). Remplacer « (bullets of this very tick pass through) » par « (HP drop no further; shots of this very tick already tested by a BulletManager are still consumed, as for an enemy: from the next tick on they pass through) » et renommer le test en `test_the_30th_hit_destroys_it_once_and_the_shots_of_that_tick_are_consumed`. Décision R1.
- [x] [Review][Patch] **Une lampe éteinte absorbe un second tir du même tick** [`game/rooms/markers/trigger.gd:43`] : même cause ; critère 5 (« tirs suivants ignorés »). Après `hurtbox.camp = BulletManager.Camp.ENEMY`, ajouter `hurtbox.one_hit_per_tick = true` (la lampe ne se déclenche qu'une fois : les tirs suivants du tick passent). Test : deux tirs du joueur sur la lampe au même tick → `player_bullets().active_count == 1` après le tick.
- [x] [Review][Patch] **Le validateur ne vérifie ni `def.size` ni `def.max_hp`** [`game/rooms/validator/room_validator.gd:257-259`] : une taille < 1 donne zéro case (`_cells_of`), la pièce passe toutes les règles puis `Furniture._ready()` fait `assert(false)` ; `max_hp <= 0` fait asserter `HitPoints`. Après le test `def == null` : `if piece.def.size.x < 1 or piece.def.size.y < 1: problems.append("%s has an invalid size" % label); continue` et `if not (is_finite(piece.def.max_hp) and piece.def.max_hp > 0.0): problems.append("%s has invalid max_hp" % label)`.
- [x] [Review][Patch] **Empreinte du validateur ≠ empreinte du jeu hors centre de tuile** [`game/rooms/validator/room_validator.gd:257`, `:297`] : `_cells_of` prend `floor(position / 16)`, `Furniture.footprint_rect()` part de `position - 8` ; un marqueur déplacé à la main sur un coin de tuile (snap de l'éditeur) couvre `size + 1` cases en vrai et peut chevaucher mur, porte ou marqueur sans être signalé. Dans `_check_furniture`, après le test de def : `var half: float = Const.TILE_SIZE / 2.0` ; `if not is_equal_approx(fposmod(piece.position.x, Const.TILE_SIZE), half) or not is_equal_approx(fposmod(piece.position.y, Const.TILE_SIZE), half): problems.append("%s is not on a tile center" % label); continue`.
- [x] [Review][Defer] **Point d'entrée du joueur non vérifié contre les meubles** [`game/rooms/validator/room_validator.gd`] — reporté à la 4.8 (le point `player_entry_distance` n'est vérifié contre aucun bloqueur, déjà vrai avant).
- [x] [Review][Defer] **`destroyed` émis avant la coupure différée du corps ; passages d'une tuile** [`game/rooms/furniture.gd:141`, `room_validator.gd` `_check_reachability`] — reporté à la 4.5.
- [x] [Review][Defer] **Le son d'un télégraphe annulé n'est pas coupé** [`game/combat/telegraph.gd`] — reporté à l'epic 7 (audio).
- [x] [Review][Defer] **La lampe de `onset_combat_005` est loin de tout point d'apparition** [`game/rooms/pool/onset/onset_combat_005.tscn`] — reporté au playtest / 4.10.

Correctifs appliqués (4 patchs) et vérifiés : GUT 159/159, validateur sur le pool OK, `run_all.sh` ALL PASS.

## État du code concerné

- `BulletManager` ne connaît que des cellules de `TileMapLayer` (solides) et des `Hurtbox` enregistrées (cibles rectangulaires, un tir touche au plus une cible, dans l'ordre d'enregistrement) : un meuble est donc une cible, pas une couche solide.
- `Hurtbox.receive()` émet `damage_received(info)` ; `HitPoints.apply_damage(amount)` (flottants) ; `Enemy._on_hurtbox_damage_received` est le modèle. `Events.enemy_damaged` part pour les hurtbox ENEMY (chiffres de dégâts) : un meuble ENEMY-camp afficherait un chiffre ; le garder (feedback) ou le refuser par `refuse_hit()` : on le garde pour la hurtbox du meuble côté joueur.
- `Telegraph` n'a ni annulation ni état (`_ticks_left`) hors `start` ; `Enemy._start_telegraph_of()` ; les sous-classes écrivent leurs états dans `_enter` seulement.
- `Arena._overlaps_obstacle(rect)` filtre les apparitions ; il lit les couches `HighObstacles` et `LowObstacles` : y ajouter les rectangles de meubles vivants.
- Aucun ennemi n'a de notion d'attaque interrompue avant cette story (deferred-work 2.4/2.5 : « `Telegraph` sans annulation »).

## Pièges

- Un meuble détruit pendant la boucle de tests du `BulletManager` : ne pas se désinscrire dans `damage_received` (la boucle livre les coups après les tests, `_deliver_hits()`) ; désactiver par `set_deferred` / `process_mode` et laisser `tree_exiting` désinscrire.
- `StaticBody2D.collision_layer`/`CollisionShape2D.disabled` se modifient en différé pendant un tick de physique : `set_deferred("disabled", true)`.
- `Hurtbox.is_hittable()` : un meuble détruit doit répondre faux immédiatement (filtre `set_hit_filter(func() -> bool: return not hp.is_dead())`), comme les ennemis.
- Le rayon de Glissement et la requête de forme utilisent des masques en dur dans `glide.gd` : oublier un des deux laisse le joueur apparaître dans un meuble.
- La poursuite directe d'un ennemi derrière un meuble est bloquée : c'est le sujet de la 4.5, pas de contournement ici.
- `Telegraph.cancel()` pendant le tick de l'ennemi : l'ennemi lit `is_active()` dans son état TELEGRAPH et ferait passer à l'état suivant : `_on_dazzled()` doit repasser en `_enter(CHASE/REST)` dans le même appel.

## Fichiers prévus

`rooms/furniture.gd/.tscn`, `rooms/markers/trigger.gd`, `core/furniture_def.gd`, `data/furniture/*.tres`, `core/room_tuning.gd`, `combat/telegraph.gd`, `enemies/enemy.gd` + les quatre ennemis, `player/player.gd`, `player/powers/glide.gd`, `rooms/room.gd`, `rooms/validator/room_validator.gd`, `rooms/pool/onset/onset_combat_005.tscn`, `tests/**`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Un coup ennemi vaut 1 PV sur un meuble** (le dégât de la balle, en demi-cœurs) : le GDD ne chiffre que les 30 PV.
2. **Le meuble bloque les corps comme un obstacle haut** et arrête la charge du Mouton sans l'étourdir.
3. **La lampe ne réagit qu'aux tirs du joueur** et les tirs ennemis la traversent (le GDD dit « un tir » ; le but est « jouer avec la salle »).
4. **Contact actif pendant l'éblouissement** (règle de télégraphe du GDD : le contact n'est pas une attaque).
5. **Reprise à l'état de départ** après l'éblouissement, pas à l'état interrompu.
6. **La lampe n'est pas détruite** et ne coupe pas les tirs au-delà de leur consommation.
7. **Meubles obligatoires à détruire interdits** par le validateur : une salle ne peut pas exiger de les casser.
8. **Portée de la lampe inclusive** : un ennemi à exactement 3 tuiles (centre à centre) est ébloui (`<=`), le GDD dit « moins de 3 tuiles » sans trancher la borne.
9. **Pose d'un meuble** : le marqueur est le centre de la tuile en haut à gauche, la pièce couvre `size` tuiles vers la droite et le bas (lit 3×2, chaise 1×1, pupitre 2×1 : tailles provisoires, le GDD ne les donne pas).
10. **Éblouissement** : l'ennemi ébloui est teinté de jaune (provisoire) ; le minuteur de tir des tireurs est gelé pendant l'éblouissement ; un Mouton étourdi est ramené au repos par l'éblouissement ; la lampe n'a ni corps ni PV, sa hurtbox refuse le coup (pas de chiffre de dégâts) ; les meubles affichent un chiffre de dégâts aux tirs du joueur (feedback gardé).
11. **Arrêt de la charge du Mouton** : aucun changement de `STUNNING_LAYERS` ; toucher le meuble termine déjà la charge sans étourdir (collision non « étourdissante »).
12. **Salles de test** : `onset_combat_005` plus des fixtures `furniture_*`/`trigger_no_kind` ; les lignes `furniture none` et `trigger none` du constructeur ASCII servent aux fixtures (pièce sans def, déclencheur sans genre).
13. **R1 (revue) : critère 4 « les tirs en vol dans le même tick ne le touchent plus »** : lu comme « les PV ne baissent plus et les tirs des ticks suivants passent ». Les autres tirs du même `BulletManager` dans le tick de destruction restent consommés (limite connue du manager, la même que pour un ennemi tué) ; un budget de coups par hurtbox coûterait plus qu'il ne rapporte (quelques balles perdues sur 30 PV). La lampe, elle, passe en `one_hit_per_tick` (un seul déclenchement).

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Completion Notes

- `FurnitureDef` (`core/furniture_def.gd`, `data/furniture/{bed,chair,desk}.tres`, 30 PV) ; `Furniture` construit à l'entrée un `StaticBody2D` sur `LAYER_FURNITURE`, un `HitPoints` et deux `Hurtbox` (ENEMY pour les tirs du joueur, PLAYER pour ceux des ennemis) qui écrivent dans le même `HitPoints` ; destruction : signal `destroyed`, `is_destroyed()`, désactivations différées, filtre de coup immédiat.
- Masques : `Player`, `Enemy`, `Glide` (rayon et requête de forme) ; `Room._overlaps_obstacle` compte les meubles vivants.
- `Trigger` (lampe) : hurtbox ENEMY seule, une fois par salle, `Room.enemies_within()` ; réglages `Tuning.ROOM.lamp_radius_tiles` / `lamp_dazzle_duration`.
- `Telegraph.cancel()`, `Enemy.dazzle()/is_dazzled()/_tick_dazzle()/_on_dazzled()` ; les quatre ennemis appellent `_tick_dazzle` en tête de `_physics_process` et reviennent à leur état de départ.
- Validateur : meuble sans def, hors zone, sur mur/obstacle/trou, chevauchement, accessibilité (le meuble bloque le flood fill), marqueur sur un meuble, déclencheur sans genre ou de genre inconnu.
- Vérifications : `tools/run_tests.sh` 127 + 10 nouveaux tests GUT verts ; `tools/validate_rooms.sh` 5 salles valides ; `run_all.sh` : ALL PASS en mode normal (aucune scène scratch ajoutée : les nouvelles vérifications sont en GUT).
- NON ÉVALUÉ (humain) : lisibilité de l'éblouissement (teinte jaune provisoire, pas de son), équilibre de `onset_combat_005`, ressenti des meubles comme couvert (30 PV, 1 PV par demi-cœur).

### File List

`core/furniture_def.gd`, `data/furniture/*.tres`, `core/room_tuning.gd`, `data/tuning/room_tuning.tres`, `rooms/furniture.gd`, `rooms/markers/trigger.gd`, `rooms/room.gd`, `rooms/validator/room_builder.gd`, `rooms/validator/room_validator.gd`, `rooms/pool/onset/onset_combat_005.tscn`, `art_source/rooms/onset_combat_005.txt`, `combat/telegraph.gd`, `enemies/enemy.gd` + les quatre ennemis, `player/player.gd`, `player/powers/glide.gd`, `tests/**` (test_furniture, test_lamp, test_telegraph_cancel, test_room_validator_furniture, fixtures).

### Change Log

- 2026-11-24 : implémentation de la story 4.4 (meubles, lampe, éblouissement, validateur, salle `onset_combat_005`).
- 2026-11-24 : revue de code (3 couches) : 4 actions, 5 reportés, décision R1 ; statut `in-progress`.

# Story 5.10 : Affronter son reflet : le Miroir

Status: in-progress

## Story

En tant que joueur,
je veux un objet qui double mon tir, mais fait parfois surgir mon reflet hostile,
afin de payer ma puissance en affrontant mon propre build.

Exigences : FR52, AR15 (`BuildCarrier` sur une autre entité) (epics.md, Story 5.10). Architecture : P5 (le reflet reçoit une copie des `ItemDef` dans son propre `Loadout`, tire par le `BulletManager` ennemi, apparence dédiée), flux `combat`.

**Dépend de : 5.1** (`BuildCarrier`, `REAR_SHOT`, `ItemCatalog`), **5.9** (`room_fight_started`, `fire_hold`), 2.4 (ennemi tireur, `Telegraph`), 3.7 (précédent d'un tirage `combat` dans la salle). Les effets des autres objets (5.6) doivent refuser un porteur qui n'est pas le joueur.

Hors périmètre : Toi (acte 1), cohabitation reflet + présence d'On te regarde (question ouverte du GDD).

## Critères d'acceptation

1. **Miroir** (`data/items/mirror.tres`, tags Regard, `modifiers` : `REAR_SHOT +1`) : quand le joueur tire, un **second tir part vers l'arrière** (direction opposée à la visée). Le motif de tir est calculé par `ShotPattern.directions(aim, stats) -> Array[Vector2]` (`combat/shot_pattern.gd`, pur) que `Player._fire()` appelle : un tir sans Miroir donne `[aim]`, avec Miroir `[aim, -aim]`. Chaque balle du motif passe par `BulletManager.fire` avec les mêmes `BulletParams` ; un seul son, un seul recul. Si le pool refuse la balle arrière, la balle avant part quand même.
2. **Apparition** : à `room_fight_started(room)` d'une salle de combat (`COMBAT`, pas `is_nightmare()`, première apparition de la vague, salle non vidée), si le joueur porte le Miroir, un tirage du flux `combat` (`stream(COMBAT, floor_index)`, `randi_range(0, 3) == 0`, **toujours un seul tirage**) décide si un reflet hostile apparaît, soit 1 salle sur 4 en moyenne. Jamais dans la salle d'un cauchemar, ni dans une salle vidée, ni dans le départ, le trésor, la boutique. Le reflet apparaît par `Room.spawn_enemy(def, position, prepare)` (seul chemin) à 3 tuiles ou plus du joueur (règle existante de `spawn_enemy`).
3. **Le reflet** (`enemies/reflection/reflection.tscn/.gd`, `ReflectionDef` hérite d'`EnemyDef`/`ShooterDef`, `data/enemies/reflection.tres`) : 60 PV (`max_hp`) multipliés par le facteur d'étage (`FloorDef.hp_factor`, 1,0 pour l'Endormissement, passé par `RoomOptions`). Il porte un `BuildCarrier` qui **reçoit une copie des `ItemDef` du joueur** (`Loadout.copy_defs()`) : ses propres `StatBlock` et `Loadout` ; les modificateurs de stats s'y appliquent (par exemple vitesse de déplacement −20 % avec Jambes de plomb), et le Miroir y donne le tir arrière. Les `effect_script` qui ne déclarent pas `supports_non_player()` ne sont **pas** attachés (Ailes, Chute libre, synergies) ; la Dent n'enlève pas de cœurs au reflet ; le reflet ne porte ni consommable, ni objet actif, ni armure.
4. **Tir** : il tire par le `BulletManager` **ennemi** de la salle : balles à la couleur et au contour ennemis (`Const.COLOR_ENEMY_BULLET` et contour, apparence existante), dégâts d'un tir ennemi standard (½ cœur), motif = `ShotPattern.directions(visée vers le joueur, stats du reflet)` : il tire donc aussi vers l'arrière s'il porte le Miroir. Pas de traversée : le motif reprend le nombre et les directions, pas le `PIERCE` (une balle ennemie qui traverse le joueur est hors de propos).
5. **Télégraphe** : chacune de ses attaques est précédée d'un télégraphe d'au moins 0,4 s (`Telegraph`, minimum de `Tuning.COMBAT.min_telegraph`, même sous Abandon avec `telegraph_mult` 0,85).
6. **Comportement en données** : `ReflectionDef.movement` (enum `STILL`, `KEEP_DISTANCE`, `MIRROR_PLAYER`) et `preferred_distance`, `move_speed`, `fire_interval` sont dans `reflection.tres`, réglables pour le playtest. Défaut : `KEEP_DISTANCE`.
7. **Fin de salle** : le reflet compte comme un ennemi de la salle (`_alive`) : la salle n'est vidée qu'après sa mort. `room_cleared` utilise le `lowest_tier` habituel. Il ne laisse pas de drop propre.
8. **Pools** : le Miroir est ajouté aux pools trésor et boutique ; clés `strings.csv` (nom, bonus « un second tir part vers l'arrière », coût « dans 1 salle de combat sur 4, un reflet hostile apparaît »).
9. **Débogage** : F1 force l'apparition du reflet dans la salle courante (touche `M`), sans tirage.

## Tâches

- [x] `combat/shot_pattern.gd` ; `Player._fire()` boucle sur le motif ; `Player._on_stat_changed` ignore `REAR_SHOT` (lu au tir).
- [x] `BuildCarrier` utilisable sans `Player` : `setup(stats)` et `host: Node` (le `Player` ou le reflet) ; `ItemEffect.supports_non_player()` (faux par défaut) ; `Loadout.copy_defs()`, `Loadout.add_def_for_copy()`.
- [x] `enemies/reflection/*`, `data/enemies/reflection.tres`, `ReflectionDef`, `FloorDef.hp_factor` (+ `onset.tres`), `RoomOptions.hp_factor`, `Room.spawn_enemy(def, requested, prepare: Callable = Callable())` : `prepare` est appelé entre `enemy.setup()` et `add_child()` (donne la copie d'objets et le facteur).
- [x] `Room` : à `fight_started`, tirage `combat` et apparition (écouteur différé : `call_deferred`, pas dans la boucle de `begin_room`).
- [x] Télégraphe : réutiliser `Enemy._start_telegraph_of` ; son placeholder de télégraphe propre au reflet est autorisé.
- [x] `strings.csv`, F1, tests.

## État du code concerné

- `Player._fire()` : une seule balle (`_bullets.fire(_shot_params, origine locale, _aim.direction)`), puis recul et son ; `_shot_params` reconstruit par `equip_bullets`.
- `ShooterEnemy` : cycle de tir, `_fire_volley()` éventail de `bullet_count` balles ; `ShooterDef` (`bullet_speed`, `bullet_count`, `spread_angle`, `fire_interval`) ; apparence ennemie via `EnemyBulletLook` ; la danger de salle règle vitesse de balle et télégraphe.
- `Room.spawn_enemy(def, requested)` : `enemy.setup(def, _player, _player.hurtbox, _enemy_bullets, danger, _nav)` avant `add_child`, `_alive += 1`, signal `tree_exited` ; `_maybe_schedule_reinforcement()` est le précédent d'un tirage `combat` pour un ennemi supplémentaire.
- 5.9 : `fight_started`, `fire_hold`, `pace_mult` (le reflet en profite comme tout ennemi) ; 5.1 : `Loadout`, `BuildCarrier` ; 5.6 : effets liés au `Player`.
- `FloorDef` n'a pas de facteur d'étage (aucun n'existe : le GDD le cite sans le définir).

## Pièges

- `spawn_enemy()` depuis `fight_started` : le signal part de `begin_room()` appelé par le `WaveRunner` pendant sa propre logique ; ne pas créer d'ennemi en synchrone dans l'écouteur, différer (`call_deferred`) et vérifier que la salle est encore valide et active.
- Le flux `combat` est partagé avec le renfort d'Abandon (3.7) : le tirage du reflet ne doit pas être **conditionnel** à autre chose que le Miroir porté et le type de salle, sinon deux joueurs de même seed divergent. Un seul `randi_range` par salle éligible, toujours consommé.
- Une `ItemDef` copiée dans le reflet ne partage pas ses `OwnedItem` avec le joueur (sinon `clear_source` croisé) : `Loadout.copy_defs()` renvoie des `ItemDef`, pas des `OwnedItem`.
- `BuildCarrier` du reflet est libéré avec lui : tous ses effets `detach` à la sortie de l'arbre ; pas de signal du joueur connecté au reflet (aucun effet attaché).
- La balle arrière du joueur part vers un mur proche : `BulletManager.fire` peut refuser l'origine dans un mur ; ne pas faire échouer le tir avant ; le recul et le son ne dépendent que de la balle avant.
- Le reflet a un `Hurtbox` ennemi comme les autres : à enregistrer auprès de `_player_bullets` par `spawn_enemy` (déjà le cas).
- 60 PV × facteur : valeur flottante ; `HitPoints` accepte les flottants.

## Tests

- `unit/combat/test_shot_pattern.gd` : sans Miroir un tir, avec Miroir deux directions opposées, `PIERCE` ignoré pour un motif ennemi.
- `unit/items/test_loadout_copy.gd` : copie d'`ItemDef` sans partage de sources, Dent sans effet sur les cœurs du reflet, effets non supportés non attachés.
- `unit/enemies/test_reflection_def.gd` : `reflection.tres` valide, 60 PV, `hp_factor` appliqué, comportement lu des données.
- `integration/items/test_mirror_reflection.gd` : un tir de joueur Miroir produit 2 balles ; sur 400 salles simulées avec une seed fixe, environ 100 reflets (tolérance), jamais en cauchemar ni en salle vidée ; le reflet tire par le manager ennemi avec un télégraphe ≥ 0,4 s ; la salle ne se vide pas tant qu'il vit ; mêmes seed et mêmes choix = mêmes salles à reflet.

## Sources

epics.md (Story 5.10) ; GDD ligne Miroir et note de design ; architecture P5 (« le reflet du Miroir reçoit une copie des `ItemDef` du joueur ») ; deferred-work (`spawn_enemy` / `room_cleared`).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Facteur d'étage = `FloorDef.hp_factor`** (1,0 pour l'Endormissement), aucun n'étant défini ailleurs ; à régler avec l'équilibrage des étages.
2. **« Motif des tirs » = nombre et directions** (`ShotPattern`), pas la traversée ni la vitesse ; les dégâts sont ceux d'un tir ennemi.
3. **Seuls les modificateurs de stats et les effets marqués `supports_non_player()` s'appliquent au reflet** ; la Dent ne retire pas de cœur au reflet.
4. **Le reflet doit être tué pour vider la salle** (il est un ennemi de la salle) ; pas de drop propre.
5. **Tirage 1 sur 4 à `fight_started`** (apparition au début du combat, pas à l'entrée), un seul tirage `combat` par salle éligible.
6. **Comportement de déplacement par `enum` de données** (`STILL`, `KEEP_DISTANCE`, `MIRROR_PLAYER`) pour le playtest.
7. **`spawn_enemy` reçoit un `prepare: Callable` facultatif** pour garder `setup()` avant `add_child()` (architecture).
8. **`BuildCarrier.setup_host(host, stats)` en plus de `setup(player, stats)`** (au lieu de changer la signature de `setup`, utilisée par les tests et le joueur) : le porteur d'un reflet n'a ni joueur, ni `TagTracker` (donc ni synergie ni bannière), et son `_physics_process` compte en temps `ENEMIES`.
9. **`Loadout.add_def_for_copy` ne garde l'effet que s'il `supports_non_player()`** (sinon l'instance est jetée) ; aucun effet existant ne le déclare. Le Miroir n'a pas de script : ses modificateurs suffisent.
10. **La salle attend le reflet pour passer à la vague suivante** : le `WaveRunner` ne voit la salle vidée (`emptied`) qu'à `_alive == 0`, reflet compris. Voulu par l'AC 7, noté pour le playtest.
11. **Position d'apparition = point opposé au joueur par rapport au centre de la salle** (aucun tirage de position : un seul tirage `combat` par salle) ; `spawn_enemy` corrige la distance.
12. **Le tirage vit dans `ReflectionSpawner`** (`rooms/reflection_spawner.gd`, écoute `Room.fight_started`) plutôt que dans `room.gd` ; `Room.spawn_reflection()` sert à F1 (touche `M`). Pas de salle « Miroir » à construire : l'histoire n'en demande pas (`validate_rooms.sh` : 34 salles valides).
13. **Tag du Miroir : `gaze`** (Regard, comme Être nu en public). Réglages du `.tres` (à tester en jeu) : `KEEP_DISTANCE`, 5 tuiles, vitesse 2, cadence 2 s, télégraphe 0,5 s.
14. **Revue — reflet borné à la vue de la caméra** (patch 1) : dans les 8 salles larges/hautes (ex. `onset_combat_007`, 72 tuiles de large, vue de 40), le point opposé au joueur tombe hors écran ; le reflet y télégraphie et tire hors de vue pendant ~30 s (marche à 2 t/s). Choix : garder le point opposé de la décision 11, mais le ramener dans la vue (moins la bande du HUD), comme le renfort 3.7 préfère un repère visible.
15. **Revue — touche F1 du reflet : `N` au lieu de `M`** (patch 2) : le panneau lit `physical_keycode` ; en AZERTY, la touche physique `M` est la virgule. `N` est au même endroit sur les deux claviers et libre (panneau et `InputMap`).
16. **Revue — copie du build prise à l'apparition, pas suivie en direct** : un objet pris pendant le combat ne change pas le reflet déjà là. Gardé (l'AC 3 parle d'une copie ; plus simple, aucun signal du joueur vers le reflet).

### Review Findings

Revue de code (2026-11-24, Opus, trois couches en sous-agents parallèles : Blind Hunter, Edge Case Hunter, Acceptance Auditor) sur `f4e5ea4..ca50abf`. L'auditeur a lancé les cinq fichiers GUT de la story : 24/24, 87 assertions. Vérifiés sans défaut : tir du joueur inchangé (cadence, recul et son sur la balle avant seule ; la balle arrière reprend `_shot_params`, donc la traversée ; « avant refusée, arrière acceptée » impossible : tout refus de `BulletManager.fire` ignore la direction ; frôlement et dash parfait ne concernent que les balles ennemies) ; copie du build (`copy_defs` sans l'actif, `add_def_for_copy` crée ses propres `OwnedItem` sur le `StatBlock` du reflet, aucune fuite de stats, `Health` ou signal vers le joueur, ni consommable, ni armure, ni prix en cœurs, aucun effet existant ne déclare `supports_non_player()`, détache à la sortie de l'arbre, horloge `ENEMIES`) ; contact 0,875 > 0,625 + 0,125 ; balles par le manager ennemi (seul le hurtbox du joueur y est inscrit), ½ cœur, sans traversée ; télégraphe 0,5 × 0,85 = 0,425 s, plancher `min_telegraph` ; `hp_factor` seulement sur le reflet ; un seul `randi_range` par salle éligible, après le tirage du renfort, `fight_started` une fois par instance de salle ; apparition différée revérifiée (salle libérée : l'appel différé tombe avec le `ReflectionSpawner`), mort du joueur : rien ; `fire_hold` posé avant l'apparition ; position corrigée par `_is_valid_spawn` (murs, trous, obstacles) ; `strings.csv` et pools.

- [ ] [Review][Patch] Reflet hors écran dans les grandes salles [`game/rooms/reflection_spawner.gd:61`, `game/rooms/room.gd:552-555`] — extraire le rectangle de vue de `_pick_reinforcement_position` dans `Room.visible_rect_local() -> Rect2` (`_camera.position - Vector2(Const.VIEWPORT) / 2.0 + Vector2(0.0, Const.HUD_BAND_HEIGHT)`, taille `Vector2(Const.VIEWPORT) - Vector2(0.0, Const.HUD_BAND_HEIGHT)`), l'utiliser dans `_pick_reinforcement_position`, et dans `spawn()` après `requested` : `var view: Rect2 = _room.visible_rect_local(); var inset: Vector2 = Vector2.ONE * Const.TILE_SIZE; requested = requested.clamp(view.position + inset, view.end - inset)` (`spawn_enemy` garde les 3 tuiles et les cases valides). Test : salle WIDE, joueur à l'entrée ouest, le reflet apparaît dans la vue.
- [ ] [Review][Patch] Touche F1 `M` inaccessible en AZERTY [`game/debug/debug_panel.gd:107`, `:440`, `:180`] — `KEY_M:` → `KEY_N:` ; aide : `"N spawn the hostile reflection (Mirror, no draw)"` ; supprimer la troisième ligne vide avant `_spawn_reflection`.
- [ ] [Review][Patch] Journal de volée faux pour le reflet (« reflection fired 2/1 ») [`game/enemies/shooter_enemy.gd:101`, `:104`] — `var directions: Array[Vector2] = _volley_directions(aim)` avant la boucle, `for direction: Vector2 in directions:`, et loguer `[_def.id, fired, directions.size()]`.
- [ ] [Review][Patch] Test instable `test_blank_exam_adds_one_drop_laid_beside_the_first` (5.9) [`game/tests/integration/economy/test_loot_flow.gd:172`] — cause confirmée : la seed du run est aléatoire, sans ennemi tué les drops sont posés au milieu de la salle (`Room.last_kill_position()`), là où se tient le joueur, qui ramasse aussitôt une ½ armure, des Éclats ou un consommable ; seul un ½ cœur (refusé à pleine vie) reste. Le test ne passe que si tous les types tirés sont `HALF_HEART` (23 échecs sur 30 lancers). Correctif, avant `await _clear(0)` : `_player.global_position = Vector2(-500, -500)` puis `await _harness.ticks(2)` (déplacer sans attendre ne suffit pas : 13 échecs sur 15 ; avec les 2 ticks : 0 sur 12, copie jetable vérifiée).

## Dev Agent Record

### Notes de complétion

- `ShotPattern.directions` partagé ; `Player._fire` boucle sur le motif (recul et son suivent la balle avant seule). `REAR_SHOT` existait déjà dans `StatBlock`.
- `Reflection` (`ShooterEnemy`, hook `_volley_directions`), `ReflectionDef`, `FloorDef.hp_factor` -> `RoomOptions.hp_factor` -> `Enemy.hp_factor` ; `Room.spawn_enemy(..., prepare)`.
- Tests GUT : `unit/combat/test_shot_pattern`, `unit/items/test_loadout_copy`, `unit/enemies/test_reflection_def`, `integration/items/test_mirror_reflection`, `unit/ui/test_item_strings`.
- NON ÉVALUÉ (humain) : sensation du reflet (distance, cadence, lisibilité du placeholder violet), équilibre 60 PV, 1 salle sur 4.
- Observation : `test_loot_flow::test_blank_exam_adds_one_drop_laid_beside_the_first` échoue par intermittence (seed de run aléatoire), sans lien avec 5.10.

### Liste des fichiers

`combat/shot_pattern.gd`, `player/player.gd`, `items/{build_carrier,loadout,item_effect}.gd`, `data/items/mirror.tres`, `data/pools/*.tres`, `enemies/{enemy,shooter_enemy}.gd`, `enemies/reflection/*`, `data/enemies/reflection.tres`, `rooms/{room,room_options,reflection_spawner}.gd`, `generation/floor_def.gd`, `data/floors/onset.tres`, `run/run.gd`, `debug/debug_panel.gd`, `localization/strings.csv`, tests ci-dessus.

### Journal des modifications

- 2026-11-24 : implémentation de la story 5.10.

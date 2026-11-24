# Story 5.10 : Affronter son reflet : le Miroir

Status: ready-for-dev

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

- [ ] `combat/shot_pattern.gd` ; `Player._fire()` boucle sur le motif ; `Player._on_stat_changed` ignore `REAR_SHOT` (lu au tir).
- [ ] `BuildCarrier` utilisable sans `Player` : `setup(stats)` et `host: Node` (le `Player` ou le reflet) ; `ItemEffect.supports_non_player()` (faux par défaut) ; `Loadout.copy_defs()`, `Loadout.add_def_for_copy()`.
- [ ] `enemies/reflection/*`, `data/enemies/reflection.tres`, `ReflectionDef`, `FloorDef.hp_factor` (+ `onset.tres`), `RoomOptions.hp_factor`, `Room.spawn_enemy(def, requested, prepare: Callable = Callable())` : `prepare` est appelé entre `enemy.setup()` et `add_child()` (donne la copie d'objets et le facteur).
- [ ] `Room` : à `fight_started`, tirage `combat` et apparition (écouteur différé : `call_deferred`, pas dans la boucle de `begin_room`).
- [ ] Télégraphe : réutiliser `Enemy._start_telegraph_of` ; son placeholder de télégraphe propre au reflet est autorisé.
- [ ] `strings.csv`, F1, tests.

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

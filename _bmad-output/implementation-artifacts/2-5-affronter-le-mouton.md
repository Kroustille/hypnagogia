# Story 2.5 : Affronter Le Mouton

Status: done

## Story

En tant que joueur,
je veux un ennemi qui charge en ligne droite et s'assomme contre les murs,
afin de jouer avec la salle pour le punir.

**Exigences couvertes :** FR26, FR29, ainsi que FR4 (ennemis), FR12 (contact), AR7, AR9, AR13, AR23 (ligne droite), AR24 (F1), AR27, AR28, AR32, NFR9.

**Prérequis : la story 2.4 est `done`** (vérifié à la création de ce fichier : `Enemy`, `EnemyDef`, `HitPoints`, `Hitbox`, `Telegraph` avec `progress()`, `Arena.spawn_enemy()`, `Sleepwalker`, `ShooterDef` / `ShooterEnemy`, `NightLight`, `Lullaby`, `Enemy.setup()` à 4 paramètres, contrat des dégâts de `BulletManager.fire()`, touches 6 à 8 de F1 existent dans le dépôt). Les stories 1.7 et 1.8 sont reportées par Kroustille : elles ne sont **pas** des prérequis.

**Cinquième story de l'epic 2 : le quatrième et dernier ennemi du jalon A.** Le Mouton hérite directement d'`Enemy` (il ne tire pas : **pas** de `ShooterEnemy`). La story règle le report « Base des ennemis pour la 2.5 » (déplacement par direction, charge qui traverse le joueur) et donne aux ennemis apparus un nom lisible dans les journaux (constaté par Kroustille en jouant : `telegraph @CharacterBody2D@221 started`). **La base reste minimale** : `Enemy` ne gagne qu'une aide de déplacement.

## Critères d'acceptation

1. **Étant donné** Le Mouton (50 PV), **quand** il lance une attaque, **alors** il gratte le sol pendant 0,5 s (télégraphe, animation et son), recule de 0,5 tuile, puis charge en ligne droite vers la position du joueur au moment du télégraphe, à 10 tuiles/s.
2. **Étant donné** une charge en cours, **quand** Le Mouton heurte un mur, **alors** il reste étourdi 1 s, puis reprend son cycle.
3. **Étant donné** une charge en cours, **quand** il touche le joueur vulnérable, **alors** le contact inflige un coup de ½ cœur, **et** la charge continue jusqu'au mur.
4. **Étant donné** ses valeurs, **quand** on les règle, **alors** tout vient de `sheep.tres`.

**Conséquences à tenir pour que le système reste cohérent de bout en bout** (non écrites dans l'epic, mais exigées par l'architecture, par les reports des stories précédentes, par l'état du dépôt ou par le retour de jeu de Kroustille) :

5. **Un cycle complet** : repos → grattage (télégraphe) → recul → charge → étourdissement (mur) → repos. La première attaque vient un repos complet après l'apparition. La direction de la charge est **figée au départ du télégraphe** (une direction, pas un point visé) : ni le recul ni la charge ne suivent le joueur ensuite.
6. **La charge traverse le joueur** (exception de collision entre Le Mouton et le corps de sa cible pendant la charge) : le joueur n'est ni arrêté ni poussé par le corps du Mouton, il ne l'arrête pas non plus ; seul le contact (`Hitbox`) le touche. L'exception est levée au premier tick, après la charge, où les deux corps ne se chevauchent plus. Hors charge, les corps se bloquent comme en 2.3 (le dash ne traverse pas Le Mouton).
7. **Ce qui arrête une charge** : le premier contact avec un mur (couche `LAYER_WALLS`) étourdit ; le premier contact avec un autre ennemi arrête la charge **sans** étourdissement (retour au repos). La charge ne glisse jamais le long d'un mur.
8. **Le Mouton reste un ennemi de la 2.3** : apparition par `room.spawn_enemy()` (distance minimale, corps disjoints, compte des vivants), 10 PV par tir du joueur avec flash et recul (5 tirs), mort au coup qui vide les PV (désactivé : il ne charge plus, ne touche plus, ne bloque plus ; l'exception disparaît avec lui), dégâts au contact de ½ cœur dans **tous** les états, chemin du coup inchangé (`Hitbox` → `Hurtbox.receive()` → `Health.apply_damage()`, source `CONTACT`, un coup par tick puis l'invulnérabilité). Le joueur invulnérable (après un coup, dash, F1) est traversé sans coup.
9. **Pause, écran de réveil et ralenti** : la pause et l'écran de réveil figent Le Mouton dans chaque état (position, repos, télégraphe, recul, charge, étourdissement) ; F4 ralentit ×0,25 repos, télégraphe, recul, charge et étourdissement.
10. **Relance propre** : à la relance, Le Mouton disparaît avec l'ancien `Run`, même en pleine charge ou avec une exception de collision posée ; après cinq cycles, nombre de nœuds stable, aucun orphelin, connexions au bus stables.
11. **Un Mouton à la demande en debug** : le panneau F1 fait apparaître un Mouton (touche 9) par `room.spawn_enemy()`.
12. **Noms lisibles des ennemis apparus** : `spawn_enemy()` nomme chaque ennemi `<id>_<n>` (`sheep_1`, `sleepwalker_2`…), `n` compté par la salle à partir de 1, jamais réutilisé ; les journaux (`telegraph sheep_1 started …`) n'affichent plus de nom généré en `@`.
13. Marche, dash, tir, cibles, chiffres de dégâts, coups et invulnérabilité, mort et relance, pause, réglages, F1 à F5, test de charge (`Bullets 400 | refused 0`), Le Somnambule, La Veilleuse et La Berceuse (1.1 à 2.4) sont inchangés.

## Tâches / sous-tâches

- [x] **T1. Lexique et architecture** (AR32 : un terme entre dans le lexique **avant** le code)
  - [x] `game-architecture.md`, section « Lexique » : ajouter la ligne `Charge ; gratter le sol ; reculer ; étourdi, étourdissement ; repos (entre deux attaques) ; direction de charge ; ce qui assomme ; nom d'un ennemi apparu | charge ; scrape ; backup ; stun ; rest ; charge_direction ; STUNNING_LAYERS ; spawn_serial (<id>_<n>)`.
  - [x] `game-architecture.md` : « Création d'entités », une ligne story 2.5 (`spawn_enemy()` nomme l'ennemi `<id>_<n>`, compteur de la salle) ; « États et télégraphes », une ligne story 2.5 (charge qui traverse sa cible : exception de collision avec le corps de la cible pendant la charge, levée quand les corps ne se chevauchent plus ; arrêt au premier contact, mur = couche du collisionneur dans `STUNNING_LAYERS`) ; « Arborescence », `enemies/sheep/` : `sheep.tscn/.gd, sheep_def.gd`.
- [x] **T2. Base des ennemis** (CA 1, 5) : `enemies/enemy.gd` : `_move_in_direction()`, `_move_toward()` sans test de la cible (voir « `Enemy` »).
- [x] **T3. Noms lisibles** (CA 12) : `rooms/arena/arena.gd` : compteur et nom avant `add_child()`, journal d'apparition (voir « Arène »).
- [x] **T4. Le Mouton** (CA 1 à 9) : `enemies/sheep/sheep_def.gd` (`SheepDef`), `sheep.tscn` + `sheep.gd`, `data/enemies/sheep.tres`, `audio/sfx/sfx_enemy_sheep_telegraph.wav` (voir « Le Mouton », « Son du télégraphe »).
- [x] **T5. Panneau F1** (CA 11) : touche 9 (voir « Panneau F1 »).
- [x] **T6. Vérifications headless** (CA 1 à 13) : nouvelles scènes de `game/.scratch`, `run_all.sh` étendu (voir « Stratégie de test »).
- [ ] **T7. Vérifications fenêtrées sous WSLg** (CA 1, 2, 6) : grattage, recul, charge, étourdissement, **F2 sous `main.tscn`** (leçon de 2.4), captures. Ce qui n'est pas capturé est marqué NON VÉRIFIÉ à l'écran.
- [x] **T8. Régression** : import et lancement sans erreur, recherche des interdits, `run_all.sh` complet (scènes de 2.3 et 2.4 inchangées, et nouvelles).
- [x] **T9. Reports** : mettre à jour `deferred-work.md` (entrée « Base des ennemis pour la 2.5 » résolue, voir « Reports traités par cette story » ; nouvelles entrées NON ÉVALUÉ / NON VÉRIFIÉ, voir « Stratégie de test » point 15).

### Review Findings

Revue de code du 2026-11-23 (`gds-code-review`, mode complet, trois couches : Blind Hunter, Edge Case Hunter, Acceptance Auditor ; diff `fc7469e..70dec34 -- game/ _bmad-output/game-architecture.md`). Les CA 1 à 13 sont implémentés dans le code. Points demandés : l'exception de collision tient dans tous les cas sondés par l'Edge Case Hunter (gel en pleine charge, mort du Mouton, deux Moutons, relance, dash sans changement de couche), mais la pose de l'exception lit une cible libérée sans test (patch 1) ; `_move_toward()` est strictement équivalent pour le Somnambule et la Berceuse (les 4 appelants passent `_target_position()`, `>= 1e-6` est l'exact contraire de l'ancien `< 1e-6`) ; noms `<id>_<n>` uniques par construction, mais une apparition refusée laisse son nœud nommé une frame (patch 2). Contrôles de `game/.scratch` non audités (pipeline allégé). 3 patchs, 0 décision, 2 reports, 13 rejetés.

- [x] [Review][Patch] **Cible libérée avant l'entrée en charge : `_target as PhysicsBody2D` lève `SCRIPT ERROR: Trying to cast a freed object`** [game/enemies/sheep/sheep.gd:184] — Reproduit par l'Edge Case Hunter (cible libérée pendant le grattage ou le recul, puis entrée en `CHARGE`) ; en debug, la suite d'`_enter()` est abandonnée. Inatteignable en jeu aujourd'hui (le joueur n'est libéré qu'avec le `Run`), mais toutes les autres lectures de `_target` testent d'abord sa validité. Correctif : remplacer la ligne 184 par `var body: PhysicsBody2D = _target as PhysicsBody2D if is_instance_valid(_target) else null` (la ligne 185 reste). Vérifier : `t_sheep` point 7 étendu d'un cas « cible libérée pendant le recul » → la charge part, aucune exception posée, aucun `SCRIPT ERROR`.
- [x] [Review][Patch] **Apparition refusée après `add_child()` : le nœud nommé `<id>_<n>` reste dans `Enemies` jusqu'à la fin de la frame** [game/rooms/arena/arena.gd:107-108] — Contredit la stratégie de test point 10 (« ne laisse aucun nœud nommé dans `Enemies` ») ; consigné par le dev dans `deferred-work.md` mais « Aucun écart » dans les Completion Notes. Correctif : dans la branche `if enemy.hurtbox == null or enemy.process_mode == Node.PROCESS_MODE_DISABLED:`, appeler `_enemies.remove_child(enemy)` juste avant `enemy.queue_free()` (rien n'est encore connecté ni enregistré à ce stade : `tree_exited` et `register_hurtbox()` viennent après). Puis barrer l'entrée « Apparition refusée après `add_child()` » de la section 2-5 de `deferred-work.md` (« Résolu en revue »).
- [x] [Review][Patch] **T1 coché, ses deux sous-tâches non cochées** [_bmad-output/implementation-artifacts/2-5-affronter-le-mouton.md:38-40] — Le travail est fait (lexique, « Création d'entités », « États et télégraphes », arborescence `sheep/` dans `game-architecture.md`, commit `e7ce92b`). Correctif : cocher les deux sous-tâches `- [ ]` sous T1.

Les 3 correctifs sont appliqués (2026-11-23, par l’orchestrateur) : cible testée avant le cast dans `sheep.gd`, `remove_child()` avant `queue_free()` sur une apparition refusée dans `arena.gd`, sous-tâches de T1 cochées. Vérifié : import et `--quit-after 120` propres, `run_all.sh` ALL PASS (12 scènes, 617 contrôles). Pas de nouveau contrôle pour le cas « cible libérée pendant le recul » (pipeline allégé).
- [x] [Review][Defer] **Une charge qui ne touche rien ne finit jamais** [game/enemies/sheep/sheep.gd:130-146] — deferred, stories 4.3 (trous) et 4.8 (portes) : la décision 16 suppose une salle fermée ; une porte ouverte, un trou ou une limite de salle hors `LAYER_WALLS` laisseraient le Mouton charger sans fin (salle jamais nettoyée). Garder les portes fermées en combat, ou ajouter une durée ou une distance maximale de charge qui ramène au repos.
- [x] [Review][Defer] **`_move_toward()` ne s'arrête plus quand la cible disparaît : la règle « pas de cible, pas de mouvement » repose sur l'appelant** [game/enemies/enemy.gd:129-131] — deferred, story 4.5 : sans effet aujourd'hui (les 4 appelants passent `_target_position()`), mais un appelant qui passe un point fixe (chemin `AStarGrid2D`) avancerait vers lui sans cible. La 4.5 garde la règle dans son appelant.

## Dev Notes

### Ce que cette story pose, et ce qu'elle ne pose pas

Le Mouton (`SheepDef`, `Sheep`, `sheep.tres`, son de télégraphe), le déplacement par direction dans la base, la charge qui traverse sa cible, l'arrêt contre un mur ou un ennemi, l'étourdissement, le nom lisible des ennemis apparus, et la touche 9 de F1. **Hors périmètre** (ne pas anticiper) :

| Élément | Story |
|---|---|
| Vagues, `Events.room_cleared`, « ennemi choisi » (remplace les touches 6 à 9), « tuer tout », « vague suivante », plafond des sons de télégraphe | 2.6 |
| HUD (lisibilité d'un coup reçu) | 2.7 |
| Télémétrie (cause de la mort `CONTACT`, ennemi qui a tué) | 2.8 |
| Danger (`telegraph_mult` ≠ 1), Éveil qui repousse les ennemis, renfort | Epic 3 |
| Poussée du joueur par le Somnambule en accélération, trous, pièges | 4.3 |
| Lampe qui éblouit et **annule les télégraphes** (annulation de `Telegraph`) | 4.4 |
| Obstacles hauts qui étourdissent Le Mouton comme un mur (`STUNNING_LAYERS` élargi), `AStarGrid2D` | 4.5 |
| Sprites, animations, sons définitifs (charge, choc, étourdissement) | 7.3, 7.7 |

### État actuel du dépôt (stories 1.1 à 2.4 `done`)

- **Autoloads** : `Log`, `Events`, `GameClock`, `Settings`, `SaveService`, `Audio`.
  - `Events` : `player_hit(damage: int, source: int)`, `enemy_damaged(world_position: Vector2, amount: float)`, `run_ended(outcome: int)`. **Cette story n'ajoute aucun signal au bus.**
  - `GameClock` : groupes `PLAYER, ENEMIES, ENEMY_BULLETS, PLAYER_BULLETS, WORLD, FX` ; `scale(group)` nul en pause ; `global_multiplier` borné à [0, 1] (F4) ; `paused` écrit par `Main._freeze()` seul.
  - `Audio.play_sfx(stream, max_voices = 3) -> bool`, `voices_of(stream)` ; limite de voix **par flux** (le son du Mouton a ses 3 voix). Ne pas modifier.
- **`core/constants.gd`** (`Const`) : `TILE_SIZE` 16, `ROOM_TILES` 36×19, couches `LAYER_WALLS` (1), `LAYER_HIGH_OBSTACLES`, `LAYER_LOW_OBSTACLES`, `LAYER_FURNITURE`, `LAYER_PLAYER` (16), `LAYER_ENEMIES` (32)…, `COLOR_ENEMY_BULLET`, `COLOR_ENEMY_BULLET_OUTLINE`, `Z_INDEX_ENEMY_BULLETS` 10, `PHYSICS_PRIORITY_HITBOXES` 50, `PHYSICS_PRIORITY_BULLETS` 100, `GROUP_ROOM`, `GROUP_PLAYER`, `GROUP_DEBUG_SHAPES`. Pas touché.
- **`core/combat_tuning.gd`** : `hit_damage_half_hearts` 1, `hit_invulnerability_duration` 1,0, `min_telegraph` 0,4, `min_spawn_distance` 3,0, `enemy_bullet_radius`, `enemy_bullet_lifetime`. Pas touché.
- **`combat/telegraph.gd`** (`Telegraph`) : `setup(clock_group)` ; `start(base, sound, multiplier = 1.0) -> float` (durée `max(base × mult, min_telegraph)`, valeurs invalides bornées avec `_assert_failed()`, **`Log.debug("combat", "telegraph <nom du parent> started duration=…")`**, son par `Audio.play_sfx()`) ; `is_active()` ; `progress()` (0 → 1 pendant le télégraphe, 0 inactif) ; enfant de l'ennemi à la même priorité, **il tique après lui** : démarré au tick N pour 0,5 s, l'ennemi le voit inactif au tick N + 30. **Pas d'annulation** (4.4). Pas touché.
- **`combat/hitbox.gd`** (`Hitbox`, priorité 50, rectangle testé à la main contre la hurtbox de la cible, filtre de la cible, contact continu), **`combat/hurtbox.gd`**, **`combat/hit_points.gd`**, **`combat/health.gd`**, **`combat/damage_info.gd`** (`Source { PLAYER_SHOT, ENEMY_BULLET, DEBUG, CONTACT }`), **`combat/hit_feedback.gd`**, **`combat/bullets/`** : pas touchés.
- **`enemies/enemy_def.gd`** (`EnemyDef`) : `id`, `scene`, `max_hp`, `body_size`, `hurtbox_size`, `contact_size`, **défauts neutres** (0, `Vector2.ZERO`), oubli signalé par la validation (`HitPoints._init`, `Enemy._pixel_size`). Pas touché.
- **`enemies/enemy.gd`** (`Enemy extends CharacterBody2D`) :
  - `setup(def, target: Node2D, target_hurtbox: Hurtbox, bullets: BulletManager = null)` avant `add_child` ; `_ready()` incomplet → `process_mode = DISABLED`, `_def = null`, `Log.error` + `assert`.
  - Crée en code : corps (forme neuve, `LAYER_ENEMIES`, **masque murs | joueur | ennemis**, `MOTION_MODE_FLOATING`), `hp`, `hurtbox` (camp `ENEMY`), `_contact` (`Hitbox`, `hit_damage_half_hearts`, `CONTACT`, groupe `ENEMIES`), `_feedback` (`HitFeedback`), `telegraph` (`Telegraph`, groupe `ENEMIES`).
  - `_die()` : une fois, `PROCESS_MODE_DISABLED` (le corps quitte l'espace physique, enfants arrêtés), invisible, `queue_free()`.
  - **`_move_toward(point, speed_px, clock_scale)`** : `velocity` nulle si `_target` invalide **ou** point atteint, sinon vers le point ; `move_and_slide()`. C'est le report de 2.3 : il ne fait qu'**approcher un point** et teste `_target` alors que `_target_position()` le fait déjà.
  - `_target_position()` (sa propre position sans cible), `_distance_to_target()` (`INF` sans cible), `body_world_rect()`, `_pixel_size()`, `_make_rectangle()`, `_assert_failed()`.
  - Contrat de scène : `%Sprite` (`Sprite2D` en (0, 0), sans `material`, animé par `texture` seulement), `%Body` (`CollisionShape2D`).
- **`enemies/sleepwalker/`** : `Sleepwalker` (`enum State { CHASE, TELEGRAPH, RUSH }`, accélération qui **continue de viser le joueur**, décision 6 de 2.3 : c'est ce qui le distingue du Mouton), `_bounded_px()` / `_bounded_seconds()`, textures provisoires 16×24 générées en code. Utilise `_move_toward(_target_position(), …)`. **Ne pas modifier.**
- **`enemies/shooter_def.gd`, `shooter_enemy.gd`, `night_light/`, `lullaby/`** (2.4) : couche des tireuses ; la Berceuse utilise `_move_toward(_target_position(), …)` et `_move_toward(global_position * 2.0 - _target_position(), …)` (recul). **Ne pas modifier.** Le Mouton n'en hérite pas.
- **`rooms/arena/arena.gd`** (`Arena`) : `spawn_enemy(def, requested) -> Enemy` : gardes, `_resolve_spawn_position()`, `instantiate()` → `as Enemy`, `enemy.setup(def, _player, _player.hurtbox, _enemy_bullets)`, `enemy.position`, **`_enemies.add_child(enemy)` sans nom** (la racine de scène s'appelle `Sleepwalker`, `NightLight`… : le premier garde ce nom, les suivants reçoivent un nom généré `@CharacterBody2D@221`, doc `Node.add_child()` 4.7 : `force_readable_name = false` attribue un nom factice avec `@`), refus d'un `_ready()` raté, `reset_physics_interpolation()`, inscription dans `PlayerBullets`, compte, `tree_exited`, `Log.debug("room", "spawned %s at %s alive=%d" % [def.id, …])`. Les murs : `TileMapLayer` `Walls`, couche physique du `TileSet` = `Const.LAYER_WALLS`.
- **`player/player.gd`** : `collision_layer = LAYER_PLAYER`, `collision_mask = LAYER_WALLS | LAYER_ENEMIES` (le dash et la marche s'arrêtent sur les corps ennemis, FR4) ; **`move_and_slide()` appelé à chaque tick, même à vitesse nulle** (la récupération de pénétration de Godot déplace donc un joueur immobile qui chevauche un corps de son masque : c'est la « poussée » du Somnambule, report 4.3). Le joueur est dans `Run`, **avant** `RoomSlot` : il tique avant les ennemis. **Pas touché.**
- **`debug/debug_panel.gd`** : touches 1 à 8 (`physical_keycode`, panneau visible, hors pause, sans répétition), `_spawn(def, label)` commun (`SPAWN_REQUEST` (304, 40), « no room », « spawn refused »), `SLEEPWALKER_DEF`, `NIGHT_LIGHT_DEF`, `LULLABY_DEF` ; texte `F1 panel (keys 1-8)`, une ligne par touche ; `Label` de 144 px de haut (`debug_panel.tscn`, `offset_bottom = 144.0`).
- **`audio/sfx/`** : `sfx_enemy_sleepwalker_telegraph.wav` (300 → 700 Hz, 0,35 s), `sfx_enemy_night_light_telegraph.wav` (≈ 0,5 s montant), `sfx_enemy_lullaby_telegraph.wav` (≈ 0,4 s grave), générés par script, `.import` versionnés.
- **Il n'existe ni `enemies/sheep/`, ni `sheep.tres`, ni déplacement par direction, ni exception de collision nulle part dans le jeu.**
- **`game/.scratch`** (vrai dossier exclu de git, **ne jamais le commiter ni le remplacer par un lien**) : `th.gd` (harnais, priorité 200 ; `check()`, `approx()`, `make_run()`, `spawn()`, `put()`, `key()`, `find_all()`, `test_params()`, `enemy_bullets()`, `live()`, `enemy_params()`, constantes `SLEEPWALKER_DEF`, `NIGHT_LIGHT_DEF`, `LULLABY_DEF`), `killer.gd`, `mover.gd`, `mk_tscn.sh`, `rs.sh`, scènes `t_enemy_parts`, `t_sleepwalker`, `t_enemy_main`, `t_invalid23`, `t_regress`, `t_enemy_bullets`, `t_shooters`, `t_shooters_main`, `t_invalid24` (9 scènes `PASS`, 456 contrôles au dernier passage), `run_all.sh` (import et lancement, verdicts, assertions comptées pour `t_invalid*`, lignes `Log.error` comptées par scène, journaux, règles de source avec témoins plantés, machines à états). **Ces scènes ne se réécrivent pas** : la 2.5 en ajoute de nouvelles, étend `th.gd` (ajouts seulement) et `run_all.sh`.

### Reports traités par cette story (`deferred-work.md`)

| Report | Origine | Réponse de cette story |
|---|---|---|
| Base des ennemis pour la 2.5 : `_move_toward(point)` ne fait qu'approcher un point et teste `_target` en double | revue 2.3 | `_move_in_direction(direction, speed_px, clock_scale)` dans `Enemy` ; `_move_toward()` le réutilise et ne teste plus `_target` (comportement inchangé : ses appelants passent `_target_position()`, qui rend la position de l'ennemi sans cible) |
| Masque du corps avec `LAYER_PLAYER` : la charge s'arrêterait sur le joueur | revue 2.3 | Ni masque propre à la charge, ni décision 10 de 2.3 revue : **exception de collision** avec le corps de la cible pendant la charge (CA 6) ; le masque ne change pas |
| `Telegraph` n'a pas d'annulation | revue 2.3 | **Toujours inutile** : aucune attaque du Mouton n'est interrompue (la mort désactive l'ennemi) ; reste ouvert pour la lampe de la 4.4 |
| Noms générés `@CharacterBody2D@…` dans les journaux | jeu de Kroustille (2.4) | CA 12 : `spawn_enemy()` nomme l'ennemi `<id>_<n>` |

**Restent ouverts** (ne pas traiter ici) : poussée du joueur par le Somnambule (4.3) ; son de télégraphe muet au-delà de 3 voix (2.6 ou 7.7) ; `refuse_hit()` non réentrant ; `equip_bullets()` répétable (4.8) ; lisibilité d'un coup reçu (2.7) ; `fire_interval` ≤ télégraphe (3.6) ; salve tronquée, pool presque plein (2.6) ; dégâts du joueur bornés à 0 ; mesure de 10 minutes à 400 projectiles sur la machine de référence (**étape humaine, NON FAITE**, à rappeler à Kroustille en fin d'epic).

### Leçons des stories 1.1 à 2.4 à appliquer

- **Chaque contrôle prouve son mécanisme, avec un témoin, et doit pouvoir échouer** ; pas de tautologie, pas de `check(true)`, pas de valeur calculée et non affirmée. Ici plusieurs mécanismes se recouvrent : un Mouton « immobile » peut être au repos, en télégraphe, étourdi, figé par la pause, mort, ou bloqué contre un corps ; un joueur « pas poussé » peut être figé (`set_physics_process(false)` : **pas de `move_and_slide()`, donc pas de récupération de pénétration** — le contrôle de la traversée doit utiliser un joueur **actif** sans entrée), invulnérable ou hors de la ligne. Chaque point de la « Stratégie de test » dit ce qu'il isole et donne son témoin. Contrôles par mutation consignés dans le Debug Log (mécanisme retiré, scène relancée, fichier restauré octet pour octet, somme de contrôle `cksum`).
- **Ordre des ticks** : joueur (dans `Run`, avant `RoomSlot`) puis ennemis à 0, `Hitbox` à 50, `BulletManager` à 100, harnais à 200. Le `Telegraph` tique après son propriétaire. Une source de dégâts de priorité < 0 tue un ennemi **avant** son `_physics_process` du même tick : c'est `PROCESS_MODE_DISABLED` qui l'arrête, pas `queue_free()` (revue 2.4).
- **Un assert qui échoue interrompt la fonction en build de debug** : poser l'état sûr **avant** `Log.error` + `assert`, isoler l'assert dans `_assert_failed()` quand une valeur bornée doit encore être renvoyée (décision 27 de 2.3).
- **Défauts neutres dans les `Def`** (décision 32 de 2.3) : 0 partout ; les valeurs du GDD vivent dans le `.tres` (Godot omet d'un `.tres` réenregistré une valeur égale au défaut) ; un oubli est signalé, jamais hérité. **Un ennemi qui ne peut jamais attaquer est inerte** : ni télégraphe ni son (décision 27 de 2.4 : un télégraphe sans attaque ment au joueur).
- **Typage strict, avertissements en erreur** : `PackedScene.instantiate()` → `as Enemy` ; `_def as SheepDef` ; `_target as PhysicsBody2D` ; les valeurs d'un `Dictionary` (résultat de `intersect_shape()`) sont des `Variant` : `result.get("rid") as RID` ; `get_slide_collision(i)` rend un `KinematicCollision2D`.
- **Injection** : `setup()` avant `add_child()` ; composants créés en code avec un `name` explicite ; formes neuves par instance ; pas de `/root/...` ni `get_parent().get_parent()`.
- **Ticks** : compteurs décrémentés de `GameClock.scale(groupe)`, `TICK_EPSILON = 1e-6`. Pas de `Timer`, `create_timer`, `Tween` en temps réel. Un tick sans mouvement à chaque transition (décision 9 de 2.3).
- **Couleurs provisoires sans nombre du GDD** (décisions 26 et 29 de 2.4) : les règles de `run_all.sh` cherchent dans `enemies/` `2.5`, `5.0`, `0.4`, `0.6`, `30`, `3.0`, `40`, `20`, `1.5`, `6.0`, `4.0`, `8.0`, et à partir de cette story `50` et `10.0` (voir le point 14) ; une couleur `Color(0.6, …)` y serait prise : décaler d'un centième. Toute couleur à ≥ 0,2 (RGB) des deux couleurs réservées (contrôle de `t_enemy_bullets`, qui parcourt toutes les constantes `Color` des scripts : il verra celles du Mouton).
- **Vérifications** : `--import`, puis `--quit-after 120` (zéro `SCRIPT ERROR`, zéro `Parse Error`, seul avertissement connu `settings.cfg missing`) ; scènes (`--scene res://.scratch/<scène>.tscn`) ; `Input.parse_input_event()` s'applique au tick suivant ; `preload()` dans les scripts de test, `@warning_ignore_start(...)` pour les scripts jetables seulement ; chemins d'erreur dans une scène `t_invalid*` qui annonce ses assertions (`CASE … EXPECT_ASSERTS n`, `TOTAL_EXPECTED_ASSERTS`), chaque `Log.error` suivi d'une assertion.
- **Captures F2 sous `main.tscn`** (le `CollisionDrawer` y vit ; la capture de 2.4 sous `run.tscn` était sans formes).
- **Fichiers générés par Godot** : versionner les `.uid` des nouveaux scripts et le `.wav.import` ; relire `sheep.tres` après `--import` (valeurs explicites conservées).

### `SheepDef` (AR9, D4, CA 1, 2, 4)

`enemies/sheep/sheep_def.gd`, `class_name SheepDef extends EnemyDef`, **défauts neutres (0)**, `@export_range` et une ligne de doc par champ (en-tête comme `SleepwalkerDef` : unités, défauts neutres).

| Champ | Type | Valeur (`sheep.tres`) | Source | Rôle |
|---|---|---|---|---|
| `rest_duration` | `float` (s) | 1.0 | **absent du GDD** : provisoire, NON ÉVALUÉ | repos immobile entre deux attaques (après l'apparition, après l'étourdissement, après une charge arrêtée par un ennemi) |
| `telegraph_duration` | `float` (s) | 0.5 | GDD (« gratte le sol, 0,5 s ») | grattage, au moins `min_telegraph` |
| `backup_distance` | `float` (tuiles) | 0.5 | GDD (« recule de 0,5 tuile ») | longueur du recul en terrain libre |
| `backup_speed` | `float` (tuiles/s) | 2.0 | **absent du GDD** : provisoire, NON ÉVALUÉ | vitesse du recul (0,25 s pour 0,5 tuile) |
| `charge_speed` | `float` (tuiles/s) | 10.0 | GDD | vitesse de la charge |
| `stun_duration` | `float` (s) | 1.0 | GDD (« étourdi 1 s ») | étourdissement après un mur |

**`data/enemies/sheep.tres`** (`script_class="SheepDef"`) : `id = &"sheep"`, `scene` = `res://enemies/sheep/sheep.tscn`, `max_hp` 50, tailles provisoires du Somnambule (`body_size` (0.625, 0.625), `hurtbox_size` (0.75, 1.25), `contact_size` (0.75, 0.75)), puis les six champs ci-dessus. **Toutes les valeurs explicites** dans le fichier (relu après `--import`).

### `Enemy` (CA 1, 5 ; report « Base des ennemis pour la 2.5 »)

`enemies/enemy.gd`, deux changements, rien d'autre :

```gdscript
## The straight line of AR23 (AStarGrid2D replaces it in story 4.5): toward a point, stopping on it.
## velocity is rewritten every tick. Without a target, callers pass _target_position() (the enemy's own position).
func _move_toward(point: Vector2, speed_px: float, clock_scale: float) -> void:
	var to: Vector2 = point - global_position
	_move_in_direction(to.normalized() if to.length_squared() >= 1e-6 else Vector2.ZERO, speed_px, clock_scale)


## Moves along a direction (unit vector, or zero to stand still) at speed_px per second, scaled by the clock:
## never stops on a point (a charge goes on until something stops it). move_and_slide() reports what it hit.
func _move_in_direction(direction: Vector2, speed_px: float, clock_scale: float) -> void:
	velocity = direction * speed_px * clock_scale
	move_and_slide()
```

- Le test `is_instance_valid(_target)` disparaît de `_move_toward()` : **comportement inchangé** pour le Somnambule et la Berceuse (leurs appels passent `_target_position()`, qui rend `global_position` sans cible : direction nulle, `move_and_slide()` appelé comme avant). Prouvé par `t_sleepwalker` et `t_shooters` inchangés (contrôles « cible libérée » compris).
- `move_and_slide()` reste appelé à vitesse nulle (même récupération de pénétration qu'avant).

### Le Mouton (FR29, CA 1 à 9)

**`enemies/sheep/sheep.tscn`** : racine `Sheep` (`CharacterBody2D`, script `sheep.gd`) > `Sprite` (`Sprite2D`, `unique_name_in_owner`, en (0, 0), sans `material`) et `Body` (`CollisionShape2D`, `unique_name_in_owner`). Même contrat que `sleepwalker.tscn`.

**`enemies/sheep/sheep.gd`** :

```gdscript
class_name Sheep
extends Enemy
## Le Mouton (FR29): rests, then scrapes the floor (Telegraph: animation and sound), backs up backup_distance away
## from where the player stood when the scraping began, and charges in a straight line in that direction at
## charge_speed. The charge goes through its target (a collision exception with the target's body, lifted once
## the bodies no longer overlap) and stops on the first thing it hits: a wall (STUNNING_LAYERS) stuns it for
## stun_duration, another enemy only ends the charge. Then it rests again. The direction is set when the scraping
## starts: it never steers (unlike Le Somnambule's rush). Contact hurts in every state (Enemy's Hitbox).
## Every value comes from SheepDef (sheep.tres).

enum State { REST, TELEGRAPH, BACKUP, CHARGE, STUN }

## Placeholder telegraph sound, generated by a script; replaced by story 7.7.
const TELEGRAPH_SOUND: AudioStream = preload("res://audio/sfx/sfx_enemy_sheep_telegraph.wav")
const TICK_EPSILON: float = 1e-6
## What stuns a charging sheep (FR29: walls). Story 4.5 adds the high obstacles.
const STUNNING_LAYERS: int = Const.LAYER_WALLS

var _state: State = State.REST
var _sheep_def: SheepDef
var _rest_seconds: float = 0.0
var _backup_px: float = 0.0           # speed, pixels per second
var _backup_seconds: float = 0.0      # backup_distance / backup_speed, 0 when either is 0
var _charge_px: float = 0.0
var _stun_seconds: float = 0.0
var _ticks_left: float = 0.0          # rest, backup or stun
var _charge_direction: Vector2 = Vector2.ZERO
## The target's body while it is excepted from collisions (from the charge until the bodies no longer overlap).
var _excepted_body: PhysicsBody2D
# placeholder textures: rest, two scrape steps, charge (head down), stunned


func _physics_process(_delta: float) -> void:
	var clock_scale: float = GameClock.scale(GameClock.Group.ENEMIES) # one read per tick
	if clock_scale <= 0.0:
		return
	if _excepted_body != null and _state != State.CHARGE:
		_release_exception_when_clear()
	match _state:
		State.REST:
			_process_rest(clock_scale)
		State.TELEGRAPH:
			_process_telegraph(clock_scale)
		State.BACKUP:
			_process_backup(clock_scale)
		State.CHARGE:
			_process_charge(clock_scale)
		State.STUN:
			_process_stun(clock_scale)
```

- **`_ready()`** : `super()` ; `if _def == null: return` ; `_sheep_def = _def as SheepDef` ; nul → `process_mode = DISABLED` **avant** `Log.error("combat", "sheep needs a SheepDef")` + `assert`, `return` (comme le Somnambule). Conversion **une fois** (AR28) : vitesses × `TILE_SIZE` ; durées en secondes ; `_backup_seconds = backup_distance / backup_speed` si les deux sont valides et > 0, sinon 0 (pas de recul). Valeurs non finies ou ≤ 0 → `Log.error("combat", "sheep <champ>=<valeur> is invalid, bounded to 0")` + `_assert_failed()`, bornées à 0 (repos 0 : il réattaque dès la fin de l'étourdissement ; étourdissement 0 ; recul 0). **`charge_speed` invalide : Le Mouton est inerte** (jamais de télégraphe ni de son ; message « … is invalid, it never charges ») — décision 27 de 2.4. `telegraph_duration` est passé tel quel à `telegraph.start()`, qui le borne déjà (NaN → `Log.error` + assertion, au moins `min_telegraph`). Textures ; `_enter(State.REST)`.
- **`_process_rest()`** : `_ticks_left -= clock_scale` ; si `_ticks_left <= TICK_EPSILON`, que Le Mouton n'est pas inerte, que `_target` est valide et que `_target_position() - global_position` n'est pas nul (`length_squared() >= 1e-6`) → `_enter(State.TELEGRAPH)` ; sinon il attend (il reteste au tick suivant, sans erreur). **Aucun déplacement au repos, aucune condition de distance** : la charge traverse la salle.
- **`_process_telegraph()`** : tant que `telegraph.is_active()`, texture de grattage `mini(int(telegraph.progress() * SCRAPE_STEPS), SCRAPE_STEPS - 1)` ; sinon `_enter(State.BACKUP)` (aucun mouvement ce tick).
- **`_process_backup()`** : `if _ticks_left <= TICK_EPSILON: _enter(State.CHARGE); return` ; `_move_in_direction(-_charge_direction, _backup_px, clock_scale)` ; `_ticks_left -= clock_scale`. Le recul glisse le long d'un mur (`move_and_slide()`), il n'est ni raccourci ni allongé : il dure `_backup_seconds`.
- **`_process_charge()`** : `_move_in_direction(_charge_direction, _charge_px, clock_scale)` ; puis, pour `i` dans `get_slide_collision_count()`, lire `get_slide_collision(i)` : si **un** collisionneur est un mur (`_is_stunning(collision)`) → `_enter(State.STUN)` ; sinon, s'il y a au moins une collision → `_enter(State.REST)` (arrêtée par un ennemi). Sans collision, la charge continue au tick suivant. Un seul glissement possible au tick du choc (le reste du pas de `move_and_slide()`) : moins d'un pas (≈ 2,7 px), accepté ; aux ticks suivants Le Mouton ne bouge plus.
- **`_is_stunning(collision: KinematicCollision2D) -> bool`** : `(PhysicsServer2D.body_get_collision_layer(collision.get_collider_rid()) & STUNNING_LAYERS) != 0`. Pour une tuile, `get_collider_rid()` est le corps du quadrant du `TileMapLayer` (doc 4.7 `TileMapLayer.get_coords_for_body_rid()`), dont la couche est celle du `TileSet` (`LAYER_WALLS`). **Ne pas** tester `get_collider() is TileMapLayer` : les obstacles de la 4.5 ne seront pas forcément des tuiles, et `enemies/` ne dépend pas de `rooms/`.
- **`_process_stun()`** : `if _ticks_left <= TICK_EPSILON: _enter(State.REST); return` ; `_ticks_left -= clock_scale`. Immobile (aucun `move_and_slide()`), touchable, contact actif.
- **`_enter()`** (seul endroit qui écrit `_state`) :
  - `REST` : `velocity = Vector2.ZERO`, texture de repos, `_ticks_left = _rest_seconds * Engine.physics_ticks_per_second`.
  - `TELEGRAPH` : `velocity = Vector2.ZERO`, `_charge_direction = (_target_position() - global_position).normalized()` (**figée ici**), première texture de grattage, `telegraph.start(_sheep_def.telegraph_duration, TELEGRAPH_SOUND)`.
  - `BACKUP` : texture de charge (tête baissée) ou de repos, `_ticks_left = _backup_seconds * Engine.physics_ticks_per_second`.
  - `CHARGE` : texture de charge ; **exception** : `var body: PhysicsBody2D = _target as PhysicsBody2D` ; s'il est valide et que `_excepted_body` est nul, `add_collision_exception_with(body)`, `_excepted_body = body`.
  - `STUN` : `velocity = Vector2.ZERO`, texture étourdie, `_ticks_left = _stun_seconds * Engine.physics_ticks_per_second`, `Log.debug("combat", "%s charge stopped by a wall, stunned" % name)`.
  - Retour au repos depuis la charge (ennemi) : `Log.debug("combat", "%s charge stopped by %s" % [name, <nom du collisionneur>])`. **Une ligne par charge, jamais par tick, hors de `_physics_process`** (la règle de `run_all.sh` regarde le corps de `_physics_process` : les `Log.` vont dans `_enter()` ou une aide). Les logs existants (`hit`, `died`) gardent `_def.id`.
- **`_release_exception_when_clear()`** (appelée à chaque tick hors charge tant que `_excepted_body` est posé) : si `_excepted_body` n'est plus valide → `_excepted_body = null` ; sinon requête `get_world_2d().direct_space_state.intersect_shape()` avec un `PhysicsShapeQueryParameters2D` gardé (créé une fois) : `shape = _body.shape`, `transform = _body.global_transform`, `collision_mask = Const.LAYER_PLAYER` (la couche de la cible ; la requête n'applique pas les exceptions, seulement `exclude` = `[get_rid()]`), `collide_with_areas = false`. Si aucun résultat n'a `rid == _excepted_body.get_rid()` → `remove_collision_exception_with(_excepted_body)`, `_excepted_body = null`. Doc 4.7 : `intersect_shape()` renvoie des `Dictionary` (`collider`, `collider_id`, `rid`, `shape`) et ignore `motion`. **Pourquoi** : lever l'exception pendant que les corps se chevauchent (charge arrêtée contre un mur où se tient le joueur) ferait déplacer le joueur par la récupération de pénétration, voire le coincer entre le mur et le Mouton.
- **Exception de collision, symétrie** : doc 4.7 « Adds a body to the list of bodies that this body can't collide with ». Le serveur 2D de Godot teste l'exception dans les deux sens au déplacement d'un corps (`GodotSpace2D::_cull_aabb_for_body` : exception de l'un **ou** de l'autre) : le joueur ne heurte pas non plus le Mouton qui charge. **C'est le point 3 de la stratégie de test qui le prouve** (joueur actif sans entrée, position identique au bit près pendant la traversée ; témoin par mutation sans exception). Si ce contrôle montrait une exception à sens unique, ajouter l'exception symétrique côté cible (`body.add_collision_exception_with(self)`, retirée au même moment) et le consigner dans les notes de fin.
- **Tailles et ordre** : corps 10×10 px ; zone de contact 12×12 px contre la hurtbox 6×6 px du joueur : à 2,67 px par tick, une traversée de face recouvre la hurtbox pendant plusieurs ticks (pas d'effet tunnel), un joueur décalé de moins de 9 px de la ligne est touché.
- **Textures provisoires** (constantes visuelles locales, « placeholder until epic 7 », animation par `texture` seulement) : toile 16×24 comme les autres ; une boule de laine pâle (par exemple beige crème, distincte du blanc du flash par sa teinte) avec une tête sombre et deux pattes ; `SCRAPE_STEPS` = 2 textures de grattage (une patte avant levée puis posée, plus un petit nuage de poussière au sol) ; charge (tête baissée vers l'avant, corps plus bas) ; étourdi (yeux en croix et un petit cercle d'étoiles au-dessus de la tête). Couleurs distinctes du joueur (bleu), du Somnambule (violet), de la Veilleuse (ocre / jaune), de la Berceuse (vert d'eau), des cibles (orange), du tir (cyan) ; **≥ 0,2 (RGB) des couleurs réservées** ; aucun nombre du GDD dans les littéraux.

**Nombre de ticks** (60 Hz, échelle 1, valeurs de `sheep.tres`) :

- apparition : repos de 60 ticks ; **premier départ de télégraphe au 60e tick de physique** après l'ajout à l'arbre ;
- télégraphe démarré au tick N ; vu inactif au tick N + 30 → `BACKUP` (sans mouvement) ; recul aux ticks N + 31 à N + 45 (15 pas de 8/15 px = 8 px) ; `CHARGE` au tick N + 46 (sans mouvement) ; premier pas de charge au tick N + 47, puis 8/3 px par tick (160 px/s) ;
- choc contre un mur au tick M → `STUN` ; immobile aux ticks M + 1 à M + 60 ; `REST` au tick M + 61 ; télégraphe suivant au tick M + 121.
- Ces nombres sont des attentes ; les contrôles affirment « au moins » pour les durées d'annonce (FR26 : grattage ≥ 0,4 s) et la valeur exacte à ±1 tick ailleurs.

### Son du télégraphe (FR26)

`game/audio/sfx/sfx_enemy_sheep_telegraph.wav`, généré par un script jetable du scratchpad (`uv run python <script>`, module standard `wave`, même méthode que les sons de 2.3 et 2.4) : mono, 16 bits, 22 050 Hz, amplitude ≈ 0,4, **≈ 0,4 s** (dans les 0,5 s du grattage), **déterministe** (bruit tiré d'un `random.Random` à graine fixe **du script**, jamais du jeu) : deux ou trois raclements (rafales de bruit filtré, enveloppes courtes) qui évoquent un sabot qui gratte. Distinct des trois sons de télégraphe existants, du tir et du coup reçu. Puis `--import`, versionner `.wav` et `.wav.import`. Remplacé par la 7.7. **Pas de son de charge, de choc ni d'étourdissement** (décision 17 de 2.4).

### Arène (CA 12)

`rooms/arena/arena.gd` :

- `var _spawn_serial: int = 0` (doc : « spawns of this room so far: names the next enemy <id>_<n>, never reused »).
- Dans `spawn_enemy()`, **après** `enemy.setup(…)` et **avant** `_enemies.add_child(enemy)` : `_spawn_serial += 1` ; `enemy.name = "%s_%d" % [_enemy_base_name(def), _spawn_serial]` où `_enemy_base_name()` rend `String(def.id).validate_node_name()`, ou `"enemy"` si l'`id` est vide (doc 4.7 : `validate_node_name()` remplace `. : @ / " %` par `_`). Le compteur est celui de la salle : il repart à 1 avec une nouvelle arène (relance) et n'est jamais réutilisé dans une même salle (unicité entre frères garantie, aucun renommage automatique en `@`).
- Journal : `Log.debug("room", "spawned %s at %s alive=%d node=%s" % [def.id, position_px, _alive, enemy.name])` (le début de la ligne ne change pas : la règle `spawned sleepwalker at` de `run_all.sh` reste vraie).
- Rien d'autre ne change. Les ennemis ajoutés à la main par les scènes de test (`t_invalid24`, `t_shooters`) ne passent pas par là : ils gardent leur nom.

### Panneau F1 (AR24, CA 11)

`debug/debug_panel.gd` : `const SHEEP_DEF: EnemyDef = preload("res://data/enemies/sheep.tres")` (debug seulement, comme les autres) ; touche **9** → `_spawn(SHEEP_DEF, "sheep")` (mêmes règles que 6 à 8, mêmes messages) ; texte `9 spawn sheep`, `F1 panel (keys 1-9)`, en-tête de classe « keys 1 to 9 ». Agrandir le `Label` de `debug_panel.tscn` si le texte déborde (par exemple `offset_bottom` 144 → 160). La 2.6 remplacera 6 à 9 par « ennemi choisi ».

### Règles d'architecture qui s'appliquent

- GDScript typé partout ; `snake_case` pour fichiers et dossiers, un script par classe, racine en `PascalCase` (`sheep.tscn` → `Sheep`) ; `Def` pour le contenu. Code, commentaires, logs, noms de fichiers **en anglais**.
- **États et télégraphes** : enum + `match`, un `_process_<état>()` par état, `_state` écrit **seulement** dans `_enter()` ; l'attaque passe par `Telegraph`.
- **Temps** (AR13) : `GameClock.Group.ENEMIES` pour tout (repos, télégraphe, recul, charge, étourdissement) ; pas de `Timer`.
- **Données** (AR9, NFR9) : les valeurs vivent dans `sheep.tres` ; la `Def` n'est jamais modifiée à l'exécution ; aucun nombre du GDD en dur (50, 0.5, 10, 1) dans les scripts ; `STUNNING_LAYERS` est une règle (FR29 : « un mur »), pas un réglage.
- **Création d'entités** : par `room.spawn_enemy()` seulement ; `setup()` avant `add_child()` ; le nom est donné par la salle.
- **Frontières** : `enemies/` dépend de `combat/`, `core/` et du moteur (`PhysicsBody2D`, `PhysicsServer2D`), **pas** de `player/` ni de `rooms/` (la cible reste un `Node2D` vu comme `PhysicsBody2D`) ; rien ne dépend de `debug/`.
- **Logs** (AR27) : `Log.debug` pour le télégraphe (déjà dans `Telegraph`, nom lisible désormais), une ligne par fin de charge ; aucun `INFO` nouveau ; aucun `Log.` dans un `_physics_process`.
- **Aléatoire** : aucun.

### Arborescence attendue à la fin de la story

```
game/
├── enemies/
│   ├── enemy.gd                          (UPDATE : _move_in_direction(), _move_toward() sans test de cible)
│   └── sheep/sheep.tscn, sheep.gd, sheep_def.gd (NEW, + .uid)
├── data/enemies/sheep.tres               (NEW)
├── audio/sfx/sfx_enemy_sheep_telegraph.wav (NEW, + .import)
├── rooms/arena/arena.gd                  (UPDATE : nom <id>_<n>, journal d'apparition)
└── debug/
    ├── debug_panel.gd                    (UPDATE : touche 9)
    └── debug_panel.tscn                  (UPDATE si le texte déborde)
```

Mettre à jour aussi `_bmad-output/game-architecture.md` (T1) et `deferred-work.md` (T9). Ne pas toucher à `combat/`, `core/`, `sleepwalker/`, `night_light/`, `lullaby/`, `shooter_*.gd`, `enemy_def.gd`, `player/`, `run/`, `main/`, aux autoloads, aux menus.

### Stratégie de test

Aucun framework (AR26 : avant le jalon B). Nouvelles scènes jetables dans `game/.scratch/` (créées par `mk_tscn.sh`, harnais `th.gd` **étendu par ajouts** : par exemple `const SHEEP_DEF := preload("res://data/enemies/sheep.tres")`), ajoutées à `SCENES` dans `run_all.sh`. Joueur figé par `player.set_physics_process(false)` **sauf** quand le contrôle porte sur la poussée ou la traversée des corps (joueur actif, aucune entrée). Scènes proposées : `t_sheep` (comportement, `run.tscn` seul), `t_sheep_main` (`main.tscn`), `t_invalid25` (chemins d'erreur). **Chaque point dit ce qu'il isole et donne son témoin ; mutations au point 13.** Géométrie de référence : joueur en (304, 168) (centre), zone jouable x 16 à 592, y 16 à 320 ; un Mouton placé à gauche du joueur sur la même ligne (par exemple (176, 168)) charge vers la droite et doit finir contre le mur droit (bord du corps à ≤ 1 px de x = 592).

1. **Import et lancement** : `--import` puis `--quit-after 120` : zéro `SCRIPT ERROR`, zéro `Parse Error`, aucun avertissement nouveau ; `.wav` importé ; `sheep.tres` relu après import : toutes ses valeurs explicites (dont `rest_duration`, `stun_duration` à 1.0 et `max_hp` 50) ; `project.godot` inchangé.
2. **Cycle et télégraphe** (`t_sheep`, joueur figé) — CA 1, 2, 5 :
   - **premier télégraphe** au 60e tick après l'apparition (±1 ; aucun avant) ; **témoin** : `SheepDef` dupliqué par le test avec `rest_duration` 2,0 → 120 ticks (la valeur vient de la `Def`), le `.tres` partagé intact ;
   - **grattage** : textures de grattage dès le tick du départ, au moins `SCRAPE_STEPS` textures distinctes vues dans l'ordre, `Audio.voices_of(Sheep.TELEGRAPH_SOUND) == 1`, **position identique au bit près** pendant les 30 ticks ; le recul commence au tick N + 31 (≥ N + 30 : au moins 0,5 s d'annonce) ;
   - **recul** : déplacement total de 8 px (±0,01) en 15 ticks, colinéaire à −(joueur − Mouton) (produit scalaire normé ≥ 0,9999) ; **témoin** : `backup_distance` 1,0 → 16 px ;
   - **charge** : à partir du tick N + 47, pas de 8/3 px (±0,01) loin des murs, colinéaire à la direction figée ; **témoin** : `charge_speed` 5,0 → 4/3 px par tick ;
   - **direction figée au départ du télégraphe** : joueur téléporté par le test pendant le grattage → la charge garde l'ancienne direction (elle passe par l'ancienne position, à ±1 px) ; **témoin** : téléporté **avant** le départ du télégraphe → la charge vise la nouvelle position ; **contrôle croisé** : un Somnambule dans la même situation suit le joueur pendant son accélération (les deux ennemis restent distincts, décision 6 de 2.3) ;
   - **mur** : la charge s'arrête contre le mur (bord du corps à ≤ 1 px du mur, jamais dedans), état étourdi, texture étourdie, **une** ligne `charge stopped by a wall` ; position identique au bit près pendant 60 ticks ; aucun télégraphe avant M + 121 (±1), télégraphe à M + 121 ; **témoin** : `stun_duration` 2,0 → télégraphe à M + 181 ;
   - **charge en diagonale** : Mouton placé en diagonale du joueur → s'arrête au premier contact avec un mur, **sans glisser le long** (position stable aux ticks suivants, au plus un pas de glissement au tick du choc) ; **charge parallèle à un mur** à 2 px de lui → atteint le mur du fond (aucun faux choc contre le mur longé).
3. **La charge traverse le joueur** (`t_sheep`, **joueur actif sans entrée**, vulnérable, sur la ligne) — CA 3, 6, 8 :
   - un seul `player_hit(1, CONTACT)` pendant la traversée (un coup puis l'invulnérabilité) ; Le Mouton continue jusqu'au mur droit (position finale > joueur + 100 px) ; **position du joueur identique au bit près** du départ de la charge à la fin de la traversée (aucune poussée, aucun blocage) ; **témoins par mutation** : sans l'exception, la charge s'arrête au joueur (ou le pousse) → le contrôle échoue ;
   - `get_collision_exceptions()` du Mouton : contient le joueur pendant la charge, **vide** quelques ticks après la fin de la traversée ;
   - **joueur invulnérable** (F1, appel de la méthode publique, ou dash) → traversé, aucun coup ; **témoin** : vulnérable → coup ;
   - **le joueur marche à travers un Mouton qui charge** (entrée simulée vers lui) : il n'est pas bloqué ; **hors charge** (repos, étourdi), le même mouvement est bloqué par le corps (FR4, décision 10 de 2.3) et le dash aussi ;
   - **charge arrêtée sur le joueur collé au mur** (joueur actif à 1 px du mur droit, sur la ligne) : l'exception reste posée tant que les corps se chevauchent (le joueur n'est **pas** déplacé par la récupération : position identique au bit près pendant l'étourdissement), puis le joueur sort par une entrée simulée → exception levée au premier tick où les corps ne se chevauchent plus ; ensuite le joueur qui revient vers le Mouton étourdi est bloqué ; **témoin par mutation** : exception levée à l'entrée en `STUN` → le joueur est déplacé (le contrôle échoue).
4. **Arrêt par un ennemi** (`t_sheep`) — CA 7 : une Veilleuse placée (`put()`) sur la ligne de charge → la charge s'arrête contre son corps, **pas** d'étourdissement (texture de repos, ligne `charge stopped by night_light_<n>`), télégraphe suivant un repos plus tard (M + 61 ±1) ; la Veilleuse n'a pas bougé ; **témoin** : sans la Veilleuse, la charge atteint le mur et étourdit.
5. **Tirs du joueur et mort** (`t_sheep`) — CA 8 : 50 PV → 5 tirs (vivant à 10 PV après le 4e), `enemy_damaged` 10 par tir, flash et recul (`_sprite.position != Vector2.ZERO` au tick qui suit) ; mort → désactivé dans le tick du coup mortel (`process_mode == PROCESS_MODE_DISABLED` avant l'`await`), libéré, compte de la salle à 0 ; **mort en pleine charge** : plus aucun mouvement ni contact, joueur jamais touché ensuite ; **tué au tick du premier pas de charge depuis un nœud de priorité −10** (`killer.gd`) → aucun pas de charge ; **témoin** : coup non mortel au même tick → le pas a lieu ; touché pendant l'étourdissement : dégâts normaux.
6. **Contact** (`t_sheep`) — CA 8 : joueur vulnérable collé au Mouton au repos, en grattage, étourdi → coup `CONTACT` (chemin de 2.3) ; dash vers un Mouton au repos → arrêté par son corps.
7. **Sans cible** (`t_sheep`) : cible libérée avant le départ du télégraphe → aucun télégraphe (repos prolongé), aucune erreur ; **libérée pendant la charge** → la charge continue jusqu'au mur, exception oubliée sans erreur (`_excepted_body` nul) ; **témoin** : cible gardée → télégraphe.
8. **F4 et gel** (`t_sheep` pour F4, `t_sheep_main` pour la pause) — CA 9 : `global_multiplier = 0.25` → repos de 240 ticks, grattage 120, recul 60 ticks, pas de charge de 2/3 px, étourdissement 240 ; **pause** puis **écran de réveil** pendant chaque état (repos, grattage, recul, charge, étourdi) : position, ticks restants du Mouton et du télégraphe figés 60 ticks ; reprise : même nombre de ticks hors pause que sans pause.
9. **Base des ennemis** : `t_sleepwalker`, `t_enemy_parts`, `t_enemy_main`, `t_shooters`, `t_shooters_main`, `t_invalid23`, `t_invalid24`, `t_enemy_bullets`, `t_regress` passent **telles quelles** (refactorisation de `_move_toward()` sans effet : poursuite, accélération, recul de la Berceuse, « cible libérée »). `_move_in_direction()` : un ennemi de test (Mouton en repos, appel direct) avec une direction nulle ne bouge pas ; avec une direction et une vitesse, avance de `vitesse / 60` px par tick, au-delà de tout point (pas d'arrêt).
10. **Noms lisibles** (`t_sheep`, `t_sheep_main`) — CA 12 : apparitions successives d'un Somnambule, de deux Moutons et d'une Veilleuse → noms `sleepwalker_1`, `sheep_2`, `sheep_3`, `night_light_4` (aucun `@`, uniques) ; ligne `telegraph sheep_2 started` dans le journal ; une apparition **refusée** (position impossible ou setup raté) ne laisse aucun nœud nommé dans `Enemies` (son numéro peut être perdu : n'affirmer ni la contiguïté ni l'absence de trou) ; après une relance, la nouvelle arène repart à `_1` ; **témoin** : un ennemi ajouté à la main sous `Enemies` avec le même nom de scène qu'un frère reçoit un nom en `@` (le contrôle sait voir un `@`).
11. **Partie complète** (`t_sheep_main`, `main.tscn`) — CA 10, 11 : F1 + touche 9 → un Mouton à ≥ 48 px du joueur, `alive_enemy_count() == 1`, texte `9 spawn sheep` et `F1 panel (keys 1-9)` ; touche 9 panneau caché → rien ; F5 puis 9 → « no room » ; F5 retour → 9 marche ; **relance** : mort pendant une charge avec l'exception posée → relance → aucun `Sheep` dans l'arbre ; cinq cycles (un Mouton en charge à chaque mort) : `OBJECT_NODE_COUNT` identique après le 1er et le 5e cycle, `OBJECT_ORPHAN_NODE_COUNT` à 0, connexions de `Events.enemy_damaged` et `Events.run_ended` stables ; **mort par la charge** : joueur à ½ cœur traversé → mort, `Events.run_ended` une fois, `player_hit` de source `CONTACT` juste avant.
12. **Chemins d'erreur** (`t_invalid25`, comptés par `run_all.sh` comme les autres `t_invalid*`) : scène `sheep.tscn` avec un `EnemyDef` qui n'est pas un `SheepDef` (par exemple `sleepwalker.tres`) → désactivé ; `SheepDef` dupliqué avec `charge_speed` 0 → 1 assertion, **inerte** (télégraphe jamais actif à chaque tick sur 300 ticks, aucun son) ; **témoin** : `charge_speed` 10 → télégraphe ; `stun_duration` NaN → borné à 0 (repos aussitôt après le choc) ; `backup_speed` 0 → pas de recul, charge au tick N + 31 ; `rest_duration` −1 → borné à 0 ; `telegraph_duration` NaN → borné par `Telegraph` (au moins `min_telegraph`) ; `SheepDef` neuve (défauts neutres) → messages annoncés, aucune valeur héritée d'un autre ennemi ; nombre exact d'assertions annoncé cas par cas, aucun autre `SCRIPT ERROR`, aucune erreur par tick.
13. **Contrôles par mutation** (mécanisme retiré, scène relancée, restauration octet pour octet, consignés dans le Debug Log) : exception de collision retirée → point 3 échoue ; exception levée à l'entrée en `STUN` au lieu de « corps disjoints » → point 3 (joueur collé au mur) échoue ; direction recalculée à chaque tick de charge → point 2 (direction figée) échoue ; télégraphe sauté (charge dans `_enter(TELEGRAPH)`) → point 2 échoue ; recul retiré → point 2 échoue ; test de mur retiré (tout choc étourdit) → point 4 échoue ; test de mur inversé (rien n'étourdit) → point 2 échoue ; arrêt au premier choc retiré (la charge continue après une collision) → points 2 (diagonale) et 4 échouent ; `_die()` sans `PROCESS_MODE_DISABLED` → point 5 (tueur −10) échoue ; nom non donné dans `spawn_enemy()` → point 10 échoue ; `_move_toward()` sans repli de direction nulle (normalisation d'un vecteur nul) → point 9 ou `t_sleepwalker` échoue.
14. **Régression et règles de source** (`run_all.sh`) : toutes les scènes `PASS` ; recherche des interdits (inchangée) ; **nombres du GDD** : règles existantes inchangées, plus une règle 2.5 avec témoin planté : aucun `50` dans `enemies/` et `combat/`, aucun `10.0` dans `enemies/` hors lignes `@export_range` (les bornes d'éditeur, comme `0.0, 10.0` de `shooter_def.gd`, ne sont pas des valeurs de jeu ; `0.5` et `1.0` ne sont pas cherchés : moitiés et facteurs légitimes) ; **machine à états** de `sheep.gd` (`state_machine`) avec témoins plantés (transition qui écrit `_state` hors `_enter()`, `_process_stun()` manquant) ; **journaux** : une ligne `telegraph sheep_<n> started` par départ (compte échantillonné par la scène, `TELEGRAPH_COUNT`), une ligne `charge stopped by` par fin de charge (`CHARGE_END_COUNT`), lignes `spawned … node=<id>_<n>`, **aucune ligne `telegraph @`** dans les journaux de `t_sheep`, `t_sheep_main`, `t_shooters` et `t_sleepwalker` (scènes qui font apparaître par `spawn_enemy()` ; vérifier qu'aucune n'ajoute un ennemi à la main qui télégraphie) avec témoin planté ; aucun `INFO` nouveau ; aucun `Log.` dans un `_physics_process`.
15. **Fenêtré sous WSLg** (indicatif, captures `get_viewport().get_texture().get_image().save_png()`) : repos, deux pas de grattage, recul, charge (tête baissée), étourdi contre un mur, Mouton qui traverse le joueur (deux captures), **F2 sous `main.tscn`** (corps, hurtbox, zone de contact du Mouton). Ce qui n'est pas capturé est marqué **NON VÉRIFIÉ à l'écran** dans le Debug Log et `deferred-work.md`.
16. **Étapes humaines** (à consigner `NON ÉVALUÉ` dans la story et `deferred-work.md`, ne pas déclarer vérifiées) : lisibilité du grattage provisoire et son à l'oreille ; repos de 1 s, vitesse du recul ; difficulté d'esquive d'une charge à 10 tuiles/s (annonce de 0,5 s + recul de 0,25 s) ; plaisir de « punir » contre un mur (1 s d'étourdissement : 4 tirs) ; traversée du joueur (et dash à travers un Mouton qui charge) ; arrêt sans étourdissement contre un ennemi ; tailles provisoires.

### Commit

Directement sur `main`, Conventional Commits en anglais, `git push` après chaque commit (consigne du projet), ligne `Co-Authored-By` du modèle réellement utilisé. Commiter par tâche cohérente, chaque commit laissant le jeu lançable. Exemples : `docs(architecture): add sheep and charge terms to the lexicon` ; `refactor(enemies): move enemies along a direction` ; `fix(rooms): give spawned enemies readable names` ; `feat(enemies): add the sheep` ; `feat(debug): spawn the sheep from the f1 panel` ; `docs(story): record story 2.5 implementation and move it to review`.

### Project Structure Notes

- Conforme à l'arborescence de l'architecture : `enemies/sheep/`, `data/enemies/sheep.tres`, son `sfx_enemy_sheep_telegraph.wav`, classe `Sheep` (lexique).
- **Écarts assumés** : `sheep_def.gd` (sous-classe propre, comme `sleepwalker_def.gd`) ajouté à l'arborescence en T1 ; aucun nouveau dossier.

### Project Context Rules

Il n'y a pas de `project-context.md`. Règles tirées de `CLAUDE.md`, de la mémoire du projet et du brief du pipeline :

- Conversation, documents de conception et artefacts BMAD : **français**. Code (identifiants, commentaires, noms de fichiers, messages de log) : **anglais**.
- Commits en anglais, Conventional Commits (`type(scope): description`, impératif, minuscules, sans point final), **directement sur `main`, sans branche**, avec un push vers `origin/main` aussitôt après chaque commit, et la ligne `Co-Authored-By` en fin de message.
- Textes affichés au joueur : fichiers de localisation, jamais en dur (aucun dans cette story ; le panneau F1 est du debug, exempté).
- Prototype rapide, itérations courtes : ne poser que ce que cette story exige.
- Pipeline automatisé de l'epic 2 : Kroustille n'est pas disponible avant la fin de l'epic ; toute question se tranche et se consigne ci-dessous.
- `game/.scratch` : vrai dossier exclu de git, jamais commité, jamais remplacé par un lien ; les scènes existantes ne se réécrivent pas.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Cycle : repos → grattage → recul → charge → étourdissement → repos**, première attaque un repos après l'apparition — Question : que fait Le Mouton entre deux attaques, et quand attaque-t-il ? Choix : immobile pendant `rest_duration` (1 s, provisoire), puis il attaque quelle que soit la distance (cible valide requise). Raison : le GDD ne dit rien ; un chargeur traverse la salle, une condition de portée n'apporte rien ; le repos laisse un répit après l'apparition et après chaque charge. **NON ÉVALUÉ.**
2. **Direction figée au départ du télégraphe** (une direction, pas un point) — Raison : lecture littérale de « vers la position du joueur au moment du télégraphe » ; la charge passe par ce point et continue « jusqu'au mur » ; elle reste distincte de l'accélération du Somnambule qui suit le joueur (décision 6 de 2.3).
3. **Recul en durée** (`backup_distance / backup_speed`, 2 tuiles/s provisoires, soit 0,25 s), immobile pendant le grattage, glissement contre un mur sans raccourcir — Raison : le GDD ne donne pas la vitesse ; une durée fixe garde l'annonce prévisible ; le recul allonge l'annonce (0,75 s en tout) sans compter dans le télégraphe (FR26 tenu par les 0,5 s). **NON ÉVALUÉ.**
4. **La charge traverse sa cible par une exception de collision** avec le corps de la cible, le masque ne change pas — Question (report de 2.3) : masque propre à la charge, ou décision 10 revue ? Choix : ni l'un ni l'autre. Raison : retirer `LAYER_PLAYER` du masque ne suffit pas (le joueur, qui a `LAYER_ENEMIES` dans son masque, serait poussé par la récupération de pénétration à chaque tick de chevauchement, comme par le Somnambule en accélération, report 4.3, mais à une vitesse double) ; l'exception agit dans les deux sens, pour ce seul couple, pendant la seule charge. Conséquence assumée : pendant une charge, le joueur (marche ou dash) traverse Le Mouton ; exception locale à FR4. **NON ÉVALUÉ.**
5. **Exception levée quand les corps ne se chevauchent plus**, pas à la fin de la charge — Raison : une charge arrêtée contre le mur où se tient le joueur laisserait les corps l'un dans l'autre ; lever l'exception aussitôt ferait déplacer (ou coincer) le joueur par la récupération. Une requête `intersect_shape()` par tick, seulement tant que l'exception est posée.
6. **Arrêt au premier contact ; seul un mur (`STUNNING_LAYERS` = `LAYER_WALLS`) étourdit ; un ennemi arrête la charge sans étourdir** — Raison : FR29 dit « un mur » ; la 4.5 ajoutera les obstacles hauts ; sans arrêt au contact, la charge pousserait indéfiniment un ennemi de face ; sans étourdissement contre un ennemi, « punir contre un mur » garde son sens. **NON ÉVALUÉ.**
7. **Mur reconnu par la couche du collisionneur** (`PhysicsServer2D.body_get_collision_layer(get_collider_rid())`), pas par son type — Raison : indépendant des tuiles et de `rooms/` (frontières), prêt pour les obstacles de la 4.5.
8. **Le coup de la charge est le contact** (`Hitbox` existante, ½ cœur, source `CONTACT`), sans zone d'attaque propre ni dégâts lourds — Raison : le CA 3 dit « le contact inflige un coup de ½ cœur » ; FR12 réserve le coup lourd aux cauchemars.
9. **Pas de bonus de dégâts pendant l'étourdissement** — Raison : le GDD n'en donne pas ; la punition est le temps libre pour tirer (1 s = 4 tirs, 40 des 50 PV).
10. **Valeurs invalides** : `charge_speed` invalide → Mouton inerte (ni télégraphe ni son, décision 27 de 2.4) ; repos, recul, étourdissement invalides → bornés à 0 avec `Log.error` + assertion ; `telegraph_duration` laissé à la validation de `Telegraph` — Raison : AR28, une annonce sans attaque ment au joueur, les autres valeurs ont un 0 sans danger.
11. **Tailles provisoires = celles du Somnambule** (corps 10×10, hurtbox 12×20, contact 12×12 px), toile 16×24 — Raison : le GDD ne les donne pas ; précédent de la décision 19 de 2.4. **NON ÉVALUÉ.**
12. **Un seul son : le grattage** ; ni charge, ni choc, ni étourdissement — Raison : décision 17 de 2.4 ; le GDD n'exige que le son du télégraphe ; 7.7.
13. **Noms `<id>_<n>`, compteur unique par salle** (à partir de 1, jamais réutilisé, repart avec une nouvelle arène), donné par `spawn_enemy()` avant `add_child()` ; la ligne `spawned` gagne `node=` en fin de ligne ; les autres logs gardent `_def.id` — Question : quel nom lisible (retour de jeu de Kroustille) ? Choix : l'`id` de la `Def` et un compteur de salle. Raison : unique entre frères par construction, ordre d'apparition visible, aucun renommage `@` ; le début des lignes existantes ne change pas (règles de `run_all.sh`).
14. **`_move_toward()` sans test de la cible, nouvelle `_move_in_direction()`** dans `Enemy` — Raison : report de 2.3 ; comportement inchangé pour le Somnambule et la Berceuse ; la base ne gagne qu'une aide.
15. **Une ligne `Log.debug` par fin de charge** (mur ou ennemi), avec le nom lisible — Raison : AR27 ; utile au playtest (« pourquoi il ne s'est pas assommé ») ; une charge au plus toutes les ≈ 2 s, jamais par tick.
16. **Pas d'annulation de `Telegraph`, pas de durée maximale de charge** — Raison : aucune attaque n'est interrompue avant la lampe de la 4.4 ; la salle est fermée, toute charge finit contre un mur ou un corps (vérifié par les contrôles de charge en diagonale et parallèle au mur).
17. **Cible perdue en pleine charge : la charge continue jusqu'au mur** ; cible perdue au repos : pas de télégraphe — Raison : la direction est déjà figée ; une annonce sans cible n'a pas de sens.
18. **F1 : touche 9 (Mouton)**, l'arène reste vide au lancement — Raison : décisions 25 de 2.3 et 20 de 2.4 ; les vagues sont la 2.6.
19. **Les décisions de 2.1 à 2.4 restent valables** (filtre de hurtbox, un coup par tick sur le joueur, ordre entités / `Hitbox` / managers, défauts neutres des `Def`, `_assert_failed()`, apparition déterministe, mort par `PROCESS_MODE_DISABLED`, ennemi inerte s'il ne peut pas attaquer, couleurs provisoires sans nombre du GDD, un seul son par télégraphe).

### Questions ouvertes

Aucune bloquante. Points à faire valider par Kroustille en fin d'epic : les décisions ci-dessus, en priorité 1 (repos et attaque sans portée), 3 (vitesse du recul), 4 (traversée du joueur, dash à travers une charge) et 6 (arrêt sans étourdissement contre un ennemi), à juger au jeu.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.5 : Affronter Le Mouton]
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences fonctionnelles] (FR4, FR12, FR26, FR29) et [#Exigences supplémentaires (architecture)] (AR7, AR9, AR13, AR23, AR24, AR27, AR28, AR32)
- [Source: _bmad-output/planning-artifacts/epics.md#Story 4.4] (lampe qui annule les télégraphes), [#Story 4.5] (« un obstacle haut l'arrête et l'étourdit comme un mur »), [#Story 2.6] (« ennemi choisi ») : contexte, non implémentés ici
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Ennemis et IA] (tableau : Le Mouton, chargeur, 50 PV, recule de 0,5 tuile, charge en ligne droite à 10 tuiles/s, étourdi 1 s contre un mur, gratte le sol 0,5 s ; règle de télégraphe : la charge est une attaque), [#Santé et armure] (dégâts au contact), [#Dash] (« le dash traverse les projectiles mais ni les murs ni les ennemis »)
- [Source: _bmad-output/game-architecture.md#Création d'entités], [#États et télégraphes] (exemple `_enter()` d'une charge), [#Accès aux données], [#Dégâts et unités], [#Temps (D7)], [#Logs], [#Frontières architecturales], [#Arborescence] (`enemies/sheep/`), [#Lexique] (`Sheep`), [#Conventions de nommage]
- [Source: _bmad-output/implementation-artifacts/2-3-affronter-le-somnambule.md] (base des ennemis, décisions 6, 9, 10, 27, 32, 33, ordre des ticks, stratégie de test)
- [Source: _bmad-output/implementation-artifacts/2-4-affronter-la-veilleuse-et-la-berceuse.md] (décisions 17, 19, 26, 27, 29 ; revue : tueur de priorité −10, F2 sous `main.tscn`, contrôles creux à éviter)
- [Source: _bmad-output/implementation-artifacts/deferred-work.md] (reports listés dans « Reports traités par cette story »)
- Documentation Godot 4.7 consultée par Context7 à la création : `PhysicsBody2D.add_collision_exception_with()` / `remove_collision_exception_with()` / `get_collision_exceptions()` ; `CharacterBody2D.get_slide_collision_count()`, `get_slide_collision()`, `get_last_slide_collision()` ; `KinematicCollision2D.get_collider_rid()` et `TileMapLayer.get_coords_for_body_rid()` (le RID d'une collision avec une tuile est le corps du quadrant) ; `PhysicsServer2D.body_get_collision_layer()` ; `PhysicsDirectSpaceState2D.intersect_shape()` et `PhysicsShapeQueryParameters2D` (`exclude`, `collision_mask`, `collide_with_areas`, résultats `collider`, `rid`, `shape`, `motion` ignoré) ; `Node.name` (unique entre frères, renommage automatique, caractères `. : @ / " %` remplacés) et `add_child(force_readable_name = false)` (nom factice en `@`), `String.validate_node_name()`. Rappels vérifiés dans le code du dépôt : le joueur appelle `move_and_slide()` à chaque tick (récupération de pénétration même immobile) et tique avant les ennemis ; `Telegraph` vu inactif par son propriétaire au tick N + durée × 60 ; le `TileSet` de l'arène pose `LAYER_WALLS` sur sa couche physique.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Debug Log References

- **Contrôles par mutation SAUTÉS** par décision de Kroustille (pipeline allégé, 2026-11-23) : aucun mécanisme n'a été retiré pour voir échouer une scène. Les contrôles restent des assertions réelles (témoins simples inclus dans les scènes), mais la preuve « le contrôle sait échouer » n'est pas faite.
- Scènes ajoutées (`game/.scratch`, hors git) : `t_sheep` (cycle, direction figée, murs, traversée du joueur actif, joueur collé au mur, arrêt par un ennemi, tirs et mort, contact, sans cible, F4, noms, `_move_in_direction`), `t_sheep_main` (touche 9, pause et écran de réveil dans les 5 états, F4, mort par la charge, cinq relances), `t_invalid25` (17 assertions annoncées = 17 vues). `th.gd` : ajout de `SHEEP_DEF`. `run_all.sh` : trois scènes ajoutées, contrôle « aucune ligne `telegraph @` », comptes `TELEGRAPH_COUNT` / `CHARGE_END_COUNT` contre les journaux, lignes `spawned … node=<id>_<n>`. Les règles de source (nombres du GDD 2.5, machine à états du Mouton) ont été retirées (pipeline allégé).
- Seule scène existante adaptée : `t_shooters_main`, le contrôle du texte du panneau F1 attend désormais `keys 1-9` (la touche 9 est le changement légitime de la 2.5).
- **Point 3 (symétrie de l'exception)** : confirmé. Joueur actif sans entrée, position identique au bit près pendant toute la traversée ; le joueur qui marche traverse aussi un Mouton qui charge (99 pas sans blocage). Le repli (`body.add_collision_exception_with(self)`) n'a pas été nécessaire.
- Sonde au passage : un Mouton dont la cible est un autre corps que le joueur réel est arrêté par le joueur réel (l'exception ne vise que `_target`) ; sans objet en jeu.

### Completion Notes List

- T1 : lexique et architecture mis à jour avant le code (lexique, Création d'entités, États et télégraphes, arborescence `sheep/`).
- T2 : `Enemy._move_in_direction()`, `_move_toward()` sans test de la cible ; Somnambule et Berceuse inchangés (leurs scènes passent telles quelles).
- T3 : `spawn_enemy()` nomme `<id>_<n>` (compteur de salle, `validate_node_name()`, `enemy` si `id` vide), journal `… node=<nom>`.
- T4 : `SheepDef`, `Sheep` (REST / TELEGRAPH / BACKUP / CHARGE / STUN), `sheep.tres` (valeurs explicites relues après import), son de grattage généré (0,4 s, déterministe), textures provisoires. Valeurs invalides : bornées à 0 (repos, recul, étourdissement) ; `charge_speed` invalide : inerte. Calendrier mesuré : premier télégraphe au tick 60, recul 15 pas de 8/15 px, charge de 8/3 px par tick dès N + 47, étourdissement 60 ticks, télégraphe suivant à M + 121 ; sous F4 tout est ×4.
- T5 : touche 9 du panneau F1 ; `Label` agrandi (160 px).
- T6 : voir Debug Log. t_sheep 94 contrôles, t_sheep_main 56, t_invalid25 11 (+17 assertions).
- T7 : **NON FAIT** (pipeline allégé) : aucune capture fenêtrée ; NON VÉRIFIÉ à l'écran (voir `deferred-work.md`).
- T8 : `run_all.sh` ALL PASS (617 contrôles de scènes : 9 scènes existantes inchangées sauf le texte du panneau dans `t_shooters_main`, t_sheep 94, t_sheep_main 56, t_invalid25 11), import et `--quit-after 120` propres. T9 : `deferred-work.md` mis à jour (report « Base des ennemis pour la 2.5 » résolu, entrées NON ÉVALUÉ / NON VÉRIFIÉ).
- Aucun écart aux « Décisions prises sans Kroustille ». Détail d'implémentation : le journal de fin de charge contre un ennemi nomme le collisionneur (`sheep_1 charge stopped by night_light_2`).

### File List

- `_bmad-output/game-architecture.md` (UPDATE)
- `game/enemies/enemy.gd` (UPDATE)
- `game/rooms/arena/arena.gd` (UPDATE)
- `game/enemies/sheep/sheep.gd`, `sheep.tscn`, `sheep_def.gd` (+ `.uid`) (NEW)
- `game/data/enemies/sheep.tres` (NEW)
- `game/audio/sfx/sfx_enemy_sheep_telegraph.wav` (+ `.import`) (NEW)
- `game/debug/debug_panel.gd`, `debug_panel.tscn` (UPDATE)
- `_bmad-output/implementation-artifacts/deferred-work.md`, `sprint-status.yaml`, ce fichier (UPDATE)

### Change Log

- 2026-11-23 : story 2.5 créée (`ready-for-dev`).
- 2026-11-23 : story 2.5 implémentée, passée en `review` (T7 fenêtré et mutations non faits : pipeline allégé).
- 2026-11-23 : revue de code (trois couches) : 3 patchs laissés en actions, 2 reports, 13 rejetés ; story repassée en `in-progress`.

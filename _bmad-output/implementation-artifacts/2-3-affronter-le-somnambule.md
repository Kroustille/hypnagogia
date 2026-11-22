---
baseline_commit: 7480bdb6de885872a5ed27cbe1757ae30a852665
---

# Story 2.3 : Affronter Le Somnambule

Status: in-progress

## Story

En tant que joueur,
je veux un premier ennemi qui me poursuit et annonce son accélération,
afin d'apprendre à lire un télégraphe.

**Exigences couvertes :** FR4 (ennemis), FR12 (contact), FR26, FR27, FR31, AR7, AR23 (déplacement direct), ainsi que AR8, AR9, AR13, AR24 (F1), AR27, AR28, AR32.

**Prérequis : la story 2.2 est `done`** (vérifié à la création de ce fichier : `Run` > `Player` + `RoomSlot` > arène, `Events.run_ended`, écran de réveil, gel par `Main`, `Health`, `Hurtbox.is_hittable()` / `set_hit_filter()`, `CombatTuning`, `BulletManager.has_hurtbox()`, panneau F1 existent dans le dépôt). Les stories 1.7 et 1.8 sont reportées par Kroustille : elles ne sont **pas** des prérequis.

**Troisième story de l'epic 2, premier ennemi.** Elle pose la base commune des ennemis (`Enemy`, `EnemyDef`), les composants de combat qui leur manquent (`HitPoints`, `Hitbox` de contact, `Telegraph`), l'apparition par la salle et Le Somnambule. Les stories 2.4 et 2.5 ajoutent trois ennemis sur cette base ; la 2.6 les fait apparaître en vagues. **La base reste minimale** : rien n'est prévu pour un ennemi qui n'existe pas encore.

## Critères d'acceptation

1. **Étant donné** une salle, **quand** elle fait apparaître un ennemi, **alors** l'apparition passe par `room.spawn_enemy(def, position)`, qui tient le compte des ennemis vivants, **et** aucun ennemi n'apparaît à moins de 3 tuiles du joueur : une position trop proche est refusée et remplacée par une autre position valide.
2. **Étant donné** un Somnambule défini par `sleepwalker.tres` (`EnemyDef`), **quand** il est actif, **alors** il marche vers le joueur à 2,5 tuiles/s, en ligne directe, bras tendus, **et** à moins de 2 tuiles il lève les bras pendant 0,4 s (télégraphe, animation et son), puis accélère à 5 tuiles/s pendant 0,6 s, **et** sa machine à états est un enum, avec une fonction `_process_<état>()` par état et des transitions par `_enter()` uniquement, **et** son temps suit `GameClock.scale(ENEMIES)`.
3. **Étant donné** le composant `Telegraph`, **quand** une attaque est lancée, **alors** sa durée vaut `max(base × multiplicateur, min_telegraph)`, avec `min_telegraph` = 0,4 s dans `CombatTuning`. Le multiplicateur reste à 1 tant que le danger n'existe pas.
4. **Étant donné** le joueur vulnérable, **quand** le Somnambule le touche, **alors** le contact inflige un coup de ½ cœur.
5. **Étant donné** le Somnambule et ses 30 PV, **quand** les tirs du joueur le touchent, **alors** il perd 10 PV par tir, avec les retours d'impact de la Story 1.5, et meurt à 0, **et** le dash du joueur ne le traverse pas.

**Conséquences à tenir pour que le système reste cohérent de bout en bout** (non écrites dans l'epic, mais exigées par l'architecture, par les reports des stories précédentes ou par l'état du dépôt) :

6. **Un coup refusé par le propriétaire ne compte pas** (report de la revue de 2.1) : quand le propriétaire d'une hurtbox n'applique pas un coup (ennemi déjà mort, montant invalide ; montant invalide côté joueur), `Hurtbox.receive()` renvoie `false` et n'émet pas `Events.enemy_damaged` (pas de chiffre de dégâts fictif, et le panneau F1 affiche « hit ignored »).
7. **Le contact est continu et lu dans le tick courant** : tant que la zone de contact chevauche la hurtbox du joueur et que celui-ci est touchable, un coup est livré (pas seulement à l'entrée du contact) ; l'invulnérabilité après un coup, celle du dash et l'invulnérabilité forcée (F1) l'empêchent ; le test se fait **après** le déplacement de toutes les entités, quel que soit l'ordre de l'arbre ; un coup au plus par tick sur le joueur, contact et projectiles confondus.
8. **Un ennemi mort ne joue plus** : au coup mortel, il cesse aussitôt de bouger, de toucher au contact et de bloquer (retiré de la physique), les tirs suivants le traversent sans dégâts ni chiffre, il disparaît, il est libéré à la fin de l'image et le compte de la salle diminue. Les ennemis ne sont jamais mis en pool ni déplacés d'un parent à l'autre.
9. **Pause, écran de réveil et ralenti** : la pause et l'écran de réveil figent les ennemis (position, télégraphe, accélération, contact) ; F4 les ralentit ×0,25 (vitesses et durées).
10. **Relance propre** : à la relance, les ennemis disparaissent avec l'ancien `Run` ; la nouvelle arène compte 0 ennemi ; après cinq cycles avec des ennemis vivants à chaque mort, nombre de nœuds stable, aucun orphelin, connexions au bus stables.
11. **Ordre de dessin** : les ennemis sont dessinés au-dessus du sol et des murs, sous les projectiles et les chiffres de dégâts.
12. **Un Somnambule à la demande en debug** : le panneau F1 (touche 6) fait apparaître un Somnambule par `room.spawn_enemy()` (en attendant « ennemi choisi » de la 2.6).
13. Marche, dash, tir, cibles d'entraînement, chiffres de dégâts, coups et invulnérabilité, clignotement, mort et relance, pause, réglages, F1 à F5 et le test de charge (`Bullets 400 | refused 0`) de 1.1 à 2.2 sont inchangés.

## Tâches / sous-tâches

- [x] **T1. Lexique et architecture** (AR32 : un terme entre dans le lexique **avant** le code)
  - [x] `game-architecture.md`, section « Lexique » : ajouter `Ennemi ; PV ; dégâts au contact ; zone de contact ; apparition ; distance minimale d'apparition ; ennemis vivants ; poursuite ; accélération du Somnambule ; lever les bras | enemy ; hp (HitPoints) ; contact_damage ; Hitbox ; spawn ; min_spawn_distance ; alive_enemies ; chase ; rush ; raise_arms`.
  - [x] `game-architecture.md` : une ligne dans « Projectiles (D1) » (ordre : entités à 0, `Hitbox` de contact à `Const.PHYSICS_PRIORITY_HITBOXES` (50), `BulletManager` à 100) ; une ligne dans « Dégâts et unités » (PV des ennemis dans `HitPoints`, pas dans `Health` ; `Hurtbox.refuse_hit()`) ; une ligne dans « Création d'entités » (apparition à ≥ `min_spawn_distance` du joueur, remplacement déterministe sans RNG avant l'epic 4 ; pas de pool d'ennemis).
- [x] **T2. `CombatTuning`** (CA 1, 3) : `min_telegraph` (0,4 s) et `min_spawn_distance` (3 tuiles), script et `.tres` (voir « `CombatTuning` »).
- [x] **T3. Composants de combat** (CA 3, 4, 5, 6, 7)
  - [x] `combat/hit_points.gd` : `HitPoints` (voir « `HitPoints` »).
  - [x] `combat/telegraph.gd` : `Telegraph` (voir « `Telegraph` »).
  - [x] `combat/hitbox.gd` : `Hitbox` de contact (voir « `Hitbox` »).
  - [x] `combat/hurtbox.gd` : `refuse_hit()`, commentaire d'en-tête (voir « `Hurtbox` »).
  - [x] `combat/damage_info.gd` : `Source.CONTACT = 3`.
  - [x] `core/constants.gd` : `PHYSICS_PRIORITY_HITBOXES` (50), `GROUP_ROOM` (`&"room"`).
- [x] **T4. Base des ennemis** (CA 2, 5, 7, 8) : `enemies/enemy_def.gd` (`EnemyDef`) et `enemies/enemy.gd` (`Enemy`) (voir « `EnemyDef` » et « `Enemy` »).
- [x] **T5. Le Somnambule** (CA 2, 3, 4, 5)
  - [x] `enemies/sleepwalker/sleepwalker_def.gd` (`SleepwalkerDef extends EnemyDef`), `data/enemies/sleepwalker.tres`.
  - [x] `enemies/sleepwalker/sleepwalker.tscn` + `sleepwalker.gd` (machine à états, textures provisoires) (voir « Le Somnambule »).
  - [x] `audio/sfx/sfx_enemy_sleepwalker_telegraph.wav` généré par script (voir « Son du télégraphe »).
- [x] **T6. Joueur** (CA 5, 6) : `player/player.gd` : `collision_mask` avec `Const.LAYER_ENEMIES` ; `hurtbox.refuse_hit()` quand `Health` refuse le coup (voir « Joueur »).
- [x] **T7. Arène** (CA 1, 8, 10, 11) : `rooms/arena/arena.tscn` (nœud `Enemies`), `rooms/arena/arena.gd` (`spawn_enemy()`, `alive_enemy_count()`, groupe `room`, `_player_bullets` gardé) (voir « Arène »).
- [x] **T8. Panneau F1** (CA 12) : touche 6 (voir « Panneau F1 »).
- [x] **T9. Vérifications headless** (CA 1 à 13) : scènes du scratchpad, `run_all.sh` étendu (voir « Stratégie de test »).
- [x] **T10. Vérifications fenêtrées sous WSLg** (CA 2, 5, 11) : marche bras tendus, bras levés, flash, ordre de dessin, F2, captures.
- [x] **T11. Régression** : import et lancement sans erreur, recherche des interdits, `run_all.sh` complet (anciennes et nouvelles scènes).
- [x] **T12. Reports** : mettre à jour `deferred-work.md` (entrées résolues, voir « Reports traités par cette story » ; nouvelles entrées NON ÉVALUÉ / NON VÉRIFIÉ, voir « Stratégie de test » point 14).

### Review Findings

Revue de code du 2026-11-22 (`gds-code-review`, mode complet, trois couches : Blind Hunter, Edge Case Hunter, Acceptance Auditor ; diff `3628517..a932fff`). Les CA 1 à 13 sont implémentés comme la spec les décrit ; les points ci-dessous sont des défauts de robustesse, de vérification et de documentation. **Attention : le scratchpad a été vidé par un redémarrage pendant la revue ; `game/.scratch` (lien) pointe vers un dossier vide, les 11 scènes et `run_all.sh` sont perdus** (voir le dernier point « Patch »).

- [ ] [Review][Patch] **Deux ennemis apparus au même point se bloquent l'un dans l'autre pour toujours** [game/rooms/arena/arena.gd:148-179] — Vérifié par sonde en revue (`run.tscn`, joueur figé en (304, 168), deux `spawn_enemy(sleepwalker, (304, 40))`, soit F1 + touche 6 deux fois) : les deux corps, confondus, glissent ensemble de ≈ 10 px par tick vers la gauche puis restent figés en (56,3 ; 40), distance 0, sans plus jamais poursuivre ; `alive_enemy_count()` reste à 2 (une vague de la 2.6 ne serait jamais finie). L'Edge Case Hunter a vu une fois les corps traverser le mur (x = −54). Correctif : dans `_is_valid_spawn()`, refuser aussi un point dont le rectangle de corps (`def.body_size × TILE_SIZE`, centré) chevauche, marge de 1 px comprise, le corps d'un enfant vivant de `_enemies` (`not enemy.is_dead()` et `not enemy.is_queued_for_deletion()` ; passer `def` à `_resolve_spawn_position()`) ; ajouter des candidats déterministes autour de la demande (anneaux de 1 à 4 tuiles, 8 directions, ordre fixe) **avant** le point repoussé et les coins. Contrôle à écrire : deux demandes au même point → positions distinctes, corps disjoints, les deux poursuivent le joueur (distance au joueur qui diminue en 30 ticks) ; témoin : la règle retirée → l'état bloqué observé ci-dessus. Corriger aussi l'entrée « Apparition » de `deferred-work.md` (« leurs corps se repoussent ensuite » est faux).
- [ ] [Review][Patch] **Aucun candidat valide, ou demande non finie : apparition au centre de la zone, sans contrôle, sur le joueur** [game/rooms/arena/arena.gd:150-173] — `best` vaut `bounds.get_center()` (304, 168), le point d'apparition du joueur, et n'est jamais validé. Une demande `Vector2(NAN, NAN)` ou `(INF, 0)` donne des distances NaN/INF, aucun candidat n'est retenu et l'ennemi apparaît sur le joueur, sans log (vérifié par sonde par l'Edge Case Hunter). Même chose si `min_spawn_distance` dépasse ≈ 19 tuiles (export `or_greater`). Correctif : demande non finie → `Log.error("room", …)` + `assert` (via un helper `_assert_failed()`, décision 27), puis traitée comme refusée avec la direction `Vector2.RIGHT` ; distances au candidat calculées seulement si la demande est finie (sinon ordre de la liste) ; plus de valeur par défaut au centre : `_resolve_spawn_position()` renvoie un drapeau (ou `Vector2(INF, INF)`) quand rien n'est valide, et `spawn_enemy()` le teste **avant** `instantiate()` → `Log.error` + `assert`, `return null`. Contrôles dans `t_invalid23` : NaN → position valide (≥ 48 px, dans les limites), message d'assertion compté ; aucune position valide (réglage de test très grand, sur une copie dupliquée, `Tuning` non modifié) → `null`, aucun nœud.
- [ ] [Review][Patch] **Une demande hors de la zone mais loin du joueur est ramenée à 3 tuiles du joueur au lieu d'être bornée à la zone** [game/rooms/arena/arena.gd:154-162] — Demande (304, 5), joueur en (304, 168) → (304, 120), alors que (304, 32) est valide et bien plus proche ; joueur en (304, 290) et demande (304, 10) → (304, 242) (vérifié par sonde). Le commentaire promet « the nearest valid position ». Correctif : premier candidat = `requested.clamp(bounds.position, bounds.end)`, puis ce point repoussé radialement à `min_px` du joueur s'il est trop près, puis les candidats existants. Contrôle : (304, 5) avec le joueur en (304, 168) → (304, 32) exactement ; témoin : la demande (304, 40), valide, reste inchangée.
- [ ] [Review][Patch] **Un ennemi dont le `_ready()` a échoué est compté vivant et inscrit (hurtbox nulle ou ennemi zombie touchable)** [game/rooms/arena/arena.gd:84-89] — `setup()` incomplet → `enemy.hurtbox == null` passé à `register_hurtbox(null)` ; une scène `Sleepwalker` avec un `EnemyDef` qui n'est pas un `SleepwalkerDef` → l'ennemi est désactivé par `Sleepwalker._ready()` mais sa hurtbox existe : la salle le compte, l'inscrit, il reste visible sans texture et prend des coups (chiffres de dégâts). `spawn_enemy()` appelé avant le `_ready()` de l'arène → `_enemies` nul, plantage. Correctif : en tête de `spawn_enemy()`, `if not is_node_ready(): Log.error + assert, return null` ; après `_enemies.add_child(enemy)`, `if enemy.hurtbox == null or enemy.process_mode == Node.PROCESS_MODE_DISABLED: Log.error("room", "spawn of %s refused: enemy setup failed" % def.id); enemy.queue_free(); return null` (avant inscription, compte et connexion). Contrôle dans `t_invalid23` : `EnemyDef` de test (pas un `SleepwalkerDef`) pointant `sleepwalker.tscn` → `null`, `alive_enemy_count()` inchangé, aucun `Sleepwalker` dans l'arbre à l'image suivante.
- [ ] [Review][Patch] **`rush_duration` n'est pas validé : NaN ou INF bloque le Somnambule en `RUSH` pour toujours** [game/enemies/sleepwalker/sleepwalker.gd:42-44, 95] — Seul champ de `SleepwalkerDef` qui ne passe ni par `_bounded_px()` ni par la validation de `Telegraph.start()` ; `_rush_ticks_left <= TICK_EPSILON` n'est jamais vrai pour NaN (AR28 incohérent). Correctif : dans `_ready()`, `_rush_seconds` = `rush_duration` si fini et > 0, sinon 0 avec `Log.error("combat", …)` + `_assert_failed()` (même modèle que `_bounded_px`) ; `_enter(RUSH)` lit `_rush_seconds`. Contrôle dans `t_invalid23` : `SleepwalkerDef` dupliqué avec `rush_duration = NAN` → le Somnambule repasse en `CHASE` au plus tard 2 ticks après la fin du télégraphe, un message d'assertion compté.
- [ ] [Review][Patch] **Valeurs du GDD en défaut des scripts de `Def`, dont celles du Somnambule dans la base commune** [game/enemies/enemy_def.gd:12-18 ; game/enemies/sleepwalker/sleepwalker_def.gd:6-14] — `EnemyDef.max_hp = 30.0` et les trois tailles du Somnambule sont les défauts de la base : un `night_light.tres` ou `sheep.tres` (2.4, 2.5) qui oublie un champ hérite en silence des valeurs du Somnambule ; et Godot omet d'un `.tres` réenregistré toute valeur égale au défaut du script, si bien que les valeurs du GDD ne vivraient plus que dans le script (AR9, point 14 de la stratégie : la règle de `run_all.sh` a été rétrécie aux lignes non `@export`). Correctif (décision 32) : défauts neutres (`max_hp = 0.0`, tailles `Vector2.ZERO`, champs de `SleepwalkerDef` à `0.0`) ; la validation existante (`HitPoints._init`, `Enemy._pixel_size`, `Sleepwalker._bounded_px`, `rush_duration` ci-dessus) signale un oubli par `Log.error` + `assert` ; `sleepwalker.tres` garde toutes ses valeurs explicites (vérifier après un `--import` qu'elles y sont toujours) ; retirer l'exclusion des lignes `@export` de la règle « nombres du GDD » de `run_all.sh` pour `enemies/`. `CombatTuning` n'est pas concerné (précédent des stories 1.x, une seule instance).
- [ ] [Review][Patch] **Aucun `Log.debug` au départ d'un télégraphe** [game/combat/telegraph.gd:43-50] — « Règles d'architecture › Logs (AR27) : `Log.debug` pour apparition, coup, mort, télégraphe » ; apparition, coup et mort journalisent, pas le télégraphe. Correctif : dans `Telegraph.start()`, après le calcul de `duration`, `Log.debug("combat", "telegraph %s started duration=%.2f" % [get_parent().name if get_parent() != null else name, duration])` (une fois par départ, jamais par tick : `start()` n'est pas un `_physics_process`, la règle de `run_all.sh` reste vérifiée). Contrôle : une ligne `telegraph … started` par télégraphe dans le journal de `t_sleepwalker`, aucune entre deux départs.
- [ ] [Review][Patch] **« Un mort ne touche plus / ne bloque plus » : vérification comportementale possible et absente ; l'entrée de `deferred-work.md` donne une raison fausse** [_bmad-output/implementation-artifacts/deferred-work.md, section « story 2-3 », entrée « Libération d'un ennemi mort »] — L'entrée affirme qu'« aucun tick ne s'écoule entre sa mort et sa libération qu'un test puisse observer » : faux. Le code garantit bien le comportement (le `SceneTree` reteste `can_process()` à chaque envoi de `_physics_process`, la `Hitbox` enfant est donc sautée dès le tick suivant la mort, rattrapage compris ; corps retiré de l'espace par `DISABLE_MODE_REMOVE`), mais les contrôles de `t_sleepwalker` ne le prouvent pas : « killed before contact » tue l'ennemi **avant** le contact et sans témoin ; « the player walks through » marche après `ticks(3)`, quand l'ennemi est déjà libéré. Correctif : (1) contrôle « ne touche plus » : un nœud de test à `process_physics_priority = 10` (< 50) appelle, dans son `_physics_process`, un `hurtbox.receive()` mortel sur un Somnambule dont la zone de contact recouvre le joueur vulnérable → aucun `player_hit` à ce tick ni après ; témoin : même montage, coup non mortel → `player_hit` au même tick ; (2) contrôle « ne bloque plus » : nœud de test à priorité −1 qui tue l'ennemi, puis le joueur (priorité 0) avance par `move_and_slide()` dans le même tick à travers l'emplacement ; témoin : ennemi vivant → bloqué ; (3) réécrire l'entrée de `deferred-work.md` en conséquence, et y consigner que le coup mortel d'un tir (priorité 100) arrive **après** la `Hitbox` (50) : un contact peut encore toucher au tick même de la mort (ordre « contact puis mort », accepté) ; (4) corriger dans la même section l'entrée « Ressenti du contact » : la sonde « aucune poussée continue » ne vaut que hors accélération (voir le report de la poussée pendant l'accélération).
- [ ] [Review][Patch] **Scènes de vérification perdues, et contrôles creux ou sans témoin à réécrire** [game/.scratch/ (hors dépôt) : run_all.sh, t_enemy_parts, t_sleepwalker, t_enemy_main, t_invalid23] — Le scratchpad a été vidé par un redémarrage pendant la revue : les 11 scènes `PASS` annoncées ne peuvent plus être relancées. Recréer le dossier `godot-scratch` du scratchpad et le lien, réécrire `t_enemy_parts`, `t_sleepwalker`, `t_enemy_main`, `t_invalid23` et `run_all.sh` selon la « Stratégie de test » (les scènes de 2.1 et 2.2 ne se réécrivent pas : consigner que la régression repose sur les nouvelles scènes, plus import et lancement), avec ces corrections, d'après la lecture partielle faite par l'Acceptance Auditor avant la perte : `t_sleepwalker` ~l.107 « hurtbox unregistered after the free » vaut `true` dès que l'ennemi est libéré (tautologie) → tester `has_hurtbox()` vrai avant la mort puis faux dans un gestionnaire `tree_exiting` de la hurtbox connecté après celui du manager ; ~l.314-316 témoin « zone de la taille du corps » : `Hitbox` de test désactivée, seul `intersects()` est lu → la laisser active (zone de contact réelle désactivée pendant ce contrôle, joueur vulnérable, 120 ticks, 0 coup ; témoin : la même `Hitbox` de test à 12×12 → coup) ; ~l.438-445 « deux tirs mortels au même tick » : rien ne prouve la simultanéité → affirmer que les deux projectiles sont actifs au tick précédent et que le compte de projectiles actifs passe de 2 à 0 au même tick ; ~l.305 « centres ≈ 8,08 px » toléré entre 7,5 et 8,7 → 8,00 ± 0,1 (valeur mesurée) ; ~l.448-476 → remplacés par les contrôles du point précédent. Relire aussi `run_all.sh` (structure de la machine à états, nombres du GDD, `Log.` dans `_physics_process`), non relus par la revue. Les mutations du point 13 sont à refaire et à consigner.
- [ ] [Review][Patch] **T10 et point 15 cochés alors que les vérifications fenêtrées sont partielles** [_bmad-output/implementation-artifacts/2-3-affronter-le-somnambule.md, Debug Log, paragraphe « Fenêtré sous WSLg »] — Le Debug Log ne cite ni l'ennemi « sous les projectiles », ni le chiffre de dégâts, ni le recul à l'écran. Correctif : marquer ces trois éléments **NON VÉRIFIÉ** à l'écran dans le Debug Log et dans `deferred-work.md` (l'ordre de l'arbre reste vérifié en headless par `t_enemy_main`, CA 11), ou refaire les captures.
- [x] [Review][Defer] **Le Somnambule pousse le joueur pendant l'accélération** [game/enemies/sleepwalker/sleepwalker.gd:75-80 ; game/enemies/enemy.gd:115-121] — deferred : ressenti à juger au jeu, à régler au plus tard avec les trous (4.3) (décision 33).
- [x] [Review][Defer] **Son du télégraphe : un 4e télégraphe simultané est muet (`max_voices` 3), le son survit à un ennemi mort** [game/combat/telegraph.gd:49] — deferred, story 2.6 (vagues) ou 7.7.
- [x] [Review][Defer] **Base des ennemis pour la 2.4 : pas de `BulletManager` ennemi dans `Enemy.setup()`, `EnemyBullets` local à l'arène** [game/enemies/enemy.gd:28 ; game/rooms/arena/arena.gd:125-134] — deferred, story 2.4.
- [x] [Review][Defer] **Base des ennemis pour la 2.5 : `_move_toward()` ne fait qu'approcher un point et teste la validité de la cible, masque du corps avec `LAYER_PLAYER`, pas d'annulation de télégraphe** [game/enemies/enemy.gd:43, 115-121 ; game/combat/telegraph.gd:31] — deferred, story 2.5.
- [x] [Review][Defer] **Contrat des dégâts nuls : `BulletManager` accepte un tir à 0, `HitPoints` le refuse avec `assert`** [game/combat/hit_points.gd:26-29] — deferred, story 2.4 (rejoint le report « dégâts ennemis < 0,5 »).
- [x] [Review][Defer] **`Hurtbox.refuse_hit()` non réentrant** [game/combat/hurtbox.gd:73-77] — deferred, à reprendre dès qu'un gestionnaire peut rappeler `receive()`.

## Dev Notes

### Ce que cette story pose, et ce qu'elle ne pose pas

La base commune des ennemis (`Enemy` + `EnemyDef`), les PV flottants (`HitPoints`), le contact (`Hitbox`), le télégraphe (`Telegraph`), l'apparition par la salle (`spawn_enemy()`, distance minimale, compte des vivants), Le Somnambule, et la commande F1 qui en fait apparaître un. **Hors périmètre** (ne pas anticiper) :

| Élément | Story |
|---|---|
| La Veilleuse, La Berceuse, projectiles ennemis à couleur et contour réservés, dégâts ennemis < 0,5, projectile apparu dans une cellule solide | 2.4 |
| Le Mouton, charge en ligne droite, étourdissement contre un mur | 2.5 |
| Vagues, `Events.room_cleared`, « ennemi choisi », « tuer tout » et « vague suivante » dans F1, ennemis présents en début de partie | 2.6 |
| HUD | 2.7 |
| Télémétrie (cause de la mort, ennemis tués) | 2.8 |
| Danger (`DangerProfile`, `telegraph_mult` ≠ 1, vitesse des projectiles), renfort, Éveil qui repousse les ennemis, graze | Epic 3 |
| Classe `Room` commune aux salles, marqueurs `EnemySpawn`, obstacles, `RunRng` (tirage d'une position), `AStarGrid2D` | Epic 4 (4.2, 4.5, 4.7) |
| Reflet du Miroir (ennemi qui porte un build) | 5.10 |
| Sprites, animations (marche, télégraphe, mort), sons définitifs | Epic 7 |

### État actuel du dépôt (stories 1.1 à 2.2 `done`)

- **Autoloads** : `Log`, `Events`, `GameClock`, `Settings`, `SaveService`, `Audio` (dans cet ordre).
  - `Events` : `player_hit(damage: int, source: int)`, `enemy_damaged(world_position: Vector2, amount: float)`, `run_ended(outcome: int)`. Types primitifs seulement. **Cette story n'ajoute aucun signal au bus.**
  - `GameClock` : `enum Group { PLAYER, ENEMIES, ENEMY_BULLETS, PLAYER_BULLETS, WORLD, FX }`, `paused` (écrit par `Main._freeze()` seul), `global_multiplier` borné à [0, 1] (F4), `scale(group)` nul en pause.
  - `Audio.play_sfx(stream, max_voices = 3) -> bool`, `voices_of(stream)`. Ne pas modifier.
  - `Log` : catégories `run`, `room`, `combat`… Cette story utilise `combat` et `room`.
- **`core/`** : `Const` (`TILE_SIZE` 16, `ROOM_TILES` 36×19, `HUD_BAND_HEIGHT` 24, couches dont `LAYER_WALLS`, `LAYER_PLAYER`, `LAYER_ENEMIES` (1 << 5), `LAYER_PLAYER_HURTBOX`, `LAYER_ENEMY_HURTBOX`, groupes `GROUP_BULLET_MANAGERS`, `GROUP_DEBUG_SHAPES`, `GROUP_PLAYER`, `Z_INDEX_DECOR` −1, `PHYSICS_PRIORITY_BULLETS` 100). `Tuning` (`@abstract`, `PLAYER`, `DASH`, `SHOT`, `COMBAT` préchargés). Scripts des Resources de réglage dans `core/`, `.tres` dans `data/tuning/`. **`LAYER_ENEMIES` n'est utilisée par aucun nœud aujourd'hui.**
- **`core/combat_tuning.gd`** : `starting_half_hearts` 6, `heart_cap_half_hearts` 24, `hit_damage_half_hearts` 1, `hit_invulnerability_duration` 1,0 (`@export_range`, une ligne de doc par champ). **Pas de `min_telegraph` ni de distance d'apparition.**
- **`core/shot_tuning.gd`** : `damage` 10 (PV ennemis), `impact_flash_duration` 0,05 s, `impact_knockback_distance` 0,125 tuile (2 px), `impact_knockback_duration` 0,05 s : les retours d'impact de la 1.5 que `HitFeedback` lit déjà.
- **`combat/health.gd`** (`Health extends Node`) : **pensé pour le joueur** (demi-cœurs entiers, armure, plafond, invulnérabilité après un coup en ticks pondérés, invulnérabilité forcée). `apply_damage(info) -> int` (0 si refusé : mort, invulnérable, montant non fini ou `< 1` après arrondi avec `Log.error` + `assert`). Coup mortel : `changed` puis `died`. Pas touché.
- **`combat/hurtbox.gd`** (`Hurtbox extends Area2D`) : `@export var camp`, `one_hit_per_tick`, signal local `damage_received(info)`, `set_hit_filter(Callable)`, `is_hittable()` (forme, `monitorable`, `disabled`, dans l'arbre, filtre du propriétaire testé `is bool`, erreur journalisée une fois), `receive(info) -> bool` : `false` sans rien émettre si non touchable ; sinon `damage_received`, puis `Events.enemy_damaged` (haut centre du rectangle) pour le camp ennemi, puis `true` — **même si le propriétaire a refusé le coup dans son gestionnaire** (report de 2.1). `world_rect()` global (rotation et échelle ignorées). Commentaire d'en-tête : « The collision layer is for future Area2D consumers (contact, epic 2) » (à corriger : le contact n'utilise pas la physique, voir « `Hitbox` »).
- **`combat/damage_info.gd`** : `enum Source { PLAYER_SHOT = 0, ENEMY_BULLET = 1, DEBUG = 2 }` (valeurs explicites, ajout en fin), `amount`, `source`, `is_heavy`, `direction` ; `static from_bullet(amount, direction, source)`. Commentaire : « Contact and pits come with stories 2.3 and 4.3 ».
- **`combat/hit_feedback.gd`** (`HitFeedback extends Node`) : `setup(sprite, clock_group)` avant `add_child` : **écrase `sprite.material`** par un `ShaderMaterial` neuf (`hit_flash.gdshader`, paramètre `flash`) et crée un `SpriteKick` ; `play(direction)` ; `is_flashing()`. `vfx/sprite_kick.gd` : écrit `sprite.position` et **le remet à `Vector2.ZERO`** à la fin. Pas touchés (voir « Reports »).
- **`combat/bullets/bullet_manager.gd`** : priorité 100 ; `_refresh_target_rects()` lit `world_rect()` et `is_hittable()` **une fois par tick** ; `_test_targets()` enregistre les coups ; `_deliver_hits()` livre après la boucle, en sautant une cible libérée, désinscrite ou **en cours de suppression** (`_is_being_deleted()` remonte les parents : un ennemi qui fait `queue_free()` sur sa racine est bien sauté) ; résultat de `receive()` ignoré (projectile déjà libéré). `register_hurtbox()` (camp opposé, hurtbox dans l'arbre, désinscription sur `tree_exiting` en `CONNECT_ONE_SHOT`), `has_hurtbox()`. Pas touché.
- **`player/player.gd`** (`Player`, `CharacterBody2D`, origine = centre du torse) : `collision_layer = Const.LAYER_PLAYER`, **`collision_mask = Const.LAYER_WALLS`** (le dash traverse donc tout ce qui n'est pas un mur) ; `health` et `hurtbox` créés en code (hurtbox 6×6 px, camp `PLAYER`, `one_hit_per_tick`, filtre `_can_be_hit()` = `not is_invulnerable() and not health.is_dead()`, où `is_invulnerable()` = dash ou `Health`) ; `_on_hurtbox_damage_received(info)` : `lost = health.apply_damage(info)` ; `if lost <= 0: return` ; sinon `Events.player_hit`, son, `Log.debug`, mort éventuelle (`_die()`). `_physics_process` : moteur, `_dash.tick()`, tir, `move_and_slide()` (`MOTION_MODE_FLOATING`), teinte, clignotement. Groupe `player`.
- **`player/dash.gd`** : vitesse 3 tuiles en 0,18 s, invulnérabilité les 0,15 premières secondes (posée avant le mouvement du tick). Le dash se fait par `move_and_slide()` : il s'arrête sur tout ce que le masque du joueur contient. Pas touché.
- **`run/run.gd`** (`Run`) : `Player` puis `RoomSlot` ; instancie `ARENA_SCENE`, `arena.setup(_player)` avant `add_child`, place le joueur à `arena.player_spawn_position()` ((304, 168)). Pas touché.
- **`rooms/arena/arena.tscn`** : `Arena` (`Node2D`) > `Floor`, `Walls` (`TileMapLayer`, `%`), `Targets` (3 `TrainingTarget` en (464, 168), (144, 104), (144, 232)), `Camera` (`%Camera`). **`rooms/arena/arena.gd`** (`Arena`) : `setup(player)` ; `_ready()` : décor en `Z_INDEX_DECOR`, tuiles, `_setup_player_bullets()` (`PlayerBullets`, **variable locale**, cibles inscrites, `_player.equip_bullets()` si joueur), `_setup_enemy_bullets()` (`EnemyBullets`, hurtbox du joueur inscrite), `_setup_damage_numbers()` ; caméra ; `player_spawn_position()`. Origine du monde = coin haut gauche du cadre de murs ; zone jouable : cellules 1 à 36 en x, 1 à 19 en y (pixels 16..592 × 16..320). **Aucun ennemi, aucun `spawn_enemy()`, aucun groupe.**
- **`rooms/arena/training_target.gd`** : modèle d'entité touchable : `hurtbox` dans la scène (12×20 px, `resource_local_to_scene`), `HitFeedback` sur `%Sprite`, gestionnaire unique de `damage_received`. Pas touché.
- **`main/main.gd`** : `RUN_SCENE` préchargé ; `_freeze()` seul écrit `GameClock.paused` et `ActiveScene.process_mode` ; pause, écran de réveil (`_run_over`), relance (`_start_run()` : retire l'ancien `Run`, dégèle, ajoute le nouveau) ; F4, F5 en debug et hors pause ; panneau F1 chargé par `load()` en debug. Pas touché.
- **`debug/debug_panel.gd`** : touches 1 à 5 (`physical_keycode`, ignorées en pause et panneau caché), joueur par le groupe `player`, manager ennemi par `has_hurtbox(player.hurtbox)`, `_log()` / `_last_message`, texte rafraîchi. Exempté de `tr()`.
- **`debug/collision_drawer.gd`** (F2) : dessine tout `CollisionShape2D` du groupe `GROUP_DEBUG_SHAPES` (rectangles et cercles, une seule couleur).
- **`audio/sfx/`** : `sfx_player_shot.wav`, `sfx_player_hit.wav` (générés par script, `.import` versionnés).
- **`project.godot`** : physique à 60 Hz, **interpolation physique activée** (`reset_physics_interpolation()` après tout placement par code), couche 6 nommée `enemies`, avertissements de typage en erreur.
- **Il n'existe ni `enemies/`, ni `data/enemies/`, ni `Hitbox`, ni `Telegraph`, ni PV d'ennemi.**
- **`game/.scratch`** : lien vers le scratchpad du pipeline, exclu de git. `run_all.sh` lance `t_health`, `t_arena`, `t_misc`, `t_death`, `t_isolated`, `t_load`, `t_invalid` (7 scènes `PASS` au dernier passage), vérifie les journaux `run`, la recherche des interdits et l'écriture de `GameClock.paused`, chaque contrôle avec un témoin qui doit échouer. **Le lien est vide au début d'une nouvelle session du pipeline** : s'il manque, recréer le dossier `godot-scratch` du scratchpad et le lien ; si les scènes 2.1/2.2 ont disparu, consigner que la régression repose sur les nouvelles scènes plus import et lancement (ne pas réécrire les anciennes).

### Reports traités par cette story (`deferred-work.md`)

| Report | Origine | Réponse de cette story |
|---|---|---|
| `Hurtbox.receive()` renvoie `true` et émet `Events.enemy_damaged` même si le propriétaire refuse le coup ; à trancher avec les PV des ennemis | revue 2.1 | CA 6 : `Hurtbox.refuse_hit()`, appelé par le propriétaire dans son gestionnaire (ennemi et joueur) |
| `Health` pensée pour le joueur ; la 2.3 décide si les ennemis la réutilisent | 2.1, décision 6 | Non : `HitPoints` (PV flottants, ni armure ni invulnérabilité), `Health` inchangée |
| `SpriteKick` suppose un sprite au repos en (0, 0) et `HitFeedback.setup()` écrase le `material` du sprite : à revoir avec Le Somnambule | revue 1.5 | Règle posée pour les ennemis : `%Sprite` en (0, 0) (ancrage par `offset`), sans `material` propre ; l'animation du télégraphe change la `texture`, jamais `position` ni `material` |
| Désinscription des hurtbox par `tree_exiting` en `CONNECT_ONE_SHOT` : une hurtbox déplacée ou mise en pool n'est plus touchée ; à revoir avec un pool d'ennemis | revue 1.5 | Sans objet : pas de pool d'ennemis (architecture : pools pour les projectiles et effets seulement), un ennemi n'est jamais déplacé d'un parent à l'autre (règle écrite dans `Enemy`) |
| `CollisionDrawer` ignore les formes autres que rectangle et cercle et les formes désactivées, à traiter avec la `Hitbox` | 1.3 / 1.5 | Partiel : `Hitbox` porte un `RectangleShape2D` et rejoint le groupe F2 (dessinée sans changer `CollisionDrawer`) ; formes désactivées : toujours ouvert |
| `DamageInfo` : « Contact and pits come with stories 2.3 and 4.3 » | 2.1 | `Source.CONTACT = 3` |

**Restent ouverts** (ne pas traiter ici) : dégâts ennemis < 0,5 et projectile apparu dans une cellule solide (2.4) ; `TICK_EPSILON` dans `Dash` ; `equip_bullets()` répétable et sortie de salle (4.8) ; mesure de 10 minutes à 400 projectiles sur la machine de référence (**étape humaine, NON FAITE**, à rappeler à Kroustille en fin d'epic).

### Leçons des stories 1.1 à 2.2 à appliquer

- **Chaque contrôle prouve son mécanisme, avec un témoin, et doit pouvoir échouer** (revues de 2.1 et 2.2). Ici plusieurs mécanismes se recouvrent : un joueur qui « ne prend pas de coup » peut être invulnérable, hors de portée ou derrière un ennemi bloqué ; un Somnambule qui « s'arrête » peut être en télégraphe, figé par la pause ou mort. Chaque point de la « Stratégie de test » dit ce qu'il isole et donne son témoin. Les contrôles par mutation (le mécanisme retiré sur une copie, le contrôle doit échouer) sont consignés dans le Debug Log.
- **Ordre des ticks** : entités à 0, puis (nouveau) `Hitbox` à 50, puis `BulletManager` à 100. Un test de touche lit l'état du tick courant. Un composant enfant d'une entité, à la même priorité, tique **après** elle (ordre de l'arbre) : c'est ce qui fixe le nombre de ticks du télégraphe (voir « Le Somnambule »).
- **Typage strict, avertissements en erreur** : `PackedScene.instantiate()` renvoie un `Node` : `as Enemy` n'est pas un `UNSAFE_CAST` (comme `as Arena` dans `run.gd`) ; `_def as SleepwalkerDef` (Resource vers sous-classe) non plus ; le résultat d'un `Callable.call()` est un `Variant` : `is` avant usage.
- **Injection** : `setup()` avant `add_child()` ; composants créés en code avec un `name` explicite ; formes **neuves** par instance (jamais une sous-ressource partagée) ; pas de `/root/...` ni `get_parent().get_parent()`.
- **AR28** : calculer la valeur sûre avant de journaliser ; `setup()` oublié ou donnée invalide → `Log.error` + `assert`, le reste continue. En debug headless, un `assert(false)` imprime un `SCRIPT ERROR` et le jeu continue : les chemins d'erreur se vérifient dans des scènes à part, qui comptent les messages d'assertion attendus (modèle : `t_invalid` et sa règle dans `run_all.sh`).
- **Ticks** : compteurs décrémentés de `GameClock.scale(groupe)`, `TICK_EPSILON = 1e-6`. Pas de `Timer`, `create_timer`, `Tween` en temps réel.
- **Vérifications** : `--import`, puis `--quit-after 120` (zéro `SCRIPT ERROR`, zéro `Parse Error`, seul avertissement connu : `settings.cfg missing`) ; scènes du scratchpad (`--scene res://.scratch/<scène>.tscn`) ; `Input.parse_input_event()` s'applique au tick suivant ; `preload()` dans les scripts de test (pas de `class_name` vu depuis un dossier caché), `@warning_ignore_start(...)` pour les `unsafe_*` des scripts jetables seulement.
- **Fichiers générés par Godot** : versionner les `.uid` des nouveaux scripts et le `.wav.import` ; `strings.fr.translation` n'est pas versionné (rien à commiter, aucun texte joueur dans cette story).

### `CombatTuning` (AR9, CA 1, 3)

Ajouter dans `core/combat_tuning.gd` et `data/tuning/combat_tuning.tres` :

| Champ | Type | Valeur | Source |
|---|---|---|---|
| `min_telegraph` | `float` (s) | 0.4 | FR26 / AR7 : aucun télégraphe sous 0,4 s, y compris en Abandon (CA 3) |
| `min_spawn_distance` | `float` (tuiles) | 3.0 | FR31 : aucun ennemi à moins de 3 tuiles du joueur |

`@export_range` et une ligne de doc par champ, comme les autres. Mettre à jour le commentaire d'en-tête de la classe (elle ne porte plus seulement la santé : « balancing values of health, hits, telegraphs and spawns »). Les **dégâts au contact** n'ont pas de champ : un contact est « un coup de ½ cœur » (CA 4), donc `hit_damage_half_hearts` (qui deviendra 1 cœur à l'étage 3, FR12).

### `HitPoints` (« Dégâts et unités » : ennemis en PV flottants)

`combat/hit_points.gd`, `class_name HitPoints extends RefCounted`. Pas de tick (ni armure ni invulnérabilité), donc pas de nœud. Servira aussi aux meubles (30 PV, 4.4) et au cauchemar.

```gdscript
class_name HitPoints
extends RefCounted
## Hit points of an enemy (floats: enemies count HP, the player counts half-hearts in Health).
## No armor, no invulnerability: a dead owner refuses every hit. Runtime state: the EnemyDef stays read-only.

var current: float = 0.0
var maximum: float = 0.0

## max_hp not finite or <= 0: bounded to 1 with Log.error + assert (AR28).
func _init(max_hp: float) -> void

## Returns the HP removed (at most current). 0 when dead, or when amount is not finite or <= 0
## (Log.error + assert: a refused hit).
func apply_damage(amount: float) -> float

func is_dead() -> bool  # current <= 0
```

Pas de signal : le propriétaire lit le retour de `apply_damage()` et `is_dead()` dans son gestionnaire (le HUD du cauchemar ajoutera un signal le jour où il en aura besoin).

### `Telegraph` (AR7, FR26, CA 2, 3)

`combat/telegraph.gd`, `class_name Telegraph extends Node`. Toute attaque d'ennemi passe par lui.

```gdscript
class_name Telegraph
extends Node
## Announces an attack (FR26, AR7): every enemy attack starts with start(). Its duration is
## max(base x multiplier, Tuning.COMBAT.min_telegraph), counted in game ticks of the owner's clock group.
## Plays the telegraph sound; the animation is the owner's (it swaps its sprite texture on the same tick).
## The multiplier stays 1 until the danger exists (epic 3: room.danger.telegraph_mult).

const TICK_EPSILON: float = 1e-6

## Dependency injection: call before add_child().
func setup(clock_group: GameClock.Group) -> void

## Starts (or restarts) the telegraph. Returns its duration in seconds.
func start(base_seconds: float, sound: AudioStream, multiplier: float = 1.0) -> float

func is_active() -> bool
```

- `start()` : `base_seconds` non fini ou négatif → 0 ; `multiplier` non fini ou négatif → 1 ; dans les deux cas `Log.error("combat", ...)` + `assert`. Durée = `maxf(base * multiplier, Tuning.COMBAT.min_telegraph)` ; `_ticks_left = durée × Engine.physics_ticks_per_second` ; `Audio.play_sfx(sound)` (son nul → `Log.error` + `assert`, le télégraphe démarre quand même : la durée prime). `Log.debug` au plus, jamais par tick.
- `_physics_process` : si actif, `_ticks_left -= GameClock.scale(_clock_group)` ; à ≤ `TICK_EPSILON` : inactif. Figé en pause, ×4 plus long sous F4.
- `_ready()` sans `setup()` : `Log.error` + `assert` + `set_physics_process(false)` (modèle : `HitFeedback`).
- **Ordre des ticks** : enfant de l'ennemi, même priorité, il tique **après** lui. Démarré au tick N par l'ennemi, il passe de 24 à 23 au tick N, et à 0 au tick N + 23 ; l'ennemi le voit inactif au tick N + 24. Le Somnambule bouge donc à nouveau, en accélération, au tick N + 25 (voir plus bas) : 25 ticks immobile, bras levés, ≥ 24 = 0,4 s (FR26 : « au moins 0,4 s avant »).

### `Hitbox` de contact (FR12 contact, CA 4, 7)

`combat/hitbox.gd`, `class_name Hitbox extends Area2D`, sur le modèle de `Hurtbox` (un `CollisionShape2D` enfant à `RectangleShape2D`, rejoint le groupe F2). **Pas de recouvrement physique** (`area_entered` ou `get_overlapping_areas()` reflètent l'état du tick précédent et ne redonnent rien tant que les zones restent en contact) : le test est fait à la main, comme dans le `BulletManager` (D1), dans le tick courant.

```gdscript
class_name Hitbox
extends Area2D
## Contact damage zone of an entity (FR12: enemies also hurt on contact). Contact is not an attack: no telegraph.
## No physics overlap: every tick, after the entities (Const.PHYSICS_PRIORITY_HITBOXES), it tests its rectangle
## against its target's Hurtbox (world_rect(), is_hittable()) and delivers a DamageInfo through Hurtbox.receive().
## The hit filter of the target (invulnerability after a hit, dash, F1) turns the contact into a continuous one:
## a new hit lands as soon as the target can be hit again while the zones still overlap.
## Its CollisionShape2D child must hold a RectangleShape2D; it joins the F2 debug group.

## Whose zone this is: an ENEMY hitbox hits PLAYER-camp hurtboxes, and the other way round.
@export var camp: BulletManager.Camp = BulletManager.Camp.ENEMY

## Dependency injection: call before add_child().
func setup(target: Hurtbox, damage: float, source: DamageInfo.Source, clock_group: GameClock.Group) -> void

func world_rect() -> Rect2
```

- `_ready()` : `process_physics_priority = Const.PHYSICS_PRIORITY_HITBOXES` ; `collision_layer = 0`, `collision_mask = 0`, `monitoring = false`, `monitorable = false` ; forme rectangle obligatoire (sinon `Log.error` + `assert`, inactif) ; groupe F2. Sans `setup()`, cible nulle ou du même camp : `Log.error` + `assert`, inactif.
- `_physics_process` : `if GameClock.scale(_clock_group) <= 0.0: return` ; `if not is_instance_valid(_target) or not _target.is_hittable(): return` ; si `world_rect().intersects(_target.world_rect())` (bords exclus, doc `Rect2` 4.7) : `DamageInfo` (`amount = damage`, `source`, `direction` = du centre de la zone vers le centre de la cible, normalisée, `ZERO` si confondus) → `_target.receive(info)`. Aucun log.
- **Un coup au plus par tick sur le joueur** : le premier coup accepté ouvre l'invulnérabilité, donc `is_hittable()` est faux pour une seconde `Hitbox` et pour les `BulletManager` (priorité 100) du même tick. Rien à ajouter.
- `Const.PHYSICS_PRIORITY_HITBOXES: int = 50`, commentée : « contact hitboxes tick after the entities (0) and before the BulletManagers (100): they read this tick's positions and invulnerabilities (story 2.3) ».

### `Hurtbox` (CA 6)

`combat/hurtbox.gd` :

```gdscript
var _refused: bool = false

## Called by the owner from its damage_received handler when it does not apply the hit (invalid amount, already
## dead): receive() then returns false and notifies nothing more (no Events.enemy_damaged).
## The owner is the only listener of damage_received. Outside a handler it has no effect.
func refuse_hit() -> void:
	_refused = true

func receive(info: DamageInfo) -> bool:
	if not is_hittable():
		return false
	_refused = false
	damage_received.emit(info)
	if _refused:
		return false
	# ... Events.enemy_damaged for the ENEMY camp, unchanged
	return true
```

Mettre à jour la doc de `receive()` et l'en-tête : la couche de collision de la hurtbox ne sert plus « au contact » (le contact est la `Hitbox`, test à la main) ; elle reste pour de futurs lecteurs physiques (lancer de rayon du Glissement, epic 3). `TrainingTarget` n'appelle jamais `refuse_hit()` : comportement inchangé.

### `EnemyDef` (AR9, D4, CA 2)

`enemies/enemy_def.gd` (emplacement de l'architecture : `enemies/ — enemy.gd, enemy_def.gd`), `class_name EnemyDef extends Resource`. **Seulement ce que les quatre ennemis ont en commun** ; chaque ennemi ajoute ses valeurs dans une sous-classe (`SleepwalkerDef` ici ; 2.4 et 2.5 feront de même). Distances en tuiles, durées en secondes ; conversion en pixels à un seul endroit (le `setup()`/`_ready()` de l'ennemi, une fois).

| Champ | Type | Somnambule | Rôle |
|---|---|---|---|
| `id` | `StringName` | `&"sleepwalker"` | logs ; vagues (2.6) et télémétrie (2.8) plus tard |
| `scene` | `PackedScene` | `sleepwalker.tscn` | instanciée par `room.spawn_enemy()` |
| `max_hp` | `float` | 30.0 | GDD, FR27 |
| `body_size` | `Vector2` (tuiles) | (0.625, 0.625) = 10×10 px | corps physique : murs, joueur, ennemis |
| `hurtbox_size` | `Vector2` (tuiles) | (0.75, 1.25) = 12×20 px | zone touchée par les tirs (comme les cibles d'entraînement) |
| `contact_size` | `Vector2` (tuiles) | (0.75, 0.75) = 12×12 px | zone de contact ; **plus grande que le corps** |

- Les trois tailles sont des valeurs de jeu provisoires (le GDD ne les donne pas, voir les décisions), toutes centrées sur l'origine de l'ennemi.
- **Pourquoi la zone de contact dépasse le corps** : le corps du joueur (6×6) et celui de l'ennemi se bloquent l'un l'autre (`move_and_slide()`), leurs centres restent à ≈ 8,08 px (5 + 3 + marge de sécurité de 0,08 px, mesuré par sonde à la création). Hurtbox du joueur (demi-côté 3) + zone de contact (demi-côté 6) = 9 > 8,08 : les zones se recouvrent au contact. Une zone de la taille du corps ne toucherait jamais.
- Validation (AR28) : dans `Enemy.setup()`, `max_hp` borné par `HitPoints`, tailles non finies ou ≤ 0 bornées à 1 px avec `Log.error` + `assert`.

### `Enemy` (AR7, D2, CA 2, 5, 7, 8)

`enemies/enemy.gd`, `class_name Enemy extends CharacterBody2D`. Base minimale : corps, PV, hurtbox, zone de contact, retours d'impact, télégraphe, mort, déplacement en ligne directe. **La machine à états est dans chaque ennemi**, pas dans la base.

```gdscript
class_name Enemy
extends CharacterBody2D
## Base of the enemies (AR7, D2): body, HitPoints, Hurtbox (player shots), contact Hitbox, HitFeedback and
## Telegraph, created in code from the EnemyDef. Spawned only by a room (room.spawn_enemy()): setup() before
## add_child(). Never pooled nor moved to another parent: its Hurtbox unregisters from the BulletManager when it
## leaves the tree. Node origin = center of the body.
## Subclasses hold the state machine: an enum, one _process_<state>() per state, transitions in _enter() only.
## Scene contract: a %Sprite (Sprite2D) at (0, 0) without material of its own (HitFeedback sets one, SpriteKick
## puts it back at (0, 0)): anchor it with offset, animate it with texture; a %Body (CollisionShape2D).

var hp: HitPoints
## Registered by the room with the player's BulletManager.
var hurtbox: Hurtbox
var telegraph: Telegraph

var _def: EnemyDef
var _target: Node2D
var _target_hurtbox: Hurtbox
var _contact: Hitbox
var _feedback: HitFeedback
var _dead: bool = false

@onready var _sprite: Sprite2D = %Sprite
@onready var _body: CollisionShape2D = %Body

## Dependency injection: call before add_child(). target: what the enemy chases; target_hurtbox: what its contact hits.
func setup(def: EnemyDef, target: Node2D, target_hurtbox: Hurtbox) -> void

func is_dead() -> bool
```

- **`_ready()`** : sans `setup()` ou `def` nul : `Log.error("combat", ...)` + `assert`, `process_mode = PROCESS_MODE_DISABLED`, `return` (la sous-classe teste `_def != null` après `super()`). Sinon :
  - `motion_mode = MOTION_MODE_FLOATING` ; `collision_layer = Const.LAYER_ENEMIES` ; `collision_mask = Const.LAYER_WALLS | Const.LAYER_PLAYER | Const.LAYER_ENEMIES` ;
  - `_body.shape` = `RectangleShape2D` **neuf** de `def.body_size × TILE_SIZE`, `_body` dans le groupe F2 ;
  - `hp = HitPoints.new(def.max_hp)` ;
  - `hurtbox` : `Hurtbox.new()`, `name = "Hurtbox"`, `camp = ENEMY`, `CollisionShape2D` + `RectangleShape2D` neuf de `def.hurtbox_size` ajouté **avant** `add_child(hurtbox)` (son `_ready()` cherche la forme) ; `set_hit_filter(_can_be_hit)` ; `damage_received` → `_on_hurtbox_damage_received` ;
  - `_contact` : `Hitbox.new()`, `name = "ContactHitbox"`, `camp = ENEMY`, forme neuve de `def.contact_size`, `setup(target_hurtbox, Tuning.COMBAT.hit_damage_half_hearts, DamageInfo.Source.CONTACT, GameClock.Group.ENEMIES)` avant `add_child` ;
  - `_feedback` : `HitFeedback.new()`, `setup(_sprite, GameClock.Group.ENEMIES)` avant `add_child` ;
  - `telegraph` : `Telegraph.new()`, `name = "Telegraph"`, `setup(GameClock.Group.ENEMIES)` avant `add_child`.
- **`_can_be_hit()`** : `not hp.is_dead()`.
- **`_on_hurtbox_damage_received(info)`** (gestionnaire unique : PV d'abord, retours ensuite) :

```gdscript
func _on_hurtbox_damage_received(info: DamageInfo) -> void:
	var removed: float = hp.apply_damage(info.amount)
	if removed <= 0.0:
		hurtbox.refuse_hit() # no damage number, receive() returns false (CA 6)
		return
	_feedback.play(info.direction) # flash and 2 px knockback of story 1.5
	Log.debug("combat", "%s hit amount=%s hp=%s" % [_def.id, removed, hp.current])
	if hp.is_dead():
		_die()
```

- **`_die()`** (une seule fois, drapeau `_dead`) : `process_mode = PROCESS_MODE_DISABLED` (arrête l'ennemi **et ses enfants** : `Hitbox`, `Telegraph`, `HitFeedback` ; et retire le corps de la physique, `disable_mode` par défaut `DISABLE_MODE_REMOVE`, doc `CollisionObject2D` 4.7 et sonde à la création : un joueur traverse ensuite l'emplacement) ; `visible = false` (pas d'animation de mort avant l'epic 7) ; `Log.debug("combat", "%s died" % _def.id)` ; `queue_free()`. Appelé depuis `_deliver_hits()` du `BulletManager` (priorité 100) : désactiver un ancêtre de `CharacterBody2D` et d'`Area2D` à ce moment ne lève aucune erreur (sonde de 2.2). Libéré à la fin de l'image : entre-temps, dans les ticks de rattrapage, il ne bouge plus, ne touche plus, et les tirs le traversent (filtre).
- **`_move_toward(point: Vector2, speed_px: float, clock_scale: float) -> void`** : la ligne directe d'AR23 à un seul endroit (`AStarGrid2D` la remplacera en 4.5) : `var to: Vector2 = point - global_position` ; `velocity = ZERO` si `to.length_squared() < 1e-6`, sinon `to.normalized() * speed_px * clock_scale` ; `move_and_slide()`. `velocity` réécrite à chaque tick (ne jamais la relire après `move_and_slide()`).
- **`_target_position() -> Vector2`** et **`_distance_to_target() -> float`** : depuis `_target.global_position` ; cible non valide (`is_instance_valid`) → l'ennemi ne bouge pas (vitesse nulle, pas d'erreur par tick).
- Pas de signal `died` sur l'ennemi ni sur le bus : la salle compte par `tree_exited` (architecture, « Création d'entités ») ; la 2.6 ajoutera ce dont les vagues ont besoin.

### Le Somnambule (FR27, CA 2, 3, 4, 5)

**`enemies/sleepwalker/sleepwalker_def.gd`** : `class_name SleepwalkerDef extends EnemyDef`.

| Champ | Type | Valeur | Source (GDD, FR27) |
|---|---|---|---|
| `walk_speed` | `float` (tuiles/s) | 2.5 | marche vers le joueur |
| `rush_trigger_range` | `float` (tuiles) | 2.0 | « à moins de 2 tuiles » |
| `telegraph_duration` | `float` (s) | 0.4 | lève les bras 0,4 s |
| `rush_speed` | `float` (tuiles/s) | 5.0 | accélère à 5 tuiles/s |
| `rush_duration` | `float` (s) | 0.6 | pendant 0,6 s |

**`data/enemies/sleepwalker.tres`** (`script_class="SleepwalkerDef"`) : les valeurs ci-dessus, plus celles d'`EnemyDef` (`id`, `scene` = `res://enemies/sleepwalker/sleepwalker.tscn`, `max_hp` 30, tailles). `data/` ne contient que des `.tres`.

**`enemies/sleepwalker/sleepwalker.tscn`** : racine `Sleepwalker` (`CharacterBody2D`, script `sleepwalker.gd`) > `Sprite` (`Sprite2D`, `unique_name_in_owner`, en (0, 0), sans `material`) et `Body` (`CollisionShape2D`, `unique_name_in_owner`, forme posée en code). Rien d'autre : les composants sont créés par `Enemy`.

**`enemies/sleepwalker/sleepwalker.gd`** :

```gdscript
class_name Sleepwalker
extends Enemy
## Le Somnambule (FR27): walks straight at the player, arms out. Within rush_trigger_range it stops and raises its
## arms (Telegraph: animation and sound), then rushes at rush_speed for rush_duration, still steering at the player,
## then walks again. Contact hurts in every state (Enemy's Hitbox). Every value comes from SleepwalkerDef.

enum State { CHASE, TELEGRAPH, RUSH }

## Placeholder telegraph sound, generated by a script; replaced by story 7.7.
const TELEGRAPH_SOUND: AudioStream = preload("res://audio/sfx/sfx_enemy_sleepwalker_telegraph.wav")
const TICK_EPSILON: float = 1e-6

var _state: State = State.CHASE
var _walk_speed_px: float = 0.0
var _rush_speed_px: float = 0.0
var _trigger_range_px: float = 0.0
var _rush_ticks_left: float = 0.0
var _sleepwalker_def: SleepwalkerDef
var _walk_texture: Texture2D
var _raise_texture: Texture2D


func _physics_process(_delta: float) -> void:
	var clock_scale: float = GameClock.scale(GameClock.Group.ENEMIES) # one read per tick
	if clock_scale <= 0.0:
		return
	match _state:
		State.CHASE:
			_process_chase(clock_scale)
		State.TELEGRAPH:
			_process_telegraph(clock_scale)
		State.RUSH:
			_process_rush(clock_scale)


func _process_chase(clock_scale: float) -> void:
	if _distance_to_target() < _trigger_range_px:
		_enter(State.TELEGRAPH)
		return
	_move_toward(_target_position(), _walk_speed_px, clock_scale)


func _process_telegraph(_clock_scale: float) -> void:
	if not telegraph.is_active():
		_enter(State.RUSH)


func _process_rush(clock_scale: float) -> void:
	if _rush_ticks_left <= TICK_EPSILON:
		_enter(State.CHASE)
		return
	_move_toward(_target_position(), _rush_speed_px, clock_scale)
	_rush_ticks_left -= clock_scale


## The only place that writes _state.
func _enter(next: State) -> void:
	_state = next
	match next:
		State.CHASE:
			_sprite.texture = _walk_texture
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			_sprite.texture = _raise_texture
			telegraph.start(_sleepwalker_def.telegraph_duration, TELEGRAPH_SOUND)
		State.RUSH:
			_sprite.texture = _walk_texture
			_rush_ticks_left = _sleepwalker_def.rush_duration * Engine.physics_ticks_per_second
```

- **`_ready()`** : `super()` ; `if _def == null: return` (déjà signalé) ; `_sleepwalker_def = _def as SleepwalkerDef` ; nul → `Log.error("combat", "sleepwalker needs a SleepwalkerDef")` + `assert` + `process_mode = PROCESS_MODE_DISABLED`, `return`. Conversion **une fois** : vitesses × `TILE_SIZE` (px/s), portée × `TILE_SIZE` (px). Valeurs non finies ou ≤ 0 → bornées (`Log.error` + `assert`). Textures provisoires générées en code ; `_enter(State.CHASE)` (pose la texture de marche).
- **Mesures** (centre à centre, origines des nœuds : centre du corps de l'ennemi, centre du torse du joueur) : déclenchement quand la distance est **strictement** inférieure à 32 px.
- **Nombre de ticks** (60 Hz, échelle 1) :
  - marche : 40 px/s, soit 2/3 px par tick ; accélération : 80 px/s, soit 4/3 px par tick ;
  - télégraphe démarré au tick N (le Somnambule ne bouge pas au tick N) ; inactif vu par l'ennemi au tick N + 24 → `_enter(RUSH)` (tick sans mouvement) ; premier mouvement d'accélération au tick N + 25 ; **36 ticks** d'accélération (N + 25 à N + 60), soit 48 px = 3 tuiles en ligne droite ; au tick N + 61, `_enter(CHASE)` (tick sans mouvement) ; marche dès N + 62 ;
  - chaque transition prend donc un tick sans mouvement ; l'essentiel : télégraphe ≥ 24 ticks avant le premier tick rapide (FR26), accélération de 36 ticks exactement.
- **Pendant le télégraphe, il ne bouge pas** ; **pendant l'accélération, il continue de viser le joueur** (sa position à chaque tick) ; **pas de récupération** après l'accélération : si le joueur est encore à moins de 2 tuiles, il relève aussitôt les bras (voir les décisions 5 à 7).
- **Contact** dans tous les états (la `Hitbox` de la base, indépendante de l'état) : le contact n'est pas une attaque, il n'a pas de télégraphe (FR26).
- **Textures provisoires** (constantes visuelles locales, « placeholder until epic 7 ») : toile 16×24, couleur distincte du joueur (bleu), des cibles (orange) et du tir du joueur (cyan), par exemple un violet pâle ; `_walk_texture` : corps + bras tendus (deux barres horizontales de part et d'autre, à hauteur de poitrine) ; `_raise_texture` : corps + bras levés (deux barres verticales au-dessus des épaules). Silhouettes nettement différentes à 640×360 ; l'animation change **seulement** `texture` (ni `position`, ni `material`, ni `modulate` : `HitFeedback` et `SpriteKick` s'en servent).

### Son du télégraphe (FR26)

Générer `game/audio/sfx/sfx_enemy_sleepwalker_telegraph.wav` par un script jetable du scratchpad (`uv run python <script>`, module standard `wave`, même méthode que `sfx_player_hit.wav`) : mono, 16 bits, 22 050 Hz, **≈ 0,35 s** (dans les 0,4 s du télégraphe), une sinusoïde **montante** (par exemple 300 → 700 Hz : « il lève les bras »), attaque courte puis décroissance, amplitude ≈ 0,4, distincte du tir (aigu, court) et du coup reçu (grave, descendant). **Aucun hasard.** Puis `--import`, versionner le `.wav` et son `.wav.import`. Nom selon la convention `sfx_<domaine>_<nom>.wav`. Son provisoire, remplacé par la 7.7.

### Joueur (FR4, CA 5, 6)

`player/player.gd` :

- `collision_mask = Const.LAYER_WALLS | Const.LAYER_ENEMIES` : le dash (et la marche) s'arrêtent sur le corps d'un ennemi (FR4 : « le dash traverse les projectiles, mais ni les murs ni les ennemis »). Les projectiles ne sont pas des corps : inchangé. Les cibles d'entraînement n'ont pas de corps : inchangé.
- Comportement mesuré par sonde à la création (deux `CharacterBody2D` flottants qui s'avancent l'un vers l'autre) : ils se bloquent, centres à ≈ 8,08 px ; au premier contact, la récupération de pénétration décale le corps immobile d'environ 1,3 px, puis plus rien : **aucune poussée continue** (le Somnambule ne pousse pas le joueur dans un mur).
- `_on_hurtbox_damage_received()` : `if lost <= 0: hurtbox.refuse_hit(); return` (CA 6 : un montant invalide n'est plus « hit applied » dans F1). Rien d'autre ne change.

### Arène (AR16 à venir, CA 1, 8, 10, 11)

`rooms/arena/arena.tscn` : ajouter `Enemies` (`Node2D`, `unique_name_in_owner`) **après `Targets`** et avant `Camera`. Les `BulletManager` et `DamageNumbers`, ajoutés en code à la fin, restent dessinés au-dessus des ennemis ; le décor est en `z_index` −1 ; le joueur (dans `Run`, avant `RoomSlot`) est dessiné avant l'arène, donc **sous** les ennemis (même couche Entités, sans conséquence).

`rooms/arena/arena.gd` :

- `var _player_bullets: BulletManager` (gardé par `_setup_player_bullets()`) ; `var _alive: int = 0` ; `@onready var _enemies: Node2D = %Enemies`.
- `_ready()` : `add_to_group(Const.GROUP_ROOM)` (`&"room"` : « the active room, one at a time (D14); found by debug tools without a node path »).
- **`spawn_enemy(def: EnemyDef, requested: Vector2) -> Enemy`** (seul chemin d'apparition, architecture « Création d'entités ») :

```gdscript
## Spawns an enemy: the only way (architecture, "Création d'entités"). requested: room coordinates (the room
## sits at the world origin). Closer than Tuning.COMBAT.min_spawn_distance to the player, or outside the
## playable area: replaced by the nearest valid position (deterministic, no RNG before epic 4).
## Returns null when it cannot spawn (Log.error).
func spawn_enemy(def: EnemyDef, requested: Vector2) -> Enemy:
	# def null, def.scene null, no player (setup() skipped): Log.error + assert, return null.
	var node: Node = def.scene.instantiate()
	var enemy: Enemy = node as Enemy
	if enemy == null:
		node.free() # never leak a refused instance
		# Log.error + assert, return null
	var position_px: Vector2 = _resolve_spawn_position(requested)
	enemy.setup(def, _player, _player.hurtbox) # before add_child()
	enemy.position = position_px
	_enemies.add_child(enemy)
	enemy.reset_physics_interpolation() # it does not trail from (0, 0)
	if _player_bullets != null:
		_player_bullets.register_hurtbox(enemy.hurtbox)
	_alive += 1
	enemy.tree_exited.connect(_on_enemy_tree_exited, CONNECT_ONE_SHOT)
	Log.debug("room", "spawned %s at %s alive=%d" % [def.id, position_px, _alive])
	return enemy

## Enemies spawned by this room and still in the tree (dead ones leave at the end of their frame).
func alive_enemy_count() -> int:
	return _alive
```

- **`_resolve_spawn_position(requested) -> Vector2`** :
  1. `bounds` : zone jouable en pixels (cellules 1 à 36 × 1 à 19, soit 16..592 × 16..320), réduite de `SPAWN_MARGIN` = 1 tuile de chaque côté (constante technique commentée : le corps n'apparaît pas contre un mur) → 32..576 × 32..304 ;
  2. `min_px = Tuning.COMBAT.min_spawn_distance × TILE_SIZE` (48 px) ; `valid(p)` = `bounds.has_point(p)` et `p.distance_to(player) >= min_px - 1e-3` (« à moins de 3 tuiles » est refusé, exactement 3 accepté) ;
  3. `requested` valide → le garder tel quel ;
  4. sinon, candidats dans cet ordre : `player + (requested - player).normalized() * min_px` (direction `Vector2.RIGHT` si `requested == player`), puis les quatre coins de `bounds` ; garder le **candidat valide le plus proche de `requested`** (égalité : ordre de la liste) ; `Log.debug("room", "spawn at %s refused (too close or outside), moved to %s")`. Le joueur ne peut être à moins de 3 tuiles que d'un seul coin (coins à ≥ 272 px les uns des autres) : un candidat valide existe toujours. Aucun tirage aléatoire (AR14 : `RunRng` arrive en 4.7 ; le RNG global est interdit).
- **`_on_enemy_tree_exited()`** : `_alive = maxi(_alive - 1, 0)`. Rien d'autre (cela arrive aussi quand l'arène elle-même quitte l'arbre à la relance : sans effet).
- Mettre à jour le commentaire d'en-tête de la classe (ennemis, `spawn_enemy()`, groupe `room`). Pas d'ennemi au lancement : l'arène reste vide jusqu'aux vagues (2.6).

### Panneau F1 (AR24, CA 12)

`debug/debug_panel.gd` :

- `const SLEEPWALKER_DEF: EnemyDef = preload("res://data/enemies/sleepwalker.tres")` (le panneau n'est chargé qu'en debug : aucune référence en release) ; `const SPAWN_REQUEST: Vector2 = Vector2(304, 40)` (constante de debug : haut centre de la zone jouable, même point que l'émetteur de test ; remplacé par la salle s'il est trop près du joueur).
- Touche **6** (`KEY_6`, mêmes règles que 1 à 5 : panneau visible, jeu hors pause, appui sans répétition) → `_spawn_sleepwalker()` : salle par `get_tree().get_first_node_in_group(Const.GROUP_ROOM) as Arena` (jamais en cache : l'arène est recréée à chaque partie et par F5) ; aucune → `_last_message = "no room"` (test de charge F5) ; sinon `room.spawn_enemy(SLEEPWALKER_DEF, SPAWN_REQUEST)` → `_log("sleepwalker spawned at %s" % ...)` ou `"spawn refused"`.
- Texte : ligne `6 spawn sleepwalker`, et `enemies alive N` quand une salle existe (lu par `alive_enemy_count()`).
- La 2.6 remplacera la touche 6 par « ennemi choisi » et ajoutera « tuer tout » et « vague suivante ».

### Règles d'architecture qui s'appliquent

- GDScript typé partout ; `snake_case` pour fichiers et dossiers, un script par classe, nœud racine en `PascalCase` (`sleepwalker.tscn` → `Sleepwalker`) ; Resources de contenu suffixées `Def` (`EnemyDef`, `SleepwalkerDef`) ; signaux au passé ; gestionnaires `_on_<émetteur>_<signal>` (`_on_hurtbox_damage_received`, `_on_enemy_tree_exited`). Code, commentaires, logs, noms de fichiers **en anglais**.
- **États et télégraphes** : enum + `match`, un `_process_<état>()` par état, `_state` écrit **seulement** dans `_enter()` ; toute attaque passe par `Telegraph`.
- **Temps** (AR13) : `GameClock.scale(GameClock.Group.ENEMIES)` pour l'ennemi, son télégraphe, sa zone de contact et ses retours d'impact ; pas de `Timer`.
- **Données** (AR9) : les valeurs du GDD vivent dans `sleepwalker.tres` et `combat_tuning.tres` ; les Resources ne sont jamais modifiées à l'exécution (une `Def` partagée par tous les Somnambules) ; aucun nombre du GDD en dur (2.5, 5, 0.4, 0.6, 2, 3, 30, 10) dans les scripts.
- **Communication** (D3) : `Hurtbox` → ennemi par signal local ; ennemi → composants par appel direct ; `Events.enemy_damaged` par la hurtbox (inchangé) ; aucun nouveau signal sur le bus.
- **Création d'entités** : `room.spawn_enemy()` uniquement ; `setup()` avant `add_child()` ; pas de pool d'ennemis.
- **Frontières** : `combat/` ne dépend ni de `player/` ni de `enemies/` (la `Hitbox` reçoit une `Hurtbox`, pas un joueur) ; `enemies/` dépend de `combat/` et `core/`, pas de `player/` (cible = `Node2D` + `Hurtbox`) ; `rooms/` dépend de `enemies/` et `player/` ; rien ne dépend de `debug/`.
- **Logs** (AR27) : `Log.debug` pour apparition, coup, mort, télégraphe ; aucun log par tick ; aucun `INFO` nouveau (pas un jalon).
- **Aléatoire** : aucun (remplacement de position déterministe).

### Arborescence attendue à la fin de la story

```
game/
├── core/
│   ├── combat_tuning.gd                  (UPDATE : min_telegraph, min_spawn_distance)
│   └── constants.gd                      (UPDATE : PHYSICS_PRIORITY_HITBOXES, GROUP_ROOM)
├── data/
│   ├── tuning/combat_tuning.tres         (UPDATE)
│   └── enemies/sleepwalker.tres          (NEW)
├── combat/
│   ├── hit_points.gd                     (NEW, + .uid)
│   ├── hitbox.gd                         (NEW, + .uid)
│   ├── telegraph.gd                      (NEW, + .uid)
│   ├── hurtbox.gd                        (UPDATE : refuse_hit())
│   └── damage_info.gd                    (UPDATE : CONTACT)
├── enemies/
│   ├── enemy.gd                          (NEW, + .uid)
│   ├── enemy_def.gd                      (NEW, + .uid)
│   └── sleepwalker/
│       ├── sleepwalker.tscn              (NEW)
│       ├── sleepwalker.gd                (NEW, + .uid)
│       └── sleepwalker_def.gd            (NEW, + .uid)
├── audio/sfx/sfx_enemy_sleepwalker_telegraph.wav (NEW, + .import)
├── player/player.gd                      (UPDATE : masque ennemis, refuse_hit())
├── rooms/arena/
│   ├── arena.tscn                        (UPDATE : Enemies)
│   └── arena.gd                          (UPDATE : spawn_enemy(), alive_enemy_count(), groupe room)
└── debug/debug_panel.gd                  (UPDATE : touche 6)
```

Mettre à jour aussi `_bmad-output/game-architecture.md` (T1) et `deferred-work.md` (T12). Ne pas toucher à `health.gd`, `bullet_manager.gd`, `hit_feedback.gd`, `sprite_kick.gd`, `dash.gd`, `run.gd`, `main.gd`, `training_target.gd`, `collision_drawer.gd`, aux autoloads, aux menus.

### Stratégie de test

Aucun framework (AR26 : avant le jalon B). Scènes jetables dans `game/.scratch/` (`godot --headless --path game --scene res://.scratch/<scène>.tscn`), ajoutées à `run_all.sh` (même format : `ok` / `FAIL`, `FAILS=`, verdict par scène). Pour le comportement sans gel : `run.tscn` seul sous la scène de test (rien ne fige, joueur et arène réels) ; pour la partie complète : `main.tscn`. Ennemi par `arena.spawn_enemy()` ; joueur figé à volonté par `player.set_physics_process(false)` (son corps et sa santé restent actifs). **Chaque point dit ce qu'il isole et donne son témoin ; les contrôles par mutation sont listés au point 13.**

1. **Import et lancement** : `--import` puis `--quit-after 120` : zéro `SCRIPT ERROR`, zéro `Parse Error`, aucun avertissement nouveau ; `.wav`, `.tres` importés ; `project.godot` inchangé.
2. **`HitPoints` seul** (`t_enemy_parts`) : `HitPoints.new(30)` → 30 ; `apply_damage(10)` ×3 → 10, 10, 10, mort au troisième ; un quatrième → 0 ; `apply_damage(25)` sur 20 restants → 20 (borné). Montants invalides (NaN, 0, −1) et `max_hp` invalide : dans la scène d'erreurs (point 12).
3. **`Telegraph` seul** (`t_enemy_parts`, nœud sous la scène de test, échelle `ENEMIES`) — isole le plancher : `start(0.4, son)` → actif exactement 24 ticks (compter les ticks où `is_active()` est vrai après le tick de départ, en tenant compte de l'ordre : relever la valeur, attendue 24) ; `start(0.1, son)` → 24 aussi (plancher `min_telegraph`) ; **témoin** : `start(0.6, son)` → 36 et `start(1.0, son, 0.85)` → 51 (la base est bien utilisée au-dessus du plancher) ; `start(0.6, son, 0.5)` → 24 (plancher sur le produit) ; valeur renvoyée en secondes égale ; `Audio.voices_of(son)` passe à 1 au départ ; `GameClock.global_multiplier = 0.25` → 96 ticks ; `GameClock.paused = true` (test isolé, hors `Main`, remis ensuite) → compteur figé 30 ticks.
4. **`Hitbox` et `Hurtbox.refuse_hit()` seuls** (`t_enemy_parts`) :
   - une `Hitbox` (camp `ENEMY`) et une `Hurtbox` cible (camp `PLAYER`) créées par le test : recouvrement → `receive()` appelée une fois par tick tant que la cible est touchable (cible sans filtre : un coup par tick ; avec un filtre qui renvoie `false` : aucun) ; **témoin** : rectangles bord à bord (`intersects` sans les bords) → aucun coup ; 1 px de recouvrement → coup ; source `CONTACT`, direction normalisée de la zone vers la cible ;
   - **priorité** : `process_physics_priority == Const.PHYSICS_PRIORITY_HITBOXES` ; une entité à 0 placée **après** la `Hitbox` dans l'arbre, qui déplace la cible dans la zone pendant son tick → coup **au même tick** (sans la priorité, il arriverait au tick suivant : contrôle par mutation) ;
   - `refuse_hit()` : propriétaire de test qui appelle `refuse_hit()` dans son gestionnaire → `receive()` renvoie `false` et **aucun** `Events.enemy_damaged` ; **témoin** : même propriétaire sans `refuse_hit()` → `true`, un `enemy_damaged`. `refuse_hit()` appelé hors gestionnaire, puis un coup accepté → `true` (le drapeau est remis à zéro).
5. **Apparition** (`t_sleepwalker`, `run.tscn` seul, joueur figé à (304, 168)) — CA 1 :
   - demande à 10 tuiles → position **exactement** la demandée ; `alive_enemy_count()` 0 → 1 ; l'ennemi est sous `Enemies`, sa hurtbox inscrite dans `PlayerBullets` (`has_hurtbox`) ;
   - demande à 1 tuile → remplacée : distance au joueur ≥ 48 px, dans les limites, **et différente de la demande** ; même demande deux fois → même résultat (déterministe) ;
   - **bord** : demande à 47,9 px → remplacée ; **témoin** à 48,0 px → gardée ;
   - demande hors de la zone jouable (dans un mur) → remplacée par une position dans les limites ;
   - joueur placé dans le coin haut gauche, demande sur lui → position valide (pas ce coin) ;
   - log `room` « spawned … » en `DEBUG`, aucun `INFO` nouveau.
6. **Comportement du Somnambule** (`t_sleepwalker`, joueur figé) — CA 2 :
   - **marche** : Somnambule à 8 tuiles → 30 ticks : déplacement de 20 px (± 0,01), colinéaire à la direction du joueur (ligne directe), texture de marche ; **témoin** : un `SleepwalkerDef` **dupliqué par le test** avec `walk_speed` 5,0 donne 40 px (la vitesse vient de la `Def`, pas d'une constante) ; le `.tres` partagé n'est pas modifié ;
   - **déclenchement** : à 32,5 px → reste en `CHASE` ; au premier tick où la distance passe sous 32 px → `TELEGRAPH` (relever le tick N) ;
   - **télégraphe** : texture « bras levés » dès le tick N, `Audio.voices_of(Sleepwalker.TELEGRAPH_SOUND) == 1`, position **inchangée** de N à N + 24 ; premier tick de déplacement rapide = N + 25 (attendu ; affirmer `>= N + 24`) ;
   - **accélération** : 4/3 px par tick pendant **36** ticks (48 px au total si le joueur ne bloque pas : placer le joueur de façon à ce que la course ne l'atteigne pas, ou déplacer le joueur par le test pendant la course), puis retour à 2/3 px par tick ; **cap** : déplacer le joueur (téléportation par le test) au milieu de la course → la direction suit le joueur ;
   - **relance du cycle** : joueur toujours à moins de 2 tuiles à la fin de l'accélération → nouveau télégraphe (son rejoué) sans phase de marche ;
   - **F4** (`GameClock.global_multiplier = 0.25`) : 1/6 px par tick en marche, télégraphe 96 ticks, accélération 144 ticks ;
   - **structure** (`run_all.sh`) : `_state =` n'apparaît qu'une fois dans `sleepwalker.gd`, dans `_enter()` ; chaque état a son `_process_<état>()` ; **témoin** : la vérification échoue sur une copie où une transition écrit `_state` hors de `_enter()`.
7. **Contact** (`t_sleepwalker`) — CA 4, 7 :
   - Somnambule qui poursuit le joueur figé jusqu'au contact → au premier tick de recouvrement : joueur 5/6, `Events.player_hit(1, DamageInfo.Source.CONTACT)` une fois, son de coup ;
   - **contact continu** : le Somnambule reste collé (télégraphe immobile au contact, puis accélération contre le joueur) → aucun coup pendant les 59 ticks suivants, un second coup au tick + 60 (prouve que le contact n'est pas un simple « entrée dans la zone ») ;
   - **filtre** : invulnérabilité forcée (F1, `set_forced_invulnerability(true)`) → aucun coup au contact pendant 120 ticks ; **témoin** : désactivée → coup au tick suivant ;
   - **zone plus grande que le corps** : centres à ≈ 8,08 px (corps bloqués, relevé), zones de contact et hurtbox recouvertes ; **témoin** : une `Hitbox` de test de la taille du corps (10×10), à la même position, ne livre aucun coup ;
   - **un coup par tick** : deux Somnambules au contact au même tick (dont un placé par le test) → un seul `player_hit` ;
   - **coup mortel par contact** : joueur à ½ cœur → mort, `Events.run_ended` une fois (chemin de 2.2 inchangé).
8. **Tirs et mort** (`t_sleepwalker`) — CA 5, 6, 8 :
   - tirs posés par le test dans `PlayerBullets` (apparence de test, `damage = Tuning.SHOT.damage`), et **au moins un vrai tir** du joueur (stick droit simulé vers l'ennemi, comme les contrôles de 1.5) → PV 30 → 20 → 10 ; à chaque tir accepté : `Events.enemy_damaged` une fois avec 10, `_feedback.is_flashing()`, sprite décalé (`_sprite.position != ZERO`) puis revenu à (0, 0) ;
   - troisième tir → mort : `is_dead()`, `process_mode == PROCESS_MODE_DISABLED`, invisible ; libéré à l'image suivante (`is_instance_valid()` faux) ; `alive_enemy_count()` revient à 0 ; `PlayerBullets.has_hurtbox()` faux après la libération ;
   - **tir après la mort** (dans les ticks qui précèdent la libération : tuer et tirer dans la même image n'est pas forcé ; à défaut, appeler `hurtbox.receive()` sur l'ennemi mort) → `false`, aucun `enemy_damaged`, et un projectile qui arrive sur sa position continue jusqu'au mur ;
   - **deux tirs mortels au même tick** (ennemi à 10 PV, deux projectiles même origine, même direction) → un seul `enemy_damaged`, aucune erreur ;
   - **un mort ne touche plus** : ennemi tué au contact du joueur vulnérable → aucun coup ensuite ; **témoin** : vivant au même endroit → coup ;
   - **un mort ne bloque plus** : le joueur traverse l'emplacement d'un ennemi tué (avant sa libération) ; **témoin** : vivant → bloqué.
9. **Le dash ne traverse pas** (`t_sleepwalker`, joueur actif) — CA 5 : Somnambule immobilisé par le test (`set_physics_process(false)` sur l'ennemi seulement : sa `Hitbox` continue) à 2 tuiles à droite du joueur ; dash vers la droite → le joueur s'arrête au contact (centre du joueur ≤ centre de l'ennemi − 8 px + 0,1) ; **témoin** : sans ennemi, même dash → 48 px ; **témoin de masque** : masque du joueur sans `LAYER_ENEMIES` (mutation) → traversée. Pendant les 0,15 s d'invulnérabilité du dash, aucun coup de contact ; ensuite, au contact, coup.
10. **Partie complète** (`t_enemy_main`, `main.tscn`) — CA 9, 10, 11, 12 :
    - F1 + touche 6 → un Somnambule, `alive_enemy_count() == 1`, à ≥ 48 px du joueur ; F5 (test de charge) puis touche 6 → « no room » ; F5 retour → touche 6 marche sur la nouvelle arène ;
    - **pause** : position, état et ticks restants (télégraphe en cours) figés 60 ticks, reprise où ils en étaient (nombre total de ticks de télégraphe hors pause = celui du point 6) ; **écran de réveil** : même chose ;
    - **relance** : mort (touche 3 ou contact) avec 2 Somnambules vivants → relance → aucun `Sleepwalker` dans l'arbre (parcours récursif `is Sleepwalker`), nouvelle arène à 0 ; cinq cycles (2 Somnambules apparus à chaque partie) : `OBJECT_NODE_COUNT` identique après le 1er et le 5e cycle (mesuré une image après la relance), `OBJECT_ORPHAN_NODE_COUNT` à 0, `Events.enemy_damaged` et `Events.run_ended` : nombre de connexions stable ;
    - **ordre de dessin** : `Enemies` après `Targets` et avant `PlayerBullets`, `EnemyBullets`, `DamageNumbers` dans l'arène ; `z_index` 0.
11. **Panneau F1, refus** : `player.hurtbox.receive()` d'un montant invalide (scène d'erreurs) → `false` ; texte « hit ignored » quand la touche 3 est refusée (invulnérabilité forcée).
12. **Chemins d'erreur** (`t_invalid23`, comptés dans `run_all.sh` comme `t_invalid`) : `HitPoints.new(NAN)`, `apply_damage(NAN)`, `apply_damage(0)`, `apply_damage(-1)` → valeurs sûres ; `enemy.hurtbox.receive(DamageInfo d'un montant 0)` → `false`, aucun `enemy_damaged` ; `spawn_enemy(null, …)` → `null` ; une scène dont la racine n'est pas un `Enemy` dans un `EnemyDef` de test → `null`, pas de nœud orphelin ; `Telegraph.start(NAN, …)` → durée `min_telegraph` ; un ennemi ajouté sans `setup()` → désactivé ; nombre exact de messages d'assertion attendu, aucun autre `SCRIPT ERROR`.
13. **Contrôles par mutation** (sur une copie du projet ou annulés aussitôt, consignés dans le Debug Log) : sans le plancher `min_telegraph` → point 3 échoue ; `Hitbox` à la taille du corps → point 7 échoue ; sans `refuse_hit()` dans `Enemy` → points 4/12 échouent ; sans `LAYER_ENEMIES` dans le masque du joueur → point 9 échoue ; sans le remplacement de position → point 5 échoue ; télégraphe sauté (`_enter(RUSH)` directement) → point 6 échoue ; sans `process_mode = DISABLED` à la mort → point 8 (« ne touche plus ») échoue ; sans la priorité de la `Hitbox` → point 4 (même tick) échoue.
14. **Régression et interdits** : `run_all.sh` complet (scènes de 2.1 et 2.2 plus les nouvelles), toutes `PASS` ; recherche des interdits de `run_all.sh` (inchangée) ; **nombres du GDD** : aucun `2.5`, `5.0`, `0.4`, `0.6`, `30`, `3.0` dans `enemies/` et `combat/` hors commentaires (règle ajoutée à `run_all.sh`, avec un témoin planté) ; aucun `Log.` dans un `_physics_process`.
15. **Fenêtré sous WSLg** (indicatif, captures `get_viewport().get_texture().get_image().save_png()`) : Somnambule qui marche bras tendus, bras levés pendant le télégraphe, flash blanc et recul au tir, chiffre de dégâts (réglage activé), ennemi au-dessus du sol et sous les projectiles, F2 (corps, hurtbox, zone de contact : trois rectangles).
16. **Étapes humaines** (à consigner `NON ÉVALUÉ` dans la story et `deferred-work.md`, ne pas déclarer vérifiées) : lisibilité du télégraphe (bras levés provisoires, 0,4 s) et son à l'oreille ; ressenti de la poursuite et de l'accélération (cap qui suit le joueur ou non, absence de récupération) ; ressenti du contact (corps qui bloquent, petit décalage au premier contact) ; tailles provisoires du corps, de la hurtbox et de la zone de contact.

### Commit

Directement sur `main`, Conventional Commits en anglais, `git push` après chaque commit (consigne du projet), ligne `Co-Authored-By` du modèle réellement utilisé. Commiter par tâche cohérente, chaque commit laissant le jeu lançable. Exemples : `docs(architecture): add enemy and spawn terms to the lexicon` ; `feat(combat): add hit points, contact hitbox, telegraph and owner hit refusal` ; `feat(enemies): add the enemy base and the sleepwalker` ; `feat(rooms): spawn enemies away from the player and count them` ; `feat(player): stop the dash on enemies` ; `feat(debug): spawn a sleepwalker from the f1 panel` ; `docs(story): record story 2.3 implementation progress`.

### Project Structure Notes

- Conforme à l'arborescence de l'architecture : `enemies/enemy.gd`, `enemies/enemy_def.gd`, `enemies/sleepwalker/`, `combat/hitbox.gd`, `combat/telegraph.gd`, `data/enemies/sleepwalker.tres`.
- **Écarts assumés** :
  - `combat/hit_points.gd` (`HitPoints`) n'est pas dans l'arborescence : les PV flottants des ennemis ne vont pas dans `Health` (voir les décisions).
  - `SleepwalkerDef` (sous-classe d'`EnemyDef`) dans `enemies/sleepwalker/` : l'architecture ne nomme qu'`EnemyDef` ; le `.tres` reste « un `EnemyDef` » (CA 2).
  - `spawn_enemy()` vit dans `Arena`, seule salle du jalon A ; la classe `Room` commune (`rooms/room.gd`) arrive avec la 4.2, qui y déplacera `spawn_enemy()` et le compte.
  - `Enemy.setup(def, target, target_hurtbox)` au lieu de `setup(def, room)` (exemple de l'architecture) : le Somnambule n'a besoin que de sa cible ; la salle (danger) viendra avec l'epic 3.

### Project Context Rules

Il n'y a pas de `project-context.md`. Règles tirées de `CLAUDE.md`, de la mémoire du projet et du brief du pipeline :

- Conversation, documents de conception et artefacts BMAD : **français**. Code (identifiants, commentaires, noms de fichiers, messages de log) : **anglais**.
- Commits en anglais, Conventional Commits (`type(scope): description`, impératif, minuscules, sans point final), **directement sur `main`, sans branche**, avec un push vers `origin/main` aussitôt après chaque commit, et la ligne `Co-Authored-By` en fin de message.
- Textes affichés au joueur : fichiers de localisation, jamais en dur (aucun dans cette story ; le panneau F1 est du debug, exempté).
- Prototype rapide, itérations courtes : ne poser que ce que cette story exige.
- Pipeline automatisé de l'epic 2 : Kroustille n'est pas disponible avant la fin de l'epic ; toute question se tranche et se consigne ci-dessous.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **PV des ennemis : `HitPoints`, pas `Health`** — Question : réutiliser `Health` (report de 2.1, décision 6) ? Choix : un `RefCounted` à part, PV flottants, sans armure, plafond ni invulnérabilité. Raison : l'architecture compte les ennemis en PV flottants et le joueur en demi-cœurs entiers ; généraliser `Health` toucherait le joueur sans rien apporter ; servira aux meubles et au cauchemar.
2. **Refus d'un coup par le propriétaire : `Hurtbox.refuse_hit()`** — Question : comment `receive()` apprend-il que le coup est refusé (report de 2.1) ? Choix : le propriétaire appelle `refuse_hit()` dans son gestionnaire (appel direct vers un enfant, D3) ; `receive()` renvoie alors `false` sans `enemy_damaged`. Appliqué à l'ennemi et au joueur. Raison : le plus petit changement compatible (les cibles d'entraînement ne changent pas), sans remplacer le signal par un `Callable` de retour.
3. **Contact par `Hitbox` testée à la main** (priorité 50), pas par recouvrement physique d'`Area2D` — Raison : mêmes règles que le `BulletManager` (tick courant, filtre de la hurtbox, ordre fixé), contact continu sans gestion d'entrée et de sortie ; la physique rapporte l'état du tick précédent.
4. **Dégâts au contact = `CombatTuning.hit_damage_half_hearts`**, pas un champ d'`EnemyDef` — Raison : FR12, le coup dépend de l'étage (½ cœur aux étages 1 et 2, 1 cœur ensuite), pas de l'ennemi.
5. **Immobile pendant le télégraphe** — Question : le Somnambule marche-t-il en levant les bras ? Choix : non. Raison : à 2,5 tuiles/s il ferait encore 1 tuile en 0,4 s et toucherait le joueur avant la fin de l'annonce ; l'arrêt rend le télégraphe lisible (pilier 1).
6. **Accélération qui continue de viser le joueur** (cap mis à jour à chaque tick), et non une course en ligne droite figée — Raison : le GDD dit « accélère » pour le Somnambule et « charge en ligne droite vers la position du joueur au moment du télégraphe » pour Le Mouton (2.5) : les deux ennemis restent distincts. À 5 tuiles/s contre 6 pour le joueur, on s'échappe en fuyant ou en dashant. **NON ÉVALUÉ** au jeu.
7. **Pas de récupération après l'accélération** — Raison : le GDD n'en donne pas ; si le joueur reste à moins de 2 tuiles, le Somnambule relève les bras, et ces 0,4 s immobiles servent de répit. À juger au jeu.
8. **Distances mesurées centre à centre** (origines des nœuds), déclenchement strictement sous 2 tuiles, apparition refusée strictement sous 3 tuiles — Raison : lecture littérale de « à moins de » ; le plus simple à tester.
9. **Un tick sans mouvement à chaque transition** (télégraphe de 25 ticks immobile avant le premier tick rapide, ≥ 24) — Raison : transitions par `_enter()` seulement, sans enchaîner deux `_process_` dans le même tick ; FR26 demande « au moins 0,4 s ».
10. **Collisions des corps** : ennemis contre murs, joueur et ennemis ; joueur contre murs et ennemis, en marche comme en dash — Raison : FR4 (le dash ne traverse pas les ennemis) ; des ennemis empilés cacheraient leur nombre (lisibilité) ; sonde : pas de poussée continue entre corps.
11. **Tailles provisoires dans `EnemyDef`** : corps 10×10 px, hurtbox 12×20 px (comme les cibles), zone de contact 12×12 px — Raison : le GDD ne les donne pas ; la zone de contact doit dépasser le corps pour qu'un contact compte (voir « `EnemyDef` »).
12. **`EnemyDef` commun + `SleepwalkerDef`** (sous-classe) — Raison : seuls l'identifiant, la scène, les PV et les tailles sont communs aux quatre ennemis ; les valeurs propres à chacun restent typées sans gonfler la base ; le `.tres` est bien un `EnemyDef`.
13. **`Enemy.setup(def, target, target_hurtbox)`**, sans référence à la salle ni au joueur — Raison : le Somnambule n'a besoin que de sa cible ; `enemies/` ne dépend pas de `player/` ; la salle (danger) s'ajoutera avec l'epic 3.
14. **Pas de classe `Room` commune** : `spawn_enemy()` et le compte dans `Arena` — Raison : une seule salle au jalon A ; la 4.2 crée `Room`.
15. **Remplacement de position déterministe** (point repoussé à 3 tuiles, sinon coin le plus proche de la zone jouable, marge d'une tuile), sans aléatoire — Raison : `RunRng` arrive avec l'epic 4 et le RNG global est interdit ; un candidat valide existe toujours.
16. **`min_spawn_distance` et `min_telegraph` dans `CombatTuning`** — Raison : le CA 3 y place `min_telegraph` ; la distance d'apparition est une règle de combat commune à toutes les salles.
17. **Coordonnées de `spawn_enemy()` = coordonnées de la salle** (l'arène est à l'origine du monde) — Raison : architecture (`enemy.position = pos` sous la salle) ; les marqueurs de l'epic 4 seront en coordonnées de salle.
18. **Pas de pool d'ennemis, jamais de changement de parent** — Raison : architecture (« pools uniquement pour les projectiles et les effets d'impact ») ; la désinscription `CONNECT_ONE_SHOT` reste juste (report de 1.5 sans objet).
19. **Mort : disparition immédiate**, ennemi désactivé (`process_mode`) puis libéré, aucun signal sur le bus — Raison : pas d'animation avant l'epic 7 ; les vagues (2.6) comptent par la salle ; la télémétrie (2.8) n'en a pas besoin.
20. **Compte des vivants par `tree_exited`** (exemple de l'architecture), pas à la mort — Raison : couvre toutes les sorties (mort, « tuer tout » en 2.6, relance) ; le décalage d'une image est sans effet.
21. **`Telegraph` est un nœud qui tique seul** ; le son est passé à `start()`, l'animation est un changement de texture par l'ennemi — Raison : AR7 (composants nœuds), même modèle que `Health` ; un ennemi aux attaques multiples (Le Professeur) passera un son par attaque.
22. **Son du télégraphe provisoire** généré par script (montant, ≈ 0,35 s) — Raison : FR26 exige un son ; remplacé par la 7.7.
23. **Visuels provisoires** : deux textures générées (bras tendus, bras levés) sur un sprite en (0, 0) sans `material` propre — Raison : FR26 exige une animation ; respecte les hypothèses de `SpriteKick` et `HitFeedback` (report de 1.5).
24. **Groupe `room`** pour que F1 trouve la salle active — Raison : pas de chemin absolu (D3) ; même mécanisme que le groupe `player`.
25. **Touche 6 de F1 : un Somnambule demandé en haut au centre** ; arène vide au lancement — Raison : les vagues sont la 2.6 ; sans commande de debug, l'ennemi ne pourrait pas être essayé. En build de release, aucun ennemi avant la 2.6.
26. **Les décisions de 2.1 et 2.2 restent valables** (filtre de hurtbox, un coup par tick sur le joueur, ordre des managers, ordre du coup mortel, gel par `Main`, joueur dans `Run`, F1 par `has_hurtbox()`). La décision 10 de 2.1 (cible devenue intouchable entre le test et la livraison : un projectile perdu) s'applique aux deux tirs mortels du même tick (point 8) : accepté.
27. **Chemins d'erreur : état sûr posé avant l'assert, `_assert_failed()` pour les retours** (écart d'implémentation, 2.3) — Question : comment tenir AR28 alors qu'un `assert` qui échoue interrompt la fonction en build de debug ? Choix : poser `maximum`/`current`, `process_mode`, `set_physics_process(false)` avant `Log.error` + `assert`, et isoler l'assert dans `_assert_failed()` quand la fonction doit encore retourner une valeur bornée (`Telegraph.start()`, `Enemy._pixel_size()`, `Sleepwalker._bounded_px()`). Raison : constaté par `t_invalid23` (la première version renvoyait la valeur par défaut du type).
28. **Apparition : zone valide inclusive, constantes techniques dans `Arena`** — `SPAWN_MARGIN_TILES` (1) et `SPAWN_DISTANCE_EPSILON` (1e-3 px) ; la zone réduite est testée bords compris (`Rect2.has_point` exclut le bord bas et droit, donc refuserait les coins, qui sont des candidats de remplacement). Raison : la story garantit qu'un coin valide existe toujours.
29. **`Enemy` incomplet désactivé aussi si la cible ou sa hurtbox manque** — `setup()` oublié ou cible nulle : `process_mode = DISABLED`, `Log.error` + `assert` (la story ne citait que la `Def` nulle). Raison : une `Hitbox` sans cible serait inactive de toute façon ; l'ennemi entier l'est avec un message clair.
30. **Sprite provisoire un peu plus large** (corps 8×16 px de la toile 16×24 au lieu de 6×16) — Raison : à 640×360 la silhouette de 6 px était trop fine à côté du joueur ; à relire au jeu avec les tailles (point 11).
31. **Revue : position de remplacement = la plus proche, bornée à la zone d'abord** (revue de code, 2.3) — Question : garder la liste de candidats de la spec (point repoussé, coins), qui ramène vers le joueur une demande hors zone, ou borner la demande à la zone d'abord ? Choix : borner d'abord (`clamp`), puis repousser, puis les coins ; plus des candidats en anneau pour ne pas superposer deux corps. Raison : le commentaire et l'intention du CA 1 (« remplacée par une autre position valide », « la plus proche ») ; les vagues (2.6) et les marqueurs (epic 4) proches d'un mur n'apparaîtront pas collés au joueur ; deux ennemis superposés se figent (sonde). Coût faible, sans RNG.
32. **Revue : défauts neutres dans `EnemyDef` et `SleepwalkerDef`** — Question : les défauts de script qui recopient les valeurs du GDD (et celles du Somnambule dans la base commune) sont-ils acceptables, comme dans `CombatTuning` ? Choix : non pour les `Def` de contenu : défauts à 0, la validation existante signale un oubli. Raison : plusieurs ennemis partagent la base (2.4, 2.5) ; un oubli hériterait en silence du Somnambule, et un `.tres` réenregistré perdrait les valeurs égales au défaut (AR9). `CombatTuning` (une seule instance) reste tel quel.
33. **Revue : poussée du joueur pendant l'accélération reportée, pas corrigée** — Question : arrêter l'accélération au contact du joueur (ou ajouter une récupération) ? Choix : reporter, NON ÉVALUÉ. Raison : ≈ 0,37 px par tick au contact pendant l'accélération (≈ 13 px par accélération, sonde de l'Edge Case Hunter) ; sans conséquence tant qu'il n'y a ni trou ni piège (4.3) ; c'est un ressenti de jeu (décisions 6 et 7) à juger avec Kroustille, qu'un correctif maintenant préjugerait.
34. **Revue : scènes de vérification perdues, pas un blocage** — Le scratchpad a été vidé par un redémarrage pendant la revue. Choix : la story repasse `in-progress` et la réécriture des contrôles (avec les corrections de la revue) devient une action ; le code n'est pas mis en doute pour autant (l'Acceptance Auditor a lu une partie des scènes avant la perte, l'Edge Case Hunter et la revue ont refait des sondes ciblées). Raison : rien de coûteux à défaire ; les scènes sont jetables par construction (AR26).

### Questions ouvertes

Aucune bloquante. Points à faire valider par Kroustille en fin d'epic : les décisions ci-dessus, en priorité 5 (immobile pendant le télégraphe), 6 (accélération qui vise), 7 (pas de récupération) et 11 (tailles), à juger au jeu.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.3 : Affronter Le Somnambule]
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences fonctionnelles] (FR4, FR12, FR26, FR27, FR31) et [#Exigences supplémentaires (architecture)] (AR7, AR9, AR13, AR14, AR23, AR24, AR27, AR28, AR32)
- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.4], [#Story 2.5], [#Story 2.6] (ennemis suivants, vagues : contexte, non implémentés ici)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Ennemis et IA] (tableau des ennemis : Somnambule chaser, 30 PV, 2,5 tuiles/s, 2 tuiles, 5 tuiles/s 0,6 s, bras levés 0,4 s ; règle de télégraphe ; le contact n'est pas une attaque)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Armes et tir] (flash blanc 0,05 s, recul de 2 px sur l'ennemi touché) et [#Tir] (10 dégâts par tir)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Déplacement et dash] (le dash ne traverse ni murs ni ennemis) et [#Santé et armure] (dégâts au contact)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Génération procédurale] (jamais d'apparition à moins de 3 tuiles du joueur)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/decision-log.md] (Somnambule : télégraphe de 0,4 s avant l'accélération ; contact exclu de la règle de télégraphe)
- [Source: _bmad-output/game-architecture.md#Gestion de l'état] (machine à états par enum), [#États et télégraphes], [#Création d'entités] (`spawn_enemy`, `setup()` avant `add_child()`, pools), [#Dégâts et unités] (PV flottants), [#Accès aux données] (`Def` en lecture seule), [#Temps (D7)], [#Décisions reportées (D17, D18)] (déplacement direct), [#Frontières architecturales], [#Arborescence] (`enemies/`, `combat/hitbox.gd`, `combat/telegraph.gd`, `data/enemies/`), [#Lexique] (`Sleepwalker`, `telegraph`)
- [Source: _bmad-output/implementation-artifacts/2-1-encaisser-des-coups.md] (`Health`, `Hurtbox`, ordre des managers, F1, décisions, revue)
- [Source: _bmad-output/implementation-artifacts/2-2-mourir-et-relancer-en-moins-de-3-secondes.md] (`Run`, gel, relance, fuites, `run_all.sh`, décisions, revue)
- [Source: _bmad-output/implementation-artifacts/1-5-viser-et-tirer.md] (`HitFeedback`, `SpriteKick`, son généré par script)
- [Source: _bmad-output/implementation-artifacts/deferred-work.md] (reports listés dans « Reports traités par cette story »)
- Documentation Godot 4.7 consultée par Context7 à la création : `CollisionObject2D.disable_mode` (comportement physique quand `process_mode` est `DISABLED`) ; `Rect2.intersects(b, include_borders = false)` (bords exclus) ; `CharacterBody2D.move_and_slide()` (glissement sur un autre corps) ; signaux `tree_exiting` / `tree_exited` de `Node` et `is_queued_for_deletion()`. Sonde headless en 4.7.2 (scratchpad, `probe23`) : deux `CharacterBody2D` flottants (6×6 et 10×10) qui avancent l'un vers l'autre se bloquent à 8,08 px de centre à centre, avec un décalage unique d'environ 1,3 px au premier contact et aucune poussée continue ; un `CharacterBody2D` passé en `PROCESS_MODE_DISABLED` sort de la physique (l'autre corps avance de 50 px en 10 ticks à travers son emplacement).

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5 (`claude-sonnet-5-5`), workflow `gds-dev-story`, pipeline automatisé de l'epic 2.

### Debug Log References

**Vérifications headless** (scènes de `game/.scratch`, toutes lancées par `run_all.sh`, 11 scènes `PASS`) :

| Scène | Contrôles `ok` | Couvre |
|---|---|---|
| `t_health`, `t_arena`, `t_misc`, `t_death`, `t_isolated`, `t_load`, `t_invalid` (2.1 et 2.2) | 16, 23, 30, 115, 9, 3, 1 | **inchangées** : aucune n'a été adaptée, le comportement de 2.1 et 2.2 n'a pas bougé (le masque du joueur et `refuse_hit()` n'y changent rien) ; `t_load` : `Bullets 400 \| refused 0` |
| `t_enemy_parts` (nouvelle) | 31 | points 2 à 4 : `HitPoints` ; `Telegraph` (24, 24, témoins 36 et 51, plancher sur le produit, son, F4 96 ticks, pause) ; `Hitbox` (un coup par tick, bords exclus, direction, filtre, pause, même tick qu'une entité à 0) ; `refuse_hit()` |
| `t_sleepwalker` (nouvelle) | 85 | points 5 à 9 : apparition (3 tuiles, 47,9 / 48,0, mur, coin, déterminisme) ; marche 20 px en 30 ticks (témoin `Def` dupliquée à 5,0 : 40 px) ; déclenchement à 32 px ; télégraphe 25 ticks immobile, accélération 36 ticks à 4/3 px, 48 px, cap qui suit le joueur ; cycle sans récupération ; F4 (1/6 px, 96 et 144 ticks) ; contact (un coup, source `CONTACT`, second coup à exactement +60 ticks, témoin zone de la taille du corps, invulnérabilité forcée et témoin, deux ennemis, coup mortel et `run_ended` une fois) ; tirs (PV 30, 20, 10, 0, flash, recul, retour à (0, 0)), vrais tirs du joueur, mort (corps retiré de l'espace physique, `can_process()` faux, libéré, compte à 0), tirs qui traversent un propriétaire à 0 PV, deux tirs mortels au même tick, un mort ne bloque plus (témoin : vivant bloque) ; dash arrêté par le corps (témoin 48 px sans ennemi) et sans coup pendant l'invulnérabilité du dash alors que les zones se recouvrent |
| `t_enemy_main` (nouvelle, `main.tscn`) | 31 | points 10 à 12 : F1 + touche 6, texte du panneau, ordre de dessin, pause (position, état, ticks du télégraphe, texture figés 60 ticks puis reprise), F4, F5 (« no room », retour), « hit ignored » et témoin « hit applied », écran de réveil (2 ennemis figés 60 ticks), relance (aucun `Sleepwalker`, arène à 0), 5 cycles avec 2 ennemis vivants (nœuds 106 / 106, orphelins 0, connexions 2 et 1 stables) |
| `t_invalid23` (nouvelle) | 16 | point 12 : valeurs sûres et refus, 11 messages d'assertion attendus comptés un par un par `run_all.sh` |

`run_all.sh` ajoute : machine à états du Somnambule (`_state =` une seule fois, dans `_enter()`, un `_process_<état>()` par état, témoins : copie qui écrit `_state` ailleurs, copie sans `_process_rush()`), nombres du GDD absents du code de jeu de `enemies/` et `combat/` (témoin planté ; les lignes `@export` des `Def`, qui reflètent les `.tres`, sont exclues), aucun `Log.` dans un `_physics_process` (témoin planté), logs `room` (`spawned` en DEBUG, jamais en INFO, ligne de position remplacée).

**Contrôles par mutation** (mécanisme retiré, la scène doit échouer, puis annulé et vérifié par somme de contrôle) :

| Mutation | Scène | Résultat |
|---|---|---|
| sans le plancher `min_telegraph` | `t_enemy_parts` | 3 FAIL (0,1 s : 6 ticks au lieu de 24 ; 0,6 × 0,5 : 18) |
| zone de contact à la taille du corps | `t_sleepwalker` | 3 FAIL (aucun contact obtenu) |
| sans `refuse_hit()` dans `Enemy` | `t_invalid23` | 2 FAIL |
| `refuse_hit()` sans effet dans `Hurtbox` | `t_enemy_parts`, `t_invalid23` | 3 et 3 FAIL |
| sans `LAYER_ENEMIES` dans le masque du joueur | `t_sleepwalker` | 4 FAIL (le dash et la marche traversent) |
| sans remplacement de position | `t_sleepwalker` | 6 FAIL |
| télégraphe sauté (`_enter(RUSH)` direct) | `t_sleepwalker` | 13 FAIL |
| sans `PROCESS_MODE_DISABLED` à la mort | `t_sleepwalker` | 3 FAIL (voir la limite : contrôle structurel) |
| sans la priorité de la `Hitbox` | `t_enemy_parts` | 2 FAIL (le coup arrive au tick 4 au lieu de 3) |
| filtre de la hurtbox ouvert (`_can_be_hit` vrai) | `t_sleepwalker` | 1 FAIL (le tir ne traverse plus un propriétaire à 0 PV) |
| `_state` écrit hors de `_enter()` ; `_process_rush()` absent | `run_all.sh` | contrôles du script : échouent comme attendu |

**Import et lancement** : `--import` puis `--quit-after 120` : zéro `SCRIPT ERROR`, zéro `Parse Error`, seul avertissement `settings.cfg missing` ; `project.godot` inchangé. **Fenêtré sous WSLg** (captures `game/.scratch`, indicatives) : Somnambule qui marche bras tendus, bras levés pendant le télégraphe, flash au tir (`is_flashing()` vrai), F2 (corps, hurtbox et zone de contact dessinés), ennemi au-dessus du sol.

### Completion Notes List

- Analyse de contexte terminée : guide d'implémentation complet créé (create-story, 2026-11-21).
- Implémentation de la story 2.3 (dev-story, 2026-11-21) : lexique et architecture (AR32) avant le code ; `CombatTuning` (`min_telegraph` 0,4 s, `min_spawn_distance` 3 tuiles) ; `HitPoints`, `Telegraph`, `Hitbox`, `Hurtbox.refuse_hit()`, `DamageInfo.Source.CONTACT`, `PHYSICS_PRIORITY_HITBOXES`, `GROUP_ROOM` ; `EnemyDef`, `Enemy`, `SleepwalkerDef`, `Sleepwalker` (scène, textures provisoires, son généré par script) ; masque du joueur avec `LAYER_ENEMIES` ; `Arena.spawn_enemy()`, `alive_enemy_count()`, groupe `room`, nœud `Enemies` ; touche 6 du panneau F1. Les 13 critères d'acceptation sont couverts par les scènes ci-dessus.
- **Aucune scène de 2.1 ou 2.2 n'a été modifiée** ; elles passent telles quelles. `run_all.sh` passe de 7 à 11 scènes.
- Mesures relevées (écart avec la rédaction de la story signalé) : centres du joueur et du Somnambule bloqués à 8,00 px (la story annonçait ≈ 8,08 ; la zone de contact recouvre quand même la hurtbox : 6 + 3 = 9 > 8) ; les demandes d'apparition « à 33 px » des scènes sont remplacées par 48 px (règle de la distance minimale), le déclenchement est donc mesuré en marchant jusqu'à 32 px.
- **Limite de test assumée** : « un mort ne touche plus » n'est vérifié que par structure (voir `deferred-work.md`), les tirs qui traversent un propriétaire à 0 PV le sont par comportement.
- **Un assert qui échoue interrompt la fonction** : sur les chemins d'erreur, l'état sûr est posé avant `Log.error` + `assert`, et `Telegraph.start()`, `Enemy._pixel_size()` et `Sleepwalker._bounded_px()` passent par `_assert_failed()` pour que l'appelant garde la valeur bornée.
- **NON ÉVALUÉ / NON VÉRIFIÉ** (étapes humaines, reportées dans `deferred-work.md`) : lisibilité du télégraphe et son à l'oreille ; ressenti de la poursuite, de l'accélération (cap qui suit, absence de récupération) et du contact ; tailles provisoires ; mesure de 10 minutes à 400 projectiles (story 1.2, toujours **NON FAITE**).
- Revue de code non lancée (hors rôle du développeur).

### File List

Nouveaux : `game/combat/hit_points.gd`, `game/combat/hitbox.gd`, `game/combat/telegraph.gd` (+ `.uid`) ; `game/enemies/enemy.gd`, `game/enemies/enemy_def.gd`, `game/enemies/sleepwalker/sleepwalker.gd`, `game/enemies/sleepwalker/sleepwalker_def.gd` (+ `.uid`), `game/enemies/sleepwalker/sleepwalker.tscn` ; `game/data/enemies/sleepwalker.tres` ; `game/audio/sfx/sfx_enemy_sleepwalker_telegraph.wav` (+ `.import`).

Modifiés : `game/combat/hurtbox.gd`, `game/combat/damage_info.gd`, `game/core/combat_tuning.gd`, `game/core/constants.gd`, `game/data/tuning/combat_tuning.tres`, `game/player/player.gd`, `game/rooms/arena/arena.gd`, `game/rooms/arena/arena.tscn`, `game/debug/debug_panel.gd` ; `_bmad-output/game-architecture.md` ; `_bmad-output/implementation-artifacts/deferred-work.md`, `sprint-status.yaml` et ce fichier.

Hors dépôt (`game/.scratch`, exclu de git) : `t_enemy_parts`, `t_sleepwalker`, `t_enemy_main`, `t_invalid23`, `t_shots23` (captures), `run_all.sh` étendu.

### Change Log

- 2026-11-21 : story 2.3 créée (`ready-for-dev`).
- 2026-11-21 : story 2.3 implémentée, vérifiée en headless (11 scènes `PASS`, mutations consignées) et passée en `review`.
- 2026-11-22 : revue de code (trois couches) : 10 actions `[Review][Patch]`, 6 reports, 17 constats écartés ; décisions 31 à 34 ; scènes du scratchpad perdues (redémarrage), à réécrire ; story repassée en `in-progress`.

# Story 2.4 : Affronter La Veilleuse et La Berceuse

Status: ready-for-dev

## Story

En tant que joueur,
je veux deux tireuses aux projectiles toujours reconnaissables,
afin d'apprendre à esquiver des tirs annoncés.

**Exigences couvertes :** FR26, FR28, FR30, NFR8, AR6 (camp ennemi), ainsi que AR7, AR9, AR13, AR23 (déplacement direct), AR24 (F1), AR27, AR28, AR32, NFR9.

**Prérequis : la story 2.3 est `done`** (vérifié à la création de ce fichier : `Enemy`, `EnemyDef`, `HitPoints`, `Hitbox`, `Telegraph`, `Hurtbox.refuse_hit()`, `Arena.spawn_enemy()` avec ses règles d'apparition revues, `Sleepwalker`, défauts neutres des `Def`, touche 6 de F1 existent dans le dépôt). Les stories 1.7 et 1.8 sont reportées par Kroustille : elles ne sont **pas** des prérequis.

**Quatrième story de l'epic 2 : les premiers ennemis qui tirent.** Elle donne aux ennemis le `BulletManager` ennemi de la salle, pose une couche commune aux deux tireuses (`ShooterDef`, `ShooterEnemy` : cycle de tir, télégraphe, salve), l'apparence réservée des projectiles ennemis, et règle trois reports du `BulletManager` (dégâts nuls, projectile né dans un mur, une apparence par manager). **La couche commune reste minimale** : seulement ce dont La Veilleuse et La Berceuse ont besoin toutes les deux ; Le Somnambule ne change pas, Le Mouton (2.5) n'en hérite pas.

## Critères d'acceptation

1. **Étant donné** un projectile ennemi, **quand** il est dessiné, **alors** il a une couleur et un contour réservés aux projectiles ennemis, dessinés au-dessus de tout le reste du monde.
2. **Étant donné** La Veilleuse (40 PV, immobile), **quand** son cycle de 2 s arrive à son terme, **alors** une lueur monte pendant 0,6 s (animation et son), **et** elle tire ensuite un éventail de 3 projectiles écartés de 20°, centré sur le joueur, à 5 tuiles/s, par `BulletManager.fire()`.
3. **Étant donné** La Berceuse (30 PV), **quand** elle est active, **alors** elle se tient entre 4 et 8 tuiles du joueur, en se rapprochant ou en s'éloignant en ligne directe, **et** toutes les 1,5 s elle inspire pendant 0,5 s (animation et son), puis tire un projectile visé sur le joueur, à 6 tuiles/s.
4. **Étant donné** les deux ennemis, **quand** on règle leurs valeurs, **alors** tout vient de `night_light.tres` et `lullaby.tres`.

**Conséquences à tenir pour que le système reste cohérent de bout en bout** (non écrites dans l'epic, mais exigées par l'architecture, par les reports des stories précédentes ou par l'état du dépôt) :

5. **Une seule apparence pour tous les projectiles ennemis** : la Veilleuse, la Berceuse, l'émetteur de test de F1 (touches 4 et 5) et le test de charge F5 tirent avec la même texture réservée ; un `BulletManager` n'a qu'un `MultiMeshInstance2D` pour elle, quel que soit le nombre de tireuses apparues (aucune limite de 256 apparences atteinte au fil des vagues de la 2.6). Aucune autre couleur du jeu n'est proche des deux couleurs réservées.
6. **Contrat des dégâts** (reports des revues 2.1 et 2.3) : `BulletManager.fire()` refuse, avec `Log.error` + `assert`, un tir dont la cible refuserait les dégâts : camp ennemi (vers la `Health` du joueur, en demi-cœurs entiers) si `roundi(damage) < 1` ; camp joueur (vers les `HitPoints`) si `damage <= 0`. Les tirs des ennemis portent `Tuning.COMBAT.hit_damage_half_hearts`. Le test de charge F5 tire avec cette valeur (il n'a aucune cible) et affiche toujours `Bullets 400 | refused 0`.
7. **Projectile né dans un mur** (report de la revue 1.2) : un tir dont l'origine est dans une cellule solide n'est pas tiré (`fire()` renvoie `false`, sans log ni compte dans `refused_count`).
8. **Le coup d'un projectile ennemi suit le chemin de 2.1** : `DamageInfo` (source `ENEMY_BULLET`) → `Hurtbox.receive()` → `Health.apply_damage()`, ½ cœur, `Events.player_hit(1, ENEMY_BULLET)`, projectile détruit ; pendant l'invulnérabilité (après un coup, dash, F1) les projectiles traversent le joueur et continuent ; un coup au plus par tick, contact compris.
9. **Les tireuses restent des ennemis de la 2.3** : apparition par `room.spawn_enemy()` (distance minimale, corps disjoints, compte des vivants), 10 PV par tir du joueur avec flash et recul, mort au coup qui vide les PV (elle ne tire plus, ne touche plus, ne bloque plus), dégâts au contact de ½ cœur, le dash ne les traverse pas. Une tireuse morte pendant sa lueur ne tire pas ; ses projectiles déjà tirés continuent leur course.
10. **Pause, écran de réveil et ralenti** : la pause et l'écran de réveil figent les tireuses (position, cycle, lueur ou inspiration) et leurs projectiles ; F4 ralentit ×0,25 cycles, télégraphes, déplacements et projectiles.
11. **Relance propre** : à la relance, tireuses et projectiles disparaissent avec l'ancien `Run` ; après cinq cycles avec des tireuses vivantes et des projectiles en vol à chaque mort, nombre de nœuds stable, aucun orphelin, connexions au bus stables.
12. **Des tireuses à la demande en debug** : le panneau F1 fait apparaître une Veilleuse (touche 7) et une Berceuse (touche 8) par `room.spawn_enemy()` (en attendant « ennemi choisi » de la 2.6).
13. Marche, dash, tir, cibles, chiffres de dégâts, coups et invulnérabilité, mort et relance, pause, réglages, F1 à F5, test de charge (`Bullets 400 | refused 0`) et Le Somnambule (1.1 à 2.3) sont inchangés.

## Tâches / sous-tâches

- [ ] **T1. Lexique et architecture** (AR32 : un terme entre dans le lexique **avant** le code)
  - [ ] `game-architecture.md`, section « Lexique » : ajouter `Tireuse ; cycle de tir ; lueur ; inspirer ; éventail ; écart de l'éventail ; salve ; projectile visé ; distance de maintien (min, max) ; se tenir à distance ; projectile ennemi ; apparence réservée des projectiles ennemis | shooter (ShooterEnemy, ShooterDef) ; fire_interval ; glow ; inhale ; fan ; spread_angle ; volley ; aimed shot ; min_distance, max_distance ; keep_distance ; enemy_bullet ; EnemyBulletLook (COLOR_ENEMY_BULLET, COLOR_ENEMY_BULLET_OUTLINE)`.
  - [ ] `game-architecture.md` : « Projectiles (D1) », une ligne story 2.4 (contrat des dégâts par camp dans `fire()`, origine dans un mur non tirée, `add_appearance()` sans doublon, apparence réservée unique) ; « Rendu (D13) », une ligne (`EnemyBullets` en `z_index` = `Const.Z_INDEX_ENEMY_BULLETS`, au-dessus de tout le monde, chiffres de dégâts compris, sous le réticule jusqu'à la 2.7) ; « Création d'entités », une ligne (`Enemy.setup(def, target, target_hurtbox, bullets)`, le `BulletManager` ennemi de la salle passé à tout ennemi) ; « Arborescence », `enemies/` : `shooter_enemy.gd, shooter_def.gd`, `combat/bullets/` : `enemy_bullet_look.gd`.
- [ ] **T2. Réglages et constantes** (CA 1, 5) : `CombatTuning` `enemy_bullet_radius` (0,25 tuile) et `enemy_bullet_lifetime` (10 s), script et `.tres` ; `Const` `COLOR_ENEMY_BULLET`, `COLOR_ENEMY_BULLET_OUTLINE`, `Z_INDEX_ENEMY_BULLETS` (voir « Réglages et constantes »).
- [ ] **T3. `BulletManager` et apparence réservée** (CA 1, 5, 6, 7)
  - [ ] `combat/bullets/bullet_manager.gd` : contrat des dégâts par camp, origine dans une cellule solide, `add_appearance()` sans doublon (voir « `BulletManager` »).
  - [ ] `combat/bullets/enemy_bullet_look.gd` : `EnemyBulletLook` (voir « Apparence réservée »).
  - [ ] `debug/bullet_load_test.gd` : dégâts et apparence (voir « Test de charge F5 »).
- [ ] **T4. `Telegraph.progress()`** (CA 2, 3) (voir « `Telegraph` »).
- [ ] **T5. Base des ennemis** (CA 2, 3, 9) : `enemies/enemy.gd` (`setup()` à 4 paramètres) ; `enemies/shooter_def.gd` (`ShooterDef`) et `enemies/shooter_enemy.gd` (`ShooterEnemy`) (voir « `Enemy` », « `ShooterDef` », « `ShooterEnemy` »).
- [ ] **T6. La Veilleuse** (CA 2, 4) : `enemies/night_light/night_light.tscn` + `night_light.gd`, `data/enemies/night_light.tres`, `audio/sfx/sfx_enemy_night_light_telegraph.wav` (voir « La Veilleuse »).
- [ ] **T7. La Berceuse** (CA 3, 4) : `enemies/lullaby/lullaby_def.gd` (`LullabyDef`), `lullaby.tscn` + `lullaby.gd`, `data/enemies/lullaby.tres`, `audio/sfx/sfx_enemy_lullaby_telegraph.wav` (voir « La Berceuse »).
- [ ] **T8. Arène** (CA 1, 9) : `rooms/arena/arena.gd` : `_enemy_bullets` gardé, `z_index`, passé à `spawn_enemy()` (voir « Arène »).
- [ ] **T9. Panneau F1** (CA 5, 12) : touches 7 et 8, émetteur de test à l'apparence réservée (voir « Panneau F1 »).
- [ ] **T10. Vérifications headless** (CA 1 à 13) : nouvelles scènes de `game/.scratch`, `run_all.sh` étendu (voir « Stratégie de test »).
- [ ] **T11. Vérifications fenêtrées sous WSLg** (CA 1, 2, 3) : lueur, inspiration, projectiles au-dessus des ennemis, du joueur et des chiffres, F2, captures.
- [ ] **T12. Régression** : import et lancement sans erreur, recherche des interdits, `run_all.sh` complet (scènes de 2.3 inchangées et nouvelles).
- [ ] **T13. Reports** : mettre à jour `deferred-work.md` (entrées résolues, voir « Reports traités par cette story » ; nouvelles entrées NON ÉVALUÉ / NON VÉRIFIÉ, voir « Stratégie de test » point 16).

## Dev Notes

### Ce que cette story pose, et ce qu'elle ne pose pas

Le `BulletManager` ennemi donné aux ennemis, la couche commune des tireuses, La Veilleuse, La Berceuse, l'apparence réservée des projectiles ennemis et leur ordre de dessin, le contrat des dégâts de `fire()`, le refus d'un tir né dans un mur, et deux commandes F1. **Hors périmètre** (ne pas anticiper) :

| Élément | Story |
|---|---|
| Le Mouton, charge, étourdissement, déplacement par direction, masque de charge, annulation de télégraphe | 2.5 |
| Vagues, `Events.room_cleared`, « ennemi choisi », « tuer tout », « vague suivante », plafond des sons de télégraphe simultanés | 2.6 |
| HUD (lisibilité d'un coup reçu) | 2.7 |
| Télémétrie (cause de la mort `ENEMY_BULLET`) | 2.8 |
| Graze, dash parfait (`FLAG_COUNTED`), danger (`telegraph_mult` ≠ 1, projectiles plus rapides en Dérive), Éveil qui efface les projectiles | Epic 3 |
| Obstacles et meubles qui arrêtent les projectiles, ligne de vue, `AStarGrid2D` (contourner un coin en reculant), `RunRng` | Epic 4 |
| Reflet du Miroir (tire des projectiles ennemis) | 5.10 |
| `BulletPattern` en Resource (spirales, rangées du Professeur) | 6.1 / 6.2 |
| Couleurs définitives (réservées comprises), sprites, animations, sons définitifs | 7.2, 7.3, 7.7 |

### État actuel du dépôt (stories 1.1 à 2.3 `done`)

- **Autoloads** : `Log`, `Events`, `GameClock`, `Settings`, `SaveService`, `Audio`.
  - `Events` : `player_hit(damage: int, source: int)`, `enemy_damaged(world_position: Vector2, amount: float)`, `run_ended(outcome: int)`. **Cette story n'ajoute aucun signal au bus.**
  - `GameClock` : groupes `PLAYER, ENEMIES, ENEMY_BULLETS, PLAYER_BULLETS, WORLD, FX` ; `scale(group)` nul en pause ; `global_multiplier` borné à [0, 1] (F4) ; `paused` écrit par `Main._freeze()` seul.
  - `Audio.play_sfx(stream, max_voices = 3) -> bool`, `voices_of(stream)` ; limite de voix **par flux** (chaque son de télégraphe a donc ses 3 voix). Ne pas modifier.
- **`core/constants.gd`** (`Const`) : `TILE_SIZE` 16, `ROOM_TILES` 36×19, couches (`LAYER_WALLS`, `LAYER_PLAYER`, `LAYER_ENEMIES`…), groupes `GROUP_BULLET_MANAGERS`, `GROUP_DEBUG_SHAPES`, `GROUP_PLAYER`, `GROUP_ROOM`, `COLOR_PLAYER_SHOT` (0.55, 0.95, 1.0) « réservée aux tirs du joueur, valeur finale en 7.2 », `Z_INDEX_DECOR` −1, `PHYSICS_PRIORITY_HITBOXES` 50, `PHYSICS_PRIORITY_BULLETS` 100. **Aucune couleur ni `z_index` des projectiles ennemis.**
- **`core/combat_tuning.gd`** : `starting_half_hearts` 6, `heart_cap_half_hearts` 24, `hit_damage_half_hearts` 1, `hit_invulnerability_duration` 1,0, `min_telegraph` 0,4, `min_spawn_distance` 3,0 (défauts = valeurs du GDD, précédent des stories 1.x : une seule instance, exemptée de la décision 32 de 2.3). **Ni rayon ni durée de vie des projectiles ennemis.**
- **`combat/bullets/bullet_manager.gd`** (`BulletManager`, `Node2D`, priorité 100) :
  - `setup(solid_layers)` avant `add_child` ; `_ready()` dimensionne les tableaux, groupe `bullet_managers`.
  - `add_appearance(texture) -> int` : **crée un `MultiMeshInstance2D` à chaque appel**, même pour une texture déjà enregistrée (`MAX_APPEARANCES` 256, au-delà `Log.error` + `assert`, −1). Le joueur en ajoute une à chaque `equip_bullets()` (report 1.5, non traité ici) ; le panneau F1 en ajoute une par manager rencontré.
  - `fire(params, origin, direction) -> bool` : `_is_shot_valid()` (prêt, `params`, apparence connue, vitesse dans (0, une tuile par tick), durée de vie finie > 0, rayon ≥ 0, **dégâts finis ≥ 0**, direction normée ; sinon `Log.error` + `assert`, `false`) ; pool plein → `refused_count += 1`, `false` sans log. Conversion tuiles → pixels **ici seulement** (`speed`, `radius`).
  - `_physics_process` : déplacement, durée de vie, cibles **avant** murs (`_test_targets` cercle contre rectangle, `one_hit_per_tick`), murs par lecture de cellule (`_hits_solid`) ; coups livrés après la boucle (`_deliver_hits`, source `ENEMY_BULLET` pour le camp ennemi, cible sautée si libérée, désinscrite ou en suppression).
  - **Un projectile né dans une cellule solide** : testé seulement après son premier pas ; s'il en sort dans ce pas (origine à moins d'un pas du bord de la cellule, en s'éloignant du mur), il vit (report 1.2).
  - `FLAG_COUNTED` réservé au graze (epic 3) : ne pas y toucher.
- **`combat/bullets/bullet_params.gd`** (`BulletParams`) : `speed` 5.5, `radius` 0.25, `lifetime` 8.0, `appearance` 0, `damage` **0.0** (tuiles, secondes). Pas touché.
- **`combat/telegraph.gd`** (`Telegraph`, `Node`) : `setup(clock_group)` ; `start(base, sound, multiplier = 1.0) -> float` (durée `max(base × mult, min_telegraph)`, valeurs invalides bornées avec `_assert_failed()`, `Log.debug("combat", "telegraph <propriétaire> started duration=…")`, son par `Audio.play_sfx()`, son nul → `Log.error` + assert) ; `is_active()` ; décompte en ticks pondérés, enfant de l'ennemi à la même priorité, **il tique après lui** : démarré au tick N pour 0,4 s, l'ennemi le voit inactif au tick N + 24 (0,6 s → N + 36 ; 0,5 s → N + 30). **Pas de progression exposée.**
- **`combat/hit_points.gd`**, **`combat/hitbox.gd`**, **`combat/hurtbox.gd`** (`refuse_hit()`), **`combat/damage_info.gd`** (`Source { PLAYER_SHOT = 0, ENEMY_BULLET = 1, DEBUG = 2, CONTACT = 3 }`), **`combat/health.gd`** (`apply_damage()` : `roundi(amount) < 1` refusé avec `Log.error` + `assert`) : pas touchés.
- **`enemies/enemy_def.gd`** (`EnemyDef`) : `id`, `scene`, `max_hp`, `body_size`, `hurtbox_size`, `contact_size`, **défauts neutres** (0, `Vector2.ZERO`) ; un oubli est signalé par la validation (`HitPoints._init`, `Enemy._pixel_size`). Pas touché.
- **`enemies/enemy.gd`** (`Enemy extends CharacterBody2D`) :
  - `setup(def, target: Node2D, target_hurtbox: Hurtbox)` avant `add_child` ; `_ready()` incomplet → `process_mode = DISABLED`, `_def = null`, `Log.error` + `assert`.
  - Crée en code : corps (forme neuve, `LAYER_ENEMIES`, masque murs | joueur | ennemis, `MOTION_MODE_FLOATING`), `hp` (`HitPoints`), `hurtbox` (camp `ENEMY`, filtre `not hp.is_dead()`), `_contact` (`Hitbox`, `hit_damage_half_hearts`, `CONTACT`, groupe `ENEMIES`), `_feedback` (`HitFeedback`), `telegraph` (`Telegraph`, groupe `ENEMIES`).
  - `_on_hurtbox_damage_received()` : PV, `refuse_hit()` si refusé, flash et recul, `_die()` (une fois : `PROCESS_MODE_DISABLED`, invisible, `queue_free()`).
  - Aides : `_move_toward(point, speed_px, clock_scale)` (ligne directe, `move_and_slide()`, arrêt si cible invalide ou point atteint), `_target_position()`, `_distance_to_target()` (`INF` sans cible), `body_world_rect()`, `_pixel_size()`, `_assert_failed()`.
  - Contrat de scène : `%Sprite` (`Sprite2D` en (0, 0), sans `material` ; on l'anime par `texture` seulement), `%Body` (`CollisionShape2D`).
- **`enemies/sleepwalker/`** : `SleepwalkerDef`, `Sleepwalker` (`enum State { CHASE, TELEGRAPH, RUSH }`, `_process_<état>()`, `_state` écrit dans `_enter()` seulement, `_bounded_px()` / `_bounded_seconds()` avec `_assert_failed()`, textures provisoires générées en code sur une toile 16×24, violet pâle), `sleepwalker.tscn` (racine + `Sprite` + `Body`), `data/enemies/sleepwalker.tres` (valeurs explicites). **Ne pas modifier** (le 4e paramètre de `setup()` est optionnel).
- **`rooms/arena/arena.gd`** (`Arena`) :
  - `_ready()` : groupe `room`, décor en `Z_INDEX_DECOR`, tuiles, `_setup_player_bullets()` (`_player_bullets` gardé, cibles inscrites, `equip_bullets()`), `_setup_enemy_bullets()` (**`EnemyBullets` dans une variable locale**, capacité 512, hurtbox du joueur inscrite, **aucune apparence**), `_setup_damage_numbers()` ; caméra.
  - `spawn_enemy(def, requested) -> Enemy` : garde `is_node_ready()`, def / scène / joueur, `_resolve_spawn_position()` (bornage à la zone, distance minimale 3 tuiles, corps disjoints des vivants avec marge de 1 px, anneaux de 1 à 4 tuiles, coins ; `Vector2(INF, INF)` si rien), racine `Enemy` exigée, **`enemy.setup(def, _player, _player.hurtbox)`**, ajout sous `Enemies`, refus d'un `_ready()` raté, `reset_physics_interpolation()`, inscription de la hurtbox dans `PlayerBullets`, compte, `tree_exited` en `CONNECT_ONE_SHOT`, `Log.debug("room", "spawned …")`.
  - Ordre de l'arbre : `Floor`, `Walls`, `Targets`, `Enemies`, `Camera`, puis en code `PlayerBullets`, `EnemyBullets`, `DamageNumbers` (dessinés dans cet ordre, tous à `z_index` 0 sauf le décor). Le joueur est dans `Run`, avant `RoomSlot` : dessiné sous l'arène.
- **`player/player.gd`** : `collision_mask = LAYER_WALLS | LAYER_ENEMIES` ; hurtbox 6×6 px, `one_hit_per_tick`, filtre `not is_invulnerable() and not health.is_dead()` ; `equip_bullets(manager)` : `BulletParams` propre, `damage = maxf(tuning.damage, 0.0)`, texture 4×4 px `COLOR_PLAYER_SHOT` alpha 0,7. **Pas touché.**
- **`player/reticle.gd`** : `top_level`, `z_index` 100 (« au-dessus de la salle et des projectiles »), passe dans le HUD à la 2.7. Pas touché.
- **`debug/debug_panel.gd`** : touches 1 à 6 (`physical_keycode`, panneau visible, hors pause, sans répétition) ; émetteur de test (touches 4 et 5) : `BulletParams` propre, vitesse 5 tuiles/s, rayon 0,25, durée 10 s, dégâts `hit_damage_half_hearts`, **texture rose 8×8 propre** `EMITTER_BULLET_COLOR` (1.0, 0.35, 0.6), apparence ajoutée une fois par manager (`_appearance_manager_id`) ; touche 6 → `room.spawn_enemy(SLEEPWALKER_DEF, SPAWN_REQUEST (304, 40))` ; ligne `enemies alive N`. Le `Label` fait 118 px de haut (débordement toléré, ou l'agrandir).
- **`debug/bullet_load_test.gd`** (F5) : manager ennemi de 512, ≈ 400 projectiles, `_params = BulletParams.new()` **avec `damage` 0** (défaut) et sa propre texture rose 8×8 `BULLET_COLOR` (1.0, 0.35, 0.6) ; aucune cible.
- **`vfx/damage_numbers.gd`** : couche des chiffres de dégâts, `z_index` 0, ajoutée après `EnemyBullets`.
- **`audio/sfx/`** : `sfx_player_shot.wav`, `sfx_player_hit.wav`, `sfx_enemy_sleepwalker_telegraph.wav` (générés par script, `.import` versionnés).
- **Il n'existe ni `enemies/night_light/`, ni `enemies/lullaby/`, ni `ShooterEnemy`, ni couleur réservée des projectiles ennemis, ni `Telegraph.progress()`.**
- **`game/.scratch`** (vrai dossier exclu de git, **ne jamais le commiter ni le remplacer par un lien**) : `th.gd` (harnais, priorité 200, `check()`, `approx()`, `make_run()`, `spawn()`, `put()`, `key()`, `find_all()`, `test_params()`), `killer.gd`, `mover.gd`, `mk_tscn.sh`, `rs.sh`, scènes `t_enemy_parts`, `t_sleepwalker`, `t_enemy_main`, `t_invalid23`, `t_regress` (5 scènes `PASS`, 250 contrôles au dernier passage), `run_all.sh` (import et lancement, verdicts, messages d'assertion comptés pour `t_invalid23`, journaux, règles de source avec témoins plantés). **Ces scènes ne se réécrivent pas** : la 2.4 en ajoute de nouvelles et étend `run_all.sh`.

### Reports traités par cette story (`deferred-work.md`)

| Report | Origine | Réponse de cette story |
|---|---|---|
| Base des ennemis pour la 2.4 : pas de `BulletManager` ennemi dans `Enemy.setup()`, `EnemyBullets` local à l'arène | revue 2.3 | `Enemy.setup(def, target, target_hurtbox, bullets = null)` ; l'arène garde `_enemy_bullets` et le passe à tout ennemi |
| Projectile ennemi de dégâts < 0,5 accepté par `fire()` : il consomme le coup du tick et `Health` le refuse avec `assert` | revue 2.1 | CA 6 : `fire()` refuse un camp ennemi à `roundi(damage) < 1` ; les tireuses portent `hit_damage_half_hearts` ; F5 tire avec cette valeur |
| Contrat des dégâts nuls : `BulletManager` accepte un tir à 0, `HitPoints` le refuse avec `assert` | revue 2.3 | CA 6 : `fire()` refuse un camp joueur à `damage <= 0` |
| Projectile qui apparaît dans une cellule solide : il vit | revue 1.2 (« à reprendre avec les motifs ennemis ») | CA 7 : `fire()` renvoie `false` pour une origine dans une cellule solide |

**Restent ouverts** (ne pas traiter ici) : son de télégraphe muet au-delà de 3 voix et qui survit à l'ennemi (2.6 ou 7.7 ; les deux nouveaux sons ont leurs propres 3 voix) ; poussée du joueur par le Somnambule en accélération (4.3) ; base des ennemis pour la 2.5 ; `refuse_hit()` non réentrant ; `equip_bullets()` répétable (4.8) ; lisibilité d'un coup reçu en plein combat (2.7, HUD) ; mesure de 10 minutes à 400 projectiles sur la machine de référence (**étape humaine, NON FAITE**, à rappeler à Kroustille en fin d'epic).

### Leçons des stories 1.1 à 2.3 à appliquer

- **Chaque contrôle prouve son mécanisme, avec un témoin, et doit pouvoir échouer** ; pas de tautologie, pas de `check(true)`, pas de valeur calculée et non affirmée. Ici plusieurs mécanismes se recouvrent : une tireuse qui « ne tire pas » peut être en début de cycle, en lueur, figée par la pause, morte, sans cible, ou ses tirs refusés par `fire()` (vérifier `active_count` **et** l'absence de message d'erreur) ; un joueur « pas touché » peut être invulnérable, hors trajectoire ou derrière une salve refusée. Chaque point de la « Stratégie de test » dit ce qu'il isole et donne son témoin. Contrôles par mutation consignés dans le Debug Log (mécanisme retiré, scène relancée, fichier restauré octet pour octet, somme de contrôle).
- **Ordre des ticks** : entités à 0 (une tireuse tire dans son tick), `Hitbox` à 50, `BulletManager` à 100. **Un projectile tiré au tick N par une tireuse avance d'un pas au même tick N** (son manager tique après elle) et peut toucher au tick N. Le `Telegraph`, enfant de l'ennemi, tique après lui.
- **Un assert qui échoue interrompt la fonction en build de debug** : poser l'état sûr **avant** `Log.error` + `assert`, isoler l'assert dans `_assert_failed()` quand une valeur bornée doit encore être renvoyée (décision 27 de 2.3).
- **Défauts neutres dans les `Def`** (décision 32 de 2.3) : 0 partout ; les valeurs du GDD vivent dans les `.tres` (Godot omet d'un `.tres` réenregistré une valeur égale au défaut) ; un oubli est signalé, jamais hérité.
- **Typage strict, avertissements en erreur** : `PackedScene.instantiate()` → `as Enemy` ; `_def as ShooterDef` / `as LullabyDef` ; résultat d'un `Callable.call()` testé par `is` ; `deg_to_rad()` pour les angles (Resources en degrés, code en radians, architecture « Dégâts et unités ») ; `Vector2.rotated()` prend des radians.
- **Injection** : `setup()` avant `add_child()` ; composants créés en code avec un `name` explicite ; formes et `BulletParams` **neufs** par instance (jamais une Resource partagée modifiée) ; pas de `/root/...` ni `get_parent().get_parent()`.
- **Ticks** : compteurs décrémentés de `GameClock.scale(groupe)`, `TICK_EPSILON = 1e-6`. Pas de `Timer`, `create_timer`, `Tween` en temps réel.
- **Vérifications** : `--import`, puis `--quit-after 120` (zéro `SCRIPT ERROR`, zéro `Parse Error`, seul avertissement connu `settings.cfg missing`) ; scènes (`--scene res://.scratch/<scène>.tscn`, `--script` ne résout pas les autoloads) ; `Input.parse_input_event()` s'applique au tick suivant ; `preload()` dans les scripts de test, `@warning_ignore_start(...)` pour les `unsafe_*` des scripts jetables seulement ; en headless, un `assert(false)` imprime un `SCRIPT ERROR` et le jeu continue : les chemins d'erreur vont dans une scène qui annonce ses assertions (`CASE … EXPECT_ASSERTS n`).
- **Fichiers générés par Godot** : versionner les `.uid` des nouveaux scripts et les `.wav.import` ; relire les `.tres` après `--import` (valeurs explicites conservées).

### Réglages et constantes (AR9, CA 1, 5)

`core/combat_tuning.gd` et `data/tuning/combat_tuning.tres` :

| Champ | Type | Valeur | Rôle |
|---|---|---|---|
| `enemy_bullet_radius` | `float` (tuiles) | 0.25 | rayon de collision de tout projectile ennemi (4 px) ; la texture réservée a ce diamètre (8 px) : ce qu'on voit est ce qui touche |
| `enemy_bullet_lifetime` | `float` (s) | 10.0 | filet de sécurité, pas une portée : les murs arrêtent tout projectile bien avant |

`@export_range` et une ligne de doc par champ, comme les autres ; en-tête de classe : « … telegraphs, spawns and enemy bullets ». Valeurs absentes du GDD (provisoires, voir les décisions). Défauts = valeurs (précédent `CombatTuning`).

`core/constants.gd` :

```gdscript
## Colors reserved for enemy bullets (FR26, NFR8): a fill and a 1 px outline that no other drawing uses, identical in
## every phase and lucidity tier. Placeholder values, final ones set by story 7.2.
const COLOR_ENEMY_BULLET: Color = Color(1.0, 0.2, 0.55)
const COLOR_ENEMY_BULLET_OUTLINE: Color = Color(0.4, 0.0, 0.2)

## z_index of the enemy BulletManager: above everything else in the world (entities, player shots, damage numbers),
## whatever its place in the tree (AR19, NFR8). Below the reticle (100), an aim aid that moves to the HUD in story 2.7.
const Z_INDEX_ENEMY_BULLETS: int = 10
```

- Couleurs : remplissage rose vif saturé, contour lie-de-vin sombre ; à 640×360 sur le sol sombre, le remplissage porte la lisibilité, le contour la portera sur les décors pastel de l'epic 7. Le développeur peut ajuster les valeurs **à condition** que le contrôle « couleurs réservées » (point 3 de la stratégie de test) passe : distance RGB ≥ 0,2 de toute autre `Color` constante du jeu, blanc du flash et du réticule compris.
- `Z_INDEX_ENEMY_BULLETS` : `z_as_relative` reste à `true` (doc `CanvasItem` 4.7 : la valeur finale est la somme avec le parent ; l'arène est à 0) ; les `MultiMeshInstance2D` enfants du manager héritent du décalage. Plage autorisée : `RenderingServer.CANVAS_ITEM_Z_MIN..CANVAS_ITEM_Z_MAX`.

### `BulletManager` (CA 5, 6, 7)

`combat/bullets/bullet_manager.gd`, trois changements, rien d'autre (la boucle par projectile ne change pas) :

1. **`add_appearance()` sans doublon** : garder `var _appearance_textures: Array[Texture2D] = []` ; si `texture` y est déjà (même objet, `find()` compare les références), renvoyer son index **sans** créer de `MultiMeshInstance2D`. Doc : « The same Texture2D registered again returns its first index: one MultiMeshInstance2D per look, whatever the number of shooters ». Le comportement du joueur (texture neuve à chaque `equip_bullets()`) ne change pas.
2. **Contrat des dégâts par camp** dans `_is_shot_valid()`, à la place de `damage < 0.0` :

```gdscript
	elif not is_finite(params.damage):
		problem = "damage %s must be finite" % params.damage
	elif camp == Camp.ENEMY and roundi(params.damage) < 1:
		# Same rule as Health.apply_damage(): the player counts whole half-hearts (story 2.4, reports of 2.1 and 2.3).
		problem = "damage %s would be refused by the player's Health (at least 1 half-heart after rounding)" % params.damage
	elif camp == Camp.PLAYER and params.damage <= 0.0:
		problem = "damage %s would be refused by the enemies' HitPoints (must be > 0)" % params.damage
```

   Toujours `Log.error` + `assert` (une donnée invalide, pas une situation de jeu). Mettre à jour la doc de `fire()` et de `BulletParams.damage` (« ENEMY camp: half-hearts, at least 1 after rounding. PLAYER camp: enemy HP, > 0 »).
3. **Origine dans une cellule solide** : dans `fire()`, après la validation et **avant** le test du pool : `if _hits_solid(origin): return false` (sans log : une tireuse collée à un mur est une situation de jeu ; pas de `refused_count`, qui compte le pool plein, lu par F3). Doc de `fire()` : « Returns false, without error or log, when the origin is inside a solid cell (the wall would stop it at once) ». Un tir **hors** de la cellule, même collé au mur, part normalement.

Le coût ajouté est une lecture de cellule par tir (pas par tick) : sans effet mesurable sur le test de charge.

### Apparence réservée (FR26, NFR8, CA 1, 5)

`combat/bullets/enemy_bullet_look.gd` :

```gdscript
@abstract
class_name EnemyBulletLook
## The one look of every enemy bullet (FR26, NFR8): a disc of the collision diameter (Tuning.COMBAT.enemy_bullet_radius)
## in Const.COLOR_ENEMY_BULLET, with a 1 px outer ring in Const.COLOR_ENEMY_BULLET_OUTLINE, transparent outside.
## Built once and shared: BulletManager.add_appearance() returns the same index for the same texture, so a manager
## draws every enemy bullet with one MultiMeshInstance2D. Whoever fires enemy bullets uses this texture, debug included.

static var _texture: Texture2D


static func texture() -> Texture2D
```

- Construite au premier appel (`static var`, GDScript ≥ 4.1, doc 4.7 « static variables » ; elle vit jusqu'à la fin du programme, c'est voulu : une texture, aucun nœud) : côté = `maxi(2, ceili(2 × rayon_px))` (8 px aux valeurs actuelles), pixel dont le centre est dans le disque de rayon `rayon_px` → remplissage, ou contour si sa distance au centre dépasse `rayon_px − 1` ; hors disque : transparent. Rayon non fini ou ≤ 0 → texture du plus petit disque (2×2 px) avec `Log.error` + `assert` (état sûr posé avant l'assert ; pas de valeur de jeu en dur).
- Aux valeurs actuelles (8×8) : les 4 pixels centraux sont du remplissage, les pixels du bord du disque sur les axes (par exemple (0, 3), (3, 0)) du contour, les coins (0, 0) transparents (vérifié par le point 3 de la stratégie de test).
- Rien d'autre ne fabrique de texture de projectile ennemi : l'émetteur de F1 et le test de charge F5 passent par `EnemyBulletLook.texture()`.

### Test de charge F5 (CA 6, 13)

`debug/bullet_load_test.gd` : `_params.damage = Tuning.COMBAT.hit_damage_half_hearts` (aucune cible : sans effet, mais `fire()` refuserait désormais 0) ; `_params.radius = Tuning.COMBAT.enemy_bullet_radius` ; apparence `EnemyBulletLook.texture()` ; retirer `BULLET_COLOR`, `BULLET_SIZE` et `_make_bullet_texture()`. Même taille de quad (8 px) : la mesure de 1.2 reste comparable. **Vérifier `Bullets 400 | refused 0`** (`t_regress` le fait déjà) **et** zéro `SCRIPT ERROR` dans la scène F5.

### `Telegraph` (CA 2, 3)

`combat/telegraph.gd` : ajouter `var _ticks_total: float = 0.0`, posé dans `start()` avec `_ticks_left`, et :

```gdscript
## Share of the telegraph already elapsed, from 0 (just started) to 1 (about to end); 0 when inactive.
## Drives the owner's animation steps (rising glow, inhale). Ticks after its owner: the owner reads last tick's value.
func progress() -> float:
	if not is_active() or _ticks_total <= 0.0:
		return 0.0
	return clampf(1.0 - _ticks_left / _ticks_total, 0.0, 1.0)
```

Rien d'autre ne change (le Somnambule ne l'utilise pas).

### `Enemy` (CA 9)

`enemies/enemy.gd` :

- `setup(def: EnemyDef, target: Node2D, target_hurtbox: Hurtbox, bullets: BulletManager = null)` ; `var _bullets: BulletManager` (doc : « the room's enemy BulletManager: shooters fire through it; null for an enemy that never fires »). Optionnel : Le Somnambule et les scènes de test de 2.3 l'ignorent. `_ready()` ne le teste pas (c'est `ShooterEnemy` qui l'exige).
- En-tête : ajouter « Shooters (ShooterEnemy) fire through the room's enemy BulletManager, given by setup() ».
- **Aucune autre modification** : ni machine à états, ni tir dans la base.

### `ShooterDef` (AR9, D4, CA 2, 3, 4)

`enemies/shooter_def.gd`, `class_name ShooterDef extends EnemyDef` : les valeurs de tir communes aux deux tireuses, **défauts neutres (0)**.

| Champ | Type | Veilleuse | Berceuse | Rôle |
|---|---|---|---|---|
| `fire_interval` | `float` (s) | 2.0 | 1.5 | cycle de tir : d'un départ de télégraphe au suivant, donc d'une salve à la suivante |
| `telegraph_duration` | `float` (s) | 0.6 | 0.5 | lueur / inspiration, avant la salve (au moins `min_telegraph`) |
| `bullet_speed` | `float` (tuiles/s) | 5.0 | 6.0 | vitesse des projectiles |
| `bullet_count` | `int` | 3 | 1 | projectiles par salve |
| `spread_angle` | `float` (degrés) | 20.0 | 0.0 | angle entre deux projectiles voisins de l'éventail |

`@export_range` par champ (`bullet_count` : `0, 16, 1, "or_greater"`), une ligne de doc chacun. L'éventail est **centré** sur la direction du joueur : décalage du projectile `i` = `spread × (i − (count − 1) / 2.0)`, soit −20°, 0°, +20° pour la Veilleuse, 0° pour la Berceuse. `bullet_count` et `spread_angle` de la Berceuse sont des valeurs du GDD (« 1 projectile visé », NFR9), pas des constantes du code.

### `ShooterEnemy` (CA 2, 3, 9, 10)

`enemies/shooter_enemy.gd`, `class_name ShooterEnemy extends Enemy` : la mécanique commune du cycle, du télégraphe et de la salve. **La machine à états reste dans chaque tireuse** (enum, `_process_<état>()`, `_state` écrit dans `_enter()` seulement).

```gdscript
class_name ShooterEnemy
extends Enemy
## Base of the enemies that shoot (La Veilleuse, La Berceuse): a fire cycle of ShooterDef.fire_interval that restarts
## when a telegraph starts, so volleys come every fire_interval; the first telegraph comes one full cycle after the
## spawn. A volley is a fan of bullet_count bullets spread_angle apart, centered on the target, fired through the
## room's enemy BulletManager (setup()) at the target's position of the firing tick, with the reserved look.
## Subclasses hold the state machine and call _tick_cycle() once per tick, in every state.

const TICK_EPSILON: float = 1e-6

var _shooter_def: ShooterDef
var _bullet_params: BulletParams
var _cycle_ticks_left: float = 0.0
var _volley_count: int = 0
var _spread_radians: float = 0.0
var _interval_seconds: float = 0.0


func _ready() -> void:
	super()
	if _def == null:
		return # already reported by Enemy
	# _shooter_def = _def as ShooterDef; null, or _bullets null: PROCESS_MODE_DISABLED, Log.error + assert, _def = null
	# (subclasses test _def after super(), like Enemy's contract), return.
	# Validated once (AR28, decision 27 of 2.3): fire_interval and telegraph_duration finite and > 0, bullet_count >= 0,
	# spread_angle finite, bullet_speed finite and > 0; otherwise bounded with Log.error + _assert_failed():
	# interval/telegraph -> 0, spread -> 0, count -> 0; an invalid speed sets _volley_count to 0 (never fires).
	# _bullet_params: BulletParams.new() (own instance): speed = bullet_speed, radius = Tuning.COMBAT.enemy_bullet_radius,
	# lifetime = Tuning.COMBAT.enemy_bullet_lifetime, damage = Tuning.COMBAT.hit_damage_half_hearts,
	# appearance = _bullets.add_appearance(EnemyBulletLook.texture()) (the same index for every shooter).
	# _restart_cycle(): the first telegraph comes one full cycle after the spawn.


## Once per tick, in every state, before the state's _process_<state>(): advances the fire cycle.
func _tick_cycle(clock_scale: float) -> void:
	_cycle_ticks_left -= clock_scale


func _is_cycle_over() -> bool:
	return _cycle_ticks_left <= TICK_EPSILON


## Starts the telegraph (sound included) and restarts the cycle. Called by the subclass's _enter(TELEGRAPH).
func _start_telegraph(sound: AudioStream) -> void:
	_restart_cycle()
	telegraph.start(_shooter_def.telegraph_duration, sound)


## Fires one volley at the target's current position. Returns the number of bullets fired (0 without a target, on
## top of it, with a refused or walled-in shot). One Log.debug per volley, never per tick.
func _fire_volley() -> int
```

- **`_fire_volley()`** : `if _volley_count <= 0 or not is_instance_valid(_target): return 0` ; `origin = _bullets.to_local(global_position)` ; `to = _bullets.to_local(_target_position()) - origin` ; `to.length_squared() < 1e-6` → 0 ; `aim = to.normalized()` ; pour `i` dans `_volley_count` : `_bullets.fire(_bullet_params, origin, aim.rotated(_spread_radians * (i - (_volley_count - 1) / 2.0)))`, compter les `true` ; `Log.debug("combat", "%s fired %d/%d" % [_def.id, fired, _volley_count])` ; renvoyer `fired`. `aim.rotated()` d'un vecteur normé reste normé (`is_equal_approx` de `fire()`).
- `_restart_cycle()` : `_cycle_ticks_left = _interval_seconds * Engine.physics_ticks_per_second`.
- **Nombre de ticks** (60 Hz, échelle 1), pour une tireuse dont la sous-classe appelle `_tick_cycle()` en tête de tick puis passe en `TELEGRAPH` dès `_is_cycle_over()` :
  - apparition : `_cycle_ticks_left` = 120 (Veilleuse) ; premier départ de télégraphe au **120e tick de physique** après l'ajout à l'arbre ;
  - télégraphe démarré au tick N (cycle remis à 120 après la décrémentation du tick N) ; l'ennemi le voit inactif au tick N + 36 (Veilleuse) / N + 30 (Berceuse) → salve à ce tick ;
  - télégraphe suivant au tick N + 120 (Veilleuse) / N + 90 (Berceuse) : **une salve exactement toutes les 120 / 90 ticks**, ≥ 0,6 / 0,5 s de télégraphe avant chacune (FR26 : ≥ 0,4 s).
  - Si un jour le télégraphe dure plus que le cycle (danger, epic 3), la tireuse repart en télégraphe dès la salve tirée : la période s'allonge, l'annonce n'est jamais raccourcie.
- Une tireuse morte est désactivée (`_die()` de la base) : plus de tick, donc ni télégraphe ni salve ; ses projectiles déjà tirés appartiennent au manager et continuent.

### La Veilleuse (FR28, CA 2, 4)

**`data/enemies/night_light.tres`** : `script_class="ShooterDef"` (pas de sous-classe : la Veilleuse n'a aucune valeur propre ; « immobile » est son comportement, pas un réglage). `id = &"night_light"`, `scene` = `res://enemies/night_light/night_light.tscn`, `max_hp` 40, tailles provisoires identiques au Somnambule (`body_size` (0.625, 0.625), `hurtbox_size` (0.75, 1.25), `contact_size` (0.75, 0.75)), `fire_interval` 2.0, `telegraph_duration` 0.6, `bullet_speed` 5.0, `bullet_count` 3, `spread_angle` 20.0. Toutes les valeurs explicites dans le fichier.

**`enemies/night_light/night_light.tscn`** : racine `NightLight` (`CharacterBody2D`, script `night_light.gd`) > `Sprite` (`Sprite2D`, `unique_name_in_owner`, en (0, 0), sans `material`) et `Body` (`CollisionShape2D`, `unique_name_in_owner`). Même contrat que `sleepwalker.tscn`.

**`enemies/night_light/night_light.gd`** :

```gdscript
class_name NightLight
extends ShooterEnemy
## La Veilleuse (FR28): a turret that never moves. When its fire cycle ends, a glow rises for telegraph_duration
## (Telegraph: animation in GLOW_STEPS textures, and sound), then it fires a fan of bullets centered on the player.
## Contact hurts (Enemy's Hitbox); its body blocks the player but is never pushed (it never calls move_and_slide()).
## Every value comes from its ShooterDef (night_light.tres).

enum State { IDLE, TELEGRAPH }

## Placeholder telegraph sound, generated by a script; replaced by story 7.7.
const TELEGRAPH_SOUND: AudioStream = preload("res://audio/sfx/sfx_enemy_night_light_telegraph.wav")
## Placeholder animation: rest texture plus this many rising glow textures (visual, until epic 7).
const GLOW_STEPS: int = 3

var _state: State = State.IDLE
var _rest_texture: Texture2D
var _glow_textures: Array[Texture2D] = []


func _physics_process(_delta: float) -> void:
	var clock_scale: float = GameClock.scale(GameClock.Group.ENEMIES) # one read per tick
	if clock_scale <= 0.0:
		return
	_tick_cycle(clock_scale)
	match _state:
		State.IDLE:
			_process_idle(clock_scale)
		State.TELEGRAPH:
			_process_telegraph(clock_scale)


func _process_idle(_clock_scale: float) -> void:
	if _is_cycle_over():
		_enter(State.TELEGRAPH)


func _process_telegraph(_clock_scale: float) -> void:
	if telegraph.is_active():
		_sprite.texture = _glow_textures[mini(int(telegraph.progress() * GLOW_STEPS), GLOW_STEPS - 1)]
		return
	_fire_volley()
	_enter(State.IDLE)


## The only place that writes _state.
func _enter(next: State) -> void:
	_state = next
	match next:
		State.IDLE:
			_sprite.texture = _rest_texture
		State.TELEGRAPH:
			_sprite.texture = _glow_textures[0]
			_start_telegraph(TELEGRAPH_SOUND)
```

- **`_ready()`** : `super()` ; `if _def == null: return` (déjà signalé) ; textures provisoires ; `_enter(State.IDLE)`. Aucune sous-classe de `Def` à tester (`ShooterEnemy` a déjà exigé un `ShooterDef`).
- **Immobile** : jamais de `move_and_slide()`, `velocity` reste nulle. Un `CharacterBody2D` n'est déplacé que par son propre `move_and_slide()` : le joueur qui la pousse s'arrête sur son corps, elle ne bouge pas (contrôle : position identique au bit près après 120 ticks de poussée).
- **Salve** : visée au tick du tir (position du joueur à ce tick), éventail centré, 3 projectiles à 80 px/s (4/3 px par tick), 20° entre voisins.
- **Textures provisoires** (constantes visuelles locales, « placeholder until epic 7 ») : toile 16×24 (comme le Somnambule) ; une lampe de chevet : pied et abat-jour d'une couleur sourde (par exemple ocre pâle), ampoule éteinte au repos ; `GLOW_STEPS` textures où l'ampoule et un halo s'éclaircissent et s'élargissent pas à pas (jaune de plus en plus clair). **Couleurs à au moins 0,2 (RGB) des deux couleurs réservées** (contrôle du point 3) et distinctes du joueur (bleu), du Somnambule (violet), des cibles (orange), du tir du joueur (cyan). L'animation change **seulement** `texture`.

### La Berceuse (FR30, CA 3, 4)

**`enemies/lullaby/lullaby_def.gd`** : `class_name LullabyDef extends ShooterDef`, défauts neutres.

| Champ | Type | Valeur | Source |
|---|---|---|---|
| `min_distance` | `float` (tuiles) | 4.0 | GDD : « se tient entre 4 et 8 tuiles » |
| `max_distance` | `float` (tuiles) | 8.0 | idem |
| `move_speed` | `float` (tuiles/s) | 2.0 | **absent du GDD** : valeur provisoire (voir les décisions), NON ÉVALUÉE |

**`data/enemies/lullaby.tres`** (`script_class="LullabyDef"`) : `id = &"lullaby"`, `scene` = `res://enemies/lullaby/lullaby.tscn`, `max_hp` 30, tailles provisoires du Somnambule, `fire_interval` 1.5, `telegraph_duration` 0.5, `bullet_speed` 6.0, `bullet_count` 1, `spread_angle` 0 (égal au défaut : Godot l'omet, c'est la vraie valeur), `min_distance` 4.0, `max_distance` 8.0, `move_speed` 2.0.

**`enemies/lullaby/lullaby.tscn`** : racine `Lullaby`, même contrat (`%Sprite`, `%Body`).

**`enemies/lullaby/lullaby.gd`** :

```gdscript
class_name Lullaby
extends ShooterEnemy
## La Berceuse (FR30): keeps between min_distance and max_distance of the player, walking straight toward it when
## farther, straight away from it when closer, still in between. When its fire cycle ends it stops and inhales for
## telegraph_duration (Telegraph: animation and sound), then fires an aimed shot (a volley of bullet_count).
## Contact hurts (Enemy's Hitbox). Every value comes from LullabyDef (lullaby.tres).

enum State { KEEP_DISTANCE, TELEGRAPH }

## Placeholder telegraph sound, generated by a script; replaced by story 7.7.
const TELEGRAPH_SOUND: AudioStream = preload("res://audio/sfx/sfx_enemy_lullaby_telegraph.wav")

var _state: State = State.KEEP_DISTANCE
var _lullaby_def: LullabyDef
var _min_px: float = 0.0
var _max_px: float = 0.0
var _speed_px: float = 0.0
var _rest_texture: Texture2D
var _inhale_texture: Texture2D


func _process_keep_distance(clock_scale: float) -> void:
	if _is_cycle_over():
		_enter(State.TELEGRAPH)
		return
	var distance: float = _distance_to_target()
	if distance > _max_px and is_finite(distance):
		_move_toward(_target_position(), _speed_px, clock_scale)
	elif distance < _min_px:
		_move_toward(global_position * 2.0 - _target_position(), _speed_px, clock_scale) # straight away
	else:
		velocity = Vector2.ZERO # in the band: holds its position


func _process_telegraph(_clock_scale: float) -> void:
	if not telegraph.is_active():
		_fire_volley()
		_enter(State.KEEP_DISTANCE)


## The only place that writes _state.
func _enter(next: State) -> void:
	_state = next
	match next:
		State.KEEP_DISTANCE:
			_sprite.texture = _rest_texture
		State.TELEGRAPH:
			velocity = Vector2.ZERO # stands still while inhaling
			_sprite.texture = _inhale_texture
			_start_telegraph(TELEGRAPH_SOUND)
```

- `_physics_process` : même squelette que la Veilleuse (une lecture de l'échelle, retour si ≤ 0, `_tick_cycle()`, `match`).
- **`_ready()`** : `super()` ; `if _def == null: return` ; `_lullaby_def = _def as LullabyDef` ; nul → `process_mode = DISABLED`, `Log.error("combat", "lullaby needs a LullabyDef")` + `assert`, `return` ; conversion **une fois** : distances et vitesse × `TILE_SIZE` ; valeurs non finies ou ≤ 0, ou `min_distance >= max_distance` → bornées (`Log.error` + `_assert_failed()`, vitesse 0 = elle ne bouge pas) ; textures ; `_enter(State.KEEP_DISTANCE)`.
- **Bande** : bornes **comprises** (elle bouge seulement si la distance est strictement au-delà de 8 tuiles ou strictement en deçà de 4) ; distances centre à centre (décision 8 de 2.3) ; à 32 px/s (0,53 px par tick) elle s'arrête au premier tick où elle rentre dans la bande.
- **Recul** : ligne directe à l'opposé du joueur (`_move_toward()` vers le point symétrique ; point confondu → vitesse nulle, sans erreur) ; contre un mur, `move_and_slide()` la fait glisser ; dans un coin elle reste à moins de 4 tuiles (AR23 : contournement avec `AStarGrid2D`, 4.5).
- **Immobile pendant l'inspiration** ; le cycle continue de courir pendant le déplacement et le télégraphe ; **elle tire quelle que soit la distance** (le GDD ne lie pas le tir à la bande).
- **Textures provisoires** : toile 16×24 ; une silhouette (couleur pâle distincte : par exemple vert d'eau pâle) ; `_inhale_texture` : poitrine gonflée (corps plus large de 2 px de chaque côté) et bouche ouverte. Couleurs à ≥ 0,2 des couleurs réservées. `texture` seulement.

### Sons des télégraphes (FR26)

Deux fichiers générés par un script jetable du scratchpad (`uv run python <script>`, module standard `wave`, même méthode que `sfx_enemy_sleepwalker_telegraph.wav`) : mono, 16 bits, 22 050 Hz, amplitude ≈ 0,4, **déterministes** (aucun hasard ; un bruit, s'il en faut un, vient d'un générateur à graine fixe du script) :

- `game/audio/sfx/sfx_enemy_night_light_telegraph.wav` : **≈ 0,5 s** (dans les 0,6 s), un scintillement qui monte (par exemple sinusoïde 500 → 1 000 Hz avec un léger trémolo, enveloppe croissante : « la lueur monte »).
- `game/audio/sfx/sfx_enemy_lullaby_telegraph.wav` : **≈ 0,4 s** (dans les 0,5 s), une inspiration douce (par exemple bourdon grave 180 → 260 Hz, attaque lente, fin coupée nette : « elle retient son souffle »).

Distincts entre eux, du télégraphe du Somnambule (300 → 700 Hz, 0,35 s), du tir (aigu, court) et du coup reçu (grave, descendant). Puis `--import`, versionner `.wav` et `.wav.import`. Remplacés par la 7.7. **Pas de son de tir** pour les tireuses (voir les décisions).

### Arène (CA 1, 9)

`rooms/arena/arena.gd` :

- `var _enemy_bullets: BulletManager`, posé par `_setup_enemy_bullets()` ; dans cette fonction, `bullets.z_index = Const.Z_INDEX_ENEMY_BULLETS` (doc : « drawn above everything else in the world, damage numbers included (NFR8) »). L'ordre de l'arbre ne change pas (le contrôle d'ordre de `t_enemy_main` reste vrai).
- `spawn_enemy()` : `enemy.setup(def, _player, _player.hurtbox, _enemy_bullets)` — à **tout** ennemi (le Somnambule l'ignore). Rien d'autre ne change dans l'apparition.
- En-tête : « the enemy BulletManager (it hits the player's hurtbox; given to every enemy, drawn above the whole world) ».
- Pas d'apparence pré-enregistrée : la première tireuse (ou l'émetteur F1) ajoute `EnemyBulletLook.texture()`, les suivantes retrouvent le même index.

### Panneau F1 (AR24, CA 5, 12)

`debug/debug_panel.gd` :

- `const NIGHT_LIGHT_DEF: EnemyDef = preload("res://data/enemies/night_light.tres")`, `const LULLABY_DEF: EnemyDef = preload("res://data/enemies/lullaby.tres")` (chargés en debug seulement, comme `SLEEPWALKER_DEF`).
- Touches **7** et **8** (mêmes règles que 1 à 6) → un `_spawn(def, label)` commun aux touches 6, 7 et 8 (salle par le groupe `room`, jamais en cache ; « no room » ; `room.spawn_enemy(def, SPAWN_REQUEST)` ; `"<label> spawned at …"` ou `"spawn refused"`). Refactoriser `_spawn_sleepwalker()` dans `_spawn()` sans changer son comportement ni ses messages.
- Émetteur de test (touches 4 et 5) : `manager.add_appearance(EnemyBulletLook.texture())` (avec le sans-doublon, `_appearance_manager_id` peut rester ou disparaître : au choix, comportement identique) ; `_params.radius = Tuning.COMBAT.enemy_bullet_radius` ; retirer `EMITTER_BULLET_RADIUS`, `EMITTER_BULLET_SIZE`, `EMITTER_BULLET_COLOR` et `_make_texture()`. Vitesse, durée de vie, salve de 3 à 15° et cadence restent des valeurs de debug.
- Texte : `7 spawn night light`, `8 spawn lullaby` ; `F1 panel (keys 1-8)`. Agrandir le `Label` si le texte déborde (optionnel).
- La 2.6 remplacera 6, 7, 8 par « ennemi choisi ».

### Règles d'architecture qui s'appliquent

- GDScript typé partout ; `snake_case` pour fichiers et dossiers, un script par classe, racine en `PascalCase` (`night_light.tscn` → `NightLight`, `lullaby.tscn` → `Lullaby`) ; `Def` pour le contenu ; gestionnaires `_on_<émetteur>_<signal>`. Code, commentaires, logs, noms de fichiers **en anglais**.
- **États et télégraphes** : enum + `match`, un `_process_<état>()` par état, `_state` écrit **seulement** dans `_enter()` ; toute attaque passe par `Telegraph` (ici par `_start_telegraph()`, qui appelle `telegraph.start()`).
- **Temps** (AR13) : `GameClock.Group.ENEMIES` pour les tireuses, leur cycle, leur télégraphe ; `ENEMY_BULLETS` pour leurs projectiles (le manager) ; pas de `Timer`.
- **Données** (AR9, NFR9) : les valeurs du GDD vivent dans `night_light.tres`, `lullaby.tres` et `combat_tuning.tres` ; `Def` et `Tuning` jamais modifiés à l'exécution (un `BulletParams` neuf par tireuse) ; aucun nombre du GDD en dur (40, 20, 2, 0.6, 5, 30, 4, 8, 1.5, 0.5, 6, 3, 1) dans les scripts ; angles en degrés dans la Resource, radians dans le code.
- **Création d'entités** : projectiles par `BulletManager.fire()` uniquement (jamais d'instanciation de scène) ; ennemis par `room.spawn_enemy()` ; `setup()` avant `add_child()`.
- **Frontières** : `combat/` ne dépend ni de `player/` ni de `enemies/` (`EnemyBulletLook` lit `Const` et `Tuning`) ; `enemies/` dépend de `combat/` et `core/`, pas de `player/` ni de `rooms/` (le manager arrive par `setup()`) ; rien ne dépend de `debug/`.
- **Logs** (AR27) : `Log.debug` pour le départ d'un télégraphe (déjà dans `Telegraph`) et pour chaque salve (une ligne par salve, jamais par tick, hors de tout `_physics_process`) ; aucun `INFO` nouveau ; aucun log dans `fire()` pour un tir né dans un mur ou un pool plein.
- **Aléatoire** : aucun.

### Arborescence attendue à la fin de la story

```
game/
├── core/
│   ├── combat_tuning.gd                  (UPDATE : enemy_bullet_radius, enemy_bullet_lifetime)
│   └── constants.gd                      (UPDATE : couleurs réservées, Z_INDEX_ENEMY_BULLETS)
├── data/
│   ├── tuning/combat_tuning.tres         (UPDATE)
│   └── enemies/night_light.tres, lullaby.tres (NEW)
├── combat/
│   ├── telegraph.gd                      (UPDATE : progress())
│   └── bullets/
│       ├── bullet_manager.gd             (UPDATE : contrat des dégâts, origine dans un mur, sans doublon)
│       └── enemy_bullet_look.gd          (NEW, + .uid)
├── enemies/
│   ├── enemy.gd                          (UPDATE : setup() à 4 paramètres)
│   ├── shooter_def.gd                    (NEW, + .uid)
│   ├── shooter_enemy.gd                  (NEW, + .uid)
│   ├── night_light/night_light.tscn, night_light.gd (NEW, + .uid)
│   └── lullaby/lullaby.tscn, lullaby.gd, lullaby_def.gd (NEW, + .uid)
├── audio/sfx/sfx_enemy_night_light_telegraph.wav, sfx_enemy_lullaby_telegraph.wav (NEW, + .import)
├── rooms/arena/arena.gd                  (UPDATE : _enemy_bullets, z_index, setup())
└── debug/
    ├── debug_panel.gd                    (UPDATE : touches 7 et 8, apparence réservée)
    └── bullet_load_test.gd               (UPDATE : dégâts, apparence réservée)
```

Mettre à jour aussi `_bmad-output/game-architecture.md` (T1) et `deferred-work.md` (T13). Ne pas toucher à `health.gd`, `hurtbox.gd`, `hitbox.gd`, `hit_points.gd`, `damage_info.gd`, `bullet_params.gd`, `enemy_def.gd`, `sleepwalker/`, `player/`, `run.gd`, `main.gd`, `damage_numbers.gd`, aux autoloads, aux menus.

### Stratégie de test

Aucun framework (AR26 : avant le jalon B). Nouvelles scènes jetables dans `game/.scratch/` (créées par `mk_tscn.sh`, harnais `th.gd`, qu'on peut **étendre** sans casser les scènes de 2.3 : par exemple des constantes `NIGHT_LIGHT_DEF`, `LULLABY_DEF` et une aide `enemy_bullets()`), ajoutées à `SCENES` dans `run_all.sh`. Joueur figé par `player.set_physics_process(false)` ; position des projectiles lue dans les tableaux du manager (`_positions`, `_velocities`, `_flags`, scripts jetables avec `@warning_ignore_start`). **Chaque point dit ce qu'il isole et donne son témoin ; mutations au point 14.** Scènes proposées : `t_enemy_bullets` (manager, apparence, ordre de dessin), `t_shooters` (comportement, `run.tscn` seul), `t_shooters_main` (`main.tscn`), `t_invalid24` (chemins d'erreur).

1. **Import et lancement** : `--import` puis `--quit-after 120` : zéro `SCRIPT ERROR`, zéro `Parse Error`, aucun avertissement nouveau ; `.wav` et `.tres` importés ; `night_light.tres` et `lullaby.tres` relus après import : toutes les valeurs non nulles explicites (témoin : un champ égal au défaut est omis, comme en 2.3) ; `project.godot` inchangé.
2. **`BulletManager`** (`t_enemy_bullets`, manager de test sous la scène, couche de murs de test) — CA 5, 6, 7 :
   - **sans doublon** : `add_appearance(T)` deux fois → même index, **un seul** `MultiMeshInstance2D` enfant ; **témoin** : deux textures différentes → deux index, deux enfants ;
   - **contrat des dégâts** : camp ennemi, `damage` 1 → `true` ; 0,49 → refusé (assertion annoncée, `active_count` inchangé) ; 0,5 → accepté (`roundi(0.5)` = 1, même règle que `Health`) ; camp joueur, 10 → `true`, 0 → refusé, 0,01 → accepté ; NaN → refusé dans les deux camps (les refus vont dans `t_invalid24`, pour le compte des assertions) ;
   - **origine dans un mur** : origine au centre d'une cellule de mur → `false`, `active_count` et `refused_count` inchangés, aucun message ; origine dans le mur à 1 px du bord, direction vers l'extérieur → `false` (avant la story, ce tir vivait : **témoin par mutation**) ; **témoin** : origine à 1 px **hors** de la cellule, direction vers le mur → `true`, puis libéré par le mur au tick suivant ;
   - **pool plein** inchangé : `refused_count` + 1, `false`.
3. **Apparence réservée et ordre de dessin** (`t_enemy_bullets` puis `run.tscn`) — CA 1, 5 :
   - `EnemyBulletLook.texture()` : même objet à chaque appel ; taille = 2 × rayon en pixels (8×8) ; pixels centraux = `COLOR_ENEMY_BULLET`, pixels du bord du disque sur les axes = `COLOR_ENEMY_BULLET_OUTLINE`, coins transparents ; **témoin** : aucun pixel d'une autre couleur que ces deux-là et le transparent ;
   - **couleurs réservées** : charger tous les scripts `.gd` du jeu (`res://` hors `.scratch`, parcours `DirAccess`), lire `get_script_constant_map()`, et pour toute constante `Color` hors `Const.COLOR_ENEMY_BULLET*` : distance RGB ≥ 0,2 aux deux couleurs réservées ; ajouter à la liste le blanc (`Color.WHITE`, flash et réticule) ; **témoin** : un `GDScript` créé par le test (`source_code` avec une constante égale à `COLOR_ENEMY_BULLET`, `reload()`) est détecté ; et les anciennes constantes roses de F1 et F5 n'existent plus ;
   - **une apparence** : `run.tscn`, 2 Veilleuses + 2 Berceuses + une salve F1 (appel direct de la méthode publique de tir du panneau, ou touche 4 par `main.tscn` au point 12) → `EnemyBullets` a exactement **un** `MultiMeshInstance2D` ;
   - **au-dessus du monde** : `EnemyBullets.z_index == Const.Z_INDEX_ENEMY_BULLETS` ; z final (somme des `z_index` relatifs) de tout `CanvasItem` du `Run` hors `EnemyBullets` et ses enfants et hors `Reticle` : strictement inférieur à celui d'`EnemyBullets` (joueur, ennemis, cibles, `PlayerBullets`, `DamageNumbers` compris) ; `Reticle` au-dessus (100) ; **témoin** : sans le `z_index` (mutation), `DamageNumbers` (ajouté après) passe au-dessus.
4. **`Telegraph.progress()`** (`t_enemy_bullets` ou `t_shooters`) : `start(0.6, son)` → progression croissante, ≈ 0,5 (± 1/36) à mi-course, 0 une fois inactif ; **témoin** : sans `start()`, 0.
5. **La Veilleuse** (`t_shooters`, `run.tscn` seul, joueur figé en (304, 168), Veilleuse demandée à 6 tuiles) — CA 2, 4 :
   - **cycle** : premier départ de télégraphe au 120e tick après l'apparition (relever le tick T0, attendu 120 ± 1 ; affirmer ≥ 120 − 1 et aucune salve avant) ; départs suivants exactement tous les 120 ticks (3 cycles) ; **témoin** : un `ShooterDef` dupliqué par le test avec `fire_interval` 1,0 → 60 ticks (la valeur vient de la `Def`), le `.tres` partagé intact ;
   - **lueur** : texture de lueur dès le tick du départ, `Audio.voices_of(NightLight.TELEGRAPH_SOUND) == 1`, textures qui changent au fil de la lueur (au moins `GLOW_STEPS` textures distinctes vues, dans l'ordre), aucun projectile pendant 36 ticks ; **salve au tick N + 36** (attendu ; affirmer ≥ N + 36 : au moins 0,6 s) ; texture de repos ensuite ;
   - **éventail** : `active_count` + 3 au tick de la salve ; les trois vitesses de norme 80 px/s (± 0,01) ; la vitesse centrale colinéaire à (joueur − Veilleuse) (produit scalaire normé ≥ 0,9999) ; angles entre voisins 20° (± 0,01°), symétriques ; **visée au tick du tir** : joueur téléporté par le test pendant la lueur → l'éventail vise la nouvelle position ; **témoin** : téléporté **après** la salve → l'éventail garde l'ancienne direction ;
   - **immobile** : position identique (au bit près) après 600 ticks, dont 120 où le joueur (actif, entrée simulée) la pousse ; pendant la poussée, le joueur reste bloqué au contact (centres à ≈ 8 px : la poussée est réelle) ; Veilleuse placée à 12 tuiles du joueur figé : position stable 600 ticks ; **témoin** : une Berceuse (autre `ShooterEnemy`) placée au même endroit se déplace (le contrôle de position sait échouer pour une tireuse qui bouge) ;
   - **coup** : salve sur le joueur vulnérable → un seul `player_hit(1, ENEMY_BULLET)` (un coup par tick puis l'invulnérabilité), le projectile qui touche est détruit, les autres continuent jusqu'au mur ; joueur invulnérable (F1) → aucun coup, les projectiles traversent ; **témoin** : joueur vulnérable sur la trajectoire → coup.
6. **La Berceuse** (`t_shooters`, joueur figé) — CA 3, 4 :
   - **approche** : à 12 tuiles → se rapproche en ligne directe (déplacement colinéaire au joueur, 32 px/s ± 0,01, soit 16 px en 30 ticks), s'arrête au premier tick où la distance ≤ 128 px, puis ne bouge plus (hors télégraphe : position stable 30 ticks) ; **témoin** : un `LullabyDef` dupliqué avec `move_speed` 4,0 → 32 px en 30 ticks ;
   - **recul** : joueur téléporté à 2,5 tuiles → s'éloigne en ligne droite à l'opposé jusqu'à ≥ 64 px, puis s'arrête ; **témoin** : à 6 tuiles (dans la bande) → ne bouge pas ;
   - **bornes** : à 128,0 px et 64,0 px exactement → ne bouge pas ; à 128,5 → s'approche ; à 63,5 → recule ;
   - **contre un mur** : reculer vers un mur → glisse le long, ne traverse pas, reste dans la zone jouable ;
   - **cycle** : premier télégraphe au 90e tick, puis tous les 90 ticks ; **immobile pendant l'inspiration** (position inchangée de N à N + 30, même hors bande : joueur téléporté à 12 tuiles juste avant) ; texture d'inspiration, son (`voices_of == 1`) ; **tir au tick N + 30** (≥ N + 30), un projectile, 96 px/s, visé au centre du joueur (produit scalaire ≥ 0,9999) ; elle reprend son déplacement après ;
   - **tir hors bande** : à 12 tuiles, elle tire quand même au terme du cycle.
7. **Communs aux deux tireuses** (`t_shooters`) — CA 9, 10 :
   - **tirs du joueur** : 40 PV → 4 tirs (Veilleuse), 30 → 3 (Berceuse), `enemy_damaged` 10 par tir, flash et recul ; mort → désactivée, libérée, compte de la salle à 0 ;
   - **morte pendant sa lueur ne tire pas** : tuée au tick N + 10 de son télégraphe → aucune salve à N + 36 ni après (`active_count` constant) ; **témoin** : vivante → salve ; **ses projectiles survivent** : tuée juste après une salve → les 3 projectiles continuent (positions qui avancent, puis libérés par le mur) ;
   - **contact** : joueur vulnérable collé à une tireuse → coup `CONTACT` (chemin de 2.3 inchangé) ; dash vers une Veilleuse → arrêté par son corps ;
   - **sans cible** : cible libérée (test) → aucun tir, aucune erreur ;
   - **F4** (`global_multiplier = 0.25`) : cycle 480 ticks (Veilleuse), lueur 144 ticks, projectiles à 1/3 px par tick, Berceuse à 0,133 px par tick ;
   - **apparition** : deux Veilleuses demandées au même point → corps disjoints (règle de 2.3) ; à 1 tuile du joueur → remplacée à ≥ 48 px ;
   - **structure** (`run_all.sh`) : `state_machine` sur `night_light.gd` et `lullaby.gd` (`_state` écrit une fois, dans `_enter()`, un `_process_<état>()` par état) ; **témoins** plantés comme en 2.3.
8. **Le Somnambule inchangé** : les scènes `t_sleepwalker`, `t_enemy_parts`, `t_enemy_main` passent telles quelles (il reçoit le manager sans s'en servir : aucune apparence ajoutée par un Somnambule, `EnemyBullets` sans enfant après l'apparition de 3 Somnambules).
9. **Partie complète** (`t_shooters_main`, `main.tscn`) — CA 10, 11, 12 :
   - F1 + touche 7 → une Veilleuse, + touche 8 → une Berceuse, `alive_enemy_count() == 2`, texte du panneau (`7 spawn night light`, `8 spawn lullaby`), à ≥ 48 px du joueur ; F5 puis 7 → « no room » ; F5 retour → 8 marche sur la nouvelle arène ;
   - **pause** pendant une lueur avec 3 projectiles en vol : positions des projectiles, position de la Berceuse, ticks restants du télégraphe et du cycle figés 60 ticks ; reprise : salve au même nombre de ticks hors pause que sans pause (point 5) ; **écran de réveil** : même chose ;
   - **relance** : mort avec 2 tireuses vivantes et des projectiles en vol → relance → aucune `NightLight` / `Lullaby` dans l'arbre, nouvel `EnemyBullets` à `active_count` 0 et à un seul `MultiMeshInstance2D` au plus ; cinq cycles (2 tireuses par partie, projectiles en vol à chaque mort) : `OBJECT_NODE_COUNT` identique après le 1er et le 5e cycle, `OBJECT_ORPHAN_NODE_COUNT` à 0, connexions de `Events.enemy_damaged` et `Events.run_ended` stables ;
   - **mort par projectile** : joueur à ½ cœur touché par une salve → mort, `Events.run_ended` une fois, `player_hit` de source `ENEMY_BULLET` juste avant.
10. **Test de charge** (`t_regress`, inchangé, + un contrôle dans une nouvelle scène si besoin) : F5 → `Bullets 400 | refused 0`, zéro `SCRIPT ERROR` ; l'apparence du test de charge est `EnemyBulletLook.texture()`.
11. **Émetteur F1** : touche 4 → 3 projectiles à l'apparence réservée, dégâts `hit_damage_half_hearts`, rayon `enemy_bullet_radius` ; touche 4 répétée et 5 → toujours un seul `MultiMeshInstance2D` dans `EnemyBullets`.
12. **Chemins d'erreur** (`t_invalid24`, comptés par `run_all.sh` comme `t_invalid23` : généraliser le test du nom à `t_invalid*`) : `fire()` à dégâts 0 / 0,49 / NaN (camp ennemi), 0 / −1 (camp joueur) → `false`, `active_count` inchangé ; tireuse sans `BulletManager` (scène `night_light.tscn` instanciée par le test, `setup()` à 3 paramètres, ajoutée sous la scène de test : l'arène, elle, en passe toujours un) → désactivée, aucun tir ; scène `night_light.tscn` avec un `EnemyDef` qui n'est pas un `ShooterDef` → désactivée ; scène `lullaby.tscn` avec un `ShooterDef` → désactivée ; `ShooterDef` dupliqué avec `fire_interval` NaN, `bullet_speed` 0, `bullet_count` −1, `spread_angle` INF → valeurs bornées, aucun tir pour la vitesse 0, aucune erreur par tick ; `LullabyDef` avec `min_distance` ≥ `max_distance` → bornée ; `Def` oubliée (défauts neutres) → messages annoncés, aucune valeur héritée d'un autre ennemi ; nombre exact de messages d'assertion annoncé cas par cas (`CASE … EXPECT_ASSERTS n`, `TOTAL_EXPECTED_ASSERTS`), aucun autre `SCRIPT ERROR`.
13. **Journaux** (`run_all.sh`) : une ligne `[DEBUG] [combat] <id> fired n/m` par salve (compte de salves échantillonné par la scène, comme `TELEGRAPH_COUNT` en 2.3), une ligne `telegraph … started` par départ, aucune ligne `INFO` nouvelle en `combat` / `room`, aucun `Log.` dans un `_physics_process`.
14. **Contrôles par mutation** (mécanisme retiré, scène relancée, restauration octet pour octet, consignés dans le Debug Log) : sans le sans-doublon → point 3 « une apparence » échoue ; sans le contrat des dégâts → points 2 et 12 échouent ; sans le test d'origine dans un mur → point 2 échoue ; sans `z_index` sur `EnemyBullets` → point 3 échoue ; contour retiré de la texture → point 3 échoue ; cycle remis à zéro à la salve au lieu du départ du télégraphe → période de 156 ticks, point 5 échoue ; télégraphe sauté (salve dans `_enter(TELEGRAPH)`) → points 5 et 6 échouent ; éventail non centré (`i * spread`) → point 5 échoue ; visée figée au départ du télégraphe → point 5 échoue ; Berceuse qui bouge pendant l'inspiration → point 6 échoue ; bande retirée (toujours s'approcher) → point 6 (recul) échoue ; mort sans désactivation (`_die()` sans `PROCESS_MODE_DISABLED`) → point 7 (« morte pendant sa lueur ») échoue.
15. **Régression et interdits** : `run_all.sh` complet (scènes de 2.3 et nouvelles), toutes `PASS` ; recherche des interdits (inchangée) ; **nombres du GDD** : règle existante inchangée, plus une règle 2.4 avec témoin planté : aucun `40`, `20`, `1.5`, `6.0`, `4.0`, `8.0` dans `enemies/`, aucun `40`, `20`, `1.5`, `6.0` dans `combat/` (hors commentaires ; `8.0` est la durée de vie par défaut de `BulletParams`, sans rapport ; `2.0` et `0.5` ne sont pas cherchés : moitiés et centres de pixel légitimes) ; aucun `Log.` dans un `_physics_process`.
16. **Fenêtré sous WSLg** (indicatif, captures `get_viewport().get_texture().get_image().save_png()`) : lueur qui monte (3 captures), Berceuse qui inspire, éventail, projectile dessiné **au-dessus** d'un ennemi, du joueur et d'un chiffre de dégâts (réglage activé), projectile ennemi à côté d'un tir du joueur (plus visible), F2 (corps, hurtbox, zone de contact des tireuses). Ce qui n'est pas capturé est marqué **NON VÉRIFIÉ à l'écran** dans le Debug Log et `deferred-work.md` (leçon de la revue 2.3).
17. **Étapes humaines** (à consigner `NON ÉVALUÉ` dans la story et `deferred-work.md`, ne pas déclarer vérifiées) : lisibilité des couleurs réservées et de la taille des projectiles (8 px) en plein combat ; lisibilité de la lueur et de l'inspiration provisoires, sons à l'oreille ; difficulté de l'éventail (20°, 5 tuiles/s, à 3 tuiles du joueur au pire) ; vitesse provisoire de la Berceuse (2 tuiles/s) et son comportement dans les coins ; immobilité pendant l'inspiration ; absence de son de tir.

### Commit

Directement sur `main`, Conventional Commits en anglais, `git push` après chaque commit (consigne du projet), ligne `Co-Authored-By` du modèle réellement utilisé. Commiter par tâche cohérente, chaque commit laissant le jeu lançable. Exemples : `docs(architecture): add shooter and enemy bullet terms to the lexicon` ; `feat(combat): give enemy bullets a reserved look and refuse unhittable shots` ; `feat(enemies): add the shooter base, the night-light and the lullaby` ; `feat(rooms): give the enemy bullet manager to spawned enemies` ; `feat(debug): spawn the night-light and the lullaby from the f1 panel` ; `docs(story): record story 2.4 implementation progress`.

### Project Structure Notes

- Conforme à l'arborescence de l'architecture : `enemies/night_light/`, `enemies/lullaby/`, `data/enemies/night_light.tres`, `lullaby.tres`, sons `sfx_enemy_<nom>_telegraph.wav`.
- **Écarts assumés** :
  - `enemies/shooter_enemy.gd` et `enemies/shooter_def.gd` (couche commune des tireuses) ne sont pas dans l'arborescence : ajoutés en T1.
  - `combat/bullets/enemy_bullet_look.gd` au lieu de `bullet_sprites/` : une texture générée en code jusqu'à la 7.2 ; ajouté en T1.
  - `night_light.tres` est un `ShooterDef` sans sous-classe propre (la Veilleuse n'a aucune valeur en plus) ; `lullaby.tres` un `LullabyDef`.
  - `bullet_pattern.gd` (arborescence) n'est pas créé : l'éventail centré suffit aux deux tireuses ; les patterns en Resource arrivent avec le Professeur (6.1).

### Project Context Rules

Il n'y a pas de `project-context.md`. Règles tirées de `CLAUDE.md`, de la mémoire du projet et du brief du pipeline :

- Conversation, documents de conception et artefacts BMAD : **français**. Code (identifiants, commentaires, noms de fichiers, messages de log) : **anglais**.
- Commits en anglais, Conventional Commits (`type(scope): description`, impératif, minuscules, sans point final), **directement sur `main`, sans branche**, avec un push vers `origin/main` aussitôt après chaque commit, et la ligne `Co-Authored-By` en fin de message.
- Textes affichés au joueur : fichiers de localisation, jamais en dur (aucun dans cette story ; le panneau F1 est du debug, exempté).
- Prototype rapide, itérations courtes : ne poser que ce que cette story exige.
- Pipeline automatisé de l'epic 2 : Kroustille n'est pas disponible avant la fin de l'epic ; toute question se tranche et se consigne ci-dessous.
- `game/.scratch` : vrai dossier exclu de git, jamais commité, jamais remplacé par un lien ; les scènes existantes ne se réécrivent pas.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Le manager ennemi arrive par `Enemy.setup(…, bullets = null)`**, passé par `spawn_enemy()` à tout ennemi — Question : `setup()` étendu ou `setup_shooter()` propre aux tireuses (report de 2.3) ? Choix : 4e paramètre optionnel. Raison : un seul chemin d'injection, avant `add_child()` ; la salle n'a pas à connaître le type d'ennemi ; le Somnambule et les scènes de test de 2.3 ne changent pas.
2. **Couche commune `ShooterDef` + `ShooterEnemy`**, sans toucher à la base `Enemy` au-delà de `setup()` — Raison : le cycle, le télégraphe et la salve sont communs aux deux tireuses et à elles seules ; le Somnambule et le Mouton n'en portent rien ; la machine à états reste dans chaque ennemi (AR7). `night_light.tres` est un `ShooterDef` (aucune valeur propre).
3. **Une salve toutes les `fire_interval`, le cycle repart au départ du télégraphe** ; première lueur un cycle complet après l'apparition — Question : la lueur s'ajoute-t-elle au cycle (2,6 s) ou s'y inscrit-elle (2 s) ? Choix : elle s'y inscrit. Raison : FR28 et le GDD disent « toutes les 2 s, elle tire » ; le CA (« quand son cycle de 2 s arrive à son terme, une lueur monte, puis elle tire ») reste vrai, la lueur démarrant au terme du cycle ; le premier cycle complet laisse un répit après l'apparition. Même règle pour la Berceuse (1,5 s, inspiration 0,5 s).
4. **Visée au tick du tir**, au centre du joueur ; éventail centré, 20° **entre deux projectiles voisins** (40° d'un bord à l'autre) — Raison : lecture littérale de « écartés de 20° » et « centré sur le joueur » ; viser au départ de la lueur rendrait la lueur inutile pour se placer. À 6 tuiles, deux projectiles voisins sont à ≈ 2 tuiles l'un de l'autre : on passe entre. NON ÉVALUÉ.
5. **La Berceuse est immobile pendant l'inspiration** — Raison : cohérent avec le Somnambule (décision 5 de 2.3) : une attaque annoncée l'est par un ennemi qui se fige ; le GDD « inspire » est une pause.
6. **Vitesse de la Berceuse : 2 tuiles/s** (`move_speed` dans `LullabyDef`) — Raison : le GDD ne la donne pas ; plus lente que le joueur (6) pour qu'on puisse la rattraper, plus lente que le Somnambule (2,5) : c'est une tireuse, pas une poursuivante. NON ÉVALUÉE.
7. **Bande de 4 à 8 tuiles, bornes comprises, ligne directe** ; recul à l'opposé du joueur, glissement contre les murs, coincée dans un coin — Raison : AR23 (direct au jalon A) ; le contournement viendra avec `AStarGrid2D` (4.5).
8. **Les tireuses tirent quelle que soit la distance**, sans ligne de vue — Raison : le GDD ne lie pas le tir à la distance ; aucun obstacle avant l'epic 4.
9. **Contact : ½ cœur pour les deux tireuses**, corps de la Veilleuse qui bloque — Raison : GDD « Santé et armure » (« les ennemis infligent aussi des dégâts au contact ») ; la base de 2.3 le fait déjà.
10. **Une seule apparence réservée pour tous les projectiles ennemis**, F1 et F5 compris, et `add_appearance()` sans doublon — Raison : NFR8 (« identiques à toutes les phases ») : une texture unique rend la règle vraie par construction ; sans le sans-doublon, chaque tireuse ajouterait un `MultiMeshInstance2D` et la limite de 256 tomberait au fil des vagues (2.6).
11. **Couleurs réservées provisoires dans `Const`** (rose vif, contour lie-de-vin) et contrôle de distance ≥ 0,2 à toute autre couleur du code — Raison : `COLOR_PLAYER_SHOT` est déjà dans `Const` ; valeurs définitives en 7.2 ; le contrôle rend « réservé » vérifiable. NON ÉVALUÉ à l'œil.
12. **Rayon (0,25 tuile) et durée de vie (10 s) des projectiles ennemis dans `CombatTuning`**, communs à toutes les tireuses — Raison : le GDD ne les donne pas ; une apparence unique impose une taille unique ; ce qu'on voit (disque de 8 px) est ce qui touche ; mêmes valeurs que l'émetteur de test de 2.1.
13. **Projectiles ennemis en `z_index` 10**, au-dessus de tout le monde, chiffres de dégâts et tirs du joueur compris, sous le réticule — Raison : AR19 et le CA 1 (« au-dessus de tout le reste du monde ») ; un `z_index` ne dépend plus de l'ordre de l'arbre (salles de l'epic 4) ; le réticule est une aide de visée qui part dans le HUD (2.7).
14. **Contrat des dégâts tenu par `fire()`, par camp, avec `Log.error` + `assert`** (camp ennemi `roundi(damage) < 1`, camp joueur `damage <= 0`) — Question : refus dans `fire()` ou valeur nulle refusée sans assert à la livraison (reports 2.1 et 2.3) ? Choix : refus dans `fire()`. Raison : une donnée invalide est refusée à la source (AR28), une fois par tir et non à chaque coup ; aucun projectile ne consomme plus le coup du tick pour rien. Conséquence : le test de charge F5 tire avec `hit_damage_half_hearts` (sans cible, sans effet).
15. **Origine dans une cellule solide : tir refusé sans log ni compte** — Raison : report de 1.2 ; c'est une situation de jeu (tireuse collée à un mur), pas une erreur ; `refused_count` reste le compte du pool plein lu par F3.
16. **Les projectiles survivent à leur tireuse**, et disparaissent avec la salle à la relance — Raison : ils appartiennent au manager de la salle ; un tir annoncé et parti reste à esquiver (lisibilité) ; rien à libérer en plus.
17. **Pas de son de tir pour les ennemis**, seulement le son du télégraphe — Raison : le GDD n'exige que le son du télégraphe ; un son par projectile encombrerait le mix ; 7.7.
18. **`Telegraph.progress()`** pour animer la lueur qui monte (3 textures) — Raison : « une lueur qui monte » demande une animation progressive ; l'animation reste un changement de `texture` (contrat de 2.3) ; la Berceuse peut s'en passer (deux textures).
19. **Tailles provisoires des deux tireuses = celles du Somnambule** — Raison : le GDD ne les donne pas ; une seule chose à juger au jeu.
20. **F1 : touches 7 (Veilleuse) et 8 (Berceuse)** ; l'arène reste vide au lancement — Raison : décision 25 de 2.3 ; les vagues sont la 2.6.
21. **Une ligne `Log.debug` par salve** — Raison : AR27 (« télégraphe » et « tirage » en DEBUG) ; une salve au plus toutes les 1,5 s, jamais par tick.
22. **Les décisions de 2.1 à 2.3 restent valables** (filtre de hurtbox, un coup par tick sur le joueur, ordre entités / `Hitbox` / managers, défauts neutres des `Def`, `_assert_failed()`, apparition déterministe, mort par `PROCESS_MODE_DISABLED`).

### Questions ouvertes

Aucune bloquante. Points à faire valider par Kroustille en fin d'epic : les décisions ci-dessus, en priorité 3 (période), 4 (visée et écart), 6 (vitesse de la Berceuse), 11 (couleurs) et 12 (taille des projectiles), à juger au jeu.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.4 : Affronter La Veilleuse et La Berceuse]
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences fonctionnelles] (FR26, FR28, FR30), [#Exigences non fonctionnelles] (NFR8, NFR9, NFR11 : couleurs réservées aux projectiles hors palette) et [#Exigences supplémentaires (architecture)] (AR6, AR7, AR9, AR13, AR19, AR23, AR24, AR27, AR28, AR32)
- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.5], [#Story 2.6] (Mouton, vagues : contexte, non implémentés ici)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Ennemis et IA] (tableau : Veilleuse tourelle, 40 PV, immobile, éventail de 3 à 20°, toutes les 2 s, 5 tuiles/s, lueur 0,6 s ; Berceuse tireuse mobile, 30 PV, 4 à 8 tuiles, 1 projectile visé toutes les 1,5 s, 6 tuiles/s, inspire 0,5 s ; règle de télégraphe ; couleur et contour exclusifs)
- [Source: gdd.md#Style visuel] (lisibilité : projectiles ennemis au premier plan, couleur et contour exclusifs, tirs du joueur plus discrets), [#Santé et armure] (dégâts au contact), [#Arènes et salles] (distances d'engagement des tireurs : 4 à 10 tuiles), [#Son et musique] (un son par télégraphe), [#Assets] (couleurs réservées aux projectiles hors des 32 couleurs)
- [Source: _bmad-output/game-architecture.md#Projectiles (D1)], [#Rendu (D13)], [#Création d'entités] (`BulletManager.fire()`, `setup()` avant `add_child()`), [#États et télégraphes], [#Dégâts et unités] (angles en degrés dans les Resources), [#Accès aux données], [#Temps (D7)], [#Logs], [#Frontières architecturales], [#Arborescence] (`enemies/night_light/`, `enemies/lullaby/`), [#Lexique] (`NightLight`, `Lullaby`)
- [Source: _bmad-output/implementation-artifacts/2-3-affronter-le-somnambule.md] (base des ennemis, ordre des ticks du télégraphe, décisions 1 à 34, revue, stratégie de test)
- [Source: _bmad-output/implementation-artifacts/2-1-encaisser-des-coups.md] (chemin d'un coup de projectile ennemi, émetteur de test, `one_hit_per_tick`)
- [Source: _bmad-output/implementation-artifacts/1-2-valider-400-projectiles-a-60-fps.md] (test de charge, `refused_count`)
- [Source: _bmad-output/implementation-artifacts/deferred-work.md] (reports listés dans « Reports traités par cette story »)
- Documentation Godot 4.7 consultée par Context7 à la création : `CanvasItem.z_index` (plage `CANVAS_ITEM_Z_MIN..MAX`) et `z_as_relative` (z final = somme avec le parent, vrai par défaut : les enfants du manager héritent du décalage) ; variables `static var` de GDScript (depuis 4.1, persistantes tant que le script est chargé ; `@static_unload` non utilisé). Rappels vérifiés dans le code du dépôt : `Health.apply_damage()` refuse `roundi(amount) < 1` ; `Telegraph` vu inactif par son propriétaire au tick N + durée × 60 ; un `CharacterBody2D` ne bouge que par son propre `move_and_slide()`.

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

- Analyse de contexte terminée : guide d'implémentation complet créé (create-story, 2026-11-22).

### File List

### Change Log

- 2026-11-22 : story 2.4 créée (`ready-for-dev`).

# Story 6.1 : Affronter Le Professeur : la Dictée

Status: ready-for-dev

## Story

En tant que joueur,
je veux affronter Le Professeur au bout de l'étage, en commençant par la Dictée,
afin d'avoir un vrai boss à battre.

Exigences : FR60 (Dictée, PV, annonce), AR7 (patterns en Resources) (epics.md, Story 6.1). Architecture : D2 (machine à états par entité), D4 (Resources `.tres`), P1 (`DangerProfile`), P4 (temps par groupe), dossier `bosses/` (`boss.gd`, `boss_def.gd`, `boss_attack.gd`, `professor/`).

**Dépend de :** 4.7/4.8 (salle `NIGHTMARE` placée au bout de l'étage), 2.3 (`Enemy`, `HitPoints`, `Telegraph`), 3.6 (`DangerProfile`), 5.10 (patron `Room.spawn_enemy(..., prepare)` et flux nommé). **Pose le cadre des stories 6.2 (autres épreuves), 6.3 (Interro surprise) et 6.4 (mort et victoire)** : leur code s'ajoute à ce qui est créé ici, sans le réécrire.

Hors périmètre : Calcul mental, Examen final, règle, attaque lourde (6.2) ; Interro surprise (6.3) ; mort du boss, Éclats, victoire (6.4) ; sprites et audio réels (epic 7).

## Critères d'acceptation

1. **Salle du cauchemar** : `rooms/pool/onset/onset_boss_001.tscn` (déjà `room_type = NIGHTMARE`, contenu provisoire de 4 types d'ennemis) est refaite : un écran (36×19), sans obstacle haut ni trou (les craies le traversent de part en part), une porte, un seul marqueur `EnemySpawn` au centre (vague 1) portant `data/bosses/professor.tres`. Elle passe `validate_rooms.sh` et les tests de pool/étage existants (le cauchemar reste une impasse à ≥ 4 salles du départ).
2. **`professor.tres`** (`BossDef`, hérite d'`EnemyDef`) : 2 500 PV, corps 2×2 tuiles, zone de coups 2,5×2,5, contact 2,25×2,25 (> corps + 0,125, voir deferred « zones de contact »), scène `bosses/professor/professor.tscn`, liste de phases (`BossPhase`) dont seule la Dictée est remplie ici. Aucune valeur de combat en dur dans les scripts.
3. **Barre de vie** : tant que le boss vit, une barre s'affiche en bas de l'écran (nom « Le Professeur » depuis `strings.csv`, remplissage = PV / PV max), mise à jour à chaque coup via `Events.boss_health_changed`. Elle disparaît avec lui (6.4) ou quand la run est détruite.
4. **Aucun renfort** : en Abandon total comme en Abandon, la salle n'appelle aucun renfort d'Abandon et le Miroir n'y fait pas apparaître de reflet (déjà garanti par `Room.is_nightmare()` ; verrouillé par un test).
5. **Annonce à la craie** : au début du combat (le boss vient d'apparaître), `Events.boss_announced(boss_id, &"BOSS_PROFESSOR_PHASE_1")` fait écrire « Dictée » au tableau (texte en haut de la salle, lettre par lettre, clé de localisation). Le boss n'attaque pas avant la fin de l'annonce (`BossDef.announce_duration`, 1,5 s).
6. **Dictée (100 à 66 % des PV)** : toutes les 2 s, une rangée horizontale de craies apparaît en haut de la salle et descend à 5 tuiles/s, avec **un trou de 5 tuiles** à franchir. Chaque rangée est annoncée par un signe de télégraphe (bande + trou éclairé) d'au moins 0,4 s (`Tuning.COMBAT.min_telegraph`, durée de données 0,5 s). Dégâts : ½ cœur (`hit_damage_half_hearts`), couleur et contour réservés aux projectiles ennemis (`EnemyBulletLook`).
7. **Motif en Resource** : la rangée est une `BossAttack` (`kind = ROW`, `interval`, `telegraph`, `bullet_speed`, `spacing_tiles`, `gap_tiles`, `max_gap_shift_tiles`), `BossAttack.validate()` rejette les valeurs impossibles (non finies, ≤ 0, télégraphe < minimum). La position du trou vient d'un flux dédié `RunRng.BOSS` (par étage) : même seed, mêmes trous ; deux trous consécutifs ne s'écartent jamais de plus de `max_gap_shift_tiles` (10), donc le trou est toujours atteignable à 6 tuiles/s.
8. **Le danger de la salle s'applique** : vitesse des craies × `danger.enemy_bullet_speed_mult`, durée du signe × `danger.telegraph_mult` (plancher 0,4 s), cadence × `danger.pace_mult` et gel complet sous `danger.fire_hold` (Copie d'examen vierge, Nu en public).
9. **Mort du joueur ou fin de run** : plus aucune craie ni rangée en attente n'apparaît.

## Tâches

- [ ] `bosses/boss_def.gd` (`BossDef extends EnemyDef` : `announce_duration`, `phases: Array[BossPhase]`), `boss_phase.gd` (`title_key`, `hp_from` en fraction des PV max, `groups: Array[BossAttackSet]`), `boss_attack_set.gd` (`attacks: Array[BossAttack]`), `boss_attack.gd` (enum `Kind { ROW }`, champs plats, `validate() -> String`). 6.2 et 6.3 ajoutent des valeurs à `Kind` **à la fin** et des champs, jamais de renumérotation (valeurs explicites, elles sont sérialisées dans des `.tres`).
- [ ] `bosses/chalk_patterns.gd` : classe statique pure (`row(...) -> Array[Vector2]` positions des craies d'une rangée, trou exclu ; `next_gap(...)`), sans nœud ni horloge, testable.
- [ ] `bosses/runners/attack_runner.gd` (base `RefCounted` : `setup(boss, attack)`, `tick(step)`, `stop()`, fabrique statique `make(attack)` qui renvoie `null` + `Log.error` pour un `Kind` inconnu) et `row_runner.gd` (attente de l'intervalle, signe, tir de la rangée).
- [ ] `bosses/attack_sign.gd` : `Node2D` qui dessine la bande et le trou pendant le télégraphe puis se libère ; ajouté sous la salle (`Const.Z_INDEX_COMBAT`).
- [ ] `bosses/boss.gd` (`Boss extends Enemy`) : états `ANNOUNCING`, `FIGHTING` (6.4 ajoute `DEFEATED`), phase courante dérivée de la fraction de PV, `BulletParams` propres validés comme dans `ShooterEnemy` (vitesse < 1 tuile/tick), aide `fire_bullet(origin, direction, speed_tiles)` tirant par le `BulletManager` ennemi de la salle. Immobile ; refuse `dazzle()` et `knock_back()` (surcharges).
- [ ] `enemies/enemy.gd` : deux crochets vides `_on_hit_applied()` (après `hp.apply_damage` et le retour visuel) et `_on_death()` (dans `_die()`, avant `queue_free()`), sans changer le comportement des autres ennemis.
- [ ] `combat/telegraph.gd` : `static func duration_for(base, multiplier) -> float` (le `maxf(base × mult, min_telegraph)` de `start()`, factorisé) pour que les runners, qui n'ont pas de nœud `Telegraph`, appliquent la même règle.
- [ ] `core/run_rng.gd` : `const BOSS: StringName = &"boss"`.
- [ ] `autoloads/events.gd` : `boss_engaged(boss_id, max_hp)`, `boss_health_changed(hp, max_hp)`, `boss_announced(boss_id, text_key)`, `boss_phase_changed(boss_id, phase_index)`.
- [ ] `bosses/professor/professor.tscn` + `professor.gd` (marionnette : placeholder rectangle 2×2 tuiles, `%Sprite`, `%Body`, contrat de scène d'`Enemy`), `data/bosses/professor.tres`.
- [ ] `ui/hud/boss_bar.gd` et `ui/announcements/chalk_title.gd`, ajoutés par `Main._ready()` à `_ui` (comme la carte), entre le HUD et les menus ; clés `BOSS_PROFESSOR_NAME`, `BOSS_PROFESSOR_PHASE_1` (« Dictée ») dans `strings.csv`.
- [ ] Salle `onset_boss_001.tscn` (outil de salles de la 4.2 : régénérer depuis le texte source, voir D4.2-20), puis tests de pool.
- [ ] Débogage F1 : une touche libre (voir `debug_panel.gd`) amène le boss à une fraction de PV (`Boss.debug_set_hp_fraction(f)`), utile aux tests de 6.2.
- [ ] Tests.

## État du code concerné

- `Room.RoomType.NIGHTMARE` existe ; `Room.is_nightmare()` bloque `_maybe_schedule_reinforcement()` et `ReflectionSpawner.is_eligible()`. `Run._roll_loot` ignore déjà tout sauf `COMBAT`. Le combat d'une salle de cauchemar passe par le même chemin que les autres : marqueurs `EnemySpawn` → `Room._make_wave_list()` → `WaveRunner` → `Room.spawn_enemy()` ; la salle s'ouvre quand le boss quitte l'arbre (`emptied`). **Ne pas créer de chemin parallèle** pour le boss.
- `Enemy` crée corps, `HitPoints` (`max_hp × hp_factor`, ici 1), `Hurtbox`, contact `Hitbox`, `Telegraph` en code ; l'attaque de contact est permanente. `Enemy._die()` désactive et libère.
- `EnemyDef.max_hp` borné à 1000 dans l'inspecteur seulement (`or_greater`) : 2 500 passe.
- `DangerProfile` : `boss_extra_pattern` est déjà calculé (utilisé par 6.3) ; `pace_mult` et `fire_hold` sont posés par les objets de la 5.9.
- `BulletManager.fire()` refuse (`false`, sans erreur) une origine dans un mur : une rangée naît à 1,5 tuile du bord haut, pas dans le mur. Capacité 512 : la Dictée seule en demande ~85 (2 rangées × ~42).
- 6.2 ajoute dans `bosses/` : `spiral_runner.gd`, `aimed_runner.gd`, `ruler_runner.gd` et les phases 2 et 3 de `professor.tres` ; 6.3 `ring_runner.gd` ; 6.4 la mort du boss. Les signaux de `Events` ci-dessus sont ceux que toutes lisent.

## Pièges

- Les runners n'ont pas d'horloge propre : le boss leur passe `GameClock.scale(ENEMIES) × danger.pace_mult` chaque tick ; jamais de `Timer` ni `create_timer()` (règle du projet), sinon la pause et le ralenti F4 les désynchronisent.
- Un seul `Telegraph` par `Enemy` : le boss s'en sert pour son annonce ; chaque runner compte son propre télégraphe en ticks (`Telegraph.duration_for`) et dessine son signe. Ne pas partager le nœud entre attaques simultanées (6.2).
- Les `Resource` `.tres` sont partagées : un runner ne modifie jamais sa `BossAttack` (état dans le runner). `Array[BossPhase]` exporté : typer les tableaux, pas de `Array[Array]`.
- La rangée tire 40+ balles en un tick : un refus du pool (`refused_count`) doit rester à 0 ; ne pas tirer d'une origine hors de la salle visible.
- Le trou n'est jamais tiré sans le flux `BOSS` ; **ne pas toucher aux flux `combat` ni `drops`** (le boss ne consomme rien d'eux, la compatibilité des seeds avec les stories 3.7 et 5.10 en dépend).
- `spawn_enemy()` déplace une demande trop proche du joueur (3 tuiles) : le marqueur est au centre, le joueur entre par une porte à 3 tuiles du mur ; vérifier qu'il n'est pas repoussé hors de la salle (`min_spawn_distance`).
- Contact du boss permanent : l'entrée du joueur ne doit pas être à portée (porte à plus de 3 tuiles du bord du boss).

## Tests (GUT)

- `unit/bosses/test_boss_def` : `professor.tres` valide, 2 500 PV, phases triées par `hp_from` décroissant, contact > corps + 0,125, `BossAttack.validate()` refuse les cas limites.
- `unit/bosses/test_chalk_patterns` : une rangée a le bon nombre de craies, aucune dans le trou, espacement < diamètre des balles + 0,25 (pas de passage hors trou), `next_gap` ne dépasse jamais `max_gap_shift_tiles` ni les murs ; mêmes tirages = mêmes trous.
- `integration/bosses/test_professor_room` : la salle se charge, le boss apparaît au centre ; « Dictée » est annoncée avant la première balle ; première rangée à `announce_duration` + télégraphe, puis toutes les 2 s ± 1 tick ; durée du signe ≥ 0,4 s même avec `telegraph_mult` 0,85 ; aucun renfort ni reflet en Abandon total ; sous `fire_hold` rien ne tire ; mort du joueur : plus de tir ; mêmes seed et mêmes trous sur deux salles.
- `unit/ui/test_boss_bar` : la barre suit `boss_health_changed` et se cache sans boss.

## Sources

epics.md (Story 6.1) ; GDD, Ennemis et IA, Le Professeur (2 500 PV, Dictée, 5 tuiles/s), règle de télégraphe ≥ 0,4 s ; architecture (dossier `bosses/`, AR7) ; deferred-work (taille des zones de contact ; salles de cauchemar : `Arena.is_nightmare` n'est qu'un drapeau).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Boss = `Enemy` data-driven, spawné par le marqueur et la vague de la salle** (pas de chemin dédié). Raison : la salle, les portes, `room_cleared` et les tests marchent tels quels. Écart léger à l'architecture (`professor.gd` est une marionnette, la logique est dans `boss.gd`).
2. **Rangée : 5 tuiles de trou, craies espacées de 0,75 tuile (diamètre 0,5), trou déplacé d'au plus 10 tuiles, signe 0,5 s, annonce 1,5 s.** Le GDD ne chiffre que 2 s, 5 tuiles/s, télégraphe ≥ 0,4 s. À régler au playtest.
3. **Flux RNG dédié `boss`** plutôt que `combat`. Raison : `combat` est partagé par le renfort et le Miroir ; ces deux-là n'existent pas en cauchemar, mais un flux nommé garde la règle D8 « un usage, un flux ».
4. **Salle sans obstacle haut, boss au centre, immobile.** Le GDD ne dit rien du déplacement ; une salle ouverte rend les rangées lisibles.
5. **Barre de vie en bas de l'écran, titre en haut de la salle.** NON ÉVALUÉ (lisibilité, placement).
6. **Le boss refuse l'éblouissement et le recul.** Raison : lampe et meubles n'existent pas dans cette salle ; évite une annonce annulée au milieu d'une épreuve.
7. **`Kind` d'attaque en champs plats dans une seule Resource** (pas une classe par motif). Raison : lisible dans l'inspecteur, validation en un endroit.

## Dev Agent Record

### Notes de complétion

### Liste des fichiers

### Journal des modifications

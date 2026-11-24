# Story 6.2 : Affronter Le Professeur : Calcul mental et Examen final

Status: review

## Story

En tant que joueur,
je veux que le combat se durcisse en trois épreuves,
afin que le boss monte en tension jusqu'à la fin.

Exigences : FR12 (attaques lourdes), FR60 (Calcul mental, Examen final) (epics.md, Story 6.2). Architecture : AR7 (patterns en Resources), D4, P4.

**Dépend de : 6.1** (`Boss`, `BossDef`, `BossPhase`, `BossAttackSet`, `BossAttack`, `AttackRunner`, signaux `boss_*`, flux `RunRng.BOSS`, `Telegraph.duration_for`). **Prépare 6.3** (le motif supplémentaire s'ajoute aux ensembles d'attaques actifs) et **6.4** (la règle doit s'arrêter à la mort du boss).

Hors périmètre : Interro surprise (6.3), mort et victoire (6.4), réglage fin de la durée au playtest (consigné, pas corrigé ici).

## Critères d'acceptation

1. **Seuils de phase** : `professor.tres` porte trois `BossPhase` (`hp_from` 1,0 / 0,66 / 0,33). À chaque franchissement vers le bas, `Events.boss_phase_changed` puis `Events.boss_announced` (clés `BOSS_PROFESSOR_PHASE_2` « Calcul mental », `BOSS_PROFESSOR_PHASE_3` « Examen final ») : la craie écrit le nom, le boss **suspend ses attaques** pendant `announce_duration` (les craies déjà tirées continuent), puis la phase démarre. Un coup qui franchit deux seuils d'un coup mène directement à la phase correspondant aux PV restants, une seule annonce (celle de la phase atteinte).
2. **Calcul mental (66 à 33 %)** : une spirale à **4 bras** tourne à **60°/s** autour du boss (craies tirées à 5 tuiles/s, une par bras toutes les 0,2 s, donc 12° entre deux craies d'un bras), **et** 3 craies visées partent toutes les 3 s : éventail de 3 à 20°, centré sur la position du joueur au tir, télégraphe 0,5 s. La spirale annonce son départ par un signe de 0,5 s ; son angle de départ est fixe (0°), sans tirage.
3. **Examen final (33 à 0 %)** : annonce, puis les deux épreuves **alternent** (ensemble « Dictée » 8 s, ensemble « Calcul mental » 8 s, en boucle, à partir de la Dictée) : au changement, les runners de l'ensemble quitté s'arrêtent (leurs craies en vol continuent), ceux du nouvel ensemble démarrent avec leur télégraphe de départ.
4. **Règle** : pendant l'Examen final, toutes les 7 s une règle balaie la salle. Une barre verticale de toute la hauteur, 1 tuile d'épaisseur, traverse la salle à 8 tuiles/s, de gauche à droite ou de droite à gauche (sens tiré dans le flux `BOSS`). Elle est annoncée par **une ligne 0,8 s avant** : le rectangle de départ de la barre et une flèche de sens, durée ≥ 0,4 s sous tous les paliers (le facteur de télégraphe de l'Abandon peut la raccourcir, jamais sous le plancher).
5. **Attaque lourde** : la règle touche via une zone de contact dédiée qui livre un `DamageInfo` avec `is_heavy = true`, `amount = Tuning.COMBAT.heavy_hit_half_hearts` (2 = **1 cœur**), `source = DamageInfo.Source.RULER` (nouvelle valeur, ajoutée à la fin de l'enum). Le dash (i-frames), l'invulnérabilité d'arrivée et d'après-coup l'annulent comme tout coup ; l'armure absorbe d'abord. La règle ne touche qu'une fois par passage (l'invulnérabilité de 1 s après un coup existe déjà).
6. **Données** : arms, `rotation_deg_per_s`, `emit_interval`, éventail, intervalles, durées d'alternance, vitesse et épaisseur de la règle, tout est dans `BossAttack` / `BossPhase` de `professor.tres` ; `BossPhase.alternate_seconds` (0 = pas d'alternance) et `BossPhase.extras: Array[BossAttack]` (attaques actives pendant toute la phase, ici la règle). `validate()` couvre les nouveaux champs.
7. **Durée visée** : avec le build de référence (tir de base 10 dégâts à 4 tirs/s, +30 %, 70 % des tirs touchent = 36,4 dégâts/s), 2 500 PV demandent 68,7 s de tir, + 3 annonces de 1,5 s : **≈ 73 s, soit ≈ 75 s**. Un test calcule cette durée théorique depuis `Tuning.SHOT` et `professor.tres` (entre 65 et 85 s) ; l'écart mesuré en jeu est consigné au playtest (NON ÉVALUÉ ici).
8. **Capacité des projectiles** : pendant 60 s simulées d'Examen final en Abandon total (vitesse ×1,1), `BulletManager.refused_count` reste 0 (pool ennemi de 512).

## Tâches

- [ ] `boss_attack.gd` : `Kind { ROW, SPIRAL, AIMED, RULER }` (ajouts à la fin), champs `arms`, `rotation_deg_per_s`, `emit_interval`, `bullet_count`, `spread_deg`, `thickness_tiles`, `sweep_speed`, validation.
- [ ] `boss_phase.gd` : `alternate_seconds`, `extras`. `boss.gd` : changement de phase (`_update_phase()` appelé par `_on_hit_applied()` de 6.1), suspension pendant l'annonce, rotation des ensembles, démarrage/arrêt des runners ; `Boss.phase_index()`.
- [ ] `runners/spiral_runner.gd`, `aimed_runner.gd`, `ruler_runner.gd` ; `chalk_patterns.gd` : `spiral_directions(angle, arms)`, `aimed_fan(aim, count, spread)`.
- [ ] `bosses/ruler.gd` : `Node2D` + `Hitbox` (voir État du code) qui se déplace de `sweep_speed × step` par tick et se libère au bord opposé, à l'arrêt du runner ou à la mort du boss.
- [ ] `combat/hitbox.gd` : `setup(..., heavy: bool = false)` ; l'info livrée porte `is_heavy`. `core/combat_tuning.gd` + `combat_tuning.tres` : `heavy_hit_half_hearts = 2`. `combat/damage_info.gd` : `Source.RULER = 6`. `telemetry` : la cause « ruler » sort de `Source.find_key` sans autre changement (vérifié par test).
- [ ] `attack_sign.gd` : formes `BAND`, `LINE_ARROW`, `RING` (6.3 ajoute son cercle à `RING` s'il est déjà là).
- [ ] `professor.tres` : phases 2 et 3 ; `strings.csv` : `BOSS_PROFESSOR_PHASE_2`, `BOSS_PROFESSOR_PHASE_3`.
- [ ] Tests.

## État du code concerné

- 6.1 : un `Boss` avec une seule phase, un seul ensemble, `RowRunner`. `AttackRunner.make()` renvoie `null` pour tout `Kind` inconnu : y brancher les trois nouveaux.
- `Hitbox` : AABB seulement (« Rotation and scale are ignored »), testé chaque tick après les entités (`PHYSICS_PRIORITY_HITBOXES`), `GameClock.scale(group)` ; livre `DamageInfo.from_bullet(damage, direction, source)` ; sa cible doit avoir le camp opposé (ici le `Hurtbox` du joueur). `Hurtbox.is_hittable()` consulte le filtre du joueur (dash, invulnérabilité). C'est pourquoi la règle est une **barre alignée sur les axes**, pas un bras rotatif.
- `DamageInfo.is_heavy` existe, jamais lu ; `Health.apply_damage` retire `roundi(amount)` demi-cœurs, armure d'abord. `Player._on_hurtbox_damage_received` laisse passer `hit_incoming` (un objet peut réduire le coup à 0 : coup refusé proprement).
- `Telemetry` lit `DamageInfo.Source.find_key` pour la cause de mort ; `test_code_rules` peut vérifier les enums : lancer toute la suite.
- Danger : `danger_bullet_speed_mult` vaut 1,1 à Dérive et au-delà ; `danger_telegraph_mult` 0,85 à Abandon et au-delà.

## Pièges

- Le seuil se lit **après** le coup : `_on_hit_applied()` compare `hp.current / hp.maximum` à `hp_from` des phases ; ne pas changer de phase pendant le calcul du coup (la mort passe par `_die()`, 6.4).
- Pendant l'annonce, `boss.process` des runners est suspendu, mais le `Hitbox` d'une règle en cours ne doit pas geler en travers de la salle : une règle lancée avant le seuil va au bout de sa course (seule la création de nouvelles règles est suspendue).
- La règle sort des bornes de la salle : la libérer sur la position, pas sur `visible_rect_local()` (grandes salles) ; la salle du cauchemar fait un écran.
- Le `Hitbox` créé en code : son `process_physics_priority` est posé dans son `_ready()` ; l'ajouter à l'arbre avant de le déplacer, sinon `world_rect()` lit une position non valide.
- Spirale : accumuler l'angle en degrés flottants, normaliser (`fposmod(360)`) pour éviter la dérive ; tirer plusieurs craies dans un même tick si un gros ralenti (`scale` > intervalle) en doit plusieurs.
- Éventail visé : la visée est prise au tir, pas au début du télégraphe (comme `ShooterEnemy`).
- Le boss ne doit jamais tirer une craie « visée » sur un joueur à distance nulle (`to.length_squared() < 1e-6` → ne pas tirer, comme `_fire_volley`).
- Ajouter `RULER` à `Source` : `Events.player_hit(damage, source)` transporte l'entier ; ne pas renuméroter.

## Tests (GUT)

- `unit/bosses/test_chalk_patterns` (compléter) : spirale 4 bras à angle donné, 12° entre deux tirs d'un bras à 0,2 s et 60°/s ; éventail de 3 à 20° centré.
- `unit/bosses/test_boss_duration` : durée de référence théorique entre 65 et 85 s ; seuils 0,66 et 0,33 de `professor.tres`.
- `unit/combat/test_heavy_hit` : une règle (Hitbox lourd) retire 1 cœur, ou l'armure d'abord ; `is_heavy` vrai dans l'info reçue ; refusée en dash ; une fois par passage.
- `integration/bosses/test_professor_phases` : coups jusqu'à 66 % puis 33 % : annonces dans l'ordre, une seule par phase ; pas d'attaque pendant l'annonce ; saut direct 100 % → 20 % : une annonce (phase 3) ; alternance 8 s / 8 s ; règle annoncée ≥ 0,4 s avant le premier tick du hitbox ; aucune règle en phase 1 et 2 ; 60 s d'Examen final en Abandon total : `refused_count == 0`.

## Sources

epics.md (Story 6.2) ; GDD, Le Professeur (trois épreuves, spirale 4 bras 60°/s, 3 craies visées toutes les 3 s, règle annoncée 0,8 s) ; GDD, définition du build de référence ; architecture (`DamageInfo.is_heavy`).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **La règle est une barre verticale qui balaie de gauche à droite (ou l'inverse)**, 1 tuile, 8 tuiles/s, toutes les 7 s. Le GDD dit « balaie la salle, annoncée par une ligne ». Raison : le `Hitbox` est un rectangle sans rotation ; la parade est le dash (i-frames 0,15 s ≥ temps de passage ≈ 0,17 s avec le corps du joueur). À vérifier à la main : si le passage est trop serré, ralentir la règle ou élargir la barre (donnée).
2. **Attaque lourde = 2 demi-cœurs** (« retire 1 cœur ») portés par `Tuning.COMBAT.heavy_hit_half_hearts`, **source `RULER`** dédiée (cause de mort lisible en télémétrie).
3. **Spirale : une craie par bras toutes les 0,2 s ; éventail visé de 3 à 20° ; Examen final : 8 s par ensemble, démarrant par la Dictée.** Le GDD donne bras, vitesse de rotation, 3 craies et 3 s, rien de plus.
4. **Annonce de phase = pause de 1,5 s des nouvelles attaques**, craies déjà en vol conservées. Raison : lisibilité du changement ; allonge le combat de ≈ 4,5 s dans la cible des 75 s.
5. **Un coup multi-seuils saute à la phase atteinte, sans annoncer celles qu'il enjambe.**
6. **Pas d'invulnérabilité du boss pendant l'annonce** : il reste touchable (le joueur n'a pas à attendre).
7. **Durée de 75 s : vérifiée par le calcul, pas mesurée.** Le tir réel dépend du joueur ; mesure au playtest.

## Dev Agent Record

### Décisions complémentaires (dev, sans Kroustille)

8. **`spread_deg` = angle entre les deux craies extrêmes** de l'éventail (3 craies sur 20° : -10°, 0°, +10°).
9. **Première règle 7 s après le début de l'Examen final** (signe à 6,2 s) : pas de règle pendant l'annonce ni juste après le départ de la Dictée.
10. **Vitesse des craies visées 6 t/s** (le GDD ne la donne pas) ; la spirale tire à 5 t/s.
11. **Une règle déjà lancée est libérée à l'arrêt de son runner** (sortie de phase, mort, fin de run) ; tant que la phase dure, elle va au bout même pendant une annonce (elle avance seule). `fire_hold` la fige et désactive son contact.
12. **Annonce en cours de combat = nouvel état ANNOUNCING du boss** (même télégraphe que l'ouverture) ; un second seuil franchi pendant l'annonce relance l'annonce de la phase atteinte.
13. **`SPIRAL` ignore `interval`** (c'est `emit_interval`) et `RULER` ignore `bullet_speed` : `validate()` ne les exige plus pour ces genres.
14. **Fenêtre de dash contre la règle** : passage de la barre sur le corps du joueur = (1 + 0,375) / 8 = 0,17 s > 0,15 s d'i-frames : un dash sur place (sans mouvement) échoue de 0,02 s ; un dash vers la barre (vitesse relative ≈ 25 t/s) la franchit en ≈ 0,06 s, et marche si la barre est à moins de 3 tuiles au départ du dash (testé à 2 tuiles). Même sens que la barre : moins de marge. À juger à la main ; réglage par donnée (`sweep_speed`, `thickness_tiles`).

### Notes de complétion

- Genres `SPIRAL`, `AIMED`, `RULER` ajoutés à la fin de `BossAttack.Kind` ; `BossPhase.alternate_seconds` / `extras` ; `Boss` gère les changements de phase avec annonce (attaques suspendues, craies en vol conservées), l'alternance des ensembles et les extras.
- `Hitbox.setup(..., heavy)`, `DamageInfo.Source.RULER = 6`, `Tuning.COMBAT.heavy_hit_half_hearts = 2`. `AttackSign` : formes `BAND`, `LINE_ARROW`, `RING` (6.3 ajoutera son cercle à `RING`).
- Tests : GUT 698 / 698 (dont `test_heavy_hit`, `test_boss_duration`, `test_professor_phases`, `test_chalk_patterns` complété) ; 60 s d'Examen final en Abandon : `refused_count == 0`.

### Liste des fichiers

`game/bosses/{boss,boss_attack,boss_phase,chalk_patterns,attack_sign,ruler}.gd`, `game/bosses/runners/{attack_runner,spiral_runner,aimed_runner,ruler_runner}.gd`, `game/combat/{hitbox,damage_info}.gd`, `game/core/combat_tuning.gd`, `game/data/tuning/combat_tuning.tres`, `game/data/bosses/professor.tres`, `game/localization/strings.csv`, tests (`unit/bosses/test_boss_duration`, `test_chalk_patterns`, `unit/combat/test_heavy_hit`, `integration/bosses/test_professor_phases`).

### Journal des modifications

- 2026-11-24 : implémentation de la story 6.2 (commits 5e538ab à 59b6e6c).

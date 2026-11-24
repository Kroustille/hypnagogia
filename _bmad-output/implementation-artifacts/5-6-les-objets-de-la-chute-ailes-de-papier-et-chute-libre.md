# Story 5.6 : Les objets de la Chute : Ailes de papier et Chute libre

Status: in-progress

## Story

En tant que joueur,
je veux des objets qui jouent avec la chute,
afin de construire un build autour des trous et de l'esquive.

Exigences : FR48, FR49, AR15 (`ItemEffect`) (epics.md, Story 5.6). Architecture : D9, P5 (exemple `FreeFallEffect`).

**Dépend de : 5.1** (`BuildCarrier`, `ItemEffect`, `hit_incoming` / `hit_taken`, `OwnedItem`), 4.3 (chute dans les trous, `CAN_FLY_OVER_PITS`). Prépare 5.7 (ces deux objets portent le tag Chute) et 5.10 (les effets sont refusés sur un porteur qui n'est pas le joueur).

Hors périmètre : onde de choc et synergies (5.7).

## Critères d'acceptation

1. **Ailes de papier** (`data/items/paper_wings.tres`, tag Chute, `effect_script = PaperWingsEffect`) : tant que l'objet est porté et qu'il n'a pas été interrompu, `CAN_FLY_OVER_PITS` est à 1 (modificateur `ADD_FLAT 1` dont la source est l'`OwnedItem`). Le joueur survole les trous : `Player.can_fly_over_pits()` ne change pas.
2. **Coup reçu** : sur `hit_taken`, le survol est retiré (`clear_modifier`) pendant 3 s (`params.suspend_seconds`, en ticks du groupe `PLAYER`), puis rendu (`set_modifier` à nouveau). Un nouveau coup pendant la suspension relance les 3 s.
3. **Coup reçu au-dessus d'un trou** : le survol disparaît, le joueur tombe sur le champ : retour à `_pit_guard.last_safe`, **sans dégât de chute** (`PIT_DAMAGE` non appliqué : il ne perd que le coup). `Player` expose `fall_if_over_pit()` (le test de `_is_over_pit()` puis `_fall(deal_damage = false)`), appelé par l'effet après avoir retiré le survol. Le coup lui-même a déjà été appliqué par le chemin normal du `Hurtbox`.
4. **Chute libre** (`data/items/free_fall.tres`, tag Chute, `effect_script = FreeFallEffect`) : tant que le joueur n'est pas touché, un modificateur `ADD_PERCENT` de la source `DAMAGE` monte de +5 % par seconde pleine jusqu'à +50 % (`params.rate`, `params.max_bonus`, `params.step_seconds` = 1). Le compteur progresse avec `GameClock.scale(PLAYER)` (le pause, le ralenti de 5.8 ne le font pas avancer à tort : seul le joueur compte).
5. **Coup reçu avec bonus actif** : sur `hit_incoming(info)`, si le bonus est > 0, `info.amount += 1` (½ cœur de plus, l'armure absorbe d'abord comme pour tout coup) et le bonus retombe à zéro (modificateur retiré). Sans bonus, aucun supplément. Le bonus repart de zéro à chaque coup, avec ou sans supplément. Un coup refusé (invulnérabilité) n'est pas un coup : `hit_incoming` n'est émis qu'après les filtres de la hurtbox (il l'est dans `_on_hurtbox_damage_received`, donc déjà filtré).
6. **`detach()`** : retiré, chaque effet se déconnecte de tous les signaux qu'il écoutait et laisse la stat comme s'il n'avait jamais été posé ; `Loadout.remove` appelle aussi `clear_source` (5.1). Deux Chute libre : une seule `ItemDef` non `stackable`, jamais en double.
7. **Chute libre et le coup de chute** : tomber dans un trou sans survol est un coup de la source `PIT` : il compte comme un coup (bonus perdu, supplément ½ cœur inclus), documenté et testé.
8. **Pools** : les deux objets sont ajoutés aux pools trésor et boutique (`data/pools/*.tres`, 5.2).
9. Textes `strings.csv` : noms, bonus, coûts des deux objets (le coût de Chute libre : « le bonus retombe à zéro au premier coup, et ce coup retire ½ cœur de plus »).

## Tâches

- [x] `items/effects/paper_wings_effect.gd`, `items/effects/free_fall_effect.gd` (sans valeur littérale : tout dans `ItemDef.params`), `data/items/paper_wings.tres`, `free_fall.tres`.
- [x] `BuildCarrier` : appelle `effect.tick(delta × GameClock.scale(PLAYER))` pour les effets qui le demandent (`wants_tick`), ne le fait pas quand le joueur est mort.
- [x] `BuildCarrier.hit_incoming` émis par `Player._on_hurtbox_damage_received` **avant** `health.apply_damage(info)` (5.1 pose le signal ; câblage vérifié ici).
- [x] `Player.fall_if_over_pit()` + paramètre de dégâts de `_fall`.
- [x] Pools, `strings.csv`, tests.

## État du code concerné

- `Player._on_hurtbox_damage_received(info)` : `health.apply_damage(info)` → `Events.player_hit` → `_die` si mort ; `hurtbox.refuse_hit()` si rien n'est perdu. `info.amount` est un float de demi-cœurs.
- `Player._fall()` : replace au dernier point sûr, remet le moteur à zéro, puis un `DamageInfo(PIT)` par `hurtbox.receive(info)` si `PIT_DAMAGE ≥ 1` ; un joueur invulnérable est replacé sans dégât (c'est le cas juste après un coup : invulnérabilité de 1 s).
- `_is_over_pit()` ne tombe pas quand `can_fly_over_pits()` ; `_check_pits()` ne teste que hors dash.
- `Glide` : atterrir dans un trou tombe sans invulnérabilité d'arrivée (4.3) ; avec Ailes de papier, le test `_is_over_pit()` renvoie faux : rien à faire.
- `StatBlock.set_modifier` remplace le modificateur de la source sur la stat ; `clear_modifier(source, stat)` le retire.

## Pièges

- **Ordre** : l'effet des Ailes réagit à `hit_taken` (après `apply_damage`), pas à `hit_incoming`. Au moment où il retire le survol, le joueur est invulnérable (1 s) : `_fall` n'applique donc pas de coup supplémentaire, mais on passe `deal_damage = false` quand même (ne pas dépendre de l'invulnérabilité : une invulnérabilité réglée à 0 s dans `CombatTuning` doit donner le même résultat).
- **Mort au coup** : si le coup tue, ne rien faire (pas de chute, pas de signal de plus) ; `hit_taken` est émis avant `_die` mais l'effet vérifie `health.is_dead()`.
- **Suspension et `Run.travel`** : le joueur est `PROCESS_MODE_DISABLED` pendant le fondu (4.8) : le carrier est son enfant, ses timers se figent avec lui (voulu).
- Chute libre ajoute 1 à `info.amount` : le coup « ½ cœur de plus » sur armure retire de l'armure d'abord, comme tout coup. À écrire tel quel dans le test.
- `ItemEffect.tick` ne doit pas allouer à chaque tick (pas de nouvelle `Callable` par tick) ; le bonus n'est réécrit dans le `StatBlock` qu'à chaque palier d'une seconde (évite `changed` 60 fois par seconde).
- Le survol est une stat à 0/1 : pas de `MULTIPLY` (0 × tout = 0).

## Tests

- `unit/items/test_paper_wings_effect.gd` : stat à 1 à l'attachement, 0 après `hit_taken`, 1 de nouveau après 180 ticks, relance sur un second coup, `detach` rend la stat à 0 et déconnecte (compte de connexions du carrier).
- `unit/items/test_free_fall_effect.gd` : +5 % / s plafonné à +50 % à 10 s, aucun supplément sans bonus, `info.amount += 1` avec bonus, retombée à 0, pas de tick avec `GameClock.paused`.
- `integration/items/test_fall_items.gd` : joueur au-dessus d'un trou avec Ailes de papier, coup reçu : replacé au point sûr, un seul coup perdu ; survol qui revient après 3 s ; Chute libre : bonus de dégâts lu sur `_shot_params`, supplément de ½ cœur sur un vrai coup.

## Sources

epics.md (Story 5.6) ; GDD « Objets du MVP » (lignes Ailes de papier, Chute libre) et notes de design ; architecture P5 (exemple de `FreeFallEffect`).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Bonus de Chute libre par paliers d'une seconde** (+5 %, +10 %…) plutôt que continu : lisible, et peu de `changed`.
2. **Le coup de chute (`PIT`) compte comme un coup** pour Chute libre ; il retire le bonus et le ½ cœur de plus.
3. **Chute sans dégât au retrait du survol** passe par un paramètre de `_fall`, pas par une modification de `PIT_DAMAGE`.
4. **Chute libre n'est pas cumulable** (`stackable` faux, sans doublon dans la run), comme les autres objets hors Dent.
5. **Le bonus est dans le temps du groupe `PLAYER`** (pas affecté par le Réveil cassé qui épargne le joueur).

## Dev Agent Record

### Notes de complétion

- `PaperWingsEffect` / `FreeFallEffect` : tout dans `ItemDef.params` ; source des modificateurs = `OwnedItem` (`ItemEffect.modifier_source()`). `ItemEffect` gagne `required_params()`, `param()` ; `ItemCatalog.problem_of` refuse un effet sans ses params ou un script qui n'étend pas `ItemEffect`.
- Cycle de vie (dette 5.6) : `attach`/`detach` idempotents, `BuildCarrier._enter_tree` rattache (`Loadout.attach_all`), pas de `tick` sur un effet détaché ni quand le joueur est mort, objet non `RefCounted` libéré à la création.
- `hit_incoming` (dette 5.6) : `Player._on_hurtbox_damage_received` refuse avant l'émission si mort/invulnérable ; si un effet ramène le montant sous 1, le coup est refusé proprement (`refuse_hit`). Un montant invalide venu de dehors passe toujours par `Health` (journal + assert, `t_invalid23`).
- `Player.fall_if_over_pit()` + `_fall(deal_damage)`. Retirer les Ailes en plein trou fait tomber normalement (`_check_pits`, avec dégâts de chute).
- Tag des deux objets : `fall` (comme les objets existants). Pools trésor et boutique mis à jour.
- Checks : GUT 532/532 ; `run_all.sh` : seuls `t_sheep_main` et `t_enemy_main` échouent en parallèle (ok=2 sur la touche F1 9), identique sur HEAD sans mes changements (flake de charge, passent seuls) ; `--quit-after 120` propre.

### Décisions prises sans Kroustille (ajouts)

6. Les Ailes se retirent aussi si l'objet est retiré en plein trou : chute normale avec dégâts (pas de chute gratuite).
7. Une pré-validation de `required_params` dans le catalogue plutôt qu'un défaut silencieux à 0.

### Liste des fichiers

`items/effects/{paper_wings,free_fall}_effect.gd`, `data/items/{paper_wings,free_fall}.tres`, `data/pools/*.tres`, `items/{item_effect,loadout,build_carrier,item_catalog}.gd`, `player/player.gd`, `localization/strings.csv`, tests GUT `unit/items/test_{paper_wings,free_fall}_effect.gd`, `test_item_catalog.gd`, `integration/items/test_fall_items.gd`.

### Non évalué (humain)

- Ressenti de Chute libre (+5 %/s, ½ cœur de plus) et des 3 s de suspension des Ailes : playtest du jalon A.

### Review Findings

Revue de code (2026-11-24, 3 couches : Blind Hunter, Edge Case Hunter, Acceptance Auditor), diff `dc69e08..83848c1`. Lignes à `83848c1` (entre parenthèses : à `8acaa74` quand elles ont bougé). 4 patchs, 3 reports, 14 rejets.

**Régression signalée `t_enemy_main` / `t_sheep_main` : pas une régression de 5.6, pas un bogue du jeu.** Preuve : arbres propres de `dc69e08` et `83848c1` extraits à part (le dev 5.7 modifiait l'arbre de travail) ; au calme, 3/3 PASS sur chacun ; sous charge (10 instances en parallèle), 5/5 FAIL sur **chacun**, au même pas (« F1 + key 6 »). Instrumenté : quand l'échec arrive, `Engine.get_process_frames()` n'a pas avancé pendant les 2 ticks de `press()` (0 image de rendu, 2 ticks de physique dans la même itération) ; or `Input.parse_input_event` ne vide sa file qu'à l'image suivante : la touche 6 n'est jamais livrée avant le check. Chaque passage avec ≥ 1 image passe. C'est le harnais (en `--fixed-fps 60` : une image par tick, jamais d'échec). Report ci-dessous.

- [ ] [Review][Patch] Ailes rattachées pendant la suspension : le vol ne revient jamais [`game/items/effects/paper_wings_effect.gd:19-20`] — `detach()` met `wants_tick = false` et garde `_suspended_left` ; `attach()` (via `BuildCarrier._enter_tree` → `Loadout.attach_all`, ajouté par cette story) ne remet pas `wants_tick`, donc `tick()` n'est plus appelé et le survol est perdu pour la run. Correctif : `if _suspended_left <= 0.0: _grant_flight()` puis `else: wants_tick = true`. Test GUT dans `test_paper_wings_effect.gd` : coup reçu, 60 ticks, `remove_child`/`add_child` du carrier, 130 ticks de plus → `CAN_FLY_OVER_PITS` = 1 (échoue aujourd'hui).
- [ ] [Review][Patch] Un montant de coup invalide venu d'une source n'est plus signalé [`game/player/player.gd:529-533` (`533-537`)] — un `info.amount` fini < 1 dès l'entrée (ennemi mal réglé, 0,4) saute l'émission puis est refusé en silence, alors qu'avant `Health.apply_damage` journalisait `hit refused: invalid amount` + assert. Correctif : ne refuser en silence que si un effet a baissé le montant : `if is_finite(info.amount) and roundi(info.amount) >= 1:` `carrier.hit_incoming.emit(info)` puis, **dans ce bloc**, `if is_finite(info.amount) and roundi(info.amount) < 1: hurtbox.refuse_hit(); return` ; un montant invalide d'origine va à `Health` comme avant 5.6. Test GUT : `DamageInfo` amount 0.4 sans objet → `assert_push_error`/journal d'erreur ou `lost == 0` via `Health` (voir `t_invalid23`) ; le test `test_an_effect_that_cancels_the_hit_refuses_it_cleanly` doit rester vert.
- [ ] [Review][Patch] `ItemCatalog.problem_of` crée un effet jetable à chaque appel, donc à chaque tick par pickup d'Ailes / Chute libre [`game/items/item_catalog.gd:47-56`] — chaîne `Pickup._physics_process` → `_refresh_look` → `is_available` → `BuildCarrier.can_take` → `refusal_of` → `problem_of` → `effect_script.new()` (60 allocations/s par pickup, plus l'`_init` de l'effet). Correctif : cache statique par script, `static var _required_by_script: Dictionary = {}` (script → `Array[StringName]`, ou `""`/marqueur pour « n'étend pas `ItemEffect` »), rempli au premier appel. Test GUT dans `test_item_catalog.gd` : deux appels sur `paper_wings.tres` donnent `""`, et une définition sans `suspend_seconds` est toujours refusée après un premier appel valide sur un autre objet du même script.
- [ ] [Review][Patch] AC3 non prouvé sans l'invulnérabilité d'après-coup [`game/tests/integration/items/test_fall_items.gd:50`] — le test de chute gratuite passe aussi si `fall_if_over_pit` infligeait le coup de chute, car le joueur est invulnérable 1 s. Ajouter un test : joueur vulnérable (pas de coup avant) au-dessus du trou, survol retiré à la main, `player.fall_if_over_pit()` → `true`, replacé à `last_safe`, `half_hearts` inchangé, aucun `player_hit`. Ajouter aussi, dans `test_free_fall_effect.gd`, un `detach()` direct (sans `Loadout.remove`) avec bonus > 0 → modificateur `DAMAGE` absent (AC6).
- [x] [Review][Defer] Chute libre face à un effet qui annule un coup (aucun aujourd'hui) — reporté, voir `deferred-work.md`.
- [x] [Review][Defer] Dash encore actif quand `fall_if_over_pit` / `_fall` replace le joueur — reporté (déjà vrai pour le Planer), voir `deferred-work.md`.
- [x] [Review][Defer] Harnais scratch : touche simulée non livrée quand 2 ticks tombent dans la même image (`t_enemy_main`, `t_sheep_main`) — reporté, voir `deferred-work.md`.

Rejetés (14) : refus mort/invulnérable avant l'émission redondant avec `Hurtbox.is_hittable` / `Health` mais même issue (pas de `player_hit`, `refuse_hit`, invulnérabilité de coup, i-frames du dash, contact et télémétrie inchangés, touche 3 « hit ignored » inchangée) ; `fall_if_over_pit` sans salle (`_is_over_pit` teste déjà `_room == null` et la mort) ; chute « dans un rappel physique » (les coups arrivent depuis `_physics_process` des hitbox / gestionnaires de balles, pas depuis un signal du moteur) ; `_enter_tree` sur une loadout vide (rien à rattacher) ; rattachement des anciens effets (Café et Pincement sont des consommables, pas des `ItemEffect`) ; `PIT_DAMAGE` < 1 ne compte pas comme coup pour Chute libre (pas de coup, cohérent avec « un coup refusé n'est pas un coup ») ; `bonus()` périmé après `detach` (aucun lecteur, `attach` remet à 0) ; `detach_all` qui touche les stats (voulu : rien ne doit rester posé hors de l'arbre) ; `DamageInfo` réutilisé (chaque source en crée un neuf) ; dérive flottante de 1 tick sur les 180 ; nombres en dur dans `strings.csv` (convention des autres objets) ; `load_steps` ; `effect_script` non `GDScript` (le projet n'a que du GDScript) ; carrier avec `player` nul dans l'arbre (aucun chemin du jeu ; `setup` reçoit toujours le joueur).

### Décisions prises sans Kroustille (revue de code)

8. **Joueur mort : les consommables en cours se figent aussi** (`BuildCarrier._physics_process` sort avant `_running`) : accepté, la run est finie et `_exit_tree` les annule.
9. **Échecs de `t_enemy_main` / `t_sheep_main` classés « harnais »**, pas bogue du jeu : mêmes échecs sur `dc69e08` sous charge, cause mesurée (file d'entrée non vidée sans image de rendu entre les ticks).

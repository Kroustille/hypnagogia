# Epic 3 : décisions prises sans toi, à valider

> **En attente : Kroustille validera toutes les décisions en une fois, à la fin. Les choix par défaut s'appliquent d'ici là.**

Pendant l'epic 3 (stories 3.1 à 3.8, la lucidité à deux pôles), 102 décisions ont été prises sans toi. Elles sont toutes notées dans les sections « Décisions prises sans Kroustille » de chaque story. Ce document les trie pour que tu puisses valider vite, en même temps que celles des autres epics.

**Comment répondre :** réponds avec les numéros à changer et ce que tu veux à la place ; tout le reste est validé. Exemple : « D3.5-1 : la cadence et non la vitesse de balle ; D3.7-1 : 64 bits ».

Lecture d'un numéro : `D3.5-8` = story 3.5, décision 8. Les décisions 9 et suivantes de certaines stories viennent des ajouts du dev ou de la revue de code (la 3.6 saute de 11 à 12 parce que la 12 remplace la 11).

Colonne « GDD ? » : **conforme** (le GDD dit déjà la même chose), **comble un manque** (le GDD ne dit rien, on a choisi), **s'en écarte** (le GDD ou l'architecture dit autre chose).

Plan :
1. Écarts au GDD ou à l'architecture.
2. À regarder en priorité (ce que le joueur ressent).
3. À survoler (technique, une ligne par sujet).
4. À juger en jouant (ce qui n'a jamais été vu, entendu ni tenu en main par un humain).
5. Actions qui te reviennent.

---

## 1. Écarts au GDD ou à l'architecture

Onze points s'écartent d'un texte de référence (ou en lisent une phrase ambiguë). Chacun est aussi dans les tableaux de la section 2, avec son contexte.

- **D3.2-1 : un projectile déjà frôlé peut encore rapporter un dash parfait (2 + 5).** Le GDD dit que le dash parfait « remplace le graze » et le pseudo-code de l'architecture (P2) écrit `not counted`. Raison : sinon le dash parfait serait presque inatteignable en réaction (la zone d'une tuile précède l'impact de 0,2 s, l'invulnérabilité du dash dure 0,15 s). Avec D3.2-8, le cas ne se produit plus en pratique. Alternative : ne donner que +3 de complément.
- **Observation de la revue 3.2 (sans numéro) : le dash parfait est atteignable en réaction quand on dashe à travers une balle (fenêtre d’environ 0,3 s de trajet), mais un dash perpendiculaire à la balle est quasiment à l’image près.** À juger en jouant.
- **D3.2-8 : le graze est compté quand le projectile s'éloigne de la hurtbox, pas quand il entre dans la zone d'une tuile.** Le GDD dit seulement « passe à moins d'une tuile sans toucher ». Raison : compté à l'entrée, chaque coup aurait rapporté +2 juste avant l'impact. Les projectiles très rapides (au-delà de 6 tuiles/s) pourront manquer leur graze (reporté).
- **D3.3-9 : la Veilleuse n'est pas repoussée par l'Éveil.** Le GDD dit « repousse de 2 tuiles les ennemis situés à moins de 3 tuiles » ; la Veilleuse est une tourelle fixe (FR28, « ne bouge jamais »). Changement d'une ligne si tu veux l'inverse.
- **D3.5-1 : « tirs 30 % plus rapides » lu comme vitesse de balle ×1,3, pas comme cadence.** Le GDD est ambigu ; l'AC de l'epic dit « vont 30 % plus vite ».
- **D3.5-8 : `contact_size` des quatre ennemis de 0,75 à 0,875 tuile.** Cela modifie des valeurs validées à l'epic 2 (le GDD ne donne aucune taille de contact). Raison : avec la hurtbox de 4 px du palier Lucide, l'ancienne zone de 12 px ne faisait plus que toucher le joueur et le contact n'infligeait plus jamais de dégâts. Effet : +1 px de portée latérale hors Lucide.
- **D3.6-12 : le son et l'anneau rouge de danger ne se jouent que si le profil de danger change (rien de Lucide à Flottant).** Le GDD dit « chaque aggravation en pleine salle est signalée » ; on lit « aggravation » comme un changement réel de danger. Raison : sinon le premier Éveil de chaque vague joue quatre retours à la fois sans aucun effet. Réversible en une ligne.
- **D3.7-1 : seed de run de 40 bits, affichée en 8 caractères Crockford base32.** L'architecture (D8) dit « 64 bits » et « 8 caractères », ce qui est incompatible. À valider ; si oui, le texte de `game-architecture.md` est à aligner (reporté).
- **D3.7-3 : une vague qui commence en Abandon reçoit son renfort aussitôt.** L'AC de l'epic dit « atteint Abandon pour la première fois dans la vague » ; le GDD dit 1 ennemi supplémentaire par salle de combat en Abandon, ce qui va dans ce sens.
- **D3.7-13 (avec D3.7-11) : un seul renfort par vague, pas par salle, et aucun entre deux vagues.** Le GDD dit « 1 ennemi supplémentaire par salle de combat ». L'arène en enchaîne plusieurs vagues dans une même « salle » : par salle, le renfort ne viendrait qu'une fois pour six vagues.
- **D3.8-5 (avec D3.8-10) : tremblement d'écran à l'Éveil (1 à 2 px, 0,15 s).** Le GDD ne cite le tremblement que dans l'accessibilité (le réduire) et ne dit pas qui le provoque. L'Éveil en est le seul déclencheur pour l'instant.
- **Pas de base `power.gd` ni de `awaken.gd`** (report de la revue de 3.3, sans numéro de décision ; 3.4 a copié le motif). L'architecture prévoit `player/powers/power.gd`, `awaken.gd` et `glide.gd` ; le code a `Awakening`, la logique dans `Player._try_awakening` et `Glide` en fonction statique (D3.4-9). Conséquence : la lucidité est dépensée même si aucune salle n'écoute `awakening_used`. À trancher en rétro d'epic : aligner l'architecture sur le code, ou extraire une base `Power`.

---

## 2. À regarder en priorité

### Jauge, paliers et annonces (3.1)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D3.1-1 | Aucun bonus de lucidité appliqué en 3.1 (ni dégâts ni précision). | Le CA ne porte que sur la jauge et les paliers ; les effets sont en 3.5. | conforme |
| D3.1-4 | Deux sons de palier, un pour la descente et un pour la montée, provisoires, générés par script. Aucun son à la création. | « Un son marque chaque changement de palier » ; deux timbres rendent le sens lisible. Remplacés par 7.7. | conforme |
| D3.1-5 | Une étiquette avec le nom du palier à droite de la jauge. Pas d'effet plein écran. | La couleur seule ne suffit pas (accessibilité, FR67) ; photosensibilité. | comble un manque |
| D3.1-2 | Le tuning donne le plancher de chaque palier (76, 51, 26, 1, 0) et le maximum (100). | Les limites du GDD restent des données modifiables. | conforme |

### Gains de lucidité : graze et dash parfait (3.2)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D3.2-1** | **Un projectile déjà frôlé peut encore rapporter un dash parfait (2 + 5).** | Voir section 1. | **s'en écarte** |
| **D3.2-8**, D3.2-14 | **Le graze est compté quand le projectile s'éloigne.** Gardé en revue : juste à toutes les vitesses actuelles (6 tuiles/s au plus) et sous tous les angles. | Voir section 1. | **s'en écarte** |
| D3.2-3 | Si le plafond de graze est atteint, le projectile reste marqué, le son et l'événement partent quand même (gain 0). | Le joueur a bien frôlé ; un son qui disparaît sans raison ressemblerait à un bug. | comble un manque |
| D3.2-13 | Le plafond de +20 par salle compte le gain réel, pas le gain demandé. | Une jauge pleine ne doit pas épuiser le plafond avant une dépense. | conforme |
| D3.2-6 | Le dash parfait n'est pas plafonné. | Le GDD ne plafonne que le graze ; le dash parfait est le geste difficile. | conforme |
| D3.2-11 | Pas de dash parfait pendant l'invulnérabilité après un coup ou forcée, même si le dash est actif. | L'AC (« aurait touché ») l'emporte ; sinon un coup ouvre une fenêtre de +5 par projectile sans risque. | conforme |
| D3.2-12 | Un projectile esquivé par le dash ne peut plus toucher le joueur : il continue sa course, la hurtbox l'ignore. | Sans cela environ 15 % des dashs « à travers » donnaient le son du dash parfait puis un coup. Alternative : libérer le projectile. | comble un manque |
| D3.2-10 | Sons provisoires : graze 1800 vers 2400 Hz (60 ms), dash parfait 700 vers 1500 Hz (180 ms). | Remplacés en 7.7. | conforme |

### Éveil (3.3)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D3.3-3 | Le recul ne coupe aucune attaque en cours (charge du Mouton, télégraphe, grattage). | Interrompre créerait des états à tester dans 4 ennemis. À revoir au playtest. | comble un manque |
| D3.3-4 | Le recul est instantané (pas d'animation) ; un anneau signale l'effet. | Lisible, sans état supplémentaire. | comble un manque |
| D3.3-5 | Les projectiles du joueur ne sont pas effacés. | « Tous les projectiles ennemis » (GDD). | conforme |
| D3.3-6 | Pas d'indicateur de recharge dans le HUD ; le son de refus est le seul retour. | Les emplacements de pouvoir arrivent en epic 5. Marqué NON ÉVALUÉ. | comble un manque |
| D3.3-7 | `power_1` : clic droit et LT (axe 4). | AC de l'epic. | comble un manque |
| D3.3-8 | L'Éveil est utilisable pendant un dash. | Aucune règle contraire ; sortie de secours. | comble un manque |
| **D3.3-9** | **La Veilleuse n'est pas repoussée.** | Voir section 1. | **s'en écarte** |
| D3.3-10 | « Tous les projectiles » = ceux présents à l'activation. Un ennemi qui tire dans le même tick, après le joueur dans l'arbre, garde sa salve. | C'est un tir neuf, annoncé par un télégraphe ; l'effacer coûterait plus cher qu'un tick. | conforme |

### Glissement et obstacles (3.4)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D3.4-1 | Obstacles de test dans l'arène : 3 blocs bas et 2 blocs hauts de 2×2 tuiles, posés en code. | L'AC demande « quelques » obstacles ; les vraies salles viennent en epic 4. | comble un manque |
| D3.4-3 | Un trajet inférieur à 0,5 tuile est refusé sans dépense. | Payer 20 pour ne pas bouger serait un piège. | comble un manque |
| D3.4-4, D3.4-10 | Stick relâché : 2 tuiles vers la dernière visée. Au stick, la distance suit l'inclinaison (un stick à peine hors zone morte donne environ 2 tuiles). | Le GDD dit « de 2 à 6 tuiles » ; on suit le code de visée existant. | conforme |
| D3.4-5 | Glissement autorisé pendant un dash ; le dash continue depuis l'arrivée. | `Dash` n'est pas annulable et le GDD ne l'interdit pas. | comble un manque |
| D3.4-6 | L'invulnérabilité d'arrivée est une invulnérabilité ordinaire : pas de graze, pas de dash parfait. | Le dash parfait est celui de l'invulnérabilité du dash (GDD). | conforme |
| D3.4-7 | `power_2` : Maj gauche et LB. | AC de l'epic ; le dash est sur Espace et RB. | comble un manque |
| D3.4-8 | Les ennemis sont aussi bloqués par les obstacles bas et hauts ; ils ne contournent pas (limite connue, epic 4). | Cohérence. | comble un manque |
| D3.4-12 | Anneaux de Glissement : rayon 1 tuile, 0,25 s, au départ et à l'arrivée ; F3 affiche « Glide n% ». | L'AC ne donne pas de valeurs. | comble un manque |
| D3.4-13 | Dash puis Glissement : les i-frames du dash suivent la téléportation et peuvent payer des dashs parfaits à l'arrivée. Il faut au moins 4 balles esquivées (4 × 5) pour rembourser les 20 de lucidité. | Pas de ferme rentable, le dash seul permet déjà la même chose. À surveiller au playtest. | comble un manque |

### Précision de Lucide et puissance de l'Abandon (3.5)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D3.5-1** | **« Projectiles 30 % plus rapides » = vitesse de balle ×1,3, pas la cadence.** | Voir section 1. À valider en jouant. | **s'en écarte** (lecture d'une phrase ambiguë) |
| D3.5-2, D3.5-3 | La hurtbox de Lucide est remplacée par 4 px (pas un pourcentage). Seule la hurtbox rétrécit ; le corps de mouvement garde 6×6 px. | 4 px est une valeur absolue du GDD ; changer le corps pourrait coincer le joueur dans un mur au changement de palier. | conforme |
| D3.5-4 | Dégâts de 13,5 gardés en flottant (chiffres affichés arrondis à 14). | L'AC donne 13,5 ; les PV ennemis sont flottants. | conforme |
| D3.5-7 | Pas d'affichage des bonus dans le HUD. | La jauge et le nom du palier suffisent au jalon A. À juger. | comble un manque |
| **D3.5-8**, D3.5-10 | **`contact_size` des quatre ennemis : 0,75 à 0,875 tuile.** Maintenu en revue (correctif de données, réversible). En Lucide la portée latérale reste celle validée en 2.5 ; hors Lucide elle passe de 9 à 10 px. | Voir section 1. | **s'en écarte** (valeurs d'epic 2) |

### Danger du palier le plus bas (3.6)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D3.6-2 | Une vague qui commence en Abandon applique danger et renfort du palier dès le début, sans son d'aggravation. | « La salle commence à ce palier » ; le signal est réservé aux aggravations en pleine salle. | conforme |
| D3.6-3 | Le danger s'applique aux ennemis qui tirent ou lancent un télégraphe après l'aggravation ; rien n'est rétroactif sur les projectiles en vol. | AC. | conforme |
| D3.6-4 | Signal d'aggravation : son grave et anneau rouge autour du joueur, pas de flash. | Lisibilité et photosensibilité (FR67). | conforme |
| D3.6-7 | Le Mouton et le Somnambule subissent seulement ×0,85 sur leurs télégraphes (ils n'ont pas de projectiles). Le plancher de 0,4 s est tenu par `min_telegraph`. | Le GDD ne cite que « projectiles ennemis » et « télégraphes ». | conforme |
| **D3.6-12** (remplace D3.6-11) | **Le signal n'est joué que si le profil de danger change.** Lucide vers Flottant : aucun signal. Flottant vers Dérive, Dérive vers Abandon, Abandon vers Abandon total : signal. | Voir section 1. | **s'en écarte** (lecture stricte) |

### Renfort de l'Abandon (3.7)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D3.7-2 | Le type le plus présent se compte sur la vague prévue, morts compris. | « Le type le plus présent dans la salle » ; stable quel que soit le moment de l'aggravation. | conforme |
| **D3.7-3** | **Une vague qui commence en Abandon reçoit son renfort aussitôt.** | Voir section 1. | conforme au GDD, **s'écarte de l'AC** |
| D3.7-4 | Les renforts retardent `room_cleared` (le renfort en attente compte comme vivant). | Sinon la vague serait « vidée » avant son dernier ennemi. | comble un manque |
| D3.7-6 | 4 marqueurs de renfort, un par coin éloigné, posés dans `arena.tscn`. | Le GDD prévoit des emplacements propres à chaque salle ; les salles de l'epic 4 les remplaceront. | conforme |
| D3.7-7 | Le signe est un cercle ambre qui se resserre sur 0,6 s, sans flash, avec un son dédié. | Lisibilité et photosensibilité ; le délai de 0,6 s est celui du GDD. | conforme |
| D3.7-9 | Le renfort ne compte pas dans `MAX_WAVE_ENEMIES` (12). | Plafond technique de la composition ; +1 reste dans la marge du pool de projectiles. | comble un manque |
| **D3.7-11**, **D3.7-13** | **Pas de renfort entre deux vagues ; un seul renfort par vague, pas par salle.** | Voir section 1. | **s'en écarte** |
| **D3.7-1** | **Seed de run de 40 bits (code de 8 caractères).** | Voir section 1. | **s'en écarte** (architecture) |

### Effets de l'Abandon à l'écran et à l'oreille (3.8)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D3.8-1 | Les distorsions suivent le palier en direct (pas `room_tier`). | « Les signes de la lucidité à l'écran » ; seuls danger et loot lisent `room_tier`. | conforme |
| D3.8-14 | Les anneaux et signes de combat restent à z 0 avec les entités ; seuls les projectiles ennemis sont à z 10. L'AC1 est lue comme « au-dessus de la copie déformée ». | Rien au-dessus de −1 n'est déformé ; un anneau d'Éveil à z 10 pourrait masquer des balles ennemies. | conforme |
| D3.8-15 (remplace D3.8-7 pour l'onde et l'aberration, et D3.8-9) | Valeurs par palier : onde 0 / 0,75 / 1,25 / 1,75 / 2,25 px, aberration 0 / 1 / 2 / 3 / 4 px, plafond photosensible 1 px. Coupure du passe-bas 20 500 / 8 000 / 4 000 / 2 000 / 1 000 Hz (D3.8-7). | L'arrondi entier rendait deux paliers voisins identiques ; l'AC demande une hausse visible à chaque palier. Placeholders à juger fenêtré. | comble un manque |
| D3.8-7 | Voir D3.8-15 pour l'onde et l'aberration ; la coupure du passe-bas garde la table de D3.8-7. | Placeholders croissants. | comble un manque |
| D3.8-4 | La photosensibilité prime sur les curseurs sans les modifier. | Le joueur retrouve ses réglages en la désactivant. | conforme |
| D3.8-9 | Photosensibilité : plafond en pixels (voir D3.8-15 : 1 px), pas une fraction. | L'onde et l'aberration sont déjà en pixels. | conforme |
| **D3.8-5**, D3.8-10 | **Le tremblement n'a qu'un consommateur : l'Éveil (1 à 2 px, 0,15 s).** L'amplitude est `round(pixels × réglage)` : rien à 0 % ni à 20 % ou moins. | Voir section 1. | **s'en écarte** (comble : le GDD ne dit pas d'où vient le tremblement) |
| D3.8-6 | Interpolation de 0,5 s entre paliers, filtre interpolé en échelle logarithmique. | Pas de saut brutal. | comble un manque |
| D3.8-16 | La musique reste étouffée derrière l'écran de réveil ; la relance repart filtre ouvert. | L'arène reste vivante derrière l'écran ; cohérent avec l'état figé du rêve. À juger. | comble un manque |
| D3.8-3 | Boucle musicale provisoire de 8 s, générée par script, lancée par `Audio`. | L'AC demande une boucle provisoire ; remplacée en 7.7. | comble un manque |

### Télémétrie (3.1)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D3.1-7 | Temps par palier en temps réel de session, pauses comptées. | Cohérent avec la durée de jeu de D2.8-5 ; sans effet à l'échelle d'un playtest. | comble un manque |
| D3.1-10 | La ligne INFO « time per tier » n'est écrite qu'à la mort ; une relance F1 ou une sortie ne laisse que l'événement `run_end`. L'issue de partie est reportée à 6.4. | La mort est la seule vraie fin de partie aujourd'hui. | comble un manque |
| D3.1-11 | La télémétrie suppose le palier Lucide au début de chaque partie. | « Joueur neuf », vrai avec le tuning actuel ; non traité par la 3.6, reporté avant le playtest du jalon A. | comble un manque |

---

## 3. À survoler

Rien de visible pour le joueur ici. Une ligne par sujet, tous les numéros concernés.

### Lucidité : jauge, bus, signatures

- Signal `Events.lucidity_value_changed(value, tier)` : le CA3 disait `(value)`, le code envoie aussi le palier (le HUD n'écoute que `Events`) : D3.1-3, D3.1-9.
- `Lucidity.gain(amount)` sans `source` ni plafond en 3.1 ; devient `gain(amount, source)` et renvoie le gain réel en 3.2 : D3.1-8, D3.2-4.
- `try_spend(cost, power)` avec le nom du pouvoir en argument facultatif ; palier journalisé = palier d'avant la dépense : D3.3-1, D3.3-2.
- Distance de graze mesurée du centre du projectile au rectangle de la hurtbox : D3.2-2.
- Gain de salle vidée porté par le joueur (écoute de `Events.room_cleared`) ; `Arena.begin_room()` appelé par `WaveRunner` : D3.2-5.
- Zone de graze en F2 : rectangle élargi aux coins carrés, via `Hurtbox.show_graze_zone(margin_px)` et le groupe `Const.GROUP_DEBUG_GRAZE` : D3.2-7, D3.2-9.
- Les sons de 3.2 sont générés par un script Python jetable non versionné : D3.2-10 (voir priorité).

### Glissement : résolution d'atterrissage

- Atterrissage par recul au pas de 1 px jusqu'à un point libre ; `Glide.resolve_destination` est une fonction statique pure, le trajet utile est mesuré avant la dépense : D3.4-2, D3.4-9.
- Obstacles : deux `TileSet` distincts (un par couche), cellules en constantes de `Arena` ; `_is_valid_spawn` refuse tout corps qui recouvre un obstacle (le test du corps géant les vide) : D3.4-11.

### Stats et danger

- Un palier = une source de modificateurs (l'objet `Lucidity`) ; `HURTBOX_SIZE` est une `Stat` du `StatBlock` : D3.5-5, D3.5-6.
- `StatBlock` en double précision, tests à 1e-12 ; la hurtbox de Lucide est un écart `ADD_FLAT` calculé depuis la base (combinaison avec les objets reportée à l'epic 5) : D3.5-9, D3.5-11.
- `DangerProfile` unique par salle, mutée sur place ; `Events.room_cleared(room, lowest_tier)` ; `F1 L` aggrave la salle en cours ; pas de modification de la Berceuse : D3.6-1, D3.6-5, D3.6-6, D3.6-8.
- `Lucidity.room_danger_raised(tier, previous)` à deux arguments ; `Enemy._start_telegraph_of` ; l'ancienne décision de signaler toute aggravation est remplacée par D3.6-12 : D3.6-9, D3.6-10, D3.6-11.

### Renfort et seed

- Distance de 3 tuiles testée au tirage puis recorrigée à l'apparition par `spawn_enemy` : D3.7-5.
- `is_nightmare` : booléen exporté, en attendant l'epic 6 : D3.7-8.
- `wave_defs` vide : aucun renfort ; tirages de l'égalité et de la place faits à l'annonce, dans cet ordre (déterminisme) : D3.7-10, D3.7-12.

### Rendu, réglages et sortie propre

- Décor = sols et murs ; copie déformée par un `ColorRect` à `z_index` −1 qui échantillonne l'écran ; décor à −2 : D3.8-2.
- Curseurs d'accessibilité de 0 à 100 % par pas de 5, comme les volumes : D3.8-8.
- `Audio._exit_tree` vide les lecteurs (la boucle ne finit jamais) ; `Telemetry._prune_old_sessions` prend un dossier en paramètre ; la 3.8 garde ces deux changements dans son diff : D3.8-11, D3.8-12, D3.8-18.
- `run_all.sh` ignore les avertissements de lecture de `Settings` de `t_lucidity_fx` : D3.8-13.
- Tâche « capture fenêtrée WSLg » cochée sans capture, l'aspect restant NON ÉVALUÉ : D3.8-17.

### Debug

- Touche F1 `L` : cycle de 5 valeurs de lucidité (100, 75, 50, 25, 0) : D3.1-6.

---

## 4. À juger en jouant

Ces points n'ont jamais été vus, entendus ni tenus en main par un humain (tests automatiques seulement, aucune capture fenêtrée en 3.8). Touches utiles : panneau `F1` (`1` invulnérable, `2` armure, `3` coup au joueur, `4` salve, `5` tir auto, `6` à `9` ennemis, `0` tue tout, `-` vague suivante, `L` fait défiler les valeurs de lucidité), `F2` collisions et zone de graze, `F3` perf et stats, `F4` ralenti, `F5` test de charge. Éveil : clic droit ou LT. Glissement : Maj gauche ou LB.

### Jauge et annonces de palier (`F1` puis `L`)
- Jauge de 160×8 px, couleurs de palier, repères, étiquette du nom : lisibles à l'échelle réelle ? Les deux sons de palier (descente et montée) s'entendent-ils et se distinguent-ils ? (D3.1-4, D3.1-5)
- Abandon total (jauge à 0) : le remplissage est vide, seuls l'étiquette et le son l'annoncent (reporté, 3.8).

### Graze et dash parfait (`F1` puis `5`, `F2` pour la zone)
- Rayon d'une tuile, +2 par graze, +5 par dash parfait, plafond de 20 : le gain se sent-il ? Le graze compté à l'éloignement (D3.2-8) paraît-il juste ?
- Les deux sons sont-ils audibles et distincts ? La zone jaune de `F2` est-elle lisible ?
- Le dash parfait est-il atteignable en réaction ? (D3.2-1, D3.2-12)
- Cas à noter : rattraper un projectile qui s'éloigne donne un graze puis un coup (rare).

### Éveil (clic droit ou LT, avec `F1` `3` et `7`/`9` pour créer du danger)
- Recul instantané de 2 tuiles, anneau, sons provisoires, recharge d'1 s. Le recul qui n'interrompt ni charge ni télégraphe (D3.3-3) et la Veilleuse qui reste fixe (D3.3-9) conviennent-ils ?
- Pas d'indicateur de recharge dans le HUD : le son de refus suffit-il ? (D3.3-6)
- LT sur manette réelle : une gâchette tenue autour du seuil peut déclencher plusieurs Éveils (NON VÉRIFIÉ).

### Glissement (Maj gauche ou LB)
- Distance, recharge d'1 s, invulnérabilité d'arrivée de 0,1 s (teinte), anneaux et son provisoires. Disposition des obstacles : des ennemis s'y coincent (limite connue, epic 4).
- Distance au stick droit (2 à 6 tuiles) sur manette réelle.
- Dash puis Glissement : la combinaison rembourse-t-elle trop de lucidité ? (D3.4-13)
- Maj sur Windows : cinq appuis rapides ouvrent la boîte « Touches rémanentes » (NON VÉRIFIÉ, Windows natif).

### Lucide : précision et dégâts (`F1` puis `L`, puis tire)
- Balles +30 % de vitesse, hurtbox de 4 px contre 6, dégâts 10 / 11 / 12 / 13,5 : la précision se sent-elle à l'écran ? Aucun bonus n'est affiché dans le HUD. (D3.5-1, D3.5-7)
- Les contacts ennemis à 14 px font toujours mal en Lucide, et pas trop en dehors. (D3.5-8)

### Danger de salle et renfort (`F1` puis `L` pour plonger, `7`/`8`/`9` pour les ennemis)
- Signal d'aggravation : son grave provisoire, anneau rouge de 2 tuiles, projectiles ×1,1 en Dérive, télégraphes ×0,85 en Abandon. Lisible, pas trop bavard ? (D3.6-4, D3.6-12)
- Une dépense pendant la pause entre deux vagues fait quand même plonger la salle et joue le signal.
- Renfort : cercle ambre de 0,6 s et son provisoire. Le délai laisse-t-il le temps de réagir, le renfort tombe-t-il dans le dos du joueur, les 4 marqueurs sont-ils bien placés ? (D3.7-6, D3.7-7)
- Renfort après aggravation tardive (un seul ennemi restant) : il retarde `room_cleared` de 0,6 s ; trop punitif ?

### Effets de l'Abandon (`F1` puis `L`, fenêtré)
- Onde et aberration du décor à chaque palier (ondulation 0 / 0,75 / 1,25 / 1,75 / 2,25 px, aberration 0 à 4 px), passe-bas de la musique (20 500 à 1 000 Hz), boucle musicale provisoire, tremblement d'Éveil. (D3.8-5, D3.8-7, D3.8-15)
- Lisibilité des balles et des télégraphes en Abandon total, mode photosensibilité, curseurs de réglages.
- Coût de la copie d'écran (`hint_screen_texture`) : 60 FPS en `F3` ?
- Musique encore étouffée derrière l'écran de réveil. (D3.8-16)

### Manette réelle et Windows
- Stick droit, LT (Éveil), LB (Glissement), distance au stick : jamais essayés avec une vraie manette.
- Touches rémanentes de Windows sur Maj.

---

## 5. Actions qui te reviennent

1. **Stories 1.7 (réassignation des touches, invites par périphérique) et 1.8 (export, latence, relance en moins de 3 s)** : à faire avant le playtest du jalon A. 7.1 (cohérence des graphismes IA) aussi, avant que des amis jouent.
2. **Mesure de 10 minutes à 400 projectiles** (story 1.2, reportée depuis l'epic 2). Sur la machine de référence : `F5` lance le test de charge, `F3` affiche la perf. Cible du GDD : 60 FPS soutenus, 1 % low d'au moins 55. Toujours pas faite.
3. **Télémétrie chez tes amis : ni avertissement ni option pour la couper.** Aucun texte ne dit qu'un fichier est écrit. À prévoir pour le build du jalon A : une ligne dans le README livré (où trouver les fichiers, quoi te renvoyer), voire un réglage de désactivation. Contenu actuel : horodatage local et compteurs, aucune donnée personnelle.
4. **Fichiers de télémétrie de test à nettoyer.** `~/.local/share/godot/app_userdata/Hypnagogia/telemetry/` contient 100 fichiers issus des tests automatiques (le plafond de 100 sessions les garde). À vider avant de lancer une vraie session de mesure pour ne pas les mélanger.
5. **Optionnel : `gds-retrospective` pour l'epic 3**, avec deux sujets : aligner ou extraire `power.gd` (section 1), et passer la seed à 64 bits ou corriger l'architecture (D3.7-1).

# Epic 2 : décisions prises sans toi, à valider

Pendant l'epic 2 (stories 2.1 à 2.8), 167 décisions ont été prises sans toi. Elles sont toutes notées dans la section « Décisions prises sans Kroustille » de chaque story. Ce document les trie pour que tu puisses valider vite.

**Comment répondre :** réponds avec les numéros à changer et ce que tu veux à la place ; tout le reste est validé. Exemple : « D2.5-4 : le joueur ne traverse pas le Mouton ; D2.6-2 : 4 vagues ».

Lecture d'un numéro : `D2.3-6` = story 2.3, décision 6.

Colonne « GDD ? » : **conforme** (le GDD dit déjà la même chose), **comble un manque** (le GDD ne dit rien, on a choisi), **s'en écarte** (le GDD dit autre chose).

Plan :
1. À regarder en priorité (ce que le joueur ressent).
2. À survoler (technique, une ligne par sujet).
3. À juger en jouant (ce qui n'a jamais été vu ni entendu par un humain).
4. Actions qui te reviennent.

---

## 1. À regarder en priorité

**Une seule décision s'écarte du GDD : D2.5-4** (la charge du Mouton traverse le joueur). Elle est en gras dans le tableau « Le Mouton ».

### Santé et coups reçus

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D2.1-1 | Le joueur a des cœurs max (6 demi-cœurs au départ, fixes). Le soin monte jusqu'aux cœurs max. Le plafond de 12 cœurs compte cœurs max + armure. | Le GDD parle de « −1 cœur max » (Dent qui tombe) et d'un cœur de boutique qui « soigne ». | conforme |
| D2.1-16 | Le sprite clignote pendant l'invulnérabilité : 0,1 s visible, 0,1 s caché (5 clignotements par seconde). | Le GDD ne donne pas de cadence. | comble un manque |
| D2.1-17 | Son de coup grave et provisoire (220 vers 90 Hz, 0,15 s). | Le GDD exige un son ; tu avais trouvé le son de tir trop aigu. | comble un manque |
| D2.3-4 | Les dégâts de contact sont ceux du réglage de combat (½ cœur aux étages 1 et 2), pas une valeur propre à chaque ennemi. | Le coup dépend de l'étage, pas de l'ennemi. | conforme |
| D2.4-9 | Les deux tireuses font aussi ½ cœur au contact. | Le GDD dit que les ennemis font des dégâts au contact. | conforme |

### Le Somnambule

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D2.3-5 | Il s'arrête de marcher pendant les 0,4 s où il lève les bras. | À 2,5 tuiles/s il toucherait le joueur avant la fin de l'annonce. | comble un manque |
| D2.3-6 | Pendant l'accélération (5 tuiles/s, 0,6 s), il continue de viser le joueur. On s'échappe en fuyant ou en dashant (le joueur va à 6). | Le Mouton charge en ligne droite, le Somnambule doit rester différent. | conforme |
| D2.3-7 | Aucune récupération après l'accélération. Si tu restes à moins de 2 tuiles, il relève les bras aussitôt. | Le GDD n'en donne pas ; les 0,4 s d'annonce servent de répit. | comble un manque |
| D2.3-33 | Pendant l'accélération, au contact, il pousse le joueur (≈ 13 px par accélération). Non corrigé. | C'est un ressenti à juger avec toi ; sans conséquence tant qu'il n'y a pas de trous. | comble un manque |
| D2.3-10 | Les ennemis se bloquent entre eux et contre les murs ; le joueur est bloqué par les ennemis, même en dash. | Le dash ne traverse pas les ennemis (GDD) ; des ennemis empilés cacheraient leur nombre. | conforme |
| D2.3-11, D2.3-30, D2.4-19, D2.5-11 | Tailles provisoires, les mêmes pour les 4 ennemis : corps 10×10 px, hurtbox 12×20 px, contact 12×12 px, sprite 16×24 (corps dessiné de 8 px de large). | Le GDD ne donne aucune taille ; une seule chose à juger. | comble un manque |

### La Veilleuse et la Berceuse

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D2.4-3 | La lueur s'inscrit dans le cycle : la Veilleuse tire bien toutes les 2 s (Berceuse 1,5 s). Première lueur un cycle complet après l'apparition. | « Toutes les 2 s, elle tire » dit le GDD ; le répit à l'apparition est un plus. | conforme |
| D2.4-4 | Elle vise le joueur au moment du tir (pas au début de la lueur). L'éventail fait 20° entre deux projectiles voisins (40° au total). | Lecture littérale du GDD ; viser au départ de la lueur la rendrait inutile. | conforme |
| D2.4-5, D2.4-6 | La Berceuse est immobile pendant l'inspiration. Sa vitesse est de 2 tuiles/s (le joueur : 6, le Somnambule : 2,5). | Une attaque annoncée l'est par un ennemi qui se fige ; le GDD ne donne pas la vitesse. | comble un manque |
| D2.4-8 | Les tireuses tirent à toute distance, sans ligne de vue. | Pas d'obstacle avant l'epic 4. | comble un manque |
| D2.4-10, D2.4-11, D2.4-12 | Tous les projectiles ennemis ont la même apparence : rose vif à contour lie-de-vin, disque de 8 px (rayon 0,25 tuile), durée de vie 10 s. | Le GDD veut des projectiles ennemis à couleur et contour exclusifs ; une seule apparence rend la règle vraie par construction. | conforme |
| D2.4-17, D2.5-12 | Pas de son de tir. Un seul son par ennemi : celui du télégraphe (grattage pour le Mouton). | Le GDD n'exige que le son du télégraphe ; le reste viendra en 7.7. | comble un manque |

### Le Mouton

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D2.5-1 | Cycle : repos 1 s, grattage, recul, charge, étourdissement, repos. Il attaque à toute distance. Le repos de 1 s est provisoire. | Le GDD ne parle pas du repos ; un chargeur traverse la salle. | comble un manque |
| D2.5-2 | La charge part dans une direction figée au début du grattage. | Lecture littérale de « vers la position du joueur au moment du télégraphe ». | conforme |
| D2.5-3 | Le recul se fait à 2 tuiles/s (0,25 s) après le grattage de 0,5 s : l'annonce dure 0,75 s en tout. | Le GDD ne donne pas la vitesse ; le 0,5 s d'annonce est respecté. | comble un manque |
| **D2.5-4** | **Pendant une charge, le joueur (à pied ou en dash) traverse le Mouton, et lui le joueur. C'est une exception locale à « le dash ne traverse pas les ennemis ».** | Sinon le joueur serait poussé à chaque tick par la récupération de collision. | **s'en écarte** |
| D2.5-6, D2.5-9 | Seul un mur étourdit (1 s). Contre un autre ennemi, la charge s'arrête sans étourdir. Pas de bonus de dégâts pendant l'étourdissement. | Le GDD dit « un mur » ; 1 s d'étourdissement = 4 tirs, soit 40 des 50 PV. | conforme |
| D2.5-8 | Le coup de la charge est un simple contact : ½ cœur, pas de coup lourd. | Les coups lourds sont réservés aux cauchemars. | conforme |

### Vagues

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D2.6-2 | 6 vagues de 2 à 7 ennemis, mélange des types, première vague après 1 s, pause de 2 s entre vagues. Tout est dans `data/waves/arena_waves.tres`. | Le GDD ne donne ni liste ni durée (≈ 45 s par salle, soit 2 à 3 vagues) ; 6 vagues servent l'entraînement sans fin. | comble un manque |
| D2.6-5 | Les télégraphes simultanés partagent un plafond de 3 voix : le 4e son est muet. | Des sons identiques en même temps n'ajoutent que du volume ; l'animation annonce chaque attaque. | comble un manque |

### HUD

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D2.7-3 | Cœurs rouges à gauche, puis l'armure sur la même rangée : 1 point = ½ cœur bleu, 2 = un cœur bleu. 12 icônes au plus. | Le GDD donne le plafond de 12 et l'armure en demi-cœurs bleus. | conforme |
| D2.7-4 | Éclats : « 0 » fixe. Emplacements d'objet actif et de consommable : cadres vides, sans touche affichée. | Monnaie et objets arrivent avec l'epic 5. | comble un manque |
| D2.7-5 | La place de la jauge de lucidité est un cadre vide de 160×8 px au centre de la bande. | La 3.1 la remplira ; le GDD met la jauge dans le HUD. | conforme |
| D2.7-6 | Quand tu es touché, la rangée de cœurs flashe en blanc 0,25 s. Rien d'autre (pas d'écran rouge). | Suffisant pour lire le coup ; jugement en combat encore à faire. | comble un manque |
| D2.7-10 | Le réticule ne s'affiche jamais sous la bande de HUD (il y était caché derrière). Seul l'affichage est borné, la visée reste celle de la souris. | Sans cela le joueur n'avait plus de viseur au-dessus de y = 24. | comble un manque |

### Mort et relance

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D2.2-7 | L'écran de réveil attend le joueur (pas de relance automatique). « Moins de 3 s » = garde de 0,3 s + chargement, si tu relances aussitôt. | La 2.8 y pose une question et la 6.5 y rattachera la chambre. | conforme |
| D2.2-9 | Garde de 0,3 s avant d'accepter une relance. | Espace (dash) est aussi « valider » ; un clic tenu à la mort ne doit pas passer l'écran. | comble un manque |
| D2.2-10 | Deux façons de relancer : touche R, ou bouton « Se rendormir (R) » (Entrée, Espace, clic, A manette). | R est libre dans le GDD ; la réassignation viendra avec la 1.7. | comble un manque |
| D2.2-8 | Derrière l'écran, la partie est figée : pause, F4, F5 et commandes F1 sont ignorées. | Un mort ne doit plus rien subir ; la pause rouvrirait la partie. | comble un manque |
| D2.2-11 | À la mort, le sprite du joueur disparaît et le joueur s'arrête. Pas d'animation de mort. | Repère provisoire derrière un fond semi-transparent ; l'animation arrive à l'epic 7. | comble un manque |

### Question de fin de run et télémétrie (builds d'amis)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D2.8-1, D2.8-2 | La question « mort juste ? » est deux boutons Oui / Non sur l'écran de réveil, sans touche dédiée. On répond une seule fois, et répondre ne relance pas. Le focus reste sur la relance : Entrée sans répondre = « pas de réponse ». | Le GDD veut une question après chaque mort ; elle ne doit pas ralentir la relance. | conforme |
| D2.8-7 | Taux de oui = oui / (oui + non). Les absences de réponse sont comptées à part. | Le GDD cible 80 % de oui ; les non-réponses ne doivent pas fausser le taux. | conforme |
| D2.8-3 | La cause de la mort est le type de la dernière source de dégâts (`enemy_bullet`, `contact`…), sans savoir quel ennemi. | Le signal ne porte que la source ; l'enrichir attend un besoin réel. | comble un manque |
| D2.8-5 | La durée de jeu est le temps réel de la session, pauses comprises. | Simple et suffisant pour le playtest. | comble un manque |
| D2.8-9 | Le jeu garde les 100 sessions de télémétrie les plus récentes dans `user://telemetry/`. | Évite que le dossier gonfle chez tes amis, sans couper la télémétrie en headless. | comble un manque |

### Touches et contrôles

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D2.1-13 | Panneau F1 : commandes aux touches 1 à 5, lues en position physique du clavier, pas de boutons. | Le curseur est caché en jeu ; touches libres dans le GDD ; outil de debug. | comble un manque |
| D2.6-4, D2.6-12 | F1 : 6 à 9 font apparaître un ennemi, 0 tue tout, `-` passe à la vague suivante (touche `-` du pavé numérique, ou position QWERTY du `-` ; sur AZERTY c'est la touche `)`). | Pas de sélecteur d'ennemi : la touche est déjà le choix ; la position physique évite le conflit avec la touche 6. | comble un manque |
| D2.2-10 | (voir « Mort et relance ») R pour relancer ; pas d'événement manette pour R, A presse le bouton focalisé. | Invites par périphérique : story 1.7. | comble un manque |

---

## 2. À survoler

Rien de visible pour le joueur ici. Une ligne par sujet, tous les numéros concernés.

### Architecture : santé, coups, signaux

- Santé du joueur en demi-cœurs entiers dans `Health` (armure dedans, pas de `Armor` séparée), réglages dans `CombatTuning` ; PV ennemis flottants à part dans `HitPoints` : D2.1-3, D2.1-4, D2.1-5, D2.1-6, D2.3-1.
- Un ajout partiel sous le plafond ajoute ce qui tient et renvoie `true` : D2.1-2.
- Un coup se refuse via un filtre de hurtbox (`set_hit_filter`), puis `refuse_hit()` côté propriétaire : D2.1-7, D2.3-2.
- Un seul coup par tick sur le joueur ; cas résiduel accepté (un projectile perdu si deux cibles meurent au même tick) : D2.1-8, D2.1-10.
- Ordre de traitement : les `BulletManager` passent après les entités (priorité 100) ; contact par `Hitbox` testée à la main (priorité 50) : D2.1-9, D2.3-3.
- Signal `Events.player_hit(damage, source)` ; `Events.run_ended(outcome)` avec `Outcome.DEATH = 0`, écouté par `Main` : D2.1-18, D2.2-4, D2.2-5.
- Ordre du coup mortel : changed, player_hit, run_ended, died (écart à la lettre du CA accepté, documenté) : D2.2-6, D2.2-20.
- La mort « minimale » de 2.1 est remplacée par celle de 2.2 : D2.1-11, D2.2-18.
- Les décisions de 2.1 à 2.4 restent valables pour les stories suivantes : D2.3-26, D2.4-22, D2.5-19.
- Dégâts ennemis < 0,5 reportés à la 2.4 ; contrat de dégâts tenu dans `fire()` par camp (refus avec `Log.error` + `assert`) ; dégâts joueur à 0 reporté : D2.1-24, D2.4-14, D2.4-30.

### Architecture : partie, arène, écrans

- `Run` > `Player`, `RoomSlot` > arène ; l'arène reçoit le joueur par `Arena.setup(player)` ; `Floor` et `Walls` en z_index −1 : D2.2-1, D2.2-2, D2.2-3.
- `Transition` vide ; cache des ressources par `preload` en chaîne : D2.2-12, D2.2-14.
- Au redémarrage : l'ancien `Run` est retiré avant le dégel ; une arène sans `setup()` ne plante pas : D2.2-21, D2.2-22.
- Garde de 0,3 s comptée en ticks bruts (risque d'à-coup renvoyé à la mesure 1.8) : D2.2-23.
- Libellé de touche par `as_text_physical_keycode()` : D2.2-16.
- Pas de seed dans « run started » (le RNG de run n'existe pas avant l'epic 4) : D2.2-15.

### Architecture : ennemis

- `EnemyDef` commun + une sous-classe par ennemi ; défauts neutres à 0 pour signaler un oubli : D2.3-12, D2.3-32.
- `Enemy.setup(def, target, target_hurtbox, bullets)` ; `ShooterDef` + `ShooterEnemy` pour les deux tireuses : D2.3-13, D2.4-1, D2.4-2.
- Pas de classe `Room` (`spawn_enemy()` dans `Arena`), pas de pool d'ennemis, compte des vivants par `tree_exited` : D2.3-14, D2.3-18, D2.3-20.
- Coordonnées de `spawn_enemy()` = coordonnées de la salle ; groupe `room` pour que F1 trouve la salle : D2.3-17, D2.3-24.
- Mort d'un ennemi : disparition immédiate, aucun signal : D2.3-19.
- `Telegraph` est un nœud qui tique seul, avec `progress()` pour la lueur ; les projectiles survivent à leur tireuse : D2.3-21, D2.4-18, D2.4-16.
- Tests de distances : centre à centre, strictement sous 2 tuiles pour déclencher, strictement sous 3 pour refuser l'apparition ; un tick sans mouvement à chaque transition : D2.3-8, D2.3-9.
- Bande 4 à 8 tuiles de la Berceuse bornes comprises, ligne directe ; origine de tir dans un mur : tir refusé sans log : D2.4-7, D2.4-15.
- Apparition déterministe : point repoussé à 3 tuiles, puis coins, zone valide inclusive, borné à la zone d'abord ; `min_spawn_distance` et `min_telegraph` dans `CombatTuning` : D2.3-15, D2.3-16, D2.3-28, D2.3-31.
- Mouton : direction hors cible (`_move_in_direction`) ; exception de collision levée quand les corps ne se chevauchent plus ; mur reconnu par couche de collision ; pas d'annulation de télégraphe ni de durée max de charge ; cible perdue en charge = la charge continue : D2.5-5, D2.5-7, D2.5-14, D2.5-16, D2.5-17.
- Noms d'ennemis `<id>_<n>` avec un compteur par salle : D2.5-13.
- Apparences et couleurs : une seule apparence réservée sans doublon ; couleurs provisoires dans `Const` avec contrôle de distance ≥ 0,2 ; couleurs décalées pour éviter les nombres du GDD ; projectiles ennemis en z_index 10 sous le réticule : D2.4-10 (voir priorité), D2.4-13, D2.4-26, D2.4-29.

### Architecture : vagues et HUD

- `WaveRunner` enfant de l'arène, liste en `WaveList` (`.tres`), points d'apparition fixes sans RNG : D2.6-1, D2.6-3.
- `room_cleared(room)` sans palier de lucidité pour l'instant, jamais émis après `run_ended` ; F1 « vague suivante » ne l'émet pas : D2.6-6, D2.6-8, D2.6-11.
- `Arena.waves_enabled` statique pour couper les vagues dans les scènes de test ; le compte à rebours suit l'horloge ennemis ; une vague où rien n'apparaît est sautée ; la ligne d'état F1 affiche `pause` : D2.6-7, D2.6-9, D2.6-10, D2.6-13.
- Signal `Events.player_health_changed` ; icônes dessinées en code ; réticule reste enfant du joueur ; panneau F1 et surcouche F3 décalés sous la bande ; HUD non masqué pendant F5 : D2.7-1, D2.7-2, D2.7-7, D2.7-8, D2.7-9, D2.7-11.

### Architecture : télémétrie

- Fichier réécrit en entier à chaque événement ; identifiant de session = date/heure + identifiant de processus ; la mort sans réponse à la fermeture compte comme « pas de réponse » ; issue de `run_ended` ignorée jusqu'à 6.4 ; échec d'écriture journalisé en catégorie `save` ; focus initial sur la relance maintenu : D2.8-4, D2.8-6, D2.8-8, D2.8-10, D2.8-11, D2.8-12, D2.8-13.

### Validation des données invalides

- Valeur invalide : état sûr posé avant l'assert, `_assert_failed()` pour les retours ; `Enemy` incomplet (cible ou `Def` manquante) désactivé : D2.3-27, D2.3-29.
- Tireuse qui ne peut jamais tirer = inerte (pas d'annonce sans tir) ; `fire_interval` invalide : cycle sans fin ; vitesse de projectile invalide ; bande de Berceuse invalide : elle ne bouge pas : D2.4-23, D2.4-24, D2.4-25, D2.4-27.
- Mouton : `charge_speed` invalide = inerte ; repos, recul, étourdissement invalides bornés à 0 : D2.5-10.
- `fire_interval` ≤ durée du télégraphe non validé (reporté, inatteignable avec les `.tres`) : D2.4-28.

### Debug, tests, logs

- Panneau F1 instancié par `Main` ; « −½ cœur » = un vrai coup (source `DEBUG`) ; émetteur de test en haut de l'arène (salve de 3, tir auto à 4/s) ; tir auto conservé d'une partie à l'autre ; manager trouvé par `has_hurtbox()` : D2.1-12, D2.1-14, D2.1-15, D2.2-13, D2.2-19.
- Touches F1 d'ennemis : 6 Somnambule, 7 Veilleuse, 8 Berceuse, 9 Mouton ; l'arène reste vide au lancement : D2.3-25, D2.4-20, D2.5-18.
- Clignotement dérivé du compteur de `Health` ; accesseurs en lecture seule ; contrôles du dash au premier tick : D2.1-20, D2.1-21, D2.1-22, D2.1-23.
- Scènes de vérification de 2.3 perdues par un redémarrage : à réécrire (pas un blocage) : D2.3-34.
- Journalisation : un seul `INFO` par mort ; `Log.debug` par salve et par fin de charge ; pas de log hors jalons : D2.2-17, D2.4-21, D2.5-15.
- Sons et visuels provisoires du Somnambule (son montant 0,35 s, textures générées par script) : D2.3-22, D2.3-23.
- Mesure de 10 minutes à 400 projectiles non faite (voir section 4) : D2.1-19.

---

## 3. À juger en jouant

Ces points n'ont jamais été vus ni entendus par un humain (tests automatiques et captures WSLg seulement). Panneau F1 : `1` invulnérable, `2` armure, `3` coup au joueur, `4` salve, `5` tir auto, `6` Somnambule, `7` Veilleuse, `8` Berceuse, `9` Mouton, `0` tue tout, `-` vague suivante (pavé numérique, ou `)` sur AZERTY). `F2` collisions, `F3` perf, `F4` ralenti, `F5` test de charge 400 projectiles.

### Quand tu es touché
- `F1` puis `3` (ou laisse la Veilleuse te tirer dessus avec `7`). Regarde : le clignotement à 5 par seconde est-il lisible ? Le réticule reste-t-il visible ? Le son de coup grave est-il bon ? (D2.1-16, D2.1-17)
- Le flash blanc de 0,25 s sur les cœurs suffit-il en plein combat ? Les icônes de 8×7 px sont-elles assez grandes et contrastées à l'échelle réelle ?
- Touche `1` pour tester l'invulnérabilité, `5` pour une pluie de projectiles.

### Somnambule (`F1` puis `6`)
- Le télégraphe de 0,4 s (bras levés + son montant) se lit-il ? (D2.3-5)
- L'accélération qui continue de te viser (D2.3-6), l'absence de récupération (D2.3-7), la poussée au contact (D2.3-33) : plaisir ou frustration ?
- Contact : corps qui se bloquent, un coup par seconde tant que tu restes collé, dash invulnérable sur le contact.
- Tailles provisoires et silhouette de 8 px : assez lisibles à côté du joueur ? (D2.3-11, D2.3-30)
- Pas encore capturés à l'écran : ennemi dessiné sous les projectiles, chiffre de dégâts, recul à l'écran, F2 sur les tireuses.

### Veilleuse et Berceuse (`F1` puis `7`, puis `8`)
- La lueur de la Veilleuse (halo discret à 640×360) et l'inspiration de la Berceuse se lisent-elles en mouvement ? Les sons (500 vers 1000 Hz ; 180 vers 260 Hz) ?
- Éventail de 20° à 5 tuiles/s : esquivable ? Période de 2 s et de 1,5 s : bonne ? (D2.4-3, D2.4-4)
- Berceuse : vitesse de 2 tuiles/s, bande 4 à 8 tuiles, comportement dans un coin, immobilité pendant l'inspiration, absence de son de tir. (D2.4-5, D2.4-6)
- Projectiles ennemis : couleur rose vif et contour, disque de 8 px, bien distincts du tir du joueur ? (D2.4-10 à D2.4-12)

### Mouton (`F1` puis `9`)
- Esquive d'une charge à 10 tuiles/s : annonce 0,5 s + recul 0,25 s, est-ce assez ? Le repos de 1 s ? (D2.5-1, D2.5-3)
- Punir contre un mur : 1 s d'étourdissement = 4 tirs, est-ce satisfaisant ? Arrêt sans étourdissement contre un ennemi ? (D2.5-6)
- Traverser un Mouton qui charge, à pied ou en dash : accepté ou bizarre ? (D2.5-4, la seule décision hors GDD)
- Son de grattage, tailles et textures provisoires.
- Rien n'a été capturé à l'écran pour le Mouton : grattage, recul, charge tête baissée, étourdi, F2.

### Vagues (lance le jeu, ou `-` pour passer à la vague suivante)
- Contenu des 6 vagues (2 à 7 ennemis), 1 s avant la première, 2 s de pause : rythme, difficulté de la boucle sans fin, lisibilité de 6 ennemis à l'écran. Tout se règle dans `data/waves/arena_waves.tres`. (D2.6-2)
- Plusieurs télégraphes ensemble (vague de Somnambules ou de Moutons) : le 4e son muet se remarque-t-il ? (D2.6-5)
- Apparition de 6 ennemis, enchaînement visuel, ligne `wave N` du panneau F1 : jamais vus en fenêtré.

### Mort et relance
- Meurs, puis relance tout de suite : le rythme mort, écran de réveil, nouvelle partie est-il bon ? La garde de 0,3 s est-elle trop longue ou trop courte ? Le sprite qui disparaît est-il un repère suffisant ? (D2.2-9, D2.2-11)
- Titre « Tu te réveilles. », bouton « Se rendormir (R) » : lisibles à l'œil ?
- Relance en moins de 3 s sur la machine de référence et en export : non vérifiée (voir section 4).

### Question de fin de run
- Boutons Oui / Non : taille, lisibilité, tentation de répondre au lieu de relancer, navigation clavier ou manette entre Oui, Non et la relance. À voir au premier playtest avec tes amis. (D2.8-1)
- Écriture de `user://telemetry/` sur un build exporté Windows (chemin réel, droits) : non vérifiée.

### Manette, 144 Hz, Windows (reportés depuis l'epic 1)
- Avec une vraie manette : stick gauche, stick droit, RT, RB (dash), Start et B (pause), bouton A sur l'écran de réveil.
- Écran 144 Hz : les projectiles saccadent-ils ? Plein écran et VSync sous Windows natif.
- Ressenti du déplacement, du dash et du tir (valeurs de départ jamais jugées).

---

## 4. Actions qui te reviennent

1. **Mesure de 10 minutes à 400 projectiles** (story 1.2, reportée « avant le combat ennemi »). Sur la machine de référence : `F5` lance le test de charge, `F3` affiche la perf. Cible du GDD : 60 FPS soutenus, 1 % low d'au moins 55. Cette mesure a été rappelée en D2.1-19 et n'a pas été faite.
2. **Stories 1.7 (réassignation des touches, invites par périphérique) et 1.8 (latence, mesure d'export, relance en moins de 3 s)** : à faire avant le playtest du jalon A.
3. **Optionnel : `gds-retrospective`** pour la rétrospective de l'epic 2.

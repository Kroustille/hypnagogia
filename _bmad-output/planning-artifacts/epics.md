---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - '_bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md'
  - '_bmad-output/game-architecture.md'
  - '_bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/epics.md'
  - '_bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/decision-log.md'
---

# hypnagogia : découpage en epics et stories

## Vue d'ensemble

Ce document découpe en epics et en stories prêtes à implémenter les exigences du GDD et de l'architecture de Hypnagogia. Il n'existe pas de document UX : les exigences d'interface viennent du GDD.

**Périmètre du découpage** : les jalons A (le combat) et B (le MVP). Les exigences du jalon C (l'acte 1) sont seulement listées, sans être découpées : elles le seront après la validation du jalon B.

**Notation** : `[A]` jalon A, `[B]` jalon B. Toutes les valeurs numériques sont des valeurs de départ, que le playtest viendra régler.

**Règles transverses** : toute story respecte NFR9 et AR9 (aucune valeur de gameplay en dur), NFR10 (textes localisés), AR32 (conventions de nommage et lexique), ainsi que les règles de cohérence de l'architecture (temps, aléatoire, logs, apparitions). Une revue de code les vérifie, même si la story ne les cite pas.

## Inventaire des exigences

### Exigences fonctionnelles

**Contrôles et sensations**

- FR1 `[A]` : le joueur se déplace en 8 directions à 6 tuiles/s. Il atteint sa vitesse maximale en 0,06 s et s'arrête en 0,04 s.
- FR2 `[A]` : la hitbox du joueur fait 6×6 px, centrée sur le torse d'un sprite de 16×24.
- FR3 `[A]` : le dash parcourt 3 tuiles en 0,18 s. Il rend invulnérable pendant ses 0,15 premières secondes, se recharge 0,6 s après sa fin et accepte un tampon d'entrée de 0,1 s. Le joueur ne peut pas tirer pendant un dash.
- FR4 `[A]` : le dash traverse les projectiles, mais ni les murs ni les ennemis. Il ne survole un trou que s'il le franchit entièrement.
- FR5 `[A]` : le tir est libre, à la souris ou au stick droit. Il inflige 10 dégâts, à 4 tirs/s et 14 tuiles/s, avec une hitbox de 4×4 px. Sa portée est illimitée : il file jusqu'à un mur ou un ennemi, sans dispersion ni coup critique. C'est toujours un projectile visible, jamais du hitscan.
- FR6 `[A]` : chaque tir a son retour, et chaque impact aussi :
  - au tir : le sprite recule de 1 px pendant 0,05 s, et un son court se joue ;
  - à l'impact : l'ennemi touché flashe en blanc pendant 0,05 s et recule de 2 px.
  Les chiffres de dégâts sont désactivés par défaut.
- FR7 `[A]` : les contrôles par défaut suivent le tableau du GDD, au clavier-souris et à la manette (disposition Xbox). Toutes les touches sont réassignables.
- FR8 `[A]` : le jeu bascule automatiquement entre clavier-souris et manette, selon le dernier périphérique utilisé.
- FR9 : la caméra dépend de la taille de la salle :
  - `[A]` salle d'un écran : la caméra est fixe et centrée ;
  - `[B]` grande salle (deux écrans) : la caméra suit le joueur, bornée par les limites de la salle.
- FR10 `[A]` : le jeu propose une pause.

**Santé et mort**

- FR11 `[A]` : le joueur commence avec 3 cœurs (6 demi-cœurs). Le plafond est de 12 cœurs, armure comprise.
- FR12 `[A]` : un coup retire ½ cœur aux étages 1 et 2. À partir de l'étage 3, et pour les attaques lourdes des cauchemars, il retire 1 cœur. Les ennemis infligent aussi des dégâts au contact.
- FR13 `[A]` : après un coup, le joueur est invulnérable pendant 1,0 s. Un clignotement du sprite et un son le signalent.
- FR14 `[A]` : l'armure est une couche de demi-cœurs bleus, perdue avant les cœurs. Elle ne se soigne pas et ne se regagne qu'en la ramassant. Au plafond de 12 cœurs, l'armure reste au sol.
- FR15 `[A]` : à 0 cœur, le personnage se réveille et la run est perdue. Une nouvelle run démarre en moins de 3 s, et l'écran du réveil peut se passer.

**Lucidité à deux pôles**

- FR16 `[A]` : la jauge de lucidité compte 100 points. Elle est pleine au début de chaque run et reste bornée entre 0 et 100 : les gains au-delà de 100 sont perdus.
- FR17 `[A]` : la jauge a 5 paliers :

  | Palier | Lucidité |
  |---|---|
  | Lucide | 100 à 76 |
  | Flottant | 75 à 51 |
  | Dérive | 50 à 26 |
  | Abandon | 25 à 1 |
  | Abandon total | 0 |

- FR18 `[A]` : les récompenses suivent la jauge en direct :
  - Lucide : la précision, c'est-à-dire des tirs 30 % plus rapides et une hitbox du joueur réduite à 4×4 ;
  - Flottant : +10 % de dégâts ;
  - Dérive : +20 % de dégâts ;
  - Abandon et Abandon total : +35 % de dégâts.

  Les bonus en pourcentage s'additionnent entre eux, objets compris, puis s'appliquent aux dégâts de base.
- FR19 `[A]` : le danger dépend du palier le plus bas atteint dans la salle :
  - Dérive : les projectiles ennemis vont 10 % plus vite ;
  - Abandon : en plus, un renfort apparaît (une copie du type d'ennemi le plus présent), et les télégraphes durent ×0,85, jamais moins de 0,4 s. Le renfort apparaît sur un emplacement de renfort, annoncé 0,6 s avant. Il n'y en a qu'un par salle, et jamais dans la salle d'un cauchemar ;
  - Abandon total : en plus, les cauchemars gagnent un pattern.

  Passer sous un palier en pleine salle applique aussitôt son danger, signalé par un son et un effet. Remonter ne l'allège qu'à l'entrée de la salle suivante. Dans l'arène, le danger est remis à zéro à chaque vague.
- FR20 `[B]` : le multiplicateur de loot dépend du palier le plus bas atteint dans la salle : ×1,25 en Flottant, ×1,5 en Dérive, ×2 en Abandon. Il s'applique aux Éclats et à la chance de drop.
- FR21 `[A]` : la lucidité ne baisse que par les choix du joueur : les pouvoirs, et les objets ou consommables qui affichent ce coût. Les coups ne la touchent jamais. Une dépense que la jauge ne couvre pas est refusée : un son de refus retentit, et rien n'est consommé.
- FR22 `[A]` : la lucidité se regagne de trois façons :
  - le graze (+2) : un projectile ennemi passe à moins d'une tuile de la hitbox sans la toucher. Il compte une seule fois par projectile, jamais pendant une invulnérabilité, et rapporte au plus +20 par salle ;
  - le dash parfait (+5) : l'invulnérabilité du dash évite un projectile qui aurait touché. Pour ce projectile, il remplace le graze ;
  - la salle vidée (+5).
- FR23 `[A]` : Éveil coûte 30 de lucidité et se recharge en 1 s. Il efface tous les projectiles ennemis à l'écran et repousse de 2 tuiles les ennemis situés à moins de 3 tuiles.
- FR24 `[A]` : Glissement coûte 20 de lucidité et se recharge en 1 s.
  - Il téléporte le joueur vers le point visé, à 6 tuiles au plus, à travers les projectiles et les obstacles bas. Le joueur est invulnérable 0,1 s à l'arrivée.
  - Si le point visé est dans un mur, un obstacle haut ou un ennemi, le joueur arrive au dernier point libre sur la ligne de visée. Glissement ne franchit ni les murs de la salle ni les portes fermées.
  - Un trou est une destination valide : le joueur y tombe.
  - À la manette, la distance suit l'inclinaison du stick droit, de 2 à 6 tuiles.
- FR25 `[A]` : la lucidité se voit et s'entend :
  - la jauge figure dans le HUD ;
  - l'aberration chromatique et l'ondulation du décor augmentent avec les paliers ;
  - un filtre passe-bas étouffe la musique ;
  - un son marque chaque changement de palier.

**Ennemis et arène**

- FR26 `[A]` : toute attaque (tir, charge, accélération) est annoncée par une animation et un son au moins 0,4 s avant, y compris en Abandon. Le contact n'est pas une attaque, mais il reste toujours visible. Les projectiles ennemis ont une couleur et un contour qui leur sont réservés.
- FR27 `[A]` : Le Somnambule (30 PV) marche vers le joueur à 2,5 tuiles/s. À moins de 2 tuiles, il lève les bras pendant 0,4 s, puis accélère à 5 tuiles/s pendant 0,6 s. Il inflige des dégâts au contact.
- FR28 `[A]` : La Veilleuse (40 PV) reste immobile. Toutes les 2 s, elle tire un éventail de 3 projectiles écartés de 20°, à 5 tuiles/s. Une lueur qui monte pendant 0,6 s annonce le tir.
- FR29 `[A]` : Le Mouton (50 PV) gratte le sol pendant 0,5 s, recule de 0,5 tuile, puis charge en ligne droite à 10 tuiles/s. S'il heurte un mur, il reste étourdi 1 s.
- FR30 `[A]` : La Berceuse (30 PV) se tient entre 4 et 8 tuiles du joueur. Toutes les 1,5 s, elle tire un projectile visé, à 6 tuiles/s, après avoir inspiré pendant 0,5 s.
- FR31 `[A]` : un ennemi n'apparaît jamais à moins de 3 tuiles du joueur.
- FR32 `[A]` : l'arène du jalon A enchaîne des vagues d'ennemis, et la relance y est instantanée.
- FR33 `[A]` : le HUD occupe une bande de 24 px en haut de l'écran. Il affiche les cœurs, l'armure, la jauge de lucidité, les Éclats, l'objet actif et le consommable.
- FR34 `[A]` : après chaque mort, le jeu demande au joueur « cette mort était-elle juste ? », pour le playtest.

**Étage et génération**

- FR35 `[B]` : les salles sont prédessinées, de 36×19 tuiles jouables. Les grandes salles font deux écrans, en largeur ou en hauteur.
  - Les obstacles bas laissent passer les tirs, et Glissement les franchit. Les obstacles hauts bloquent tout.
  - Chaque salle fixe ses emplacements d'ennemis, ses vagues et ses emplacements de renfort.
- FR36 `[B]` : les portes restent fermées tant que la salle n'est pas vidée.
- FR37 `[B]` : l'étage MVP compte 16 salles sur une grille : 1 départ, 12 salles de combat, 1 trésor, 1 boutique et 1 salle de cauchemar.
  - Le chemin principal est toujours garanti.
  - Une même salle n'apparaît jamais deux fois dans l'étage.
  - Le cauchemar est au bout d'un chemin d'au moins 4 salles depuis le départ.
- FR38 `[B]` : le pool de l'Endormissement compte au moins 30 salles de combat.
- FR39 `[B]` : le joueur choisit dans quel ordre il visite les salles adjacentes. La carte de l'étage se révèle au fil de l'exploration et s'affiche tant qu'on maintient sa touche.
- FR40 `[B]` : les trous sont omniprésents en Endormissement. Une chute compte comme un coup : le joueur perd ½ cœur (1 cœur à partir de l'étage 3), devient invulnérable 1 s et revient au dernier bord sûr.
- FR41 `[B]` : les meubles du rêve (lit, chaise, pupitre) arrêtent les projectiles des deux camps jusqu'à leur destruction, à 30 PV. Certains éléments se déclenchent d'un tir : par exemple, une lampe éblouit pendant 1 s les ennemis situés à moins de 3 tuiles.
- FR42 `[B]` : la salle de départ est calme. Au premier étage, elle sert de tutoriel visuel.
- FR43 `[B]` : toute la run découle d'une seed.
  - La disposition ne dépend que de la seed.
  - Les tirages d'objets, de drops et de combat sont indépendants les uns des autres.
  - La seed s'affiche à la mort et dans le menu pause, et elle peut être saisie avant une run.
  - Une run avec seed saisie ne débloque rien.

**Objets, consommables et économie**

- FR44 `[B]` : chaque objet a un bonus et un coût, décrits en jeu, et porte des tags (Chute, Temps, Regard, Corps). Le cumul est sans limite, et aucune rareté n'est affichée. Un objet n'apparaît qu'une fois par run, sauf la Dent qui tombe.
- FR45 `[B]` : le joueur porte un seul objet actif. En ramasser un autre dépose l'ancien au sol, qui garde sa charge. L'objet actif se recharge en vidant des salles.
- FR46 `[B]` : Dent qui tombe (Corps, Chute) : +30 % de dégâts, −1 cœur max.
  - Elle est cumulable, mais ne compte qu'une fois pour les tags.
  - S'il ne reste qu'un cœur max, elle s'affiche grisée et ne peut pas être prise. La salle trésor tire alors un autre objet.
- FR47 `[B]` : Jambes de plomb (Chute) : tirs traversants, −20 % de vitesse de déplacement.
- FR48 `[B]` : Ailes de papier (Chute) : survol des trous. Chaque coup reçu retire le survol pendant 3 s. Si le coup arrive au-dessus d'un trou, le joueur tombe, sans perdre plus que le coup.
- FR49 `[B]` : Chute libre (Chute) : +5 % de dégâts par seconde sans être touché, jusqu'à +50 %. Au premier coup, le bonus retombe à zéro, et ce coup retire ½ cœur de plus.
- FR50 `[B]` : Copie d'examen vierge (Temps) : un drop garanti de plus par salle de combat vidée.
  - En contrepartie, chaque salle de combat a un chrono de 45 s. À 0, les ennemis restants se déplacent et tirent 30 % plus vite.
  - Le chrono ne tourne ni dans la salle du cauchemar ni dans une salle déjà vidée.
- FR51 `[B]` : Réveil cassé (Temps, objet actif) : ralentit tout sauf le joueur à 50 % pendant 4 s. Il se recharge en 3 salles vidées et coûte 15 de lucidité à chaque utilisation : il est donc impossible sous 15.
- FR52 `[B]` : Miroir (Regard) : un second tir part vers l'arrière.
  - En contrepartie, dans 1 salle de combat sur 4, un reflet hostile du joueur apparaît. Il a 60 PV, multipliés par le facteur d'étage, et n'apparaît jamais dans la salle d'un cauchemar.
  - Ses projectiles sont des projectiles ennemis (couleur et contour réservés), qui reprennent le motif des tirs du joueur.
- FR53 `[B]` : Être nu en public (Regard, Corps) : les ennemis ne tirent pas pendant les 1,5 premières secondes de chaque salle.
  - En contrepartie, toute l'armure est perdue, et le joueur ne peut plus en ramasser.
  - La boutique propose alors un cœur à la place de l'armure.
- FR54 `[B]` : une synergie se déclenche à partir d'un nombre d'objets distincts portant le même tag. Le jeu l'annonce, avec son nom et son effet en clair. La famille Chute en a deux :
  - à 2 objets, « Piqué » : chaque dash finit sur une onde de choc de 15 dégâts, sur un rayon de 1,5 tuile ;
  - à 3 objets, « Chute sans fin » : l'onde passe à 30 dégâts sur 2,5 tuiles, et tomber dans un trou ne retire plus de cœur.
- FR55 `[B]` : le joueur porte un seul consommable. En ramasser un autre dépose l'ancien au sol.
  - Se pincer : +25 de lucidité contre ½ cœur, jamais pris sur l'armure. Impossible s'il ne reste qu'½ cœur.
  - Café : +30 % de vitesse et de cadence pendant 10 s, puis −20 % de vitesse pendant 5 s.
- FR56 `[B]` : une salle de combat vidée rapporte de 1 à 3 Éclats, multipliés par le loot du palier. Un cauchemar battu en rapporte 10.
- FR57 `[B]` : une salle de combat vidée a 30 % de chance de laisser un drop, multipliée par le loot du palier. Le drop est tiré parmi ½ cœur, ½ armure, un consommable ou 3 Éclats.
- FR58 `[B]` : la boutique propose 2 objets à 15 Éclats, 1 consommable à 5, 1 cœur à 4 (qui soigne 1 cœur) et 1 armure à 5 (+1 cœur d'armure).
- FR59 `[B]` : la salle trésor offre un objet gratuit, tiré du pool trésor. Au MVP, les pools trésor et boutique contiennent les 8 objets.

**Le Professeur et la boucle de run**

- FR60 `[B]` : Le Professeur a 2 500 PV et passe par 3 épreuves, chacune annoncée par une craie qui écrit son nom au tableau. Ses craies vont à 5 tuiles/s.
  1. Dictée (100 à 66 % des PV) : toutes les 2 s, une rangée horizontale de craies traverse la salle, avec un trou à franchir.
  2. Calcul mental (66 à 33 %) : une spirale à 4 bras tourne à 60°/s, et 3 craies visées partent toutes les 3 s.
  3. Examen final (33 à 0 %) : les deux premières épreuves alternent, et une règle balaie la salle, annoncée par une ligne 0,8 s avant.

  En Abandon total s'ajoute l'Interro surprise : un cercle de 12 craies toutes les 6 s.
- FR61 `[B]` : au MVP, battre Le Professeur termine la run par une victoire, et le personnage se réveille.
- FR62 `[B]` : une run commence dans la chambre, en s'endormissant dans le lit. Le joueur part avec 3 cœurs, 100 de lucidité, 0 Éclat et aucun objet.
- FR63 `[B]` : au retour dans la chambre, le réveil affiche l'heure du réveil.
  - La nuit commence à 23:00.
  - Dans l'étage, l'heure avance au prorata des salles de combat vidées.
  - Battre Le Professeur mène à 00:18, l'heure de fin de la phase.
- FR64 `[B]` : le joueur peut sauvegarder et quitter. La partie reprend au début de la salle en cours, avec l'état qu'avait le joueur en y entrant, et la sauvegarde est effacée dès la reprise. Après un crash, la run reprend au début de la dernière salle entrée.
- FR65 `[B]` : la mort fait tout perdre : objets, Éclats et état de la run. Seuls persistent les déblocages et le mystère. Les premières victoires et les succès sont déjà enregistrés, même si rien n'est débloqué au MVP.
- FR66 `[A]` : le menu de réglages propose les volumes, le mode fenêtré ou plein écran, la VSync et les touches.
- FR67 `[A]` : les réglages d'accessibilité réduisent les distorsions et les tremblements d'écran, et proposent un mode photosensibilité, sans aucun effet sur le gameplay.
- FR68 `[B]` : l'audio du MVP comprend :
  - une piste de musique pour l'Endormissement ;
  - un son pour chaque télégraphe ennemi ;
  - un son de frôlement discret pour le graze, et un son plus marqué pour le dash parfait ;
  - environ 40 effets sonores au total.

**Jalon C : listé, non découpé**

- FR-C1 : pactes. Une salle de pacte après chaque cauchemar battu, sauf le dernier ; 2 pactes refusables ; une malédiction contre un pouvoir, sans coût en lucidité. Les 4 pactes du brainstorm doivent d'abord être corrigés.
- FR-C2 : les phases 2 à 4, chacune avec sa mécanique : la duplication en Sommeil léger, les salles sombres en Sommeil profond, le bullet-hell à 150 projectiles en REM. Les coups retirent 1 cœur à partir de l'étage 3.
- FR-C3 : les cauchemars La Poursuite, La Vague, La Silhouette au pied du lit et Toi ; le pool cauchemar.
- FR-C4 : le choix de porte à la fin de l'étage 3, les salles spéciales (trésor maudit, pacte renforcé, salle d'oubli) et l'étage secret optionnel, où l'horloge reste bloquée sur 4:12.
- FR-C5 : au moins 4 objets par tag, avec leurs synergies ; les consommables restants ; les cœurs variés.
- FR-C6 : la chambre qui change, le journal de rêves, une couche du mystère par première victoire, la fin de l'acte 1.
- FR-C7 : les déblocages par succès et l'Ascension.

### Exigences non fonctionnelles

- NFR1 : le jeu tient 60 FPS soutenus, avec un 1 % low d'au moins 55 FPS, sur un PC de classe GTX 1060 (CPU 4 cœurs, 8 Go de RAM). Mesure : 400 projectiles ennemis simultanés pendant 10 minutes.
- NFR2 : la latence d'entrée est d'au plus 3 frames entre l'appui et l'écran. Mesure : filmer à 240 images/s.
- NFR3 : passer d'un étage à l'autre prend moins de 2 s, et relancer une run après la mort moins de 3 s.
- NFR4 : aucun crash sur 20 runs MVP consécutives.
- NFR5 : une même seed, avec les mêmes déblocages, reproduit la même disposition et les mêmes objets. Vérifié sur 10 seeds.
- NFR6 : le jeu tourne sur PC, Windows en priorité et macOS souhaité, sous Godot 4.7.2.
- NFR7 : le rendu interne est en 640×360, mis à l'échelle par un facteur entier de 720p à 4K (×2, ×3, ×4, ×6).
  - Hors 16:9, ou si la définition n'est pas un multiple exact, l'image a des bandes noires.
  - Les écrans HiDPI sont pris en charge.
  - Le jeu tourne en fenêtré ou en plein écran.
- NFR8 : le combat reste toujours lisible :
  - les projectiles ennemis ont une couleur et un contour réservés, identiques à toutes les phases et à tous les paliers ;
  - les tirs du joueur restent plus discrets ;
  - les distorsions ne touchent jamais les projectiles, les télégraphes ni les entités.
- NFR9 : toute valeur numérique du GDD se règle sans toucher au code.
- NFR10 : tout texte affiché passe par les fichiers de localisation, avec le français comme langue de référence.
- NFR11 : chaque phase a au plus 32 couleurs, plus les couleurs réservées aux projectiles. Tailles des sprites : tuiles de 16×16, joueur de 16×24, ennemis de 16 à 32 px, cauchemars de 64×64 et plus.
- NFR12 : le jeu mesure les indicateurs de playtest par télémétrie :
  - jalon A : 20 min de jeu volontaire par joueur ;
  - mort juste : au moins 80 % de oui ;
  - au moins 25 % de la run sous Lucide ;
  - jalon B : au moins 3 runs d'affilée, et une run médiane de 12 à 18 min ;
  - Le Professeur : 30 à 50 % de victoires à partir de la 5e tentative.

### Exigences supplémentaires (architecture)

**Démarrage du projet (Epic 1, Story 1)**

- AR1 : il n'y a pas de modèle de départ. Le projet Godot 4.7.2 est vide, créé dans `game/`, et `game/.godot/` et `builds/` sont ajoutés au `.gitignore`.
  - Réglages initiaux : viewport 640×360, stretch `viewport` + `keep` + `integer`, HiDPI, rendu `gl_compatibility`, filtre `Nearest`, physique à 60 Hz.
  - Les couches de collision sont nommées.
  - Le projet déclare les autoloads `Events`, `Log`, `Settings`, `SaveService`, `Audio` et `GameClock`.
- AR2 : GDScript est typé statiquement partout, et les avertissements de typage sont traités en erreurs. C# ou GDExtension n'interviennent que si le profilage l'impose.
- AR3 : outillage de l'IA : MCP GoPeak et Context7. L'emplacement de l'éditeur (Windows, WSLg, ou dépôt côté Windows) est à trancher à l'installation.
- AR4 : le socle comprend `Const` (taille des tuiles, viewport, couches), `Tuning` (préchargement des `.tres`), `RunRng`, l'autoload `Log` et la surcouche de performances F3.
- AR5 : **le risque n°1 est levé en premier** : un prototype du `BulletManager` et une scène de test de charge à 400 projectiles (F5), mesurée sur la machine de référence.

**Systèmes**

- AR6 (D1) : un `BulletManager` par camp, construit sur :
  - des tableaux compacts de taille fixe, avec une liste d'emplacements libres ;
  - un rendu par `MultiMeshInstance2D` ;
  - des collisions écrites à la main, contre la hurtbox, les cellules des murs et obstacles hauts, et les meubles ;
  - le graze calculé dans la même boucle ;
  - un pool pré-alloué ;
  - des effets d'objets passés en `BulletParams`.

  Si le profilage l'exige, la boucle passe en GDExtension, sans changer d'interface.
- AR7 (D2) : les entités sont composées de nœuds (`Health`, `Hurtbox`, `Hitbox`, `Telegraph`), avec une machine à états par enum. Toute attaque passe par le composant `Telegraph`, dont la durée vaut `max(base × telegraph_mult, min_telegraph)`.
- AR8 (D3) : communication entre systèmes :
  - l'autoload `Events` porte les notifications transverses, des signaux au passé ;
  - un nœud parle à son parent par signal local, et à ses enfants par appel direct ;
  - l'état de la run vit dans un nœud `Run` ;
  - sont interdits : les chemins `/root/...`, `get_parent().get_parent()` et les autoloads qui gardent un état de run.
- AR9 (D4) : les valeurs d'équilibrage vivent dans des Resources typées sous `data/` : `PlayerTuning`, `DashTuning`, `ShotTuning`, `LucidityTuning`, `CombatTuning`, `EconomyTuning`, `EnemyDef`, `BossDef`, `ItemDef`, `ConsumableDef` et `FloorDef`. Ces Resources sont en lecture seule à l'exécution. Elles expriment les distances en tuiles et les durées en secondes ; la conversion se fait à un seul endroit.
- AR10 (D5, P1) : `Lucidity` est un `RefCounted` qui expose `value`, `live_tier`, `room_tier`, `begin_room()`, `try_spend()` et `gain()`, avec le plafond de graze. Ses signaux sont `value_changed`, `tier_changed` et `room_danger_raised`. Le `DangerProfile` se calcule depuis `room_tier`, et le danger ne lit que `room_tier`.
- AR11 (P2) : un drapeau `counted` par projectile ; le dash parfait est compté par projectile évité.
- AR12 (D6) : les entrées passent par des actions `InputMap`, lues à 60 Hz, avec un tampon compté en ticks. La VSync est activée par défaut, ainsi que l'interpolation physique 2D. La latence se mesure au jalon A.
- AR13 (D7, P4) : l'autoload `GameClock` fixe l'échelle de temps par groupe : `PLAYER`, `ENEMIES`, `ENEMY_BULLETS`, `PLAYER_BULLETS`, `WORLD`, `FX`.
  - Tout code de gameplay multiplie son temps par l'échelle de son groupe : `delta * GameClock.scale(group)`.
  - Les nœuds `Timer` sont interdits pour le gameplay, et `Engine.time_scale` reste à 1.
- AR14 (D8) : `RunRng` fournit un flux par usage : `layout`, `rooms`, `treasure`, `shop`, `drops`, `combat`, `cosmetic`.
  - La seed d'un flux est un hachage de `(seed, flux, étage)`.
  - La seed de run s'affiche comme un code de 8 caractères.
  - Le RNG global est interdit.
- AR15 (D9, P5) : le modèle d'objets s'appuie sur :
  - `StatBlock`, avec des modificateurs `ADD_PERCENT`, `ADD_FLAT` et `MULTIPLY` ;
  - `Loadout`, `ItemDef` et `ItemEffect`, ce dernier branché sur `hit_taken`, `room_cleared`, `dash_ended` et `tick` ;
  - `TagTracker`, qui émet `synergy_activated` ;
  - le composant `BuildCarrier`, que le reflet du Miroir porte aussi.
- AR16 (D10) : une salle est une scène `.tscn` avec :
  - les `TileMapLayer` `Floor`, `Walls`, `LowObstacles`, `HighObstacles` et `Pits` ;
  - les marqueurs `EnemySpawn`, `ReinforcementSpawn`, `Door`, `Furniture` et `Trigger` ;
  - des métadonnées : type, phase, taille.

  Un validateur headless contrôle le pool.
- AR17 (D11) : la génération étend une grille depuis le départ, applique les contraintes et retire dans le flux `layout` en cas d'échec. Les salles de l'étage sont préchargées en tâche de fond.
- AR18 (D12, P3) : trois fichiers de sauvegarde : `settings.cfg`, `profile.json` et `run.json`.
  - Les fichiers JSON portent un `schema_version`, avec une migration par version.
  - L'écriture est atomique.
  - Un fichier illisible est renommé en `.corrupt`.
  - Sauvegarder en `.tres` ou `.res` est interdit.
  - `RunSnapshot` est construit à l'entrée de salle.
  - Tout état persistant implémente `to_dict()` et `from_dict()`, et les objets sont référencés par leur `id`.
- AR19 (D13) : le rendu suit cet ordre de couches : décor, post-traitement de distorsion, entités, combat, HUD. L'intensité de la distorsion vaut f(palier) × le réglage d'accessibilité.
- AR20 (D14) : `Main` persiste et porte l'`ActiveScene` (`Bedroom` ou `Run`), l'`UI` et la `Transition`. Une seule salle est active à la fois. La relance détruit le nœud `Run`, puis le recrée.
- AR21 (D15) : l'audio a quatre bus : `Master`, `Music` (avec le passe-bas de la lucidité), `SFX` et `UI`. L'autoload `Audio` gère un pool de lecteurs, avec une limite de voix par son.
- AR22 (D16) : l'interface s'appuie sur des nœuds Control, un `Theme` unique et une police pixel. Tout texte passe par `tr("CLE")`, depuis `localization/strings.csv`.
- AR23 (D17) : au jalon A, les ennemis se déplacent en ligne directe ; `AStarGrid2D` arrive au jalon B.
- AR24 (D18) : les outils de debug arrivent dès le jalon A. Ils n'existent pas dans les builds de release, sauf F3.
  - F1 : panneau de debug ;
  - F2 : affichage des collisions ;
  - F3 : performances ;
  - F4 : ralenti ×0,25 ;
  - F5 : test de charge.
- AR25 (D18) : la télémétrie tient un journal JSON par session. Elle écoute `Events`, et aucun système ne l'appelle directement.
- AR26 : le framework de test se choisit avec `gds-test-framework` avant le jalon B. Le test sur 10 seeds est obligatoire. Les classes de logique pure (`Lucidity`, `StatBlock`, `RunRng`, `FloorGenerator`, `RunSnapshot`) se testent sans scène.
- AR27 : les logs passent par `Log.<niveau>(catégorie, message)`.
  - `print()` est interdit.
  - Rien ne se journalise dans les boucles par frame.
  - La seed est journalisée au lancement de chaque run.
- AR28 : gestion des erreurs :
  - `assert` et `Log.error` pour les invariants violés ;
  - une valeur sûre en repli pour les erreurs récupérables ;
  - les données invalides sont refusées dès le chargement.

  En release, le jeu ne s'arrête jamais sur une erreur.
- AR29 : compléments techniques :
  - trous : la dernière position sûre est mémorisée à chaque tick, et la chute se teste par lecture de cellule ;
  - Glissement : sa destination se résout par `intersect_ray` ;
  - caméra : la bande de HUD fait 24 px ;
  - seed saisie : `RunState.seeded` coupe les déblocages.
- AR30 : exports Windows et macOS, avec un build macOS non signé pour le premier cercle.
- AR31 : quatre points à vérifier au jalon A :
  - le test de charge à 400 projectiles ;
  - la latence avec la VSync activée ;
  - les projectiles sur un écran à plus de 60 Hz (interpolation) ;
  - l'export macOS lancé sur un Mac.
- AR32 : conventions de nommage et lexique GDD → code de l'architecture. Tout nouveau terme entre dans le lexique avant d'apparaître dans le code.

### Exigences de design UX

Il n'existe pas de document UX. Les exigences d'interface viennent du GDD :

- le HUD (FR33) ;
- la carte (FR39) ;
- les annonces de synergie (FR54) ;
- les menus de pause, de mort, de réglages, de touches et de saisie de seed (FR10, FR34, FR43, FR66) ;
- l'accessibilité (FR67).

### Carte de couverture des FR

| FR | Epic | Objet |
|---|---|---|
| FR1 à FR8 | Epic 1 | Déplacement, hitbox, dash, tir, retours, contrôles, bascule de périphérique |
| FR9 | Epic 1 et Epic 4 | Caméra fixe (Epic 1), caméra qui suit dans les grandes salles (Epic 4) |
| FR10 | Epic 1 | Pause |
| FR11 à FR15 | Epic 2 | Cœurs, coups, invulnérabilité, armure, mort et relance |
| FR12 | Epic 2 et Epic 6 | Contact (Epic 2), attaques lourdes du cauchemar (Epic 6) |
| FR16 à FR19 | Epic 3 | Jauge, paliers, récompenses en direct, danger de salle |
| FR20 | Epic 5 | Multiplicateur de loot |
| FR21 à FR23 | Epic 3 | Dépense, remontée, Éveil |
| FR24 | Epic 3 et Epic 4 | Glissement (Epic 3), trou comme destination (Epic 4) |
| FR25 | Epic 3 | Signes de la lucidité |
| FR26 à FR34 | Epic 2 | Télégraphes, 4 ennemis, apparitions, arène, HUD, « mort juste ? » |
| FR35 à FR43 | Epic 4 | Salles, portes, étage, pool, carte, trous, meubles, départ, seeds |
| FR44 à FR59 | Epic 5 | Objets, objet actif, les 8 objets, synergies, consommables, économie, boutique, trésor |
| FR60 à FR65 | Epic 6 | Le Professeur, victoire, chambre, heure du réveil, sauvegarde, permadeath |
| FR66 | Epic 1 | Menu de réglages |
| FR67 | Epic 3 | Accessibilité |
| FR68 | Epic 7 | Audio du MVP |
| FR-C1 à FR-C7 | Jalon C | Non découpés |

| NFR et AR | Epic |
|---|---|
| NFR1, NFR2, NFR6, NFR7 ; AR1 à AR6, AR12, AR13, AR19, AR24, AR27, AR28, AR30, AR31 | Epic 1 |
| NFR8, NFR12 ; AR7, AR8, AR22, AR23 (direct), AR25 | Epic 2 |
| AR10, AR11, AR21 | Epic 3 |
| NFR5 ; AR14, AR16, AR17, AR23 (`AStarGrid2D`), AR26, AR29 | Epic 4 |
| AR15 | Epic 5 |
| NFR3, NFR4 ; AR18, AR20 | Epic 6 |
| NFR11 | Epic 7 |
| NFR9, NFR10 ; AR9, AR32 | Tous les epics |

## Liste des epics

**Ordre** : les Epics 1 à 3 forment le jalon A, et l'Epic 3 le valide. Les Epics 4 à 6 forment le jalon B, qui ne démarre qu'une fois le jalon A validé. L'Epic 7 court en parallèle : test de style au jalon A, production au jalon B.

Contrairement à l'ébauche du GDD, le combat (Epic 2) passe avant la lucidité (Epic 3) : le graze, le dash parfait et le danger ont besoin d'ennemis et de projectiles ennemis.

### Epic 1 : Bouger et tirer dans le rêve

On contrôle un personnage nerveux dans une arène vide, au clavier-souris ou à la manette, en 640×360 net à toutes les résolutions. L'epic pose aussi le socle technique (projet Godot, autoloads, outils de debug) et lève d'abord le risque n°1, avec le test de charge à 400 projectiles.

**FR couverts :** FR1 à FR8, FR9 (caméra fixe), FR10, FR66

### Epic 2 : Survivre aux cauchemars de l'Endormissement

On affronte dans l'arène des vagues de 4 ennemis aux télégraphes lisibles. On encaisse des coups, avec de l'armure et des invulnérabilités, on meurt et on relance en moins de 3 s. Après chaque mort, le jeu demande si elle était juste.

**FR couverts :** FR11 à FR15, FR26 à FR34

### Epic 3 : Jouer avec sa lucidité

On dépense sa lucidité en Éveil et en Glissement, on glisse vers l'abandon (plus de danger, plus de dégâts) et on la regagne par le graze et le dash parfait. Cet epic valide le jalon A.

**FR couverts :** FR16 à FR19, FR21 à FR23, FR24 (sans les trous), FR25, FR67

### Epic 4 : Explorer un étage né d'une seed

On parcourt un étage Endormissement de 16 salles prédessinées, avec des trous, des meubles et des portes qui se ferment, et une carte qui se révèle au fil de l'exploration. Tout l'étage découle d'une seed reproductible.

**FR couverts :** FR9 (grandes salles), FR24 (trous), FR35 à FR43

### Epic 5 : Construire son build

On trouve et on achète les 8 objets et les 2 consommables, on déclenche la synergie Chute, et on gagne des Éclats et des drops selon son palier.

**FR couverts :** FR20, FR44 à FR59

### Epic 6 : Une nuit complète, de la chambre au réveil

On s'endort dans la chambre, on bat Le Professeur et on se réveille à l'heure affichée. On peut sauvegarder et quitter, puis reprendre la partie.

**FR couverts :** FR12 (attaques lourdes), FR60 à FR65

### Epic 7 : Le rêve prend forme, direction artistique et audio de l'Endormissement

Les graphismes IA cohérents, la palette, la musique et les effets sonores remplacent les placeholders. La première story est le test de cohérence des graphismes IA, exigé dès le jalon A.

**FR couverts :** FR68

## Epic 1 : Bouger et tirer dans le rêve

On contrôle un personnage nerveux dans une arène vide, au clavier-souris ou à la manette, en 640×360 net à toutes les résolutions. L'epic pose aussi le socle technique (projet Godot, autoloads, outils de debug) et lève d'abord le risque n°1, avec le test de charge à 400 projectiles.

### Story 1.1 : Lancer le jeu dans une fenêtre nette à toutes les résolutions

En tant que développeur,
je veux un projet Godot 4.7.2 initialisé avec son socle (réglages, autoloads, constantes, journal, surcouche de performances),
afin que chaque story suivante parte de fondations conformes à l'architecture.

**Exigences :** AR1, AR2, AR3, AR4 (sans `RunRng`), AR13, AR24 (F3), AR27, AR28, NFR7

**Critères d'acceptation :**

**Étant donné** un dépôt sans projet Godot
**Quand** le projet est créé dans `game/`
**Alors** `project.godot` porte les réglages initiaux de l'architecture : viewport 640×360, stretch `viewport`, `keep` et `integer`, HiDPI, rendu `gl_compatibility`, filtre `Nearest`, physique à 60 Hz
**Et** les couches de collision sont nommées dans les réglages du projet, et `Const` les référence
**Et** les avertissements de typage GDScript sont traités comme des erreurs
**Et** `game/.godot/` et `builds/` sont ignorés par git, et les dossiers `art_source/` et `tools/` existent

**Étant donné** le projet créé
**Quand** on le lance
**Alors** les autoloads `Events`, `Log`, `Settings`, `SaveService`, `Audio` et `GameClock` sont déclarés. Ceux dont aucune story n'a encore besoin restent des coquilles vides.
**Et** `Log.info(categorie, message)` écrit `[hh:mm:ss.mmm] [INFO] [categorie] message` dans la console et dans `user://logs/`. Les niveaux DEBUG et TRACE sont inactifs en release.
**Et** `GameClock.scale(groupe)` renvoie l'échelle de chaque groupe (`PLAYER`, `ENEMIES`, `ENEMY_BULLETS`, `PLAYER_BULLETS`, `WORLD`, `FX`), soit 1,0 par défaut, et 0 quand le jeu est en pause
**Et** la classe statique `Tuning` existe ; chaque story y ajoutera sa Resource

**Étant donné** le jeu lancé
**Quand** la fenêtre passe en 1280×720, 1920×1080, 2560×1440 puis 3840×2160, en fenêtré comme en plein écran
**Alors** l'image est mise à l'échelle par ×2, ×3, ×4 puis ×6, sans flou
**Et** une fenêtre en 16:10, ou dont la définition n'est pas un multiple exact, affiche des bandes noires

**Étant donné** n'importe quel build
**Quand** on appuie sur F3
**Alors** une surcouche affiche les FPS et le 1 % low

**Étant donné** l'environnement de développement
**Quand** la story est terminée
**Alors** l'emplacement de l'éditeur est tranché (Windows, WSLg ou dépôt côté Windows), les MCP GoPeak et Context7 sont configurés, et ce choix est consigné

### Story 1.2 : Valider 400 projectiles à 60 FPS

En tant que développeur,
je veux un `BulletManager` orienté données et une scène de test de charge à 400 projectiles,
afin de lever le risque n°1 (les performances de Godot) avant de bâtir le combat dessus.

**Exigences :** AR5, AR6, AR31 (points 1 et 3), NFR1

**Critères d'acceptation :**

**Étant donné** un `BulletManager` par camp, enfant de la scène active
**Quand** on appelle `fire(params, origin, direction)`
**Alors** le projectile est rangé dans des tableaux compacts de taille fixe, avec une liste d'emplacements libres, sans aucun nœud par projectile
**Et** il est dessiné par un `MultiMeshInstance2D` par camp et par apparence
**Et** il avance selon `delta * GameClock.scale()` du groupe de son camp
**Et** il disparaît en touchant une cellule des couches `Walls` ou `HighObstacles`, détectée par lecture de cellule du `TileMapLayer`

**Étant donné** un pool plein
**Quand** un nouveau tir est demandé
**Alors** le tir est refusé sans erreur, et le refus est compté dans la surcouche F3, sans log par frame

**Étant donné** un build de debug
**Quand** on appuie sur F5
**Alors** une scène de test entretient 400 projectiles ennemis en mouvement, et F3 affiche leur nombre

**Étant donné** la machine de référence (classe GTX 1060, CPU 4 cœurs, 8 Go)
**Quand** le test de charge tourne 10 minutes
**Alors** le jeu tient 60 FPS soutenus, avec un 1 % low d'au moins 55 FPS
**Et** le résultat, avec le moteur de rendu utilisé, est consigné dans la story
**Et** en cas d'échec, le repli retenu (boucle en GDExtension ou rendu Forward+) est décidé et consigné avant la story suivante

**Étant donné** un écran à 144 Hz
**Quand** les projectiles se déplacent
**Alors** ils ne saccadent pas. Si c'est le cas, le `BulletManager` interpole lui-même leurs positions de rendu entre deux ticks.

### Story 1.3 : Se déplacer dans l'arène

En tant que joueur,
je veux déplacer mon personnage dans une arène, au clavier ou au stick, avec une réponse immédiate,
afin de sentir un contrôle nerveux.

**Exigences :** FR1, FR2, FR9 (caméra fixe), AR9, AR12, AR24 (F2), AR29 (caméra et bande de HUD)

**Critères d'acceptation :**

**Étant donné** la scène d'arène : une salle d'un écran, 36×19 tuiles jouables entourées de murs, sous une bande de HUD de 24 px
**Quand** le jeu démarre
**Alors** le joueur apparaît dans l'arène, et la caméra est fixe et centrée sur la salle

**Étant donné** le joueur dans l'arène
**Quand** il se déplace avec ZQSD ou le stick gauche
**Alors** il atteint 6 tuiles/s en 0,06 s et s'arrête en 0,04 s, dans les 8 directions
**Et** il ne va pas plus vite en diagonale
**Et** les touches par défaut sont des touches physiques : ZQSD sur un clavier AZERTY, WASD sur un clavier QWERTY
**Et** les entrées sont lues dans `_physics_process` par les actions `InputMap` `move_*`
**Et** les murs l'arrêtent

**Étant donné** le joueur, avec un sprite provisoire de 16×24
**Quand** on inspecte sa hitbox
**Alors** elle mesure 6×6 px, centrée sur le torse
**Et** la vitesse, l'accélération, la décélération et la taille de la hitbox viennent de `PlayerTuning.tres` et se règlent sans toucher au code

**Étant donné** un build de debug
**Quand** on appuie sur F2
**Alors** les hitbox et hurtbox s'affichent

### Story 1.4 : Dasher

En tant que joueur,
je veux un dash court et invulnérable, avec un tampon d'entrée,
afin d'esquiver au dernier moment.

**Exigences :** FR3, FR4 (murs), AR12, AR24 (F4)

**Critères d'acceptation :**

**Étant donné** le joueur, en mouvement ou à l'arrêt
**Quand** il appuie sur Espace ou sur RB
**Alors** il parcourt 3 tuiles en 0,18 s dans sa direction de déplacement. À l'arrêt, il part dans sa dernière direction de déplacement.
**Et** il est invulnérable pendant les 0,15 premières secondes. `is_dash_invulnerable()` et `is_invulnerable()` exposent cet état.
**Et** un signal `dash_ended` est émis à la fin du dash

**Étant donné** un dash qui vient de finir
**Quand** le joueur appuie de nouveau sur dash pendant la recharge de 0,6 s
**Alors** l'appui n'est retenu que s'il tombe dans les 0,1 s qui précèdent la fin de la recharge : le dash part alors dès qu'elle est terminée. Plus tôt, il est ignoré.
**Et** le tampon est compté en ticks de physique

**Étant donné** un mur sur la trajectoire
**Quand** le joueur dashe vers lui
**Alors** le dash s'arrête contre le mur, sans le traverser

**Étant donné** les valeurs du dash
**Quand** on les modifie dans `DashTuning.tres`
**Alors** le dash change sans toucher au code

**Étant donné** un build de debug
**Quand** on appuie sur F4
**Alors** tout le jeu passe au ralenti ×0,25 par `GameClock`, sans toucher à `Engine.time_scale`

### Story 1.5 : Viser et tirer

En tant que joueur,
je veux tirer librement à la souris ou au stick, avec des retours nets à chaque tir et à chaque impact,
afin que chaque tir se sente.

**Exigences :** FR5, FR6, AR6 (camp joueur), AR21 (bus et pool), NFR8 (tirs du joueur discrets)

**Critères d'acceptation :**

**Étant donné** le joueur au clavier-souris
**Quand** il bouge la souris
**Alors** la visée suit la direction du joueur vers le curseur, convertie dans les coordonnées du monde (viewport 640×360), et un réticule s'affiche

**Étant donné** le joueur à la manette
**Quand** il incline le stick droit au-delà de la zone morte
**Alors** la visée suit le stick, et le tir part tout seul
**Et** RT tire dans la dernière direction visée

**Étant donné** le clic gauche maintenu
**Quand** le joueur tire
**Alors** le tir part à 4 tirs/s, va à 14 tuiles/s, inflige 10 dégâts et a une hitbox de 4×4, exactement dans la direction visée, par le `BulletManager` du joueur
**Et** il file jusqu'à un mur, sans portée maximale
**Et** les tirs du joueur sont plus petits et plus transparents que des projectiles ennemis, dans une couleur qui leur est réservée
**Et** les valeurs viennent de `ShotTuning.tres`

**Étant donné** un dash en cours
**Quand** le joueur maintient le tir
**Alors** aucun tir ne part pendant le dash, et le tir reprend dès sa fin

**Étant donné** un tir qui part
**Quand** il est émis
**Alors** le sprite du joueur recule de 1 px pendant 0,05 s, et un son court provisoire se joue par l'autoload `Audio` sur le bus `SFX`
**Et** les bus `Master`, `Music`, `SFX` et `UI` existent, et `Audio` gère un pool de lecteurs avec une limite de voix par son

**Étant donné** une cible d'entraînement dans l'arène, qui porte une `Hurtbox`
**Quand** un tir la touche
**Alors** le tir est détruit, et les dégâts passent par `DamageInfo` puis `Hurtbox.receive()`
**Et** la cible flashe en blanc pendant 0,05 s et recule de 2 px

### Story 1.6 : Mettre en pause et régler le jeu

En tant que joueur,
je veux mettre le jeu en pause et régler le son, l'affichage et la VSync,
afin de jouer dans de bonnes conditions.

**Exigences :** FR6 (chiffres de dégâts), FR10, FR66 (sans les touches), AR18 (`settings.cfg`), AR22, NFR10

**Critères d'acceptation :**

**Étant donné** une partie en cours
**Quand** le joueur appuie sur Échap ou sur Start
**Alors** le jeu se fige par `GameClock` et `process_mode`, sans toucher à `Engine.time_scale`
**Et** un menu de pause propose Reprendre, Réglages et Quitter

**Étant donné** le menu des réglages
**Quand** le joueur change les volumes (`Master`, `Music`, `SFX`, `UI`), le mode fenêtré ou plein écran, la VSync ou l'affichage des chiffres de dégâts
**Alors** le changement s'applique aussitôt et s'écrit dans `user://settings.cfg`, de façon atomique (fichier temporaire, puis renommage)
**Et** les réglages sont restaurés au lancement suivant
**Et** par défaut, la VSync est activée et les chiffres de dégâts sont désactivés

**Étant donné** les chiffres de dégâts activés
**Quand** un tir touche la cible d'entraînement
**Alors** les dégâts s'affichent au-dessus d'elle

**Étant donné** un `settings.cfg` absent ou illisible
**Quand** le jeu démarre
**Alors** il démarre avec les réglages par défaut, et un avertissement est journalisé

**Étant donné** les menus
**Quand** ils s'affichent
**Alors** tous leurs textes passent par `tr("CLE")`, depuis `localization/strings.csv`, avec le français comme langue de référence
**Et** ils utilisent le `Theme` unique et une police pixel

### Story 1.7 : Jouer à la manette ou au clavier-souris, avec ses propres touches

En tant que joueur,
je veux passer librement du clavier-souris à la manette et réassigner mes touches,
afin de jouer comme j'en ai l'habitude.

**Exigences :** FR7, FR8, AR12

**Critères d'acceptation :**

**Étant donné** le jeu lancé
**Quand** on inspecte l'`InputMap`
**Alors** toutes les actions de l'architecture existent (`move_*`, `aim_*`, `shoot`, `dash`, `power_1`, `power_2`, `use_active`, `use_consumable`, `map`, `pause`), avec les touches par défaut du tableau des contrôles du GDD, au clavier-souris et à la manette Xbox

**Étant donné** le joueur au clavier-souris
**Quand** il touche un stick au-delà de la zone morte ou appuie sur un bouton de manette
**Alors** le jeu passe en mode manette : la visée suit le stick, et le curseur est masqué
**Et** un mouvement de souris ou une touche du clavier le ramène en mode clavier-souris
**Et** une dérive du stick sous la zone morte ne fait pas basculer le mode

**Étant donné** le menu des touches, dans les réglages
**Quand** le joueur réassigne une action, au clavier ou à la manette
**Alors** la nouvelle touche fonctionne aussitôt et s'écrit dans `settings.cfg`
**Et** si la touche était déjà prise, les deux actions échangent leurs touches
**Et** un bouton rétablit les touches par défaut

### Story 1.8 : Exporter pour Windows et macOS, et mesurer la latence

En tant que développeur,
je veux des exports Windows et macOS et une mesure de la latence d'entrée,
afin que le premier cercle puisse jouer à l'arène et que les sensations tiennent la cible de 3 frames.

**Exigences :** NFR2, NFR6, AR30, AR31 (points 2 et 4)

**Critères d'acceptation :**

**Étant donné** `export_presets.cfg`, avec un preset Windows et un preset macOS
**Quand** on lance le script d'export de `tools/`
**Alors** les builds sont produits dans `builds/`
**Et** les builds de release ne contiennent aucun outil de triche (F2, F4, F5). Seule la surcouche F3 reste disponible.

**Étant donné** le build macOS non signé
**Quand** on le lance sur un Mac, en suivant la procédure Gatekeeper documentée
**Alors** l'arène tourne, avec une mise à l'échelle entière correcte sur un écran Retina

**Étant donné** la VSync activée
**Quand** on filme à 240 images/s l'appui et l'écran
**Alors** il s'écoule au plus 3 frames entre l'appui et la réaction à l'écran
**Et** la mesure est consignée. Au-delà de 3 frames, la VSync désactivée et le mode mailbox sont essayés, puis le réglage par défaut retenu est consigné.

## Epic 2 : Survivre aux cauchemars de l'Endormissement

On affronte dans l'arène des vagues de 4 ennemis aux télégraphes lisibles. On encaisse des coups, avec de l'armure et des invulnérabilités, on meurt et on relance en moins de 3 s. Après chaque mort, le jeu demande si elle était juste.

### Story 2.1 : Encaisser des coups

En tant que joueur,
je veux des cœurs, une armure et une invulnérabilité après chaque coup,
afin de savoir exactement ce que me coûte une erreur.

**Exigences :** FR11, FR12 (coup de base), FR13, FR14 (hors ramassage), AR7, AR8, AR24 (F1)

**Critères d'acceptation :**

**Étant donné** le début d'une partie
**Quand** le joueur apparaît
**Alors** il a 3 cœurs, soit 6 demi-cœurs, gérés par un composant `Health` qui compte en demi-cœurs entiers

**Étant donné** le joueur vulnérable
**Quand** un projectile ennemi touche sa hurtbox
**Alors** le coup passe par `DamageInfo`, `Hurtbox.receive()` puis `Health.apply_damage()`, et retire ½ cœur, la valeur de `CombatTuning`
**Et** le projectile est détruit
**Et** `Events.player_hit` est émis

**Étant donné** le joueur qui vient d'être touché
**Quand** d'autres coups arrivent dans la seconde qui suit
**Alors** ils ne comptent pas, et les projectiles qui le touchent continuent leur course
**Et** le sprite clignote pendant toute l'invulnérabilité, et un son de coup se joue

**Étant donné** le joueur en dash, pendant ses 0,15 s d'invulnérabilité
**Quand** un projectile ennemi le traverse
**Alors** aucun coup n'est compté, et le projectile continue sa course

**Étant donné** le joueur avec de l'armure
**Quand** il prend un coup
**Alors** l'armure, en demi-cœurs bleus, est retirée avant les cœurs
**Et** l'ajout d'armure ou de cœurs est refusé au-delà du plafond de 12 cœurs, armure comprise, et l'appel renvoie `false`

**Étant donné** un build de debug
**Quand** on ouvre le panneau F1
**Alors** il permet de basculer l'invulnérabilité, d'ajouter de l'armure, de se retirer ½ cœur et de faire tirer un émetteur de projectiles ennemis de test
**Et** le panneau est une scène séparée, instanciée seulement en debug (puis par `Main` dès la Story 2.2), qui appelle les méthodes publiques du jeu

### Story 2.2 : Mourir et relancer en moins de 3 secondes

En tant que joueur,
je veux qu'une mort me renvoie aussitôt à une nouvelle partie,
afin de relancer sans attendre.

**Exigences :** FR15, NFR3 (relance), AR20

**Critères d'acceptation :**

**Étant donné** la scène `Main` persistante
**Quand** une partie démarre
**Alors** `Main` instancie un nœud `Run` sous `ActiveScene`, avec le joueur et l'arène dans `RoomSlot`
**Et** `UI` et `Transition` sont des `CanvasLayer` de `Main`

**Étant donné** le joueur à ½ cœur, sans armure
**Quand** il prend un coup
**Alors** il meurt, `Events.run_ended` est émis, et un écran de réveil s'affiche

**Étant donné** l'écran de réveil
**Quand** le joueur appuie sur la touche de relance, ou passe l'écran
**Alors** le nœud `Run` est détruit, un nouveau est instancié, et la nouvelle partie démarre en moins de 3 s après la mort
**Et** les ressources de l'arène restent en cache
**Et** `Log.info("run", ...)` journalise la mort et le lancement de la nouvelle partie

### Story 2.3 : Affronter Le Somnambule

En tant que joueur,
je veux un premier ennemi qui me poursuit et annonce son accélération,
afin d'apprendre à lire un télégraphe.

**Exigences :** FR4 (ennemis), FR12 (contact), FR26, FR27, FR31, AR7, AR23 (déplacement direct)

**Critères d'acceptation :**

**Étant donné** une salle
**Quand** elle fait apparaître un ennemi
**Alors** l'apparition passe par `room.spawn_enemy(def, position)`, qui tient le compte des ennemis vivants
**Et** aucun ennemi n'apparaît à moins de 3 tuiles du joueur. Une position trop proche est refusée et remplacée par une autre position valide.

**Étant donné** un Somnambule défini par `sleepwalker.tres` (`EnemyDef`)
**Quand** il est actif
**Alors** il marche vers le joueur à 2,5 tuiles/s, en ligne directe, bras tendus
**Et** à moins de 2 tuiles, il lève les bras pendant 0,4 s (télégraphe, animation et son), puis accélère à 5 tuiles/s pendant 0,6 s
**Et** sa machine à états est un enum, avec une fonction `_process_<état>()` par état et des transitions par `_enter()` uniquement
**Et** son temps suit `GameClock.scale(ENEMIES)`

**Étant donné** le composant `Telegraph`
**Quand** une attaque est lancée
**Alors** sa durée vaut `max(base × multiplicateur, min_telegraph)`, avec `min_telegraph` = 0,4 s dans `CombatTuning`. Le multiplicateur reste à 1 tant que le danger n'existe pas.

**Étant donné** le joueur vulnérable
**Quand** le Somnambule le touche
**Alors** le contact inflige un coup de ½ cœur

**Étant donné** le Somnambule et ses 30 PV
**Quand** les tirs du joueur le touchent
**Alors** il perd 10 PV par tir, avec les retours d'impact de la Story 1.5, et meurt à 0
**Et** le dash du joueur ne le traverse pas

### Story 2.4 : Affronter La Veilleuse et La Berceuse

En tant que joueur,
je veux deux tireuses aux projectiles toujours reconnaissables,
afin d'apprendre à esquiver des tirs annoncés.

**Exigences :** FR26, FR28, FR30, NFR8, AR6 (camp ennemi)

**Critères d'acceptation :**

**Étant donné** un projectile ennemi
**Quand** il est dessiné
**Alors** il a une couleur et un contour réservés aux projectiles ennemis, dessinés au-dessus de tout le reste du monde

**Étant donné** La Veilleuse (40 PV, immobile)
**Quand** son cycle de 2 s arrive à son terme
**Alors** une lueur monte pendant 0,6 s (animation et son)
**Et** elle tire ensuite un éventail de 3 projectiles écartés de 20°, centré sur le joueur, à 5 tuiles/s, par `BulletManager.fire()`

**Étant donné** La Berceuse (30 PV)
**Quand** elle est active
**Alors** elle se tient entre 4 et 8 tuiles du joueur, en se rapprochant ou en s'éloignant en ligne directe
**Et** toutes les 1,5 s, elle inspire pendant 0,5 s (animation et son), puis tire un projectile visé sur le joueur, à 6 tuiles/s

**Étant donné** les deux ennemis
**Quand** on règle leurs valeurs
**Alors** tout vient de `night_light.tres` et `lullaby.tres`

### Story 2.5 : Affronter Le Mouton

En tant que joueur,
je veux un ennemi qui charge en ligne droite et s'assomme contre les murs,
afin de jouer avec la salle pour le punir.

**Exigences :** FR26, FR29

**Critères d'acceptation :**

**Étant donné** Le Mouton (50 PV)
**Quand** il lance une attaque
**Alors** il gratte le sol pendant 0,5 s (télégraphe, animation et son), recule de 0,5 tuile, puis charge en ligne droite vers la position du joueur au moment du télégraphe, à 10 tuiles/s

**Étant donné** une charge en cours
**Quand** Le Mouton heurte un mur
**Alors** il reste étourdi 1 s, puis reprend son cycle

**Étant donné** une charge en cours
**Quand** il touche le joueur vulnérable
**Alors** le contact inflige un coup de ½ cœur, et la charge continue jusqu'au mur

**Étant donné** ses valeurs
**Quand** on les règle
**Alors** tout vient de `sheep.tres`

### Story 2.6 : Enchaîner les vagues dans l'arène

En tant que joueur,
je veux que l'arène m'envoie des vagues d'ennemis variées,
afin de m'entraîner au combat sans fin.

**Exigences :** FR32, AR24 (F1)

**Critères d'acceptation :**

**Étant donné** l'arène
**Quand** une partie démarre
**Alors** une première vague apparaît, tirée d'une liste de vagues définie en données (types d'ennemis et nombre)

**Étant donné** une vague en cours
**Quand** le dernier ennemi meurt
**Alors** `Events.room_cleared` est émis
**Et** la vague suivante apparaît après une courte pause réglable
**Et** la liste de vagues reboucle en fin de liste

**Étant donné** un build de debug
**Quand** on ouvre le panneau F1
**Alors** on peut faire apparaître un ennemi choisi, tuer tous les ennemis et passer à la vague suivante

### Story 2.7 : Lire son état dans le HUD

En tant que joueur,
je veux voir mes cœurs, mon armure et mes emplacements d'objet d'un coup d'œil,
afin de ne jamais quitter le combat des yeux.

**Exigences :** FR33, AR22

**Critères d'acceptation :**

**Étant donné** une partie en cours
**Quand** le HUD s'affiche
**Alors** il occupe la bande de 24 px en haut de l'écran, hors de la zone jouable
**Et** il montre les cœurs, l'armure en demi-cœurs bleus, les Éclats (0) et les emplacements de l'objet actif et du consommable, vides
**Et** une place est réservée à la jauge de lucidité

**Étant donné** un coup reçu ou de l'armure ajoutée
**Quand** l'état du joueur change
**Alors** le HUD se met à jour par signaux, sans jamais modifier l'état du jeu

### Story 2.8 : Dire si sa mort était juste

En tant que développeur qui fait jouer ses amis,
je veux qu'on demande après chaque mort si elle était juste, et journaliser les sessions,
afin de mesurer les indicateurs de playtest.

**Exigences :** FR34, NFR12, AR25

**Critères d'acceptation :**

**Étant donné** l'écran de réveil après une mort
**Quand** il s'affiche
**Alors** il demande « cette mort était-elle juste ? » avec Oui et Non
**Et** la question ne bloque pas la relance : relancer sans répondre enregistre une absence de réponse

**Étant donné** une session de jeu
**Quand** des événements se produisent (début de partie, mort et sa cause, réponse, fin de session)
**Alors** l'autoload de télémétrie, qui écoute `Events` uniquement, les écrit dans `user://telemetry/<session>.json`
**Et** aucun système n'appelle directement la télémétrie
**Et** le journal donne, par session, la durée de jeu, le nombre de parties et le taux de « oui »
**Et** la télémétrie est présente dans les builds envoyés aux amis

## Epic 3 : Jouer avec sa lucidité

On dépense sa lucidité en Éveil et en Glissement, on glisse vers l'abandon (plus de danger, plus de dégâts) et on la regagne par le graze et le dash parfait. Cet epic valide le jalon A.

### Story 3.1 : Voir sa lucidité et ses paliers

En tant que joueur,
je veux une jauge de lucidité lisible qui annonce chaque changement de palier,
afin de savoir à tout moment où j'en suis.

**Exigences :** FR16, FR17, FR25 (jauge et son), AR10, NFR12 (temps par palier)

**Critères d'acceptation :**

**Étant donné** le début d'une partie
**Quand** le joueur apparaît
**Alors** il porte un objet `Lucidity` (`RefCounted`) à 100, avec des paliers lus dans `LucidityTuning.tres` : Lucide de 100 à 76, Flottant de 75 à 51, Dérive de 50 à 26, Abandon de 25 à 1, Abandon total à 0

**Étant donné** la jauge à 95
**Quand** un gain de +10 arrive
**Alors** elle s'arrête à 100, et le surplus est perdu
**Et** la valeur ne descend jamais sous 0

**Étant donné** un changement de palier, dans un sens ou dans l'autre
**Quand** `live_tier` change
**Alors** `tier_changed` est émis, `Events.lucidity_tier_changed` est relayé, et un son de palier se joue

**Étant donné** le HUD
**Quand** la lucidité change
**Alors** la jauge occupe la place réservée par la Story 2.7, montre les limites des paliers et se met à jour par `value_changed`

**Étant donné** un build de debug
**Quand** on utilise le panneau F1
**Alors** on peut fixer la lucidité à une valeur choisie par `lucidity.set_value()`
**Et** F3 affiche le palier en direct

**Étant donné** la télémétrie
**Quand** une partie se termine
**Alors** le journal donne le temps passé dans chaque palier

### Story 3.2 : Regagner sa lucidité par le skill

En tant que joueur,
je veux regagner de la lucidité en frôlant les projectiles et en dashant au bon moment,
afin que mon skill nourrisse mes pouvoirs.

**Exigences :** FR22, AR10, AR11, FR68 (sons du graze et du dash parfait, provisoires)

**Critères d'acceptation :**

**Étant donné** un projectile ennemi qui passe à moins d'une tuile de la hitbox du joueur sans la toucher
**Quand** le joueur n'est pas invulnérable
**Alors** il gagne +2, `Events.player_grazed` est émis, un son de frôlement discret se joue, et le projectile est marqué `counted`
**Et** le même projectile ne rapporte plus rien ensuite

**Étant donné** le joueur invulnérable, après un dash ou après un coup
**Quand** un projectile ennemi le frôle
**Alors** aucun graze n'est compté

**Étant donné** le joueur en dash
**Quand** son invulnérabilité évite un projectile qui l'aurait touché
**Alors** il gagne +5, `Events.perfect_dash` est émis, un son plus marqué se joue, et ce projectile ne peut plus rapporter de graze
**Et** le dash parfait est compté par projectile évité, pas par dash

**Étant donné** une salle, ou une vague de l'arène
**Quand** les grazes ont déjà rapporté +20 depuis `begin_room()`
**Alors** les grazes suivants ne rapportent plus rien, et ce plafond est tenu par `Lucidity.gain()`
**Et** `begin_room()` est appelé au début de chaque vague de l'arène

**Étant donné** une vague vidée
**Quand** `room_cleared` est émis
**Alors** le joueur gagne +5

**Étant donné** un build de debug
**Quand** on appuie sur F2
**Alors** le rayon de graze s'affiche

### Story 3.3 : Dépenser sa lucidité : Éveil

En tant que joueur,
je veux effacer tous les projectiles d'un sursaut de lucidité,
afin de me sortir d'une situation perdue au prix de ma jauge.

**Exigences :** FR21, FR23

**Critères d'acceptation :**

**Étant donné** la jauge à 30 ou plus, et Éveil disponible
**Quand** le joueur appuie sur clic droit ou sur LT
**Alors** `try_spend(30)` retire 30, tous les projectiles ennemis à l'écran disparaissent, et les ennemis situés à moins de 3 tuiles sont repoussés de 2 tuiles, sans traverser les murs
**Et** Éveil se recharge pendant 1 s

**Étant donné** la jauge sous 30, ou Éveil en recharge
**Quand** le joueur l'active
**Alors** rien n'est consommé, et un son de refus se joue

**Étant donné** le joueur qui prend un coup
**Quand** le coup est appliqué
**Alors** la lucidité ne change pas

**Étant donné** les valeurs d'Éveil
**Quand** on les règle
**Alors** le coût, la recharge, le rayon et la distance de recul viennent d'une Resource
**Et** chaque dépense est journalisée par la télémétrie, avec le palier au moment de la dépense

### Story 3.4 : Dépenser sa lucidité : Glissement

En tant que joueur,
je veux me téléporter vers le point visé à travers les projectiles,
afin de traverser un mur de tirs au prix de ma jauge.

**Exigences :** FR21, FR24 (sans les trous), AR29 (rayon)

**Critères d'acceptation :**

**Étant donné** l'arène
**Quand** cette story est livrée
**Alors** l'arène contient quelques obstacles bas (ils bloquent les déplacements, pas les tirs) et hauts (ils bloquent tout)

**Étant donné** la jauge à 20 ou plus, et Glissement disponible
**Quand** le joueur appuie sur Maj ou sur LB
**Alors** `try_spend(20)` retire 20, et le joueur se téléporte vers le point visé, à 6 tuiles au plus, à travers les projectiles et les obstacles bas
**Et** il est invulnérable pendant 0,1 s à l'arrivée
**Et** Glissement se recharge pendant 1 s

**Étant donné** un point visé dans un mur, un obstacle haut ou un ennemi, ou une ligne de visée qui en croise un
**Quand** le joueur glisse
**Alors** il arrive au dernier point libre sur la ligne de visée, résolu par `intersect_ray` contre les murs, les obstacles hauts et les ennemis
**Et** il ne franchit jamais les murs de la salle

**Étant donné** le joueur à la souris
**Quand** le curseur est à plus de 6 tuiles
**Alors** la destination est ramenée à 6 tuiles dans la direction du curseur

**Étant donné** le joueur à la manette
**Quand** il glisse
**Alors** la distance suit l'inclinaison du stick droit, de 2 tuiles (juste au-delà de la zone morte) à 6 tuiles (stick à fond)

**Étant donné** la jauge sous 20, ou Glissement en recharge
**Quand** le joueur l'active
**Alors** rien n'est consommé, et le son de refus se joue

### Story 3.5 : Être précis en Lucide, frapper fort dans l'abandon

En tant que joueur,
je veux que chaque palier change ma façon de combattre,
afin de choisir entre la précision et la puissance.

**Exigences :** FR18, AR15 (`StatBlock`)

**Critères d'acceptation :**

**Étant donné** le joueur
**Quand** ses stats sont calculées
**Alors** elles passent par un `StatBlock` : les stats de base viennent des Resources, et les modificateurs `ADD_PERCENT` s'additionnent entre eux avant de s'appliquer à la base

**Étant donné** le palier Lucide en direct
**Quand** le joueur tire
**Alors** ses projectiles vont 30 % plus vite, et sa hitbox mesure 4×4 px au lieu de 6×6

**Étant donné** le palier en direct qui passe de Lucide à Flottant, Dérive, Abandon puis Abandon total
**Quand** les modificateurs se mettent à jour sur `tier_changed`
**Alors** les dégâts par tir valent 11, 12, puis 13,5 en Abandon et en Abandon total (bonus de +10 %, +20 % et +35 %)
**Et** la précision du palier Lucide disparaît dès qu'on le quitte

**Étant donné** la jauge qui remonte en pleine vague
**Quand** le palier en direct remonte
**Alors** les récompenses suivent aussitôt la jauge

### Story 3.6 : Subir le danger du palier le plus bas

En tant que joueur,
je veux que plonger rende la salle plus dangereuse jusqu'à sa fin, même si je remonte,
afin que dépenser soit un vrai risque.

**Exigences :** FR19 (vitesse des projectiles, télégraphes, signalement), AR10, P1

**Critères d'acceptation :**

**Étant donné** le début d'une vague
**Quand** `begin_room()` est appelé
**Alors** `room_tier` prend la valeur de `live_tier`

**Étant donné** une dépense qui fait passer `live_tier` sous `room_tier`
**Quand** la jauge descend
**Alors** `room_tier` suit, `room_danger_raised` est émis, et la salle recalcule son `DangerProfile`
**Et** un son et un effet visuel signalent l'aggravation

**Étant donné** la jauge qui remonte en pleine vague
**Quand** `live_tier` remonte
**Alors** `room_tier` ne change pas avant la vague suivante

**Étant donné** `room_tier` en Dérive ou plus bas
**Quand** un ennemi tire
**Alors** son projectile part 10 % plus vite
**Et** les projectiles déjà en vol gardent leur vitesse

**Étant donné** `room_tier` en Abandon ou plus bas
**Quand** un ennemi lance un télégraphe
**Alors** sa durée est multipliée par 0,85, sans jamais descendre sous 0,4 s

**Étant donné** tout système de danger
**Quand** il lit la lucidité
**Alors** il ne lit que `room_tier`, jamais `live_tier`
**Et** F3 affiche `room_tier`

### Story 3.7 : Voir arriver le renfort de l'abandon

En tant que joueur,
je veux qu'un ennemi de plus soit annoncé quand je tombe en Abandon,
afin que l'aggravation reste lisible.

**Exigences :** FR19 (renfort), AR14 (premier flux `combat`)

**Critères d'acceptation :**

**Étant donné** une partie qui démarre
**Quand** le nœud `Run` est créé
**Alors** il porte un `RunRng`, avec une seed de run tirée sans le RNG global et journalisée, et un flux `combat`

**Étant donné** l'arène, avec des marqueurs `ReinforcementSpawn`
**Quand** `room_tier` atteint Abandon pour la première fois dans la vague
**Alors** un renfort est programmé : une copie du type d'ennemi le plus présent dans la vague. Une égalité se départage dans le flux `combat`.
**Et** son emplacement est annoncé 0,6 s avant l'apparition, par un signe visuel et un son
**Et** l'emplacement est choisi dans le flux `combat` parmi les marqueurs situés à 3 tuiles ou plus du joueur

**Étant donné** un renfort déjà apparu dans la vague
**Quand** le palier redescend encore, jusqu'à Abandon total
**Alors** aucun second renfort n'apparaît

**Étant donné** une salle marquée comme salle de cauchemar
**Quand** `room_tier` atteint Abandon
**Alors** aucun renfort n'apparaît

### Story 3.8 : Sentir l'abandon, sans perdre le combat de vue

En tant que joueur,
je veux que le décor ondule et que la musique s'étouffe à mesure que je plonge, avec des réglages pour adoucir ces effets,
afin de sentir le rêve déborder sans jamais perdre la lisibilité du combat.

**Exigences :** FR25 (distorsions, passe-bas), FR67, AR19, AR21 (passe-bas), NFR8

**Critères d'acceptation :**

**Étant donné** la scène de jeu
**Quand** elle s'affiche
**Alors** les couches suivent cet ordre : décor, post-traitement, entités, combat (télégraphes et projectiles), puis HUD

**Étant donné** le palier en direct qui descend
**Quand** les effets se mettent à jour
**Alors** l'aberration chromatique et l'ondulation du décor augmentent à chaque palier, avec une intensité égale à f(palier) × le réglage d'accessibilité
**Et** les entités, les télégraphes, les projectiles et le HUD restent nets à tous les paliers

**Étant donné** une boucle musicale provisoire sur le bus `Music`
**Quand** le palier en direct descend
**Alors** le filtre passe-bas du bus `Music` étouffe de plus en plus la musique

**Étant donné** les réglages d'accessibilité
**Quand** le joueur baisse l'intensité des distorsions ou des tremblements d'écran, ou active le mode photosensibilité
**Alors** les effets visuels se réduisent en conséquence. Le mode photosensibilité supprime les flashs plein écran et plafonne les distorsions.
**Et** ces réglages n'ont aucun effet sur le gameplay, et ils sont sauvegardés dans `settings.cfg`

## Epic 4 : Explorer un étage né d'une seed

On parcourt un étage Endormissement de 16 salles prédessinées, avec des trous, des meubles et des portes qui se ferment, et une carte qui se révèle au fil de l'exploration. Tout l'étage découle d'une seed reproductible.

### Story 4.1 : Tester la logique du jeu sans le lancer

En tant que développeur,
je veux un framework de test et des tests sur les classes de logique pure,
afin que le jalon B s'appuie sur une base vérifiée, et que le test des 10 seeds soit possible.

**Exigences :** AR26

**Critères d'acceptation :**

**Étant donné** le jalon A validé
**Quand** le framework de test est choisi avec `gds-test-framework` (GUT ou GdUnit4)
**Alors** il est installé dans `game/addons/`, et les tests vivent dans `game/tests/unit/` et `game/tests/integration/`, en miroir des dossiers de code

**Étant donné** le framework installé
**Quand** on lance les tests en ligne de commande, en headless
**Alors** les tests de `Lucidity` passent : bornes, paliers, plafond de graze, `try_spend`, `room_tier`
**Et** les tests de `StatBlock` passent : cumul additif des `ADD_PERCENT`
**Et** une commande de `tools/` lance toute la suite

### Story 4.2 : Jouer une salle prédessinée

En tant que joueur,
je veux des salles dessinées à la main, avec leurs obstacles, leurs vagues et des portes qui se ferment,
afin que chaque salle ait sa propre personnalité.

**Exigences :** FR35, FR36, AR16

**Critères d'acceptation :**

**Étant donné** la scène de base `room_base.tscn`
**Quand** on crée une salle
**Alors** elle a les `TileMapLayer` `Floor`, `Walls`, `LowObstacles`, `HighObstacles` et `Pits`, les marqueurs `EnemySpawn` (type, vague), `ReinforcementSpawn`, `Door` (côté), `Furniture` et `Trigger`, et des métadonnées (type, phase, taille)
**Et** une salle standard mesure 36×19 tuiles jouables, sur un tileset `onset` provisoire

**Étant donné** le joueur qui entre dans une salle de combat
**Quand** il y entre
**Alors** `begin_room()` est appelé, les portes se ferment, et les ennemis apparaissent vague par vague selon leurs marqueurs
**Et** quand la dernière vague est vidée, `room_cleared` est émis et les portes s'ouvrent

**Étant donné** les obstacles
**Quand** les tirs les rencontrent
**Alors** les obstacles bas laissent passer les tirs des deux camps, et les obstacles hauts les arrêtent

**Étant donné** le script `validate_rooms.gd`, lancé en headless par `tools/`
**Quand** il parcourt `rooms/pool/`
**Alors** il signale toute salle aux dimensions invalides, sans porte, avec un `EnemySpawn` à moins de 3 tuiles d'une entrée, ou sans `ReinforcementSpawn`
**Et** il renvoie un code d'erreur si une salle est invalide

### Story 4.3 : Tomber dans les trous

En tant que joueur,
je veux que les trous du rêve me fassent chuter si je m'y laisse aller,
afin de sentir les sursauts hypnagogiques de l'Endormissement.

**Exigences :** FR4 (trous), FR24 (trou comme destination), FR40, AR29 (trous)

**Critères d'acceptation :**

**Étant donné** le joueur qui marche sur le sol
**Quand** chaque tick passe
**Alors** `PlayerMotor` mémorise la dernière position sûre, sur une cellule de sol

**Étant donné** le joueur dont le déplacement, le dash ou le Glissement se termine sur une cellule de `Pits`
**Quand** la chute est détectée
**Alors** il subit un coup de source `PIT` (½ cœur, ou la valeur de la stat `pit_damage`), devient invulnérable 1 s et revient à la dernière position sûre

**Étant donné** un dash qui commence avant un trou
**Quand** sa position finale est hors du trou
**Alors** le joueur le survole sans tomber
**Et** si la position finale est dans le trou, il tombe

**Étant donné** un Glissement vers un point situé dans un trou
**Quand** le joueur arrive
**Alors** il tombe

**Étant donné** la stat `can_fly_over_pits` du `StatBlock`
**Quand** elle est active
**Alors** le joueur ne tombe pas dans les trous
**Et** cette stat existe dès maintenant pour les objets de l'Epic 5

### Story 4.4 : Jouer avec la salle : meubles et éléments déclenchables

En tant que joueur,
je veux des meubles qui arrêtent les tirs et des éléments à déclencher d'un tir,
afin de me servir de la salle comme d'une arme.

**Exigences :** FR41

**Critères d'acceptation :**

**Étant donné** un meuble du rêve (lit, chaise, pupitre) posé par un marqueur `Furniture`
**Quand** des projectiles des deux camps le touchent
**Alors** ils sont arrêtés, et le meuble perd des PV
**Et** à 0 PV (30 au départ, réglable dans une Resource), il est détruit et ne bloque plus rien

**Étant donné** une lampe posée par un marqueur `Trigger`
**Quand** un tir du joueur la touche
**Alors** les ennemis situés à moins de 3 tuiles sont éblouis pendant 1 s : ils n'avancent ni n'attaquent, et leurs télégraphes en cours sont annulés
**Et** la lampe ne se déclenche qu'une fois par salle

### Story 4.5 : Des ennemis qui contournent les obstacles

En tant que joueur,
je veux que les ennemis me poursuivent intelligemment entre les obstacles,
afin que les salles dessinées ne les piègent pas bêtement.

**Exigences :** AR23 (`AStarGrid2D`)

**Critères d'acceptation :**

**Étant donné** une salle avec des obstacles et des trous
**Quand** elle est chargée
**Alors** une `AStarGrid2D` est construite sur sa grille, avec les murs, les obstacles et les trous comme cellules bloquées

**Étant donné** Le Somnambule ou La Berceuse
**Quand** la ligne directe vers sa cible est bloquée
**Alors** il suit le chemin de l'`AStarGrid2D`
**Et** le chemin est recalculé à intervalle réglable, jamais à chaque frame pour tous les ennemis

**Étant donné** Le Mouton
**Quand** il charge
**Alors** il charge toujours en ligne droite, et un obstacle haut l'arrête et l'étourdit comme un mur

### Story 4.6 : Explorer les grandes salles

En tant que joueur,
je veux des salles de deux écrans où la caméra me suit,
afin de varier l'espace de combat.

**Exigences :** FR9 (caméra qui suit), FR35 (grandes salles)

**Critères d'acceptation :**

**Étant donné** une salle de 2 écrans en largeur ou en hauteur
**Quand** le joueur s'y déplace
**Alors** la caméra le suit, bornée aux limites de la salle, sans jamais montrer l'extérieur
**Et** la bande de HUD reste fixe en haut de l'écran

**Étant donné** une salle d'un écran
**Quand** le joueur y entre
**Alors** la caméra reste fixe et centrée

**Étant donné** une grande salle
**Quand** elle est validée
**Alors** `validate_rooms.gd` accepte ses dimensions (72×19 ou 36×38 tuiles jouables, à ajuster selon la grille)

### Story 4.7 : Générer l'étage depuis une seed

En tant que joueur,
je veux qu'un étage différent soit assemblé à chaque run, et identique pour une même seed,
afin de rejouer sans cesse et de partager une run intéressante.

**Exigences :** FR37, FR43 (déterminisme), NFR5, AR14, AR17

**Critères d'acceptation :**

**Étant donné** une seed de run (entier 64 bits)
**Quand** `RunRng` est créé
**Alors** il fournit les flux `layout`, `rooms`, `treasure`, `shop`, `drops`, `combat` et `cosmetic`, chacun initialisé par un hachage de `(seed, flux, étage)`
**Et** la seed s'affiche comme un code de 8 caractères, qui se convertit dans les deux sens

**Étant donné** `FloorDef` `onset.tres`, qui liste le pool de salles et la composition de l'étage
**Quand** `FloorGenerator` (`RefCounted`) génère l'étage
**Alors** il obtient 16 salles : 1 départ, 12 combats, 1 trésor, 1 boutique et 1 cauchemar
**Et** la grille est étendue depuis le départ, et le chemin vers chaque salle est garanti
**Et** le cauchemar, le trésor et la boutique sont placés sur des impasses, le cauchemar à 4 salles ou plus du départ
**Et** aucune salle prédessinée n'apparaît deux fois
**Et** si les contraintes échouent, un nouveau tirage est fait dans le flux `layout`

**Étant donné** la même seed, avec les mêmes déblocages
**Quand** l'étage est généré 10 fois, pour 10 seeds différentes
**Alors** le test automatisé obtient chaque fois la même disposition et les mêmes salles
**Et** aucun appel au RNG global n'existe dans `generation/`
**Et** les tests utilisent un pool de salles factices, sans attendre le pool réel de la Story 4.10

**Étant donné** les salles trésor, boutique et cauchemar, encore sans contenu
**Quand** l'étage est généré
**Alors** elles existent comme salles provisoires : le trésor et la boutique sont vides, et le cauchemar est une salle de combat renforcée jusqu'à l'Epic 6

### Story 4.8 : Passer d'une salle à l'autre

En tant que joueur,
je veux parcourir l'étage en choisissant l'ordre des salles,
afin d'explorer à ma façon.

**Exigences :** FR24 (portes fermées), FR36, FR39 (ordre libre), FR42, AR17 (préchargement), AR20

**Critères d'acceptation :**

**Étant donné** une nouvelle partie
**Quand** elle démarre
**Alors** l'étage est généré, ses salles sont préchargées en tâche de fond, et le joueur apparaît dans la salle de départ
**Et** l'arène du jalon A reste accessible depuis le panneau F1

**Étant donné** une porte ouverte
**Quand** le joueur la franchit
**Alors** la salle quittée est libérée, la salle voisine est instanciée dans `RoomSlot`, et le joueur entre par la porte correspondante, avec une transition courte
**Et** une seule salle est active à la fois

**Étant donné** une salle déjà vidée
**Quand** le joueur y revient
**Alors** ses portes sont ouvertes, et aucun ennemi ne réapparaît

**Étant donné** une salle de combat non vidée
**Quand** le joueur y entre
**Alors** les portes se ferment, et Glissement ne peut pas les franchir

**Étant donné** la salle de départ du premier étage
**Quand** le joueur y apparaît
**Alors** elle est calme, sans ennemi, et montre un tutoriel visuel des contrôles (déplacement, tir, dash, pouvoirs), adapté au périphérique actif et localisé

### Story 4.9 : Consulter la carte de l'étage

En tant que joueur,
je veux une carte qui se révèle au fil de l'exploration,
afin de m'orienter et de choisir où aller.

**Exigences :** FR39 (carte)

**Critères d'acceptation :**

**Étant donné** un étage en cours
**Quand** le joueur maintient Tab ou Select
**Alors** la carte s'affiche par-dessus le jeu, sans le mettre en pause, et disparaît au relâchement

**Étant donné** l'exploration en cours
**Quand** la carte s'affiche
**Alors** les salles visitées sont dessinées, et les salles adjacentes à une salle visitée apparaissent comme inexplorées
**Et** la salle actuelle est mise en évidence
**Et** le trésor, la boutique et le cauchemar portent leur icône une fois découverts

### Story 4.10 : Remplir le pool de l'Endormissement

En tant que joueur,
je veux au moins 30 salles de combat différentes,
afin que deux runs ne se ressemblent pas.

**Exigences :** FR38, FR40 (trous omniprésents)

**Critères d'acceptation :**

**Étant donné** `rooms/pool/onset/`
**Quand** le pool est livré
**Alors** il contient au moins 30 salles de combat nommées `onset_combat_<nnn>.tscn`, ainsi que les salles de départ, de trésor, de boutique et de cauchemar
**Et** des trous sont présents dans la plupart des salles de combat
**Et** les 4 ennemis y sont combinés en vagues variées, et quelques salles sont grandes

**Étant donné** le pool complet
**Quand** `validate_rooms.gd` tourne
**Alors** toutes les salles passent

**Étant donné** 10 seeds différentes
**Quand** l'étage est généré
**Alors** les 12 salles de combat tirées varient d'une seed à l'autre

### Story 4.11 : Afficher et saisir une seed

En tant que joueur,
je veux voir la seed de ma run et pouvoir en saisir une,
afin de rejouer ou de partager une run.

**Exigences :** FR43 (affichage et saisie), AR24 (F1), AR27 (seed journalisée), AR29 (`seeded`)

**Critères d'acceptation :**

**Étant donné** une run en cours
**Quand** le joueur ouvre le menu de pause, ou meurt
**Alors** le code de seed de 8 caractères s'affiche

**Étant donné** l'écran de réveil, ou le menu de pause
**Quand** le joueur choisit « Nouvelle partie avec une seed » et saisit un code valide
**Alors** une run démarre sur cette seed, avec `RunState.seeded = true`
**Et** un code invalide est refusé avec un message localisé, sans lancer de run

**Étant donné** une run qui démarre
**Quand** elle est lancée
**Alors** `Log.info("run", ...)` journalise sa seed

**Étant donné** un build de debug
**Quand** on utilise le panneau F1
**Alors** on peut relancer avec une seed donnée

## Epic 5 : Construire son build

On trouve et on achète les 8 objets et les 2 consommables, on déclenche la synergie Chute, et on gagne des Éclats et des drops selon son palier.

### Story 5.1 : Ramasser un objet et comprendre son prix

En tant que joueur,
je veux ramasser des objets dont le bonus et le coût sont écrits en clair,
afin de choisir mon build en connaissance de cause.

**Exigences :** FR44, FR46, FR47, AR15

**Critères d'acceptation :**

**Étant donné** le joueur
**Quand** il apparaît
**Alors** il porte un composant `BuildCarrier` (`StatBlock`, `Loadout`, `TagTracker`), qui émet `hit_taken`, `dash_ended` et `room_cleared`

**Étant donné** un `ItemDef` (`id`, tags, clés de nom et de description, modificateurs, `effect_script` facultatif, coût en lucidité facultatif)
**Quand** le joueur passe sur l'objet posé au sol
**Alors** l'objet entre dans son `Loadout`, ses modificateurs s'appliquent, et son `ItemEffect` éventuel est attaché
**Et** une bannière affiche son nom, son bonus et son coût, depuis les fichiers de localisation

**Étant donné** Dent qui tombe
**Quand** le joueur la ramasse
**Alors** il gagne +30 % de dégâts et perd 1 cœur max
**Et** une deuxième Dent ajoute encore +30 % et −1 cœur max
**Et** s'il ne reste qu'un cœur max, la Dent s'affiche grisée et ne peut pas être prise

**Étant donné** Jambes de plomb
**Quand** le joueur la ramasse
**Alors** ses tirs traversent les ennemis, par `BulletParams` et sans code spécifique dans la boucle des projectiles
**Et** sa vitesse de déplacement baisse de 20 %

**Étant donné** un build de debug
**Quand** on utilise le panneau F1
**Alors** on peut faire apparaître n'importe quel objet

### Story 5.2 : Trouver un objet dans la salle trésor

En tant que joueur,
je veux un objet gratuit dans la salle trésor de chaque étage,
afin d'avoir toujours au moins une pièce de build.

**Exigences :** FR44 (pas de doublon), FR59

**Critères d'acceptation :**

**Étant donné** la salle trésor
**Quand** le joueur y entre pour la première fois
**Alors** un objet tiré du pool trésor, dans le flux `treasure`, l'attend sur un piédestal
**Et** au MVP, les pools trésor et boutique contiennent les 8 objets, et sont définis en données

**Étant donné** un objet déjà obtenu pendant la run
**Quand** un pool est tiré
**Alors** cet objet est exclu, sauf la Dent qui tombe

**Étant donné** une Dent qui tombe tirée alors que le joueur n'a plus qu'un cœur max
**Quand** la salle trésor tire son objet
**Alors** un autre objet est tiré à sa place

**Étant donné** la même seed et les mêmes choix d'objets
**Quand** on rejoue
**Alors** la salle trésor propose le même objet

### Story 5.3 : Porter un consommable

En tant que joueur,
je veux porter un consommable à double tranchant,
afin de le garder pour le bon moment.

**Exigences :** FR55

**Critères d'acceptation :**

**Étant donné** le joueur sans consommable
**Quand** il en ramasse un
**Alors** le consommable occupe l'emplacement du HUD
**Et** s'il en portait déjà un, l'ancien est déposé au sol

**Étant donné** Se pincer
**Quand** le joueur l'utilise avec A ou Y
**Alors** il gagne +25 de lucidité et perd ½ cœur, jamais pris sur l'armure
**Et** s'il ne lui reste qu'½ cœur, l'utilisation est refusée avec le son de refus, et rien n'est consommé

**Étant donné** Café
**Quand** le joueur l'utilise
**Alors** sa vitesse et sa cadence augmentent de 30 % pendant 10 s, puis sa vitesse baisse de 20 % pendant 5 s
**Et** ces effets passent par des modificateurs temporaires du `StatBlock`

**Étant donné** les consommables
**Quand** on règle leurs valeurs
**Alors** tout vient de `pinch.tres` et `coffee.tres` (`ConsumableDef`)

### Story 5.4 : Gagner des Éclats et des drops selon son palier

En tant que joueur,
je veux que vider une salle rapporte plus quand j'ai plongé,
afin que l'abandon paie.

**Exigences :** FR14 (ramassage d'armure), FR20, FR56 (salles de combat), FR57

**Critères d'acceptation :**

**Étant donné** une salle de combat vidée
**Quand** `room_cleared` est émis avec le `room_tier` de la salle
**Alors** le joueur gagne de 1 à 3 Éclats, tirés dans le flux `drops`, multipliés par le loot du palier (×1 en Lucide, ×1,25 en Flottant, ×1,5 en Dérive, ×2 en Abandon et en Abandon total) et arrondis à l'entier le plus proche
**Et** le HUD met les Éclats à jour

**Étant donné** la même salle vidée
**Quand** le drop est tiré
**Alors** sa chance vaut 30 % × le loot du palier, et il apparaît par `Drops.spawn(kind, position, rng)`
**Et** son type est tiré parmi ½ cœur, ½ armure, un consommable ou 3 Éclats

**Étant donné** un ½ cœur au sol, avec le joueur sans blessure, ou de l'armure au sol, avec le joueur au plafond de 12 cœurs
**Quand** le joueur passe dessus
**Alors** le ramassable reste au sol

**Étant donné** les tirages d'Éclats et de drops
**Quand** le joueur prend un objet ou joue en Abandon
**Alors** les tirages d'objets suivants ne sont pas décalés, car chaque type de tirage a son propre flux

### Story 5.5 : Acheter à la boutique

En tant que joueur,
je veux dépenser mes Éclats dans une boutique,
afin de transformer ma prise de risque en objets.

**Exigences :** FR58

**Critères d'acceptation :**

**Étant donné** la boutique
**Quand** le joueur y entre pour la première fois
**Alors** elle propose 2 objets à 15 Éclats tirés dans le pool boutique (flux `shop`, sans doublon), 1 consommable à 5, 1 cœur à 4 et 1 armure à 5
**Et** chaque article affiche son prix, et les objets montrent leur bonus et leur coût

**Étant donné** assez d'Éclats
**Quand** le joueur achète un article
**Alors** les Éclats sont retirés, et l'article est obtenu : le cœur soigne 1 cœur, et l'armure ajoute 1 cœur d'armure

**Étant donné** pas assez d'Éclats, ou un cœur ou une armure impossibles à prendre (plafond, santé pleine)
**Quand** le joueur tente l'achat
**Alors** l'achat est refusé avec le son de refus, et rien n'est retiré

**Étant donné** la boutique, à la reprise ou à la seconde visite
**Quand** le joueur y revient
**Alors** les articles déjà achetés ont disparu, et les autres sont toujours là

### Story 5.6 : Les objets de la Chute : Ailes de papier et Chute libre

En tant que joueur,
je veux des objets qui jouent avec la chute,
afin de construire un build autour des trous et de l'esquive.

**Exigences :** FR48, FR49, AR15 (`ItemEffect`)

**Critères d'acceptation :**

**Étant donné** Ailes de papier
**Quand** le joueur la porte
**Alors** il survole les trous, par `can_fly_over_pits`
**Et** chaque coup reçu retire le survol pendant 3 s
**Et** si ce coup arrive au-dessus d'un trou, le joueur tombe, sans perdre plus que le coup

**Étant donné** Chute libre
**Quand** le joueur reste sans être touché
**Alors** il gagne +5 % de dégâts par seconde, jusqu'à +50 %, par un modificateur du `StatBlock`

**Étant donné** Chute libre avec un bonus actif
**Quand** le joueur prend un coup
**Alors** le bonus retombe à zéro, et ce coup retire ½ cœur de plus

**Étant donné** chaque `ItemEffect`
**Quand** son objet est retiré
**Alors** `detach()` le déconnecte de tous les signaux qu'il écoutait

### Story 5.7 : Déclencher les synergies de la Chute

En tant que joueur,
je veux qu'en réunissant des objets Chute, une synergie s'annonce et change ma façon de jouer,
afin que les combinaisons se devinent et récompensent.

**Exigences :** FR54

**Critères d'acceptation :**

**Étant donné** `TagTracker`
**Quand** le joueur obtient des objets
**Alors** il compte les objets distincts par tag : deux Dents qui tombent ne comptent qu'une fois

**Étant donné** 2 objets Chute distincts
**Quand** le seuil est atteint
**Alors** `synergy_activated` est émis, et une bannière annonce « Piqué » avec son effet en clair
**Et** chaque dash se termine sur une onde de choc de 15 dégâts, sur un rayon de 1,5 tuile, qui touche les ennemis et les meubles

**Étant donné** 3 objets Chute distincts
**Quand** le seuil est atteint
**Alors** « Chute sans fin » est annoncée : l'onde passe à 30 dégâts sur 2,5 tuiles, et une chute dans un trou ne retire plus de cœur (`pit_damage` = 0)

**Étant donné** les synergies
**Quand** on les règle
**Alors** elles sont définies dans `fall_2.tres` et `fall_3.tres` (`SynergyDef`)

### Story 5.8 : Utiliser l'objet actif : Réveil cassé

En tant que joueur,
je veux un objet actif qui ralentit le rêve autour de moi,
afin de reprendre la main dans un moment critique.

**Exigences :** FR45, FR51, AR13 (ralenti par groupe)

**Critères d'acceptation :**

**Étant donné** Réveil cassé chargé, et la jauge à 15 ou plus
**Quand** le joueur appuie sur E ou X
**Alors** `try_spend(15)` retire 15 de lucidité, et `GameClock` ralentit tous les groupes sauf `PLAYER` à 50 % pendant 4 s, avant de revenir à 1 tout seul
**Et** la charge est vidée

**Étant donné** la jauge sous 15, ou un objet non chargé
**Quand** le joueur tente de l'utiliser
**Alors** l'utilisation est refusée avec le son de refus, et rien n'est consommé

**Étant donné** Réveil cassé déchargé
**Quand** 3 salles sont vidées
**Alors** il est de nouveau chargé, et le HUD montre la progression de la charge

**Étant donné** le joueur qui porte un objet actif
**Quand** il en ramasse un autre
**Alors** l'ancien est déposé au sol avec sa charge

### Story 5.9 : Copie d'examen vierge et Être nu en public

En tant que joueur,
je veux des objets qui changent le rythme des salles,
afin de prendre des risques calculés.

**Exigences :** FR50, FR53

**Critères d'acceptation :**

**Étant donné** Copie d'examen vierge
**Quand** le joueur entre dans une salle de combat non vidée
**Alors** un chrono de 45 s s'affiche et défile
**Et** à 0, les ennemis restants se déplacent et tirent 30 % plus vite, ennemis sans projectiles compris
**Et** le chrono ne tourne ni dans la salle du cauchemar ni dans une salle déjà vidée

**Étant donné** Copie d'examen vierge
**Quand** une salle de combat est vidée
**Alors** un drop garanti s'ajoute au tirage normal

**Étant donné** Être nu en public
**Quand** le joueur le ramasse
**Alors** toute son armure est perdue, et il ne peut plus en ramasser ni en acheter
**Et** pendant les 1,5 premières secondes de chaque salle, les ennemis ne tirent pas
**Et** la boutique propose un cœur à la place de l'armure

### Story 5.10 : Affronter son reflet : le Miroir

En tant que joueur,
je veux un objet qui double mon tir, mais fait parfois surgir mon reflet hostile,
afin de payer ma puissance en affrontant mon propre build.

**Exigences :** FR52, AR15 (`BuildCarrier` sur une autre entité)

**Critères d'acceptation :**

**Étant donné** le Miroir
**Quand** le joueur tire
**Alors** un second tir part vers l'arrière, par `BulletParams`

**Étant donné** le Miroir porté
**Quand** le joueur entre dans une salle de combat non vidée
**Alors** un reflet hostile apparaît dans 1 salle sur 4, en moyenne, tiré dans le flux `combat`, à 3 tuiles ou plus du joueur
**Et** il n'apparaît jamais dans la salle d'un cauchemar

**Étant donné** le reflet
**Quand** il apparaît
**Alors** il porte un `BuildCarrier` qui reçoit une copie des `ItemDef` du joueur, et a 60 PV × le facteur d'étage
**Et** il tire par le `BulletManager` ennemi : des projectiles à la couleur et au contour ennemis, qui reprennent le motif des tirs du joueur
**Et** chacune de ses attaques est annoncée par un télégraphe d'au moins 0,4 s
**Et** son comportement de déplacement est réglable en données, pour le playtest

## Epic 6 : Une nuit complète, de la chambre au réveil

On s'endort dans la chambre, on bat Le Professeur et on se réveille à l'heure affichée. On peut sauvegarder et quitter, puis reprendre la partie.

### Story 6.1 : Affronter Le Professeur : la Dictée

En tant que joueur,
je veux affronter Le Professeur au bout de l'étage, en commençant par la Dictée,
afin d'avoir un vrai boss à battre.

**Exigences :** FR60 (Dictée, PV, annonce), AR7 (patterns en Resources)

**Critères d'acceptation :**

**Étant donné** la salle du cauchemar générée par l'Epic 4
**Quand** le joueur y entre
**Alors** la salle provisoire est remplacée par `onset_boss_001.tscn` avec Le Professeur, défini par `professor.tres` (`BossDef`), avec 2 500 PV
**Et** une barre de vie du cauchemar s'affiche
**Et** aucun renfort d'Abandon n'apparaît dans cette salle

**Étant donné** le début du combat
**Quand** la première épreuve commence
**Alors** une craie écrit « Dictée » au tableau, depuis les fichiers de localisation, avant la première attaque

**Étant donné** la Dictée, de 100 à 66 % des PV
**Quand** elle est en cours
**Alors** toutes les 2 s, une rangée horizontale de craies traverse la salle à 5 tuiles/s, avec un trou à franchir
**Et** chaque rangée est annoncée par un télégraphe d'au moins 0,4 s
**Et** le motif est une `BossAttack` (Resource), sans valeur en dur dans le script

### Story 6.2 : Affronter Le Professeur : Calcul mental et Examen final

En tant que joueur,
je veux que le combat se durcisse en trois épreuves,
afin que le boss monte en tension jusqu'à la fin.

**Exigences :** FR12 (attaques lourdes), FR60 (Calcul mental, Examen final)

**Critères d'acceptation :**

**Étant donné** Le Professeur à 66 % de ses PV
**Quand** le seuil est franchi
**Alors** la craie écrit « Calcul mental », puis une spirale à 4 bras tourne à 60°/s, et 3 craies visées partent toutes les 3 s

**Étant donné** Le Professeur à 33 % de ses PV
**Quand** le seuil est franchi
**Alors** la craie écrit « Examen final », et les deux premières épreuves alternent
**Et** une règle balaie la salle, annoncée par une ligne 0,8 s avant

**Étant donné** la règle qui touche le joueur vulnérable
**Quand** le coup est appliqué
**Alors** c'est une attaque lourde (`is_heavy`), qui retire 1 cœur

**Étant donné** le build de référence (tir de base, +30 % de dégâts, 70 % des tirs qui touchent)
**Quand** on mesure la durée du combat au playtest
**Alors** elle avoisine 75 s, et l'écart est consigné pour le réglage

### Story 6.3 : Subir l'Interro surprise en Abandon total

En tant que joueur,
je veux qu'un pattern de plus s'ajoute si j'affronte Le Professeur à 0 de lucidité,
afin que l'abandon total se paie aussi contre le boss.

**Exigences :** FR19 (pattern supplémentaire), FR60 (Interro surprise)

**Critères d'acceptation :**

**Étant donné** le `DangerProfile` de la salle du cauchemar
**Quand** `room_tier` atteint Abandon total
**Alors** `boss_extra_pattern` est actif, et l'Interro surprise s'ajoute à l'épreuve en cours : un cercle de 12 craies toutes les 6 s, annoncé par un télégraphe
**Et** l'Interro surprise reste active jusqu'à la fin du combat, même si la jauge remonte

### Story 6.4 : Gagner la nuit

En tant que joueur,
je veux que battre Le Professeur termine la run par une victoire,
afin que la nuit ait une fin.

**Exigences :** FR56 (Éclats du cauchemar), FR61

**Critères d'acceptation :**

**Étant donné** Le Professeur à 0 PV
**Quand** il meurt
**Alors** ses projectiles disparaissent, le joueur gagne 10 Éclats, et `Events.boss_defeated` est émis

**Étant donné** le cauchemar le plus profond débloqué battu (au MVP, toujours Le Professeur)
**Quand** la victoire est constatée
**Alors** `Events.run_ended` est émis avec une issue « victoire », et le personnage se réveille sur un écran de réveil qui indique la victoire

### Story 6.5 : S'endormir dans la chambre

En tant que joueur,
je veux commencer chaque nuit dans la chambre et y revenir à chaque réveil,
afin que la boucle de run ait un lieu.

**Exigences :** FR62, AR20

**Critères d'acceptation :**

**Étant donné** le lancement du jeu
**Quand** `Main` démarre
**Alors** `ActiveScene` contient `Bedroom`, une chambre minimale où le personnage se déplace librement

**Étant donné** le joueur près du lit
**Quand** il appuie sur la touche d'interaction affichée
**Alors** `Main` remplace `Bedroom` par un nouveau `Run`, et la run démarre avec 3 cœurs, 100 de lucidité, 0 Éclat et aucun objet

**Étant donné** une mort ou une victoire
**Quand** l'écran de réveil est passé
**Alors** le joueur revient dans la chambre
**Et** une relance directe depuis l'écran de réveil reste possible et démarre en moins de 3 s

**Étant donné** la chambre
**Quand** le joueur veut saisir une seed
**Alors** une option près du lit permet de la saisir avant de s'endormir

### Story 6.6 : Lire l'heure du réveil

En tant que joueur,
je veux que le réveil de la chambre affiche l'heure à laquelle je me suis réveillé,
afin de mesurer jusqu'où j'ai tenu.

**Exigences :** FR63

**Critères d'acceptation :**

**Étant donné** une run qui commence
**Quand** `WakeClock` est initialisé
**Alors** il marque 23:00, et la phase de l'Endormissement couvre 78 min (valeurs en données)

**Étant donné** 6 salles de combat vidées sur les 12 de l'étage
**Quand** le joueur meurt
**Alors** l'heure du réveil est 23:39, au prorata des salles de combat vidées

**Étant donné** Le Professeur battu
**Quand** la run se termine
**Alors** l'heure du réveil est 00:18, l'heure de fin de la phase

**Étant donné** le retour dans la chambre
**Quand** le joueur regarde le réveil
**Alors** il affiche l'heure de la dernière run, et l'écran de réveil l'affiche aussi

### Story 6.7 : Garder la trace de ses victoires

En tant que joueur,
je veux que mes premières victoires et mes succès soient enregistrés,
afin que les déblocages de l'acte 1 puissent s'y brancher.

**Exigences :** FR65, AR18 (`profile.json`), AR29 (`seeded`)

**Critères d'acceptation :**

**Étant donné** `profile.json`
**Quand** il est écrit
**Alors** il porte un `schema_version`, et son écriture est atomique (fichier temporaire, puis renommage)
**Et** une fonction de migration existe par version de schéma

**Étant donné** un `profile.json` illisible
**Quand** le jeu démarre
**Alors** le fichier est renommé en `.corrupt`, un message localisé prévient le joueur, et le jeu démarre avec un profil neuf

**Étant donné** `progression/achievements.gd`, qui écoute `Events`
**Quand** Le Professeur est battu pour la première fois, ou qu'un succès est obtenu pour la première fois (par exemple une salle vidée en Abandon total, ou une synergie à 3 objets)
**Alors** la première victoire ou le succès est enregistré dans `profile.json`, avec ses statistiques
**Et** rien n'est débloqué au MVP

**Étant donné** une run avec seed saisie (`RunState.seeded = true`)
**Quand** une victoire ou un succès survient
**Alors** rien n'est enregistré

**Étant donné** une run perdue
**Quand** elle se termine
**Alors** objets, Éclats et état de la run sont perdus, et seul le profil persiste

### Story 6.8 : Sauvegarder, quitter et reprendre

En tant que joueur,
je veux quitter en pleine run et reprendre au début de la salle,
afin de ne pas perdre une nuit entamée.

**Exigences :** FR64, AR18 (`run.json`), P3

**Critères d'acceptation :**

**Étant donné** le joueur qui entre dans une salle
**Quand** la salle est entrée, avant l'apparition des ennemis
**Alors** `Run` construit un `RunSnapshot` (seed, étage, carte visitée et vidée, heure du réveil, cœurs, armure, lucidité, Éclats, ids des objets, charge de l'actif, consommable, états de tous les flux RNG)
**Et** `SaveService.write_run()` l'écrit dans `run.json` de façon atomique
**Et** tout état persistant implémente `to_dict()` et `from_dict()`, et les objets sont référencés par leur `id`

**Étant donné** le menu de pause
**Quand** le joueur choisit « Sauvegarder et quitter »
**Alors** le jeu se ferme, et `run.json` est conservé

**Étant donné** un `run.json` présent au lancement, après un « Sauvegarder et quitter » ou un crash
**Quand** le joueur accepte de reprendre
**Alors** la run est reconstruite depuis l'instantané, `run.json` est effacé, et la salle est rejouée depuis son début, avec les mêmes ennemis et les mêmes tirages qu'à la première entrée

**Étant donné** la fin d'une run, par une mort ou une victoire
**Quand** elle se termine
**Alors** `run.json` est effacé

**Étant donné** un test d'intégration de reprise
**Quand** on sauvegarde à l'entrée d'une salle puis on reprend
**Alors** l'état du joueur et les états des flux RNG sont identiques

### Story 6.9 : Tenir vingt nuits sans faille

En tant que développeur,
je veux vérifier les chargements, la stabilité et les indicateurs du jalon B sur des runs complètes,
afin de livrer un MVP fiable au premier cercle.

**Exigences :** NFR3 (chargement d'étage), NFR4, NFR12 (indicateurs du jalon B)

**Critères d'acceptation :**

**Étant donné** la chambre
**Quand** le joueur s'endort
**Alors** l'étage est jouable en moins de 2 s

**Étant donné** 20 runs MVP complètes enchaînées, morts et victoires mêlées
**Quand** elles sont jouées sur la machine de référence
**Alors** aucun crash ne se produit, et le résultat est consigné

**Étant donné** la télémétrie
**Quand** une session se termine
**Alors** le journal donne les runs par session, la durée de chaque run, l'issue de chaque tentative contre Le Professeur et le temps passé sous Lucide

## Epic 7 : Le rêve prend forme, direction artistique et audio de l'Endormissement

Les graphismes IA cohérents, la palette, la musique et les effets sonores remplacent les placeholders. La première story est le test de cohérence des graphismes IA, exigé dès le jalon A. Le reste de la production attend la validation du jalon A.

### Story 7.1 : Tester la cohérence des graphismes IA

En tant que développeur,
je veux produire le joueur et un ennemi sous des contraintes de style strictes, avec toutes leurs animations,
afin de savoir dès le jalon A si les graphismes IA tiennent la route.

**Exigences :** NFR11, risque « graphismes IA » du GDD

**Critères d'acceptation :**

**Étant donné** `art_source/`
**Quand** le test commence
**Alors** un guide de style y est écrit : prompts de référence, palette, tailles (joueur 16×24, ennemis de 16 à 32 px), vue, éclairage, contour

**Étant donné** le joueur et Le Somnambule
**Quand** leurs planches sont produites
**Alors** chacun a les animations `idle`, `walk`, `telegraph`, `attack`, `hurt` et `death` (selon le cas), importées dans `game/` sous `<entité>_<animation>.png`, avec le filtre `Nearest`

**Étant donné** les sprites importés
**Quand** on les joue dans l'arène
**Alors** la cohérence d'une image à l'autre et d'une animation à l'autre est évaluée, et la décision est consignée : continuer, ajuster les contraintes, ou changer d'approche

### Story 7.2 : Fixer la palette de l'Endormissement et les couleurs réservées

En tant que joueur,
je veux un Endormissement aux pastels délavés, où les projectiles ressortent toujours,
afin que le rêve soit beau sans gêner la lecture du combat.

**Exigences :** NFR8, NFR11

**Critères d'acceptation :**

**Étant donné** la palette de l'Endormissement
**Quand** elle est définie
**Alors** elle compte au plus 32 couleurs de pastels délavés, plus les couleurs réservées aux projectiles ennemis (couleur et contour) et aux tirs du joueur

**Étant donné** un script de `tools/`
**Quand** il parcourt les sprites de la phase
**Alors** il signale toute couleur hors palette, et toute utilisation d'une couleur réservée hors des projectiles

**Étant donné** les projectiles ennemis
**Quand** ils sont dessinés sur n'importe quel décor de la phase, à n'importe quel palier
**Alors** ils restent nettement visibles

### Story 7.3 : Donner corps au joueur et aux 4 ennemis

En tant que joueur,
je veux des personnages finaux dont les animations annoncent clairement les attaques,
afin de lire le combat au premier coup d'œil.

**Exigences :** FR26, NFR11

**Critères d'acceptation :**

**Étant donné** le jalon A validé
**Quand** les sprites sont produits
**Alors** le joueur, Le Somnambule, La Veilleuse, Le Mouton et La Berceuse remplacent leurs placeholders, avec toutes leurs animations

**Étant donné** chaque télégraphe
**Quand** on le joue au ralenti (F4)
**Alors** son animation couvre toute la durée du télégraphe et se distingue de l'attente et du déplacement

**Étant donné** les ennemis de contact
**Quand** ils sont à l'écran
**Alors** ils restent visibles en permanence

### Story 7.4 : Habiller les salles et la chambre

En tant que joueur,
je veux des lieux d'enfance flous, des trous qui donnent le vertige et une chambre habitée,
afin de croire au rêve.

**Exigences :** NFR11, FR41 (meubles), FR40 (trous), FR62 (chambre)

**Critères d'acceptation :**

**Étant donné** le tileset `onset.tres`
**Quand** il est livré
**Alors** il couvre le sol, les murs, les obstacles bas et hauts, les trous et les portes, en tuiles de 16×16, dans la palette de la phase
**Et** les salles du pool l'utilisent sans retouche de leur disposition

**Étant donné** les meubles du rêve et la lampe
**Quand** ils sont affichés
**Alors** ils ont un sprite intact, un sprite abîmé et un sprite détruit, et la lampe a son effet d'éblouissement

**Étant donné** la chambre
**Quand** elle est affichée
**Alors** elle montre le lit, le réveil qui affiche l'heure et la grande horloge bloquée sur 4:12

### Story 7.5 : Dessiner Le Professeur, les objets et les ramassables

En tant que joueur,
je veux un boss imposant et des objets reconnaissables d'un coup d'œil,
afin que le MVP soit cohérent de bout en bout.

**Exigences :** NFR11, FR60, FR44

**Critères d'acceptation :**

**Étant donné** Le Professeur
**Quand** il est livré
**Alors** il mesure 64×64 px ou plus, avec ses animations d'épreuve, la craie qui écrit au tableau, et la règle qui balaie la salle

**Étant donné** les 8 objets, les 2 consommables et les ramassables (½ cœur, ½ armure, Éclats)
**Quand** ils sont livrés
**Alors** chacun a son icône, utilisée au sol, dans la boutique, dans la bannière et dans le HUD

**Étant donné** les objets qui modifient les tirs
**Quand** le joueur les porte
**Alors** l'apparence des tirs change (taille, traînée), toujours dans la couleur réservée au joueur et plus discrète que les projectiles ennemis

### Story 7.6 : Composer la musique de l'Endormissement

En tant que joueur,
je veux une musique ambient lente qui s'étouffe quand je plonge,
afin d'entendre le rêve m'échapper.

**Exigences :** FR25 (passe-bas), FR68 (piste)

**Critères d'acceptation :**

**Étant donné** `mus_onset.ogg`
**Quand** elle est importée
**Alors** elle boucle sans coupure audible sur le bus `Music`

**Étant donné** le filtre passe-bas de la Story 3.8
**Quand** le palier descend
**Alors** la piste s'étouffe progressivement, et le réglage de chaque palier est consigné après écoute

### Story 7.7 : Produire les effets sonores du MVP

En tant que joueur,
je veux un son distinct pour chaque action et chaque menace,
afin de jouer autant à l'oreille qu'à l'œil.

**Exigences :** FR68, AR21

**Critères d'acceptation :**

**Étant donné** les placeholders sonores des Epics 1 à 6
**Quand** les effets sont produits
**Alors** environ 40 effets les remplacent, nommés `sfx_<domaine>_<nom>.wav` : tir, impact, dash, coup reçu, mort, chaque télégraphe ennemi, graze, dash parfait, descente et remontée de palier, refus de dépense, Éveil, Glissement, salle vidée, ramassages, achat, synergie, craie du Professeur, règle, interface

**Étant donné** des tirs et des grazes nombreux
**Quand** ils se jouent en même temps
**Alors** la limite de voix par son de l'autoload `Audio` évite la saturation, et le son de graze reste discret

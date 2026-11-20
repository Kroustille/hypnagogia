---
title: 'GDD — Hypnagogia'
game_type: roguelike
platforms: [PC]
status: final
created: '2026-11-20'
updated: '2026-11-20'
sources:
  - '_bmad-output/planning-artifacts/briefs/brief-hypnagogia-2026-11-20/brief.md'
  - '_bmad-output/planning-artifacts/briefs/brief-hypnagogia-2026-11-20/addendum.md'
  - '_bmad-output/planning-artifacts/hypnagogia-brainstorm.md'
  - '_bmad-output/planning-artifacts/brainstorm-stress-test.md'
---

# Hypnagogia : Game Design Document

**Auteur :** Kroustille
**Type de jeu :** Roguelike (twin-stick shooter)
**Plateforme cible :** PC

> **Lire ce document.**
> - **Chiffres** : toutes les valeurs numériques (vitesses, coûts, dégâts, durées, prix) sont des **valeurs de départ**. Le jalon A les règle au playtest, et chaque changement est consigné dans le journal de décisions.
> - **Règles** : elles sont toutes décidées. Leur historique se trouve dans `decision-log.md`.
> - **Unités** : 1 tuile = 16 px. Résolution interne 640×360. Durées en secondes à 60 FPS (1 frame ≈ 0,017 s).

**Lexique**

| Terme | Sens dans ce document |
|---|---|
| Cauchemar | Le boss qui termine un étage. |
| Lucide, Flottant, Dérive, Abandon, Abandon total | Les paliers de la jauge de lucidité. « Sous Lucide » désigne tous les paliers à partir de Flottant. |
| Graze | Frôler un projectile ennemi sans être touché. |
| Invulnérabilité | Période pendant laquelle aucun coup ne compte (i-frames). |
| Drop | Un ramassable laissé par une salle vidée : ½ cœur, ½ armure, un consommable ou 3 Éclats. |
| Éclats | La monnaie unique de la run. |
| Étage secret | Le cinquième étage, « le rêve dans le rêve ». |

---

## Résumé

### Concept

Hypnagogia est un roguelike twin-stick en 2D. Un homme fait des rêves lucides sans savoir pourquoi. Chaque run est une nuit, chaque mort un réveil, et le réveil lui-même finit par se fissurer : chaque réveil n'est peut-être qu'une couche de rêve de plus.

> **Vision** : lutter avec frénésie dans un rêve où la frontière avec la réalité devient si fine qu'on ne sait plus ce qui est vrai.

Le cœur du jeu est **la lucidité à deux pôles**. Le joueur dépense sa lucidité pour plier le rêve, ce qui le fait glisser vers l'abandon, où le danger et les récompenses augmentent. Il la regagne par le skill.

**Ce que vit le joueur** :
- **L'adrénaline** : il dépense sa lucidité, glisse vers l'abandon, s'expose davantage et gagne plus.
- **L'intrigue** : la chambre change, des détails clochent, et ce qu'il croyait réel se fissure.
- **La montée en puissance** : des choix durs (sacrifier un objet, accepter un pacte, dépenser sa lucidité).
- **La réaction visée** : « c'est quoi ce truc de fou », puis on relance.

**Garde-fou** : le doute porte sur ce qui est réel, jamais sur le combat. Projectiles et hitbox restent toujours lisibles.

### Public cible

Les vétérans d'Isaac (300 à 500 h et plus). Ils connaissent les item pools, les synergies, les pactes et les déblocages, lisent les patterns, veulent que leur précision paie, et cherchent un nouveau mystère sous une vraie couche de skill. Le premier cercle (le développeur et ses amis, ≈ 500 h chacun) **est** le public principal : on ne conçoit pas pour les débutants.

**Durée d'une run** : ≈ 15 min au début, jusqu'à ≈ 45 min une fois les cauchemars profonds débloqués.

### Arguments uniques

1. **La lucidité à deux pôles**, une mécanique qu'aucune des références n'a.
2. **Un mystère qui se lit dans la chambre**, plus explicite qu'Isaac ou Gungeon, sans jamais trancher.
3. **Des objets qui ont du sens** : ils viennent des rêves universels, ont un coût, et leurs synergies se devinent.
4. **Une musique qui suit la plongée** : un genre par phase du sommeil, une musique qui se densifie avec la profondeur et s'étouffe quand le joueur perd le contrôle. Elle est composée par le développeur.

L'avantage tient à l'identité et aux sensations, pas au volume : on ne vise pas les 700 objets d'Isaac.

---

## Objectifs et contexte

### Objectifs du projet

- **Réussite** : le développeur et ses amis prennent plaisir à y jouer. Une sortie Steam serait un plus, pas l'objectif.
- **Jalons** :

| Jalon | Contenu | Ce qu'il valide | Horizon |
|---|---|---|---|
| A. Le combat | Une arène, les contrôles, 4 ennemis, la lucidité à deux pôles, mort et relance instantanées | Le combat est nerveux et la lucidité donne envie de jouer avec (critères chiffrés : Indicateurs de réussite) | ≈ 3 à 4 semaines |
| B. MVP : une vraie run | Lucidité complète, 1 étage Endormissement, Le Professeur, 8 objets, 2 consommables, boutique, chambre minimale | Une run de 15 min donne envie de relancer | 2 mois |
| C. L'acte 1 | Les 4 phases et l'étage secret, 5 cauchemars, les pactes, la chambre qui change, le premier mystère et sa fin | Le jeu tient seul | Non fixé |
| D. Les actes 2 et 3 | Le réveil, puis l'asile | L'histoire complète | Plus tard |

**Porte du jalon B** : on ne produit pas le contenu du MVP (sprites du Professeur, objets, pool de salles) avant que le jalon A ait validé la lucidité.

### Contexte et raisons

Projet personnel, sans sortie publique prévue. Le développeur veut « quelque chose de nouveau : Isaac est vieux, il faut un autre mystère à découvrir ». Il est seul, expérimenté (il a déjà fini au moins un jeu), mais c'est son premier projet sous Godot. Il compose la musique. Les graphismes sont générés par IA. Il y consacre plusieurs dizaines d'heures par semaine. Il ne part de rien : ni prototype, ni moodboard, ni musique.

**Références** :
- **Isaac** : la structure (salles prédessinées, item pools, pactes façon diable et ange, mêmes types de cœurs, déblocages par succès).
- **Enter the Gungeon** : la nervosité (dodge avec invulnérabilité, blanks, synergies signalées, ennemis avec une personnalité, la salle dont on se sert).
- **Neon Abyss** : le cumul sans limite, les Faiths qui modifient le donjon, le néon de la phase REM.
- **Slay the Spire** : tout est lisible, avec des choix durs et l'Ascension.
- **Cuphead** : les intentions annoncées par l'animation.
- **Hellblade** : la santé mentale sans cliché.
- **À éviter** : Yume Nikki, Omori, Little Nightmares. Ce sont des repères pour s'en distinguer, et la différence se fait sur l'histoire et la direction artistique.

---

## Gameplay

### Piliers

Chaque pilier vient avec un interdit qui permet de trancher.

1. **Action nerveuse, mort méritée.** Tout se lit (animation, télégraphe, origine visible) et reste esquivable, parfois de justesse. *Interdit* : les attaques invisibles, le hasard qui tue.
2. **Le thème explique les mécaniques.** Mourir, c'est se réveiller. La profondeur, c'est la difficulté. Perdre sa lucidité, c'est perdre le contrôle de son rêve. Accepter un pacte, c'est s'enfoncer plus profond. Le rêve peut être abstrait, jamais arbitraire. *Interdit* : une mécanique sans justification onirique (un « +10 % de dégâts » générique, par exemple).
3. **Des synergies qu'on devine.** Les combinaisons peuvent surprendre, mais en bien. *Interdit* : la mauvaise surprise cachée. Regretter un coût connu et accepté reste permis.
4. **Un mystère dévoilé une couche à la fois.** La première victoire contre un cauchemar, ou le premier succès obtenu, révèle une seule information. Une run peut donc en révéler plusieurs. *Interdit* : les révélations groupées, les pavés d'exposition.

**Règles non négociables** : les projectiles restent lisibles ; la méta-progression ne passe que par le contenu ; les coups ne retirent que des cœurs.

### Boucle de jeu

**Boucle de salle (≈ 45 s)** : entrer, les portes se ferment, lire les télégraphes, tirer, dasher, grazer pour remonter la lucidité, la dépenser en pouvoir quand la salle l'exige. La salle vidée rapporte des Éclats, +5 de lucidité et une chance de drop. *Piliers 1 et 2.*

**Boucle d'étage (≈ 9 min)** : explorer l'étage en choisissant l'ordre de visite des salles adjacentes, passer à la salle trésor et à la boutique, battre le cauchemar. Entre deux étages : une salle de pacte (à partir de l'acte 1), puis un choix de porte dans les derniers étages. *Piliers 1 et 3.*

**Boucle de run, la nuit (15 à 45 min)** : s'endormir depuis la chambre, descendre étage par étage selon les phases du sommeil, jusqu'au cauchemar le plus profond débloqué. La mort ou la victoire réveille. *Tous les piliers.*

**Boucle méta, le réveil** : de retour dans la chambre, le réveil affiche l'heure à laquelle on s'est réveillé. Chaque première victoire révèle une couche du mystère et débloque du contenu (objets, consommables, pactes, cauchemars, étages). **Jamais plus de puissance.** *Piliers 2 et 4.*

**Pourquoi relancer la centième fois** : la lucidité fait de chaque salle une décision (dépenser maintenant ou remonter d'abord), les synergies par tags changent la façon de jouer d'une run à l'autre, et la chambre promet toujours une couche de plus.

### Conditions de victoire et de défaite

- **Défaite** : les cœurs tombent à 0. Le personnage se réveille, et la run est terminée.
- **Victoire de run** : battre le cauchemar le plus profond débloqué parmi les 4 phases du sommeil. Le personnage se réveille de lui-même. Le cauchemar battu débloque le suivant, et donc un étage de plus pour les runs suivantes.
- **Au départ**, seul Le Professeur est débloqué : une run gagnée tient en un étage. Une fois La Silhouette débloquée, une run gagnée fait 4 étages, ≈ 36 min, et ≈ 45 min avec l'étage secret.
- **Au MVP**, la run se termine toujours après Le Professeur, puisque les cauchemars suivants n'existent pas encore.
- **L'étage secret est optionnel.** Battre La Silhouette gagne la run. Une fois qu'elle a été battue au moins une fois, une troisième porte apparaît après elle et propose de replonger. Le joueur peut se réveiller (victoire) ou entrer dans l'étage secret. Mourir dans l'étage secret, c'est mourir : la run est perdue.
- **Fin de l'acte 1** : battre Toi, le cauchemar de l'étage secret, révèle le faux réveil, la vraie fin de l'acte.
- **L'heure du réveil** : le réveil de la chambre affiche l'heure de la mort, comme un score déguisé.
  - La nuit commence à 23:00, et chacune des 4 phases couvre 78 min. Les 4 phases mènent donc à **4:12**.
  - Dans un étage, l'heure avance au prorata des salles de combat vidées sur le nombre de salles de combat de l'étage. Battre le cauchemar amène à l'heure de fin de la phase (par exemple 00:18 après Le Professeur).
  - L'étage secret est hors du temps : l'horloge y reste bloquée sur 4:12, quelle que soit la progression.

---

## Mécaniques

### Mécaniques principales

#### Déplacement et dash *(pilier 1)*

| Paramètre | Valeur |
|---|---|
| Vitesse de déplacement | 6 tuiles/s |
| Accélération jusqu'à la vitesse max | 0,06 s |
| Décélération jusqu'à l'arrêt | 0,04 s |
| Hitbox du joueur | 6×6 px, centrée sur le torse (sprite 16×24) ; 4×4 px au palier Lucide |
| Dash : distance | 3 tuiles |
| Dash : durée | 0,18 s |
| Dash : invulnérabilité | les 0,15 premières secondes |
| Dash : recharge | 0,6 s après la fin du dash |
| Dash : tampon d'entrée | 0,1 s |
| Tir pendant le dash | non |

Le dash traverse les projectiles mais ni les murs ni les ennemis. Il survole un trou seulement s'il le franchit entièrement.

#### Tir *(pilier 1)*

| Paramètre | Valeur de base |
|---|---|
| Dégâts par tir | 10 |
| Cadence | 4 tirs/s |
| Vitesse du projectile | 14 tuiles/s |
| Portée | Illimitée : le tir file jusqu'à un mur ou un ennemi, sans gravité |
| Hitbox du projectile | 4×4 px |
| Dispersion | Aucune : le tir part exactement dans la direction visée |
| Coups critiques | Aucun |

**Bonus de dégâts** : tous les bonus en pourcentage (objets, paliers de lucidité) s'additionnent, puis s'appliquent aux dégâts de base. Exemple : Dent qui tombe (+30 %) et palier Dérive (+20 %) donnent +50 %, soit 15 dégâts par tir.

Les objets modifient l'apparence des tirs (taille, traînée, dans la couleur réservée au joueur). Les tirs du joueur restent toujours plus discrets que les projectiles ennemis.

#### Santé et armure *(pilier 1)*

- **Cœurs de départ** : 3 (6 demi-cœurs). **Plafond** : 12 cœurs, armure comprise.
- **Coup reçu** : ½ cœur aux étages 1 et 2 ; 1 cœur à partir de l'étage 3 et pour les attaques lourdes des cauchemars. Les ennemis infligent aussi des dégâts au contact.
- **Invulnérabilité après un coup** : 1,0 s, signalée par un clignotement du sprite et un son.
- **Armure** : une couche de demi-cœurs bleus par-dessus les cœurs, perdue en premier. Elle ne se soigne pas : on n'en récupère qu'en en ramassant (drops, boutique). Au plafond de 12 cœurs, l'armure reste au sol.
- **Acte 1** : les mêmes types de cœurs qu'Isaac (hors MVP).

#### Lucidité à deux pôles *(piliers 1 et 2, cœur du jeu)*

Une seule jauge de **100 points**, pleine au début de chaque run. Elle ne descend jamais sous 0.

**Paliers.** Le danger suit la descente :
- passer sous un palier en pleine salle applique aussitôt le danger du nouveau palier, signalé par un son et un effet visuel ;
- remonter n'allège le danger qu'à l'entrée de la salle suivante ;
- dans une salle, le danger est donc celui du palier le plus bas atteint depuis l'entrée ;
- le bonus de dégâts et la précision suivent la jauge en direct.

Un renfort d'Abandon déclenché en pleine salle apparaît sur un emplacement de renfort, annoncé 0,6 s avant.

| Palier | Lucidité | Danger (palier le plus bas atteint dans la salle) | Récompense |
|---|---|---|---|
| Lucide | 100 à 76 | Aucun | **Précision** : tirs 30 % plus rapides, hitbox du joueur réduite à 4×4 px |
| Flottant | 75 à 51 | Aucun | +10 % de dégâts, loot ×1,25 |
| Dérive | 50 à 26 | Projectiles ennemis 10 % plus rapides | +20 % de dégâts, loot ×1,5 |
| Abandon | 25 à 1 | En plus : 1 ennemi supplémentaire par salle de combat (une copie du type le plus présent dans la salle) ; télégraphes ×0,85, jamais sous 0,4 s | +35 % de dégâts, loot ×2 |
| Abandon total | 0 | En plus : les cauchemars gagnent un pattern supplémentaire | Comme Abandon |

- **Deux pôles, deux identités (pilier 2)** : en Lucide, le joueur contrôle son rêve. Il est précis : ses tirs vont plus vite, et il esquive plus finement. Sous Lucide, le rêve déborde : le joueur frappe plus fort et le rêve lui donne plus, mais il ne le contrôle plus. En perdant le palier Lucide, il perd aussi la précision.
- **Le danger reste lisible** : il passe toujours par des réglages annoncés (vitesse, nombre d'ennemis, fenêtres d'attaque, pattern supplémentaire), jamais par un comportement aléatoire. Chaque aggravation en pleine salle est signalée.
- **Loot** : le multiplicateur s'applique aux Éclats et à la chance de drop. Il est calculé au palier le plus bas atteint dans la salle, celui qui règle aussi le danger.

**Dépense.** Seuls des choix du joueur font baisser la lucidité : les pouvoirs, et les objets ou consommables qui affichent ce coût. Les coups ne la touchent jamais. Une dépense est impossible si la jauge ne la couvre pas : un son de refus retentit, et rien n'est consommé. À 0, aucun pouvoir ni aucun objet qui coûte de la lucidité n'est utilisable.

**Remontée** :

| Source | Gain | Règle |
|---|---|---|
| Graze | +2 | Un projectile ennemi passe à moins d'une tuile de la hitbox sans toucher. Chaque projectile ne compte qu'une fois. Pas de graze pendant l'invulnérabilité (dash ou coup reçu). **Plafond : +20 par salle.** |
| Dash parfait | +5 | L'invulnérabilité du dash évite un projectile qui aurait touché. Il remplace le graze pour ce projectile. |
| Salle vidée | +5 | Le filet de sécurité. |
| Consommable | +25 | Se pincer. |

À 100, les gains sont perdus : cela pousse à dépenser.

**Pouvoirs du MVP** (2) :

| Pouvoir | Effet | Coût | Recharge |
|---|---|---|---|
| **Éveil** | Efface tous les projectiles ennemis à l'écran et repousse de 2 tuiles les ennemis situés à moins de 3 tuiles. Le blank de Gungeon, vécu comme un sursaut de lucidité. | 30 | 1 s |
| **Glissement** | Téléporte vers le point visé, à 6 tuiles au plus, à travers les projectiles et les obstacles bas. 0,1 s d'invulnérabilité à l'arrivée. | 20 | 1 s |

**Destination de Glissement** : si le point visé est dans un mur, un obstacle haut ou un ennemi, le joueur arrive au dernier point libre sur la ligne de visée. Glissement ne franchit ni les murs de la salle ni les portes fermées. Un trou est une destination valide : on y tombe, sauf avec Ailes de papier. À la manette, la distance suit l'inclinaison du stick droit (de 2 à 6 tuiles).

**Signes de la lucidité à l'écran** : la jauge figure dans le HUD. L'aberration chromatique et l'ondulation des décors croissent avec les paliers, et le filtre passe-bas étouffe de plus en plus la musique. Les réglages d'accessibilité réduisent ces effets sans toucher au gameplay.

#### Objets *(pilier 3)*

- Chaque objet a **un bonus et un coût**, décrits clairement en jeu. Le cumul est sans limite. Les objets sont tirés de pools selon le type de salle.
- **Tags thématiques** : Chute, Temps, Regard, Corps. Les synergies se déclenchent à partir d'un nombre d'**objets distincts** portant le même tag, pas par paires écrites à la main.
- Quand un seuil de tag est atteint, le jeu l'annonce (nom de la synergie et effet en clair), comme les synergies signalées de Gungeon.
- **Un seul objet actif** à la fois. En ramasser un autre dépose l'ancien au sol, et l'objet déposé garde sa charge.
- **Pas de doublon** dans une run, sauf la Dent qui tombe.
- **Sacrifice et échange : la salle d'oubli** *(acte 1, hors MVP)*. C'est l'oubli du rêve au réveil (pilier 2). Le joueur y oublie un objet passif qu'il porte, puis choisit l'un de 2 objets tirés pour le remplacer (on ne peut pas récupérer l'objet oublié). Un objet oublié ne ressort plus de la run. La salle d'oubli est l'une des salles spéciales derrière le choix de porte.

**Objets du MVP** (8) :

| Objet | Tags | Bonus | Coût |
|---|---|---|---|
| Dent qui tombe | Corps, Chute | +30 % de dégâts | −1 cœur max |
| Jambes de plomb | Chute | Tirs traversants | −20 % de vitesse de déplacement |
| Ailes de papier | Chute | Survol des trous | Chaque coup reçu retire le survol pendant 3 s |
| Chute libre | Chute | +5 % de dégâts par seconde sans être touché (max +50 %) | Le bonus retombe à zéro au premier coup, et ce coup retire ½ cœur de plus |
| Copie d'examen vierge | Temps | Un drop garanti en plus par salle de combat vidée | Chrono de 45 s par salle de combat ; à 0, les ennemis restants se déplacent et tirent 30 % plus vite |
| Réveil cassé *(actif)* | Temps | Ralentit tout sauf le joueur à 50 % pendant 4 s ; se recharge en 3 salles vidées | −15 de lucidité à chaque utilisation |
| Miroir | Regard | Un second tir part vers l'arrière | Dans 1 salle de combat sur 4, un reflet hostile du joueur apparaît |
| Être nu en public | Regard, Corps | Les ennemis ne tirent pas pendant les 1,5 premières secondes de chaque salle (la gêne) | Toute l'armure est perdue, et on ne peut plus en ramasser |

**Précisions** :
- **Dent qui tombe** : le rêve universel de la dent qui tombe. On perd une part de soi, et ce qui reste mord plus fort. Elle est cumulable : chaque copie ajoute +30 % et −1 cœur max, mais ne compte qu'une fois pour les tags. Elle ne peut pas être prise s'il ne reste qu'un cœur max : elle s'affiche alors grisée, et la salle trésor tire un autre objet à sa place.
- **Ailes de papier** : si le coup arrive au-dessus d'un trou, le joueur tombe, mais la chute ne coûte rien de plus que le coup.
- **Copie d'examen vierge** : le chrono ne tourne pas dans la salle du cauchemar ni dans une salle déjà vidée.
- **Réveil cassé** : il suit la règle de dépense (impossible sous 15 de lucidité).
- **Miroir** : le reflet a 60 PV, multipliés par le facteur d'étage. Il tire des projectiles ennemis (couleur et contour exclusifs) qui reprennent le motif des tirs du joueur. Il n'apparaît jamais dans la salle d'un cauchemar.
- **Être nu en public** : la boutique propose un cœur à la place de l'armure.

**Synergie du MVP, la famille Chute** (4 objets) :
- **2 objets Chute, « Piqué »** : chaque dash finit sur une onde de choc (15 dégâts, rayon 1,5 tuile).
- **3 objets Chute, « Chute sans fin »** : l'onde double (30 dégâts, rayon 2,5 tuiles), et tomber dans un trou ne retire plus de cœur.

#### Consommables *(piliers 2 et 3)*

- **Un seul porté** à la fois. En ramasser un autre dépose l'ancien au sol.
- Ils sont à double tranchant et s'inspirent des vraies techniques de rêve lucide.

| Consommable (MVP) | Effet | Coût |
|---|---|---|
| Se pincer | +25 de lucidité | −½ cœur (jamais l'armure). Impossible s'il ne reste qu'½ cœur. |
| Café | +30 % de vitesse et de cadence pendant 10 s | Puis −20 % de vitesse pendant 5 s |

Le reste de la liste du brainstorm (Regarder ses mains, Somnifère, Bougie, Doudou, Boîte à musique, Sablier, Verre d'eau) est réservé à l'acte 1. Chacun sera revu au regard des constats du stress test (voir Questions ouvertes).

#### Pactes *(piliers 2 et 3 ; acte 1, hors MVP)*

- **Quand** : une salle de pacte s'ouvre après chaque cauchemar battu, sauf le dernier de la run, avant un éventuel choix de porte. Elle propose 2 pactes, et on peut les refuser tous les deux sans pénalité.
- **Ce qu'est un pacte** : une malédiction permanente pour la run, en échange d'un pouvoir, dans l'esprit des pactes diable et ange d'Isaac et des Faiths de Neon Abyss qui modifient le donjon. Accepter, c'est s'enfoncer plus profond dans le rêve. **Un pacte ne coûte jamais de lucidité.**
- **Les 4 pactes du brainstorm** sont repris pour l'acte 1 :
  - Sans voix ;
  - On te regarde : les salles qu'aide à vider la présence qui suit le joueur rapportent le double d'Éclats ;
  - Visage oublié ;
  - Portes mouvantes : une salle trésor de plus par étage.

  Leurs corrections restent ouvertes (voir Questions ouvertes).

### Contrôles

| Action | Clavier et souris | Manette |
|---|---|---|
| Déplacement | ZQSD | Stick gauche |
| Visée | Souris | Stick droit |
| Tir | Clic gauche, maintenu | Stick droit incliné (tir auto) ou RT |
| Dash | Espace | RB |
| Pouvoir 1 (Éveil) | Clic droit | LT |
| Pouvoir 2 (Glissement) | Maj | LB |
| Objet actif | E | X |
| Consommable | A | Y |
| Carte de l'étage | Tab, maintenu | Select, maintenu |
| Pause | Échap | Start |

Toutes les touches sont réassignables.

---

## Spécificités roguelike

### Structure de run

- **Point de départ** : la chambre. On s'endort dans le lit. Chaque run commence avec 3 cœurs, 100 de lucidité, 0 Éclat, aucun objet.
- **Acte 1** : 5 étages, soit les 4 phases du sommeil puis l'étage secret.
  1. Endormissement
  2. Sommeil léger
  3. Sommeil profond
  4. Paradoxal (REM)
  5. Étage secret, « le rêve dans le rêve »
- **Longueur** : la run descend jusqu'au cauchemar le plus profond débloqué (voir Conditions de victoire). Elle dure de ≈ 15 min (1 étage au MVP) à ≈ 45 min (5 étages).
- **Un cauchemar fixe par étage** :

| Étage | Cauchemar |
|---|---|
| 1. Endormissement | Le Professeur |
| 2. Sommeil léger | La Poursuite |
| 3. Sommeil profond | La Vague |
| 4. Paradoxal (REM) | La Silhouette au pied du lit |
| 5. Étage secret | Toi |

- **Choix de porte** : à la fin de l'étage 3, deux portes, sans carte, façon Isaac. L'une mène directement à l'étage suivant ; l'autre passe d'abord par une salle spéciale (trésor maudit, pacte renforcé ou salle d'oubli). Après La Silhouette, une troisième porte propose l'étage secret (voir Conditions de victoire).
- **Quitter en pleine run** : sauvegarder et quitter. La partie reprend au début de la salle en cours, avec l'état qu'avait le joueur en y entrant, et la sauvegarde est effacée dès la reprise. Si le jeu est fermé sans sauvegarder (crash, fermeture forcée), la run reprend au début de la dernière salle entrée. *Convention du genre.*
- **Limite acceptée** : cette règle permet de rejouer une salle ratée en quittant à temps. Pour un jeu qui se joue entre amis, la simplicité passe avant la protection contre le save-scum.

### Génération procédurale

- **Étage** : une grille de salles prédessinées tirées dans le pool de la phase. Chaque étage a une seule salle de départ et une seule salle de cauchemar. Le chemin principal est toujours garanti, et une même salle n'apparaît jamais deux fois dans un étage. La salle du cauchemar se trouve au bout d'un chemin d'au moins 4 salles depuis le départ.

| Composition d'un étage | Étage standard | Étage MVP |
|---|---|---|
| Salle de départ | 1 | 1 |
| Salles de combat | 8 | 12 |
| Salle trésor (1 objet gratuit) | 1 | 1 |
| Boutique | 1 | 1 |
| Salle du cauchemar | 1 | 1 |
| **Total** | **12** | **16** |

- **Durées** : une salle de combat dure ≈ 45 s, un cauchemar ≈ 75 s. Avec les déplacements, la boutique et le trésor (≈ 1,5 min), un étage standard fait ≈ 9 min, et 5 étages ≈ 45 min. L'étage MVP, seul de sa run, compte 12 salles de combat pour tenir la run de 15 min du brief. Il repassera à 8 quand les autres étages arriveront.
- **Pool de salles** : au moins 30 salles de combat prédessinées pour Endormissement au MVP, pour que les 12 tirées par étage varient d'une run à l'autre.
- **Ennemis** : chaque salle prédessinée fixe ses emplacements et ses vagues. Le palier Abandon ajoute un ennemi sur un emplacement de renfort prévu dans la salle. Les ennemis n'apparaissent jamais à moins de 3 tuiles du joueur.
- **Pools d'objets** : un objet est tiré du pool lié au type de salle. Au MVP, le pool trésor et le pool boutique contiennent les 8 objets. Le pool cauchemar (un objet offert par chaque cauchemar battu, sauf le dernier de la run) arrive avec l'acte 1.
- **Seeds** *(convention du genre)* : toute la run découle d'une seed.
  - La seed s'affiche à la mort et dans le menu pause, et elle peut être saisie avant une run. Une run avec seed saisie ne débloque rien et ne fait pas avancer le mystère.
  - La disposition des étages et des salles ne dépend que de la seed, jamais des choix du joueur.
  - Les tirages d'objets, de drops et de combat (renfort d'Abandon, reflet du Miroir) sont indépendants les uns des autres : prendre un objet ou jouer en Abandon ne décale pas les objets qui suivent.
  - Les pools dépendant des déblocages, deux profils n'obtiennent la même run que s'ils ont les mêmes déblocages.

### Mort et progression

- **Permadeath** : la mort réveille. La run est perdue, objets, Éclats et pactes compris.
- **Ce qui persiste** : seulement le contenu débloqué et l'état du mystère dans la chambre.
- **Déblocages** : par succès, comme dans Isaac. La première victoire contre un cauchemar débloque le suivant. D'autres succès débloquent des objets, des consommables et des pactes : par exemple, une salle vidée en Abandon total, ou une synergie à 3 objets.
- **Le mystère** : chaque première victoire (cauchemar ou succès) révèle **une seule** couche (pilier 4). Une victoire répétée ne révèle rien de plus.
- **Relance** : depuis la mort, une nouvelle run démarre en moins de 3 s. L'écran du réveil peut se passer.

### Objets et améliorations

- **Types** : passifs, un actif (rechargé par les salles vidées), consommables.
- **Rareté** : pas de rareté affichée. Le choix se fait sur le compromis bonus/coût, pas sur un niveau de puissance.
- **Builds** : les tags (Chute, Temps, Regard, Corps) structurent les builds. Pour l'acte 1, il faut au moins 4 objets par tag, avec au moins une synergie à 2 objets et une à 3 objets par tag.
- **Risque** : chaque objet a son coût, les pactes ajoutent des malédictions, et la salle d'oubli fait sacrifier un objet contre un choix.

### Personnage

Un seul personnage, l'homme qui rêve. Les autres personnages (avec la même histoire) sont reportés après l'acte 1.

### Modificateurs de difficulté

- **Ascension** : après la fin de l'acte 1, des niveaux cumulatifs, chacun avec une contrainte lisible (par exemple « les salles vidées ne rendent plus de lucidité »). Hors MVP.
- **La difficulté choisie dans la run** : c'est la lucidité. Rester en Abandon, c'est jouer en mode difficile contre plus de récompenses.
- **Défis et personnages tainted** : « un jour », hors périmètre.

### Armes et tir

- Pas d'armes interchangeables : le joueur a un tir de base que les objets modifient (dégâts, traversée, tirs arrière, apparence). Voir Tir.
- **Sensations** : recul visuel du sprite de 1 px pendant 0,05 s, son de tir court, flash blanc de 0,05 s et recul de 2 px sur l'ennemi touché. Les chiffres de dégâts sont désactivés par défaut.
- **Détection** : tous les tirs sont des projectiles visibles, jamais du hitscan.

### Ennemis et IA

- **Règle de télégraphe** : chaque attaque (tir, charge, accélération) est annoncée par l'animation au moins **0,4 s** avant, y compris en Abandon. Le simple contact n'est pas une attaque : il reste visible en permanence, y compris dans les salles sombres. Les projectiles ennemis ont une couleur et un contour exclusifs, dans toutes les phases.
- **Ennemis du MVP (Endormissement)** :

| Ennemi | Archétype | PV | Comportement | Télégraphe |
|---|---|---|---|---|
| Le Somnambule | Chaser | 30 | Marche vers le joueur à 2,5 tuiles/s, bras tendus. À moins de 2 tuiles, il accélère à 5 tuiles/s pendant 0,6 s. Dégâts au contact. | Lève les bras, 0,4 s, avant d'accélérer |
| La Veilleuse | Tourelle | 40 | Immobile ; tire un éventail de 3 projectiles, écartés de 20°, toutes les 2 s, à 5 tuiles/s | Lueur qui monte, 0,6 s |
| Le Mouton | Charger | 50 | Recule de 0,5 tuile, puis charge en ligne droite à 10 tuiles/s ; étourdi 1 s s'il heurte un mur | Gratte le sol, 0,5 s |
| La Berceuse | Tireuse mobile | 30 | Se tient entre 4 et 8 tuiles du joueur ; tire 1 projectile visé toutes les 1,5 s, à 6 tuiles/s | Inspire, 0,5 s |

- **Le Professeur**, cauchemar du MVP :
  - 2 500 PV. Durée visée : ≈ 75 s avec le **build de référence** (tir de base, un objet à +30 % de dégâts, 70 % des tirs qui touchent, soit ≈ 36 dégâts par seconde).
  - Trois épreuves, chacune annoncée par une craie qui écrit son nom au tableau :
    1. **Dictée** (100 à 66 % des PV) : des rangées horizontales de craies traversent la salle toutes les 2 s, chacune avec un trou à franchir.
    2. **Calcul mental** (66 à 33 %) : une spirale à 4 bras qui tourne à 60°/s, plus 3 craies visées toutes les 3 s.
    3. **Examen final** (33 à 0 %) : alterne les deux premières épreuves ; une règle balaie la salle, annoncée par une ligne 0,8 s avant.
  - **En Abandon total** : « Interro surprise », un cercle de 12 craies toutes les 6 s.
  - Vitesse des craies : 5 tuiles/s.
- **Cauchemars de l'acte 1** : les idées du brainstorm sont reprises comme point de départ.
  - La Poursuite : une fuite à travers des salles qui défilent, puis le combat.
  - La Vague : l'étage se noie, et l'eau monte.
  - La Silhouette au pied du lit : on commence immobilisé, comme dans une paralysie du sommeil.
  - Toi : un double qui utilise le build du joueur.
- **Ambiances par phase (acte 1)** :
  - Sommeil léger : une foule sans visage qui se duplique.
  - Sommeil profond : des ennemis massifs et lents.
  - REM : du bullet-hell.

### Arènes et salles

- **Taille** : une salle standard fait un écran : 36×19 tuiles jouables, à l'intérieur des murs, sous une bande de HUD. Les grandes salles font deux écrans, en largeur ou en hauteur, avec une caméra qui suit le joueur.
- **Obstacles** : bas (on tire par-dessus, Glissement les franchit) et hauts (ils bloquent tout). Les portes se ferment tant que la salle n'est pas vidée.
- **Jouer avec la salle** : des meubles du rêve (lit, chaise, pupitre) arrêtent les projectiles des deux camps jusqu'à leur destruction (30 PV). Certains éléments se déclenchent d'un tir : par exemple, une lampe éblouit 1 s les ennemis situés à moins de 3 tuiles. C'est la réponse aux tables de Gungeon.
- **Trous** : ce sont les sursauts hypnagogiques, la sensation de tomber en s'endormant. Ils sont présents dans toutes les phases, et omniprésents en Endormissement. Une chute compte comme un coup : ½ cœur (1 cœur à partir de l'étage 3), invulnérabilité de 1 s, retour au dernier bord sûr.
- **Mécanique par phase** :

| Phase | Lieux du rêve | Mécanique |
|---|---|---|
| Endormissement | Lieux familiers flous : maison, école, rue d'enfance | Trous omniprésents |
| Sommeil léger | Couloirs impossibles, portes trompeuses | Un ennemi qui survit 8 s se duplique, une seule fois ; les copies ne se dupliquent pas |
| Sommeil profond | Eau noire, brouillard, sensation de paralysie | Salles sombres : vision de 5 tuiles autour du joueur ; les projectiles ennemis, leurs télégraphes et les ennemis de contact (yeux luisants) restent toujours visibles |
| Paradoxal (REM) | Géométries vivantes, néons | Bullet-hell : jusqu'à 150 projectiles ennemis à l'écran |
| Étage secret | Une copie corrompue de la chambre | À concevoir pour l'acte 1 |

- **Distances d'engagement** : de 4 à 10 tuiles pour les tireurs ennemis.

---

## Progression et équilibrage

### Progression du joueur

- **Pendant la run** : la puissance monte par les objets, les synergies et les pactes, sans plafond. Les runs cassées sont permises.
- **Entre les runs** : uniquement du contenu, jamais de stats.
- **Le skill** : c'est la vraie progression. Grazer et dasher au bon moment rendent la lucidité, donc les pouvoirs : un joueur qui progresse dépense plus.

### Courbe de difficulté

- **Étage 1 (Endormissement)** : la phase d'apprentissage. Coups à ½ cœur, ennemis lents, trous.
- **Étages 2 et 3** : la pression monte. Duplication, salles sombres, coups à 1 cœur à partir de l'étage 3.
- **Étage 4 (REM)** : le pic de skill, en bullet-hell.
- **Étage secret** : Toi, un double qui utilise le build du joueur.
- **Dans chaque salle**, c'est le joueur qui règle la difficulté avec sa lucidité.

**Bandes d'équilibrage** (cibles, à mesurer au playtest) :

| Étage | Objets attendus à l'entrée | Dégâts du joueur attendus | PV des ennemis | Coup reçu | Victoire visée contre le cauchemar |
|---|---|---|---|---|---|
| 1 | 0 | ×1 | ×1 | ½ cœur | 30 à 50 % à partir de la 5e tentative |
| 2 | 2 | ×1,4 | ×1,3 | ½ cœur | 25 à 40 % à partir de la 5e tentative |
| 3 | 4 | ×1,9 | ×1,7 | 1 cœur | 25 à 40 % |
| 4 | 6 | ×2,5 | ×2,2 | 1 cœur | 20 à 35 % |
| Secret | 8 | ×3 | ×2,6 | 1 cœur | 20 à 30 % |

Les dégâts du joueur augmentent un peu plus vite que les PV des ennemis : la difficulté vient de la densité des patterns, des coups à 1 cœur et des mécaniques de phase, pas de la quantité de PV à entamer.

### Économie et ressources *(pilier 3)*

- **Monnaie unique : les Éclats**. Pas de clés ni de bombes. Les salles trésor sont gratuites.
- **Gains** : 1 à 3 Éclats par salle de combat vidée (2 en moyenne), multipliés par le loot du palier. 10 Éclats par cauchemar battu, à dépenser à l'étage suivant.
- **Drops** : 30 % de chance par salle de combat vidée, multipliée par le loot du palier (jusqu'à 60 % en Abandon). Un drop est tiré parmi ½ cœur, ½ armure, un consommable ou 3 Éclats.
- **Boutique** : 2 objets à 15, 1 consommable à 5, 1 cœur à 4 (soigne 1 cœur) et 1 armure à 5 (+1 cœur d'armure).
- **Cible** : en restant Lucide, ≈ 16 Éclats par étage standard, soit environ 1 objet. En Abandon, ≈ 32, soit environ 2 objets. L'étage MVP (12 salles de combat) en rapporte ≈ 24 en restant Lucide.
- **Ressources du joueur** : cœurs, armure, lucidité, Éclats, 1 consommable, 1 objet actif.

### Mystère et narration (cadre) *(pilier 4)*

- **Où se lit l'histoire** : dans la chambre, un lieu qu'on habite et pas un menu, dans le journal de rêves (encyclopédie et écran de progression) et dans les dossiers. On ne tranche jamais trop vite : il est malade, ou on lui ment ?
- **Les indices de la chambre** : des détails qui clochent (une horloge sans aiguilles, des livres illisibles), puis des objets-indices (photos, lettres, un bracelet d'hôpital). Une grande horloge reste bloquée sur **4:12**, le motif qui revient jusque dans l'heure du réveil.
- **Garder la surprise** : le premier changement de la chambre n'est annoncé par rien. Le joueur doit le découvrir de lui-même, sans s'y attendre.
- **Les actes** :
  - Acte 1 : les phases du sommeil.
  - Acte 2 : les mêmes phases, envahies par le réel de l'hôpital.
  - Acte 3 : l'asile devient jouable.
- **Fins** : 4 au départ. L'acte 1 a une vraie fin, la révélation du faux réveil.
- **Le reste** relève de la conception narrative dédiée (`gds-create-narrative`) : le passé du personnage, le sens de 4:12, les déclencheurs des actes et des fins, la priorité entre les fins.

---

## Cadre du level design

### Types de niveaux

| Type de salle | Rôle | Présence |
|---|---|---|
| Départ | Calme ; tutoriel visuel au premier étage | 1 par étage |
| Combat | Le cœur du jeu | 8 par étage standard, 12 au MVP |
| Trésor | 1 objet gratuit tiré du pool trésor | 1 par étage |
| Boutique | Achats en Éclats | 1 par étage |
| Cauchemar | Le cauchemar de l'étage | 1 par étage |
| Pacte | Deux pactes au choix, refusables | Entre deux étages (acte 1) |
| Salle spéciale | Trésor maudit, pacte renforcé ou salle d'oubli (sacrifice d'un objet contre un choix) | Derrière le choix de porte (acte 1) |

### Progression des niveaux

- **Ordre** : linéaire, des phases du sommeil de la plus légère à la plus profonde. Le choix de porte n'apparaît qu'à la fin de l'étage 3, et l'étage secret s'ouvre après le REM.
- **Dans un étage** : le joueur choisit l'ordre dans lequel il visite les salles adjacentes. La carte de l'étage se révèle au fil de l'exploration.

---

## Direction artistique et audio

### Style visuel

Pixel art, avec une palette par phase du sommeil.

| Phase | Palette | Musique |
|---|---|---|
| Endormissement | Pastels délavés | Ambient, tempo lent |
| Sommeil léger | Tons neutres, répétitifs | Downtempo, boucles hypnotiques |
| Sommeil profond | Du gris bleuté au noir profond | Drones lourds, basses |
| Paradoxal (REM) | Néons saturés | Psytech / psytrance, tempo rapide |
| Asile (actes 2 et 3) | Blanc clinique, néons froids | Sons concrets : bips, pas, portes |

- **Abandon** : aberration chromatique et décors qui ondulent à l'image ; un filtre passe-bas étouffe la musique.
- **Lisibilité** : les tirs du joueur restent discrets (plus petits, plus transparents, couleur réservée). Les projectiles ennemis passent au premier plan, avec une couleur et un contour exclusifs, identiques dans toutes les phases et à tous les paliers de lucidité.
- **Accessibilité** : réglages pour réduire les distorsions et les tremblements d'écran, mode photosensibilité, touches réassignables.
- **Graphismes IA** : contraintes de style strictes, testées dès le jalon A.

### Son et musique

- Composée par le développeur. Une piste par phase (voir le tableau), plus une piste de cauchemar par phase. La musique se densifie avec la profondeur. Le MVP n'a qu'une piste.
- **Effets sonores** : chaque télégraphe ennemi a son son, en plus de l'animation. Le graze a un son de frôlement discret, et le dash parfait un son plus marqué. Chaque changement de palier de lucidité est signalé par un son.

---

## Spécifications techniques

### Performances

- **60 FPS soutenus**, avec un 1 % low d'au moins 55 FPS, sur un PC milieu de gamme (classe GTX 1060, CPU 4 cœurs, 8 Go de RAM). Mesure : une salle de test avec 400 projectiles ennemis simultanés pendant 10 minutes, soit plus du double du pic prévu en REM.
- **Latence d'entrée** : au plus 3 frames entre l'appui et la réaction à l'écran, mesurée en filmant à 240 images/s l'appui et l'écran.
- **Chargement** : moins de 2 s entre deux étages ; moins de 3 s entre la mort et une nouvelle run.

### Plateforme

- PC uniquement (Windows en priorité, macOS souhaité), sous Godot.
- Clavier-souris et manette (disposition Xbox), avec bascule automatique selon le dernier périphérique utilisé.
- Fenêtré ou plein écran, de 1280×720 à 3840×2160. Rendu interne 640×360, mis à l'échelle par un facteur entier : 720p ×2, 1080p ×3, 1440p ×4, 4K ×6. Les écrans qui ne sont pas en 16:9 (16:10 des Mac, ultrawide) ou dont la définition n'est pas un multiple exact affichent des bandes noires. Écrans HiDPI (Retina) pris en charge.

### Assets

| Asset | Taille ou budget |
|---|---|
| Tuiles | 16×16 px |
| Joueur | 16×24 px |
| Ennemis | 16 à 32 px |
| Cauchemars | 64×64 px ou plus |
| Palette | Au plus 32 couleurs par phase, plus les couleurs réservées aux projectiles |
| Salles, MVP | Au moins 30 salles de combat Endormissement |
| Audio, MVP | 1 piste, ≈ 40 effets sonores |
| Audio, acte 1 | 4 pistes de phase, 5 pistes de cauchemar, la chambre |

---

## Epics de développement

### Structure des epics

Le détail se trouve dans [epics.md](epics.md).

| Epic | Contenu | Jalon |
|---|---|---|
| E1. Contrôles et sensations | Déplacement, dash, tir, caméra, réassignation des touches | A |
| E2. Lucidité à deux pôles | Jauge, paliers, graze, Éveil et Glissement, effets visuels et sonores | A |
| E3. Combat et ennemis | Les 4 ennemis, télégraphes, santé, armure, HUD, mort et relance | A |
| E4. Étage et génération | Salles prédessinées, assemblage par seed, carte, trous, meubles du rêve | B |
| E5. Objets et économie | 8 objets, tags et synergie Chute, 2 consommables, Éclats, drops, boutique, trésor | B |
| E6. Le Professeur et la boucle de run | Cauchemar, victoire, chambre minimale, heure du réveil, seeds affichées, sauvegarde | B |
| E7. Direction artistique et audio du MVP | Pipeline de graphismes IA, palette Endormissement, piste musicale, accessibilité | A et B |

**Ordre** : E1, E2 et E3 forment le jalon A (le combat, testé dans une arène unique). E4, E5 et E6 forment le jalon B (la run), qui ne démarre qu'une fois le jalon A validé. E7 court en parallèle : prototypes de style au jalon A, production au jalon B. Les epics de l'acte 1 sont esquissés dans epics.md.

---

## Indicateurs de réussite

### Indicateurs techniques

- 60 FPS soutenus et un 1 % low d'au moins 55 FPS dans la salle de test à 400 projectiles.
- Aucun crash sur 20 runs MVP consécutives.
- Relance après la mort en moins de 3 s.
- Une même seed, avec les mêmes déblocages, reproduit la même disposition d'étage et les mêmes objets, vérifié sur 10 seeds.

### Indicateurs de gameplay

- **Jalon A** : chaque ami du premier cercle joue au moins 20 min dans l'arène sans y être poussé. La majorité dit avoir dépensé sa lucidité volontairement, et pas seulement pour survivre.
- **Jalon B** : en moyenne, au moins 3 runs d'affilée par joueur et par session de jeu. Durée médiane d'une run MVP : 12 à 18 min.
- **Mort méritée** : après chaque mort, une question (« cette mort était-elle juste ? »). Cible : au moins 80 % de oui.
- **Lucidité** : un joueur passe en moyenne au moins 25 % de la run sous le palier Lucide (on ose l'abandon).
- **Le Professeur** : 30 à 50 % de victoires à partir de la cinquième tentative.

---

## Hors périmètre

- **Hors MVP (jalon B)** : pactes, autres phases et autres cauchemars, choix de porte, salles spéciales, pool cauchemar, chambre qui change, histoire et journal, Ascension, cœurs variés, consommables au-delà des deux du MVP.
- **Plus tard ou jamais** : autres personnages (avec la même histoire), tainted et défis (« un jour »), fins supplémentaires, secrets communautaires, plusieurs objets actifs portés à la fois, pilules et cartes, coop locale (piste après l'acte 1).
- **Refusé** :
  - tir sur 4 directions, gravité des tirs, portée limitée des tirs ;
  - objets sans description, rareté affichée ;
  - lore enfoui ;
  - deckbuilding, carte de route à la Slay the Spire, familiers, vue de côté ;
  - clés et bombes ;
  - fragments de souvenirs débloqués par des synergies ;
  - humour scatologique, thèmes religieux.
---

## Risques

| Risque | Parade |
|---|---|
| **La lucidité n'est pas éprouvée.** Le cœur du jeu peut ne pas tenir. | Le jalon A la teste avant tout investissement dans le contenu (porte du jalon B). |
| **Le cumul sans limite casse l'équilibrage des synergies.** | Peu d'objets au départ, synergies par tags plutôt que par paires, règle de lisibilité, bandes d'équilibrage. |
| **Les graphismes IA manquent de cohérence**, en particulier dans les animations. La déclaration Steam est obligatoire, et l'accueil peut être hostile. | Contraintes de style strictes, testées dès le jalon A. |
| **Le thème psychiatrique.** Des pouvoirs trouvés dans l'abandon et dans l'arrêt du traitement peuvent se lire comme un message contre les médicaments. | Un coût clair à la lucidité de l'acte 3, et une relecture par des personnes concernées avant toute diffusion des actes 2 et 3. |
| **L'acte 1 finit sur un cliffhanger.** | Lui écrire une vraie fin (le faux réveil), et l'écrire avant d'aborder l'acte 2. |
| **Le MVP ne teste pas le pilier 4** (ni chambre qui change, ni histoire). | Accepté dans le brief : le test de l'intrigue est reporté au jalon C. |

---

## Questions ouvertes

Ces questions ne bloquent pas l'architecture ni le MVP. Elles sont à trancher avant le jalon C.

1. **Pactes** :
   - Visage oublié fait doublon avec le dash, et ne voir que l'ombre du joueur contredit la règle de lisibilité ;
   - Sans voix doit dire ce que deviennent les consommables déjà portés ;
   - Portes mouvantes ne doit jamais bloquer le joueur (pas de softlock).
2. **La Silhouette au pied du lit** : commencer immobilisé en plein bullet-hell (REM) contredit le pilier 1. Il faut revoir l'ouverture du combat, ou placer ce cauchemar à un autre étage.
3. **Plusieurs « doubles » à la fois** : il faut une règle de lisibilité si le reflet du Miroir, Toi et la présence d'On te regarde peuvent coexister.
4. **Consommables de l'acte 1** : revoir ceux dont le coût repose sur un aggro qui n'existe pas (Bougie, Boîte à musique), la portée du Sablier, et le Verre d'eau face aux malédictions de pacte.
5. **Étage secret** : sa mécanique de phase, sa palette et sa musique.
6. **Narration** : le passé du personnage, le sens de 4:12, les déclencheurs des actes et des fins, la priorité entre les fins (voir `gds-create-narrative`).

---

## Hypothèses et dépendances

- **Valeurs de départ** : toutes les valeurs numériques sont des propositions posées à la rédaction. Le jalon A les règle au playtest.
- **Godot** tient 400 projectiles à 60 FPS sur la machine de référence. À vérifier dès le jalon A.
- **Les graphismes IA** restent cohérents d'un sprite à l'autre et d'une animation à l'autre, sous contraintes de style. À tester dès le jalon A.
- **La relecture du thème psychiatrique** par des personnes concernées a lieu avant toute diffusion des actes 2 et 3.
- **La conception narrative** (`gds-create-narrative`) précisera le mystère avant le jalon C.

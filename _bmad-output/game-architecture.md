---
title: 'Architecture du jeu'
project: 'hypnagogia'
date: '2026-11-20'
author: 'Kroustille'
version: '1.0'
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8, 9]
status: 'complete'
engine: 'Godot 4.7.2'
platform: 'PC (Windows, macOS)'

# Source Documents
gdd: '_bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md'
epics: '_bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/epics.md'
brief: '_bmad-output/planning-artifacts/briefs/brief-hypnagogia-2026-11-20/brief.md'
---

# Architecture du jeu

## Résumé

**Hypnagogia** est conçu pour **Godot 4.7.2** (GDScript typé, rendu Compatibility), sur PC Windows et macOS, en 640×360 mis à l'échelle entière de 720p à 4K.

**Décisions clés :**
- Projectiles hors de l'arbre de scène, dans un gestionnaire orienté données qui calcule aussi le graze (ADR-001).
- Lucidité à deux lectures : la jauge en direct pour les récompenses, le palier le plus bas de la salle pour le danger et le loot (ADR-002).
- Temps par groupe d'entités (ADR-003) et flux RNG nommés pour des runs reproductibles par seed (ADR-004).
- Objets, pactes et consommables en Resources avec effets événementiels, portables sur toute entité qui porte un build (ADR-005).
- Distorsions de l'abandon limitées au décor : le combat reste net (ADR-006).

**Structure :** projet Godot dans `game/`, organisé par fonctionnalité, valeurs d'équilibrage regroupées dans `game/data/`.

**Patterns :** 5 patterns nouveaux et 7 standard, avec règles de cohérence contrôlables en revue.

**Prêt pour :** le découpage en stories et l'implémentation du jalon A.

---

## Contexte du projet

### Vue d'ensemble

**Hypnagogia** : roguelike twin-stick 2D vu de dessus. Un homme fait des rêves lucides ; chaque run est une nuit, chaque mort un réveil. Le cœur du jeu est la lucidité à deux pôles : le joueur la dépense pour plier le rêve, glisse vers l'abandon (plus de danger, plus de récompenses) et la regagne par le skill (graze, dash parfait).

### Périmètre technique

**Plateforme :** PC, Windows en priorité, macOS souhaité (remplace Linux, décidé à l'architecture). Clavier-souris et manette Xbox, avec bascule automatique.
**Moteur imposé :** Godot (premier projet du développeur sous Godot).
**Genre :** roguelike, twin-stick shooter, salles prédessinées assemblées par seed.
**Niveau du projet :** complexité moyenne à élevée. Le volume de contenu est modeste, les systèmes sont exigeants. Développeur solo, graphismes IA, musique originale.
**Réseau :** aucun. Coop locale évoquée comme piste après l'acte 1, hors périmètre.
**Méthode :** un prototype jouable au plus vite, puis des itérations courtes. L'architecture fixe ce dont le jalon A a besoin et ce qui coûterait cher à changer plus tard ; le reste est décidé au moment où il devient nécessaire.

### Systèmes principaux

| Système | Complexité | Référence GDD |
|---|---|---|
| Contrôles : déplacement, dash avec invulnérabilité, tampon d'entrée, tir libre, réassignation, bascule de périphérique | Moyenne | Déplacement et dash ; Tir ; Contrôles |
| Lucidité : jauge, 5 paliers, danger figé au palier le plus bas de la salle, bonus en direct, graze, dash parfait, refus de dépense | **Élevée** | Lucidité à deux pôles |
| Pouvoirs : Éveil (efface les projectiles, repousse), Glissement (téléportation avec résolution de destination) | Moyenne | Pouvoirs du MVP |
| Projectiles en masse : jusqu'à 150 en jeu, 400 au test de perf, détection du graze par proximité | **Élevée** | Mécanique par phase ; Performances |
| Ennemis et télégraphes : 4 archétypes, télégraphe ≥ 0,4 s, renforts annoncés | Moyenne | Ennemis et IA |
| Cauchemars : patterns par phase de PV, pattern supplémentaire en Abandon total ; plus tard, Toi (copie du build du joueur) | Élevée | Le Professeur ; Cauchemars de l'acte 1 |
| Objets et modificateurs : bonus et coût, cumul additif, seuils de tags, objet actif à charges, consommables, effets qui réagissent aux événements | **Élevée** | Objets ; Consommables ; Pactes |
| Génération d'étage : grille, salles prédessinées, contraintes (chemin garanti, cauchemar à ≥ 4 salles), seed, flux RNG indépendants | **Élevée** | Génération procédurale |
| Format des salles et outillage : 36×19 tuiles, grandes salles, obstacles bas et hauts, trous, emplacements et vagues, meubles destructibles | Moyenne | Arènes et salles ; Level design |
| Économie : Éclats, drops multipliés par le loot du palier, boutique, trésor, pools | Faible | Économie et ressources |
| Sauvegarde : instantané en début de salle, reprise après un crash, méta-progression (déblocages, succès, mystère) | Moyenne à élevée | Structure de run ; Mort et progression |
| Rendu : 640×360 à l'échelle entière de 720p à 4K, caméra fixe ou qui suit, distorsions qui ne touchent jamais les projectiles | Moyenne | Direction artistique ; Plateforme |
| Audio adaptatif : piste par phase, filtre passe-bas selon le palier, sons de télégraphe, graze, palier | Faible à moyenne | Son et musique |
| HUD, UI, localisation : HUD, carte de l'étage, annonces de synergie, textes en fichiers de localisation | Moyenne | Contrôles ; Objets ; CLAUDE.md |
| Boucle méta : chambre, heure du réveil, seeds affichées et saisies, relance en moins de 3 s | Faible au MVP | Conditions de victoire ; Mort et progression |
| Télémétrie de playtest : « mort juste ? », temps sous Lucide, runs par session | Faible | Indicateurs de réussite |

### Exigences techniques

- **Performances :** 60 FPS soutenus, 1 % low ≥ 55 FPS, sur un PC de classe GTX 1060, CPU 4 cœurs, 8 Go de RAM. Mesure : 400 projectiles ennemis simultanés pendant 10 minutes.
- **Latence d'entrée :** ≤ 3 frames entre l'appui et l'écran.
- **Chargements :** < 2 s entre deux étages ; < 3 s entre la mort et une nouvelle run.
- **Déterminisme :** même seed et mêmes déblocages = même disposition et mêmes objets (vérifié sur 10 seeds) ; tirages d'objets, de drops et de combat indépendants.
- **Stabilité :** 0 crash sur 20 runs MVP consécutives.
- **Résolutions :** de 1280×720 à 3840×2160. Rendu interne 640×360, mis à l'échelle par un facteur entier : ×2 en 720p, ×3 en 1080p, ×4 en 1440p, ×6 en 4K. Les écrans qui ne sont pas en 16:9 (16:10 des Mac, ultrawide) ou dont la définition n'est pas un multiple exact affichent des bandes noires. Écrans HiDPI (Retina) pris en charge. Fenêtré ou plein écran.
- **Palette :** au plus 32 couleurs par phase, plus les couleurs réservées aux projectiles.
- **Accessibilité :** réduction des distorsions et des tremblements, mode photosensibilité, touches réassignables, sans effet sur le gameplay.
- **Données :** toutes les valeurs numériques sont des valeurs de départ à régler au playtest. Elles doivent pouvoir changer sans toucher au code.

### Facteurs de complexité

**Complexité élevée**
1. **Projectiles en masse avec graze :** le pic de 400 projectiles exclut un nœud complet par projectile. Le test de proximité (moins d'une tuile, une fois par projectile, plafond par salle) tourne à chaque frame.
2. **Système de modificateurs :** cumul sans limite, bonus additifs, coûts qui réagissent aux événements (coup reçu, salle vidée, chrono), seuils de tags. Il doit accueillir sans réécriture les pactes, les objets de l'acte 1 et les cœurs variés.
3. **Génération déterministe :** flux RNG séparés (disposition, objets, drops, combat). La disposition ne dépend jamais des choix du joueur, et les pools dépendent des déblocages.
4. **Lucidité :** le palier le plus bas atteint dans la salle règle le danger et le loot, et la jauge en direct règle les dégâts et la précision. Ce sont deux lectures du même état, mises à jour à des moments différents.

**Concepts nouveaux, sans pattern standard**
1. **Danger figé par salle**, avec aggravation en pleine salle (renfort annoncé 0,6 s avant sur un emplacement prévu).
2. **Rendu en couches :** les distorsions de l'abandon touchent le décor, jamais les projectiles ni les télégraphes. Plus tard, la vision réduite des salles sombres laissera visibles les projectiles et les ennemis de contact.
3. **Entités qui reprennent le build du joueur** (reflet du Miroir, Toi) : les effets d'objets doivent pouvoir s'appliquer à une autre entité que le joueur.
4. **Temps différencié :** Réveil cassé ralentit tout sauf le joueur. On ne peut donc pas s'appuyer sur un ralenti global du moteur ; il faut une échelle de temps par groupe d'entités.
5. **Reprise en début de salle :** la sauvegarde doit figer l'état du joueur et l'état des flux RNG à l'entrée de chaque salle, pour reprendre de façon identique après « sauvegarder et quitter » ou après un crash.

### Risques techniques

| Risque | Impact | Piste |
|---|---|---|
| Godot ne tient pas 400 projectiles à 60 FPS sur la machine de référence | Pilier 1, REM injouable | Prototype de stress dès le jalon A ; projectiles gérés hors de l'arbre de scène |
| Premier projet sous Godot | Mauvais patterns figés tôt | Conventions strictes dans ce document ; base de connaissances Godot |
| Latence d'entrée > 3 frames (vsync, ordre physique/rendu) | Sensations molles | Réglages de vsync et de boucle physique décidés ici, mesurés au jalon A |
| Déterminisme cassé par un tirage partagé ou un ordre d'itération instable | Seeds non reproductibles | Flux RNG nommés et isolés ; test automatisé sur 10 seeds |
| Système d'objets trop rigide pour l'acte 1 | Réécriture au jalon C | Modèle data-driven et événementiel dès le jalon B |
| Incohérence des graphismes IA | Lisibilité, retours négatifs | Pipeline d'import et palettes contraintes (E7) |
| Corruption ou incohérence de sauvegarde | Perte de progression | Écriture atomique, sauvegarde versionnée |
| Export macOS : signature et notarisation Apple, Gatekeeper, rendu Metal | Build Mac bloqué ou refusé au lancement | Tester un export Mac tôt ; build non signé acceptable pour le premier cercle |
| Écrans non 16:9 et HiDPI | Flou, mauvaise échelle | Échelle entière forcée, bandes noires ; test 720p, 1080p, 1440p, 4K et 16:10 |

## Moteur et framework

### Moteur retenu

**Godot 4.7.2** (stable, branche 4.7)

**Raisons :** imposé par le brief. Open source et gratuit, très bon en 2D (pixel art, TileMapLayer, échelle entière native), export Windows et macOS, itération rapide. On reste sur la branche 4.7 jusqu'à la fin du jalon B ; un changement de version mineure se décide explicitement, après lecture du guide de migration.

**Langage : GDScript, typé statiquement partout.** C'est le langage le plus documenté pour Godot et le plus rapide à itérer, sans chaîne de build .NET (plus simple pour l'export macOS). C# ou GDExtension ne seront envisagés que si le profilage montre un point chaud que GDScript ne tient pas (en priorité : la boucle des projectiles).

**Moteur de rendu : Compatibility.** Le plus léger pour de la 2D en pixel art, démarrage rapide, large compatibilité matérielle. À confirmer par le prototype de stress à 400 projectiles ; repli possible sur Forward+ (Metal natif sur macOS) si un effet de post-traitement l'exige.

### Initialisation du projet

Pas de modèle de départ : projet Godot vide, créé depuis l'éditeur 4.7.2 dans le dossier `game/` du dépôt (voir Structure du projet). Réglages initiaux :

```
display/window/size/viewport_width = 640
display/window/size/viewport_height = 360
display/window/stretch/mode = "viewport"
display/window/stretch/aspect = "keep"
display/window/stretch/scale_mode = "integer"
display/window/dpi/allow_hidpi = true
rendering/renderer/rendering_method = "gl_compatibility"
rendering/textures/canvas_textures/default_texture_filter = "Nearest"
physics/common/physics_ticks_per_second = 60
```

### Ce que fournit le moteur

| Composant | Solution | Notes |
|---|---|---|
| Rendu 2D | CanvasItem, TileMapLayer, Camera2D, shaders canvas_item | Échelle entière et bandes noires gérées par le stretch « viewport » + « integer » |
| Couches de rendu | CanvasLayer, z_index, BackBufferCopy | Base pour isoler les projectiles des distorsions |
| Physique | Godot Physics 2D : CharacterBody2D, Area2D, couches et masques de collision | Joueur, ennemis, murs, trous. Les projectiles ne passent pas par les nœuds physiques |
| Bas niveau | RenderingServer, PhysicsServer2D, MultiMeshInstance2D | Disponibles pour le système de projectiles maison |
| Entrées | InputMap, InputEvent (clavier, souris, manette) | Réassignation et bascule de périphérique à construire par-dessus |
| Audio | AudioServer, bus, AudioEffectLowPassFilter | Filtre passe-bas de la lucidité sur le bus Musique |
| Scènes | PackedScene, SceneTree, autoloads | Transitions gérées par `Main` (D14) |
| Données | Resource (.tres), export de variables | Candidat naturel pour les valeurs réglables au playtest |
| Localisation | TranslationServer, fichiers CSV ou PO | Exigé par CLAUDE.md pour tout texte affiché |
| Sauvegarde | FileAccess, ConfigFile, JSON | Formats et écriture atomique : D12 |
| RNG | RandomNumberGenerator (seed et state exposés) | Une instance par flux, état sauvegardable |
| Build | Modèles d'export Windows et macOS | macOS : build non signé pour le premier cercle ; signature et notarisation seulement en cas de sortie publique |
| Profilage | Profiler, moniteurs, débogueur distant | Mesure du test à 400 projectiles |

### Décisions architecturales restantes

1. Système de projectiles : stockage, déplacement, collisions, graze, rendu.
2. Composition des entités : joueur, ennemis, cauchemars ; machines à états ; hitbox et hurtbox.
3. Système de modificateurs et d'effets : objets, consommables, pactes, tags, synergies ; application à d'autres entités que le joueur.
4. Modèle de la lucidité : jauge en direct et palier le plus bas de la salle.
5. Seeds et flux RNG indépendants, sauvegarde de leur état.
6. Échelle de temps par groupe d'entités (Réveil cassé).
7. Couches de rendu et post-traitement (distorsions qui épargnent les projectiles, accessibilité).
8. Format des salles prédessinées et outillage d'édition.
9. Communication entre systèmes : signaux, bus d'événements, autoloads.
10. Données de réglage : où vivent les valeurs à modifier au playtest.
11. Sauvegarde : instantané d'entrée de salle, méta-progression, versionnage.
12. Entrées : tampon, réassignation, bascule de périphérique, latence (vsync).
13. Framework de test (GUT ou GdUnit4) et outils de débogage et de télémétrie.

### Environnement de développement : MCP

- **GoPeak** (reporté, voir « Environnement de développement » ; `HaD0Yun/Gopeak-godot-mcp`, MIT) : MCP Godot 4.x lancé avec `npx -y gopeak`. Édition de scènes et de scripts, diagnostics LSP, logs, inspection de l'arbre de scène en direct, captures d'écran, injection d'entrées. Vérifier l'état du dépôt à l'installation.
- **Context7** (`upstash/context7`) : documentation Godot à jour pour l'IA.
- Alternative : `Coding-Solo/godot-mcp`, le plus suivi, avec moins d'outils (lancer l'éditeur, exécuter, récupérer la sortie de débogage).
- **Tranché le 2026-11-20 (story 1.1) :** l'éditeur Linux tourne via WSLg (option A), sur le dépôt WSL. Voir « Environnement de développement ».

## Décisions architecturales

### Synthèse

| # | Catégorie | Décision | Priorité | Raison principale |
|---|---|---|---|---|
| D1 | Projectiles | Gestionnaire maison orienté données (`BulletManager` par camp, tableaux compacts, `MultiMeshInstance2D`, collisions et graze calculés à la main, pool) | Critique | 400 projectiles à 60 FPS ; graze et déterminisme maîtrisés |
| D2 | Entités | Composition de nœuds + machine à états par enum ; patterns de cauchemar en Resources | Critique | Léger, lisible, suffisant pour 4 ennemis et un cauchemar |
| D3 | Communication | Autoload `Events` pour le transverse, signaux locaux, appels directs vers le bas ; état de run dans un nœud `Run` | Critique | Découplage sans autoloads envahissants ; relance propre |
| D4 | Données de réglage | Resources `.tres` typées ; aucune valeur du GDD en dur | Critique | Réglage au playtest sans toucher au code |
| D5 | Lucidité | Objet `Lucidity` avec `live_tier` et `room_tier` ; dépense par `try_spend` | Critique | Deux lectures du même état, sans ambiguïté |
| D6 | Entrées et latence | Actions `InputMap` lues à 60 Hz, tampon en ticks, bascule de périphérique, réassignation ; VSync activée par défaut, interpolation physique 2D | Critique | Latence ≤ 3 frames, sensations nerveuses |
| D7 | Temps | Autoload `GameClock`, échelle de temps par groupe ; `Engine.time_scale` interdit en jeu | Critique | Réveil cassé, pause ; coûteux à ajouter après coup |
| D8 | Seeds et RNG | Un `RandomNumberGenerator` par flux, seed dérivé de `(seed, flux, étage)` ; RNG global interdit | Critique | Runs reproductibles, tirages indépendants |
| D9 | Objets et effets | `StatBlock` + `Loadout` par entité ; `ItemDef` + `ItemEffect` branché sur les événements ; `TagTracker` | Importante | Extensible aux pactes et à l'acte 1 ; applicable au reflet et à Toi |
| D10 | Salles | Une scène `.tscn` par salle (`TileMapLayer` + marqueurs) ; validation headless | Importante | Aucun outil externe, édition dans Godot |
| D11 | Génération d'étage | Expansion sur grille depuis le départ, contraintes, nouveau tirage en cas d'échec ; préchargement en tâche de fond | Importante | Déterminisme, chargement < 2 s |
| D12 | Sauvegarde | `settings.cfg`, `profile.json` versionné, `run.json` à l'entrée de salle ; écriture atomique | Importante | Lisible, débogable, sûr |
| D13 | Rendu | Décor sous le shader de distorsion ; entités, télégraphes, projectiles et HUD au-dessus | Importante | Pilier 1 : le combat reste lisible |
| D14 | Scènes | `Main` persistante, scène active (`Bedroom` ou `Run`), une salle active à la fois | Importante | Transitions maîtrisées, relance < 3 s |
| D15 | Audio | Bus `Master`, `Music` (passe-bas), `SFX`, `UI` ; autoload `Audio` avec pool | Importante | Filtre de lucidité, contrôle du mixage |
| D16 | UI et localisation | Control + `Theme` unique ; tous les textes par `tr()` et CSV | Importante | Exigence CLAUDE.md |
| D17 | Pathfinding | Direct au jalon A ; `AStarGrid2D` au jalon B | Reportable | Arène vide au jalon A |
| D18 | Outils, tests, télémétrie | Surcouche de débogage dès le jalon A ; journal JSON de playtest ; framework de test choisi avant le jalon B | Reportable | Itération rapide ; test des 10 seeds au jalon B |

### Gestion de l'état

**Approche :** pas d'état global de jeu. Trois niveaux de durée de vie :

| Niveau | Où il vit | Durée de vie | Exemples |
|---|---|---|---|
| Application | Autoloads `Events`, `Log`, `Settings`, `SaveService`, `Audio`, `GameClock` | Tout le temps | Réglages, profil, bus audio, échelles de temps |
| Run | Nœud `Run` (enfant de `Main`) et ses objets | Une nuit ; détruit à la mort ou à la victoire | Seed et flux RNG, étage, carte, Éclats, heure du réveil |
| Salle | Scène de salle active | De l'entrée à la sortie | Ennemis, projectiles, vagues, `room_tier` |

Le joueur est un enfant du nœud `Run`, conservé d'une salle à l'autre. Il porte `Health`, `Lucidity`, `StatBlock` et `Loadout`.

Les entités utilisent une machine à états par enum dans leur script :

```gdscript
enum State { IDLE, CHASE, TELEGRAPH, ATTACK, STUNNED }
var _state: State = State.IDLE

func _physics_process(delta: float) -> void:
	var dt := delta * GameClock.scale(GameClock.Group.ENEMIES)
	match _state:
		State.CHASE: _process_chase(dt)
		State.TELEGRAPH: _process_telegraph(dt)
		# ...
```

### Persistance des données

**Système de sauvegarde :** fichiers locaux dans `user://`, sans cloud.

| Fichier | Format | Contenu | Écriture |
|---|---|---|---|
| `settings.cfg` | ConfigFile | Volumes, affichage, VSync, accessibilité, touches | À chaque changement de réglage |
| `profile.json` | JSON avec `schema_version` | Déblocages, succès, couches de mystère révélées, statistiques | À chaque fin de run et à chaque déblocage |
| `run.json` | JSON avec `schema_version` | Seed, étage, carte (visitées, vidées), état du joueur à l'entrée de salle, états des flux RNG, heure du réveil | À l'entrée de chaque salle ; effacé à la reprise et en fin de run |
| `telemetry/*.json` | JSON | Journal de playtest par session | En continu, vidé en fin de session |

- **Écriture atomique :** écrire `fichier.tmp`, puis renommer.
- **Versionnage :** une fonction de migration par version de schéma ; un fichier illisible est renommé en `.corrupt` et n'empêche jamais le jeu de démarrer.
- **Interdit :** sauvegarder en `.tres` ou `.res`, qui peuvent embarquer du code exécutable.

### Gestion des assets

**Stratégie de chargement :** par scène.

- `Main`, l'UI et le joueur sont chargés au démarrage.
- À l'entrée d'un étage, les scènes de salles de l'étage et les ressources des ennemis de la phase sont chargées en tâche de fond (`ResourceLoader.load_threaded_request`) pendant la transition.
- Les salles sont instanciées à l'entrée et libérées à la sortie ; une seule salle est active à la fois.
- Les projectiles sont pré-alloués en pool au lancement de la run.
- La relance après la mort détruit le nœud `Run` et en instancie un neuf ; les ressources de l'étage 1 restent en cache.

### Projectiles (D1)

- Un `BulletManager` par camp (`enemy`, `player`), enfant de la salle active.
- Stockage en tableaux parallèles (`PackedVector2Array` pour positions et vitesses, `PackedFloat32Array` pour rayons et durées, `PackedByteArray` pour les drapeaux), taille fixe, avec une liste d'emplacements libres.
- Rendu : un `MultiMeshInstance2D` par camp et par apparence, mis à jour une fois par tick.
- Collisions, à la main, à chaque tick :
  - projectiles ennemis contre la hurtbox du joueur (cercle contre rectangle) ; graze dans la même boucle (distance < 1 tuile, une fois par projectile, plafond par salle) ;
  - projectiles joueur contre les hurtbox ennemies (peu nombreuses : test direct) ;
  - tous contre les murs et obstacles hauts par lecture de cellule du `TileMapLayer`, et contre les meubles.
- Ordre de traitement (story 2.1) : tout `BulletManager` règle `process_physics_priority = Const.PHYSICS_PRIORITY_BULLETS` (100) et tique donc après les entités (priorité 0), où qu'il soit dans l'arbre : les tests de touche lisent l'état du tick courant (invulnérabilité du dash, hurtbox).
- Ordre de traitement (story 2.3) : les `Hitbox` de contact (zones de contact des ennemis) règlent `process_physics_priority = Const.PHYSICS_PRIORITY_HITBOXES` (50) : entités à 0, `Hitbox` à 50, `BulletManager` à 100. Le contact est testé à la main dans le tick courant, sans recouvrement physique.
- Contrat de `fire()` (story 2.4) : un tir dont la cible refuserait les dégâts est refusé avec `Log.error` + `assert` (camp ennemi : `roundi(damage) < 1`, comme `Health` ; camp joueur : `damage <= 0`, comme `HitPoints`) ; un tir dont l'origine est dans une cellule solide n'est pas tiré (`false`, sans log ni compte) ; `add_appearance()` rend l'index existant pour la même texture, sans créer de `MultiMeshInstance2D` ; tous les projectiles ennemis partagent une seule apparence réservée (`EnemyBulletLook`).
- Les effets d'objets (traversée, tir arrière, taille) passent par des paramètres de tir, jamais par du code spécifique dans la boucle.
- Repli si le test à 400 projectiles échoue : porter la boucle de mise à jour en GDExtension, sans changer l'interface.

### Communication entre systèmes (D3)

- **`Events` (autoload)** : signaux typés pour ce qui traverse plusieurs systèmes. Exemples : `player_hit`, `player_grazed`, `perfect_dash`, `lucidity_tier_changed`, `room_entered`, `room_cleared`, `run_ended`.
- **Signaux locaux** entre un nœud et ses enfants ou son parent direct.
- **Appels directs** du parent vers ses enfants.
- **Interdit :** chemins absolus (`/root/...`), `get_parent().get_parent()`, autoloads qui contiennent de l'état de run.

### Données de réglage (D4)

- Toute valeur du GDD vit dans une Resource `.tres` typée : `PlayerTuning`, `DashTuning`, `ShotTuning`, `LucidityTuning`, `EnemyDef`, `BossDef`, `ItemDef`, `ConsumableDef`, `EconomyTuning`, `FloorDef`.
- Les scripts reçoivent leur Resource par `@export` et ne contiennent aucun nombre de gameplay en dur.
- Les durées sont exprimées en secondes et les distances en tuiles dans les Resources ; la conversion en pixels (×16) se fait à un seul endroit.

### Lucidité (D5)

- `Lucidity` (classe `RefCounted`, portée par le joueur) :
  - `value: int` (0 à 100) ;
  - `live_tier` : palier de la valeur actuelle → dégâts, précision ;
  - `room_tier` : palier le plus bas atteint depuis `begin_room()` → danger, loot ;
  - `try_spend(cost) -> bool` : refuse si la jauge ne couvre pas le coût (son de refus, rien n'est consommé) ;
  - `gain(amount, source)` : plafonné à 100 ; le plafond de graze par salle est tenu ici.
- Signaux : `value_changed`, `tier_changed` (live), `room_danger_raised` (room).
- Les systèmes de danger (vitesse des projectiles ennemis, renforts, télégraphes, pattern supplémentaire) ne lisent que `room_tier`.

### Entrées et latence (D6)

- Toutes les commandes passent par des actions `InputMap` (`move_*`, `aim_*`, `shoot`, `dash`, `power_1`, `power_2`, `use_active`, `use_consumable`, `map`, `pause`).
- Lecture dans `_physics_process` (60 Hz), tampon d'entrée compté en ticks.
- Bascule de périphérique sur le dernier `InputEvent` significatif (seuil de zone morte pour les sticks).
- Visée souris convertie dans les coordonnées du monde (viewport 640×360).
- VSync activée par défaut, désactivable ; interpolation physique 2D activée.
- Mesure de latence au jalon A ; au-delà de 3 frames, essayer VSync désactivée ou en mode mailbox.

### Temps (D7)

- `GameClock` (autoload) expose `scale(group) -> float` pour les groupes `PLAYER`, `ENEMIES`, `ENEMY_BULLETS`, `PLAYER_BULLETS`, `WORLD`, `FX`.
- Tout code de gameplay multiplie son `delta` par l'échelle de son groupe. Les timers de gameplay sont des compteurs manuels, pas des nœuds `Timer` ni des `SceneTreeTimer`.
- La pause passe par `GameClock` et par `process_mode` de l'arbre de jeu ; `Engine.time_scale` reste à 1.
- Seul `Main` met en pause et reprend : il écrit ensemble `GameClock.paused` et `ActiveScene.process_mode` (`PROCESS_MODE_DISABLED`) ; `SceneTree.paused` n'est jamais utilisé, et aucun autre script n'écrit `GameClock.paused` (story 1.6).
- Pendant l'écran de réveil, `Main` fige aussi `ActiveScene` et `GameClock.paused`, sans menu de pause (story 2.2).

### Seeds et RNG (D8)

- Seed de run : entier 64 bits, affiché comme un code court (8 caractères), saisissable.
- `RunRng` (porté par `Run`) fournit un `RandomNumberGenerator` par flux : `layout`, `rooms`, `treasure`, `shop`, `drops`, `combat`, `cosmetic`.
- Seed d'un flux : hachage de `(seed_de_run, nom_du_flux, index_d_étage)`. Les étages sont donc indépendants les uns des autres.
- Les états (`state`) de tous les flux sont écrits dans `run.json` à l'entrée de salle.
- `randf()`, `randi()`, `randomize()` et `Array.shuffle()`/`pick_random()` sont interdits dans le code de gameplay (ils utilisent le RNG global).
- Le flux `cosmetic` sert aux effets visuels sans incidence sur le gameplay.

### Objets, effets et synergies (D9)

- `StatBlock` : stats de base issues des Resources + liste de modificateurs (`ADD_PERCENT` cumulés entre eux, `ADD_FLAT`, `MULTIPLY`), recalculé à chaque changement. Les bonus de lucidité sont des modificateurs comme les autres.
- `Loadout` : objets passifs, objet actif (avec charge), consommable.
- `ItemDef` (Resource) : `id`, `tags`, clés de nom et de description, modificateurs, `effect_script` optionnel, coût en lucidité éventuel.
- `ItemEffect` (`RefCounted`) : se branche sur les signaux de son entité porteuse (`hit_taken`, `room_cleared`, `dash_ended`, `tick`) et se débranche à la perte de l'objet.
- `TagTracker` : compte les objets distincts par tag, active ou désactive les effets de synergie aux seuils et émet `synergy_activated` pour l'annonce.
- Toute entité qui a un composant `BuildCarrier` (`StatBlock` + `Loadout` + `TagTracker`) peut recevoir des objets : reflet du Miroir, Toi.
- Pactes et consommables suivent le même modèle (`PactDef`, `ConsumableDef`).

### Salles et génération (D10, D11)

- Une salle = une scène `.tscn` avec :
  - `TileMapLayer` : `Floor`, `Walls`, `LowObstacles`, `HighObstacles`, `Pits` ;
  - marqueurs : `EnemySpawn` (type, vague), `ReinforcementSpawn`, `Door` (côté), `Furniture`, `Trigger` ;
  - métadonnées : type de salle, phase, taille (1 écran, 2 en largeur, 2 en hauteur).
- Un script de validation headless parcourt le pool et vérifie : dimensions, portes, apparitions à ≥ 3 tuiles des entrées, présence d'un renfort.
- Génération : expansion sur une grille depuis la salle de départ ; cauchemar sur une impasse à ≥ 4 salles ; trésor et boutique sur des impasses ; en cas d'échec des contraintes, nouveau tirage dans le flux `layout`.

### Rendu (D13)

Ordre des couches, de bas en haut :

| Couche | Contenu | Distorsion |
|---|---|---|
| Décor | Sol, murs, obstacles, meubles, trous | Oui |
| Post-traitement | `ColorRect` plein écran, shader lisant l'écran (aberration, ondulation) | — |
| Entités | Joueur, ennemis, cauchemar, drops | Non |
| Combat | Télégraphes, projectiles joueur, projectiles ennemis (au-dessus de tout le reste) | Non |
| HUD | Interface | Non |

- Couches de décor en `z_index` = `Const.Z_INDEX_DECOR` : le joueur vit dans `Run`, hors de la salle (story 2.2).
- Story 2.4 : le `BulletManager` ennemi (`EnemyBullets`) est en `z_index` = `Const.Z_INDEX_ENEMY_BULLETS` : au-dessus de tout le monde (entités, tirs du joueur, chiffres de dégâts), quelle que soit sa place dans l'arbre ; sous le réticule (100) jusqu'à la story 2.7.
- Les couches du monde suivent la caméra (`follow_viewport_enabled`).
- L'intensité de distorsion = f(palier) × réglage d'accessibilité.
- Plus tard, la vision réduite des salles sombres s'insère entre Entités et Combat, en épargnant les ennemis de contact.

### Scènes (D14)

```
Main (Node)                  — persistante
├── ActiveScene (Node)       — Bedroom ou Run, remplacée par Main
│   └── Run
│       ├── RunRng, carte, état de run
│       ├── Player
│       └── RoomSlot         — la salle active
├── UI (CanvasLayer)         — HUD, menus, surcouche de débogage
└── Transition (CanvasLayer)
```

### Audio (D15)

- Bus : `Master` → `Music` (filtre passe-bas piloté par le palier de lucidité), `SFX`, `UI`.
- Autoload `Audio` : pool de `AudioStreamPlayer`, priorité et limite de voix par son (graze, tir).
- Couches de densité de la musique (AudioStreamInteractive ou AudioStreamSynchronized) à l'acte 1.

### UI et localisation (D16)

- Nœuds Control, un `Theme` unique, une police pixel.
- Tous les textes affichés passent par `tr("CLE")` ; fichiers CSV de traduction ; français comme langue de référence.

### Décisions reportées (D17, D18)

- **Pathfinding :** déplacement direct au jalon A ; `AStarGrid2D` sur la grille de la salle au jalon B.
- **Surcouche de débogage (jalon A) :** invulnérabilité, réglage de la lucidité, apparition d'ennemis, FPS, nombre de projectiles, palier courant.
- **Télémétrie de playtest :** journal JSON par session (morts et réponse « mort juste ? », temps par palier, runs par session).
- **Framework de test :** choisi avec `gds-test-framework` avant le jalon B ; test obligatoire sur 10 seeds.

### Fiches de décision (ADR)

**ADR-001 : projectiles hors de l'arbre de scène**
- *Contexte :* 400 projectiles à 60 FPS sur une GTX 1060, graze par proximité, déterminisme.
- *Options :* un nœud `Area2D` par projectile ; plugin C++ (BlastBullets2D, PerfBullets) ; gestionnaire maison en tableaux.
- *Décision :* gestionnaire maison en tableaux, rendu par `MultiMeshInstance2D`.
- *Conséquences :* collisions écrites à la main ; graze intégré ; aucune dépendance externe. Repli GDExtension si le profilage l'exige.

**ADR-002 : deux lectures de la lucidité**
- *Contexte :* le danger et le loot suivent le palier le plus bas atteint dans la salle, les dégâts et la précision suivent la jauge en direct.
- *Décision :* un objet `Lucidity` unique exposant `live_tier` et `room_tier`, remis à zéro par `begin_room()`.
- *Conséquences :* chaque système consommateur déclare laquelle des deux lectures il utilise.

**ADR-003 : échelle de temps par groupe**
- *Contexte :* Réveil cassé ralentit tout sauf le joueur ; `Engine.time_scale` est global.
- *Décision :* `GameClock` et règle `delta * GameClock.scale(group)` partout, dès le jalon A.
- *Conséquences :* pas de nœuds `Timer` pour le gameplay ; discipline à tenir dans chaque script.

**ADR-004 : flux RNG nommés**
- *Contexte :* runs reproductibles par seed, tirages indépendants, reprise en début de salle.
- *Décision :* un `RandomNumberGenerator` par flux, seed dérivé par hachage, états sauvegardés ; RNG global interdit.
- *Conséquences :* tout tirage précise son flux ; une revue de code refuse tout appel au RNG global.

**ADR-005 : effets d'objets événementiels et portables**
- *Contexte :* cumul sans limite, coûts réactifs, synergies par tags ; le reflet du Miroir et Toi reprennent le build du joueur.
- *Décision :* `StatBlock` + `Loadout` + `ItemEffect` branché sur les signaux de l'entité porteuse ; `TagTracker`.
- *Conséquences :* ajouter un objet = une Resource + au plus un petit script ; les pactes et les cœurs variés suivent le même modèle.

**ADR-006 : la distorsion épargne le combat**
- *Contexte :* pilier 1 : projectiles et hitbox toujours lisibles, quel que soit le palier.
- *Décision :* le shader de distorsion ne s'applique qu'au décor ; entités, télégraphes et projectiles sont dessinés au-dessus.
- *Conséquences :* l'abandon se lit sur le décor et le son ; le combat garde sa netteté.

## Sujets transverses

Ces règles s'appliquent à tous les systèmes. Tout code doit les suivre.

### Gestion des erreurs

**Stratégie :** GDScript n'a pas d'exceptions. Trois cas, trois réponses :

| Cas | Exemple | Réponse |
|---|---|---|
| Erreur de programmation (invariant violé) | Projectile sans camp, palier hors bornes | `assert()` (actif en debug uniquement) + `Log.error()` |
| Erreur récupérable à l'exécution | Fichier absent, JSON illisible, Resource manquante | La fonction renvoie `bool`, `Error` ou `null` ; l'appelant gère ; repli sur une valeur sûre ; `Log.warn()` ou `Log.error()` |
| Donnée invalide au chargement | `ItemDef` sans clé de nom, salle sans porte | Validée au démarrage en debug et par le validateur headless ; refusée avant la run |

- Le jeu ne s'arrête jamais sur une erreur en build de release : il journalise et continue avec une valeur sûre.
- Une erreur ne met jamais le jeu en pause. En debug, elle s'affiche en toast dans la surcouche.
- Seul le joueur voit une erreur de sauvegarde illisible (message localisé ; le fichier est renommé en `.corrupt`).

```gdscript
func load_profile() -> Profile:
	var data := _read_json("user://profile.json")
	if data == null:
		Log.warn("save", "profile missing or unreadable, starting fresh")
		return Profile.new()
	return Profile.from_dict(data)
```

### Logs

**Format :** `[hh:mm:ss.mmm] [NIVEAU] [catégorie] message`
**Destination :** console de l'éditeur et fichier de log intégré à Godot (`user://logs/`, activé par défaut sur desktop).

| Niveau | Usage | Actif en release |
|---|---|---|
| ERROR | Quelque chose a cassé (aussi envoyé à `push_error`) | Oui |
| WARN | Inattendu mais géré (aussi envoyé à `push_warning`) | Oui |
| INFO | Jalons : lancement de run (avec la seed), entrée d'étage, mort, victoire, sauvegarde | Oui |
| DEBUG | Diagnostic : changement de palier, vague, tirage | Non |
| TRACE | Très verbeux, activé par catégorie | Non |

- Un autoload `Log` : `Log.info(category, message)`. Catégories : `run`, `room`, `combat`, `lucidity`, `items`, `gen`, `save`, `input`, `audio`, `ui`.
- `print()` direct interdit hors de `Log`.
- **Aucun log dans les boucles par frame** (projectiles, `_physics_process`). Ces données passent par des compteurs affichés dans la surcouche de debug.
- La seed est toujours journalisée au lancement d'une run, pour reproduire un bug.

```gdscript
Log.info("run", "run started seed=%s floor=%d" % [seed_code, floor_index])
```

### Configuration

| Type | Où | Exemple |
|---|---|---|
| Constantes techniques | `scripts/core/constants.gd` (`class_name Const`) | `TILE_SIZE = 16`, `VIEWPORT = Vector2i(640, 360)`, couches de collision |
| Valeurs d'équilibrage | Resources `.tres` dans `data/` (D4) | `LucidityTuning.tiers`, `EnemyDef.hp` |
| Réglages joueur | Autoload `Settings` → `user://settings.cfg` | Volumes, VSync, intensité des distorsions, touches |
| Plateforme | Surcharges `project.godot` par feature (`.windows`, `.macos`) | Uniquement si nécessaire |
| Mode debug | `OS.is_debug_build()` | Outils de triche, niveau de log |

- Les couches et masques de collision sont nommés dans les réglages du projet, et référencés par les constantes de `Const`, jamais par des nombres.

### Événements

**Pattern :** signaux Godot typés. Bus `Events` (autoload) pour le transverse, signaux locaux pour le reste (D3). Traitement synchrone.

**Nommage :**
- Signaux : `snake_case`, au passé, pour ce qui s'est produit (`player_hit`, `room_cleared`, `lucidity_tier_changed`).
- Le bus ne transporte que des notifications, jamais d'ordres. Pour faire faire quelque chose à un système, on l'appelle directement.
- Gestionnaires : `_on_<émetteur>_<signal>` (`_on_events_room_cleared`).

**Connexions :**
- Connexion en code dans `_ready()`.
- Un `RefCounted` connecté au bus (par exemple `ItemEffect`) se déconnecte explicitement dans `detach()`.
- La télémétrie de playtest écoute le bus ; aucun système n'appelle la télémétrie directement.

```gdscript
# events.gd (autoload)
signal player_grazed(bullet_id: int, gain: int)
signal room_cleared(room: Room, lowest_tier: Lucidity.Tier)

# hud.gd
func _ready() -> void:
	Events.room_cleared.connect(_on_events_room_cleared)
```

### Outils de debug

**Activation :** cheats disponibles uniquement si `OS.is_debug_build()` ; compteur de perf disponible partout.

| Touche | Outil | Builds |
|---|---|---|
| F1 | Panneau de debug : invulnérabilité, lucidité fixée, apparition d'un ennemi choisi, tuer tout, vague suivante, relance avec une seed | Debug |
| F2 | Affichage des hitbox, hurtbox, rayon de graze, emplacements d'apparition et de renfort | Debug |
| F3 | FPS, 1 % low, nombre de projectiles, palier live et palier de salle | Toutes |
| F4 | Ralenti global ×0,25 (réglage des sensations et des télégraphes) | Debug |
| F5 | Scène de test de charge : 400 projectiles ennemis | Debug |

- Le panneau de debug est une scène séparée, instanciée par `Main` seulement en debug : elle n'existe pas dans le code de release.
- Les commandes de debug appellent les mêmes méthodes publiques que le jeu (`lucidity.set_value()`), jamais des raccourcis internes.

## Structure du projet

### Organisation

**Pattern :** par fonctionnalité (domaine du jeu), avec les valeurs d'équilibrage regroupées dans `data/`.

**Raisons :** une fonctionnalité = un dossier (scène, script, sprites) ; un agent trouve tout au même endroit. Les `.tres` d'équilibrage sont regroupés pour que le réglage au playtest se fasse depuis un seul dossier (D4). Le projet Godot vit dans `game/` pour que Godot n'importe ni la documentation ni BMAD.

### Arborescence

```
hypnagogia/
├── _bmad/, _bmad-output/, docs/, .claude/   — méthode et documentation (hors Godot)
├── art_source/          — sources des graphismes IA (prompts, planches brutes), non importées
├── tools/               — scripts shell : export, validation des salles en headless
├── builds/              — exports (ignoré par git)
└── game/                — projet Godot (res://)
    ├── project.godot
    ├── export_presets.cfg
    ├── default_bus_layout.tres
    ├── addons/          — plugins tiers (GoPeak, framework de test)
    ├── autoloads/       — events.gd, log.gd, settings.gd, save_service.gd, game_clock.gd, audio.gd
    ├── core/            — constants.gd, tuning.gd, run_rng.gd, stat_block.gd, stat_modifier.gd, utils/
    ├── main/            — main.tscn/.gd, transition.tscn/.gd
    ├── run/             — run.tscn/.gd, run_state.gd, floor_map.gd, wake_clock.gd, run_snapshot.gd
    ├── player/          — player.tscn/.gd, player_input.gd, player_motor.gd, dash.gd, lucidity.gd, sprites/
    │   └── powers/      — power.gd, awaken.gd, glide.gd
    ├── combat/          — health.gd, hurtbox.gd, hitbox.gd, telegraph.gd, armor.gd, damage_info.gd, danger_profile.gd
    │   └── bullets/     — bullet_manager.gd, bullet_params.gd, bullet_pattern.gd, bullet_sprites/, enemy_bullet_look.gd
    ├── enemies/         — enemy.gd, enemy_def.gd, shooter_enemy.gd, shooter_def.gd, reinforcement.gd
    │   ├── sleepwalker/ — sleepwalker.tscn/.gd, sprites/
    │   ├── night_light/
    │   ├── sheep/
    │   └── lullaby/
    ├── bosses/          — boss.gd, boss_def.gd, boss_attack.gd
    │   └── professor/   — professor.tscn/.gd, attacks/, sprites/
    ├── items/           — build_carrier.gd, item_def.gd, item_effect.gd, loadout.gd, tag_tracker.gd, consumable_def.gd, synergy_def.gd, pickup.tscn/.gd
    │   ├── effects/     — un script par effet d'objet (free_fall_effect.gd…)
    │   └── sprites/
    ├── economy/         — drops.gd, shop.tscn/.gd, treasure.tscn/.gd
    ├── rooms/           — room.gd, room_base.tscn, door.tscn/.gd, furniture.tscn/.gd
    │   ├── markers/     — enemy_spawn.gd, reinforcement_spawn.gd, trigger.gd
    │   ├── tilesets/    — onset.tres…
    │   ├── arena/       — arena.tscn (jalon A)
    │   ├── pool/onset/  — onset_combat_001.tscn…, onset_start_001.tscn, onset_boss_001.tscn
    │   └── validator/   — validate_rooms.gd (headless)
    ├── generation/      — floor_generator.gd, floor_def.gd, floor_layout.gd
    ├── bedroom/         — bedroom.tscn/.gd, sprites/
    ├── progression/     — profile.gd, achievements.gd, unlocks.gd
    ├── ui/
    │   ├── theme/       — theme.tres, fonts/
    │   ├── hud/         — hud.tscn/.gd, hearts, lucidity_gauge, shards, slots
    │   ├── menus/       — pause, death, settings, keybinds, seed_entry
    │   ├── map/         — floor_map_view.tscn/.gd
    │   └── announcements/ — synergy_banner, tier_flash
    ├── vfx/
    │   ├── shaders/     — dream_distortion.gdshader, hit_flash.gdshader
    │   └── particles/
    ├── audio/
    │   ├── music/       — mus_onset.ogg…
    │   └── sfx/         — sfx_player_dash.wav…
    ├── localization/    — strings.csv (fr de référence)
    ├── data/            — uniquement des .tres
    │   ├── tuning/      — player_tuning, dash_tuning, shot_tuning, lucidity_tuning, combat_tuning, economy_tuning
    │   ├── enemies/     — sleepwalker.tres…
    │   ├── bosses/      — professor.tres
    │   ├── items/       — falling_tooth.tres…
    │   ├── consumables/ — pinch.tres, coffee.tres
    │   ├── synergies/   — fall_2.tres, fall_3.tres
    │   └── floors/      — onset.tres
    ├── debug/           — debug_panel.tscn/.gd, perf_overlay.tscn/.gd, collision_drawer.gd, stress_test.tscn
    ├── telemetry/       — telemetry.gd, telemetry_session.gd
    └── tests/           — unit/, integration/ (miroir des dossiers de code)
```

### Emplacement des systèmes

| Système | Emplacement | Responsabilité |
|---|---|---|
| Bus d'événements, logs, réglages, sauvegarde, temps, audio | `autoloads/` | Services d'application, sans état de run |
| Constantes, RNG, StatBlock | `core/` | Briques sans dépendance vers les scènes |
| Boucle de run, carte, heure du réveil, instantané | `run/` | État d'une nuit |
| Joueur, dash, lucidité, pouvoirs | `player/` | Entité joueur et ses composants |
| Santé, armure, hitbox, télégraphes | `combat/` | Composants partagés par toutes les entités |
| Projectiles et graze | `combat/bullets/` | Gestionnaire orienté données (D1) |
| Ennemis | `enemies/<ennemi>/` | Un dossier par ennemi |
| Cauchemars | `bosses/<cauchemar>/` | Un dossier par cauchemar, attaques en Resources |
| Objets, consommables, synergies | `items/` | Modèle D9, un script par effet |
| Éclats, drops, boutique, trésor | `economy/` | Économie de la run |
| Salles, marqueurs, tilesets, validateur | `rooms/` | Format D10 |
| Génération d'étage | `generation/` | Algorithme D11 |
| Chambre | `bedroom/` | Hub |
| Profil, succès, déblocages | `progression/` | Méta-progression : écoute `Events`, écrit `profile.json` |
| HUD, menus, carte, annonces | `ui/` | Affichage, sans logique de gameplay |
| Shaders et particules | `vfx/` | Effets visuels |
| Valeurs d'équilibrage | `data/` | `.tres` uniquement |
| Textes affichés | `localization/` | Clés et traductions |
| Outils de debug | `debug/` | Instanciés en debug seulement |
| Télémétrie de playtest | `telemetry/` | Écoute le bus d'événements |

### Conventions de nommage

#### Fichiers

- Fichiers et dossiers : `snake_case` (`bullet_manager.gd`, `onset_combat_001.tscn`).
- Un script par classe ; le fichier porte le nom de la classe en `snake_case` (`class_name BulletManager` → `bullet_manager.gd`).
- Le nœud racine d'une scène porte le nom de la scène en `PascalCase` (`sleepwalker.tscn` → `Sleepwalker`).
- Salles : `<phase>_<type>_<nnn>.tscn` (`onset_combat_014.tscn`, `onset_shop_001.tscn`).
- Resources de contenu : suffixe de classe `Def` (`EnemyDef`, `ItemDef`) ; Resources d'équilibrage global : suffixe `Tuning`.

#### Code

| Élément | Convention | Exemple |
|---|---|---|
| Classes | `PascalCase` | `BulletManager`, `ItemDef` |
| Fonctions, variables | `snake_case` | `try_spend()`, `room_tier` |
| Membres privés | préfixe `_` | `_state`, `_process_chase()` |
| Constantes | `UPPER_SNAKE_CASE` | `TILE_SIZE` |
| Enums | `PascalCase`, valeurs en `UPPER_SNAKE_CASE` | `Tier.TOTAL_ABANDON` |
| Signaux | `snake_case` au passé | `room_cleared` |
| Gestionnaires | `_on_<émetteur>_<signal>` | `_on_events_room_cleared` |
| Typage | statique partout, `:=` quand le type est évident | `var speed: float`, `var dir := Vector2.ZERO` |

#### Assets

- Sprites : `<entité>_<animation>.png` (planches), animations nommées `idle`, `walk`, `telegraph`, `attack`, `hurt`, `death`.
- Audio : `mus_<phase>.ogg`, `mus_<phase>_boss.ogg` ; `sfx_<domaine>_<nom>.wav` (`sfx_player_dash.wav`, `sfx_lucidity_tier_down.wav`).
- Clés de localisation : `UPPER_SNAKE_CASE` préfixées par domaine (`ITEM_FALLING_TOOTH_NAME`, `ITEM_FALLING_TOOTH_DESC`, `UI_PAUSE_RESUME`, `SYNERGY_DIVE_NAME`).

#### Lexique : termes du GDD → identifiants de code

| GDD (français) | Code (anglais) |
|---|---|
| Lucidité ; Lucide, Flottant, Dérive, Abandon, Abandon total | `lucidity` ; `LUCID`, `FLOATING`, `DRIFT`, `ABANDON`, `TOTAL_ABANDON` |
| Graze ; dash parfait | `graze` ; `perfect_dash` |
| Éveil ; Glissement | `Awaken` ; `Glide` |
| Éclats | `shards` |
| Cauchemar | `boss` (le mot « Cauchemar » reste dans les textes affichés) |
| Chambre ; heure du réveil | `bedroom` ; `wake_time` |
| Endormissement, Sommeil léger, Sommeil profond, Paradoxal, Étage secret | `onset`, `light_sleep`, `deep_sleep`, `rem`, `dream_within` |
| Le Somnambule, La Veilleuse, Le Mouton, La Berceuse | `Sleepwalker`, `NightLight`, `Sheep`, `Lullaby` |
| Le Professeur (Dictée, Calcul mental, Examen final, Interro surprise) | `Professor` (`dictation`, `mental_math`, `final_exam`, `pop_quiz`) |
| Dent qui tombe, Jambes de plomb, Ailes de papier, Chute libre | `falling_tooth`, `lead_legs`, `paper_wings`, `free_fall` |
| Copie d'examen vierge, Réveil cassé, Miroir, Être nu en public | `blank_exam`, `broken_alarm`, `mirror`, `naked_in_public` |
| Se pincer, Café | `pinch`, `coffee` |
| Tags Chute, Temps, Regard, Corps | `FALL`, `TIME`, `GAZE`, `BODY` |
| Synergies Piqué, Chute sans fin | `dive`, `endless_fall` |
| Pacte ; salle d'oubli ; meubles du rêve ; trous | `pact` ; `oblivion_room` ; `furniture` ; `pits` |
| Renfort ; télégraphe | `reinforcement` ; `telegraph` |
| Arène ; bande de HUD | `arena` ; `hud_band` |
| Dash ; invulnérabilité du dash ; recharge ; tampon d'entrée | `dash` ; `dash_invulnerability` ; `cooldown` ; `input_buffer` |
| Tir ; cadence ; recul du tir ; visée ; réticule ; cible d'entraînement | `shot` ; `fire_rate` ; `recoil` ; `aim` ; `reticle` ; `training_target` |
| Pause ; menu de pause ; réglages ; volume ; plein écran ; VSync ; chiffres de dégâts | `pause` ; `pause_menu` ; `settings` ; `volume` ; `fullscreen` ; `vsync` ; `damage_numbers` |
| Santé ; cœur ; demi-cœur ; armure ; plafond de cœurs ; coup reçu ; invulnérabilité après un coup ; clignotement ; panneau de debug ; émetteur de test | `health` ; `heart` ; `half_heart` ; `armor` ; `heart_cap` ; `hit` ; `hit_invulnerability` ; `blink` ; `debug_panel` ; `test_emitter` |
| Run, nuit, partie ; mort ; issue de la run ; écran de réveil ; se rendormir, relancer ; emplacement de salle ; transition ; couche de décor | `run` ; `death` ; `outcome` ; `wake_screen` ; `restart` ; `room_slot` ; `transition` ; `decor` |
| Ennemi ; PV ; dégâts au contact ; zone de contact ; apparition ; distance minimale d'apparition ; ennemis vivants ; poursuite ; accélération du Somnambule ; lever les bras | `enemy` ; `hp` (`HitPoints`) ; `contact_damage` ; `Hitbox` ; `spawn` ; `min_spawn_distance` ; `alive_enemies` ; `chase` ; `rush` ; `raise_arms` |
| Tireuse ; cycle de tir ; lueur ; inspirer ; éventail ; écart de l'éventail ; salve ; projectile visé ; distance de maintien (min, max) ; se tenir à distance ; projectile ennemi ; apparence réservée des projectiles ennemis | `shooter` (`ShooterEnemy`, `ShooterDef`) ; `fire_interval` ; `glow` ; `inhale` ; `fan` ; `spread_angle` ; `volley` ; `aimed shot` ; `min_distance`, `max_distance` ; `keep_distance` ; `enemy_bullet` ; `EnemyBulletLook` (`COLOR_ENEMY_BULLET`, `COLOR_ENEMY_BULLET_OUTLINE`) |

Tout nouveau terme du GDD entre dans ce lexique avant d'apparaître dans le code.

### Frontières architecturales

- `autoloads/` et `core/` ne dépendent d'aucun dossier de fonctionnalité. Les fonctionnalités dépendent d'eux, jamais l'inverse.
- Une fonctionnalité n'accède pas aux internes d'une autre : elle passe par les méthodes publiques d'un composant ou par `Events`.
- `ui/` lit l'état par signaux et ne modifie jamais l'état de gameplay (sauf les réglages, via `Settings`).
- Rien ne dépend de `debug/` ni de `telemetry/`.
- `data/` ne contient que des `.tres`, jamais de script.
- Seul `rooms/pool/` contient des salles jouables ; le générateur ne lit que les salles listées par un `FloorDef`.
- Les sources lourdes (planches IA brutes, projets audio) restent hors de `game/` : seuls les fichiers finaux (`.png`, `.ogg`, `.wav`) y entrent.

## Patterns d'implémentation

Ces patterns garantissent que tous les agents écrivent du code compatible.

### Patterns nouveaux

#### P1. Lucidité et danger de salle

**But :** appliquer le danger du palier le plus bas atteint dans la salle, et les récompenses en direct.

**Composants :**
- `Lucidity` (joueur) : valeur, `live_tier`, `room_tier`, `try_spend()`, `gain()`.
- `DangerProfile` : calculé depuis `room_tier` et `LucidityTuning` → `enemy_bullet_speed_mult`, `telegraph_mult`, `reinforcement`, `boss_extra_pattern`.
- `Room` : détient le `DangerProfile` courant, gère le renfort.

**Flux :**
1. `Room.enter()` appelle `lucidity.begin_room()` : `room_tier = live_tier`, le compteur de graze repart à 0.
2. Une dépense fait baisser `live_tier`. S'il passe sous `room_tier`, `room_tier` suit, et `room_danger_raised` est émis.
3. `Room` recalcule son `DangerProfile`, joue le son et l'effet d'aggravation, puis, si le palier atteint Abandon pour la première fois, programme le renfort (annoncé 0,6 s avant, sur un `ReinforcementSpawn`, copie du type le plus présent, tirage dans le flux `combat`).
4. Les ennemis lisent `room.danger` au moment où ils lancent un télégraphe ou tirent. Les projectiles déjà en vol gardent leur vitesse.
5. Remonter ne change pas `room_tier` avant la salle suivante.
6. `room_cleared` transmet `room_tier`, qui fixe le multiplicateur de loot.
7. Les bonus de dégâts et la précision suivent `live_tier` via des modificateurs du `StatBlock`, mis à jour sur `tier_changed`.

**Cas limites :** en arène, `begin_room()` est appelé à chaque vague ; un seul renfort par salle ; les télégraphes ne descendent jamais sous 0,4 s.

```gdscript
func _on_lucidity_room_danger_raised(tier: Lucidity.Tier) -> void:
	danger = DangerProfile.from_tier(tier, Tuning.LUCIDITY)
	if danger.reinforcement and not _reinforcement_done:
		_reinforcement_done = true
		_schedule_reinforcement()
```

#### P2. Graze et dash parfait

**But :** récompenser le skill dans la boucle des projectiles, sans coût supplémentaire.

**Flux :** à chaque tick, pour chaque projectile ennemi actif, le `BulletManager` ennemi :
1. si le projectile touche la hurtbox :
   - joueur invulnérable par **dash** et projectile pas encore compté → `perfect_dash` (+5), le projectile est marqué et continue sa course ;
   - joueur invulnérable après un **coup** → rien ;
   - sinon → coup, le projectile est détruit ;
2. sinon, si la distance est < 1 tuile, que le projectile n'est pas marqué et que le joueur n'est pas invulnérable → `player_grazed` (+2), le projectile est marqué.

**État :** un drapeau par projectile (`counted`). Le dash parfait est compté par projectile évité, pas par dash. Le plafond de +20 par salle est tenu par `Lucidity.gain()`, pas par le `BulletManager`.

```gdscript
if _hits_player(i):
	if player.is_dash_invulnerable() and not _counted[i]:
		_counted[i] = 1
		Events.perfect_dash.emit(i)
	elif not player.is_invulnerable():
		player.hurtbox.receive(DamageInfo.from_bullet(_params[i]))
		_free(i)
elif not _counted[i] and not player.is_invulnerable() and _dist_sq(i) < _graze_radius_sq:
	_counted[i] = 1
	Events.player_grazed.emit(i, Tuning.LUCIDITY.graze_gain)
```

#### P3. Reprise en début de salle

**But :** « sauvegarder et quitter » et reprise après un crash, à l'identique.

**Composants :** `RunSnapshot` (`run/run_snapshot.gd`), `SaveService`.

**Flux :**
1. À l'entrée d'une salle, avant l'apparition des ennemis, `Run` construit un `RunSnapshot` : seed, étage, carte (visitées, vidées), heure du réveil, état du joueur (cœurs, armure, lucidité, Éclats, ids des objets, charge de l'actif, consommable), états de tous les flux RNG.
2. `SaveService.write_run(snapshot)` l'écrit de façon atomique.
3. Au lancement, si `run.json` existe, le jeu propose de reprendre : la run est reconstruite depuis l'instantané, `run.json` est effacé, et la salle est rejouée depuis son début.
4. En fin de run (mort ou victoire), `run.json` est effacé.

**Règle :** tout état qui survit à une salle implémente `to_dict() -> Dictionary` et `static func from_dict(d: Dictionary)`. Les objets sont référencés par leur `id`, jamais sérialisés.

#### P4. Temps par groupe

```gdscript
# game_clock.gd (autoload)
enum Group { PLAYER, ENEMIES, ENEMY_BULLETS, PLAYER_BULLETS, WORLD, FX }
var _scales: Dictionary[Group, float] = {}

func scale(group: Group) -> float:
	return 0.0 if paused else _scales.get(group, 1.0)

# usage, dans tout script de gameplay
func _physics_process(delta: float) -> void:
	var dt := delta * GameClock.scale(GameClock.Group.ENEMIES)
	_cooldown -= dt
```

Réveil cassé : `GameClock.set_scale_for(groups_except_player, 0.5, 4.0)`, qui revient à 1,0 tout seul.

#### P5. Entités qui portent un build

**But :** le joueur, le reflet du Miroir et Toi partagent le même modèle.

**Composants :** un nœud composant `BuildCarrier` (enfant de l'entité, puisque GDScript n'a pas d'interfaces) qui porte `StatBlock`, `Loadout` et `TagTracker` et émet `hit_taken`, `dash_ended`, `room_cleared`. Les `ItemEffect` s'y branchent. Toute entité qui a un enfant `BuildCarrier` peut recevoir des objets.

```gdscript
# items/effects/free_fall_effect.gd
class_name FreeFallEffect extends ItemEffect

func attach(carrier: BuildCarrier) -> void:
	super.attach(carrier)
	carrier.hit_taken.connect(_on_carrier_hit_taken)

func detach() -> void:
	carrier.hit_taken.disconnect(_on_carrier_hit_taken)
	super.detach()

func tick(dt: float) -> void:
	_bonus = minf(_bonus + def.params.rate * dt, def.params.max_bonus)
	carrier.stats.set_modifier(self, StatBlock.Stat.DAMAGE, StatModifier.ADD_PERCENT, _bonus)
```

Le reflet du Miroir reçoit une copie des `ItemDef` du joueur, dans son propre `Loadout`. Il tire par le `BulletManager` ennemi de la salle, avec une apparence dédiée (couleur et contour exclusifs).

### Communication

- Notifications transverses → `Events`. Vers ses enfants → appel direct. Vers son parent → signal local.

```gdscript
# health.gd (composant)
signal died
func apply_damage(info: DamageInfo) -> void:
	_current -= info.amount
	if _current <= 0:
		died.emit()

# sleepwalker.gd (parent)
func _ready() -> void:
	health.died.connect(_on_health_died)
```

### Création d'entités

- Toute apparition d'ennemi passe par `room.spawn_enemy(def, position)`. La salle tient le compte et détecte qu'elle est vidée.
- Tout projectile passe par `BulletManager.fire(params, origin, direction)`. Jamais d'instanciation de scène pour un projectile.
- Toute apparition de ramassable passe par `Drops.spawn(kind, position, rng)`.
- Injection de dépendances : `setup()` est appelée **avant** `add_child()`. Les dépendances internes à la scène passent par `@export` ou `%NomUnique`.
- Pools uniquement pour les projectiles et les effets d'impact.
- Story 2.4 : `Enemy.setup(def, target, target_hurtbox, bullets)` : l'arène passe son `BulletManager` ennemi à tout ennemi (les tireuses tirent par lui, les autres l'ignorent).
- Apparition d'un ennemi (story 2.3) : à au moins `min_spawn_distance` (3 tuiles) du joueur ; une position trop proche ou hors de la zone jouable est remplacée de façon déterministe (sans RNG avant l'epic 4). Un ennemi n'est jamais mis en pool ni déplacé d'un parent à l'autre.

```gdscript
func spawn_enemy(def: EnemyDef, pos: Vector2) -> Enemy:
	var enemy: Enemy = def.scene.instantiate()
	enemy.setup(def, self)
	enemy.position = pos
	_enemies.add_child(enemy)
	_alive += 1
	enemy.tree_exited.connect(_on_enemy_tree_exited)
	return enemy
```

### États et télégraphes

- Machine à états par `enum` + `match`, une fonction `_process_<état>()` par état, transitions par `_enter(state)` uniquement.
- **Toute attaque passe par le composant `Telegraph`** : animation, son et durée = `maxf(base * danger.telegraph_mult, Tuning.COMBAT.min_telegraph)`.

```gdscript
func _enter(next: State) -> void:
	_state = next
	match next:
		State.TELEGRAPH:
			telegraph.start(def.charge_telegraph, room.danger)
		State.ATTACK:
			_start_charge()
```

### Accès aux données

- Contenu : chaque entité reçoit sa `Def` par `setup()` ou `@export`.
- Équilibrage global : `Tuning` (classe statique, pas d'autoload) précharge les `.tres` de `data/tuning/`.
- **Les Resources sont en lecture seule à l'exécution.** Un `.tres` chargé est partagé : on ne le modifie jamais. L'état d'exécution vit dans des objets séparés (`Health`, `Lucidity`, `StatBlock`).

```gdscript
# core/tuning.gd
class_name Tuning
const PLAYER: PlayerTuning = preload("res://data/tuning/player_tuning.tres")
const LUCIDITY: LucidityTuning = preload("res://data/tuning/lucidity_tuning.tres")
const COMBAT: CombatTuning = preload("res://data/tuning/combat_tuning.tres")
```

### Dégâts et unités

- Les dégâts passent toujours par `DamageInfo` (`amount`, `source`, `is_heavy`) → `Hurtbox.receive()` → `Health.apply_damage()`.
- Joueur : dégâts en **demi-cœurs** (entiers), armure consommée en premier. Ennemis : dégâts en PV (flottants).
- Les PV d'un ennemi sont dans `HitPoints` (flottants, ni armure ni invulnérabilité), pas dans `Health` (réservée au joueur). Un propriétaire qui n'applique pas un coup appelle `Hurtbox.refuse_hit()` dans son gestionnaire : `receive()` renvoie `false` et n'émet pas `Events.enemy_damaged` (story 2.3).
- Resources : distances en **tuiles**, durées en **secondes**, angles en **degrés**. Code : pixels et radians, convertis à la lecture (`Const.TILE_SIZE`, `deg_to_rad`).

### Règles de cohérence

| Pattern | Convention | Contrôle |
|---|---|---|
| Temps | `delta * GameClock.scale(group)` ; pas de `Timer` pour le gameplay | Revue : recherche de `Timer`, `create_timer`, `time_scale` |
| Aléatoire | Flux de `RunRng` uniquement | Revue : recherche de `randf`, `randi`, `shuffle`, `pick_random`, `randomize` |
| Valeurs de gameplay | Dans une Resource, jamais en dur | Revue : nombres magiques dans les scripts de gameplay |
| Textes affichés | `tr("CLE")` | Revue : chaînes littérales dans `ui/` |
| Typage | Statique partout | Réglage projet : avertissements de typage en erreur |
| Logs | `Log.<niveau>()` ; pas de `print()` | Revue : recherche de `print(` |
| Apparitions | `room.spawn_enemy`, `BulletManager.fire`, `Drops.spawn` | Revue |
| Resources | Lecture seule à l'exécution | Revue : affectations sur une `Def` ou un `Tuning` |
| Persistance | `to_dict()` / `from_dict()` | Test de reprise au jalon B |
| Lucidité | Le danger lit `room_tier`, les récompenses en direct lisent `live_tier` | Revue |

### Compléments (ajoutés à la validation)

- **Trous :** `PlayerMotor` mémorise à chaque tick la dernière position sûre (sur une cellule de sol). La chute se teste par lecture de cellule du `TileMapLayer` `Pits`, à la fin d'un dash, d'un Glissement ou d'un déplacement. Un dash ne survole un trou que si sa position finale est hors du trou. Une chute = `DamageInfo` de source `PIT`, puis retour à la dernière position sûre. Ailes de papier et Chute sans fin passent par des modificateurs du `StatBlock` (`can_fly_over_pits`, `pit_damage`).
- **Glissement :** la destination est résolue par un lancer de rayon (`PhysicsDirectSpaceState2D.intersect_ray`) contre les couches murs, obstacles hauts et ennemis ; le joueur s'arrête au dernier point libre. Les obstacles bas ne sont pas dans le masque. Un trou est une destination valide.
- **Caméra :** salle d'un écran : `Camera2D` fixe, centrée. Grande salle : la caméra suit le joueur, bornée par les limites de la salle. Bande de HUD en haut de l'écran (24 px), hors de la zone jouable de 36×19 tuiles.
- **Run avec seed saisie :** `RunState.seeded = true` ; `progression/` ignore alors tous les événements de déblocage et de mystère.
- **Succès et déblocages :** `progression/achievements.gd` écoute `Events` et enregistre les premières victoires dans `profile.json`. Au MVP, rien n'est débloqué, mais les victoires sont déjà enregistrées.
- **Interpolation des projectiles :** l'interpolation physique 2D ne couvre pas forcément les instances d'un `MultiMesh`. À vérifier au jalon A sur un écran à 144 Hz ; si les projectiles saccadent, le `BulletManager` interpole lui-même les positions de rendu entre deux ticks.
- **Tests :** les classes de logique pure (`Lucidity`, `StatBlock`, `RunRng`, `FloorGenerator`, `RunSnapshot`) sont des `RefCounted` sans dépendance aux scènes, donc testables sans lancer le jeu. Le framework est choisi avec `gds-test-framework`.

## Validation de l'architecture

### Synthèse

| Contrôle | Résultat | Notes |
|---|---|---|
| Compatibilité des décisions | Réussi après corrections | `BuildCarrier` devenu un composant nœud (GDScript n'a pas d'interfaces) ; autoload `Log` ajouté à la liste ; reflet du Miroir sur le `BulletManager` ennemi de la salle |
| Couverture du GDD | Réussi après compléments | Ajoutés : trous, Glissement, caméra, run avec seed saisie, succès et déblocages |
| Complétude des patterns | Réussi | Création, communication, états, erreurs, accès aux données, événements, dégâts, unités, persistance |
| Correspondance avec les epics | Réussi après correction | Dossier `progression/` ajouté pour E6 (victoires et succès) |
| Complétude du document | Réussi | Aucun texte provisoire ; l'emplacement de l'éditeur est explicitement reporté à l'installation |

### Correspondance epics → architecture

| Epic | Emplacements | Décisions et patterns |
|---|---|---|
| E1. Contrôles et sensations | `player/`, `combat/bullets/`, `main/`, `ui/menus/` | D1, D6, D7, D13 |
| E2. Lucidité à deux pôles | `player/lucidity.gd`, `player/powers/`, `vfx/shaders/`, `autoloads/audio.gd` | D5, D13, D15, P1, P2 |
| E3. Combat et ennemis | `enemies/`, `combat/`, `ui/hud/`, `debug/`, `telemetry/` | D1, D2, D18, P1, P2, États et télégraphes |
| E4. Étage et génération | `rooms/`, `generation/` | D8, D10, D11 |
| E5. Objets et économie | `items/`, `economy/`, `data/` | D4, D9, P5 |
| E6. Le Professeur et la boucle de run | `bosses/professor/`, `run/`, `bedroom/`, `progression/`, `autoloads/save_service.gd` | D2, D12, D14, P3 |
| E7. Direction artistique et audio | `art_source/`, `vfx/`, `audio/`, `ui/theme/`, `autoloads/settings.gd` | D13, D15, D16 |

### Couverture

- **Systèmes couverts :** 16 sur 16 (tableau du Contexte du projet).
- **Décisions :** 18 (D1 à D18), dont 6 avec fiche ADR.
- **Patterns :** 5 nouveaux (P1 à P5) et 7 standard (communication, création, états et télégraphes, accès aux données, dégâts et unités, cohérence, compléments).

### Versions

- Godot 4.7.2 stable, vérifié le 2026-11-20. Toutes les décisions reposent sur des fonctionnalités intégrées à Godot ; aucune bibliothèque tierce dans le jeu.
- MCP GoPeak : **reporté** (décision du 2026-11-20) ; le paquet npm `gopeak` est déprécié (CWE-78), voir « Choix retenu » dans l'environnement de développement.

### Points à vérifier au jalon A

1. Test de charge à 400 projectiles sur la machine de référence (rendu Compatibility, boucle en GDScript).
2. Latence d'entrée ≤ 3 frames avec VSync activée.
3. Rendu des projectiles sur un écran à plus de 60 Hz (interpolation).
4. Export macOS non signé lancé sur un Mac.

### Date de validation

2026-11-20

## Environnement de développement

### Prérequis

- **Godot 4.7.2 stable**, version standard (sans .NET), et ses modèles d'export (Windows, macOS).
- **Git**.
- **Node.js** (pour lancer Context7 avec `npx` ; GoPeak est reporté).
- Une **manette Xbox** pour tester la bascule de périphérique.
- Un **Mac** pour tester l'export macOS (jalon A pour un premier essai, sinon jalon B).

### Outillage IA (serveurs MCP)

| Serveur MCP | Rôle | Installation |
|---|---|---|
| GoPeak (`HaD0Yun/Gopeak-godot-mcp`), **reporté** | Édition de scènes et de scripts, diagnostics LSP, logs, arbre de scène en direct, captures, injection d'entrées | Non installé : le paquet npm est déprécié (voir « Choix retenu ») |
| Context7 (`upstash/context7`) | Documentation Godot à jour | `npx` |

**Mise en place (Claude Code) :** Context7 uniquement ; GoPeak reste à installer plus tard (voir « Choix retenu »).

```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp
```

**Choix retenu (2026-11-20, story 1.1) : éditeur Linux via WSLg, option A.**

- Binaire : Godot 4.7.2 stable Linux x86_64 (version standard), installé hors du dépôt dans `~/.local/opt/godot/Godot_v4.7.2-stable_linux.x86_64`, avec le lien `~/.local/bin/godot`. Archive vérifiée par SHA-512.
- `GODOT_PATH` : `/home/kroustille/.local/opt/godot/Godot_v4.7.2-stable_linux.x86_64`.
- Le CLI `claude` n'existe pas dans le WSL : les MCP sont déclarés dans `.mcp.json` à la racine, **ignoré par git** (config propre à la machine, avec `GODOT_PATH`). Context7 (`@upstash/context7-mcp` 4.7.3) y est déclaré et démarre.
- **GoPeak : reporté (décision du 2026-11-20), non configuré.** Le paquet npm `gopeak` 2.3.8 est déprécié : injection de commande via les arguments d'outils (CWE-78) dans toutes les versions npm, et GoPeak n'est plus publié sur npm. Les versions corrigées (2.4.1 ou plus) se trouvent dans les releases GitHub de `HaD0Yun/Doyunha-Gopeak`. Mode d'installation à décider avant d'activer ce serveur (entrée `godot` avec `GODOT_PATH`, `command` pointant vers la version installée). Alternative : `Coding-Solo/godot-mcp`. Les plugins éditeur et runtime ne sont pas installés.
- **À tester hors WSL :** performances et latence (stories 1.2 et 1.8) sur un export Windows natif, car le rendu WSLg passe par Mesa/d3d12 et n'est pas représentatif ; manette (story 1.7) sous Windows, car elle n'est pas transmise à WSL sans `usbipd` ; Retina et macOS (story 1.8) sur un Mac.
- Dépendances système du binaire Linux sous WSL (Debian 13) : bibliothèques graphiques absentes par défaut (voir les Completion Notes de la story 1.1).

### Initialisation

```bash
mkdir -p game art_source tools
printf '\n# Godot\ngame/.godot/\nbuilds/\n' >> .gitignore
```

Puis, dans Godot 4.7.2 : créer un projet dans `game/` avec les réglages de la section Moteur et framework, nommer les couches de collision, et déclarer les autoloads `Events`, `Log`, `Settings`, `SaveService`, `Audio`, `GameClock`.

### Premiers pas

1. Installer Godot 4.7.2 et ses modèles d'export.
2. Créer le projet dans `game/` et appliquer les réglages initiaux.
3. Configurer les serveurs MCP (voir Outillage IA).
4. Poser le socle : autoloads, `Const`, `Tuning`, `RunRng`, surcouche de debug (F3).
5. **Lever le risque n°1 :** prototype du `BulletManager` et scène de test de charge à 400 projectiles (F5), mesurée sur la machine de référence.
6. Joueur, dash et tir dans l'arène (E1), puis lucidité (E2) et ennemis (E3).

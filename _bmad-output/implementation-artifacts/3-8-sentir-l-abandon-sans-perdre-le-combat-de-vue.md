# Story 3.8 : Sentir l'abandon, sans perdre le combat de vue

Status: ready-for-dev

## Story

En tant que joueur,
je veux que le décor ondule et que la musique s'étouffe à mesure que je plonge, avec des réglages pour adoucir ces effets,
afin de sentir le rêve déborder sans jamais perdre la lisibilité du combat.

Exigences : FR25 (distorsions, passe-bas), FR67, AR19, AR21 (passe-bas), NFR8 (epics.md, Story 3.8). Architecture : couches de rendu (AR19), bus `Music`, réglages (`Settings`).

**Dépend de : 3.1** (palier en direct), **3.3** (Éveil : le tremblement léger s'y accroche) et **3.7** (flux `cosmetic` de `RunRng`). Indépendante des danger/renfort de 3.6/3.7 : les effets suivent `live_tier`, pas `room_tier`.

Hors périmètre : musique réelle (7.7 ; ici une boucle provisoire), menu d'accessibilité complet (epic 7), shaders définitifs, contrôles de contraste (NFR8 : on vérifie seulement que la couche de combat n'est jamais déformée).

## Critères d'acceptation

1. **Couches** : la scène de jeu dessine dans cet ordre : décor (sols et murs), post-traitement, entités, combat (projectiles ennemis et signes de combat), HUD (`CanvasLayer`). Constantes `Const.Z_INDEX_DECOR = -2`, `Z_INDEX_POSTFX = -1`, entités 0, `Z_INDEX_ENEMY_BULLETS = 10` (déjà), HUD par `CanvasLayer` ; un test lit les valeurs et l'ordre des nœuds.
2. **Distorsions** : l'ondulation du décor et l'aberration chromatique augmentent à chaque palier **en direct** ; intensité = `f(palier) × réglage` (`LucidityTuning.fx_wave[]`, `fx_aberration[]`, 0 en Lucide). Les entités, télégraphes, projectiles et HUD restent nets à tous les paliers (le shader ne touche que ce qui est dessiné avant lui). Les changements d'intensité sont interpolés (0,5 s), jamais un saut.
3. **Musique** : une boucle provisoire joue sur le bus `Music` ; un `AudioEffectLowPassFilter` sur ce bus étouffe de plus en plus (`fx_music_cutoff_hz[]` par palier) quand le palier en direct descend, et s'ouvre quand il remonte (interpolé).
4. **Réglages** (menu Réglages, persistés dans `settings.cfg`) : intensité des distorsions (0 à 100 %), intensité des tremblements d'écran (0 à 100 %), mode photosensibilité (case). Baisser un réglage réduit l'effet correspondant. Le mode photosensibilité : aucun flash plein écran (il n'y en a pas), distorsions plafonnées (`fx_photosensitive_cap`), tremblements supprimés.
5. **Tremblement léger d'Éveil** (le seul consommateur des tremblements) : décalage de la caméra d'un à deux pixels pendant 0,15 s à l'usage d'Éveil, tiré dans le flux `cosmetic` de `RunRng`, entier, multiplié par le réglage ; rien en photosensibilité ou à 0.
6. **Relecture** : les effets repartent de zéro à chaque nouvelle partie (filtre ouvert, distorsion nulle) ; ils ne modifient ni le gameplay ni le déterminisme (flux `cosmetic`).

## Tâches

- [ ] `Const` : `Z_INDEX_DECOR` passe de -1 à -2 (chercher toutes les utilisations : `Arena`, scènes `.scratch`), `Z_INDEX_POSTFX = -1`, `Z_INDEX_COMBAT = 10` (alias de `Z_INDEX_ENEMY_BULLETS`).
- [ ] `vfx/shaders/lucidity_distortion.gdshader` (`canvas_item`) : `uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest`, uniforms `wave_amount` (px), `aberration` (px), `time` ; décalage par entier de pixels (arrondi) ; aucun flou.
- [ ] `vfx/lucidity_fx.gd` (`Node`, fils de l'arène) : crée `PostFx` (`ColorRect` de la taille du cadre de la salle, `z_index = Z_INDEX_POSTFX`, matériau du shader) ; cible d'intensité par palier ; interpolation en ticks du groupe `FX` ; applique `Audio.set_music_muffle(cutoff_hz)` ; lit `Settings`. `setup(player)` avant `add_child` ; état initial depuis `lucidity.live_tier` ; écoute `Events.lucidity_tier_changed`.
- [ ] `Audio` : boucle provisoire (`audio/music/music_placeholder.wav`, générée, 8 s, `loop_mode` avant) jouée sur `Music` à `_ready` ; `AudioEffectLowPassFilter` ajouté à `Music` par code ; `set_music_muffle(cutoff_hz)`, `music_cutoff_hz()` ; `Main` ne la relance pas à chaque partie.
- [ ] `Settings` : `distortion_intensity`, `shake_intensity` (0..1, défaut 1), `photosensitive` (faux) ; section `[accessibility]` de `settings.cfg`, lecture assainie (type et bornes, `NaN` refusé), setters qui enregistrent, comme `damage_numbers`.
- [ ] `SettingsMenu` : deux curseurs et une case (réutiliser les modèles volume et `DamageNumbersButton`) ; clés `UI_SETTINGS_DISTORTION`, `UI_SETTINGS_SHAKE`, `UI_SETTINGS_PHOTOSENSITIVE` dans `strings.csv` ; la case photosensibilité prime sur les curseurs sans les modifier (décision 4).
- [ ] `LucidityTuning` : `fx_wave`, `fx_aberration`, `fx_music_cutoff_hz` (5 valeurs chacun), `fx_transition` (0,5 s), `fx_photosensitive_cap` (0,5), `shake_pixels` et `shake_duration` pour Éveil.
- [ ] `Arena.shake(pixels, duration)` : décalage entier de `Camera`, retour exact à la position d'origine ; appelé par `_on_awakening_used` (3.3).
- [ ] Vérifications `t_lucidity_fx` ; une capture fenêtrée WSLg pour juger (NON VÉRIFIÉ par un humain) ; `run_all.sh` une fois à la fin.

## État du code concerné

- `Const.Z_INDEX_DECOR = -1` : `Floor` et `Walls` ; `Z_INDEX_ENEMY_BULLETS = 10` (manager ennemi) ; le HUD est dans le `CanvasLayer` `UI` de `Main` (au-dessus du monde). Le réticule est à 100. Entités à 0. **Pas de passe de post-traitement.**
- `Arena` : caméra fixe (`%Camera`, `process_callback = 0`, `reset_physics_interpolation()` après placement) ; décor construit en code ; le cadre fait `(36+2) × (19+2)` tuiles, décalé par le bandeau HUD (24 px).
- `default_bus_layout.tres` : `Master`, `Music`, `SFX`, `UI` ; `Settings` applique les volumes et enregistre `settings.cfg` ; `SettingsMenu` a trois volumes, plein écran, vsync, chiffres de dégâts.
- `Audio` : 16 lecteurs SFX sur le bus `SFX`, ne suit pas `GameClock`. Pas de musique. Le bus `Music` n'a pas d'effet.
- 3.1 : `Events.lucidity_tier_changed(tier, previous)` et `lucidity_value_changed(value, tier)` ; flash de 0,3 s de la jauge au changement de palier (petite zone, pas plein écran). 3.3 : `Arena._on_awakening_used`. 3.7 : `Run.rng.stream(&"cosmetic")`, passé à l'arène (`arena.rng`).
- `Telemetry` : rien à ajouter (le temps par palier est déjà journalisé).

## Pièges

- **Le shader lit tout ce qui est dessiné avant lui**, pas « le décor » : l'ordre se règle par `z_index` puis par ordre dans l'arbre à z égal. `Z_INDEX_DECOR = -2`, `PostFx = -1`, entités 0 : le décor est dessiné d'abord, puis la copie déformée, puis tout le reste, intact. Ne jamais mettre d'entité à z négatif. Les scènes de vérification qui testent le z du décor doivent suivre le changement.
- `hint_screen_texture` copie le tampon courant : le `ColorRect` doit avoir un `ShaderMaterial` par instance (créé dans `LucidityFx`, jamais un `.tres` partagé écrit à l'exécution) ; le rendu `Compatibility` / `Forward+` est le même pour ce cas, mais la copie coûte un tampon (mesure NFR : budget 60 fps vérifié en F3 pendant la vérification fenêtrée).
- **Nettoyer les pixels** : `viewport` stretch en 640×360, `filter_nearest` + décalage entier (`floor`) : pas de flou ni de crénelage du décor. L'ondulation se fait sur des lignes horizontales (décalage en x par ligne de pixels), pas par UV continues.
- **Headless sans rendu** : on ne peut pas lire des pixels ; les tests lisent les uniforms du matériau et l'ordre des couches ; l'aspect est jugé en fenêtre (WSLg, llvmpipe) et marqué `NON ÉVALUÉ`.
- **Passe-bas** : `AudioEffectLowPassFilter.cutoff_hz` accepte 1 à 20 500 Hz ; la valeur « ouverte » est 20 500. Ajouter l'effet **une seule fois** (`Audio._ready`) : `add_bus_effect` à chaque partie les empile. Interpoler `cutoff_hz` en **échelle logarithmique** (sinon la fermeture est brutale à haute fréquence).
- **Boucle WAV** : un `AudioStreamWAV` généré doit avoir `loop_mode = LOOP_FORWARD`, `loop_begin = 0`, `loop_end = nombre d'échantillons` ; sinon il ne boucle pas ; pour un fichier importé, régler l'import du `.wav` (`edit/loop_mode`). En headless, le pilote audio est factice : on teste les réglages, pas le son.
- **Tremblement** : décaler `Camera.offset` (entiers, retour **exact** à zéro), pas `position` (l'interpolation physique et `reset_physics_interpolation()` de l'arène) ; tirer dans `cosmetic`, jamais `randf()` ; le décalage se fait en ticks du groupe `FX`. L'écran de réveil et la pause figent le tremblement ; un restart ne doit pas laisser de décalage (réinitialisé par l'arène neuve).
- **Photosensibilité** : l'intensité est plafonnée, l'interpolation lisse (aucun saut), aucune alternance rapide de luminosité ; les `ring_pulse` (3.3, 3.6) restent de petits anneaux. Si un effet s'ajoute plus tard, il lit `Settings.photosensitive`.
- **`Settings`** : valeurs lues du `ConfigFile` en `Variant` : refuser les types et les `NaN`/`INF`, borner à 0..1 ; une clé absente = défaut. Les setters écrivent le fichier (même mécanique que `set_damage_numbers`) ; le menu relit l'état à l'ouverture (`set_pressed_no_signal`).
- **Pas d'effet de gameplay** : le niveau de distorsion ne modifie ni collisions ni vitesses ; les `GameClock` ne sont pas touchés.
- **Texte** : tout libellé en `tr()` et `strings.csv`.

## Vérifications prévues (`.scratch/t_lucidity_fx.gd`)

- Cibles : pour chaque palier, `fx_wave` et `fx_aberration` strictement croissants (0 en Lucide) ; intensité = `f(palier) × distortion_intensity` ; photosensibilité : `min(…, cap)` ; 0 à 0 %.
- Jeu (`main.tscn`) : `set_value` à chaque palier -> après 0,5 s (30 ticks) les uniforms valent la cible ; au milieu, valeur intermédiaire (pas de saut) ; remontée -> décroissance ; nouvelle partie -> 0.
- Couches : `PostFx` existe, `z_index` entre le décor et 0 ; `Z_INDEX_DECOR < Z_INDEX_POSTFX < 0 < Z_INDEX_ENEMY_BULLETS` ; les `Enemy`, le joueur, le manager ennemi n'ont pas de matériau de shader ; le HUD est dans un `CanvasLayer`.
- Passe-bas : un seul `AudioEffectLowPassFilter` sur `Music` après trois parties ; `cutoff_hz` décroît avec le palier et remonte ; la boucle de la musique a `loop_mode` actif.
- `Settings` : valeurs hors bornes, `NaN`, mauvais type -> défauts ; sauvegarde et relecture ; menu reflète l'état.
- Tremblement : Éveil décale la caméra de 1 à 2 px entiers, retour exact à zéro après 9 ticks ; réglage 0 et photosensibilité -> aucun décalage ; deux runs de même seed -> mêmes décalages (flux `cosmetic`).
- Fenêtré WSLg : captures aux 5 paliers (rendu jugé hors scène).

## Fichiers prévus

`game/core/constants.gd`, `game/core/lucidity_tuning.gd`, `game/data/tuning/lucidity_tuning.tres`, `game/vfx/shaders/lucidity_distortion.gdshader`, `game/vfx/lucidity_fx.gd`, `game/autoloads/audio.gd`, `game/audio/music/music_placeholder.wav`, `game/autoloads/settings.gd`, `game/ui/menus/settings_menu.{gd,tscn}`, `game/localization/strings.csv`, `game/rooms/arena/arena.gd`, `game/.scratch/t_lucidity_fx.*`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Les distorsions suivent le palier en direct (pas `room_tier`)** — Raison : GDD « les signes de la lucidité à l'écran » ; seuls danger et loot lisent `room_tier`.
2. **Décor = sols et murs ; la copie déformée est un `ColorRect` à `z_index` -1 qui échantillonne l'écran** — Raison : la seule manière de ne déformer que le décor sans deuxième viewport ; décor repasse à -2.
3. **Boucle musicale provisoire de 8 s, générée par script, lancée par `Audio`** — Raison : l'AC demande une boucle provisoire ; à remplacer en 7.7.
4. **Photosensibilité prime sur les curseurs sans les modifier** — Raison : le joueur retrouve ses réglages en la désactivant.
5. **Le tremblement n'a qu'un consommateur : Éveil (1 à 2 px, 0,15 s)** — Raison : un réglage de tremblement sans consommateur serait invisible ; d'autres effets (coup, mort) pourront s'y brancher.
6. **Interpolation de 0,5 s, filtre en échelle logarithmique** — Raison : pas de saut brutal (lisibilité, photosensibilité).
7. **Valeurs par palier (ondulation 0, 0,5, 1, 1,5, 2 px ; aberration 0, 0,5, 1, 1,5, 2 px ; coupure 20 500, 8 000, 4 000, 2 000, 1 000 Hz)** — Raison : placeholders croissants ; à juger fenêtré (`NON ÉVALUÉ`).
8. **Les curseurs de réglages sont de 0 à 100 % par pas de 5** — Raison : même schéma que les volumes.

## Dev Agent Record

### Agent Model Used

### Completion Notes

### File List

# Story 4.6 : Explorer les grandes salles

Status: ready-for-dev

## Story

En tant que joueur,
je veux des salles de deux écrans où la caméra me suit,
afin de varier l'espace de combat.

Exigences : FR9 (caméra qui suit), FR35 (grandes salles), AR29 (caméra et bande de HUD) (epics.md, Story 4.6). Architecture : « Caméra » des compléments (salle d'un écran fixe, grande salle suivie et bornée, bande de HUD de 24 px), D13 (les couches du monde suivent la caméra).

**Dépend de : 4.2** (`Room`, `size_kind`, validateur, outil ASCII) ; 4.5 pour la grille de chemin (qui grandit sans changement). La 4.7 range une grande salle dans **un seul nœud** de la grille de l'étage ; la 4.8 place le joueur par les portes.

Hors périmètre : portes multiples par côté (une porte par côté, canonique), interpolation lissée de la caméra (position directe), carte détaillée des grandes salles (4.9 les dessine comme une salle).

## Critères d'acceptation

1. **Tailles** : `Room.SizeKind` : `SCREEN` (36×19 tuiles jouables), `WIDE` (72×19), `TALL` (36×38). `Room.playable_tiles()` = `Const.ROOM_TILES` × (2,1) ou (1,2) ; le cadre de murs ajoute une tuile de chaque côté. Les constantes se déduisent de `Const.ROOM_TILES` (rien de codé en dur). Les portes restent au milieu de chaque côté : en grande salle, N et S au milieu de la largeur, E et O au milieu de la hauteur.
2. **Caméra qui suit** : dans une salle `WIDE` ou `TALL`, la caméra se centre sur le joueur sur l'axe long, **bornée** : la vue ne montre jamais hors de la salle (murs compris) ; au-dessus du cadre elle montre au plus la bande de HUD (24 px) qui la recouvre. Sur l'axe court (cadre plus étroit que l'écran) la caméra reste centrée. Fonction pure `RoomCamera.target(player_pos, frame_px, viewport, band_px) -> Vector2`.
3. **Salle d'un écran** : caméra fixe, centrée, **exactement** comme aujourd'hui (position inchangée au pixel près : `frame/2 - (0, band/2)`).
4. **HUD fixe** : la bande de HUD reste en haut de l'écran (couche `UI`, déjà indépendante de la caméra) ; rien de la salle ne la déborde.
5. **Cohérence au changement de salle ou à l'apparition du joueur** : la caméra se place d'un coup sur la cible dès la première frame (`reset_physics_interpolation()`), jamais en glissant depuis l'ancienne salle.
6. **Tremblement et distorsion** : le tremblement d'Éveil (3.8) s'ajoute à la position suivie, et la caméra revient à la position suivie (pas à une position fixe d'origine) ; l'ondulation du décor (3.8) couvre tout le cadre de la grande salle.
7. **Tout ce qui lit la taille de salle** suit `playable_tiles()` : zone d'apparition, position d'apparition du joueur, grille de chemin (4.5), capacité du renfort (positions), validateur. Les apparitions et le renfort fonctionnent dans une salle de 72×19.
8. **Validateur** : accepte 72×19 et 36×38 (cadre compris : 74×21 et 38×40 cellules) pour `size_kind` `WIDE` et `TALL`, refuse toute autre combinaison (une salle `SCREEN` de 72×19, une `WIDE` de 36×19...).
9. **Salles de test** : `onset_combat_007` (WIDE, obstacles hauts en colonnes, 2 vagues) et `onset_combat_008` (TALL, un trou et un meuble, 2 vagues).

## Tâches

- [ ] `Room.SizeKind` complète, `playable_tiles()`, `frame_cells()`, `frame_px()` ; remplacer les usages restants de `Const.ROOM_TILES` hors de la vérification d'écran de `Arena`.
- [ ] `rooms/room_camera.gd` (`RefCounted`, fonctions statiques) ; `Room._physics_process` (priorité de physique 10, après le joueur) pose `_camera.position = RoomCamera.target(...) + shake_offset()` ; pas de `Camera2D.limit_*` (voir pièges).
- [ ] Adapter `_process_shake` : le retour « exact » est vers la position suivie du tick.
- [ ] Positions d'apparition par défaut du joueur (`player_spawn_position()` : centre du cadre, valable en grande salle).
- [ ] Validateur (dimensions par `size_kind`), outil ASCII (`size: wide|tall`, grille de la bonne taille).
- [ ] Tests GUT : `tests/unit/rooms/test_room_camera.gd` (bords, coins, axe court, salle d'un écran identique à l'ancienne position, vue incluse dans le cadre + bande pour 200 positions de joueur de la salle), `tests/integration/rooms/test_big_rooms.gd` (la caméra suit en déplaçant le joueur ; apparition d'ennemis et de renfort dans la zone de 72×19 ; tremblement puis retour à la position suivie ; validateur accepte/refuse).
- [ ] Capture WSLg d'une salle WIDE pour juger la lisibilité (NON VÉRIFIÉ par un humain).

## État du code concerné

- `Arena._ready` : caméra à `frame_px / 2 - (0, HUD_BAND_HEIGHT / 2)`, `process_callback = 0` (physique), `reset_physics_interpolation()` ; `shake()` décale la caméra d'entiers dans le flux `cosmetic` et revient « exactement à la position d'origine » (`_process_shake` ligne ~634) : c'est ce retour qui change.
- `Const.HUD_BAND_HEIGHT = 24`, `VIEWPORT = 640×360`, `ROOM_TILES = 36×19` ; cadre d'un écran = 38×21 tuiles = 608×336 px, bande + cadre = 360 px de haut : tient exactement. Largeur : marge de 32 px (bandes noires) hors cadre.
- `LucidityFx` (3.8) : `PostFx` = `ColorRect` de la taille du cadre, `z_index = Z_INDEX_POSTFX` ; shader sur `hint_screen_texture`. Les couches du décor sont à `Z_INDEX_DECOR` (-2).
- `Room._spawn_bounds()`, `player_spawn_position()`, `_check_screen_layout()` (uniquement pour une salle d'un écran).

## Pièges

- `Camera2D.limit_*` trop étroites pour la vue (cadre de 608 px de large < 640 px) donnent une caméra qui dérive ou se centre de façon surprenante ; d'où le calcul à la main, par axe.
- Cible de caméra : demi-vue = `viewport / 2`, avec le haut de la vue au plus à `-band_px` : sur l'axe vertical `y ∈ [-band + vh/2, frame_h - vh/2]` ; si l'intervalle est vide (cadre plus petit que la vue) la caméra est centrée.
- Priorité : la caméra doit lire la position **du tick** du joueur (priorité 0) : `process_physics_priority > 0`, sinon décalage d'un tick à haute vitesse (dash). L'interpolation physique 2D interpole aussi la caméra (`process_callback = 0`).
- Position de la caméra en entiers : arrondir (`roundi`) pour que le pixel-art ne papillote pas sous l'échelle entière ; la 3.8 raisonne déjà en pixels entiers pour le tremblement.
- `get_global_mouse_position()` suit la caméra : la visée à la souris reste juste ; ne pas utiliser la position écran.
- Un `ColorRect` du post-traitement dont la taille ne suit pas la salle laisse une zone non distordue : l'initialiser depuis `frame_px()`.
- Ne pas ajouter de nœud `Camera2D` supplémentaire : une seule caméra par salle, `make_current` implicite (une seule salle active, D14) ; la salle libérée emporte sa caméra.

## Fichiers prévus

`rooms/room.gd`, `rooms/room_camera.gd`, `rooms/room_base.tscn` (taille pilotée par les métadonnées), `rooms/validator/room_validator.gd`, `rooms/validator/room_builder.gd`, `rooms/pool/onset/onset_combat_00{7,8}.tscn`, `art_source/rooms/onset_combat_00{7,8}.txt`, `vfx/lucidity_fx.gd` (taille de couverture), `tests/**`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Dimensions en jouables : 72×19 et 36×38**, soit exactement deux écrans (l'epic dit « à ajuster selon la grille »). Une tuile jouable en moins par côté n'est pas nécessaire.
2. **Caméra posée par calcul pur, sans `limit_*`** ni lissage : lisible, testable, sans surprise sur l'axe court.
3. **Le joueur est suivi à la position du tick** (priorité 10) et la caméra n'a pas d'avance sur la visée : à juger au jeu (NON ÉVALUÉ).
4. **Une porte par côté, au milieu**, même en grande salle.
5. **La bande de HUD recouvre la zone au-dessus du cadre** : la vue peut montrer au plus 24 px hors du mur du haut, jamais plus.

## Dev Agent Record

### Agent Model Used

### Completion Notes

### File List

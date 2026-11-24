# Story 5.5 : Acheter à la boutique

Status: ready-for-dev

## Story

En tant que joueur,
je veux dépenser mes Éclats dans une boutique,
afin de transformer ma prise de risque en objets.

Exigences : FR58 (epics.md, Story 5.5). Architecture : flux `shop`, `economy/`, `EconomyTuning`.

**Dépend de : 5.1** (`Offer`, `Pickup`), **5.2** (`PickupSpot`, `ItemPicker`, pool boutique), **5.3** (consommables), **5.4** (`RunState.shards`, `EconomyTuning`, soin et armure ramassables).

Hors périmètre : variante « Être nu en public » (5.9), articles de l'acte 1.

## Critères d'acceptation

1. **Étal** : à la première entrée dans la boutique, `Run` tire dans le flux `shop` (clé `floor_index`) : 2 objets distincts du pool boutique (mêmes exclusions que 5.2 : possédés, Dent sans cœur de trop), 1 consommable du pool consommables, 1 cœur, 1 armure. Prix dans `EconomyTuning` : objet 15, consommable 5, cœur 4, armure 5. Les articles sont des `Offer` à `price > 0` posées sur les `PickupSpot` de la boutique (slots `ITEM` ×2, `CONSUMABLE`, `HEART`, `ARMOR`).
2. **Affichage** : chaque article montre son prix en Éclats (`Label` placé sous l'article, `UI_SHOP_PRICE`), les objets montrent aussi leur bonus et leur coût (la bannière 5.1 s'ouvre quand le joueur est devant, à moins de 2 tuiles, sans acheter ; l'achat est au contact).
3. **Achat** : toucher un article payant tente l'achat. Assez d'Éclats : `RunState.spend_shards(price)` puis l'article est obtenu (objet et consommable comme au ramassage ; cœur : `health.heal(2)` ; armure : `health.add_armor(2)`). `offer.taken = true`, le pickup et son prix disparaissent.
4. **Refus** : pas assez d'Éclats, ou cœur à PV pleins, ou armure impossible (plafond), ou objet non prenable (Dent à 1 cœur max) : `POWER_REFUSED_SOUND` (une fois, pas à chaque tick), rien n'est retiré, l'article reste. Un nouvel essai exige de sortir de la zone puis d'y revenir (même armement que 5.3). Le contrôle de faisabilité **précède** la dépense : jamais d'Éclats perdus sans effet.
5. **Persistance** : sortie et retour, ou seconde visite : les articles achetés ont disparu, les autres sont toujours là (même `RoomStock`) ; la boutique n'est tirée qu'une fois. Même seed et mêmes objets déjà pris : même étal.
6. **Validateur** : `RoomValidator` exige pour une boutique 5 `PickupSpot` (2 `ITEM`, 1 `CONSUMABLE`, 1 `HEART`, 1 `ARMOR`) sur le sol accessible, hors des 3 tuiles d'une porte, sans chevauchement ; `onset_shop_001` (provisoire, vide) les reçoit et reste valide.
7. **Données** : tous les prix dans `EconomyTuning` ; aucun nombre dans `shop.gd`.

## Tâches

- [ ] `EconomyTuning` : `item_price`, `consumable_price`, `heart_price`, `armor_price`, `heal_half_hearts` 2, `armor_half_hearts` 2 (le GDD parle de « 1 cœur » soigné et de « 1 cœur d'armure »).
- [ ] `economy/shop_stock.gd` (fonction statique `ShopStock.draw(pool_items, consumables, owned, health, rng, tuning) -> Array[Offer]`, pure et testable) ; un seul flux, ordre fixe : objet 1, objet 2, consommable.
- [ ] `Run._enter_cell` : première entrée en boutique, remplit le `RoomStock` ; `Room` pose les offres sur les spots du bon `slot`.
- [ ] `Pickup` : mode payant (`price`), `try_purchase(player)` appelé en différé, étiquette de prix, armement/refus.
- [ ] `RoomBuilder` / `RoomValidator` / `art_source/rooms/onset_shop_001.txt` / scène regénérée.
- [ ] `strings.csv` (`UI_SHOP_PRICE`), télémétrie : achats (id, prix).
- [ ] Tests.

## État du code concerné

- 5.1 : `Offer`, `RoomStock`, `Pickup` (collecte différée) ; 5.2 : `ItemPicker.draw`, `PickupSpot`, `PickupSpots`, validateur de trésor ; 5.3 : `ConsumableDef`, armement `_armed` ; 5.4 : `RunState.shards` et `spend_shards`, `Health.heal/add_armor` ramassables.
- `onset_shop_001` : provisoire, vide, quatre portes, type `SHOP` (`has_fight()` faux : portes ouvertes, salle « vidée » à l'entrée).
- `Hud` écoute `Events.shards_changed` (5.4).

## Pièges

- Un achat ne s'exécute **jamais** dans le callback `body_entered` : même collecte différée que 5.1.
- L'ordre Éclats / effet : vérifier d'abord `can_take`, puis `spend_shards`, puis appliquer ; si l'application échoue malgré tout (cas impossible), rendre les Éclats (`add_shards`) et `Log.error`.
- Le flux `shop` est consommé **dans un ordre fixe** quel que soit l'inventaire (comme 5.2) pour que la même seed donne le même étal avant et après un objet pris ailleurs.
- Deux objets distincts : tirer le second dans la liste privée du premier (retrait de l'index), pas par rejet répété (le nombre de tirages reste fixe).
- Les pickups payants ne doivent pas être « armés » à l'apparition (le joueur n'est pas dessus) mais le test d'armement doit rester valable si le joueur entre par la porte déjà sur un spot (spots hors des 3 tuiles d'une porte).
- Consommable de la boutique : même règle d'échange que 5.3 (l'ancien est déposé) ; l'achat n'est pas bloqué par un consommable déjà porté.

## Tests

- `unit/economy/test_shop_stock.gd` : 5 offres, 2 objets distincts, aucun possédé, prix, même seed = même étal, flux `treasure` intact.
- `integration/economy/test_shop_purchase.gd` : achat d'un objet (Éclats retirés, objet dans le `Loadout`), refus faute d'Éclats (son, rien retiré), cœur à PV pleins refusé, armure au plafond refusée, article acheté absent au retour, un essai par passage.
- `unit/rooms/test_room_validator_pickups.gd` (étendre) : boutique à 4 spots, ou avec un `HEART` manquant, refusée.

## Sources

epics.md (Story 5.5) ; GDD « Économie » (boutique : 2 objets à 15, 1 consommable à 5, 1 cœur à 4, 1 armure à 5), « Cible » d'Éclats par étage.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Achat au contact**, avec armement (style Isaac), plutôt qu'une touche d'interaction ; la bannière s'ouvre à moins de 2 tuiles pour lire avant d'acheter.
2. **Cœur acheté = 2 demi-cœurs, armure = 2 demi-cœurs d'armure** (« 1 cœur » du GDD).
3. **Pas de revente ni de réapprovisionnement** : l'étal est tiré une fois par boutique.
4. **Exclusion des objets déjà proposés au trésor non pris : non faite** ; seul le doublon avec le `Loadout` est exclu (comme 5.2).
5. **Consommable porté** : l'achat reste permis, l'ancien est déposé (cohérent avec 5.3).

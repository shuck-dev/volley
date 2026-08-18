# Shop

Zach's stall at the edge of the garden. The protagonist spends soul here on balls.

## What the player does

The stall shows a handful of balls at a time. Each carries a price in soul and the player buys one by taking it off the table. A restock button rerolls what is on offer: the first restock is free, and after that it costs a share of what is currently laid out, so clearing the table has a price.

A ball the player already owns leaves the table when they buy it. Buying a second copy of the same ball costs double each time.

## Where it sits in the fiction

Zach brings the stall over after the protagonist starts getting the hang of the rally, and fills it with things from his own home. See [Story](../story/INDEX.md).

## How it is built

`scripts/shop/shop.gd` holds the stall: it reads `ShopConfig` for the number of display slots and the restock multiplier, spawns a `ShopItem` per ball, and listens to `BallManager` for the soul balance and for purchases so a sold ball's tile leaves the table.

`scripts/shop/shop_item.gd` is the individual ball on the table.

Prices come from `BallManager.calculate_for_purchase`, which doubles the base cost for each copy already owned.

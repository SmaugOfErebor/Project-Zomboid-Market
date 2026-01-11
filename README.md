# Project Purpose
Yes. This project would be much more feasible if it was just a normal mod for Project Zomboid.

That isn't the purpose of this project.

The purpose of this project is to create an in-game market (buying and selling items between you and the server) without explicitly creating a mod, but most importantly, **without any client side files whatsoever**.

This project must always be able to function with purely vanilla clients.

This code is confirmed compatible with Project Zomboid version 42.13.1.

# Server Setup
1. Paste the start-server-wrapper.sh file into your server's base directory (the directory with the start-server.sh file).
2. Paste the market.lua and prices.lua files into your server's <base_directory>/media/lua/server/ directory.
    - The server automatically runs all lua files in this directory, so we just hijack the server by dropping our files.
3. Start your server using ./start-server-wrapper.sh instead of using ./start-server.sh

# In Game Use
All actions below will execute every 1 in game minute.

To sell an item:
- Put the items you want to sell inside a container (such as a backpack).
- Put that container (the backpack) inside another container (such as a duffel bag).
- Equip the outer container (the duffel bag) in your primary hand slot.
- If an item is not in the prices.lua dictionary, the item will not sell.

To buy an item:
- Put one and only one of the item you want to buy inside a container (such as a backpack).
- Put that container (the backpack) inside another container (such as a duffel bag).
- Equipm the outer container (the duffel bag) in your secondary hand slot.
- You must already have one of an item to purchase another of that item. This is currently necessary, but also prevents the market system from ruining the experience of having to scavenge for items in the game.
- The presence of any other item in the inner container will prevent this from working. This also prevents accidental purchasing of many duplicates.
- If the item is not in the prices.lua dictionary, the item will not buy.
# Project Purpose
Yes. This project would be much more feasible if it was just a normal mod for Project Zomboid.

No. That isn't the purpose of this project.

The purpose of this project is to create an in-game market (buying and selling items between you and the server) without explicitly creating a mod, but most importantly, **without any client side files whatsoever**.

This project must always be able to function with purely vanilla clients.
# Server Setup
Paste the start-server-wrapper.sh file into your server's base directory (the directory with the start-server.sh file).
Paste the market.lua and prices.lua files into your server's <base_directory>/media/lua/server/ directory.
Start your server using ./start-server-wrapper.sh instead of using ./start-server.sh
# In Game Use
To check your balance:
- Put only and exactly 5 rags and 5 dirty rags in your backpack.
- The presence of any other item in the backpack will prevent this from working.
- The backpack must be worn on your back.
- The server will tell you your balance the next time the in game clock advances 10 minutes.

To sell an item:
- Put only and exactly 6 rags, 5 dirty rags, and the item you want to sell in your backpack.
- Currently, you can only sell a single item at a time. Even stackable items.
- The presence of any other item in the backpack will prevent this from working.
- The backpack must be worn on your back.
- The item will sell the next time the in game clock advances 10 minutes.
- If the item is not in the prices.lua dictionary, the item will not sell.

To buy an item:
- Put only and exactly 5 rags, 6 dirty rags, and the item you want to buy in your backpack.
- You must already have one of an item to purchase another of that item. This is currently necessary, but also prevents the market system from ruining the experience of having to scavenge for items in the game.
- The presence of any other item in the backpack will prevent this from working.
- The backpack must be worn on your back.
- The item will buy the next time the in game clock advances 10 minutes.
- If the item is not in the prices.lua dictionary, the item will not buy.
# Project Purpose
Yes. This project would be much more feasible if it was just a normal mod for Project Zomboid.

No. That isn't the purpose of this project.

The purpose of this project is to create an in-game market (buying and selling items between you and the server) without explicitly creating a mod, but most importantly, **without any client side files whatsoever**.

This project must always be able to function with purely vanilla clients.

This code is confirmed compatible with Project Zomboid version 42.13.1.

# Server Setup
1. Paste the start-server-wrapper.sh file into your server's base directory (the directory with the start-server.sh file).
2. Paste the market.lua and prices.lua files into your server's <base_directory>/media/lua/server/ directory.
    - The server automatically runs all lua files in this directory, so we just hijack the server by dropping our files.
3. Start your server using ./start-server-wrapper.sh instead of using ./start-server.sh

# In Game Use
All actions below will execute every 10 in game minutes.

To check your balance:
- Put only and exactly 5 rags and 5 dirty rags in your backpack.
- The presence of any other item in the backpack will prevent this from working.
- The backpack must be worn on your back.

To sell an item:
- Put only and exactly 6 rags, 5 dirty rags, and the items you want to sell in your backpack.
- The backpack must be worn on your back.
- If an item is not in the prices.lua dictionary, the item will not sell.

To buy an item:
- Put only and exactly 5 rags, 6 dirty rags, and the item you want to buy in your backpack.
- You must already have one of an item to purchase another of that item. This is currently necessary, but also prevents the market system from ruining the experience of having to scavenge for items in the game.
- The presence of any other item in the backpack will prevent this from working.
- The backpack must be worn on your back.
- If the item is not in the prices.lua dictionary, the item will not buy.

# Known Limitations
- I haven't yet found a way to capture arbitrary data on the server that the player has entered into their client in a vanilla fashion.
  - Because of this, I use specific rag and dirty rag counts on the backpack to indicate the player's intent to the server.
  - I've tried capturing chats and capturing text from written notes with no success so far.
  - Some method of capturing arbitrary data form the client would make this whole project a lot simpler.
  - Contact me if you have ideas.
  - Potential idea: ItemContainer.getCustomName() : See line 772 here: https://github.com/PZ-Umbrella/Umbrella/blob/17381967473cc2b40a7878f3c8aebe68210b63e6/library/java/zombie/inventory/ItemContainer.lua#L772
    - Nope. Calling this method on the backpack throws an exception.
  - Potential idea: Try to get arbitrary info from getModData() on the backpack.
    - Nope. getModData() returns an empty dictionary.
- Because rags and dirty rags are used to indicate your intentions to the server, you cannot buy or sell these items.
  - These items are very common, so they would be great items to be able to sell.
  - I have ideas on how to fix this.
- All server communications are sent to all players.
  - This could be moderately annoying for small servers and extremely annoying for large servers.
  - I don't have any ideas yet on how to fix this.
  - Contact me if you have ideas.
- When items are sold from your backpack, your client UI will not necessarily update and it will appear that the items have not sold.
  - I have never seen the UI update automatically before.
  - Unequipping the backpack will cause the UI to update.
  - Adding and removing a "ghost item" does not cause the client UI to update.
  - I don't have any ideas yet on how to fix this.
  - Contact me if you have ideas.
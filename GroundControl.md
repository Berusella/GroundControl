CRITICAL:
- ALWAYS PUSH TO GIT AFTER EVERY CHANGE
- USE GODOT 4.6
- USE C#
- BEFORE ADDING NEW FOLDER AND CHANGING STRUCTURE OF THE PROJECT ASK THE USER
- FOLLOW MichałBerus164174.png structure idea
- THE GAME IS ROGUELIKE BASED ON THE BINDING OF ISAAC
END CRITICAL

1. This is 2D game.

PLAYER STATS
HP - max 10. every projectile deals 1 hp to player.
SPEED - max 2.
POWER - thats how much damage the player will deal with every projectile
FIRE RATE - max 10. thats how often in a second will the user shoot

ENEMIES STATS
HP - no max.
SPEED - max 2.
POWER - no max - its not needed for the most part but PERFECT DISGUISE uses it for damage calculation
FIRE RATE - max 10, how often does enemy shoot.


MOVEMENTS
1. User movement is controlled with WASD
2. There are four basic enemy movements:
    - BRUTE - run to player
    - ESCAPE - run from player
    - stationary
    - Dash - each second, add speed to a charge counter, and dash when it reaches 10. Dash speed is based on speed stat
    - random
3. If enemy can not detect the user it defaults to random with speed penalty set to 50%

SPECIALS:
1. PEW PEW - shoots an projectile that deals 1.5x player damage - 3 room cooldown
2. BIG BOOM - causes explosion around the player that deals damage based on 2x player damage - 3 room cooldown
3. ASCEND - gives temporary flight for the whole room, gives to player 1 hp and 2 damage - 5 room cooldown
4. INVERT - changes all movement from BRUTE to ESCAPE and ESCAPE to BRUTE. after 10 seconds revert it back - 2 room cooldown
5. Mind control - swap one of the enemies movement to player movement for the entire room except for bosses where its only for 5 seconds - 5 room cooldown
6. time stop - stop everything including the player. Allow no one to shoot except the player. END after 10 seconds - 4 room cooldown
7. speed shot - for 1 sec set fire rate to 10 - 6 room cooldown
8. copy - changes player into one of the live enemies in the current room. Lasts until next use of the special or end of the floor - 3 room cooldown

PROJECTILE
1. projectile modifiers that user can have:
    - standard - no special effects just a projectile that shoots from the current character location and goes into one of the cardinal directions
    - diagonal - unlocks shooting in every direction
    - above - user selects the place in the room that a projectile will fall after a time specified in FIRE RATE
    - bounce - the projectile will bounce up to 3 times from the enemy.
    - laser - projectile will have a cooldown set in fire rate and after a time shoot a beam that deals continuous damage for 1 second
    - double - makes player shoot 2 projectiles with each shot
    - homing - projectile will home to the nearest enemy in short radius. It has to not turn instantaneously to balance this out
2. Combos:
    - above and laser will make the projectile shoot 8 short beams in all cardinal directions after impact
    - laser + homing will turn homing instantaneous in short radius. Look up Isaac Brimstone for reference for this


ITEMS
1. every item is to be in JSON file with its id as identifier.
2. the game is to scan the whole JSON at the start of the game for the items
3. If there is missing id number from the first item to last item, set the missing id to item with id number 0
4. every entry has:
    - rarity - its not in the png but its needed to lower spawn rate of amazing items. There are four rarities from 1 to 4. 4 is the most rare and 1 common
    - special it gives or null
    - Stats it gives or null
    - projectile modifier it gives - in png its wrongly labeled as second special
5. Designed items:
    - 0; Tactical supply - rarity 1; gives 1 hp, charges special, 1 key
    - 1; Live to see another day - rarity 3; gives 1 extra life;
    - 2; tactical nuke -rarity 4; gives BIG BOOM, 2 power, above projectile
    - 3; government propaganda - rarity 4; gives mind control, 2 hp
    - 4; its time to stop - rarity 3; gives time stop
    - 5; The carrier - rarity 4; gives ASCEND
    - 6; GRANADE - rarity 2; gives big boom
    - 7; Overcharge - rarity 3; gives speed shot, 0.2 speed
    - 8; steroids - rarity 3; gives 1 power, 0.2 speed
    - 9; PERFECT DISGUISE - rarity 3; gives copy
    - 10; Healing salve - rarity 1; gives 1 hp
    - 11; Sezam - rarity 1; gives 3 keys
    - 12; Brain rot - rarity 2; gives invert
    - 13; Training Camp - rarity 3; gives PEW PEW, 3 hp, 3 power, 0.4 speed, 2 fire rate
    - 14; Plasma gun - rarity 3; gives laser, diagonal projectile
    - 15; Gattling gun - rarity 4; gives speed shot special
    - 16; dual welding - rarity 4; sets projectile to double, -0.5 power, -0.5 fire rate
    - 17; Warship turret - rarity 2; gives diagonal projectile
    - 18; super reload guy - rarity 3; gives 3.5 fire rate
    - 19; ??Football?? - rarity 3; gives bounce
    - 20; government budget - rarity 2; gives 1.5 power
    - 21; THE SPOOON - rarity 1; gives 0.2 speed
    - 22; patched hull - rarity 2; gives 2 hp
    - 23; pain in the $$$ - rarity 2; gives 0.8 speed
    - 24; Know where it is - rarity 3; gives homing

BOSSES:
1. designed bosses:
    - THE TREE - stationary movement. sits in the middle in the room. every 10 seconds it will lock on the player and after 2 seconds swipe on the user in a cone shape. The space it will hit will light up red until attack is finished. Every 2 sec it will shoot from above a projectile. It has 200 hp
    - Military experiment - brute movement. will shoot every 2 seconds, has 350 hp. spawns a bruteling every 10 seconds.
    - Gorilla - swaps from BRUTE movement to ESCAPE every 5 seconds. When in BRUTE it gains 0.5 speed and swipes dealing damage in small cone shape after 1 sec of charging. When in ESCAPE it removes 0.5 speed and shoots every 2 seconds.
    - Vietnam horror - Dash movement, leaves burning patch every 0.5 second, speed 1, after hp reaches 40% change speed to 1.5, 180 hp

ENEMIES:
1. bruteling - brute movement, speed 0.9, 25 hp
2. soldier - escape movement, speed 0.6, shoot every 2 second if there is no obstacles on the way, 15 hp
3. super sniper - escape movement, speed 0.2, shoot every 3 second a homing projectile, 12 hp
4. boiling barrel - brute movement, speed 0.6 leaves burning patch every second. Flight prevents burning from dealing damage, 20 hp
5. small sapling - stationary, shoots every 1.5 second, 17 hp
6. growing tree - stationary, swipes in a small cone shape if player gets too close. charge time is 2 seconds, 30 hp
7. the buzzer - randomly switches between player movement and random from 1 second to 3 second interval, 0.6 speed, 10 hp
8. the tourist - random movement, speed 1.5, 3 hp


ROOM:
1. Floor contains 8-12 rooms connected in a grid pattern
2. Room types:
    - START - player spawns here, no enemies, center of floor
    - NORMAL - enemies spawn based on floor spawn table, doors lock until cleared
    - BOSS - single boss enemy, placed at furthest dead-end from start
    - ITEM - requires key to enter, contains one item pedestal, no enemies
    - SHOP - requires key to enter, contains 3 items for purchase, no enemies
3. Floor generation:
    - Random walk algorithm creates connected room positions from center
    - Boss room always at furthest dead-end from start
    - Item and Shop rooms placed at other dead-ends when available
4. Room clearing:
    - Doors lock when entering uncleared room with enemies
    - Doors unlock when all enemies defeated
    - Random chance to drop consumables (hearts, keys, special charges) on clear
5. Room storage:
    - Room layouts stored as .tscn scenes (visual editing in Godot)
    - Room metadata stored as .tres resources (enemy counts, type, difficulty)
    - Enemy spawn weights per floor stored as .tres resources
6. Each room template contains:
    - TileMap for floor and walls
    - Spawn point markers for enemies
    - Door position markers (North, South, East, West)
    - Obstacle nodes (rocks, pits)

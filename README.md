# TinkerTool
TinkerTool is a command line tool for use with TinkerLands.

# Features
* Get information on various items, mobs or other game elements from a database built from files included with the Tinkerlands Modding Tool.
* Backup player and world files, as well as configuration and language files.
* Extract, format and rename images from Tinkerlands Modding Tool sprites.
* Extract and rebuild world save files.
* Extract and rebuild player save files.

# Setup
1. Extract TinkerTool to a folder.
2. Download the Mod Tool and Database Images from https://tinkerlands.com/docs/#/README
3. Extract the Mod Tool to a folder.
4. Extract the sprites to the Mod Tool folder. Inside the Mod Tool folder you should now have a "db" folder and a "sprites" folder.
5. Run TinkerTool once (For now you can just click it and have it close but we'll explain how to use it on the command line later). This will create the tinkerlands.ini file.
6. Edit the tinkerlands.ini. Here we set up various options for the program.
7. Set "dbFolder" to the location of the "db" folder inside the Mod Tool's folder.
8. Set "spritesFolder" to the location of the "sprites" folder inside the Mod Tool's folder.
9. Run "CMD Prompt Here.cmd" found in TinkerTool's folder.
10. Now we build the database. This takes a long time but you only have to do it once. In the cmd prompt we opened type:
```
tinkertool -builddatabase
```

# Usage
See usage.txt for details.

## Examples
```
tinkertool -get item name "legendary blazon"
tinkertool -get item type map -list
tinkertool -get item all -saveimages -makeicon -list
tinkertool -backup
```


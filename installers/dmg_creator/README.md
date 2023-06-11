# To create dmg file run next command

1. build macos app with
   ```
   flutter build macos
   ```
2. navigate to directory containing `confing.json` file
   ```
   installers/dmg_creator/
   ```
3. create `dmg` file via
   ```
   appdmg ./config.json ./Storeman.dmg
   ```

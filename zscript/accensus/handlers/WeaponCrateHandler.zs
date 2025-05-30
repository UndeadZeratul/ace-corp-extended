class AceCorpsWeaponCrateHandler : EventHandler {

    // List of Inventory Classes to add to Weapon Crate Spawns
    Array< Class<HDWeapon> > weaponCrateWhitelist;

    // List of Inventory Classes to remove from Weapon Crate Spawns
    Array< Class<HDWeapon> > weaponCrateBlacklist;

    bool initialized;

    // Populates the blacklist.
    void init() {

        if (initialized) return;

        weaponCrateWhitelist.clear();
        weaponCrateBlacklist.clear();

        let cmdReader = HDCoreInfoReader(StaticEventHandler.find('HDCoreInfoReader'));
        
        loadWeaponCrateLists(cmdReader.commands);

        if (hd_debug) forEach(bl : weaponCrateBlacklist) console.printF(bl.getClassName());

        initialized = true;
    }

    void loadWeaponCrateLists(Array<HDCoreCommand> cmds) {
        forEach (cmd : cmds) {
            switch (cmd.command) {
                case 'addWeaponCrateSpawnPoolFilter': {
                    // FIXME: Find a better command/logic to handle existing CVARs

                    let weapon = cmd.getNameParam("name");
                    Class<HDWeapon> wpnCls = weapon;

                    if (!wpnCls) break;

                    // If the filter entry is allowed, remove from blacklist,
                    // Otherwise add to blacklist.
                    let index = weaponCrateBlacklist.find(wpnCls);
                    if (cmd.getBoolParam("allowed")) {
                        if (index < weaponCrateBlacklist.size()) weaponCrateBlacklist.delete(index);
                    } else {
                        if (index >= weaponCrateBlacklist.size()) weaponCrateBlacklist.push(wpnCls);
                    }

                    break;
                }
                case 'addWeaponCrateWhitelist': {
                    let weapon = cmd.getNameParam("name");
                    Class<HDWeapon> wpnCls = weapon;

                    if (!wpnCls) break;

                    if (weaponCrateWhitelist.find(wpnCls) >= weaponCrateWhitelist.size()) weaponCrateWhitelist.push(wpnCls);

                    break;
                }
                case 'removeWeaponCrateWhitelist': {
                    let weapon = cmd.getNameParam("name");
                    Class<HDWeapon> wpnCls = weapon;

                    if (!wpnCls) break;

                    let index = weaponCrateWhitelist.find(wpnCls);
                    if (index < weaponCrateWhitelist.size()) weaponCrateWhitelist.delete(index);

                    break;
                }
                case 'clearWeaponCrateWhitelist': {
                    weaponCrateWhitelist.clear();
                    break;
                }
                case 'addWeaponCrateBlacklist': {
                    let weapon = cmd.getNameParam("name");
                    Class<HDWeapon> wpnCls = weapon;

                    if (!wpnCls) break;

                    if (weaponCrateBlacklist.find(wpnCls) >= weaponCrateBlacklist.size()) weaponCrateBlacklist.push(wpnCls);

                    break;
                }
                case 'removeWeaponCrateBlacklist': {
                    let weapon = cmd.getNameParam("name");
                    Class<HDWeapon> wpnCls = weapon;

                    if (!wpnCls) break;

                    let index = weaponCrateBlacklist.find(wpnCls);
                    if (index < weaponCrateBlacklist.size()) weaponCrateBlacklist.delete(index);

                    break;
                }
                case 'clearWeaponCrateBlacklist': {
                    weaponCrateBlacklist.clear();
                    break;
                }
                default:
                    break;
            }
        }
    }

    override void worldThingSpawned(WorldEvent e) {

        // Populates the main arrays if they haven't been already.
        if (!initialized) init();

        // If the Weapon Crate Whitelist and Blacklist are both empty, quit.
        if (!weaponCrateWhitelist.size() && !weaponCrateBlacklist.size()) return;

        // Handle Weapon Crate Loot Table Filtering
        if (e.thing is 'HDWeaponCrate') handleWeaponCrateLootTable();
    }

    private void handleWeaponCrateLootTable() {
        
        // Find the WCSpawnPool Handler
		WCSpawnPool sp = WCSpawnPool(EventHandler.Find("WCSpawnPool"));

        // If we somehow don't find it, quit.
        if (!sp) return;

        // If the spawn pool hasn't been initialized yet, do so.
        // if (!sp.initialized) sp.BuildValidItemList();

        // Add all "whitelisted" entries
        foreach (wl : weaponCrateWhitelist) {
            if (hd_debug) console.printf("Adding "..wl.getClassName().." to Weapon Crate Spawn Pool");

            WCSpawnPool.AddItem(wl);
        }

        // Remove all "blacklisted" entries
        foreach (bl : weaponCrateBlacklist) {
            if (hd_debug) console.printf("Removing "..bl.getClassName().." from Weapon Crate Spawn Pool");

            WCSpawnPool.removeItem(bl);
        }
    }
}

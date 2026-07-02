class WCSpawnPool : HDCoreEventHandler {

    Array<name> whitelist;
    Array<name> blacklist;

    private Array<class <HDWeapon> > ValidWeapons;

    override void beforeProcessCommands() {
        whitelist.clear();
        blacklist.clear();

        ValidWeapons.clear();

        cmdWhitelist.push('configureWCSpawnPoolHandler');
        cmdWhitelist.push('addWeaponCrateFilter');
        cmdWhitelist.push('addWeaponCrateWhitelist');
        cmdWhitelist.push('removeWeaponCrateWhitelist');
        cmdWhitelist.push('clearWeaponCrateWhitelist');
        cmdWhitelist.push('addWeaponCrateBlacklist');
        cmdWhitelist.push('removeWeaponCrateBlacklist');
        cmdWhitelist.push('clearWeaponCrateBlacklist');
    }

    override void processCommand(HDCoreCommand cmd) {
        switch (cmd.command) {
            case 'configureWCSpawnPoolHandler':
                processConfigureWeaponCrateSpawnPoolHandlerCmd(cmd);
                break;
            case 'addWeaponCrateFilter':
                processAddWeaponCrateFilterCmd(cmd);
                break;
            case 'addWeaponCrateWhitelist':
                processAddWeaponCrateWhitelistCmd(cmd);
                break;
            case 'removeWeaponCrateWhitelist':
                processRemoveWeaponCrateWhitelistCmd(cmd);
                break;
            case 'clearWeaponCrateWhitelist':
                processClearWeaponCrateWhitelistCmd(cmd);
                break;
            case 'addWeaponCrateBlacklist':
                processAddWeaponCrateBlacklistCmd(cmd);
                break;
            case 'removeWeaponCrateBlacklist':
                processRemoveWeaponCrateBlacklistCmd(cmd);
                break;
            case 'clearWeaponCrateBlacklist':
                processClearWeaponCrateBlacklistCmd(cmd);
                break;
            default:
                break;
        }
    }

    void processConfigureWeaponCrateSpawnPoolHandlerCmd(HDCoreCommand cmd) {

        if (cmd.getBoolParam("clean")) {
            processClearWeaponCrateWhitelistCmd(cmd);
            processClearWeaponCrateBlacklistCmd(cmd);
        }

        Array<name> namesArr;

        // Add all configured Blacklist Entries
        cmd.getArrayNameParam("blacklist", namesArr);
        forEach (name : namesArr) addBlacklist(name);

        // Add all configured whitelist Entries
        cmd.getArrayNameParam("whitelist", namesArr);
        forEach (name : namesArr) addWhitelist(name);
    }

    void processAddWeaponCrateFilterCmd(HDCoreCommand cmd) {

        // FIXME: Find a better command/logic to handle existing CVARs

        // If the filter entry is allowed, remove from blacklist,
        // Otherwise add to blacklist.
        if (cmd.getBoolParam("allowed")) {
            processRemoveWeaponCrateBlacklistCmd(cmd);
        } else {
            processAddWeaponCrateBlacklistCmd(cmd);
        }
    }

    void processAddWeaponCrateWhitelistCmd(HDCoreCommand cmd) {
        
        addWhitelist(cmd.getNameParam("name"));
    }

    void processRemoveWeaponCrateWhitelistCmd(HDCoreCommand cmd) {
        
        removeWhitelist(cmd.getNameParam("name"));
    }

    void processClearWeaponCrateWhitelistCmd(HDCoreCommand cmd) {

        whitelist.clear();
    }

    void processAddWeaponCrateBlacklistCmd(HDCoreCommand cmd) {
        
        addBlacklist(cmd.getNameParam("name"));
    }

    void processRemoveWeaponCrateBlacklistCmd(HDCoreCommand cmd) {
        
        removeBlacklist(cmd.getNameParam("name"));
    }

    void processClearWeaponCrateBlacklistCmd(HDCoreCommand cmd) {

        blacklist.clear();
    }

    void addWhitelist(name name) {
        
        if (whitelist.find(name) >= whitelist.size()) whitelist.push(name);
    }

    void removeWhitelist(name name) {
        
        let index = whitelist.find(name);
        if (index < whitelist.size()) whitelist.delete(index);
    }

    void addBlacklist(name name) {

        if (blacklist.find(name) >= blacklist.size()) blacklist.push(name);
    }

    void RemoveBlacklist(name name) {
        
        let index = blacklist.find(name);
        if (index < blacklist.size()) blacklist.delete(index);
    }

    override void afterProcessCommands() {
        if (HDCore.ShouldLog('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG)) {

            let msg = "Configured Weapon Crate Whitelist:\n";

            forEach(wl : whitelist) msg = msg.." * "..wl.."\n";

            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, msg);


            msg = "Configured Weapon Crate Blacklist:\n";

            forEach(bl : blacklist) msg = msg.." * "..bl.."\n";

            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, msg);
        }
    }

    override void WorldLoaded(worldevent e) {
        super.WorldLoaded(e);

        BuildValidItemList();
    }

    private void BuildValidItemList() {
        if (ValidWeapons.Size() > 0) { return; } // don't rebuild
        Initialized = true;
        for (int i = 0; i < AllActorClasses.Size(); ++i) {
            let invitem = (class<HDWeapon>)(AllActorClasses[i]);
            if (!invitem) { continue; }
            AddItem(invitem);
        }
    }

    // Runs all normal checks and adds the passed item class to the spawn pool.
    //   Returns TRUE if the item class was successfully added.
    //   Returns FALSE if the item class could not be added.
    static bool AddItem(class<HDWeapon> cls) {
        WCSpawnPool sp = WCSpawnPool(EventHandler.Find("WCSpawnPool"));
        if (!(sp && sp.Initialized)) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_ERROR, "AddItem(): Weapon Crate spawn pool not found or initialized!");

            return false;
        }

        if (cls.isAbstract()) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "AddItem(): "..cls.GetClassName().." is abstract");

            return false;
        }

        if (CheckItem(cls) != -1) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "AddItem(): "..cls.GetClassName().." already in weapon crate spawn pool");

            return false;
        }

        forEach (bl : sp.blacklist) if (cls is bl) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "AddItem(): "..cls.GetClassName().." blacklisted");

            return false;
        }

        let whitelisted = false;
        forEach (wl : sp.whitelist) if (cls is wl) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "AddItem(): "..cls.GetClassName().." whitelisted");

            whitelisted = true;
            break;
        }

        if (sp.whitelist.size() && !whitelisted) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "AddItem(): "..cls.GetClassName().." whitelist exists, not whitelisted");

            return false;
        }

        let CurrWeapon = HDWeapon(GetDefaultByType(cls));
        if (
            !sp.whitelist.size()
            && !(
                cls
                && !CurrWeapon.bWIMPY_WEAPON
                && !CurrWeapon.bCHEATNOTWEAPON
                && !CurrWeapon.bDONTNULL
                && CurrWeapon.WeaponBulk() > 0
                && !CurrWeapon.bINVBAR
                && CurrWeapon.Refid != ""
            )
        ) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "AddItem(): "..cls.GetClassName().." not a valid HDWeapon");

            return false;
        }

        // All checks passed
        sp.ValidWeapons.Push(cls);

        HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_INFO, "AddItem(): added "..cls.GetClassName().." to weapon crate spawn pool");

        return true;
    }

    // Removes an item class from the spawn pool if it exists.
    //   Returns TRUE if the item class was successfully removed.
    //   Returns FALSE if for some reason the removal failed.
    static bool RemoveItem(class<HDWeapon> cls) {
        WCSpawnPool sp = WCSpawnPool(EventHandler.Find("WCSpawnPool"));
        if (!(sp && sp.Initialized)) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_ERROR, "RemoveItem(): Weapon Crate spawn pool not found or initialized!");
            
            return false;
        }

        int index = CheckItem(cls);
        if (index != -1) {
            sp.ValidWeapons.Delete(index);
            
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "RemoveItem(): removed "..cls.GetClassName().." from weapon crate spawn pool");

            return true;
        }

        return false;
    }

    // Checks if an item class already exists in the spawn pool
    //   Returns ARRAY INDEX if the item class is found in the spawn pool
    //   Returns -1 if the item class is not found in the spawn pool
    static int CheckItem(class<HDWeapon> cls) {
        WCSpawnPool sp = WCSpawnPool(EventHandler.Find("WCSpawnPool"));
        if (!(sp && sp.Initialized)) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_ERROR, "CheckItem(): Weapon Crate spawn pool not found or initialized!");
            
            return false;
        }

        for (int i=0; i<sp.ValidWeapons.Size(); i++) if (sp.ValidWeapons[i] is cls) return i;

        return -1;
    }

    // Returns a random valid item class from the weapon crate spawn pool.
    static class<HDWeapon> GetValidItem() {
        WCSpawnPool sp = WCSpawnPool(EventHandler.Find("WCSpawnPool"));
        if (!(sp && sp.Initialized)) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_ERROR, "GetValidItem(): Weapon Crate spawn pool not found or initialized!");
            
            return null;
        }

        if (sp.ValidWeapons.Size() <= 0) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_WARN, "GetValidItem(): Weapon Crate spawn pool empty!");
            
            return null;
        }

        return sp.ValidWeapons[random(0, sp.ValidWeapons.Size() - 1)];
    }
}
package com.sickworm.dim.dim_sdk_flutter;

import java.util.Map;

import chat.dim.core.KeyCache;
import chat.dim.crypto.SymmetricKey;
import chat.dim.mkm.ID;

/**
 *  For reusable symmetric key, with direction (from, to)
 */
public class KeyStore extends KeyCache {
    private static final KeyStore ourInstance = new KeyStore();
    public static KeyStore getInstance() { return ourInstance; }

    private KeyStore() {
        super();
    }

    @Override
    public boolean saveKeys(Map keyMap) {
        // TODO: save symmetric keys into persistent storage
        return false;
    }

    @Override
    public Map loadKeys() {
        // TODO: load symmetric keys from persistent storage
        return null;
    }

    @Override
    public SymmetricKey reuseCipherKey(ID sender, ID receiver, SymmetricKey key) {
        return super.reuseCipherKey(sender, receiver, key);
    }
}
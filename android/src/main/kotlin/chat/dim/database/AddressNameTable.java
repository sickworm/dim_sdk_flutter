/* license: https://mit-license.org
 * ==============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2019 Albert Moky
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * ==============================================================================
 */
package chat.dim.database;

import java.io.IOException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import chat.dim.client.Facebook;
import chat.dim.mkm.ID;

class AddressNameTable extends ExternalStorage {

    private Map<String, ID> ansTable = loadRecords();

    // "/sdcard/chat.dim.sechat/dim/ans.txt"

    private static String getAnsFilePath() {
        return root + "/dim/ans.txt";
    }

    private boolean cacheRecord(String name, ID identifier) {
        if (name.length() == 0) {
            return false;
        }
        ansTable.put(name, identifier);
        return true;
    }

    private Map<String, ID> loadRecords() {
        Map<String, ID> dictionary = new HashMap<>();
        String path = getAnsFilePath();
        // loading ANS records
        String text;
        try {
            text = readText(path);
        } catch (IOException e) {
            e.printStackTrace();
            return dictionary;
        }
        if (text == null || text.length() == 0) {
            return dictionary;
        }
        Facebook facebook = Facebook.getInstance();
        ID moky = facebook.getID("moky@4DnqXWdTV8wuZgfqSCX9GjE2kNq7HJrUgQ");
        String[] lines = text.split("[\\r\\n]+");
        String[] pair;
        for (String record : lines) {
            pair = record.split("\\t");
            if (pair.length != 2) {
                // invalid record
                continue;
            }
            dictionary.put(pair[0], facebook.getID(pair[1]));
        }
        // Reserved names
        dictionary.put("all", ID.EVERYONE);
        dictionary.put(ID.EVERYONE.toString(), ID.EVERYONE);
        dictionary.put(ID.ANYONE.toString(), ID.ANYONE);
        dictionary.put("owner", ID.ANYONE);
        dictionary.put("founder", moky);
        return dictionary;
    }

    private boolean saveRecords(Map<String, ID> caches) {
        StringBuilder text = new StringBuilder();
        Set<String> allKeys = caches.keySet();
        ID identifier;
        for (String name : allKeys) {
            identifier = caches.get(name);
            assert identifier != null;
            text.append(name);
            text.append("\t");
            text.append(identifier.toString());
            text.append("\n");
        }
        // saving ANS records
        String path = getAnsFilePath();
        try {
            return writeText(text.toString(), path);
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     *  Save ANS record
     *
     * @param name - short name
     * @param identifier - user ID
     * @return true on success
     */
    boolean saveRecord(String name, ID identifier) {
        if (!cacheRecord(name, identifier)) {
            return false;
        }
        // save to local storage
        return saveRecords(ansTable);
    }

    /**
     *  Get ID by short name
     *
     * @param name - short name
     * @return user ID
     */
    ID record(String name) {
        return ansTable.get(name.toLowerCase());
    }

    /**
     *  Get all short names with this ID
     *
     * @param identifier - user ID
     * @return all short names pointing to this same ID
     */
    Set<String> names(String identifier) {
        Set<String> allKeys = ansTable.keySet();
        // all names
        if (identifier.equals("*")) {
            return allKeys;
        }
        Facebook facebook = Facebook.getInstance();
        ID target = facebook.getID(identifier);
        // get keys with the same value
        Set<String> keys = new HashSet<>();
        ID value;
        for (String key : allKeys) {
            value = ansTable.get(key);
            if (value != null && value.equals(target)) {
                keys.add(key);
            }
        }
        return keys;
    }
}

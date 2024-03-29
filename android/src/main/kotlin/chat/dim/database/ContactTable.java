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
import java.util.ArrayList;
import java.util.List;

import chat.dim.common.Facebook;
import chat.dim.mkm.ID;

class ContactTable extends ExternalStorage {

    private List<ID> contactList = null;
    private ID current = null;

    // "/sdcard/chat.dim.sechat/mkm/{address}/contacts.js"

    private static String getContactsFilePath(ID user) {
        return root + "/mkm/" + user.address + "/contacts.js";
    }

    @SuppressWarnings("unchecked")
    private List<ID> loadContacts(ID user) {
        assert user != current;
        // reading contacts file in the user's directory
        String path = getContactsFilePath(user);
        List<String> array;
        try {
            array = (List<String>) readJSON(path);
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
        if (array == null || array.size() == 0) {
            return null;
        }
        // add contacts
        Facebook facebook = Facebook.getInstance();
        List<ID> contacts = new ArrayList<>();
        ID contact;
        for (String item : array) {
            contact = facebook.getID(item);
            assert contact.isValid();
            if (contacts.contains(contact)) {
                continue;
            }
            contacts.add(contact);
        }
        // TODO: sort it
        return contacts;
    }

    private boolean saveContacts(ID user) {
        if (contactList == null) {
            throw new NullPointerException("contacts cannot be empty: " + user);
        }
        String path = getContactsFilePath(user);
        try {
            return writeJSON(contactList, path);
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }

    List<ID> getContacts(ID user) {
        assert user != null;
        if (user != current) {
            // user switched, clear contacts
            contactList = null;
        }
        if (contactList == null) {
            contactList = loadContacts(user);
            if (contactList == null) {
                // no need to load again
                contactList = new ArrayList<>();
            }
        }
        current = user;
        return contactList;
    }

    private void sortContacts(List<ID> contacts) {
        // TODO: sort contact list
    }

    boolean addContact(ID contact, ID user) {
        List<ID> contacts = getContacts(user);
        if (contacts.contains(contact)) {
            return false;
        }
        contacts.add(contact);
        sortContacts(contacts);
        return saveContacts(user);
    }

    boolean removeContact(ID contact, ID user) {
        List<ID> contacts = getContacts(user);
        if (!contacts.contains(contact)) {
            return false;
        }
        contacts.remove(contact);
        sortContacts(contacts);
        return saveContacts(user);
    }

    boolean saveContacts(List<ID> contacts, ID user) {
        contactList = contacts;
        current = user;
        return saveContacts(user);
    }
}

package com.sickworm.dim.dim_sdk_flutter;

import java.util.List;
import java.util.Set;

import chat.dim.crypto.PrivateKey;
import chat.dim.mkm.GroupDataSource;
import chat.dim.mkm.ID;
import chat.dim.mkm.LocalUser;
import chat.dim.mkm.Meta;
import chat.dim.mkm.Profile;
import chat.dim.mkm.UserDataSource;

public interface SocialNetworkDataSource extends UserDataSource, GroupDataSource {

    boolean savePrivateKey(PrivateKey privateKey, ID identifier);

    //-------- Meta

    boolean saveMeta(Meta meta, ID identifier);

    //-------- Profile

    boolean verifyProfile(Profile profile);

    boolean saveProfile(Profile profile);

    //-------- Address Name Service

    boolean saveAnsRecord(String name, ID identifier);

    ID ansRecord(String name);

    Set<String> ansNames(String identifier);

    //-------- User

    LocalUser getCurrentUser();

    void setCurrentUser(LocalUser user);

    List<ID> allUsers();

    boolean addUser(ID user);

    boolean removeUser(ID user);

    boolean addContact(ID contact, ID user);

    boolean removeContact(ID contact, ID user);

    //-------- Group

    boolean existsMember(ID member, ID group);
}
package chat.dim.sechat.contacts.dummy;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import chat.dim.client.Facebook;
import chat.dim.database.SocialNetworkDatabase;
import chat.dim.mkm.User;
import chat.dim.mkm.LocalUser;
import chat.dim.mkm.ID;

/**
 * Helper class for providing sample content for user interfaces created by
 * Android template wizards.
 * <p>
 * TODO: Replace all uses of this class before publishing your app.
 */
public class DummyContent {

    static Facebook facebook = Facebook.getInstance();
    static SocialNetworkDatabase userDB = SocialNetworkDatabase.getInstance();

    /**
     * An array of sample (dummy) items.
     */
    public static final List<DummyItem> ITEMS = new ArrayList<DummyItem>();

    /**
     * A map of sample (dummy) items, by ID.
     */
    public static final Map<Object, DummyItem> ITEM_MAP = new HashMap<>();

    static {
        reloadData();
    }

    public static void reloadData() {
        ITEMS.clear();

        LocalUser user = userDB.getCurrentUser();
        ID uid = user == null ? null : user.identifier;
        List<ID> contacts = facebook.getContacts(uid);
        for (ID identifier : contacts) {
            addItem(new DummyItem(identifier));
        }
    }

    private static void addItem(DummyItem item) {
        ITEMS.add(item);
        ITEM_MAP.put(item.getIdentifier(), item);
    }

    private static String makeDetails(int position) {
        StringBuilder builder = new StringBuilder();
        builder.append("Details about Item: ").append(position);
        for (int i = 0; i < position; i++) {
            builder.append("\nMore details information here.");
        }
        return builder.toString();
    }

    /**
     * A dummy item representing a piece of content.
     */
    public static class DummyItem {

        private final User account;

        public DummyItem(Object id) {
            account = Facebook.getInstance().getUser(ID.getInstance(id));
        }

        public ID getIdentifier() {
            return account.identifier;
        }

        public String getTitle() {
            return account.getName();
        }

        public String getDesc() {
            return account.identifier.toString();
        }
    }
}

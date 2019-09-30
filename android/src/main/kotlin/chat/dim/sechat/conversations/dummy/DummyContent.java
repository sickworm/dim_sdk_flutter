package chat.dim.sechat.conversations.dummy;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import chat.dim.client.Amanuensis;
import chat.dim.client.Conversation;
import chat.dim.client.Facebook;
import chat.dim.mkm.ID;
import chat.dim.mkm.Profile;

/**
 * Helper class for providing sample content for user interfaces created by
 * Android template wizards.
 * <p>
 * TODO: Replace all uses of this class before publishing your app.
 */
public class DummyContent {

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

        Amanuensis clerk = Amanuensis.getInstance();
        int count = clerk.numberOfConversations();
        Conversation chatBox;
        for (int index = 0; index < count; index++) {
            chatBox = clerk.conversationAtIndex(index);
            addItem(new DummyItem(chatBox));
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

        private final Conversation chatBox;

        public DummyItem(Conversation chatBox) {
            this.chatBox = chatBox;
        }

        public ID getIdentifier() {
            return chatBox.identifier;
        }

        public String getTitle() {
            ID identifier = chatBox.identifier;
            Facebook facebook = Facebook.getInstance();
            Profile profile = facebook.getProfile(identifier);
            String nickname = profile == null ? null : profile.getName();
            String username = identifier.name;
            if (nickname != null) {
                if (username != null && identifier.getType().isUser()) {
                    return nickname + " (" + username + ")";
                }
                return nickname;
            } else if (username != null) {
                return username;
            } else {
                // BTC address
                return identifier.address.toString();
            }
        }

        public String getDesc() {
            // TODO: get last message
            return "last message";
        }
    }
}

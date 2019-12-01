package chat.dim.network;

import chat.dim.fsm.Machine;
import chat.dim.fsm.State;
import chat.dim.utils.Log;

public class ServerState extends State {

    public final String name;

    ServerState(String name) {
        super();
        this.name = name;
    }

    @Override
    protected void onEnter(Machine machine) {
        // do nothing
        Log.info("onEnter: " + name + " state");
    }

    @Override
    protected void onExit(Machine machine) {
    }

    @Override
    protected void onPause(Machine machine) {
    }

    @Override
    protected void onResume(Machine machine) {
    }
}

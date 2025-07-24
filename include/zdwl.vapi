[CCode (cheader_filename = "dwl-ipc-client-protocol.h,wayland-client.h")]
namespace zdwl {
    [CCode (has_target = false, has_typedef = false)]
	public delegate void IpcListenerFrame (void *data, Ipc ipc);
    [CCode (has_target = false, has_typedef = false)]
	public delegate void IpcListenerMonitorAdded (void *data, Ipc ipc, string address);
    [CCode (has_target = false, has_typedef = false)]
	public delegate void IpcListenerMonitorRemoved (void *data, Ipc ipc, string address);
    [CCode (has_target = false, has_typedef = false)]
	public delegate void IpcListenerClientOpened (void *data, Ipc ipc, string address);
    [CCode (has_target = false, has_typedef = false)]
	public delegate void IpcListenerClientClosed (void *data, Ipc ipc, string address);
    [CCode (has_target = false, has_typedef = false)]
	public delegate void IpcListenerClientTitleChanged (void *data, Ipc ipc, string address);
    [CCode (has_target = false, has_typedef = false)]
	public delegate void IpcListenerClientStateChanged (void *data, Ipc ipc, string address);

    [CCode (cname = "struct dwl_ipc_listener")]
    public struct IpcListener {
        public IpcListenerFrame frame;
        public IpcListenerMonitorAdded monitor_added;
        public IpcListenerMonitorRemoved monitor_removed;
        public IpcListenerClientOpened client_opened;
        public IpcListenerClientClosed client_closed;
        public IpcListenerClientTitleChanged client_title_changed;
        public IpcListenerClientStateChanged client_state_changed;
    }

    [Compact]
    [CCode (cname = "struct dwl_ipc", free_function = "dwl_ipc_destroy")]
    public class Ipc : Wl.Proxy {
        [CCode (cname = "(&dwl_ipc_interface)")]
        public static Wl.Interface interface;

        [CCode (cname = "dwl_ipc_add_listener")]
        public int add_listener (IpcListener listener, void* data);
        /*
        public void set_user_data (void* user_data);
        public void* get_user_data ();
        public uint32 get_version ();
        */
        public Command eval (string command);
    }

    [CCode (cname = "enum dwl_command_error", cprefix = "DWL_COMMAND_ERROR_")]
    public enum CommandError {
        SUCCESS,
        FAILURE
    }

    [CCode (has_target = false, has_typedef = false)]
	public delegate void CommandListenerDone (void *data, Command command, CommandError error, string message);

    [CCode (cname = "struct dwl_command_listener")]
    public struct CommandListener {
        public CommandListenerDone done;
    }

    [Compact]
    [CCode (cname = "struct dwl_command", free_function = "dwl_command_destroy")]
    public class Command : Wl.Proxy {
        [CCode (cname = "dwl_command_interface")]
        public static Wl.Interface interface;

        public int add_listener (CommandListener listener, void* data);
    }
}

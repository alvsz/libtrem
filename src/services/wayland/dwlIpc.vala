namespace libTrem {
  internal static void global_add (void *data, Wl.Registry registry, uint32 name, string interface, uint32 version) {
    DwlIpc self = (DwlIpc)data;
    assert_nonnull (self);

    if (interface == zdwl.Ipc.interface.name) {
      self.ipc = (zdwl.Ipc)wl_registry_bind (registry,name,zdwl.Ipc.interface,version);
    }
  }

  internal static void global_remove (void *data, Wl.Registry registry, uint32 name) {
  }

  internal static void on_frame (void *data, zdwl.Ipc ipc) {
    DwlIpc self = (DwlIpc)data;
    return_if_fail (self != null);
    self.frame ();
  }

  internal static void on_monitor_added (void *data, zdwl.Ipc ipc, string address) {
    DwlIpc self = (DwlIpc)data;
    return_if_fail (self != null);
    self.monitor_added (address);
  }

  internal static void on_monitor_removed (void *data, zdwl.Ipc ipc, string address) {
    DwlIpc self = (DwlIpc)data;
    return_if_fail (self != null);
    self.monitor_removed (address);
  }

  internal static void on_client_opened (void *data, zdwl.Ipc ipc, string address) {
    DwlIpc self = (DwlIpc)data;
    return_if_fail (self != null);
    self.client_opened (address);
  }

  internal static void on_client_closed (void *data, zdwl.Ipc ipc, string address) {
    DwlIpc self = (DwlIpc)data;
    return_if_fail (self != null);
    self.client_closed (address);
  }

  internal static void on_client_title_changed (void *data, zdwl.Ipc ipc, string address) {
    DwlIpc self = (DwlIpc)data;
    return_if_fail (self != null);
    self.client_title_changed (address);
  }

  internal static void on_client_state_changed (void *data, zdwl.Ipc ipc, string address) {
    DwlIpc self = (DwlIpc)data;
    return_if_fail (self != null);
    self.client_state_changed (address);
  }

  internal static void on_command_done (void *data, zdwl.Command command, zdwl.CommandError error, string message) {
    DwlCommand self = (DwlCommand)data;
    return_if_fail (self != null);
    self.done (error, message);
  }

  public class DwlCommand : Object {
    internal unowned zdwl.Command command;
    public signal void done(uint error, string message);

    internal DwlCommand (zdwl.Command cmd) {
      this.command = cmd;
    }
  }

  public class DwlIpc : Object {
    private WlSource wl_source;
    private  unowned Wl.Display display;
    internal unowned zdwl.Ipc? ipc;

    private List<zdwl.Command> commands;

    public signal void frame();
    public signal void monitor_added(string address);
    public signal void monitor_removed(string address);
    public signal void client_opened(string address);
    public signal void client_closed(string address);
    public signal void client_title_changed(string address);
    public signal void client_state_changed(string address);

    private static zdwl.IpcListener dwl_listener;
    private static Wl.RegistryListener global_listener;
    private static zdwl.CommandListener dwl_command_listener;

    private static DwlIpc _instance;

    public DwlIpc() {
      Object();
    }

    construct {
      wl_source = new WlSource();
      assert_nonnull (wl_source);
      display = wl_source.display;

      var registry = display.get_registry ();

      wl_registry_add_listener (registry, ref global_listener, this);

      display.roundtrip ();
      assert_nonnull (ipc);

      ipc.add_listener (ref dwl_listener, this);

      display.roundtrip ();
    }

    static construct {
      global_listener = Wl.RegistryListener () ;
      dwl_listener = zdwl.IpcListener ();
      dwl_command_listener = zdwl.CommandListener ();

      global_listener.global = global_add;
      global_listener.global_remove = global_remove;

      dwl_listener.frame = on_frame;
      dwl_listener.monitor_added = on_monitor_added;
      dwl_listener.monitor_removed = on_monitor_removed;
      dwl_listener.client_opened = on_client_opened;
      dwl_listener.client_closed = on_client_closed;
      dwl_listener.client_title_changed = on_client_title_changed;
      dwl_listener.client_state_changed = on_client_state_changed;

      dwl_command_listener.done = on_command_done;
    }

    public static DwlIpc? get_default() {
      if (_instance == null)
        _instance = new DwlIpc();

      return _instance;
    }

    public DwlCommand run_command (string command) {
      commands.append (this.ipc.eval(command));
      var a = new DwlCommand (commands.last ().data);
      a.command.add_listener (ref dwl_command_listener, a);

      a.done.connect (() => {
        commands.remove (a.command);
      });

      return a;
    }
  }

}


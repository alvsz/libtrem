namespace libTrem {
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
    public signal void monitor_layout_changed(string address);
    public signal void client_opened(string address);
    public signal void client_closed(string address);
    public signal void client_title_changed(string address);
    public signal void client_state_changed(string address);

    private static zdwl.IpcListener dwl_listener;
    private static Wl.RegistryListener global_listener;
    private static zdwl.CommandListener dwl_command_listener;

    private static DwlIpc _instance;

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

    internal static void on_monitor_layout_changed (void *data, zdwl.Ipc ipc, string address) {
      DwlIpc self = (DwlIpc)data;
      return_if_fail (self != null);
      self.monitor_layout_changed (address);
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
      dwl_listener.monitor_layout_changed = on_monitor_layout_changed;
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

  public class DwlMonitor : Object {
    public string address { get; private set; }

    public signal void layout_changed();

    internal DwlMonitor (string address) {
      this.address = address;
    }
  }

  public class DwlClient : Object {
    public string address { get; private set; }

    public signal void title_changed();
    public signal void state_changed();

    internal DwlClient (string address) {
      this.address = address;
    }
  }

  public class Dwl : Object {
    public DwlIpc ipc { get; private set; }
    private HashTable<string, DwlMonitor> _monitors = new HashTable<string, DwlMonitor> (str_hash, str_equal);
    private HashTable<string, DwlClient> _clients = new HashTable<string, DwlClient> (str_hash, str_equal);

    public List<weak DwlMonitor> monitors { owned get { return _monitors.get_values (); } }
    public List<weak DwlClient> clients { owned get { return _clients.get_values (); } }

    construct {
      ipc = new DwlIpc ();

      ipc.monitor_added.connect (on_monitor_added);
      ipc.monitor_removed.connect (on_monitor_removed);
      ipc.monitor_layout_changed.connect (on_monitor_layout_changed);
      ipc.client_opened.connect (on_client_opened);
      ipc.client_closed.connect (on_client_closed);
      ipc.client_title_changed.connect (on_client_title_changed);
      ipc.client_state_changed.connect (on_client_state_changed);
    }

    private void on_monitor_added (DwlIpc source, string address) {
      printerr ("monitor added: %s", address);
      _monitors.insert (address, new DwlMonitor (address));
    }

    private void on_monitor_removed (DwlIpc source, string address) {
      printerr ("monitor removed: %s", address);
      _monitors.remove (address);
    }

    private void on_monitor_layout_changed (DwlIpc source, string address) {
      printerr ("monitor layout: %s", address);
      var m = _monitors.get (address);

      if (m == null)
        on_monitor_added (source, address);

      m.layout_changed ();
    }

    private void on_client_opened (DwlIpc source, string address) {
      printerr ("client opened: %s", address);
      _clients.insert (address, new DwlClient (address));
    }

    private void on_client_closed (DwlIpc source, string address) {
      printerr ("client closed: %s", address);
      _clients.remove (address);
    }

    private void on_client_title_changed (DwlIpc source, string address) {
      printerr ("client title: %s", address);
      var c = _clients.get (address);

      if (c == null)
        on_client_opened (source, address);

      c.title_changed ();
    }

    private void on_client_state_changed (DwlIpc source, string address) {
      printerr ("client state: %s", address);
      var c = _clients.get (address);

      if (c == null)
        on_client_opened (source, address);

      c.state_changed ();
    }
  }
}


namespace libTrem {
  public class DwlCommand : Object {
    internal unowned zdwl.Command command;
    public signal void done(uint error, string message);

    internal DwlCommand (zdwl.Command cmd) {
      this.command = cmd;
    }
  }

  public class DwlIpc : Object {
    internal WlSource wl_source;
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
      display = (Wl.Display)wl_source.display;

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
    private Json.Object obj;
    private unowned Dwl dwl_ipc;
    public string address { get; private set; }

    public string layout { get { return obj.get_string_member ("layout"); } }
    public bool focused { get { return obj.get_boolean_member ("focused"); } }
    public int64 seltags { get { return obj.get_int_member ("seltags"); } }
    public string name { get { return obj.get_string_member ("name"); } }

    public signal void layout_changed();

    internal DwlMonitor (string address, Dwl ipc) {
      this.address = address;
      this.dwl_ipc = ipc;

      ipc.ipc.frame.connect (update);
      update();
    }

    private void update () {
      dwl_ipc.ipc.run_command ("return dwl.get_monitor(%s):serialize()".printf (address)).done.connect ((err, result) => {
        if (err != 0) {
          warning ("serialize error: %s", result);
          return;
        }

        var parser = new Json.Parser();

        try {
          return_if_fail (parser.load_from_data (result));
        } catch (Error e) {
          warning ("parser error: %s", e.message);
        }

        var root = parser.get_root ();
        return_if_fail (root != null);

        var obj = root.get_object ();
        return_if_fail (obj != null);

        this.obj = obj;
        dwl_ipc.frame ();
      });
    }
  }

  public class DwlClient : Object {
    private unowned Dwl dwl_ipc;
    public Json.Object obj { get; private set; }
    public string address { get; private set; }

    public string title { get { return obj.get_string_member ("title"); } }
    public string app_id { get { return obj.get_string_member ("app_id"); } }
    public bool focused { get { return obj.get_boolean_member ("focused"); } }
    public int64 tags { get { return obj.get_int_member ("tags"); } }
    public string monitor { owned get { return obj.get_int_member ("monitor").to_string (); } }

    public signal void title_changed();
    public signal void state_changed();

    internal DwlClient (string address, Dwl ipc) {
      this.address = address;
      this.dwl_ipc = ipc;

      ipc.ipc.frame.connect (update);
      update();
    }

    private void update () {
      dwl_ipc.ipc.run_command ("return dwl.get_client(%s):serialize()".printf (address)).done.connect ((err, result) => {
        if (err != 0) {
          warning ("serialize error: %s", result);
          return;
        }

        var parser = new Json.Parser();

        try {
          return_if_fail (parser.load_from_data (result));
        } catch (Error e) {
          warning ("parser error: %s", e.message);
        }

        var root = parser.get_root ();
        return_if_fail (root != null);

        var obj = root.get_object ();
        return_if_fail (obj != null);

        this.obj = obj;
        dwl_ipc.frame ();
      });
    }
  }

  public class Dwl : Object {
    internal DwlIpc ipc;
    private HashTable<string, DwlMonitor> _monitors = new HashTable<string, DwlMonitor> (str_hash, str_equal);
    private HashTable<string, DwlClient> _clients = new HashTable<string, DwlClient> (str_hash, str_equal);

    public List<weak DwlMonitor> monitors { owned get { return _monitors.get_values (); } }
    public List<weak DwlClient> clients { owned get { return _clients.get_values (); } }

    public signal void frame();

    private static Dwl _instance;

    public DwlMonitor get_monitor (string address) throws Error {
      var c = _monitors.get (address);

      if (c == null)
        throw new IOError.NOT_FOUND ("monitor %s não encontrado".printf (address));

      return c;
    }

    public DwlClient get_client (string address) throws Error {
      var c = _clients.get (address);

      if (c == null)
        throw new IOError.NOT_FOUND ("client %s não encontrado".printf (address));

      return c;
    }

    construct {
      ipc = new DwlIpc ();

      ipc.monitor_added.connect (on_monitor_added);
      ipc.monitor_removed.connect (on_monitor_removed);
      ipc.monitor_layout_changed.connect (on_monitor_layout_changed);
      ipc.client_opened.connect (on_client_opened);
      ipc.client_closed.connect (on_client_closed);
      ipc.client_title_changed.connect (on_client_title_changed);
      ipc.client_state_changed.connect (on_client_state_changed);

      get_all_monitors ();
    }

    public static Dwl? get_default() {
      if (_instance == null)
        _instance = new Dwl();

      return _instance;
    }

    private void get_all_clients (string mon) {
      string cmd = "local list = {}\n"
        + "local mon = dwl.get_monitor(%s)\n".printf (mon)
        + "for _,i in  ipairs(mon:get_clients()) do\n"
        + "table.insert(list, i.address)\n"
        + "end\n"
        + "return table.concat(list,' ')\n";

      ipc.run_command(cmd).done.connect ((e, m) => {
        if (e == 0) {
          var clients = m.split (" ");

          foreach (var client in clients) {
            on_client_opened.begin (ipc,client);
          }
        }
      });
    }

    private void get_all_monitors () {
      string cmd = "local list = {}\n"
        + "local mons = dwl.get_monitors()\n"
        + "for _,i in  ipairs(mons) do\n"
        + "table.insert(list, i.address)\n"
        + "end\n"
        + "return table.concat(list,' ')\n";


      ipc.run_command(cmd).done.connect ((e, m) => {
        if (e == 0) {
          var mons = m.split (" ");

          foreach (var mon in mons) {
            on_monitor_added.begin (ipc, mon);
            get_all_clients (mon);
          }
        }
      });
    }

    private async void on_monitor_added (DwlIpc source, string address) {
      _monitors.insert (address, new DwlMonitor (address, this));
    }

    private void on_monitor_removed (DwlIpc source, string address) {
      _monitors.remove (address);
    }

    private void on_monitor_layout_changed (DwlIpc source, string address) {
      var m = _monitors.get (address);

      if (m == null)
        return;

      m.layout_changed ();
    }

    private async void on_client_opened (DwlIpc source, string address) {
      _clients.insert (address, new DwlClient (address, this));
    }

    private void on_client_closed (DwlIpc source, string address) {
      _clients.remove (address);
    }

    private void on_client_title_changed (DwlIpc source, string address) {
      var c = _clients.get (address);

      if (c == null)
        return;

      c.title_changed ();
    }

    private void on_client_state_changed (DwlIpc source, string address) {
      var c = _clients.get (address);

      if (c == null)
        return;

      c.state_changed ();
    }
  }
}


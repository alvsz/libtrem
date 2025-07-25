[CCode (cheader_filename="dwl-helper.h")]
namespace libTrem {
  [CCode (cname = "dwl_ipc_client_global_add")]
    internal static void global_add (void *data, Wl.Registry registry, uint32 name, string interface, uint32 version) {
      DwlIpc self = (DwlIpc)data;
      assert_nonnull (self);

      if (interface == zdwl.Ipc.interface.name) {
        printerr ("achou a interface!!!\n");
        self.ipc = (zdwl.Ipc)wl_registry_bind (registry,name,zdwl.Ipc.interface,version);
      }
    }

  [CCode (cname = "dwl_ipc_client_global_remove")]
    internal static void global_remove (void *data, Wl.Registry registry, uint32 name) {
      DwlIpc self = (DwlIpc)data;
      printerr ("protocolo sumiu: %u\n",  name);
    }

  [CCode (cname = "dwl_ipc_on_frame")]
    internal static void on_frame (void *data, zdwl.Ipc ipc) {
      DwlIpc self = (DwlIpc)data;
      assert_nonnull (self);
      printerr ("frame\n");

      self.frame ();
    }

  [CCode (cname = "dwl_ipc_on_monitor_added")]
    internal static void on_monitor_added (void *data, zdwl.Ipc ipc, string address) {
      DwlIpc self = (DwlIpc)data;
      assert_nonnull (self);
      printerr ("monitor_added: %s\n", address);
      self.monitor_added (address);
    }

  [CCode (cname = "dwl_ipc_on_monitor_removed")]
    internal static void on_monitor_removed (void *data, zdwl.Ipc ipc, string address) {
      DwlIpc self = (DwlIpc)data;
      assert_nonnull (self);
      printerr ("monitor_removed: %s\n", address);
      self.monitor_removed (address);
    }

  [CCode (cname = "dwl_ipc_on_client_opened")]
    internal static void on_client_opened (void *data, zdwl.Ipc ipc, string address) {
      DwlIpc self = (DwlIpc)data;
      assert_nonnull (self);
      printerr ("client_opened: %s\n", address);
      self.client_opened (address);
    }

  [CCode (cname = "dwl_ipc_on_client_closed")]
    internal static void on_client_closed (void *data, zdwl.Ipc ipc, string address) {
      DwlIpc self = (DwlIpc)data;
      assert_nonnull (self);
      printerr ("client_closed: %s\n", address);
      self.client_closed (address);
    }

  [CCode (cname = "dwl_ipc_on_client_title_changed")]
    internal static void on_client_title_changed (void *data, zdwl.Ipc ipc, string address) {
      DwlIpc self = (DwlIpc)data;
      assert_nonnull (self);
      printerr ("client_title_changed: %s\n", address);
      self.client_title_changed (address);
    }

  [CCode (cname = "dwl_ipc_on_client_state_changed")]
    internal static void on_client_state_changed (void *data, zdwl.Ipc ipc, string address) {
      DwlIpc self = (DwlIpc)data;
      assert_nonnull (self);
      printerr ("client_state_changed: %s\n", address);
      self.client_state_changed (address);
    }

  public class DwlCommand : Object {

  }

  public class DwlIpc : Object {
    private WlSource wl_source;
    private unowned Wl.Display display;
    public unowned zdwl.Ipc? ipc;

    public signal void frame();
    public signal void monitor_added(string address);
    public signal void monitor_removed(string address);
    public signal void client_opened(string address);
    public signal void client_closed(string address);
    public signal void client_title_changed(string address);
    public signal void client_state_changed(string address);

    private static zdwl.IpcListener dwl_listener;
    private static Wl.RegistryListener global_listener;

    private static DwlIpc _instance;


    public DwlIpc() throws Error {
      wl_source = new WlSource ();
      assert_nonnull (wl_source);
      display = wl_source.display;

      var registry = display.get_registry ();

      registry.add_listener (global_listener, this);

      display.roundtrip ();

      if (ipc == null)
        throw new IOError.FAILED ("failed to bind dwl_ipc interface");

      ipc.add_listener (dwl_listener, this);
      
      display.roundtrip ();

      for (var i = 0; i < 100; i++) {
        display.dispatch ();
      }
    }

    static construct {
      global_listener = new Wl.RegistryListener () {};
      dwl_listener = new zdwl.IpcListener () {};

      global_listener.global = global_add;
      global_listener.global_remove = global_remove;

      dwl_listener.frame = on_frame;
      dwl_listener.monitor_added = on_monitor_added;
      dwl_listener.monitor_removed = on_monitor_removed;
      dwl_listener.client_opened = on_client_opened;
      dwl_listener.client_closed = on_client_closed;
      dwl_listener.client_title_changed = on_client_title_changed;
      dwl_listener.client_state_changed = on_client_state_changed;
    }

    public static DwlIpc? get_default() {
      if (_instance == null) {
        try {
          _instance = new DwlIpc();
        } catch (Error e) {
          warning("Falha ao inicializar a biblioteca DwlIpc: %s", e.message);
        }
      }
      return _instance;
    }
  }

}


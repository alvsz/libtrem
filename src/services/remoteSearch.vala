namespace libTrem {
  public class ResultMeta : Object {
    public string id;
    public string name;
    public string description;
    public GLib.Icon? icon { get; private set; }
    public string clipboard_text;

    public ResultMeta(string id, string name, string description, Icon? icon, string clipboard_text) {
      this.id = id;
      this.name = name;
      this.description = description;
      this.icon = icon;
      this.clipboard_text = clipboard_text;
    }
  }

  [DBus(name = "org.gnome.Shell.SearchProvider")]
    internal interface IDBusSearchProvider : DBusProxy {
      public abstract async string[] get_initial_result_set(string[] terms) throws DBusError, IOError;
      public abstract async string[] get_subsearch_result_set(string[] previous_results, string[] terms) throws DBusError, IOError;

      public abstract async HashTable<string, Variant>[] get_result_metas(string[] ids) throws DBusError, IOError;
      public abstract async void activate_result(string id) throws DBusError, IOError;
    }

  [DBus(name = "org.gnome.Shell.SearchProvider2")]
    internal interface IDBusSearchProvider2 : DBusProxy {
      public abstract async string[] get_initial_result_set(string[] terms) throws DBusError, IOError;
      public abstract async string[] get_subsearch_result_set(string[] previous_results, string[] terms) throws DBusError, IOError;

      public abstract async HashTable<string, Variant>[] get_result_metas(string[] ids) throws DBusError, IOError;
      public abstract async void activate_result(string id, string[] terms, uint timestamp) throws DBusError, IOError;
      public abstract async void launch_search(string[] terms, uint timestamp) throws DBusError, IOError;
    }

  public interface SearchProviderBackend : Object {
    public abstract async string[] get_initial_result_set(string[] terms) throws Error;
    public abstract async HashTable<string, Variant>[] get_result_metas(string[] ids) throws Error;
    public abstract void activate_result(string id, string[] terms);
    public abstract void launch_search(string[] terms) throws Error;
  }

  public class DBusSearchProviderBackend : Object, SearchProviderBackend {
    private IDBusSearchProvider proxy;

    public DBusSearchProviderBackend(string bus_name, string object_path, bool autostart) throws Error {
      var flags = DBusProxyFlags.DO_NOT_LOAD_PROPERTIES;
      flags |= autostart ? DBusProxyFlags.DO_NOT_AUTO_START_AT_CONSTRUCTION : DBusProxyFlags.DO_NOT_AUTO_START;

      proxy = Bus.get_proxy_sync(BusType.SESSION, bus_name, object_path, flags);
      proxy.set_default_timeout(50);
    }

    public async string[] get_initial_result_set(string[] terms) throws Error {
      return yield proxy.get_initial_result_set(terms);
    }

    public async HashTable<string, Variant>[] get_result_metas(string[] ids) throws Error {
      return yield proxy.get_result_metas(ids);
    }

    public void activate_result(string id, string[] terms) {
      proxy.activate_result.begin(id);
    }

    public void launch_search(string[] terms) throws Error {
      throw new IOError.NOT_SUPPORTED("");
    }
  }

  public class DBusSearchProvider2Backend : Object, SearchProviderBackend {
    private IDBusSearchProvider2 proxy;

    public DBusSearchProvider2Backend(string bus_name, string object_path, bool autostart) throws Error {
      var flags = DBusProxyFlags.DO_NOT_LOAD_PROPERTIES;
      flags |= autostart ? DBusProxyFlags.DO_NOT_AUTO_START_AT_CONSTRUCTION : DBusProxyFlags.DO_NOT_AUTO_START;

      proxy = Bus.get_proxy_sync(BusType.SESSION, bus_name, object_path, flags);
      proxy.set_default_timeout(50);
    }

    public async string[] get_initial_result_set(string[] terms) throws Error {
      return yield proxy.get_initial_result_set(terms);
    }

    public async HashTable<string, Variant>[] get_result_metas(string[] ids) throws Error {
      return yield proxy.get_result_metas(ids);
    }

    public void activate_result(string id, string[] terms) {
      proxy.activate_result.begin(id, terms, (uint)(GLib.get_real_time() / 1000));
    }

    public void launch_search(string[] terms) throws Error {
      proxy.launch_search.begin(terms, (uint)(GLib.get_real_time() / 1000));
    }
  }

  internal Icon? create_icon(HashTable<string, Variant> meta) {
    if (meta.contains("icon")) {
      var v = meta.get("icon");
      return Icon.deserialize(v);
    } else if (meta.contains("gicon") && meta.get("gicon").get_type_string() == "s") {
      var s = meta.get("gicon").get_string();
      try {
        return Icon.new_for_string(s);
      } catch (Error e) {
        return null;
      }
    } else if (meta.contains("icon-data")) {
      var v = meta.get("icon-data");
      if (v == null)
        return null;

      int width, height, rowstride, bits_per_sample, n_channels;
      bool has_alpha;
      Variant data;


      v.get("(iiibii@ay)", out width, out height, out rowstride, out has_alpha, out bits_per_sample, out n_channels, out data);
      return new Gdk.Pixbuf.from_bytes(data.get_data_as_bytes(), Gdk.Colorspace.RGB,has_alpha,bits_per_sample,width,height,rowstride);
    }
    return null;
  }

  public class RemoteSearchProvider : Object {
    private SearchProviderBackend backend;
    public DesktopAppInfo app_info { get; private set; }
    public string id { get; private set; }
    public string name { get { return this.app_info.get_name(); } }
    public Icon? icon { get { return this.app_info.get_icon(); } }
    public bool default_enabled { get; set; }

    public RemoteSearchProvider(DesktopAppInfo app_info, SearchProviderBackend backend) {
      this.app_info = app_info;
      this.backend = backend;
      this.id = app_info.get_id() ?? "";
    }

    public static RemoteSearchProvider new_v1(string desktopId, string dbusName, string dbusPath, bool autostart) throws Error {
      var app_info = new DesktopAppInfo(desktopId);
      var backend = new DBusSearchProviderBackend(dbusName,dbusPath,autostart);
      return new RemoteSearchProvider(app_info,backend);
    }

    public static RemoteSearchProvider new_v2(string desktopId, string dbusName, string dbusPath, bool autostart) throws Error {
      var app_info = new DesktopAppInfo(desktopId);
      var backend = new DBusSearchProvider2Backend(dbusName,dbusPath,autostart);
      return new RemoteSearchProvider(app_info,backend);
    }

    public async GLib.List<ResultMeta> search(string[] query) throws Error {
      var metas = new GLib.List<ResultMeta>();
        var r = yield backend.get_initial_result_set(query);

        if (r != null && r.length > 0) {
          var result_metas = yield backend.get_result_metas(r);

          foreach (var meta in result_metas) {
            var meta_id = meta.contains("id") && meta.get("id").get_type_string() == "s"
              ? meta.get("id").get_string()
              : "";
            var meta_name = meta.contains("name") && meta.get("name").get_type_string() == "s" 
              ? meta.get("name").get_string()
              : "";
            var meta_description = meta.contains("description") && meta.get("description").get_type_string() == "s" 
              ? meta.get("description").get_string()
              : "";
            var clipboard = meta.contains("clipboardText") && meta.get("clipboardText").get_type_string() == "s" 
              ? meta.get("clipboardText").get_string()
              : "";

            metas.append(new ResultMeta(
                  meta_id,
                  meta_name,
                  meta_description,
                  create_icon(meta),
                  clipboard
                  ));
          }
        }
      return (owned) metas;
    }

    public void activate_result(string id, string[] query) {
      backend.activate_result(id, query);
    }

    public void launch_search(string[] query) {
      try {
        backend.launch_search(query);
      } catch (Error e) {
        warning("Search provider %s does not implement LaunchSearch", this.id);
        try {
          this.app_info.launch(null,null);
        } catch {}
      }
    }
  }
}


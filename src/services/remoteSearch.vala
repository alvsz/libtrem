namespace libTrem {
  public class ResultMeta : Object {
    public string id;
    public string name;
    public string description;
    public GLib.Icon? icon;
    public string clipboard_text;

    public ResultMeta(string id, string name, string description, Icon icon, string clipboard_text) {
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

  public class RemoteSearchProvider : Object {
    private IDBusSearchProvider proxy;
    public DesktopAppInfo app_info { get; construct; }
    public string id { get; construct; }
    public bool default_enabled { get; construct; }
    private GLib.List<ResultMeta> _results;
    public GLib.List<weak ResultMeta> results { owned get { return this._results.copy(); } }

    public async RemoteSearchProvider(DesktopAppInfo appInfo, string dbusName, string dbusPath, bool autostart) throws IOError {
      var flags = DBusProxyFlags.DO_NOT_LOAD_PROPERTIES;
      if (autostart)
        flags |= DBusProxyFlags.DO_NOT_AUTO_START_AT_CONSTRUCTION;
      else
        flags |= DBusProxyFlags.DO_NOT_AUTO_START;

      proxy = yield Bus.get_proxy(BusType.SESSION,dbusName,dbusPath,flags);
      Object(app_info: appInfo, id: appInfo.get_id() ?? "");
    }

    private Icon? create_icon(HashTable<string, Variant> meta) {
      if (meta.contains("icon")) {
        var v = meta.get("icon");
        return Icon.deserialize(v);
      } else if (meta.contains("gicon")) {
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

/*
width = v.get_child_value(1).get_int32();
height = v.get_child_value(2).get_int32();
rowstride = v.get_child_value(3).get_int32();
has_alpha = v.get_child_value(4).get_boolean();
bits_per_sample = v.get_child_value(5).get_int32();
n_channels = v.get_child_value(6).get_int32();
data = v.get_child_value(7).get_string();
*/


       v.get("(iiibii@ay)", out width, out height, out rowstride, out has_alpha, out bits_per_sample, out n_channels, out data);
//        uint8[] b = data.get_data_as_bytes().get_data();
//        Bytes b = new Bytes.take(data);
//        return new Gdk.Pixbuf.from_bytes(data.get_data_as_bytes(), Gdk.Colorspace.RGB,has_alpha,bits_per_sample,width,height,rowstride);
      }
      return null;
    }

    public async void search(string[] query) {
      var metas = new GLib.List<ResultMeta>();

      try {
        var r = yield this.proxy.get_initial_result_set(query);

        if (r != null && r.length > 0) {
          try {
            var result_metas = yield proxy.get_result_metas(r);

            foreach (var meta in result_metas) {
              var rm = new ResultMeta( meta.get("id").get_string() ?? "",
                  meta.get("name").get_string() ?? "",
                  meta.get("description").get_string() ?? "",
                  create_icon(meta),
                  meta.get("clipboardText").get_string() ?? "" );
              metas.append(rm);
            }
          } catch (Error e) {
            warning("Received error from D-Bus search provider %s during GetResultMetas: %s", this.id,e.message);
          }

        }
      } catch (Error e) {
        warning("Received error from D-Bus search provider %s: %s", this.id,e.message);
      }

      this._results = (owned) metas;
    }

    public void activate_result(string id, string[] query) {
      this.proxy.activate_result.begin(id);
    }

    public void launch_search(string[] query) {
      try {
        this.app_info.launch(null,null);
      } catch (Error e) { }
    }
  }

  public class RemoteSearchProvider2 : RemoteSearchProvider {
    public async RemoteSearchProvider2(DesktopAppInfo appInfo, string dbusName, string dbusPath, bool autostart) throws IOError {
      base(appInfo,dbusName,dbusPath,autostart);
    }

  }
}


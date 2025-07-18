namespace libTrem {
  public class ResultMeta : Object {
    public string id;
    public string name;
    public string description;
    public GLib.Icon? icon;
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

  internal Icon? create_icon(HashTable<string, Variant> meta) {
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


      v.get("(iiibii@ay)", out width, out height, out rowstride, out has_alpha, out bits_per_sample, out n_channels, out data);
      return new Gdk.Pixbuf.from_bytes(data.get_data_as_bytes(), Gdk.Colorspace.RGB,has_alpha,bits_per_sample,width,height,rowstride);
    }
    return null;
  }

  public class RemoteSearchProvider : Object {
    private IDBusSearchProvider proxy { get; private set; }

    private DesktopAppInfo app_info;
    public string id { get; private set; }
    public string name { get { return this.app_info.get_name(); } }
    public bool default_enabled { get; set; }

    public RemoteSearchProvider(string desktopId, string dbusName, string dbusPath, bool autostart) throws IOError {
      app_info = new DesktopAppInfo(desktopId);

      var flags = DBusProxyFlags.DO_NOT_LOAD_PROPERTIES;
      if (autostart)
        flags |= DBusProxyFlags.DO_NOT_AUTO_START_AT_CONSTRUCTION;
      else
        flags |= DBusProxyFlags.DO_NOT_AUTO_START;

      proxy = Bus.get_proxy_sync(BusType.SESSION,dbusName,dbusPath,flags);
      id = app_info.get_id() ?? "";
    }

    public virtual async GLib.List<ResultMeta> search(string[] query) {
      var metas = new GLib.List<ResultMeta>();

      try {
        var r = yield this.proxy.get_initial_result_set(query);

        if (r != null && r.length > 0) {
          try {
            var result_metas = yield this.proxy.get_result_metas(r);

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

      return (owned)metas;
    }

    public virtual void activate_result(string id, string[] query) {
      this.proxy.activate_result.begin(id);
    }

    public virtual void launch_search(string[] query) {
      try {
        this.app_info.launch(null,null);
      } catch (Error e) {
        warning("Search provider %s does not implement LaunchSearch, error: %s", this.id, e.message);
      }
    }
  }

  public class RemoteSearchProvider2 : RemoteSearchProvider {
    private new IDBusSearchProvider2 proxy;

    public RemoteSearchProvider2(string desktopId, string dbusName, string dbusPath, bool autostart) throws IOError {
      var flags = DBusProxyFlags.DO_NOT_LOAD_PROPERTIES;
      if (autostart)
        flags |= DBusProxyFlags.DO_NOT_AUTO_START_AT_CONSTRUCTION;
      else
        flags |= DBusProxyFlags.DO_NOT_AUTO_START;

      base(desktopId,dbusName,dbusPath,autostart);
      proxy = Bus.get_proxy_sync(BusType.SESSION,dbusName,dbusPath,flags);
    }

    public override async GLib.List<ResultMeta> search(string[] query) {
      var metas = new GLib.List<ResultMeta>();

      try {
        var r = yield this.proxy.get_initial_result_set(query);

        if (r != null && r.length > 0) {
          try {
            var result_metas = yield this.proxy.get_result_metas(r);

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

      return (owned)metas;
    }

    public override void activate_result(string id, string[] query) {
      this.proxy.activate_result.begin(id, query, (uint)(GLib.get_real_time() / 1000));
    }

    public override void launch_search(string[] query) {
      this.proxy.launch_search.begin(query,(uint)(GLib.get_real_time() / 1000));
    }
  }
}


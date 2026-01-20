namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/networkInfo.ui")]
    public class NetworkInfo : Gtk.Box {
      public AstalNetwork.Network network { get; construct; }
      public List<weak NetworkButton> aps { owned get { return _aps.get_values(); } }

      private HashTable<string, NetworkButton> _aps = new HashTable<string, NetworkButton>(str_hash, str_equal);
      private NetworkButton wired;

      public signal void go_back();

      public NetworkInfo () {
        Object ();
      }

      construct {
        if (network == null) {
          this.network = AstalNetwork.Network.get_default();
        }
        this.network.wifi.access_point_added.connect(on_ap_added);
        this.network.wifi.access_point_removed.connect(on_ap_removed);
        this.network.wifi.state_changed.connect(on_aps_changed);
        wired = new NetworkButton.from_wired();
        known_access_points.append(wired);

        this.network.wifi.access_points.foreach((ap) => {
          on_ap_added(ap);
        });

        network.wifi.bind_property("enabled", wifi_switch, "active", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.BIDIRECTIONAL);
      }

      internal HashTable<string, NM.SettingWireless> get_known_ssids () {
        var ssids = new HashTable<string, NM.SettingWireless>(str_hash, str_equal);
        var conns = network.client.get_connections();
        foreach (var conn in conns) {
          var wireless = conn.get_setting_wireless();
          if (wireless != null)
            ssids.insert(NM.Utils.ssid_to_utf8(wireless.ssid.get_data()), wireless);
        }
        return (owned)ssids;
      }

      [GtkChild]
        private unowned Gtk.Switch wifi_switch;
      [GtkChild]
        private unowned Gtk.Box known_access_points;
      [GtkChild]
        private unowned Gtk.Box unknown_access_points;

      [GtkCallback]
        private void on_go_back() {
          go_back();
        }

      private void on_ap_added(AstalNetwork.AccessPoint ap) {
        var ssids = get_known_ssids();
        var w = new NetworkButton.from_wireless(ap);

        _aps.insert(ap.bssid, w);
        if (ap.ssid != null && ssids.get(ap.ssid) != null)
          known_access_points.append(w);
        else
          unknown_access_points.append(w);

        on_aps_changed();
      }

      private void on_ap_removed(AstalNetwork.AccessPoint ap) {
        var ssids = get_known_ssids();
        var w = _aps.get(ap.bssid);

        if (ap.ssid != null && ssids.get(ap.ssid) != null)
          known_access_points.remove(w);
        else
          unknown_access_points.remove(w);

        _aps.remove(ap.bssid);

        on_aps_changed();
      }

      private void on_aps_changed() {
        var ssids = get_known_ssids();
        var ap_list = _aps.get_values();

        ap_list.sort((a,b) => {
          return b.ap.strength - a.ap.strength;
        });

        NetworkButton known_prev = wired;
        Gtk.Widget unknown_prev = null;

        foreach (var w in ap_list) {
          var parent = (Gtk.Box?)w.get_parent();

          if (w.ap.ssid != null && ssids.get(w.ap.ssid) != null) {
            if (parent != known_access_points) {
              parent?.remove(w);
              known_access_points.append(w);
            }
            known_access_points.reorder_child_after(w, known_prev);
            known_prev = w;
          } else {
            if (parent != unknown_access_points) {
              parent?.remove(w);
              unknown_access_points.append(w);
            }
            unknown_access_points.reorder_child_after(w, unknown_prev);
            unknown_prev = w;
          }
        }
      }
    }
}


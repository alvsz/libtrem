namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/networkInfo.ui")]
    public class NetworkInfo : Gtk.Box {
      public AstalNetwork.Network network { get; construct; }
      public HashTable<string, NetworkButton> aps = new HashTable<string, NetworkButton>(str_hash, str_equal);
      private NetworkButton wired;

      public signal void go_back();

      public NetworkInfo (string app_id, string contact_info, bool? auto_update) {
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
        known_ssids.append(wired);

        this.network.wifi.access_points.foreach((ap) => {
          on_ap_added(ap);
        });
      }

      [GtkChild]
        private unowned Gtk.Box known_ssids;

      [GtkCallback]
        private void on_go_back() {
          go_back();
        }

      [GtkCallback]
        private void on_wifi_toggled(Gtk.Switch s) {
          network.wifi.enabled = s.get_active();
        }

      private void on_ap_added(AstalNetwork.AccessPoint ap) {
        warning("ap added %s", ap.ssid);
        var w = new NetworkButton.from_wireless(ap);
        aps.insert(ap.bssid, w);
        known_ssids.append(w);
          on_aps_changed();
      }

      private void on_ap_removed(AstalNetwork.AccessPoint ap) {
        warning("ap removed %s", ap.ssid);
        var w = aps.get(ap.bssid);
        known_ssids.remove(w);
        aps.remove(ap.bssid);
          on_aps_changed();
      }

      private void on_aps_changed() {
        warning ("changed");
        var ap_list = aps.get_values();

        ap_list.sort((a,b) => {
          return b.ap.strength - a.ap.strength;
        });

        NetworkButton prev = wired;

        foreach (var w in ap_list) {
          known_ssids.reorder_child_after(w, prev);
          prev = w;
        }
      }
    }
}


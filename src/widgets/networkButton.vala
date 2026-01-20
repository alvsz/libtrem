namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/networkButton.ui")]
    public class NetworkButton : Gtk.Button {
      private AstalNetwork.Network network = AstalNetwork.Network.get_default ();
      public AstalNetwork.AccessPoint? ap { get; private set; }
      public AstalNetwork.Wired? wired { get; private set; }

      public new string icon_name { get; internal set; }
      public string ssid { get; internal set; }
      public bool connected { get; internal set; }
      public bool loading { get; internal set; }
      public bool password_protected { get; internal set; }

      public NetworkButton.from_wired () {
        wired = network.wired;
        ssid = "Rede cabeada";
        password_protected = false;
        wired.bind_property ("icon-name", this, "icon-name", GLib.BindingFlags.SYNC_CREATE);

        wired.notify["state"].connect(() => {
          switch (wired.state) {
            case AstalNetwork.DeviceState.PREPARE:
            case AstalNetwork.DeviceState.CONFIG:
            case AstalNetwork.DeviceState.IP_CONFIG:
            case AstalNetwork.DeviceState.DEACTIVATING:
              loading = true;
              connected = false;
              break;
            case AstalNetwork.DeviceState.ACTIVATED:
              loading = false;
              connected = true;
              break;
            default:
              loading = false;
              connected = false;
              break;
          }
        });
        wired.notify_property ("state");
      }

      public NetworkButton.from_wireless (AstalNetwork.AccessPoint a) {
        ap = a;
        var w = network.wifi;
        ap.bind_property ("icon-name", this, "icon-name", GLib.BindingFlags.SYNC_CREATE);
        ap.bind_property ("ssid", this, "ssid", GLib.BindingFlags.SYNC_CREATE);
        ap.bind_property ("requires_password", this, "password-protected", GLib.BindingFlags.SYNC_CREATE);

        w.notify["active-access-point"].connect(() => {
          if (w.active_access_point == ap) {
            switch (w.state) {
              case AstalNetwork.DeviceState.PREPARE:
              case AstalNetwork.DeviceState.CONFIG:
              case AstalNetwork.DeviceState.IP_CONFIG:
              case AstalNetwork.DeviceState.DEACTIVATING:
                loading = true;
                connected = false;
                break;
              case AstalNetwork.DeviceState.ACTIVATED:
                loading = false;
                connected = true;
                break;
              default:
                loading = false;
                connected = false;
                break;
            }
          } else {
            loading = false;
            connected = false;
          }
        });
        w.notify_property ("active-access-point");
      }

      [GtkCallback]
        private void on_click () {
          if (ap != null) {
            try {
              ap.activate.begin ();
            } catch (Error e) {
              warning ("%s", e.message);
            }
          }
        }
    }
}


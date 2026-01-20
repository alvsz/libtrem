namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/upowerDevices.ui")]
    public class UPowerDevices : Gtk.Box {
      public AstalBattery.UPower upower { get; construct; }
      public List<weak UPowerDevice> devices { owned get { return _devices.get_values(); } }

      private HashTable<string, UPowerDevice> _devices = new HashTable<string, UPowerDevice>(str_hash, str_equal);

      public UPowerDevices () {
        Object ();
      }

      construct {
        if (upower == null) {
          this.upower = new AstalBattery.UPower ();
          upower.device_added.connect (on_device_added);
          upower.device_removed.connect (on_device_removed);
        }
        upower.devices.foreach ((d) => on_device_added (d));
      }

      [GtkCallback]
        private void on_device_added (AstalBattery.Device d) {
          var w = new UPowerDevice (d);
          _devices.insert (d.native_path, w);
          this.append (w);
        }

      [GtkCallback]
        private void on_device_removed (AstalBattery.Device d) {
          var w = _devices.get (d.native_path);
          this.remove (w);
          _devices.remove (d.native_path);
        }

    }

}


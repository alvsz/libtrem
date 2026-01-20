namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/bluetoothInfo.ui")]
    public class BluetoothInfo : Gtk.Box {
      public AstalBluetooth.Bluetooth bluetooth { get; construct; }

      private HashTable<string, BluetoothButton> _devices = new HashTable<string, BluetoothButton>(str_hash, str_equal);
      private HashTable<string, AstalBluetooth.Adapter> _adapters = new HashTable<string, AstalBluetooth.Adapter>(str_hash, str_equal);

      public List<weak BluetoothButton> devices { owned get { return _devices.get_values (); } }
      public List<weak AstalBluetooth.Adapter> adapters { owned get { return _adapters.get_values (); } }

      public signal void go_back();

      public BluetoothInfo () {
        Object ();
      }

      construct {
        if (bluetooth == null) {
          this.bluetooth = AstalBluetooth.Bluetooth.get_default();
        }
        bluetooth.adapter.bind_property("powered", bt_switch, "active", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.BIDIRECTIONAL);
        bluetooth.devices.foreach ((d) => on_device_added (d));
        bluetooth.adapters.foreach ((a) => on_adapter_added (a));
      }


      [GtkChild]
        private unowned Gtk.Switch bt_switch;
      [GtkChild]
        private unowned Gtk.Box known_devices;
      [GtkChild]
        private unowned Gtk.Box unknown_devices;

      [GtkCallback]
        private void on_go_back() {
          go_back();
        }

      [GtkCallback]
        private void on_device_added (AstalBluetooth.Device d) {
          var w = new BluetoothButton(d);
          _devices.insert (d.address, w);

          if (w.device.paired)
            known_devices.append (w);
          else
            unknown_devices.append (w);
        }

      [GtkCallback]
        private void on_device_removed (AstalBluetooth.Device d) {
          var w = _devices.get (d.address);

          if (w.device.paired)
            known_devices.remove (w);
          else
            unknown_devices.remove (w);
          
          _devices.remove (w.device.address);
        }

      [GtkCallback]
        private void on_adapter_added (AstalBluetooth.Adapter a) {
          _adapters.insert (a.address, a);
        }

      [GtkCallback]
        private void on_adapter_removed (AstalBluetooth.Adapter a) {
          _adapters.remove (a.address);
        }



    }
}


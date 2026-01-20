namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/bluetoothButton.ui")]
    public class BluetoothButton : Gtk.Button {
      public AstalBluetooth.Device device { get; construct; }

      public BluetoothButton (AstalBluetooth.Device d) {
        Object(device: d);
      }

      construct {
        if (device == null)
          error("device não pode ser null");
      }

      [GtkCallback]
        private void on_click () {
          try {
            if (device.connected)
              device.disconnect_device.begin();
            else
              device.connect_device.begin();
          } catch (Error e) {
            warning ("Error: %s", e.message);
          }
        }
    }
}


namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/brightnessDevices.ui")]
    public class BrighnessDevices : Gtk.Box {
      public AstalBrightness.Brightness brightness { get; construct; }
      private HashTable<string, BrighnessDevice> _devices = new HashTable<string, BrighnessDevice>(str_hash, str_equal);

      public BrighnessDevices () {
        Object ();
      }

      construct {
        if (brightness == null) {
          this.brightness = AstalBrightness.get_default ();
        }
        brightness.backlights.device_appeared.connect (on_device_added);
        brightness.backlights.device_removed.connect (on_device_removed);
        brightness.backlights.devices.foreach ((d) => on_device_added (d));
      }

      private void on_device_added (AstalBrightness.Device d) {
        var w = new BrighnessDevice (d);
        _devices.insert (d.name, w);
        this.append (w);
      }

      private void on_device_removed (AstalBrightness.Device d) {
        var w = _devices.get (d.name);
        this.remove (w);
        _devices.remove (d.name);
      }
    }
}


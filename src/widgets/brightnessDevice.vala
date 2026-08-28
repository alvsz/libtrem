namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/brightnessDevice.ui")]
    public class BrighnessDevice : Gtk.Box {
      public AstalBrightness.Device device { get; construct; }

      public BrighnessDevice (AstalBrightness.Device d) {
        Object(device: d);
      }

      construct {
        if (device == null)
          error("device não pode ser null");
      }

      [GtkCallback]
        protected void on_value_changed(Gtk.Adjustment self) {
          device.real_brightness = (uint)self.value;
        }
    }
}


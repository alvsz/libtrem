namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/upowerDevice.ui")]
    public class UPowerDevice : Gtk.Box {
      public AstalBattery.Device device { get; construct; }

      public UPowerDevice (AstalBattery.Device d) {
        Object(device: d);
      }

      construct {
        if (device == null)
          error("device não pode ser null");
      }
    }
}


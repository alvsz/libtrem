namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/audioDevice.ui")]
    public class AudioDevice : Gtk.Box {
      public AstalWp.Endpoint endpoint { get; construct; }
      public AudioDevice group { get; construct; }

      public AudioDevice (AstalWp.Endpoint e) {
        Object(endpoint: e);
      }

      public AudioDevice.with_group (AstalWp.Endpoint e, AudioDevice g) {
        Object(endpoint: e, group: g);
      }

      construct {
        if (endpoint == null)
          error("device não pode ser null");

        if (group == null)
          group = this;
      }
    }
}


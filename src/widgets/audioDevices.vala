namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/audioDevices.ui")]
    public class AudioDevices : Gtk.Box {
      public AstalWp.Wp wp { get; construct; }
//      public List<weak AudioDevices> devices { owned get { return _devices.get_values(); } }

      private HashTable<uint, AudioDevice> _devices = new HashTable<uint, AudioDevice>(str_hash, str_equal);

      public AudioDevices () {
        Object ();
      }

      construct {
        if (wp == null) {
          this.wp = AstalWp.get_default ();
//          wp.audio.device_added.connect (on_device_added);
//          wp.audio.device_removed.connect (on_device_removed);
        }
//        wp.ready.connect(() => wp.audio.devices.foreach ((d) => on_device_added (d)));
      }

      private void on_device_added (AstalWp.Endpoint e) {
        AudioDevice w;
        if (_devices.length > 0) {
          var g = _devices.get_values ().nth_data (0);
          w = new AudioDevice.with_group (e, g);
        } else {
          w = new AudioDevice (e);
        }
        _devices.insert (e.id, w);
        this.append (w);
      }

      private void on_device_removed (AstalWp.Endpoint e) {
        var w = _devices.get (e.id);
        this.remove (w);
        _devices.remove (e.id);
      }
    }
}


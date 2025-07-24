[CCode (cheader_filename = "dwl-ipc-unstable-v2-protocol.h")]
namespace libTrem {
  public class Dwl : Object {
    internal static void global_add (void *data, Wl.Registry registry, uint32 name, string interface, uint32 version) {
      Dwl self = (Dwl)data;
      printerr ("novo protocolo: %s %u v%u", interface, name, version);
    }

    internal static void global_remove (void *data, Wl.Registry registry, uint32 name) {
      Dwl self = (Dwl)data;
      printerr ("protocolo sumiu: %u",  name);
    }


    public Dwl() {
    }

    construct {
      var display = new Wl.Display.connect (null);
      var registry = display.get_registry ();


      var listener = Wl.RegistryListener ();

      listener.global = global_add;
      listener.global_remove = global_remove;

      registry.add_listener (listener, this);

      display.roundtrip ();
      display.dispatch ();
    }
  }

}


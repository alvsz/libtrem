namespace libTrem {
  public class EvolutionDataServer: Object {
    public signal void tasklist_added (Object a);
    public signal void tasklist_removed(Object a);
    public signal void tasklist_changed(Object a);
    public signal void calendar_added (Object a);
    public signal void calendar_removed(Object a);
    public signal void calendar_changed(Object a);

    public HashTable<string,E.Source> calendars { private set; public get; }
    public HashTable<string,E.Source> tasklists { private set; public get; }
    private E.SourceRegistry source_registry;

    private static EvolutionDataServer _instance;

    public static EvolutionDataServer get_default() {
      if (_instance == null)
        _instance = new EvolutionDataServer();

      return _instance;
    }

    construct {
      calendars = new HashTable<string,E.Source> (GLib.str_hash,GLib.str_equal);
      tasklists = new HashTable<string,E.Source> (GLib.str_hash,GLib.str_equal);

      try {
        init_registry.begin();
      } catch (Error e) {
        warning ("Error: %s\n", e.message);
      }
    }

    private async void init_registry() throws Error {
      source_registry = yield new E.SourceRegistry(null);

      source_registry.source_added.connect((self,source) => {
          if (source.has_extension(E.SOURCE_EXTENSION_TASK_LIST)) {
            tasklists.set(source.uid,source);
            tasklist_added(source);
          }
          if (source.has_extension(E.SOURCE_EXTENSION_CALENDAR)) {
            calendars.set(source.uid,source);
            calendar_added(source);
          }
          });

      source_registry.source_removed.connect((self,source) => {
          if (source.has_extension(E.SOURCE_EXTENSION_TASK_LIST)) {
            tasklists.remove(source.uid);
            tasklist_removed(source);
          }
          if (source.has_extension(E.SOURCE_EXTENSION_CALENDAR)) {
            calendars.remove(source.uid);
            calendar_removed(source);
          }
          });

      source_registry.source_changed.connect((self,source) => {
          if (source.has_extension(E.SOURCE_EXTENSION_TASK_LIST)) 
            tasklist_changed(source);

          if (source.has_extension(E.SOURCE_EXTENSION_CALENDAR)) 
            calendar_changed(source);
          });

      source_registry.list_sources(E.SOURCE_EXTENSION_TASK_LIST).foreach((source) => {
          tasklists.set(source.uid,source);
          tasklist_added(source);
          });

      source_registry.list_sources(E.SOURCE_EXTENSION_CALENDAR).foreach((source) => {
          calendars.set(source.uid,source);
          calendar_added(source);
          });
    }
  }

  public class CollectionObject: Object {
    public signal void changed ();
    private ECal.Component _source;

    public ECal.Client client { get; construct; }
    public ECal.Component source { 
      get { return _source; }
      set construct {
        _source = value;
        this.changed();
      }
    }

    public string uid {
      get { return _source.get_uid(); }
    }
    public string location {
      get { return _source?.get_location() ?? ""; }
      set { _source.set_location(value); }
    }
    public int priority {
      get { return _source.get_priority(); }
      set { _source.set_priority(value); }
    }
    public int percent_complete {
      get { return _source.get_percent_complete(); }
      set { _source.set_percent_complete(value); }
    }
    public string description {
      get {
        SList<ECal.ComponentText> descriptions = _source.get_descriptions();
        StringBuilder sb = new StringBuilder();

        if (descriptions != null) {
          descriptions.foreach((desc) => {
              sb.append( desc.get_value());
              });
        }

        return sb.str;
      }
      set {
        SList<ECal.ComponentText> s = new SList<ECal.ComponentText>();
        s.append(new ECal.ComponentText(value, null));
        _source.set_descriptions(s);
      }
    }
    public string status {
      get { return _source.get_status().to_string(); }
      // set { _source.set }
      // set { _source.set_status(new ICal.Pro)}
    }
    

    public CollectionObject(ECal.Component source, ECal.Client client) {
      Object(source: source, client: client);
    }

    construct {
      if (source == null || client == null)
        error("source nem client não podem ser null\n");
    }
    
  }
}


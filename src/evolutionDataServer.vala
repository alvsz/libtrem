namespace libTrem {
  public class EvolutionDataServer: Object {
    public signal void tasklist_added (E.Source a);
    public signal void tasklist_removed (E.Source a);
    public signal void tasklist_changed (E.Source a);
    public signal void calendar_added (E.Source a);
    public signal void calendar_removed (E.Source a);
    public signal void calendar_changed (E.Source a);

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
    public string summary {
      get { return _source.get_summary().get_value(); }
      set { _source.set_summary(new ECal.ComponentText(value,null)); }
    }
    public string location {
      owned get { return _source.get_location() ?? ""; }
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
    public DateTime dtstart  {
      owned get { return ecal_to_date(_source.get_dtstart()); }
      set { _source.set_dtstart(date_to_ecal(value)); }
    }
    public DateTime  dtend  {
      owned get { return ecal_to_date(_source.get_dtend()); }
      set { _source.set_dtend(date_to_ecal(value)); }
    }
    public DateTime  due {
      owned get { return ecal_to_date(_source.get_due()); }
      set { _source.set_due(date_to_ecal(value)); }
    }
    public string description {
      owned get {
        SList<ECal.ComponentText> descriptions = _source.get_descriptions();
        string s = "";

        if (descriptions != null) {
          descriptions.foreach((desc) => {
              s = s.concat(desc.get_value());
              });
        }
        return s;
      }
      set {
        SList<ECal.ComponentText> s = new SList<ECal.ComponentText>();
        s.append(new ECal.ComponentText(value, null));
        _source.set_descriptions(s);
      }
    }
    public ICal.PropertyStatus status {
      get { return _source.get_status(); }
      set { _source.set_status(value); }
    }

    private DateTime ecal_to_date(ECal.ComponentDateTime d) {
      return new DateTime.from_unix_local(d.get_value().as_timet_with_zone(ECal.util_get_system_timezone()));
    }

    private ECal.ComponentDateTime date_to_ecal(DateTime d) {
      ICal.Time t = new ICal.Time.from_timet_with_zone((time_t)d.to_unix(),0,ECal.util_get_system_timezone());
      t.set_timezone(ECal.util_get_system_timezone());
      return new ECal.ComponentDateTime(t,null);
    }

    public CollectionObject(ECal.Component source, ECal.Client client) {
      Object(source: source, client: client);
    }

    construct {
      if (source == null || client == null)
        error("source nem client não podem ser null\n");
    }

    public async bool save() {
      SList<ICal.Component> s = new SList<ICal.Component>();
      s.append(source.get_icalcomponent());
      try {
        return client.modify_objects_sync(s,ECal.ObjModType.ALL,ECal.OperationFlags.NONE,null);
      } catch (Error e) {
        warning("Error: %s\n", e.message);
        return false;
      }
    }
  }

  public abstract class Collection : Object {
    public signal void ready();
    public signal void changed();

    public E.Source source { get; construct; }
    public string source_extension { get; construct; }

    public string display_name { get { return source.get_display_name(); } }
    public string uid { get { return source.get_uid(); } }

    protected Collection(E.Source s, string t) {
      Object(source: s, source_extension: t);
    }

    construct {
      if (source == null)
        error("source não pode ser null\n");

      init_collection.begin();
    }

    public abstract async GLib.SList<Object> query_objects(string sexp) throws Error;
    public abstract void delete(string uid);
    protected abstract async void init_collection() throws Error;
  }

  public class CollectionTypeService : Object {
    public signal void collection_added(Collection a);
    public signal void collection_removed(Collection a);
    public signal void collection_changed(Collection a);
    public signal void changed();

    protected HashTable<string, Collection> _collections = new HashTable<string, Collection>(GLib.str_hash, GLib.str_equal);
    public Type ctor { get; construct; }
    public string client_type { get; construct; }
    public List<weak Collection> collections { owned get { return _collections.get_values(); } }

    public CollectionTypeService(string t, Type type) {
      Object(client_type: t, ctor: type);
    }

    construct {
      if (client_type == null)
        error("client_type nem collection_constructor não podem ser null\n");

      EvolutionDataServer e = EvolutionDataServer.get_default();

      switch(client_type) {
        case E.SOURCE_EXTENSION_TASK_LIST:
          e.tasklist_added.connect(on_collection_added);
          e.tasklist_removed.connect(on_collection_removed);
          e.tasklist_changed.connect(on_collection_changed);

          e.tasklists.foreach((key,value) => {
              on_collection_added(e, value);
              });
          break;
        case E.SOURCE_EXTENSION_CALENDAR:
          e.calendar_added.connect(on_collection_added);
          e.calendar_removed.connect(on_collection_removed);
          e.calendar_changed.connect(on_collection_changed);

          e.calendars.foreach((key,value) => {
              on_collection_added(e, value);
              });
          break;
        default:
          print("default bugou\n\n\n");
      }
    }

    private void on_collection_added(EvolutionDataServer registry, E.Source source) {
      Collection c;
      if(!_collections.lookup_extended(source.get_uid(),null,out c)) {
        c = (Collection) Object.new(ctor,"source",source,null);
        c.ready.connect(() => {
            _collections.set(source.get_uid(), c);
            collection_added(c);
            changed();
            });
      }
    }

    private void on_collection_removed(EvolutionDataServer registry, E.Source source) {
      collection_removed(_collections.get(source.get_uid()));
      _collections.remove(source.get_uid());
      changed();
    }

    private void on_collection_changed(EvolutionDataServer registry, E.Source source) {
      Collection c;
      if(!_collections.lookup_extended(source.get_uid(),null,out c)) {
        c = (Collection) Object.new(ctor,"source",source,null);
        c.changed();
        collection_changed(c);
      }
      changed();
    }
  }
}


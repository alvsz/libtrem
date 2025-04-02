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

    public CollectionObject(ECal.Component source, ECal.Client client) {
      Object(source: source, client: client);
    }

    construct {
      if (source == null || client == null)
        error("source nem client não podem ser null\n");
    }
  }

  public class Collection : Object {
    public signal void ready();
    public signal void changed();

    protected ECal.Client client;
    protected ECal.ClientView client_view;
    public E.Source source { get; construct; }
    public ECal.ClientSourceType source_type { get; construct; }

    public string display_name { get { return source.get_display_name(); } }
    public string uid { get { return source.get_uid(); } }

    construct {
      if (source == null)
        error("source não pode ser null\n");

      init_collection.begin();
    }

    public Collection(E.Source s, ECal.ClientSourceType t) {
      Object(source: s, source_type: t);
    }

    public async GLib.SList<ECal.Component> query_objects(string sexp) throws Error {
      GLib.SList<ECal.Component> s;
      yield client.get_object_list_as_comps(sexp,null,out s);
      return s;
    }

    public void delete(string uid) {
      client.remove_object.begin(uid, null, ECal.ObjModType.ALL, ECal.OperationFlags.NONE, null);
    }

    private async void init_collection() throws Error {
        client = (ECal.Client) yield ECal.Client.connect(source, source_type, 0, null);
        yield client.get_view("#t", null, out client_view);

        client_view.objects_added.connect(() => this.changed());
        client_view.objects_removed.connect(() => this.changed());
        client_view.objects_modified.connect(() => this.changed());

        this.ready();
        this.changed();
    }
  }

  public class CollectionTypeService : Object {
    public signal void collection_added(Collection a);
    public signal void collection_removed(Collection a);
    public signal void collection_changed(Collection a);
    public signal void changed();

    protected HashTable<string, Collection> _collections;
    private ECal.ClientSourceType client_type;

    public CollectionTypeService(string type,ECal.ClientSourceType t) {
      EvolutionDataServer e = EvolutionDataServer.get_default();
      client_type = t;

      e.connect(
          type + "-added", 
          this.on_collection_added
          );
      e.connect(
          type + "-removed", 
          this.on_collection_removed
          );
      e.connect(
          type + "-changed", 
          this.on_collection_changed
          );

      switch (type) {
        case "calendar":
          e.calendars.foreach((key,value) => {
              on_collection_added(e, value);
              });
          break;
        case "tasklist":
          e.tasklists.foreach((key,value) => {
              on_collection_added(e, value);
              });
          break;
      }
    }

    public List<weak Collection> collections { owned get { return _collections.get_values(); } }

    private void on_collection_added(EvolutionDataServer registry, E.Source source) {
      Collection c;
      if(!_collections.lookup_extended(source.get_uid(),null,out c)) {
        c = new Collection(source,client_type);
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
        c = new Collection(source,client_type);

        c.changed();
        collection_changed(c);
      }
      changed();
    }
  }
}


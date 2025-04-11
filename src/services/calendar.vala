namespace libTrem {
  public class Event : CollectionObject {
    public Event(ECal.Component source, ECal.Client client) {
      base(source,client);
    }
  }

  public class CalendarCollection : Collection {
    public ECal.Client client { get; private set; }
    protected ECal.ClientView client_view;
    public ECal.ClientSourceType source_type { get; private set; }

    public CalendarCollection(E.Source s) {
      base(s, E.SOURCE_EXTENSION_CALENDAR);
    }

    public override async GLib.SList<Object> query_objects(string sexp) throws Error {
      GLib.SList<ECal.Component> s;
      yield client.get_object_list_as_comps(sexp,null,out s);
      return s;
    }

    public override void delete(string uid) {
      client.remove_object.begin(uid, null, ECal.ObjModType.ALL, ECal.OperationFlags.NONE, null);
    }

    protected override async void init_collection() throws Error {
        client = (ECal.Client) yield ECal.Client.connect(source, source_type, 0, null);
        yield client.get_view("#t", null, out client_view);

        client_view.objects_added.connect(() => this.changed());
        client_view.objects_removed.connect(() => this.changed());
        client_view.objects_modified.connect(() => this.changed());

        this.ready();
        this.changed();
    }
  }

  public class EventList : CalendarCollection {
    public EventList(E.Source s) {
      base(s);
    }

    public async GLib.List<Event> get_events_in_range(DateTime start, DateTime end) {
      string start_str = ECal.isodate_from_time_t((time_t)start.to_unix());
      string end_str = ECal.isodate_from_time_t((time_t)end.to_unix());

      string query = """(occur-in-time-range? 
  (make-time "%s")
  (make-time "%s"))""".printf(start_str,end_str);

      try {
        GLib.SList<Object> c = yield query_objects(query);
        GLib.List<Event> l = new GLib.List<Event>();

        c.foreach((ev) => {
            l.append(new Event((ECal.Component) ev,this.client));
            });

        return (owned) l;
      } catch(Error e) {
        warning("Error: %s\n", e.message);
        return new GLib.List<Event>();
      }
    }
  }

  public class CalendarService : CollectionTypeService {
    public CalendarService() {
      base(E.SOURCE_EXTENSION_CALENDAR, typeof(EventList));
    }
    
    public GLib.List<weak EventList> calendars { owned get { return (GLib.List<weak EventList>)this.collections; } }
  }
}

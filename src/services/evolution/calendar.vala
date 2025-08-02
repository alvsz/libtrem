namespace libTrem {
  public class Event : CollectionObject {
    public Event(ECal.Component source, ECal.Client client) {
      base(source,client);
    }
  }

  public class EventList : Collection {
    public EventList(E.Source s) {
      base(s, ECal.ClientSourceType.EVENTS);
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
    
    public GLib.List<weak EventList> calendars { owned get { return (GLib.List<weak EventList>) this.collections; } }
  }
}

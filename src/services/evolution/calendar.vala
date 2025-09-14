namespace libTrem {
  public class Event : CollectionObject {
    public Event(ECal.Component source, ECal.Client client) {
      base(source,client);
    }
  }

  public class EventList : Collection {
    private GLib.List<Event> _events = new List<Event>();
    public GLib.List<weak Event> events { owned get { return _events.copy(); } }
    public signal void event_added();

    public EventList(E.Source s) {
      base(s, ECal.ClientSourceType.EVENTS);
    }

    public void get_events_in_range(DateTime start, DateTime end) {
      _events.foreach((a) => {
          _events.remove(a);
      });

      client.generate_instances((time_t)start.to_unix(), (time_t)end.to_unix(), null, (icomp, _istart, _iend, _cancellable) => {
          var comp = new ECal.Component.from_icalcomponent (icomp);
          var ev = new Event (comp, client);
          _events.append(ev);
          event_added();
          return true;
      });
    }
  }

  public class CalendarService : CollectionTypeService {
    public CalendarService() {
      base(E.SOURCE_EXTENSION_CALENDAR, typeof(EventList));
    }
    
    public GLib.List<weak EventList> calendars { owned get { return (GLib.List<weak EventList>) this.collections; } }
  }
}

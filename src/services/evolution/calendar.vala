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
      GLib.List<Event> l = new GLib.List<Event>();

      client.generate_instances_sync((time_t)start.to_unix(), (time_t)end.to_unix(), null, (icomp, _istart, _iend, _cancellable) => {
          var comp = new ECal.Component.from_icalcomponent (icomp);
          var ev = new Event (comp, client);
          l.append(ev);
          return true;
      });

      return (owned) l;
    }
  }

  public class CalendarService : CollectionTypeService {
    public CalendarService() {
      base(E.SOURCE_EXTENSION_CALENDAR, typeof(EventList));
    }
    
    public GLib.List<weak EventList> calendars { owned get { return (GLib.List<weak EventList>) this.collections; } }
  }
}

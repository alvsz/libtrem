namespace libTrem {
  public class Event : CollectionObject {
    public Event(ECal.Component source, ECal.Client client) {
      base(source,client);
    }
  }

  public class EventList : Collection {
    private HashTable<string, Event> _events = new HashTable<string, Event>(str_hash, str_equal);
    public GLib.List<weak Event> events { owned get { return _events.get_values(); } }

    public EventList(E.Source s) {
      base(s, ECal.ClientSourceType.EVENTS);

      client_view.objects_added.connect((self, objects) => {
        objects.foreach((comp) => {
          client.generate_instances_for_object(comp, 0, 99999, null, (icomp, _istart, _iend, _cancellable) => {
            var ecomp = new ECal.Component.from_icalcomponent (icomp);
            var ev = new Event (ecomp, client);
            var key = "%s-%s".printf(ecomp.get_uid(), icomp.get_recurrenceid().as_ical_string());
            _events.set(key, ev);
            changed();

            return true;
          });
        });
      });

      client_view.objects_removed.connect((self, objects) => {
        objects.foreach((comp) => {
          var uid = comp.get_uid();
          _events.get_keys().foreach((key) => {
            if (key.has_prefix(uid)) {
              _events.remove(key);
              changed();
            }
          });
        });
      });

      client_view.objects_modified.connect((self, objects) => {
        objects.foreach((comp) => {
          client.generate_instances_for_object(comp, 0, 99999, null, (icomp, _istart, _iend, _cancellable) => {
            var ecomp = new ECal.Component.from_icalcomponent (icomp);
            var ev = new Event (ecomp, client);
            var key = "%s-%s".printf(ecomp.get_uid(), icomp.get_recurrenceid().as_ical_string());
            _events.set(key, ev);
            changed();

            return true;
          });
        });
      });
    }

    public async void get_events_in_range(DateTime start, DateTime end) {
      client.generate_instances((time_t)start.to_unix(), (time_t)end.to_unix(), null, (icomp, _istart, _iend, _cancellable) => {
          var comp = new ECal.Component.from_icalcomponent (icomp);
          var ev = new Event (comp, client);
          var key = "%s-%s".printf(comp.get_uid(), icomp.get_recurrenceid().as_ical_string());

          if (_events.get(key) == null) {
            _events.set(key, ev);
            changed();
          }

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

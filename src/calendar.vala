namespace libTrem {
  public class CalendarCollection : Collection {
    private ECal.Client client;
    private ECal.ClientView client_view;
    private ECal.ClientSourceType source_type;

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

    public static EventList create(E.Source s) {
      return new EventList(s);
    }
  }

  public class CalendarService : CollectionTypeService {
    CalendarService() {
      base(E.SOURCE_EXTENSION_CALENDAR,EventList.create);
    }
  }
}

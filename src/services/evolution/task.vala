namespace libTrem {
  public class Todo : CollectionObject {
    public Todo (ECal.Component source, ECal.Client client) {
      base (source, client);
    }
  }

  public class TodoList : Collection {
    public TodoList (E.Source s) {
      base (s, ECal.ClientSourceType.TASKS);
    }

    public async GLib.List<Todo> get_tasks_until (DateTime end) {
      string end_str = ECal.isodate_from_time_t ((time_t)end.to_unix ());

      string query = """(due-in-time-range?
      (time-now)
      (make-time "%s"))""".printf (end_str);

      try {
        GLib.SList<Object> c = yield query_objects (query);
        GLib.List<Todo> l = new GLib.List<Todo> ();

        c.foreach ((ev) => {
            l.append (new Todo((ECal.Component) ev, this.client));
            });

        return (owned) l;
      } catch (Error e) {
        warning ("Error: %s\n", e.message);
        return new GLib.List<Todo> ();
      }
    }
  }

  public class TodoService : CollectionTypeService {
    public TodoService () {
      base (E.SOURCE_EXTENSION_TASK_LIST, typeof (TodoList));
    }

    public GLib.List<weak TodoList> tasklists { owned get { return (GLib.List<weak TodoList>) this.collections; } }
  }
}

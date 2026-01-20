namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/userCenter.ui")]
    public class UserCenter : Gtk.Box {
      public Act.User user { get; construct; }
      
      construct {
        var manager = Act.UserManager.get_default();
        user = manager.get_user_by_id ((uint)Posix.getuid ());
        user.notify_property ("icon-file");
        user.notify_property ("real-name");
        user.notify_property ("user-name");
      }

      [GtkCallback]
        private string format_user_name (string u) {
          return "%s@%s".printf (u, GLib.Environment.get_host_name ());
        }

      [GtkCallback]
        private void on_power_off () {
          warning("coisando");
        }

      [GtkCallback]
        private void on_restart () {
          warning("coisando");
        }

      [GtkCallback]
        private void on_log_off () {
          warning("coisando");
        }

      [GtkCallback]
        private void on_lock () {
          warning("coisando");
        }
    }
}

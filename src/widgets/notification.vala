namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/notification.ui")]
    public class Notification : Gtk.Box {
      private AstalNotifd.Notification _notification;

      public bool popup { get; construct; default = false; }
      public bool hidden { get { return !this.not_hidden; } }
      public bool reveal_child { get; set; default = true; }
      public uint transition_duration { get; set; default = 250; }
      public bool icon_visible { get; private set; default = false; }
      public bool not_hidden { get; private set; default = true; }
      public AstalNotifd.Notification notification { get { return this._notification; } set {
        _notification = value;

        switch (notification.urgency) {
          case AstalNotifd.Urgency.CRITICAL:
            add_css_class ("critical");
            break;
          case AstalNotifd.Urgency.LOW:
            add_css_class ("low");
            break;
          case AstalNotifd.Urgency.NORMAL:
          default:
            add_css_class ("normal");
            break;
        }

        actions.hide();
        var w = actions.get_first_child ();
        if (w != null) {
          var s = w.get_next_sibling ();
          while (w != null) {
            actions.remove (w);
            w = s;
            if (w == null)
              break;

            s = w.get_next_sibling ();
          }
        }

        if (hidden)
          return;


        notification.actions.foreach ((a) => {
            if (a.id.length == 0)
            return;

            Gtk.Widget c;

            if (a.label.length > 0) {
            c = new Gtk.Label (a.label);
            unowned Gtk.Label d = c as Gtk.Label;
            d.wrap = true;
            d.justify = Gtk.Justification.CENTER;
            } else
            c = new Gtk.Image.from_icon_name ("media-playback-start-symbolic");

            var b = new Gtk.Button ();
            b.child = c;
            b.hexpand = true;
            b.halign = Gtk.Align.FILL;

            if (a.id == "default") b.add_css_class("suggested-action");

            b.clicked.connect (() => {
                notification.invoke (a.id);
                });

            actions.append (b);
            actions.show ();
        });
      } }

      public Notification (AstalNotifd.Notification notif, bool p, bool h) {
        Object(popup: p, notification: notif);
        not_hidden = !h;
      }

      [GtkChild]
        private unowned Gtk.Box actions;

      [GtkCallback]
        private string get_app_icon () {
          return_val_if_fail (notification != null, "");
          if (notification.app_icon.length > 0)
            return notification.app_icon;
          else if (notification.desktop_entry != null && notification.desktop_entry.length > 0)
            return notification.desktop_entry;
          else return "";
        }

      [GtkCallback]
        private bool app_icon_visible () {
          return_val_if_fail (notification != null, false);
          if (notification.app_icon.length > 0 || (notification.desktop_entry != null && notification.desktop_entry.length > 0))
            return true;
          else
            return false;
        }

      [GtkCallback]
        private string get_app_name () {
          return_val_if_fail (notification != null, "");
          if (notification.app_name.length > 0)
            return notification.app_name;
          else {
	    if (notification.desktop_entry != null) {
              var app_info = new DesktopAppInfo ("%s.desktop".printf (notification.desktop_entry));
              if (app_info != null)
                return app_info.get_display_name ();
	    }
          }
          return "Desconhecido";
        }

      [GtkCallback]
        private string format_time () {
          return_val_if_fail (notification != null, "");
          return new GLib.DateTime.from_unix_local (notification.time).format ("%H:%M");
        }

      [GtkCallback]
        private void on_clicked () {
          notification.dismiss ();
        }

      [GtkCallback]
        private Icon? get_icon () {
          return_val_if_fail (notification != null, null);

          if (notification.image == null)
            return null;

          if (notification.image.length > 0) {
            try {
              icon_visible = true;
              return Icon.new_for_string (notification.image);
            } catch (Error e) {
              warning ("%s", e.message);
            }
          }
          icon_visible = false;
          return null;
        }
    }
}

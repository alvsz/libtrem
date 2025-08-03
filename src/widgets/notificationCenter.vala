namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/notificationCenter.ui")]
    public class NotificationCenter : Gtk.Box {
      public bool hidden { get; construct; default = true; }
      public bool popup { get; construct; default = false; }
      public AstalNotifd.Notifd notifd { get; construct; }

      private HashTable<uint, Notification> notifications;

      [GtkChild]
        private unowned Gtk.Box notification_box;

      public NotificationCenter (bool h, bool p) {
        Object (hidden: h, popup: p);
      }

      construct {
        if (notifd == null)
          notifd = AstalNotifd.get_default ();

        notifications = new HashTable<uint, Notification>(GLib.direct_hash, GLib.direct_equal);
        
        get_old_notifications.begin ();
      }

      private async void get_old_notifications () {
        notifd.notifications.foreach ((n) => {
          on_notified (notifd, n.id, false);
        });
      }

      [GtkCallback]
        private void on_notified (AstalNotifd.Notifd self, uint id, bool replaced) {
          if (replaced && notifications.get (id) != null) {
            var notif = notifications.get (id);
            if (notif != null) {
              notif.notification = self.get_notification (id);
              notif.reveal_child = true;
              notification_box.reorder_child_after (notif, null);
            } 
          } else {
              var notif = new Notification (self.get_notification (id), this.popup, this.hidden);
              notif.reveal_child = true;
              notifications.set (id, notif);
              notification_box.prepend (notif);

            }
        }

      [GtkCallback]
        private void on_resolved (AstalNotifd.Notifd self, uint id, AstalNotifd.ClosedReason reason) {
          var notif = notifications.get (id);
          if (notif != null) {
            notif.reveal_child = false;

            Timeout.add (notif.transition_duration, () => {
              notif.hide ();
              notification_box.remove (notif);
              return Source.REMOVE;
            });
          }
        }

      [GtkCallback]
        private void on_clear () {
          notifd.notifications.foreach ((n) => {
            n.dismiss ();
          });
        }
    }
}

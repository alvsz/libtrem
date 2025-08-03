namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/notificationCenter.ui")]
    public class NotificationCenter : Gtk.Box {
      public bool not_hidden { get; private set; default = false; }
      public bool hidden { get { return !this.not_hidden; } construct { this.not_hidden = !value; } }
      public bool popup { get; construct; default = true; }
      public uint timeout { get; construct; default = 5000; }
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
        
        if (!popup)
          get_old_notifications.begin ();
      }

      private async void get_old_notifications () {
        notifd.notifications.foreach ((n) => {
          on_notified (notifd, n.id, false);
        });
      }

      [GtkCallback]
        private void on_notified (AstalNotifd.Notifd self, uint id, bool replaced) {
          Notification notif;
          if (replaced && notifications.get (id) != null) {
            notif = notifications.get (id);
            if (notif != null) {
              notif.notification = self.get_notification (id);
              notification_box.reorder_child_after (notif, null);
            } 
          } else {
              notif = new Notification (self.get_notification (id), this.popup, this.hidden);
              notifications.set (id, notif);
              notification_box.prepend (notif);
            }
          notif.reveal_child = true;

          if (hidden || popup)
            show ();

          if (popup) {
            if (!self.dont_disturb) {
              this.get_root ()?.show ();
            }

            Timeout.add (notif.notification.expire_timeout > 0 ? notif.notification.expire_timeout : this.timeout, () => {
              on_resolved (self, id, AstalNotifd.ClosedReason.EXPIRED);
              return Source.REMOVE;
            });
          }
        }

      [GtkCallback]
        private void on_resolved (AstalNotifd.Notifd self, uint id, AstalNotifd.ClosedReason reason) {
          var notif = notifications.get (id);
          if (notif != null) {
            notif.reveal_child = false;

            Timeout.add (notif.transition_duration + 1, () => {
              notif.hide ();
              if (notif.get_parent () == notification_box)
                notification_box.remove (notif);

              if (notification_box.get_first_child () != null) 
                return Source.REMOVE;

              if (hidden)
                hide ();
              if (popup) 
                this.get_root ()?.hide ();
              
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

      [GtkCallback]
        private bool header_visible () {
          if (hidden || popup)
            return false;
          else
            return true;
        }
    }
}

namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/lockscreenMpris.ui")]
    public class LockscreenMpris : Gtk.Box {
      public AstalMpris.Mpris mpris { get; construct set; }
      public AstalMpris.Player player { get; private set; }
      public AstalCava.Cava cava { get; construct set; }

      [GtkChild]
        private unowned Gtk.DrawingArea cava_area;

      [GtkCallback]
        protected string format_play_button() {
          if (player?.playback_status == AstalMpris.PlaybackStatus.PLAYING)
            return "media-playback-pause-symbolic";
          else return "media-playback-start-symbolic";
        }

      [GtkCallback]
        protected void on_value_changed(Gtk.Adjustment self) {
          if (Math.fabs(self.value - player?.position) > 1) {
            player.position = self.value;
          }
        }

      [GtkCallback]
        protected string format_length() {
          return this.lengthStr(player?.length);
        }

      [GtkCallback]
        protected string format_position() {
          return this.lengthStr(player?.position);
        }

      [GtkCallback]
        protected void on_previous() {
          this.player?.previous();
        }

      [GtkCallback]
        protected void on_playpause() {
          this.player?.play_pause();
        }

      [GtkCallback]
        protected void on_next() {
          this.player?.next();
        }

      [GtkCallback]
        protected bool spacer_visible() {
          return player?.can_go_next == player?.can_go_previous;
        }

      private string lengthStr(double length) {
        if (length == -1) return "--:--";
        int min = (int) length / 60;
        int sec = (int) length % 60;
        return "%d:%02d".printf(min, sec);
      }

      private void on_player_added () {
        player = mpris.players.first().data;
        visible = true;
      }

      private void on_player_closed () {
        if (mpris.players.length() == 0) {
          visible = false;
          return;
        }

        on_player_added();
      }

      construct {
        if (cava == null)
          cava = AstalCava.get_default();
        if (mpris == null)
          mpris = AstalMpris.get_default();

        mpris.player_added.connect(on_player_added);
        mpris.player_closed.connect(on_player_closed);
        on_player_closed();

        cava_area.set_draw_func((self, cr, width, height) => {
            var fg = self.get_color();
            var values = cava.get_values();
            var bar_width = Math.floor((width - 2) / cava.bars);
            var line_width = Math.floor(bar_width / 2);

            cr.set_source_rgba(fg.red,fg.green,fg.blue,fg.alpha);
            cr.set_line_cap(Cairo.LineCap.ROUND);
            cr.set_line_width(line_width);

            var old_x = line_width;

            for (uint i = 0; i < cava.bars; i++) {
              var bar_height = (values.index(i) * (height - 2 * line_width)) / 3;
              var bar_y = Math.floor((height - 2 * line_width - bar_height) / 2);

              cr.move_to(old_x,bar_y);
              cr.line_to(old_x, bar_y + bar_height);
              cr.stroke();

              old_x += bar_width;
            }
        });

        cava.notify["values"].connect(() => {
            cava_area.queue_draw();
            });
      }

      public LockscreenMpris() {
        Object();
      }
    }
}

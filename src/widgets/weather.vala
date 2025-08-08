namespace libTrem {
  [GtkTemplate(ui = "/com/github/alvsz/libtrem/ui/weather.ui")]
    public class WeatherWidget : Gtk.Box {
      private string _app_id;
      private string _contact_info;

      public Weather weather { get; construct set; }
      public string app_id { get { return this._app_id; } set { this._app_id = value; try_to_get_weather.begin (); } }
      public string contact_info { get { return this._contact_info; } set { this._contact_info = value; try_to_get_weather.begin (); } }
      public bool auto_update { get; construct set; default = true; }

      public WeatherWidget (string app_id, string contact_info, bool? auto_update) {
        Object (app_id: app_id, contact_info: contact_info, auto_update: auto_update);
      }

      construct {
        if (weather != null) {
          weather.notify["available"].connect (() => {
            this.visible = weather.available;
          });
          this.visible = weather.available;
        } else
          try_to_get_weather.begin ();
      }

      private async void try_to_get_weather () {
        if (app_id == null || contact_info == null || weather != null) 
          return;

        weather = new Weather (app_id, contact_info, auto_update);

        weather.notify["available"].connect (() => {
          this.visible = weather.available;
        });
        this.visible = weather.available;
      }

      [GtkCallback]
        private string is_daytime() {
          return this.weather.is_daytime
            ? "daytime-sunset-symbolic"
            : "daytime-sunrise-symbolic";
        }

      [GtkCallback]
        private string is_not_daytime() {
          return this.weather.is_daytime
            ? "daytime-sunrise-symbolic"
            : "daytime-sunset-symbolic";
        }

      [GtkCallback]
        private string format_daytime() {
          var sunset = weather.sunset;
          var sunrise = weather.sunrise;

          return "%s - %s".printf(weather.is_daytime ? sunset : sunrise, weather.is_daytime ? sunrise : sunset);
        }
    }
}

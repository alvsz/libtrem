namespace libTrem {
  public class Weather: Object {
    private GWeather.Info info;
    private GClue.Simple simple;

    public double latitude { private set; public get; }
    public double longitude { private set; public get; }
    public string city_name { private set; public get; }
    public bool is_daytime { private set; public get; }
    public string wind { private set; public get; }
    public string sky { private set; public get; }
    public string last_updated { private set; public get; }
    public string temp { private set; public get; }
    public string temp_summary { private set; public get; }
    public string temp_min { private set; public get; }
    public string temp_max { private set; public get; }
    public string sunrise { private set; public get; }
    public string sunset { private set; public get; }
    public string icon_name { private set; public get; }
    public string humidity { private set; public get; }
    public string pressure { private set; public get; }
    public bool available { private set; public get; }
    public string app_id { public get; construct; }
    public string contact_info { get; construct; }

    public signal void location_updated(double latitude, double longitude);
    public signal void weather_updated();

    public Weather(string app_id, string contact_info) {
      Object(app_id: app_id, contact_info: contact_info);
    }

    construct {
      if (app_id == null)
        error("app_id não pode ser nulo");
      if (contact_info == null)
        error("contact_info não pode ser nulo");

      try {
        make_gclue_simple.begin();
      }
      catch (Error err) {
        warning ("Error: %s\n", err.message);
      }
    }

    private async void make_gclue_simple() throws Error {
        simple = yield new GClue.Simple (app_id,GClue.AccuracyLevel.EXACT,null);

        simple.notify["location"].connect(on_location_update);
        on_location_update();

        info.updated.connect(on_weather_update);
        on_weather_update(info);
    }

    private GWeather.Info get_weather_info(GWeather.Location l) {
      GWeather.Info i = new GWeather.Info(l);
      i.application_id = app_id;
      i.contact_info = contact_info;
      i.enabled_providers = GWeather.Provider.METAR | GWeather.Provider.MET_NO | GWeather.Provider.OWM;
      
      return i;
    }

    private void on_location_update() {
      GClue.Location l = simple.get_location();

      if (l == null) return;

      latitude = l.latitude;
      longitude = l.longitude;
      this.location_updated(latitude,longitude);

      GWeather.Location w = GWeather.Location.get_world();

      if (w == null) return;

      GWeather.Location city = w.find_nearest_city(latitude,longitude);

      if (city == null) return;

      if (info == null)
        info = get_weather_info(city);
      else
        info.set_location(city);

      city_name = city.get_name();
      info.update();
    }
    
    private void on_weather_update(GWeather.Info i) {
      bool network_error = i.network_error();
      available = !network_error;

      if (network_error) return;

      this.weather_updated();
    }
  }
}

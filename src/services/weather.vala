namespace libTrem {
  public class Weather: Object {
    public GWeather.Info info { get; private set; }
    public GClue.Simple simple { get; private set; }

    public double latitude { private set; get; }
    public double longitude { private set; get; }
    public string city_name { private set; get; }
    public bool is_daytime { private set; get; }
    public string wind { private set; get; }
    public string sky { private set; get; }
    public string last_updated { private set; get; }
    public string temp { private set; get; }
    public string temp_summary { private set; get; }
    public string temp_min { private set; get; }
    public string temp_max { private set; get; }
    public string sunrise { private set; get; }
    public string sunset { private set; get; }
    public string icon_name { private set; get; }
    public string humidity { private set; get; }
    public string pressure { private set; get; }
    public bool available { private set; get; default = false; }

    public string app_id { get; construct; }
    public string contact_info { get; construct; }
    public bool auto_update { get; set; default = false; }
    private uint update_source;

    public signal void location_updated(double latitude, double longitude);
    public signal void weather_updated();

    public Weather(string app_id, string contact_info, bool auto_update) {
      Object(app_id: app_id, contact_info: contact_info, auto_update: auto_update);
    }

    ~Weather() {
      if (auto_update)
        Source.remove(update_source);
    }

    construct {
      if (app_id == null)
        error("app_id não pode ser nulo");
      if (contact_info == null)
        error("contact_info não pode ser nulo");

      make_gclue_simple.begin((src, res) => {
        try {
          make_gclue_simple.end(res);
        } catch (Error err) {
          warning ("Error: %s\n", err.message);
        }
      });
    }

    private async void make_gclue_simple() throws Error {
      simple = yield new GClue.Simple (app_id,GClue.AccuracyLevel.EXACT,null);

      simple.notify["location"].connect(on_location_update);
      on_location_update();

      info.updated.connect(on_weather_update);
      on_weather_update(info);

      if (auto_update) 
        update_source = Timeout.add_seconds(60*60, () => {
            this.info.update();
            return auto_update ? Source.CONTINUE : Source.REMOVE;
            });
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

      is_daytime = info.is_daytime();
      wind = info.get_wind();
      sky = info.get_sky();
      last_updated = info.get_update();
      temp = info.get_temp();
      temp_summary = info.get_temp_summary();
      temp_min = info.get_temp_min();
      temp_max = info.get_temp_max();
      sunrise = info.get_sunrise();
      sunset = info.get_sunset();
      icon_name = info.get_icon_name();
      humidity = info.get_humidity();
      pressure = info.get_pressure();

      this.weather_updated();
    }
  }
}

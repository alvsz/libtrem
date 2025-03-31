namespace libTrem {
  public class Weather: Object {
    private bool _available = false;
    private double _latitude = 0;
    private double _longitude = 0;
    private string _city_name = "";

    private GWeather.Info _info;
    private GClue.Simple _simple;
    private GClue.Location _location;

    private void _onLocationUpdate(GWeather.Location l) {
      if (l == null || !l.has_coords()) return;

      // _latitude = l.
      GWeather.Location w = GWeather.Location.get_world();

      if (w == null) return;

      l.get_coords(out _latitude, out _longitude);
      GWeather.Location city = w.find_nearest_city(_latitude,_longitude);

      if (city == null) return;

      if (_info == null)
        _info = new GWeather.Info(city);
      else
        _info.set_location(city);

      _city_name = city.get_name();
      _info.update();
    }
    
    private void _onWeatherUpdate(GWeather.Info i) {
      bool network_error = i.network_error();
      _available = !network_error;

      if (network_error) return;

      print(i.get_temp_summary());
    }

    async Weather(string app_id) {
      try {
        _simple = yield new GClue.Simple (app_id,GClue.AccuracyLevel.EXACT,null);
        _location = _simple.get_location ();

        if (_location == null) return;

        _location.connect ("notify",this._onLocationUpdate);
        _info.connect("updated",this._onWeatherUpdate);
      }
      catch (Error err) {
        warning ("Error: %s\n", err.message);
      }
      // _info = new GWeather.Info
    }
  }
}

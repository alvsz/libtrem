namespace libTrem {
  public class VPNRequestHandler : Object {

  }

  public class NetworkSecretDialog : Object {

  }

  public class NetworkSecretHandler : Object {
    public string app_id { get; construct; }
    public NetworkAgent native { get; private set; }
    private List<NetworkSecretDialog> dialogs;
    private List<VPNRequestHandler> vpn_requests;
    public bool initialized = false;

    public NetworkSecretHandler (string application_id) {
      Object (app_id: application_id);
    }

    construct {
      if (app_id == null)
        error ("app_id não pode ser nulo");

      native = (NetworkAgent) Object.new (typeof (NetworkAgent), "identifier", app_id, "capabilities", NM.SecretAgentCapabilities.VPN_HINTS, "auto_register", true, null);

      native.new_request.connect (new_request);
      native.cancel_request.connect (cancel_request);

      init_native.begin ();
    }

    private async void init_native () {
      try {
        initialized = yield native.init_async(Priority.DEFAULT, null);
      } catch (Error e) {
        warning ("Error: %s", e.message);
      }
    }

    public void enable () {
      if (initialized && !native.registered)
        native.register_async.begin (null);
    }

    public void disable () {

    }

    private void new_request (NetworkAgent source,
                              string path,
                              NM.Connection connection,
                              string setting_name,
                              List<string> hints,
                              int request_flags) {

    }

    private void cancel_request (string path) {

    }
  }
}


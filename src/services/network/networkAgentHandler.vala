namespace libTrem {
  public class VPNRequestHandler : Object {

  }

  public class NetworkSecretDialog : Object {

  }

  public class NetworkSecretHandler : Object {
    public NetworkAgent native { get; private set; }
    private List<NetworkSecretDialog> dialogs;
    private List<VPNRequestHandler> vpn_requests;
    public bool initialized = false;
  }
}


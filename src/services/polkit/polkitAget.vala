namespace libTrem {
  public class PolkitAuthenticationAgent : PolkitAgent.Listener {
    public async override bool initiate_authentication (string action_id, string message, string icon_name, Polkit.Details details, string cookie, GLib.List<Polkit.Identity> identities, GLib.Cancellable? cancellable) {

return true;
    }
  }
}

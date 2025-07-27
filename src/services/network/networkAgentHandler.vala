namespace libTrem {
  public delegate bool ValidateNetworkSecret (NetworkSecret secret);

  public class NetworkSecret : Object {
    public string label { get; private set; }
    public string? key { get; private set; }
    public string val { get; set; }
    public uint? wep_key_type { get; private set; }
    public unowned ValidateNetworkSecret? validate;
    public bool password { get; private set; }
    public bool valid { get; set; default = false; }

    internal NetworkSecret (string label, string? key, string val, NM.WepKeyType? wep_key_type, ValidateNetworkSecret? validate, bool password) {
      this.label = label;
      this.key = key;
      this.val = val;
      this.wep_key_type = wep_key_type;
      this.validate = validate;
      this.password = password;
    }
  }

  internal class NetworkSecretDialogContent : Object {
    public string title;
    public string? message;
    public List<NetworkSecret> secrets;

    internal NetworkSecretDialogContent() {
      secrets = new List<NetworkSecret> ();
    }
  }

  public class VPNRequestHandler : Object {
    internal VPNRequestHandler (NetworkAgent agent, string request_id, string service_type, NM.Connection connection, List<string> hints, int flags) {

    }
  }

  public class NetworkSecretDialog : Object {
    public NetworkAgent agent { get; private set; }
    public string request_id { get; private set; }
    public unowned NM.Connection connection { get; private set; }
    public string setting_name { get; private set; }
    public unowned List<string> hints { get; private set; }
    public int flags { get; private set; }

    private NetworkSecretDialogContent content;

    public string title { get { return content.title; }  }
    public string message { get { return content.message; } }
    public List<weak NetworkSecret> secrets { owned get { return content.secrets.copy(); } }

    public signal void done (bool cancelled);

    internal NetworkSecretDialog (NetworkAgent agent, string request_id, NM.Connection connection, string setting_name, List<string> hints, int flags, NetworkSecretDialogContent? content_override) {
      this.agent = agent;
      this.request_id = request_id;
      this.connection = connection;
      this.setting_name = setting_name;
      this.hints = hints.copy_deep ((s) => {
        return s.dup ();
      });
      this.flags = flags;

      if (content_override != null)
        this.content = content_override;
      else
        this.content = get_content ();

      notify_property ("title");
      notify_property ("message");
      notify_property ("secrets");
    }

    public void cancel () {
      this.agent.respond (this.request_id, NetworkAgentResponse.USER_CANCELED);
      this.done (true);
    }

    public void authenticate (List<NetworkSecret> secrets) {
      var valid = true;
      foreach (var secret in secrets) {
        valid = valid && secret.valid;
        if (secret.key != null) {
          if (setting_name == NM.SettingVpn.SETTING_NAME)
            agent.add_vpn_secret (request_id, secret.key, secret.val);
          else
            agent.set_password (request_id, secret.key, secret.val);
        }
      }
      
      if (valid) {
        agent.respond (request_id, libTrem.NetworkAgentResponse.CONFIRMED);
        done (false);
      }
    }

    private NetworkSecretDialogContent get_content () {
      var connection_setting = connection.get_setting_connection ();
      var connection_type = connection_setting.get_connection_type ();
      var content = new NetworkSecretDialogContent ();

      switch (connection_type) {
        case NM.SettingWireless.SETTING_NAME:
          var wireless_setting = connection.get_setting_wireless ();

          var ssid = NM.Utils.ssid_to_utf8 (wireless_setting.get_ssid().get_data());
          content.title = "Autenticação necessária";
          content.message = "Senhas ou chaves criptografadas são necessárias para acessar a rede sem fio \"%s\"".printf (ssid);

          get_wireless_secrets (content.secrets, wireless_setting);
          break;
        case NM.SettingWired.SETTING_NAME:
          content.title = "Autenticação 802.1X com cabo";
          content.message = null;
          content.secrets.append (new NetworkSecret ("Nome da rede", null, connection_setting.get_id (), null, null, false));

          get_8021x_secrets (content.secrets);
          break;
        case NM.SettingPppoe.SETTING_NAME:
          content.title = "Autenticação DSL";
          content.message = null;

          get_pppoe_secrets (content.secrets);
          break;
        case NM.SettingGsm.SETTING_NAME:
          if (hints.find ("pin") != null) {
            var gsm_setting = connection.get_setting_gsm ();
            content.title = "Código PIN necessário";
            content.message = "O código PIN é necessário para o dispositivo móvel de banda larga";

            content.secrets.append(new NetworkSecret ("PIN", "pin", gsm_setting.get_pin () ?? "", null, null, true));
          }
          break;
        case NM.SettingCdma.SETTING_NAME:
          //fall through
        case NM.SettingBluetooth.SETTING_NAME:
          content.title = "Autenticação necessária";
          content.message = "Uma senha é necessária para se conectar a \"%s\"".printf (connection_setting.get_id ());

          get_mobile_secrets (content.secrets, connection_type);
          break;
        default:
          warning ("invalid connection type: %s\n", connection_type);
          break;
      }

      return (owned)content;
    }

    private void get_wireless_secrets (List<NetworkSecret> secrets, NM.SettingWireless setting) {
      var wireless_security_setting = connection.get_setting_wireless_security ();

      if (setting_name == NM.Setting8021x.SETTING_NAME) {
        get_8021x_secrets (secrets);
        return;
      }

      switch (wireless_security_setting.key_mgmt) {
        case "wpa-none":
        case "wpa-psk":
        case "sae":
          secrets.append (new NetworkSecret ("Senha",
                                             "psk",
                                             wireless_security_setting.get_psk () ?? "",
                                             null,
                                             validate_wpa_psk,
                                             true));
          break;
        case "none":
          var idx = wireless_security_setting.get_wep_tx_keyidx ();
          secrets.append (new NetworkSecret ("Chave",
                                             "wep-key%u".printf (idx), wireless_security_setting.get_wep_key (idx) ?? "",
                                             wireless_security_setting.get_wep_key_type (),
                                             validade_static_wep,
                                             true));
          break;
        case "ieee8021x":
          if (wireless_security_setting.get_auth_alg () == "leap") {
            secrets.append (new NetworkSecret("Senha",
                  "leap-password",
                  wireless_security_setting.get_leap_password () ?? "",
                  null,
                  null,
                  true));
          } else {
            get_8021x_secrets (secrets);
          }
          break;
        case "wpa-eap":
          get_8021x_secrets (secrets);
          break;
        default:
          warning ("Invalid wireless key management: %s", wireless_security_setting.key_mgmt);
          break;
      }
    }

    private void get_8021x_secrets (List<NetworkSecret> secrets) {
      var ieee_802_1x_setting = connection.get_setting_802_1x ();

      if (setting_name == NM.Setting8021x.SETTING_NAME && hints.length () > 0) {
        if (hints.find ("identity") != null)
          secrets.append (new NetworkSecret ("Nome de usuário", "identity", ieee_802_1x_setting.get_identity () ?? "", null, null, false));
        if (hints.find ("password") != null)
          secrets.append (new NetworkSecret ("Senha", "password", ieee_802_1x_setting.get_password () ?? "", null, null, true));
        if (hints.find ("private-key-password") != null)
          secrets.append (new NetworkSecret("Senha da chave privada", "private-key-password", ieee_802_1x_setting.get_private_key_password () ?? "", null, null, true));

        return;
      }

      switch (ieee_802_1x_setting.get_eap_method (0)) {
        case "md5":
        case "leap":
        case "ttls":
        case "peap":
        case "fast":
          secrets.append(new NetworkSecret("Nome de usuário",null, ieee_802_1x_setting.get_identity () ?? "", null, null, false));
          secrets.append(new NetworkSecret("Senha", "password", ieee_802_1x_setting.get_password () ?? "", null, null, true));
          break;
        case "tls":
          secrets.append(new NetworkSecret("Identidade", null, ieee_802_1x_setting.get_identity () ?? "", null, null, false));
          secrets.append(new NetworkSecret("Senha da chave privada", "private-key-password", ieee_802_1x_setting.get_private_key_password () ?? "", null, null, true));
          break;
        default:
          warning ("Invalid EAP/IEEE802.1x method: %s", ieee_802_1x_setting.get_eap_method (0));
          break;
      }
    }

    private void get_pppoe_secrets (List<NetworkSecret> secrets) {
      var pppoe_setting = connection.get_setting_pppoe ();

      secrets.append(new NetworkSecret("Nome de usuário","username", pppoe_setting.get_username () ?? "", null, null, false));
      secrets.append(new NetworkSecret("Serviço","service", pppoe_setting.get_service () ?? "", null, null, false));
      secrets.append(new NetworkSecret("Senha","password", pppoe_setting.get_password () ?? "", null, null, true));
    }

    private void get_mobile_secrets (List<NetworkSecret> secrets, string connection_type) {
      string password;
      var cdma = connection.get_setting_cdma ();

      if (connection_type == NM.SettingBluetooth.SETTING_NAME && cdma == null)
        password = connection.get_setting_gsm ().get_password ();
      else
        password = cdma.get_password ();
      
      secrets.append(new NetworkSecret ("Senha", "password", password ?? "", null, null, true));
    }

    private bool validate_wpa_psk (NetworkSecret secret) {
      var val = secret.val;
      if (val.length == 64) {
        foreach (var c in val.to_utf8 ()) 
          if (!(c.isxdigit ()))
            return false;

        return true;
      }
      return val.length >= 8 && val.length <= 63;
    }

    private bool validade_static_wep (NetworkSecret secret) {
      var val = secret.val;
      if (secret.wep_key_type == NM.WepKeyType.KEY) {
        if (val.length == 10 || val.length == 26) {
          foreach (var c in val.to_utf8 ()) 
            if (!(c.isxdigit ()))
              return false;
        } else if (val.length == 5 || val.length == 13) {
          foreach (var c in val.to_utf8 ()) 
            if (!(c.isalpha ()))
              return false;
        } else {
          return false;
        }
      } else if (secret.wep_key_type == NM.WepKeyType.PASSPHRASE) {
        return val.length > 0 && val.length < 64;
      }
      return true;
    }
  }

  public class NetworkSecretHandler : Object {
    public string app_id { get; construct; }
    public NetworkAgent native { get; private set; }
    private HashTable<string, NetworkSecretDialog> dialogs = new HashTable<string, NetworkSecretDialog> (str_hash, str_equal);
    private HashTable<string, VPNRequestHandler> vpn_requests = new HashTable<string, VPNRequestHandler> (str_hash, str_equal);
    public bool initialized = false;

    public signal void initiate (NetworkSecretDialog dialog);

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
                              string request_id,
                              NM.Connection connection,
                              string setting_name,
                              List<string> hints,
                              NM.SecretAgentGetSecretsFlags request_flags) {
      if ((request_flags & NM.SecretAgentGetSecretsFlags.USER_REQUESTED) == 0)
        show_notification (request_id, connection, setting_name, hints, request_flags);
      else
        handle_request (request_id, connection, setting_name, hints, request_flags);
    }

    private void show_notification (string request_id,
                                    NM.Connection connection,
                                    string setting_name,
                                    List<string> hints,
                                    int request_flags) {
      printerr ("notif\n");
    }

    private void handle_request (string request_id,
                                 NM.Connection connection,
                                 string setting_name,
                                 List<string> hints,
                                 int request_flags) {
      if (setting_name == NM.SettingVpn.SETTING_NAME) {
        handle_vpn_request (request_id, connection, hints, request_flags);
        return;
      }

      var dialog = new NetworkSecretDialog (native, request_id, connection, setting_name, hints, request_flags, null);
      dialog.done.connect (() => {
        dialogs.remove (request_id);
      });
      dialogs.insert (request_id, dialog);
      initiate (dialog);
    }

    private void handle_vpn_request (string request_id, NM.Connection connection, List<string> hints, int request_flags) {
      string path;
      bool supports_hints, external_ui;
      var vpn_setting = connection.get_setting_vpn ();
      var service_type = vpn_setting.get_service_type ();

      if(!find_auth_binary (service_type, out path, out supports_hints, out external_ui)) {
        printerr ("Invalid VPN service type (cannot find authentication binary)\n");
        this.native.respond (request_id, NetworkAgentResponse.INTERNAL_ERROR);
        return;
      }

      var request = new VPNRequestHandler (native,request_id, service_type, connection, hints, request_flags);
      this.vpn_requests.set (request_id, request);
    }

    private bool find_auth_binary (string service_type, out string path, out bool supports_hints, out bool external_ui_mode) {
      path = "";
      supports_hints = false;
      external_ui_mode = false;
      string[] valores_validos = { "true", "yes", "on", "1" };

      try {
        var plugin = native.search_vpn_plugin (service_type);
        var file_name = plugin.get_auth_dialog ();

        if (!GLib.FileUtils.test (file_name, GLib.FileTest.IS_EXECUTABLE)) {
          warning ("VPN plugin em %s não é executável", file_name);
          return false;
        }

        var prop = plugin.lookup_property ("GNOME", "supports-external-ui-mode");
        var trimmed_prop = prop.strip ().down ();

        path = file_name;
        supports_hints = plugin.supports_hints ();

        foreach (var s in valores_validos)
          if (trimmed_prop == s)
            external_ui_mode = true;
      } catch (Error e) {
        printerr ("Erro: %s\n", e.message);
        return false;
      }
      return false;
    }

    private void cancel_request (NetworkAgent source, string request_id) {
      var dialog = dialogs.get (request_id);
      var vpn = vpn_requests.get (request_id);

      if (dialog != null) {
        dialog.cancel ();
        dialogs.remove (request_id);
      } else if (vpn != null) {
        vpn_requests.remove (request_id);
      }
    }
  }
}


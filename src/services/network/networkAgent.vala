/*
 * Copyright 2011 Red Hat, Inc.
 *           2011 Giovanni Campagna <scampa.giovanni@gmail.com>
 *           2017 Lubomir Rintel <lkundrak@v3.sk>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

[CCode (cheader_filename = "NetworkManager.h,nm-secret-agent-old.h,libsecret/secret.h")]
namespace libTrem {
  public enum NetworkAgentResponse {
    CONFIRMED,
    USER_CANCELED,
    INTERNAL_ERROR
  }

  public class AgentRequest : Object {
    public Cancellable? cancellable;
    public NetworkAgent self;

    public string request_id;
    public NM.Connection connection;
    public string setting_name;
    public List<string> hints;
    public NM.SecretAgentGetSecretsFlags flags;
    public unowned NM.SecretAgentOldGetSecretsFunc callback;

    public VariantDict entries;
    public VariantBuilder builder_vpn;

    public AgentRequest(NetworkAgent self, string request_id, NM.Connection connection, string setting_name, string[] hints, NM.SecretAgentGetSecretsFlags flags, NM.SecretAgentOldGetSecretsFunc callback) {
      self.ref ();
      connection.ref ();
      this.self = self;
      this.builder_vpn = new VariantBuilder(new VariantType("a{ss}"));
      this.entries = new VariantDict(null);
      this.request_id = request_id.dup ();
      this.connection = connection;
      this.setting_name = setting_name.dup ();
      this.flags = flags;
      this.callback = callback;
      this.cancellable = new Cancellable ();
      this.hints = new List<string> ();

      foreach (var hint in hints) {
        this.hints.append (hint.dup ());
      }
    }

    ~AgentRequest() {
      this.cancellable.cancel ();
      this.self.unref ();
      this.connection.unref ();
    }

    public void cancel() {
      var error = new NM.SecretAgentError.AGENTCANCELED ("Canceled by NetworkManager");
      this.callback (self,connection,null,error);
      self.cancel_request (request_id);
      self.requests.remove (request_id);
    }
  }

  public class KeyringRequest : Object {
    public int n_secrets = 0;
    public NM.SecretAgentOld self;
    public NM.Connection connection;
    public unowned NM.SecretAgentOldDeleteSecretsFunc callback;

    public KeyringRequest(NM.SecretAgentOld self, NM.Connection connection,
        NM.SecretAgentOldDeleteSecretsFunc callback) {
      self.ref ();
      connection.ref ();
      this.self = self;
      this.connection = connection;
      this.callback = callback;
    }

    ~KeyringRequest() {
      this.self.unref ();
      this.connection.unref ();
    }
  }


  public class NetworkAgent : NM.SecretAgentOld {
    internal static Secret.Schema schema;
    internal static string UUID_TAG = "connection-uuid";
    internal static string SN_TAG = "setting-name";
    internal static string SK_TAG = "setting-key";

    internal HashTable<string, AgentRequest> requests = new HashTable<string, AgentRequest>(str_hash, str_equal);
    public signal void new_request(string path,
                                   NM.Connection connection,
                                   string setting_name,
                                   List<string> hints,
                                   NM.SecretAgentGetSecretsFlags request_flags);
    public signal void cancel_request(string path);

    construct {

    }

    ~NetworkAgent() {
      requests.foreach ((id, request) => {
        var err = new NM.SecretAgentError.AGENTCANCELED ("The secret agent is going away");
        request.callback (this, request.connection, null, err);
      });
    }

    static construct {
      var attributes = new HashTable<string, Secret.SchemaAttributeType>(str_hash,str_equal);
      attributes.insert (UUID_TAG,Secret.SchemaAttributeType.STRING);
      attributes.insert (SN_TAG,Secret.SchemaAttributeType.STRING);
      attributes.insert (SK_TAG,Secret.SchemaAttributeType.STRING);

      schema = new Secret.Schema.newv ("org.freedesktop.NetworkManager.Connection",
                                       Secret.SchemaFlags.DONT_MATCH_NAME,
                                       attributes);
    }

    internal static HashTable<string,string> create_keyring_add_attr_list (NM.Connection connection,
                                                                    string connection_uuid,
                                                                    string connection_id,
                                                                    string setting_name,
                                                                    string setting_key,
                                                                    out string display_name) {
      NM.SettingConnection s_con;

      if (connection != null) {
        s_con = connection.get_setting_connection ();
        return_val_if_fail (s_con != null, null);
        connection_uuid = s_con.get_uuid ();
        connection_id = s_con.get_id ();
      }

      return_val_if_fail (connection_uuid != null, null);
      return_val_if_fail (connection_id != null, null);
      return_val_if_fail (setting_name != null, null);
      return_val_if_fail (setting_key != null, null);

      display_name = "Network secret for %s/%s/%s".printf (connection_id,setting_name,setting_key);

      return Secret.attributes_build (schema, UUID_TAG, connection_uuid, SN_TAG, setting_name, SK_TAG, setting_key);
    }

    internal static void save_one_secret (KeyringRequest r, NM.Setting setting, string key, string secret, string display_name) {
      string alt_display_name;
      var secret_flags = NM.SettingSecretFlags.NONE;

      try {
        nm_setting_get_secret_flags_fixed (setting,key,out secret_flags);
      } catch (Error e) {
        warning ("Error: %s", e.message);
      }

      if (secret_flags != NM.SettingSecretFlags.AGENT_OWNED)
        return;

      var setting_name = setting.get_name ();

      var attrs = create_keyring_add_attr_list (r.connection,null,null,setting_name,key,out alt_display_name);

      if (attrs == null)
        return;

      r.n_secrets++;

      Secret.password_storev.begin (schema,attrs,Secret.COLLECTION_DEFAULT,display_name != null ? display_name : alt_display_name, secret, null, (source,result) => {
        r.n_secrets--;

        if (r.n_secrets == 0) {
          if (r.callback != null)
            r.callback (r.self,r.connection,null);
        }
      });
    }

    internal static bool has_always_ask (NM.Setting setting) {
      var always_ask = false;

      setting.enumerate_values ((self,key,value,flags) => {
        var secret_flags = NM.SettingSecretFlags.NONE;

        try {
          if ((flags & NM.Setting.SECRET) != 0) 
            if (nm_setting_get_secret_flags_fixed (self,key,out secret_flags))
              if ((secret_flags & NM.SettingSecretFlags.NOT_SAVED) != 0)
                always_ask = true;
        } catch (Error e) {
          always_ask = false;
        }
      });

      return always_ask;
    }

    internal static bool is_connection_always_ask (NM.Connection connection) {
      var s_con = connection.get_setting_connection ();
      assert (s_con != null);

      var ctype = s_con.get_connection_type();
      var setting = connection.get_setting_by_name(ctype);
      return_val_if_fail (setting != null, false);

      if (has_always_ask(setting)) {
        return true;
      }

      if (setting is NM.SettingWireless) {
        setting = connection.get_setting_wireless_security ();
        if (setting != null && has_always_ask(setting)) {
          return true;
        }
        setting = connection.get_setting_802_1x ();
        if (setting != null && has_always_ask(setting)) {
          return true;
        }
      } else if (setting is NM.SettingWired) {
        setting = connection.get_setting_pppoe ();
        if (setting != null && has_always_ask(setting)) {
          return true;
        }
        setting = connection.get_setting_802_1x ();
        if (setting != null && has_always_ask(setting)) {
          return true;
        }
      }

      return false;
    }

    private void request_secrets_from_ui (AgentRequest request) {
      printerr("sending new request\n\t%s, %s, %d %u\n\n",request.request_id,request.setting_name,request.flags,request.hints.length ());
      new_request (request.request_id,request.connection,request.setting_name,request.hints,request.flags);
    }

    public override void save_secrets (NM.Connection connection,
                                       string connection_path,
                                       NM.SecretAgentOldSaveSecretsFunc callback) {
      var r = new KeyringRequest (this,connection,callback);

      base.delete_secrets (connection,connection_path,(agent,conn,err) => {
        conn.for_each_setting_value ((setting,key,value,flags) => {
          if ((flags & NM.Setting.SECRET) == 0)
            return;

            if (setting is NM.SettingVpn && key == NM.SettingVpn.SECRETS) {
              ((NM.SettingVpn)setting).foreach_secret ((key,secret) => {
                if (secret != null && secret.length > 0) {
                  var service_name = ((NM.SettingVpn)setting).get_service_type ();
                  var id = conn.get_id ();
                  var display_name = "VPN %s secret for %s/%s/%s".printf (key,id,service_name,NM.SettingVpn.SETTING_NAME);
                  save_one_secret (r,setting,key,secret,display_name);
                }
              });
            } else {
              if (!value.holds (GLib.Type.STRING))
                return;

              var secret = value.get_string ();
              if (secret != null && secret.strip () != "")
                save_one_secret (r,setting,key,secret,null);
            }
        });

        if (r.n_secrets == 0) 
          if (r.callback != null)
            r.callback (agent,conn, null);
      }); 
    }

    public override void get_secrets (NM.Connection connection,
                                      string connection_path,
                                      string setting_name,
                                      string[] hints,
                                      NM.SecretAgentGetSecretsFlags flags,
                                      NM.SecretAgentOldGetSecretsFunc callback) {
      var request_id = "%s/%s".printf (connection_path,setting_name);
      var request = requests.lookup (request_id);

      if (request != null)
        request.cancel ();

      var request_new = new AgentRequest (this,request_id,connection,setting_name,hints,flags,callback);

      requests.replace (request_id,request_new);

      if ((flags & NM.SecretAgentGetSecretsFlags.REQUEST_NEW) != 0 ||
          ((flags & NM.SecretAgentGetSecretsFlags.ALLOW_INTERACTION) != 0 &&
           is_connection_always_ask (connection)))
        request_secrets_from_ui (request_new);

      var attributes = Secret.attributes_build (schema,UUID_TAG,connection.get_uuid (),SN_TAG,setting_name);
      AgentRequest request_ref = (AgentRequest)request_new.ref ();


      secret_service_search.begin (null, schema, attributes, Secret.SearchFlags.ALL | Secret.SearchFlags.UNLOCK | Secret.SearchFlags.LOAD_SECRETS, request_ref.cancellable, (source, res) => {
        unowned List<Secret.Item> items;
          
        try {
          items = secret_service_search_finish ((Secret.Service)source, res);
          printerr ("sync terminou %u\n", items.length ());
        } catch (IOError.CANCELLED e) {
          return;
        } catch (Error e) {
          var error = new  NM.SecretAgentError.FAILED("Internal error while retrieving secrets from the keyring (%s)", e.message);
          request_ref.callback (request_ref.self, request_ref.connection, null, error);
          requests.remove (request_ref.request_id);
          return;
        }
        VariantBuilder builder_setting = new VariantBuilder(VariantType.VARDICT);
        bool secrets_found = false;

        foreach (var item in items) {
          var secret = item.get_secret ();

          if (secret == null)
            continue;

          var attr = item.get_attributes ();
          foreach (var name in attr.get_keys ()) {
            if (name == SK_TAG) {
              builder_setting.add ("{sv}",attributes[name],new Variant.variant  (secret.get_text ()));
              secrets_found = true;
              break;
            }
          }
        }

        var setting = builder_setting.end ();

        if (request_ref.setting_name == NM.SettingVpn.SETTING_NAME || (!secrets_found && ((request_ref.flags & NM.SecretAgentGetSecretsFlags.ALLOW_INTERACTION) != 0 ))) {
          try {
            request_ref.connection.update_secrets (request_ref.setting_name, setting);
          } catch (Error e) {}
          request_secrets_from_ui (request_ref);
          return;
        }

        var builder_connection = new VariantBuilder (new VariantType (("a{sa{sv}}")));
        builder_connection.add ("{s@a{sv}}",request_ref.setting_name,setting);
        request_ref.callback (request_ref.self, request_ref.connection, builder_connection.end (), null);

        request_ref.unref ();
      });
    }

    public override void cancel_get_secrets (string connection_path, string setting_name) {
      var request_id = "%s/%s".printf (connection_path,setting_name);
      var request = requests.lookup (request_id);

      if (request == null)
        return;

      request.cancel ();
    }

    public override void delete_secrets (NM.Connection connection, string connection_path, NM.SecretAgentOldDeleteSecretsFunc callback) {
      var s_con = connection.get_setting_connection ();

      assert(s_con != null);
      var uuid = s_con.get_uuid();
      assert(uuid != null);

      var attributes = new HashTable<string, string>(str_hash,str_equal);
      attributes.insert (UUID_TAG,uuid);


        Secret.password_clearv.begin (schema, attributes, null, (obj,res) => {
          try {
            Secret.password_clear.end (res);
            callback(this,connection,null);
          } catch (Error e) {
            var err = new NM.SecretAgentError.FAILED ("The request could not be completed. Keyring result: %s", e.message);
            callback(this,connection,err);
          }
        });
    }

    public void add_vpn_secret (string request_id, string setting_key, string setting_value) {
      return_if_fail (this is NetworkAgent);

      var request = requests.lookup (request_id);
      return_if_fail (request != null);

      request.builder_vpn.add ("{ss}", setting_key, setting_value);  
    }

    public void set_password (string request_id, string setting_key, string setting_value) {
      return_if_fail (this is NetworkAgent);

      var request = requests.lookup (request_id);
      return_if_fail (request != null);

      request.entries.insert (setting_key, "s", setting_value);
    }

    public void respond (string request_id, NetworkAgentResponse response) {
      return_if_fail (this is NetworkAgent);

      var request = requests.lookup (request_id);
      return_if_fail (request != null);

      if (response == NetworkAgentResponse.USER_CANCELED) {
        var error = new NM.SecretAgentError.USERCANCELED("Network dialog was canceled by the user");
        request.callback(this,request.connection,null,error);
        requests.remove (request_id);
        return;
      }

      if (response == NetworkAgentResponse.INTERNAL_ERROR) {
        var error = new NM.SecretAgentError.FAILED("An internal error occurred while processing the request.");
        request.callback(this,request.connection,null,error);
        requests.remove (request_id);
        return;
      }

      var vpn_secrets = request.builder_vpn.end ();

      if (vpn_secrets.n_children () > 0)
        request.entries.insert_value (NM.SettingVpn.SECRETS, vpn_secrets);

      var setting = request.entries.end ();
      
      if ((request.flags & NM.SecretAgentGetSecretsFlags.ALLOW_INTERACTION) != 0 || (request.flags & NM.SecretAgentGetSecretsFlags.REQUEST_NEW) != 0) {
        var dup = NM.SimpleConnection.new_clone (request.connection);
        try {
          dup.update_secrets (request.setting_name, setting);
          base.save_secrets (dup,null,null);
        } catch (Error e) {}
      }

      var builder_connection = new VariantBuilder (new VariantType (("a{sa{sv}}")));
      builder_connection.add ("{s@a{sv}}", request.setting_name, setting);

      request.callback (this, request.connection, builder_connection.end (), null);

      requests.remove (request_id);
    }

    public NM.VpnPluginInfo search_vpn_plugin (string service) throws Error {
      var info = new NM.VpnPluginInfo.search_file (null, service);

      if (info != null)
        return info;
      else
        throw new IOError.NOT_FOUND ("No plugin for %s", service);
    }
  }
}


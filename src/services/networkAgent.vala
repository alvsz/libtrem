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

[CCode (cheader_filename = "NetworkManager.h,nm-secret-agent-old.h")]
namespace libTrem {
  public class AgentRequest : Object {
      public Cancellable? cancellable;
      public NetworkAgent self;

      public string request_id;
      public NM.Connection connection;
      public string setting_name;
      public string[] hints;
      public NM.SecretAgentGetSecretsFlags flags;
      public NM.SecretAgentOldGetSecretsFunc callback;
      public void* callback_data;

      public VariantDict entries;
      public VariantBuilder builder_vpn;

      public AgentRequest(NetworkAgent self) {
          this.self = self;
          this.builder_vpn = new VariantBuilder(new VariantType("a{sv}"));
          this.entries = new VariantDict(null);
      }

      ~AgentRequest() {
          // liberação implícita pela GC
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
    public NM.SecretAgentOldDeleteSecretsFunc callback;

    public KeyringRequest(NM.SecretAgentOld self, NM.Connection connection,
        NM.SecretAgentOldDeleteSecretsFunc callback) {
      this.self = self;
      this.connection = connection;
      this.callback = callback;
    }
  }


  public class NetworkAgent : NM.SecretAgentOld {
    internal static Secret.Schema schema;
    internal static string UUID_TAG = "connection-uuid";
    internal static string SN_TAG = "setting-name";
    internal static string SK_TAG = "setting-key";

    internal HashTable<string, AgentRequest> requests;
    public signal void new_request(string path, NM.Connection connection, string setting_name, string[] hints, int request_flags);
    public signal void cancel_request(string path);

    public NetworkAgent() {

    }

    static construct {
      var attributes = new HashTable<string, Secret.SchemaAttributeType>(str_hash,str_equal);
      attributes.insert (UUID_TAG,Secret.SchemaAttributeType.STRING);
      attributes.insert (SN_TAG,Secret.SchemaAttributeType.STRING);
      attributes.insert (SK_TAG,Secret.SchemaAttributeType.STRING);
      schema = new Secret.Schema.newv ("org.freedesktop.NetworkManager.Connection",Secret.SchemaFlags.DONT_MATCH_NAME,attributes);
    }

    internal HashTable<string,string> create_keyring_add_attr_list (NM.Connection connection, string connection_uuid, string connection_id, string setting_name, string setting_key, out string display_name) {
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

    internal void save_one_secret (KeyringRequest r, NM.Setting setting, string key, string secret, string display_name) {
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

    public override void save_secrets (NM.Connection connection, string connection_path, NM.SecretAgentOldSaveSecretsFunc callback) {
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

    public override void get_secrets (NM.Connection connection, string connection_path, string setting_name, string[] hints, NM.SecretAgentGetSecretsFlags flags, NM.SecretAgentOldGetSecretsFunc callback) {

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
  }
}


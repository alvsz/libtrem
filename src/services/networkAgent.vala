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

  public class KeyringRequest : Object {
    public int n_secrets = 0;
    public NM.SecretAgentOld self;
    public NM.Connection connection;
    public NM.SecretAgentOldDeleteSecretsFunc callback;
    public void* callback_data;

    public KeyringRequest(NM.SecretAgentOld self, NM.Connection connection,
        NM.SecretAgentOldDeleteSecretsFunc callback, void* callback_data) {
      this.self = self;
      this.connection = connection;
      this.callback = callback;
      this.callback_data = callback_data;
    }
  }


  public class ShellNetworkAgent : NM.SecretAgentOld {
    internal static Secret.Schema schema;
    internal static string UUID_TAG = "connection-uuid";
    internal static string SN_TAG = "setting-name";
    internal static string SK_TAG = "setting-key";

    static construct {
      var attributes = new HashTable<string, Secret.SchemaAttributeType>(str_hash,str_equal);
      attributes.insert (UUID_TAG,Secret.SchemaAttributeType.STRING);
      attributes.insert (SN_TAG,Secret.SchemaAttributeType.STRING);
      attributes.insert (SK_TAG,Secret.SchemaAttributeType.STRING);
      schema = new Secret.Schema.newv ("org.freedesktop.NetworkManager.Connection",Secret.SchemaFlags.DONT_MATCH_NAME,attributes);
    }

    public signal void new_request(string path, NM.Connection connection, string setting_name, string[] hints, int request_flags);
    public signal void cancel_request(string path);

    public ShellNetworkAgent() {

    }

    public override void save_secrets (NM.Connection connection, string connection_path, NM.SecretAgentOldSaveSecretsFunc callback) {
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
                  warning (display_name);
                  //save one secret
                }
              });
            } else {
              if (!value.holds (GLib.Type.STRING))
                return;

              var secret = value.get_string ();
              if (secret != null && secret.strip () != "")
                warning ("coisou aqui");
                //save one secret
            }
        });
      }); 
    }

    public override void get_secrets (NM.Connection connection, string connection_path, string setting_name, string[] hints, NM.SecretAgentGetSecretsFlags flags, NM.SecretAgentOldGetSecretsFunc callback) {

    }

    public override void cancel_get_secrets (string connection_path, string setting_name) {

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


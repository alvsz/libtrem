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
    public signal void new_request(string path, NM.Connection connection, string setting_name, string[] hints, int request_flags);
    public signal void cancel_request(string path);

    public ShellNetworkAgent() {

    }

    public override void save_secrets (NM.Connection connection, string connection_path, NM.SecretAgentOldSaveSecretsFunc callback) {

    }
    public override void get_secrets (NM.Connection connection, string connection_path, string setting_name, string[] hints, NM.SecretAgentGetSecretsFlags flags, NM.SecretAgentOldGetSecretsFunc callback) {

    }
    public override void cancel_get_secrets (string connection_path, string setting_name) {

    }
    public override void delete_secrets (NM.Connection connection, string connection_path, NM.SecretAgentOldDeleteSecretsFunc callback) {
      //var request = new KeyringRequest (this,connection,callback, null);
      var s_con = connection.get_setting_connection ();

      assert(s_con != null);
      var uuid = s_con.get_uuid();
      assert(uuid != null);

      var attributes = new HashTable<string, string>(str_hash,str_equal);
      attributes.insert ("connection-uuid",uuid);


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

    internal static Secret.Schema schema;

    static construct {
      var attributes = new HashTable<string, Secret.SchemaAttributeType>(str_hash,str_equal);
      attributes.insert ("connection-uuid",Secret.SchemaAttributeType.STRING);
      attributes.insert ("setting-name",Secret.SchemaAttributeType.STRING);
      attributes.insert ("setting-key",Secret.SchemaAttributeType.STRING);
      schema = new Secret.Schema.newv ("org.freedesktop.NetworkManager.Connection",Secret.SchemaFlags.DONT_MATCH_NAME,attributes);

    }
  }
}


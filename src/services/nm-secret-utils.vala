namespace libTrem {
    [CCode (cheader_filename = "NetworkManager.h", cname = "nm_setting_get_secret_flags")]
        extern static bool nm_setting_get_secret_flags_fixed (
                NM.Setting setting,
                string secret_name,
                out NM.SettingSecretFlags flags
                ) throws GLib.Error;

    [CCode (cheader_filename = "libsecret/secret.h", cname = "secret_service_search", finish_cname = "secret_service_search_finish")]
        extern async static unowned List<Secret.Item> secret_service_search (
                Secret.Service? service,
                Secret.Schema schema,
                HashTable<string, string> attributes,
                Secret.SearchFlags flags,
                Cancellable? cancellable = null
                ) throws GLib.Error;

    [CCode (cheader_filename = "libsecret/secret.h", cname = "secret_service_search_sync")]
        extern static unowned List<Secret.Item> secret_service_search_sync (
                Secret.Service? service,
                Secret.Schema schema,
                HashTable<string, string> attributes,
                Secret.SearchFlags flags,
                Cancellable? cancellable = null
                ) throws GLib.Error;

}

namespace libTrem {
    [CCode (cheader_filename = "NetworkManager.h", cname = "nm_setting_get_secret_flags")]
        extern static bool nm_setting_get_secret_flags_fixed (
                NM.Setting setting,
                string secret_name,
                out NM.SettingSecretFlags flags
                ) throws GLib.Error;

    [CCode (cheader_filename = "libsecret/secret.h", cname = "secret_service_search")]
        extern static void secret_service_search (
                Secret.Service service,
                Secret.Schema schema,
                HashTable<string, string> attributes,
                Secret.SearchFlags flags,
                Cancellable? cancellable,
                AsyncReadyCallback callback
                );

    [CCode (cheader_filename = "libsecret/secret.h", cname = "secret_service_search_finish")]
        extern static unowned GLib.List<Secret.Item> secret_service_search_finish (
                Secret.Service? service,
                AsyncResult result
                ) throws GLib.Error;
}

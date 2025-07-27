namespace libTrem {
    [CCode (cheader_filename = "NetworkManager.h", cname = "nm_setting_get_secret_flags")]
        extern static bool nm_setting_get_secret_flags_fixed (
                NM.Setting setting,
                string secret_name,
                out NM.SettingSecretFlags flags
                ) throws GLib.Error;

    [CCode (cheader_filename = "NetworkManager.h", cname = "nm_secret_agent_old_save_secrets")]
        extern static void nm_secret_agent_old_save_secrets (
                NM.SecretAgentOld self,
                NM.Connection connection,
                [CCode (scope = "async")] NM.SecretAgentOldSaveSecretsFunc callback
        );

    [CCode (cheader_filename = "NetworkManager.h", cname = "nm_secret_agent_old_delete_secrets")]
        extern static void nm_secret_agent_old_delete_secrets (
                NM.SecretAgentOld self,
                NM.Connection connection,
                [CCode (scope = "async")] NM.SecretAgentOldSaveSecretsFunc callback
        );

    [CCode (cheader_filename = "libsecret/secret.h", cname = "secret_service_search")]
        extern async static unowned List<Secret.Item> secret_service_search (
                Secret.Service? service,
                Secret.Schema schema,
                HashTable<string, string> attributes,
                Secret.SearchFlags flags,
                Cancellable? cancellable = null
                ) throws GLib.Error;

    [CCode (cheader_filename = "libsecret/secret.h", cname = "secret_service_search_finish")]
        extern static unowned List<Secret.Item> secret_service_search_finish (
                Secret.Service? service,
                AsyncResult result
                ) throws GLib.Error;

    [CCode (cheader_filename = "wayland-client.h", cname = "wl_registry_bind")]
        extern static void* wl_registry_bind (
                Wl.Registry registry,
                uint32 name,
                Wl.Interface interface,
                uint32 version
        );

    [CCode (cheader_filename = "wayland-client.h", cname = "wl_registry_add_listener")]
        extern static int wl_registry_add_listener (
                Wl.Registry registry,
                ref Wl.RegistryListener listener,
                void *data
        );
}

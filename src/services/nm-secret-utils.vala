namespace libTrem {
  [CCode (cheader_filename = "NetworkManager.h", cname = "nm_setting_get_secret_flags")]
    extern static bool nm_setting_get_secret_flags_fixed (
        NM.Setting setting,
        string secret_name,
        out NM.SettingSecretFlags flags
        ) throws GLib.Error;
}

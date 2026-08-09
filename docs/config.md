# Configuration

Configuration is still very limited.

## Fields

- host: The host URL of the Quartz server. You should probably just leave this as the default.
- port: The port number of the Quartz server. 8757 is the default/preferred port, but you can change it if needed.
- log_level: The log level of the Quartz server. You can set this to `debug`, `info`, `warn`, or `error`.
- run_history_limit: The number of recent run history entries to keep. The default is 100.
- poll_interval: For triggers that require polling (e.g. `clipboard`), the interval in milliseconds between polling attempts. The default is 1s.
- dialog_backend: Default is blank/auto. You can set this to `kdialog`, `zenity`, or `tk`.

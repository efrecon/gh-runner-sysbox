[Unit]
Description=GitHub Runner Pre-Flight Init
Before=docker.service
After=runner-conf.service


[Service]
Type=oneshot
User=runner
WorkingDirectory=/actions-runner
ExecStart=/usr/local/bin/hooks.sh RUNNER_PREFLIGHT_PATH
EnvironmentFile=-/etc/runner/runner.conf

[Install]
WantedBy=multi-user.target
Session summary — project: home-lab (no git repo; a Raspberry Pi behind Tailscale)

Turned the Pi into a Tailscale exit node so phones can route traffic through home. Ran
`tailscale up --advertise-exit-node`; the node appeared but traffic did not route, and
there was no error. It turned out advertising an exit node silently does nothing until an
admin approves it in the Tailscale admin console under the machine's route settings. After
approval, routing still failed until IP forwarding was enabled with `sysctl -w
net.ipv4.ip_forward=1`; a reboot reset it, so the setting also has to be written to
`/etc/sysctl.d/99-tailscale.conf` to persist. Throughput was poor at first; CPU was idle and
the bottleneck was the SD card (logging + swap), fixed by moving swap off. Total time about
two hours, mostly waiting on reboots.

<!-- MUST-INCLUDE:
- exit-node advertisement silently no-ops until approved in the admin console
- ip_forward must be persisted in /etc/sysctl.d or it resets on reboot
-->
<!-- MUST-EXCLUDE:
- the step-by-step command sequence as a list
- "about two hours"
-->

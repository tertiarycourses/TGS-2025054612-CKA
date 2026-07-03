# Step 4 — Logs from the host

```bash
ls /var/log/pods/
ls /var/log/pods/default_multi_*/writer/
sudo tail /var/log/pods/default_multi_*/writer/0.log
```

Each line is JSON: timestamp, stream (`stdout`/`stderr`), and the raw output.

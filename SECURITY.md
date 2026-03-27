# Security Policy

## PHP upstream support (php.net)

The table below is the **official PHP project** support phase for each branch—not a guarantee that every branch appears in our image matrix. Use it to decide when to upgrade.

| Branch | Phase on php.net |
| --- | --- |
| 8.5 | Active support (bug + security fixes) |
| 8.4 | Active support (bug + security fixes) |
| 8.3 | Security fixes only |
| 8.2 | Security fixes only |
| 8.1 | End of life — upgrade as soon as practical |
| 8.0 | End of life — upgrade as soon as practical |
| 7.4 | End of life — upgrade as soon as practical |
| ≤ 7.3 | End of life — not built in this project’s current matrix |

**References**

- [Supported Versions](https://www.php.net/supported-versions.php) — active and security support dates for current branches  
- [End-of-life branches](https://www.php.net/eol.php) — historical EOL dates  

We may still ship images for **EOL** PHP versions to help migrate legacy apps; prefer a [currently supported branch](https://www.php.net/supported-versions.php) for production.

---

## Reporting a vulnerability

Follow [our responsible disclosure policy](https://www.notion.so/Responsible-Disclosure-Policy-421a6a3be1714d388ebbadba7eebbdc8).

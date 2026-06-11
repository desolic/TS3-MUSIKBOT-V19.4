# Datenschutzdokumentation — TS3-MUSIKBOT (TS3AudioBot)

DESOLIC IT — Projekt 25G524
Stand: 2026-05-29

Dieses Dokument unterstützt den DSGVO-konformen Betrieb des Musikbots. Es ersetzt
keine Rechtsberatung; es liefert die technische Grundlage für Verzeichnis von
Verarbeitungstätigkeiten (Art. 30 DSGVO), Informationspflichten (Art. 13/14) und
ein Löschkonzept.

---

## 1. Verantwortlicher

- **Verantwortlicher:** DESOLIC IT (Kontakt: it@desolic.de)
- **Anwendung:** TS3AudioBot (Open Source, MIT) als TeamSpeak-3-Musikbot

## 2. Zweck der Verarbeitung

Bereitstellung von Audiowiedergabe (Musik/Streams) in einem TeamSpeak-3-Server
sowie Steuerung/Verwaltung des Bots über Chat-Befehle und WebAPI.

## 3. Verarbeitete personenbezogene Daten

| Datenkategorie | Beispiel | Quelle | Zweck |
|---|---|---|---|
| TeamSpeak-Identität (ClientUID) | `xxxx=` | TS3-Server | Rechtevergabe (rights.toml) |
| Anzeigename | „MaxM" | TS3-Server | Bedien-/Log-Kontext |
| IP-Adresse | Verbindungs-IP | Netzwerk/TS3 | Verbindungsaufbau, Logs |
| Befehls-/Wiedergabeverlauf | Songanfragen | Bot | Queue/Historie/Komfort |
| WebAPI-Token | Token pro Nutzer | Bot | Authentifizierung |

Es werden **keine Sprachinhalte aufgezeichnet**. Der Bot sendet Audio, er
zeichnet keine Gespräche auf.

## 4. Rechtsgrundlage

In der Regel **berechtigtes Interesse (Art. 6 Abs. 1 lit. f DSGVO)** am Betrieb
des Community-Dienstes; alternativ Einwilligung (lit. a). Vom Verantwortlichen
abschließend zu bestimmen und im Verzeichnis festzuhalten.

## 5. Empfänger / Drittanbieter-Datenflüsse

| Empfänger | Übertragene Daten | Anlass | Hinweis |
|---|---|---|---|
| **YouTube/Google** (via yt-dlp) | Server-IP, angefragte Inhalte/URLs | Auflösen/Abspielen von Quellen | mögliche Drittlandübermittlung (USA) — prüfen |
| weitere Stream-Quellen | Server-IP, URL | Wiedergabe | je nach genutzter Quelle |

Im Gegensatz zur früheren SinusBot-Lösung gibt es **kein Lizenz-Phone-Home**.
**Anonyme Telemetrie von TS3AudioBot ist zu deaktivieren** (siehe
`config/ts3audiobot.toml.example`, Schlüssel `send-stats`/„stats" → `false`).

## 6. Speicherdauer / Löschkonzept

| Datum | Speicherort | Aufbewahrung | Löschung |
|---|---|---|---|
| Bot-Datenbank/Historie | PVC `/data/ts3audiobot.db` | nur solange erforderlich | regelmäßig bereinigen |
| Logs | Container-Logs / `/data` | **kurz halten** (z. B. 7–14 Tage) | Rotation + automatische Löschung |
| WebAPI-Token | `/data` | bis Widerruf | bei Personalwechsel widerrufen |

**Logging-Vorgaben:**
- Loglevel im Normalbetrieb niedrig halten; ausführliche Level (Debug) nur
  temporär zur Fehlersuche und danach zurücksetzen.
- Logs können IP-Adressen / ClientUIDs enthalten → als personenbezogen behandeln,
  rotieren und mit definierter Frist löschen.

## 7. Technische & organisatorische Maßnahmen (TOM, Art. 32)

- **Verschlüsselung im Transit:** WebAPI/Interface nur über TLS-Ingress.
- **Verschlüsselung at-rest:** PVC mit verschlüsselter StorageClass.
- **Zugriffskontrolle:** Least-Privilege via `rights.toml`; Adminrechte nur an
  konkrete TS3-UIDs; WebAPI mit Token-Auth.
- **Geheimnisverwaltung:** Passwörter/Identität/Tokens nur in K8s-Secrets,
  nicht im Image, nicht im Git.
- **Netzsegmentierung:** NetworkPolicy (Default-Deny + gezielte Egress).
- **Isolation/Härtung:** non-root, readOnlyRootFilesystem, drop ALL caps,
  seccomp, kein hostPath/hostPort.
- **Integrität:** gepinnte, per SHA256/Digest verifizierte Artefakte; kein
  Runtime-Self-Update.

## 8. Betroffenenrechte

Auskunft/Löschung/Berichtigung (Art. 15–17): Daten zu einer Person sind über die
**ClientUID** in Bot-Datenbank und Logs auffindbar und können entfernt werden.
Anfragen an it@desolic.de.

## 9. Informationspflicht gegenüber Nutzern

Nutzer des TeamSpeak-Servers sind über den Bot-Betrieb und diese Verarbeitung zu
informieren (z. B. Server-Regeln/Channel-Beschreibung/Datenschutzhinweis), inkl.
Hinweis auf die Drittanbieter-Datenflüsse (YouTube/Google) gemäß Abschnitt 5.

# Sicherheitskonzept — TS3-MUSIKBOT (TS3AudioBot)

DESOLIC IT — Projekt 25G524

Dieses Dokument beschreibt das Sicherheitsdesign des gehärteten Images und die
verpflichtenden Schritte für einen sicheren Betrieb.

---

## 1. Designentscheidungen

| Maßnahme | Begründung |
|---|---|
| **Engine: TS3AudioBot (MIT, Open Source)** statt SinusBot | auditierbar, kein Lizenz-Phone-Home, aktiv gepflegt |
| **Headless ClientQuery** (kein TS3-GUI-Client) | eliminiert Xvfb/x11vnc/GUI-Libs → drastisch kleinere Angriffsfläche |
| **Multi-Stage-Build** | Build-Werkzeuge (`wget`, `unzip`, …) sind nicht im Laufzeit-Image |
| **chiseled .NET-Runtime** | keine Shell, kein Paketmanager → minimale CVE-Fläche |
| **non-root (UID 1654)** | keine Root-Prozesse im Container |
| **alle Downloads via HTTPS + SHA256** | Schutz gegen MITM / kompromittierte Mirrors |
| **Versionen + Image-Digests gepinnt** | reproduzierbare, nachvollziehbare Builds |
| **kein Runtime-Self-Update** | kein Code-Download beim Start (anders als zuvor `youtube-dl -U`) |
| **keine Secrets im Image** | Konfiguration/Geheimnisse erst zur Laufzeit aus K8s-Secret |

---

## 2. Pflicht vor dem ersten Build: Pinning

Im `Dockerfile` und im K8s-Manifest sind Platzhalter `REPLACE_WITH_*` zu füllen.
Werte **einmalig** ermitteln, prüfen und fest eintragen:

```bash
# Base-Image-Digests
docker pull ubuntu:24.04 && docker inspect --format '{{index .RepoDigests 0}}' ubuntu:24.04
docker pull mcr.microsoft.com/dotnet/runtime:8.0-noble-chiseled \
  && docker inspect --format '{{index .RepoDigests 0}}' mcr.microsoft.com/dotnet/runtime:8.0-noble-chiseled

# Artefakt-Checksummen
sha256sum TS3AudioBot.zip          # -> TSAB_SHA256
sha256sum yt-dlp_linux             # -> YTDLP_SHA256   (oder offizielle SHA2-256SUMS prüfen)
sha256sum ffmpeg-*-linux64-gpl.tar.xz  # -> FFMPEG_SHA256
```

> Solange Platzhalter gesetzt sind, **scheitert der Build absichtlich** an
> `sha256sum -c`. Das ist gewollt: kein ungeprüfter Download gelangt ins Image.

### Versionskopplung
- `TSAB_VERSION` muss zum **.NET-Ziel-Framework** passen. Den Runtime-Tag
  (`8.0-noble-chiseled`) ggf. an das Framework der gewählten Release anpassen.
- ffmpeg-Build: einen **datierten** `autobuild`-Tag von BtbN/FFmpeg-Builds
  pinnen, nicht `latest`.

---

## 3. Laufzeithärtung (Kubernetes)

- `securityContext`: `runAsNonRoot`, `readOnlyRootFilesystem`, `drop: ALL`,
  `seccompProfile: RuntimeDefault`, `fsGroup` für das Datenvolume.
- Namespace mit **PodSecurity „restricted"**.
- **PVC** statt `hostPath`; bevorzugt StorageClass mit Encryption-at-Rest.
- **Kein hostPort** — Zugriff ausschließlich über **ClusterIP + TLS-Ingress**.
- **NetworkPolicy** Default-Deny; Egress nur DNS, TS3-Voice (9987/UDP), HTTPS.
- `automountServiceAccountToken: false`.

## 4. Konfiguration & Geheimnisse

- **Nie** echte `ts3audiobot.toml` / `bot.toml` / `rights.toml` einchecken
  (siehe `.gitignore`). Es liegen nur `*.example`-Vorlagen im Repo.
- Geheimnisse (Server-Passwort, TS3-Identität, API-Tokens) ausschließlich über
  K8s-Secret / Sealed-Secrets / Vault.
- **Rechte (`rights.toml`) nach Least-Privilege**: Adminrechte nur an konkrete
  TS3-UIDs, Standardnutzer nur Wiedergabebefehle.
- **WebAPI**: Token-Auth aktiv lassen, Tokens sicher verteilen, Interface nur
  hinter dem TLS-Ingress erreichbar.

## 5. Updates

Updates erfolgen **ausschließlich über einen neuen, gepinnten Image-Build**
(Version + Checksum aktualisieren → Build → Rollout), nicht zur Laufzeit.
Empfehlung: regelmäßiger Image-Scan (z. B. Trivy/Grype) in der CI.

## 6. Schwachstellen melden

Sicherheitsmeldungen vertraulich an **it@desolic.de**.

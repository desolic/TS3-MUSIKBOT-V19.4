# TS3-MUSIKBOT
DESOLIC-IT PROJECT 25G524
FÜR WEITERE INFORMATIONEN RUFEN SIE DAS DOKUMENT "DESOLIC - LEITFADEN SINUSBOT" IM INTNET AUF.

Gehärtetes Container-Image für einen TeamSpeak-3-Musikbot auf Basis von
**TS3AudioBot** (Open Source, MIT). Headless (kein GUI-/VNC-Stack), non-root,
distroless-artige .NET-Runtime, reproduzierbar gepinnt.

> Hinweis: Diese Version ersetzt die frühere SinusBot-Lösung (Open-Source-Engine,
> kein GUI-/VNC-Stack, kein Lizenz-Phone-Home).

## Komponenten

```
Engine:   TS3AudioBot (Open Source, MIT)
Resolver: yt-dlp (gepinnt, SHA256-verifiziert)
Audio:    statisches ffmpeg/ffprobe (gepinnt, SHA256-verifiziert)
Runtime:  .NET chiseled (non-root, keine Shell)
```

## Schnellstart

1. `.env.example` → `.env` kopieren und alle `REPLACE_WITH_*`-Werte mit
   geprüften Checksummen/Digests füllen (siehe **Pinning** unten).
2. Image bauen:
   ```bash
   docker build $(grep -v '^#' .env | sed 's/^/--build-arg /') -t ts3-musikbot .
   ```
3. Konfiguration aus `config/*.example` ableiten und als K8s-Secret einspielen
   (Geheimnisse **nicht** ins Git).
4. Deployen: `kubectl apply -f kubernetes/ts3audiobot.yaml`

## Pinning (Pflicht vor dem ersten Build)

Im `Dockerfile`/Manifest sind `REPLACE_WITH_*`-Platzhalter (Image-Digests,
SHA256-Summen, Admin-TS3-UID) **einmalig** mit geprüften Werten zu füllen.
Solange Platzhalter gesetzt sind, scheitert der Build absichtlich an der
Checksum-Prüfung — kein ungeprüfter Download gelangt ins Image.

```bash
# Base-Image-Digests
docker pull ubuntu:24.04 && docker inspect --format '{{index .RepoDigests 0}}' ubuntu:24.04
docker pull mcr.microsoft.com/dotnet/runtime:8.0-noble-chiseled \
  && docker inspect --format '{{index .RepoDigests 0}}' mcr.microsoft.com/dotnet/runtime:8.0-noble-chiseled

# Artefakt-Checksummen
sha256sum TS3AudioBot.zip               # -> TSAB_SHA256
sha256sum yt-dlp_linux                  # -> YTDLP_SHA256 (oder offizielle SHA2-256SUMS prüfen)
sha256sum ffmpeg-*-linux64-gpl.tar.xz   # -> FFMPEG_SHA256
```

- **Versionskopplung:** `TSAB_VERSION` muss zum .NET-Ziel-Framework passen — den
  Runtime-Tag (`8.0-noble-chiseled`) ggf. anpassen.
- **ffmpeg:** datierten `autobuild`-Tag von BtbN/FFmpeg-Builds pinnen, nicht `latest`.
- **Updates** erfolgen nur über einen neuen, gepinnten Image-Build (kein Runtime-Self-Update).

## Dokumentation

- [`DATENSCHUTZ.md`](DATENSCHUTZ.md) — DSGVO-Dokumentation (Art. 30/13/32)
- `config/*.example` — gehärtete Konfigurations-Vorlagen
- `kubernetes/ts3audiobot.yaml` — gehärtetes Deployment

## Sicherheit auf einen Blick

- Alle externen Artefakte via HTTPS + SHA256, Versionen/Digests gepinnt
- Kein Runtime-Self-Update, keine Secrets im Image
- non-root, readOnlyRootFilesystem, drop ALL caps, seccomp, NetworkPolicy
- PVC statt hostPath, ClusterIP + TLS-Ingress statt hostPort

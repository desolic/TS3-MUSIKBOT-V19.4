# TS3-MUSIKBOT
DESOLIC-IT PROJECT 25G524
FÜR WEITERE INFORMATIONEN RUFEN SIE DAS DOKUMENT "DESOLIC - LEITFADEN SINUSBOT" IM INTNET AUF.

Gehärtetes Container-Image für einen TeamSpeak-3-Musikbot auf Basis von
**TS3AudioBot** (Open Source, MIT). Headless (kein GUI-/VNC-Stack), non-root,
distroless-artige .NET-Runtime, reproduzierbar gepinnt.

> Hinweis: Diese Version ersetzt die frühere SinusBot-Lösung. Begründung und
> Designentscheidungen siehe [`SECURITY.md`](SECURITY.md).

## Komponenten

```
Engine:   TS3AudioBot (Open Source, MIT)
Resolver: yt-dlp (gepinnt, SHA256-verifiziert)
Audio:    statisches ffmpeg/ffprobe (gepinnt, SHA256-verifiziert)
Runtime:  .NET chiseled (non-root, keine Shell)
```

## Schnellstart

1. `.env.example` → `.env` kopieren und alle `REPLACE_WITH_*`-Werte mit
   geprüften Checksummen/Digests füllen (siehe [`SECURITY.md`](SECURITY.md)).
2. Image bauen:
   ```bash
   docker build $(grep -v '^#' .env | sed 's/^/--build-arg /') -t ts3-musikbot .
   ```
3. Konfiguration aus `config/*.example` ableiten und als K8s-Secret einspielen
   (Geheimnisse **nicht** ins Git).
4. Deployen: `kubectl apply -f kubernetes/ts3audiobot.yaml`

## Dokumentation

- [`SECURITY.md`](SECURITY.md) — Sicherheitskonzept, Pinning, Härtung
- [`DATENSCHUTZ.md`](DATENSCHUTZ.md) — DSGVO-Dokumentation (Art. 30/13/32)
- `config/*.example` — gehärtete Konfigurations-Vorlagen
- `kubernetes/ts3audiobot.yaml` — gehärtetes Deployment

## Sicherheit auf einen Blick

- Alle externen Artefakte via HTTPS + SHA256, Versionen/Digests gepinnt
- Kein Runtime-Self-Update, keine Secrets im Image
- non-root, readOnlyRootFilesystem, drop ALL caps, seccomp, NetworkPolicy
- PVC statt hostPath, ClusterIP + TLS-Ingress statt hostPort

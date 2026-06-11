# syntax=docker/dockerfile:1.7
###############################################################################
# TS3-MUSIKBOT — TS3AudioBot (gehärtet)                                        #
# DESOLIC IT — Projekt 25G524                                                  #
#                                                                             #
# Sicherheitsdesign:                                                          #
#   * Open-Source-Engine (TS3AudioBot, MIT) statt Closed-Source-SinusBot      #
#   * KEIN GUI-/X11-/VNC-Stack, headless ClientQuery -> minimale Angriffsfl.  #
#   * Multi-Stage: Build-Werkzeuge (wget/unzip/...) landen NICHT im Runtime   #
#   * ALLE Downloads via HTTPS + SHA256-Verifikation, Versionen gepinnt       #
#   * Distroless-/chiseled .NET-Runtime: keine Shell, kein Paketmanager       #
#   * Läuft als non-root (UID 1654), keine Secrets im Image                   #
#                                                                             #
# Vor dem ersten Build die mit REPLACE_WITH_* markierten Werte einmalig mit    #
# echten, geprüften SHA256-Summen / Image-Digests füllen (siehe SECURITY.md). #
###############################################################################

###############################################################################
# Stage 1 — fetch & VERIFY (Build-Tools bleiben aus dem Runtime-Image)        #
###############################################################################
# Basis per Digest pinnen -> reproduzierbar, nicht durch "latest" verschiebbar
FROM ubuntu:24.04@sha256:REPLACE_WITH_UBUNTU_DIGEST AS fetch

# --- gepinnte Versionen + Checksums (vor dem Build mit echten Werten füllen) ---
ARG TSAB_VERSION=0.13.0
ARG TSAB_URL=https://github.com/Splamy/TS3AudioBot/releases/download/${TSAB_VERSION}/TS3AudioBot.zip
ARG TSAB_SHA256=REPLACE_WITH_TS3AUDIOBOT_ZIP_SHA256

ARG YTDLP_VERSION=2025.05.22
ARG YTDLP_SHA256=REPLACE_WITH_YTDLP_LINUX_SHA256

ARG FFMPEG_TAG=autobuild-2025-05-01-12-30
ARG FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/${FFMPEG_TAG}/ffmpeg-master-latest-linux64-gpl.tar.xz
ARG FFMPEG_SHA256=REPLACE_WITH_FFMPEG_TARBALL_SHA256

SHELL ["/bin/bash", "-o", "pipefail", "-euc"]

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates wget unzip xz-utils \
 && update-ca-certificates

WORKDIR /build
RUN mkdir -p /opt/tsab /opt/bin

# --- TS3AudioBot — HTTPS + SHA256 ---
RUN wget -q -O tsab.zip "${TSAB_URL}" \
 && echo "${TSAB_SHA256}  tsab.zip" | sha256sum -c - \
 && unzip -q tsab.zip -d /opt/tsab \
 && rm -f tsab.zip

# --- yt-dlp (Resolver) — gepinnt + SHA256 ---
RUN wget -q -O yt-dlp "https://github.com/yt-dlp/yt-dlp/releases/download/${YTDLP_VERSION}/yt-dlp_linux" \
 && echo "${YTDLP_SHA256}  yt-dlp" | sha256sum -c - \
 && install -m 0755 yt-dlp /opt/bin/yt-dlp

# --- statisches ffmpeg/ffprobe — gepinnt + SHA256, nur Binaries übernehmen ---
RUN wget -q -O ffmpeg.tar.xz "${FFMPEG_URL}" \
 && echo "${FFMPEG_SHA256}  ffmpeg.tar.xz" | sha256sum -c - \
 && tar -xJf ffmpeg.tar.xz \
 && install -m 0755 "$(find . -type f -name ffmpeg  | head -1)" /opt/bin/ffmpeg \
 && install -m 0755 "$(find . -type f -name ffprobe | head -1)" /opt/bin/ffprobe

###############################################################################
# Stage 2 — minimales, non-root, distroless-artiges Runtime-Image             #
# Hinweis: Den .NET-Tag an das Ziel-Framework der gewählten TSAB_VERSION       #
# anpassen (siehe SECURITY.md). chiseled = keine Shell, kein apt -> wenig CVE. #
###############################################################################
FROM mcr.microsoft.com/dotnet/runtime:8.0-noble-chiseled@sha256:REPLACE_WITH_DOTNET_DIGEST

LABEL org.opencontainers.image.title="TS3-Musikbot (TS3AudioBot, hardened)" \
      org.opencontainers.image.maintainer="DESOLIC IT <it@desolic.de>" \
      org.opencontainers.image.source="https://github.com/desolic/ts3-musikbot-v19.4" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.description="Gehärtetes TS3-Musikbot-Image auf Basis von TS3AudioBot"

# Globalization-invariant -> keine ICU-Abhängigkeit im chiseled Image.
# Diagnostics aus -> kein offener Diagnostic-IPC-Socket.
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 \
    DOTNET_EnableDiagnostics=0 \
    PATH="/opt/bin:${PATH}"

# Verifizierte Artefakte aus dem Build-Stage; KEINE Konfiguration/Secrets ins Image.
COPY --from=fetch /opt/tsab/ /opt/tsab/
COPY --from=fetch /opt/bin/  /opt/bin/

# UID 1654 = vordefinierter non-root User 'app' der chiseled .NET-Images.
USER 1654:1654
WORKDIR /data

# Konfiguration + Datenbank liegen ausschließlich im gemounteten Volume /data.
VOLUME ["/data"]

# WebAPI/Interface (Standard 58913). Nur clusterintern exponieren, TLS davor.
EXPOSE 58913

# Kein HEALTHCHECK im Image (chiseled hat keine Shell/Tools) -> Probes in K8s.
ENTRYPOINT ["dotnet", "/opt/tsab/TS3AudioBot.dll", "--non-interactive"]

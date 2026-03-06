#!/usr/bin/env bash

set -euo pipefail

# Build Chroma and NoodleExtensions on macOS host (Quest 1.40.7).
# - Instala (via Homebrew) as ferramentas mínimas: CMake, Ninja, PowerShell.
# - Baixa e configura QPM.CLI (exposto como `qpm-rust`).
# - Baixa o Android NDK r27c para macOS (se ainda não existir) e escreve ndkpath.txt.
# - Roda os scripts oficiais de build e createqmod para Chroma e NoodleExtensions.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLS_DIR="$ROOT/.tools"
BIN_DIR="$TOOLS_DIR/bin"

echo "=== Heck Quest macOS build (Chroma + NoodleExtensions) ==="
echo "Repo root: $ROOT"
echo ""

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Este script é destinado a rodar em macOS (Darwin)."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew não encontrado. Instale via https://brew.sh e rode novamente."
  exit 1
fi

ensure_brew_pkg() {
  local pkg="$1"
  if ! brew list --versions "$pkg" >/dev/null 2>&1; then
    echo "Instalando $pkg via Homebrew..."
    brew install "$pkg"
  else
    echo "$pkg já instalado (Homebrew)."
  fi
}

echo "==> Verificando ferramentas base (cmake, ninja, PowerShell)..."
ensure_brew_pkg cmake
ensure_brew_pkg ninja

# PowerShell (pwsh) pode ser fórmula ou cask, dependendo do setup.
if ! command -v pwsh >/dev/null 2>&1; then
  if ! brew list --cask --versions powershell >/dev/null 2>&1 && \
     ! brew list --versions powershell >/dev/null 2>&1; then
    echo "Instalando PowerShell (pwsh) via Homebrew..."
    if brew info --cask powershell >/dev/null 2>&1; then
      brew install --cask powershell
    else
      brew install powershell
    fi
  fi
else
  echo "PowerShell (pwsh) já está disponível."
fi

mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

echo ""
echo "==> Verificando QPM (qpm / qpm-rust)..."
if ! command -v qpm-rust >/dev/null 2>&1 && ! command -v qpm >/dev/null 2>&1; then
  QPM_VERSION="v1.5.8"
  QPM_ARCHIVE="qpm-macos-arm64.zip"
  QPM_URL="https://github.com/QuestPackageManager/QPM.CLI/releases/download/${QPM_VERSION}/${QPM_ARCHIVE}"

  echo "Baixando QPM.CLI (${QPM_VERSION}) para macOS arm64..."
  tmp_zip="$(mktemp -t qpm-XXXXXX.zip)"
  curl -L "$QPM_URL" -o "$tmp_zip"

  echo "Extraindo QPM em $BIN_DIR..."
  unzip -q "$tmp_zip" -d "$BIN_DIR"
  rm -f "$tmp_zip"

  if [[ ! -x "$BIN_DIR/qpm" ]]; then
    chmod +x "$BIN_DIR/qpm" 2>/dev/null || true
  fi

  ln -sf "$BIN_DIR/qpm" "$BIN_DIR/qpm-rust"
  echo "QPM instalado em $BIN_DIR (com aliases 'qpm' e 'qpm-rust')."
else
  echo "qpm/qpm-rust já disponível no PATH."
fi

echo ""
echo "==> Configurando Android NDK..."
NDK_PATH_FILE="$ROOT/ndkpath.txt"

if [[ -f "$NDK_PATH_FILE" ]]; then
  NDK_PATH="$(tr -d '\r' < "$NDK_PATH_FILE" | xargs || true)"
else
  NDK_PATH=""
fi

if [[ -z "${NDK_PATH}" ]] || [[ ! -d "${NDK_PATH}" ]]; then
  NDK_PARENT="$TOOLS_DIR"
  NDK_EXTRACTED="$NDK_PARENT/android-ndk-r27c"
  if [[ ! -f "$NDK_EXTRACTED/source.properties" ]] && [[ ! -d "$NDK_EXTRACTED/toolchains" ]]; then
    echo "Baixando Android NDK r27c para macOS..."
    mkdir -p "$NDK_PARENT"
    tmp_ndk="$(mktemp -t ndk-XXXXXX.zip)"
    curl -L "https://dl.google.com/android/repository/android-ndk-r27c-darwin.zip" -o "$tmp_ndk"
    unzip -q -o "$tmp_ndk" -d "$NDK_PARENT"
    rm -f "$tmp_ndk"
  fi

  # O zip do Google extrai para android-ndk-r27c (raiz = pasta que contém source.properties)
  if [[ -f "$NDK_EXTRACTED/source.properties" ]]; then
    NDK_PATH="$NDK_EXTRACTED"
  elif [[ -d "$NDK_PARENT/android-ndk-r27c" ]]; then
    NDK_PATH="$NDK_PARENT/android-ndk-r27c"
  else
    # fallback: primeiro diretório que pareça NDK (tenha source.properties)
    NDK_PATH=""
    for d in "$NDK_PARENT"/android-ndk-r*; do
      if [[ -f "$d/source.properties" ]]; then
        NDK_PATH="$d"
        break
      fi
    done
  fi

  if [[ -z "${NDK_PATH}" ]] || [[ ! -f "${NDK_PATH}/source.properties" ]]; then
    echo "Erro: não foi possível localizar a raiz do Android NDK (source.properties)."
    echo "Instale o NDK manualmente (ex.: Android Studio → SDK Manager → NDK 27.2.x),"
    echo "crie $NDK_PATH_FILE com o caminho da pasta do NDK e rode o script de novo."
    exit 1
  fi

  printf '%s' "$NDK_PATH" > "$NDK_PATH_FILE"
  echo "ndkpath.txt criado apontando para: $NDK_PATH"
else
  echo "Usando NDK existente de ndkpath.txt: $NDK_PATH"
fi

# QPM pode exigir NDK 27.2.x; se aparecer 'Unable to validate ... NDK version', use o NDK do Android Studio.
export ANDROID_NDK_HOME="$NDK_PATH"

echo ""
echo "==> Restaurando dependências e fazendo build (Chroma)..."
cd "$ROOT/chroma"
qpm-rust restore
pwsh -NoLogo -NoProfile -Command "./scripts/build.ps1 -release"
pwsh -NoLogo -NoProfile -Command "./scripts/createqmod.ps1"

echo ""
echo "==> Restaurando dependências e fazendo build (NoodleExtensions)..."
cd "$ROOT/noodleextensions"
qpm-rust restore
pwsh -NoLogo -NoProfile -Command "./scripts/build.ps1 -release"
pwsh -NoLogo -NoProfile -Command "./scripts/createqmod.ps1"

echo ""
echo "=== Build concluído com sucesso ==="
echo "Chroma.qmod:        $ROOT/chroma/Chroma.qmod"
echo "NoodleExtensions.qmod: $ROOT/noodleextensions/NoodleExtensions.qmod"


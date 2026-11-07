#!/usr/bin/env bash
# Genera el .zip de entrega con el código fuente versionado.
# Usa `git archive`: solo incluye archivos en git (respeta .gitignore), así
# que nunca entran claves locales, node_modules ni compilados.
#
# Uso:  scripts/empaquetar.sh [carpeta_destino]
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [ -n "$(git status --porcelain)" ]; then
  echo "Hay cambios sin commit. Haz commit antes de empaquetar." >&2
  exit 1
fi

version=$(sed -n 's/^version: *\([^+]*\).*/\1/p' app/pubspec.yaml)
commit=$(git rev-parse --short HEAD)
out_dir="${1:-dist}"
mkdir -p "$out_dir"
name="vantia-v${version}-${commit}"
zip_path="$out_dir/${name}.zip"

git archive --format=zip --prefix="${name}/" -o "$zip_path" HEAD

# Control de seguridad: ningún archivo de secretos dentro del zip.
if unzip -Z1 "$zip_path" | grep -E '(^|/)(key\.properties|google-services\.json|GoogleService-Info\.plist|\.secret\.local)$|\.jks$|/env/(dev|prod)\.json$'; then
  echo "ERROR: el paquete contiene archivos sensibles." >&2
  rm -f "$zip_path"
  exit 1
fi

(cd "$out_dir" && sha256sum "${name}.zip" > "${name}.zip.sha256")
echo "Paquete: $zip_path ($(du -h "$zip_path" | cut -f1))"
echo "SHA-256: $(cut -d' ' -f1 "$zip_path.sha256")"

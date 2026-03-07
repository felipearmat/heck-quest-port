# Release folders (qmod only)

As pastas `1407/` e `1408/` devem conter **apenas ficheiros .qmod** para instalação no Beat Saber Quest (BMBF/QuestPatcher), não ficheiros .so.

## Conteúdo esperado

- **1407/** — Beat Saber 1.40.7: `Chroma.qmod`, `NoodleExtensions.qmod`
- **1408/** — Beat Saber 1.40.8: `Chroma.qmod`, `NoodleExtensions.qmod`

## Como gerar

1. Build e createqmod (a partir da raiz do repo):
   - Para 1.40.7: branch/restore para 1.40.7, depois  
     `pwsh ./scripts/build-all.ps1` e `pwsh ./scripts/createqmod-all.ps1`
   - Para 1.40.8: branch/restore para 1.40.8; se usares tracks buildado localmente, copia `local_deps/tracks/build/libtracks.so` para `chroma/extern/libs` e `noodleextensions/extern/libs` antes do build; depois build e createqmod como acima.

2. Copiar os .qmod para a pasta de release:
   ```powershell
   pwsh ./scripts/copy-qmods-to-releases.ps1 1407   # ou 1408
   ```
   Isto remove qualquer .so na pasta e copia `Chroma.qmod` e `NoodleExtensions.qmod` para `releases/1407` ou `releases/1408`.

## Docker (1.40.7)

O script `./scripts/docker-build.sh` já faz build e createqmod e copia os .qmod para `releases/1407/`.

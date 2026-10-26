# Changelog

Changelog de release deste repositório, no formato [keep-a-changelog](https://keepachangelog.com/pt-BR/1.1.0/).
Uma frase por change; a história detalhada é o ledger de changes, [`specs/CHANGELOG.md`](specs/CHANGELOG.md).
Regras: `spec-layout` → "Changelog de release".

**Changes de release (sem item):** seq 4

**Ledger anterior a este arquivo:** seq ≤ 0

## [Unreleased]

### Added

- Complication "AOD Toggle" também em imagem monocromática, pintada na cor do tema do mostrador; o estado aparece pela forma (sólido, vazado, com tarja) (seq 6)

### Changed

- CI mais rápido: cache do Gradle gravado a cada merge na `dev` e sem teste de unidade duplicado (seq 5, #6)

## [0.1.0] - 2026-10-25

### Added

- CI em runner do GitHub que roda lint, testes e o build de release do app em toda PR (seq 3, #3)
- Guard que só aceita PR para a `main` vinda da `dev` (workflow `PR origin check`) (seq 2, #2)
- Complication "AOD Toggle" e gatilho "AOD" mapeável a um botão, que alternam o Always-On Display do OnePlus Watch 3 (seq 1, #1)

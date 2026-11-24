# claude-config
A minha configuração do Claude Code para levar para outras máquinas.

- `CLAUDE.md`: instruções globais, copiadas para `~/.claude/CLAUDE.md`.
- `skills/`: skills pessoais (humanizer), copiadas para `~/.claude/skills/`.
- `settings.json`: só `model`, `env` e plugins ativos; junta-se ao settings existente.

Windows: `powershell -ExecutionPolicy Bypass -File install.ps1` · Linux: `bash install.sh`

Os scripts fazem backup de `~/.claude` e no fim mostram os comandos `/plugin` a correr.

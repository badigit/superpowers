#!/usr/bin/env bash
# Приводит namespace скиллов к бренду форка: superpowers: -> superpowers-dim:
#
# Область: skills/ и tests/claude-code/. Тесты других харнессов (hermes и пр.) не трогаем,
# иначе дельта форка растёт шумом, а синк дорожает.
#
# Идемпотентен: строка "superpowers-dim:" не содержит подстроки "superpowers:",
# поэтому повторный прогон ничего не меняет.
#
# Ветка форка хранит АПСТРИМНЫЕ `superpowers:` как есть: namespace-правки не входят в
# коммиты, поэтому не конфликтуют при синке. Скрипт зовёт установщик
# (scripts/install-superpowers-dim.ps1 в мастерской) на КОПИИ дерева перед установкой
# плагина. В самой ветке его гонять не нужно.
set -euo pipefail

BRAND="superpowers-dim"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

count=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  sed -i "s/superpowers:/${BRAND}:/g" "$f"
  echo "  ребрендинг: $f"
  count=$((count + 1))
done < <(grep -rl "superpowers:" skills/ tests/claude-code/ 2>/dev/null || true)

if [ "$count" -eq 0 ]; then
  echo "namespace уже приведён к ${BRAND}: — изменений нет"
else
  echo "готово: файлов изменено — ${count}"
fi

# Манифесты других харнессов (Codex, Antigravity, Cursor): имя плагина обязано совпасть с
# namespace из текста скиллов, иначе `superpowers-dim:writing-plans` в цепочке не найдётся.
# Меняется только первое точное `"name": "<от>"`: `superpowers-dim` и `superpowers-dev`
# под образец не попадают, поэтому прогон идемпотентен.
rename_json() { # файл, от, к
  [ -f "$1" ] || return 0
  if grep -q "\"name\": \"$2\"" "$1"; then
    sed -i "0,/\"name\": \"$2\"/s//\"name\": \"$3\"/" "$1"
    echo "  манифест: $1: $2 -> $3"
  fi
}
rename_json .codex-plugin/plugin.json superpowers "$BRAND"
rename_json .antigravity-plugin/plugin.json superpowers "$BRAND"
rename_json .cursor-plugin/plugin.json superpowers "$BRAND"
rename_json .agents/plugins/marketplace.json superpowers-dev dim
rename_json .agents/plugins/marketplace.json superpowers "$BRAND"
# Апстримный marketplace Codex указывает источник как `url`: Codex клонирует его git'ом, а копия
# сборки не репозиторий («does not appear to be a git repository»). Нужен локальный источник.
if grep -q '"url": "\./"' .agents/plugins/marketplace.json 2>/dev/null; then
  sed -i -z 's|"source": "url",\n\( *\)"url": "\./"|"source": "local",\n\1"path": "./"|' .agents/plugins/marketplace.json
  echo "  манифест: .agents/plugins/marketplace.json: источник url -> local"
fi
# using-superpowers требует загружать скиллы «при 1% шансе» и начинать любую задачу с brainstorming:
# это ломает порог запуска тяжёлой цепочки. В Claude Code его гасит skillOverrides, а у Codex,
# Antigravity и Cursor такого рубильника на скилл плагина нет, поэтому описание переписывается
# в копии: скилл остаётся в дереве (на него ссылаются другие скиллы), но срабатывать не должен.
UP=skills/using-superpowers/SKILL.md
if [ -f "$UP" ] && grep -q '^description: Use when starting any conversation' "$UP"; then
  sed -i 's|^description: Use when starting any conversation.*|description: Disabled in this setup, do not invoke. Starting a conversation does not require loading skills; superpowers-dim:lite is the default for routine changes, the heavy chain only on explicit request.|' "$UP"
  echo "  описание using-superpowers: отключено в этой сборке"
fi
# Метка для tests/dim/invariants.sh: имена манифестов проверяются только на ребрендированном дереве.
: > .dim-rebranded

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

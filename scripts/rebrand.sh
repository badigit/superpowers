#!/usr/bin/env bash
# Приводит namespace скиллов к бренду форка: superpowers: -> superpowers-dim:
#
# Идемпотентен: строка "superpowers-dim:" не содержит подстроки "superpowers:",
# поэтому повторный прогон ничего не меняет.
#
# Зачем скриптом, а не рукописным патчем: этими файлами владеет апстрим. При
# конфликте на rebase берём АПСТРИМНУЮ версию строки и прогоняем этот скрипт
# заново — разрешение конфликта становится детерминированным и не требует
# суждения. Это то, что делает патчи в апстримных файлах дешёвыми.
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
done < <(grep -rl "superpowers:" skills/ tests/ 2>/dev/null || true)

if [ "$count" -eq 0 ]; then
  echo "namespace уже приведён к ${BRAND}: — изменений нет"
else
  echo "готово: файлов изменено — ${count}"
fi

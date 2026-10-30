#!/usr/bin/env bash
# Инварианты форка superpowers-dim: bash + grep, без LLM, секунды.
#
# Зачем: при синке апстрим молча переписывает скиллы, и наша врезка (указатель на
# beads-bridge, автомерж, пустой hooks.json) пропадает без ошибки. Тест ловит это
# до установки. Установщик (scripts/install-superpowers-dim.ps1 в мастерской)
# вызывает его на собранной копии и отказывается ставить при провале.
#
# Использование: bash tests/dim/invariants.sh [корень-дерева]
# Корень по умолчанию — репозиторий форка. Namespace не важен: принимаются
# и `superpowers:`, и `superpowers-dim:` (дерево до и после ребрендинга).
#
# Проверка мутацией: на чистом upstream/main тест ОБЯЗАН упасть.
set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT" || { echo "нет каталога: $ROOT" >&2; exit 2; }

fail=0
ok()  { echo "ok    $1"; }
bad() { echo "FAIL  $1"; fail=$((fail + 1)); }

# 1. hooks.json ровно {"hooks":{}}: отсутствующее поле, [] и пустой инлайн-список
#    схлопываются обратно в auto-discovery SessionStart-хука апстрима.
if [ -f hooks/hooks.json ] && [ "$(tr -d ' \t\r\n' < hooks/hooks.json)" = '{"hooks":{}}' ]; then
  ok "hooks/hooks.json пуст ({\"hooks\":{}})"
else
  bad "hooks/hooks.json не равен {\"hooks\":{}}: SessionStart-инъекция вернётся"
fi

# 2. Указатели на beads-bridge и автомерж в апстримных файлах.
has() { # файл, шаблон, описание
  if [ -f "$1" ] && grep -Eq -- "$2" "$1"; then ok "$3"; else bad "$3 ($1)"; fi
}
has skills/brainstorming/SKILL.md                    'beads-bridge'    "brainstorming ссылается на beads-bridge"
has skills/writing-plans/SKILL.md                    'beads-bridge'    "writing-plans ссылается на beads-bridge"
has skills/verification-before-completion/SKILL.md   'bd remember'     "verification-before-completion: bd remember"
has skills/finishing-a-development-branch/SKILL.md   'beads-bridge'    "finishing ссылается на beads-bridge"
has skills/finishing-a-development-branch/SKILL.md   'integrate autonomously' "finishing: автомерж по умолчанию"

# 2b. Бюджетные правила в SDD (замена снятого режима batched): свой файл с тремя
#     правилами и указатель на него из апстримного batching.md.
B=skills/subagent-driven-development/references
if [ -f "$B/dim-budget.md" ] && grep -q 'Transcription' "$B/dim-budget.md" \
   && grep -q 'Solo-risk' "$B/dim-budget.md" && grep -q 'Re-review only on Critical' "$B/dim-budget.md" \
   && grep -q 'Risk-based TDD' "$B/dim-budget.md" && grep -q 'High-risk stays strict' "$B/dim-budget.md"; then
  ok "references/dim-budget.md: триаж, re-review только Critical, TDD по риску, high-risk strict"
else
  bad "references/dim-budget.md отсутствует или потерял одно из трёх правил"
fi
has "$B/batching.md" 'dim-budget.md' "batching.md ссылается на dim-budget.md"

# 3. Наши скиллы на месте и с фронтматтером name.
for s in lite autopilot beads-bridge; do
  if [ -f "skills/$s/SKILL.md" ] && grep -q "^name: $s\$" "skills/$s/SKILL.md"; then
    ok "скилл $s"
  else
    bad "скилл $s отсутствует или name не совпал"
  fi
done

# 4. Все ссылки superpowers(-dim):<skill> в наших скиллах и патченых файлах
#    указывают на существующий каталог skills/<skill>/.
files="skills/lite/SKILL.md skills/autopilot/SKILL.md skills/beads-bridge/SKILL.md \
skills/subagent-driven-development/references/dim-budget.md \
skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md \
skills/verification-before-completion/SKILL.md skills/finishing-a-development-branch/SKILL.md"
refs=0; broken=0
for f in $files; do
  [ -f "$f" ] || continue
  for name in $(grep -oE 'superpowers(-dim)?:[a-z][a-z0-9-]*' "$f" | sed 's/^[^:]*://' | sort -u); do
    refs=$((refs + 1))
    if [ ! -d "skills/$name" ]; then
      bad "$f: ссылка на несуществующий скилл '$name'"; broken=$((broken + 1))
    fi
  done
done
[ "$broken" -eq 0 ] && ok "ссылки на скиллы разрешаются ($refs шт.)"

# 5. После ребрендинга (если он уже прогнан) не должно остаться смеси namespace.
if grep -rq 'superpowers-dim:' skills/ 2>/dev/null; then
  if grep -rn 'superpowers:' skills/ 2>/dev/null | grep -v 'superpowers-dim:' | grep -q .; then
    bad "в skills/ смесь superpowers: и superpowers-dim: (ребрендинг неполный)"
  else
    ok "namespace приведён к superpowers-dim: целиком"
  fi
fi

if [ "$fail" -eq 0 ]; then echo "ИТОГО: инварианты соблюдены"; exit 0; fi
echo "ИТОГО: нарушено инвариантов: $fail"; exit 1

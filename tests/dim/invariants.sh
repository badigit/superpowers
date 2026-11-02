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
# Проверка мутацией: на чистом upstream/main тест ОБЯЗАН упасть, а на каждой из мутаций
# из tests/dim/test-mutations.sh — тоже. Слово без структуры (комментарий со словом
# `beads-bridge`) за указатель не считается: ищется ссылка вида superpowers(-dim):beads-bridge.
set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT" || { echo "нет каталога: $ROOT" >&2; exit 2; }

fail=0
ok()  { echo "ok    $1"; }
bad() { echo "FAIL  $1"; fail=$((fail + 1)); }

REF='superpowers(-dim)?:'

# 1. hooks.json ровно {"hooks":{}}: отсутствующее поле, [] и пустой инлайн-список
#    схлопываются обратно в auto-discovery SessionStart-хука апстрима.
if [ -f hooks/hooks.json ] && [ "$(tr -d ' \t\r\n' < hooks/hooks.json)" = '{"hooks":{}}' ]; then
  ok "hooks/hooks.json пуст ({\"hooks\":{}})"
else
  bad "hooks/hooks.json не равен {\"hooks\":{}}: SessionStart-инъекция вернётся"
fi

# 2. Указатели и автомерж в апстримных файлах.
has() { # файл, шаблон (ERE), описание
  if [ -f "$1" ] && grep -Eq -- "$2" "$1"; then ok "$3"; else bad "$3 ($1)"; fi
}
has skills/brainstorming/SKILL.md                    "${REF}beads-bridge"  "brainstorming: указатель на beads-bridge"
has skills/writing-plans/SKILL.md                    "${REF}beads-bridge"  "writing-plans: указатель на beads-bridge"
has skills/verification-before-completion/SKILL.md   "${REF}beads-bridge"  "verification: указатель на beads-bridge"
has skills/verification-before-completion/SKILL.md   'bd remember'         "verification: bd remember"
has skills/finishing-a-development-branch/SKILL.md   "${REF}beads-bridge"  "finishing: указатель на beads-bridge"
has skills/finishing-a-development-branch/SKILL.md   'Fork override'       "finishing: переопределение шага 4"
has skills/finishing-a-development-branch/SKILL.md   'integrate autonomously' "finishing: автомерж по умолчанию"
has skills/finishing-a-development-branch/SKILL.md   'unresolved Critical or Important' "finishing: остаточные находки SDD останавливают автомерж"

# 2b. Бюджетные правила в SDD (замена снятого режима batched): свой файл с тремя
#     правилами, указатель из основного SKILL.md (виден до первого диспатча) и из batching.md.
B=skills/subagent-driven-development/references
if [ -f "$B/dim-budget.md" ] && grep -q 'Transcription' "$B/dim-budget.md" \
   && grep -q 'Solo-risk' "$B/dim-budget.md" && grep -q 'Re-review only on Critical' "$B/dim-budget.md" \
   && grep -q 'Risk-based TDD' "$B/dim-budget.md" && grep -q 'High-risk stays strict' "$B/dim-budget.md"; then
  ok "references/dim-budget.md: триаж, re-review только Critical, TDD по риску, high-risk strict"
else
  bad "references/dim-budget.md отсутствует или потерял одно из трёх правил"
fi
has skills/subagent-driven-development/SKILL.md "references/dim-budget\.md" "SDD SKILL.md: указатель на dim-budget.md"
has "$B/batching.md"                            'dim-budget\.md'            "batching.md: указатель на dim-budget.md"

# 2c. Манифесты плагина: валидный JSON и наши имена (python есть везде, где собирается копия;
#     если его нет, проверка по grep).
for m in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  if [ -f "$m" ] && grep -q '"name": "superpowers-dim"' "$m" \
     && { ! command -v python >/dev/null 2>&1 || python -m json.tool "$m" >/dev/null 2>&1; }; then
    ok "манифест $m"
  else
    bad "манифест $m отсутствует, не JSON или не superpowers-dim"
  fi
done
has .claude-plugin/marketplace.json '"name": "dim"' "marketplace называется dim"
# Манифесты Codex, Antigravity, Cursor: имя совпадает с namespace скиллов (только после ребрендинга).
if [ -f .dim-rebranded ]; then
  has skills/using-superpowers/SKILL.md '^description: Disabled in this setup' "using-superpowers: описание отключено (не требует грузить скиллы при каждом запросе)"
  has skills/brainstorming/SKILL.md '^description: "Use for work that spans several' "brainstorming: описание с порогом (не «обязателен перед любой творческой работой»)"
  has skills/brainstorming/SKILL.md '<TEMPORARY-DIM-DESIGN-POLICY>' "brainstorming: временная политика без обязательного design approval"
  has skills/brainstorming/SKILL.md 'Do not pause solely to request approval of the design doc' "brainstorming: ожидание design approval отключено"
  if grep -q 'Nothing gets built until your human partner approves the design doc' skills/brainstorming/SKILL.md; then
    bad "brainstorming: обязательный design approval вернулся"
  else
    ok "brainstorming: прежний design approval gate отсутствует"
  fi
  for m in .codex-plugin/plugin.json .antigravity-plugin/plugin.json .cursor-plugin/plugin.json .agents/plugins/marketplace.json; do
    # Манифест обязан быть валидным JSON: проверка строк «имя на месте» повреждённый файл пропускала.
    if [ -f "$m" ] && { ! command -v python >/dev/null 2>&1 || python -m json.tool "$m" >/dev/null 2>&1; }; then
      ok "манифест $m: валидный JSON"
    else
      bad "манифест $m отсутствует или не JSON"
    fi
  done
  for m in .codex-plugin/plugin.json .antigravity-plugin/plugin.json .cursor-plugin/plugin.json; do
    has "$m" '"name": "superpowers-dim"' "манифест $m: имя superpowers-dim"
  done
  has .agents/plugins/marketplace.json '"path": "\./"' "Codex marketplace: путь источника ./"
  has .agents/plugins/marketplace.json '"name": "superpowers-dim"' "Codex marketplace: плагин superpowers-dim"
  has .agents/plugins/marketplace.json '"name": "dim"' "Codex marketplace называется dim"
  has .agents/plugins/marketplace.json '"source": "local"' "Codex marketplace: локальный источник, а не git url"
fi
has scripts/rebrand.sh 'superpowers-dim' "scripts/rebrand.sh на месте"
has skills/finishing-a-development-branch/SKILL.md 'When you do show the menu' "finishing: фраза «ждать ответа» привязана к меню"

# 3. Наши скиллы на месте и с фронтматтером name.
for s in lite autopilot beads-bridge; do
  if [ -f "skills/$s/SKILL.md" ] && grep -q "^name: $s\$" "skills/$s/SKILL.md"; then
    ok "скилл $s"
  else
    bad "скилл $s отсутствует или name не совпал"
  fi
done

# 4. Все ссылки superpowers(-dim):<skill> во ВСЕХ файлах skills/ и tests/claude-code/ ведут
#    на существующий skills/<skill>/SKILL.md с совпадающим name.
refs=0; broken=0
while IFS= read -r name; do
  [ -n "$name" ] || continue
  refs=$((refs + 1))
  if [ ! -f "skills/$name/SKILL.md" ]; then
    bad "ссылка на скилл '$name': нет skills/$name/SKILL.md"; broken=$((broken + 1))
  elif ! grep -q "^name: $name\$" "skills/$name/SKILL.md"; then
    bad "skills/$name/SKILL.md: name не совпадает с каталогом"; broken=$((broken + 1))
  fi
done < <(grep -rhoE "${REF}[a-z][a-z0-9-]*" skills tests/claude-code 2>/dev/null | sed 's/^[^:]*://' | sort -u)
[ "$broken" -eq 0 ] && ok "ссылки на скиллы разрешаются ($refs уникальных)"

# 5. Если ребрендинг уже прогнан, смеси namespace быть не должно. Подстрока
#    `superpowers:` не входит в `superpowers-dim:`, поэтому строка не исключается целиком.
if grep -rq 'superpowers-dim:' skills/ 2>/dev/null; then
  if grep -rn 'superpowers:' skills/ 2>/dev/null | grep -q .; then
    bad "в skills/ остался апстримный namespace superpowers: при брендированном дереве"
  else
    ok "namespace приведён к superpowers-dim: целиком"
  fi
fi

if [ "$fail" -eq 0 ]; then echo "ИТОГО: инварианты соблюдены"; exit 0; fi
echo "ИТОГО: нарушено инвариантов: $fail"; exit 1

#!/usr/bin/env bash
# Проверка мутацией для tests/dim/invariants.sh: тест обязан ПАДАТЬ на каждой поломке.
# Зелёный прогон инвариантов ничего не доказывает, пока не показано, что он умеет падать.
#
# Использование: bash tests/dim/test-mutations.sh [корень-дерева-форка]
# Каждая мутация правит копию дерева; ожидаемый результат — ненулевой код invariants.sh.
set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# База: исходное дерево обязано быть зелёным, иначе мутации ничего не значат.
if ! bash "$ROOT/tests/dim/invariants.sh" "$ROOT" >/dev/null; then
  echo "FAIL  исходное дерево уже нарушает инварианты"; exit 1
fi

fails=0
mutate() { # имя, команда-мутация (выполняется в копии)
  local name="$1" cmd="$2" d="$WORK/m"
  rm -rf "$d"; mkdir -p "$d"
  (cd "$ROOT" && tar -c --exclude=.git . ) | tar -x -C "$d"
  ( cd "$d" && eval "$cmd" ) >/dev/null 2>&1
  if bash "$d/tests/dim/invariants.sh" "$d" >/dev/null 2>&1; then
    echo "FAIL  мутация НЕ поймана: $name"; fails=$((fails + 1))
  else
    echo "ok    поймана: $name"
  fi
}

mutate "вернулся SessionStart-хук"        'cp hooks/hooks.json x && printf "{\"hooks\":{\"SessionStart\":[]}}" > hooks/hooks.json'
mutate "указатель writing-plans — комментарий" "sed -i 's/superpowers:beads-bridge/# beads-bridge removed/' skills/writing-plans/SKILL.md"
mutate "указатель brainstorming удалён"   "sed -i '/beads-bridge/d' skills/brainstorming/SKILL.md"
mutate "bd remember удалён из verification" "sed -i 's/bd remember/remember/' skills/verification-before-completion/SKILL.md"
mutate "автомерж удалён из finishing"     "sed -i 's/integrate autonomously/ask the user/' skills/finishing-a-development-branch/SKILL.md"
mutate "скилл lite удалён"                "rm -rf skills/lite"
mutate "битая ссылка в неперечисленном файле" "echo 'see superpowers:xyz-missing' >> skills/executing-plans/SKILL.md"
mutate "каталог скилла есть, SKILL.md нет" "rm skills/requesting-code-review/SKILL.md"
mutate "name скилла разошёлся с каталогом" "sed -i 's/^name: lite/name: lite-x/' skills/lite/SKILL.md"
mutate "бюджетные правила потеряли Critical" "sed -i 's/Re-review only on Critical/Re-review always/' skills/subagent-driven-development/references/dim-budget.md"
mutate "указатель на dim-budget из SDD удалён" "sed -i 's#references/dim-budget\\.md#references/other.md#g' skills/subagent-driven-development/SKILL.md"
mutate "смесь namespace в одной строке"   "bash scripts/rebrand.sh; echo 'x superpowers-dim:lite and superpowers:lite' >> skills/lite/SKILL.md"

if [ "$fails" -eq 0 ]; then echo "ИТОГО: все мутации пойманы"; exit 0; fi
echo "ИТОГО: пропущено мутаций: $fails"; exit 1

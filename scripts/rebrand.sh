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
# Описание brainstorming в апстриме («обязателен перед любой творческой работой») читают как порог:
# агент открывает тяжёлую цепочку на любой запрос. Порог нашего контура: несколько подсистем, неясный
# дизайн, высокий риск или прямая просьба; рутина идёт через lite. Правило лежит в описании, потому что
# у Codex профиль правил ограничен по размеру, а описание читают в момент выбора скилла в любом харнессе.
BR=skills/brainstorming/SKILL.md
if [ -f "$BR" ] && grep -q '^description: "You MUST use this before any creative work' "$BR"; then
  sed -i 's|^description: "You MUST use this before any creative work.*|description: "Use for work that spans several independent subsystems, has an unclear design, carries high risk (auth, payments, migrations, concurrency, public API), or when the user asks for brainstorming, a spec, a plan, or superpowers. Not for routine changes: those go through superpowers-dim:lite."|' "$BR"
  echo "  описание brainstorming: порог тяжёлой цепочки"
fi
# Временная политика владельца: обязательное ожидание утверждения спеки мешает продолжать
# уже порученную работу. Накладываем только на сборочную копию; апстримный скилл не меняем.
# Вернуть прежний gate: revert коммита этой политики и штатная переустановка плагина.
python - <<'PY'
from pathlib import Path
import re

path = Path('skills/brainstorming/SKILL.md')
text = path.read_bytes().decode('utf-8')
marker = '<TEMPORARY-DIM-DESIGN-POLICY>'
if marker not in text:
    old_step = '3. Get their approval of that doc.'
    if old_step not in text or '<HARD-GATE>' not in text or '</HARD-GATE>' not in text:
        raise SystemExit('brainstorming changed upstream: review temporary design approval policy before packaging')
    text = text.replace(old_step, '3. Self-review that doc and resolve material ambiguities; do not wait for routine approval.', 1)
    policy = '''<TEMPORARY-DIM-DESIGN-POLICY>
The owner's mandatory design-document approval checkpoint is temporarily
suspended in this fork. Do not pause solely to request approval of the design doc.
Once the requested direction is clear, write and review the design, then invoke
superpowers-dim:writing-plans and continue the authorized work. A separate
approval message is not required. State assumptions and resolve routine choices
yourself; ask only when a material ambiguity prevents useful work or when the
owner explicitly requested a checkpoint such as "show me first".

Keep design review, verification and the owner's scope constraints. This policy
does not grant new access, bypass permission controls or authorize production
delivery. It takes precedence over references elsewhere in this skill to waiting
for design approval. It remains active until the owner restores the checkpoint.
</TEMPORARY-DIM-DESIGN-POLICY>'''
    text, count = re.subn(r'<HARD-GATE>.*?</HARD-GATE>', lambda _: policy, text, count=1, flags=re.S)
    if count != 1:
        raise SystemExit('expected exactly one design approval gate')
    text = text.replace('A design doc you haven\'t written isn\'t approved.',
                        'Write and self-review the design; the temporary fork policy does not require a separate approval message.')
    text = text.replace('Keeping it is a new request. Back through the gate.',
                        'Keeping it needs a real design and the owner\'s authorized scope; use the temporary fork policy.')
    path.write_bytes(text.encode('utf-8'))
    print('  brainstorming: mandatory design approval temporarily suspended')
PY

# Метка для tests/dim/invariants.sh: имена манифестов проверяются только на ребрендированном дереве.
: > .dim-rebranded

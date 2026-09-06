#!/usr/bin/env bash
# ความจริงของโปรเจกต์ ณ ตอนนี้ — อ่านจาก git / โค้ด / ฐานข้อมูล ไม่ใช่จากเอกสาร
#
# ทำไมถึงมีไฟล์นี้: 2026-09-06 เอกสารใน docs/handoff/ ผิดพร้อมกัน 3 จุด
#   - baseline test เขียนว่า fail 16 ของจริง 17
#   - school_admin_energy_page เขียนว่า "ต่อครบแล้ว เหลือแค่งาน DoD"
#     ทั้งที่มี fallback ปลอม 10 ตัวที่ลอกมาจากไฟล์ screenshot test
#   - school_alerts_page เขียนว่าผ่าน DoD ทั้งที่ filter 4 ตัวกรองอะไรไม่ได้เลย
# เอกสารที่เป็นข้อความจะเน่าเงียบ ๆ เสมอเพราะไม่มีอะไรบังคับให้มันตรง
# สคริปต์อ่านของจริงทุกครั้งที่รัน จึงโกหกไม่ได้
#
# ⚠️ ข้อจำกัดที่ต้องรู้: สคริปต์นี้บอกได้ว่า "อะไรอยู่ตรงไหน"
#    บอกไม่ได้ว่า "หน้านี้ซื่อสัตย์ไหม" — เรื่องนั้นต้องอ่านทั้งไฟล์เสมอ
#    grep พิสูจน์ได้แค่ "ไม่ต่อ backend แน่ ๆ" ไม่เคยพิสูจน์ว่า "ต่อครบแล้ว"
#
# ใช้:  ./scripts/state.sh           สถานะย่อ (เร็ว ~2 วิ) — เอาไป paste ให้ AI ตัวอื่นได้เลย
#       ./scripts/state.sh --test    เพิ่มผลรัน flutter test (~90 วิ)
#       ./scripts/state.sh --log     ประวัติงานที่สร้างจาก git log (ใคร/เมื่อไหร่/ทำไม)
#       ./scripts/state.sh --full    ทุกอย่าง

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

WITH_TEST=0; MODE=state
for arg in "$@"; do
  case "$arg" in
    --test) WITH_TEST=1 ;;
    --log)  MODE=log ;;
    --full) WITH_TEST=1; MODE=full ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
  esac
done

APP=apps/user_app
SA=$APP/lib/pages/school_admin
EX=$APP/lib/pages/executive_redesign_prototype/pages
DB=supabase_db_aiot-school-lab

hr() { printf '─%.0s' $(seq 1 62); echo; }

# ───────────────────────────────────────────── ประวัติงานจาก git
if [ "$MODE" = log ] || [ "$MODE" = full ]; then
  echo "═══ ประวัติงาน (สร้างจาก git — แก้ย้อนหลังไม่ได้) ═══"
  echo
  since="${SINCE:-3 days ago}"
  # git ตีความวันที่เปล่า ๆ อย่าง 2026-09-06 เป็น "วันนั้นเวลาปัจจุบัน" ทำให้ได้
  # ผลลัพธ์ว่างแบบงง ๆ — เติมเวลาให้เองถ้าผู้ใช้ใส่มาแค่วันที่
  case "$since" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) since="$since 00:00" ;;
  esac
  git log --since="$since" --reverse \
    --format='%n── %h  %ad  %an%n   %s%n%w(76,3,3)%b' \
    --date=format:'%d/%m %H:%M' | sed '/^\s*Co-Authored-By:/d'
  echo
  echo "(ช่วงเวลา: $since — เปลี่ยนได้ด้วย SINCE='2 weeks ago' ./scripts/state.sh --log)"
  [ "$MODE" = log ] && exit 0
  echo
fi

# ───────────────────────────────────────────── 1. sync
echo "═══ 1. งานที่ทำไปแล้วอยู่ที่ไหน ═══"
branch=$(git branch --show-current)
tracking=$(git status -sb | head -1 | grep -oE '\[.*\]' || echo '[ไม่ได้ track remote]')
dirty=$(git status --porcelain | wc -l | tr -d ' ')
unpushed=$(git log --branches --not --remotes --oneline 2>/dev/null | wc -l | tr -d ' ')
printf 'branch      %s %s\n' "$branch" "$tracking"
printf 'ยังไม่ commit  %s ไฟล์\n' "$dirty"
if [ "$unpushed" -gt 0 ]; then
  printf '⚠️  ยังไม่ push  %s commits — AI ตัวอื่นมองไม่เห็นงานนี้\n' "$unpushed"
else
  printf 'push แล้ว    ครบ\n'
fi

echo
echo "เลนอื่นที่มีงาน (ใช้ git เป็นตัวจองงาน — เลี่ยงแตะเลนที่เพิ่งขยับ):"
git for-each-ref --sort=-committerdate refs/remotes \
  --format='  %(refname:short)|%(committerdate:relative)|%(contents:subject)' \
  2>/dev/null | grep -v 'HEAD ->' | head -4 | cut -c1-100 | column -t -s'|'

# ───────────────────────────────────────────── 2. build
hr
echo "═══ 2. build & test ═══"
line='analyze     '
for p in packages/shared_core packages/shared_ui $APP; do
  n=$(cd "$p" && flutter analyze 2>/dev/null | grep -cE "^[[:space:]]+error •")
  line="$line$(basename "$p") ${n:-?} error · "
done
echo "${line% · }"
echo '            ↑ ต้องเช็คทั้ง 3 แพ็กเกจ — analyze ใน user_app ไม่ครอบ shared_ui'
echo '              (เคยปล่อยของพังผ่านมาแล้วเพราะเช็คแค่ตัวเดียว)'

if [ "$WITH_TEST" = 1 ]; then
  echo -n 'test        '
  out=$( (cd $APP && flutter test --reporter compact 2>&1) | tr '\r' '\n')
  echo "$out" | grep -oE '\+[0-9]+ -[0-9]+: (Some tests failed|All tests passed)' | tail -1
  echo "$out" | grep -oE "test/[A-Za-z0-9_/]+\.dart: [^|]*\[E\]" \
    | sed 's|:.*||' | sort | uniq -c | sort -rn | head -8 | sed 's/^/            /'
else
  echo 'test        (ข้าม — ใส่ --test เพื่อรันจริง)'
fi

# ───────────────────────────────────────────── 3. รายหน้า
hr
echo "═══ 3. สถานะรายหน้า ═══"
role_status() {
  local dir=$1 label=$2 testdir=$3
  local total done_n disconnected
  total=$(ls -1 "$dir"/*.dart 2>/dev/null | wc -l | tr -d ' ')
  done_n=$(ls -1 "$testdir"/*connection_test.dart 2>/dev/null | wc -l | tr -d ' ')
  printf '%-14s %s หน้า · มี connection test %s\n' "$label" "$total" "$done_n"
  disconnected=""
  for f in "$dir"/*.dart; do
    grep -q "package:shared_core" "$f" || disconnected="$disconnected $(basename "$f" .dart)"
  done
  [ -n "$disconnected" ] && echo "  ❌ ไม่ import shared_core (แตะ backend ไม่ได้ 100%):$disconnected"
}
role_status "$SA" "School Admin" "$APP/test/school_admin"
role_status "$EX" "Executive" "$APP/test/executive"

# ───────────────────────────────────────────── 4. กับดัก RPC
hr
echo "═══ 4. 🔴 RPC ที่เรียกจากแอปนี้ไม่ได้ ═══"
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "$DB"; then
  # คู่แฝดสำคัญมาก: หลายตัวมีเวอร์ชัน _for_school_admin / _for_super_admin ที่รับ
  # p_token อยู่แล้ว ถ้าไม่โชว์ คนอ่านจะนึกว่าหน้าที่เรียกมันพัง
  docker exec -i "$DB" psql -U postgres -d postgres -At -F'|' -c "
    with unusable as (
      select p.proname
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.prokind = 'f'
        and pg_get_function_arguments(p.oid) not like 'p_token%'
        and (p.prosrc ilike '%is_super_admin()%' or p.prosrc ilike '%has_role(%'
             or p.prosrc ilike '%current_user_school_id()%')
    )
    select u.proname,
           coalesce((select string_agg(a.proname, ', ')
                     from pg_proc a join pg_namespace an on an.oid = a.pronamespace
                     where an.nspname = 'public'
                       and a.proname like u.proname || '\_for\_%'
                       and pg_get_function_arguments(a.oid) like 'p_token%'), '— ไม่มีตัวแทน')
    from unusable u order by 1;" 2>/dev/null \
    | awk -F'|' '{printf "  ✗ %-28s → ใช้แทน: %s\n", $1, $2}'
  echo
  echo '  ↑ ไม่มี p_token + ใช้ helper ที่อิง auth.uid() = เป็นของ aiot_dev_dashboard'
  echo '    เรียกจาก my_first_app แล้ว actor เป็น null เงียบ ๆ ไม่ error (hard rule 1)'
  echo '    เช็ค p_token ในลายเซ็นก่อนเสมอ อย่าดูแค่ชื่อ RPC'
else
  echo '  (ข้าม — Docker/Supabase ไม่ได้รันอยู่)'
fi

# ───────────────────────────────────────────── 5. จุดที่ต้องไปอ่านเอง
hr
echo "═══ 5. จุดที่ต้องไปอ่านเอง (ไม่ใช่ 'ปลอมแน่นอน') ═══"
count_in() { grep -rlE "$1" "$2"/*.dart 2>/dev/null | wc -l | tr -d ' '; }
printf '  catch (_) {} กลืน error        %s หน้า (School Admin)\n' "$(count_in 'catch \(_\) \{\}' "$SA")"
printf '  fallback ?? ค่าคงที่            %s หน้า\n' "$(count_in "\?\? *'[0-9ก-๙]" "$SA")"
no_empty=0
for f in "$SA"/*.dart; do grep -q 'ยังไม่มีข้อมูล' "$f" || no_empty=$((no_empty+1)); done
printf '  ไม่มีคำว่า ยังไม่มีข้อมูล          %s หน้า\n' "$no_empty"
echo '  ⚠️ ตัวเลขพวกนี้เคยนับผิดมาแล้ว 3 รอบ (ดู MASTER_PLAN §0) — ใช้เป็นจุดตั้งต้นในการอ่าน'

# ───────────────────────────────────────────── 6. ฐานข้อมูล
hr
echo "═══ 6. ฐานข้อมูล local ═══"
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "$DB"; then
  docker exec -i "$DB" psql -U postgres -d postgres -At -F' ' -c "
    select 'sensor_readings ' || (select count(*) from sensor_readings)
        || ' แถว · devices.building null '
        || (select count(*) from devices where building is null) || '/'
        || (select count(*) from devices);" 2>/dev/null | sed 's/^/  /'
  echo '  ↑ ถ้า sensor_readings ว่าง ทุกหน้าที่ใช้ utility RPC จะขึ้น "ยังไม่มีข้อมูล"'
  echo '    ซึ่งถูกต้อง — fallback ปลอมที่เคยมีคือสิ่งที่ปิดบังข้อนี้ไว้'
else
  echo '  Supabase ไม่ได้รันอยู่ — open -a Docker && npx supabase start'
fi

# ───────────────────────────────────────────── 7. ถัดไป
hr
echo "═══ 7. ถัดไป ═══"
echo '  แผนรายหน้า      docs/handoff/SCHOOL_ADMIN_BACKEND_SURVEY.md'
echo '                  docs/handoff/EXECUTIVE_BACKEND_SURVEY.md'
echo '  ตัดสินใจค้าง +   docs/handoff/WORK_LOG.md (ส่วนบนสุด)'
echo '  งานค้างตอนนี้'
echo
echo '  ⚠️ ห้ามสรุปว่าหน้าไหนเสร็จจากเอกสาร — ต้องอ่านไฟล์เต็มเอง'

#!/bin/bash
set -e
# Apply Phase 1 db changes for room-based timetable enrollment
echo "Applying 20260919000000_admin_timetable_enrollment.sql to production..."
npx supabase db push
echo "Done."

-- =====================================================================
-- Cosmetic cleanup found during the 2026-08-27 RBAC audit continuation:
-- set_facility_manager_building's logic was already correctly updated to
-- check school_admin/super_admin (facility_manager was merged into
-- school_admin on 2026-08-25), but the function kept its pre-merge name.
-- Not called from any client code (grep confirmed) — safe rename.
-- ALTER FUNCTION RENAME preserves existing grants, unlike DROP+CREATE.
-- =====================================================================

alter function set_facility_manager_building(text, uuid, text)
  rename to set_school_admin_building;

-- Migration: Add water_meter device_type, water_m3 metric_type, and water_rate_thb column
-- Note: Enum type additions must run in a separate transaction from function declarations in Postgres.

ALTER TYPE device_type ADD VALUE IF NOT EXISTS 'water_meter';
ALTER TYPE metric_type ADD VALUE IF NOT EXISTS 'water_m3';

ALTER TABLE school_settings ADD COLUMN IF NOT EXISTS water_rate_thb numeric;
COMMENT ON COLUMN school_settings.water_rate_thb IS 'Estimated water rate per m3 in THB';

-- Migration: Add gas_mq2_percent metric_type value
-- Reconciles schema drift: production already accepts this value for MQ-2
-- gas sensor readings ingested via tools/mqtt_to_database.py (added
-- out-of-band, not through a migration — confirmed missing from local dev's
-- metric_type enum, which is built purely from this repo's migrations).
-- This brings local dev / any fresh environment in line with what
-- production has actually been running.

ALTER TYPE metric_type ADD VALUE IF NOT EXISTS 'gas_mq2_percent';

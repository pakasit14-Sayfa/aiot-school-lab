-- =====================================================================
-- Migration: add co2/tvoc to metric_type
--
-- The real board already measures these (SGP-series gas sensor: eCO2 in
-- ppm, TVOC in ppb) but sensor_ingest has always rejected them silently
-- (unknown_metric) since metric_type never had these values — found
-- live while replacing a hardcoded fake "CO₂ 690 ppm" on the executive
-- dashboard with real data and discovering there was no real value to
-- use at all. This migration only makes the values acceptable to
-- sensor_ingest; the firmware still needs to actually send them (see
-- HANDOFF.md for the exact payload addition needed).
-- =====================================================================

alter type metric_type add value if not exists 'co2';
alter type metric_type add value if not exists 'tvoc';

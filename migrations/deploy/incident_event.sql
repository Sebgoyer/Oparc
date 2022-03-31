BEGIN;

CREATE VIEW incident_events AS
SELECT id, public_name AS name, opening_hour, opening_hour+open_duration AS closing_hour FROM "event"
WHERE id NOT IN (
    SELECT event_id FROM incident WHERE close_date IS NULL
) ORDER BY id;

COMMIT;
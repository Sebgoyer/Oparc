BEGIN;

CREATE VIEW opened_events AS
SELECT 
    "event".*, 
    opening_hour + open_duration AS closing_hour,
    (
        now() > current_date + opening_hour 
        AND now() < current_date + opening_hour + open_duration
    
    OR
        now() > current_date - '24 hours'::interval + opening_hour 
        AND now() < current_date - '24 hours'::interval + opening_hour + open_duration
    ) AS "open"
FROM "event"
WHERE "event".id NOT IN (
    SELECT DISTINCT event_id FROM incident
    WHERE close_date IS NULL
);

COMMIT;
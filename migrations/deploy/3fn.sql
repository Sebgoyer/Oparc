BEGIN;

ALTER TABLE "event"
    ADD COLUMN open_duration INTERVAL;

UPDATE "event" SET open_duration = closing_hour - opening_hour;

UPDATE "event" SET open_duration = open_duration + '24 hours' WHERE open_duration < '0';

ALTER TABLE "event"
    ALTER COLUMN open_duration SET NOT NULL;

ALTER TABLE "event"
    DROP COLUMN closing_hour;

COMMIT;
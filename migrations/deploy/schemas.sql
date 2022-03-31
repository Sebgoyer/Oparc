BEGIN;

CREATE SCHEMA booking;

ALTER DOMAIN posint SET SCHEMA booking;

ALTER TABLE visitor SET SCHEMA booking;
ALTER TABLE booking SET SCHEMA booking;
ALTER TABLE "event" SET SCHEMA booking;

ALTER VIEW identified_visitor SET SCHEMA booking;
ALTER VIEW opened_events SET SCHEMA booking;

ALTER FUNCTION next_ride(json) SET SCHEMA booking;
ALTER FUNCTION new_booking(json) SET SCHEMA booking;


CREATE SCHEMA incident;

ALTER TABLE incident SET SCHEMA incident;
ALTER TABLE comment SET SCHEMA incident;

ALTER VIEW detailed_incident SET SCHEMA incident;
ALTER VIEW incident_events SET SCHEMA incident;

DROP FUNCTION clean_bookings(int);

CREATE FUNCTION incident.clean_bookings(int) RETURNS void AS $$
    DELETE FROM booking.booking 
    WHERE event_id=$1
    AND scheduled_time >= now()
    AND scheduled_time <= now()+'1 hour'::interval
$$ LANGUAGE sql STRICT SECURITY DEFINER;

DROP FUNCTION new_incident(json);

CREATE FUNCTION incident.new_incident(json) RETURNS int AS $$
    SELECT incident.clean_bookings(($1->>'event_id')::int);
    INSERT INTO incident.incident (incident_number, nature, technician, event_id) VALUES (
        $1->>'incident_number',
        $1->>'nature',
        $1->>'technician',
        ($1->>'event_id')::int
    ) RETURNING id;
$$ LANGUAGE sql STRICT;

DROP FUNCTION clean_bookings(json);

CREATE FUNCTION incident.clean_bookings(json) RETURNS void AS $$
    DELETE FROM booking.booking 
    WHERE event_id=($1->>'event_id')::int
    AND scheduled_time >= now()
    AND (
            (
                ($1->>'opening_hour')::time < ($1->>'closing_hour')::time AND 
                scheduled_time < (current_date+'1 day'::interval+'00:00:00'::time)::timestamptz AND 
				(
					scheduled_time < (current_date + ($1->>'opening_hour')::time)::timestamptz
					OR
					scheduled_time > (current_date + ($1->>'closing_hour')::time)::timestamptz
				)
			)
        OR
            (
                ($1->>'opening_hour')::time > ($1->>'closing_hour')::time AND 
                scheduled_time < (current_date+'1 day'::interval + ($1->>'opening_hour')::time)::timestamptz AND 
				(
                    scheduled_time < (current_date + ($1->>'opening_hour')::time)::timestamptz
					OR
					scheduled_time > (current_date+'1 day'::interval + ($1->>'closing_hour')::time)::timestamptz
				)
			)
    )
$$ LANGUAGE sql STRICT SECURITY DEFINER;

DROP FUNCTION modify_event(json);

CREATE FUNCTION incident.modify_event(json) RETURNS void AS $$
    SELECT incident.clean_bookings($1);
    UPDATE booking.event SET 
        opening_hour=($1->>'opening_hour')::time,
        open_duration=
            CASE
                WHEN ($1->>'closing_hour')::time > ($1->>'opening_hour')::time
                THEN
                    ($1->>'closing_hour')::time-($1->>'opening_hour')::time
                ELSE
                    ($1->>'closing_hour')::time-($1->>'opening_hour')::time + '24 hours'::interval
                END
        
        WHERE id=($1->>'event_id')::int
$$ LANGUAGE sql STRICT SECURITY DEFINER;

ALTER FUNCTION new_incident_with_comment(json) SET SCHEMA incident;
ALTER FUNCTION update_incident(json) SET SCHEMA incident;
ALTER FUNCTION update_incident_with_comment(json) SET SCHEMA incident;


COMMIT;
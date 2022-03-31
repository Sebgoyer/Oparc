BEGIN;

CREATE FUNCTION clean_bookings(json) RETURNS void AS $$
    DELETE FROM booking 
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

CREATE FUNCTION modify_event(json) RETURNS void AS $$
    SELECT clean_bookings($1);
    UPDATE event SET 
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

COMMIT;
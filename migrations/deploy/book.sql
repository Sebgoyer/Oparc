BEGIN;

CREATE FUNCTION next_ride(json) RETURNS timestamptz AS $$
    SELECT
        y.time::timestamptz
    FROM event
    CROSS JOIN generate_series(
        ($1->>'validity_start')::date, ($1->>'validity_end')::date, '1 day'
    ) d (day) 
    CROSS JOIN generate_series(
        d.day + event.opening_hour,
        d.day + event.opening_hour + event.open_duration - '1 second'::interval,
        event.duration) y (time) 
    WHERE id = ($1->>'eventId')::int AND y.time > now() 
   
    AND y.time >= ($1->>'validity_start')::timestamptz AND y.time <= ($1->>'validity_end')::timestamptz
   
    AND capacity >= COALESCE((SELECT SUM(places) FROM booking WHERE scheduled_time=y.time AND event_id=($1->>'eventId')::int) + ($1->>'nbPlaces')::int, 0)
    ORDER BY y.time
    LIMIT 1;  
$$ LANGUAGE sql STRICT;


CREATE FUNCTION new_booking(json) RETURNS booking AS $$
    INSERT INTO booking (visitor_id, event_id, places, scheduled_time) VALUES(
        ($1->>'visitorId')::int,
        ($1->>'eventId')::int,
        ($1->>'nbPlaces')::int,
        (SELECT next_ride($1))
    ) RETURNING *;
$$ LANGUAGE sql STRICT;


COMMIT;
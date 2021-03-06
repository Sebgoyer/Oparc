BEGIN;

CREATE FUNCTION update_incident(json) RETURNS void AS $$
    UPDATE incident SET technician=$1->>'technician', close_date=
	CASE
		WHEN ($1->>'close')::boolean = true
		THEN 
			now()
		ELSE 
			NULL
	 END
	 WHERE id=($1->>'incidentId')::int;
$$ LANGUAGE sql STRICT;

CREATE FUNCTION update_incident_with_comment(json) RETURNS void AS $$
    INSERT INTO comment("text", incident_id) VALUES(
        $1->>'comment',
        ($1->>'incidentId')::int
    );
    SELECT update_incident($1);
$$ LANGUAGE sql STRICT;


COMMIT;
BEGIN;

CREATE TABLE comment (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "text" TEXT NOT NULL,
    "date" TIMESTAMPTZ NOT NULL DEFAULT now(),
    incident_id INT NOT NULL REFERENCES incident(id)
);

DROP VIEW detailed_incident;


CREATE VIEW detailed_incident AS
SELECT 
    incident.*, 
    (SELECT public_name FROM event WHERE id=incident.event_id) AS event_name,
	case
		when count(comment.*) > 0
		then
			array_agg(json_build_object('text', comment.text, 'date', comment.date) ORDER BY comment.date DESC)
		else
			'{}'
		end 
	AS comments
FROM incident
LEFT JOIN comment ON comment.incident_id=incident.id
WHERE close_date IS NULL
GROUP BY incident.id
ORDER BY open_date;

COMMIT;
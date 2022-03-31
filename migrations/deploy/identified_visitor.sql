BEGIN;

CREATE VIEW identified_visitor AS
    SELECT *, 
    (validity_start <= now() AND validity_end >= now()) AS valid_ticket,
    ((SELECT COUNT(*) FROM booking WHERE visitor_id=visitor.id) < 3) AS can_book
    FROM visitor;

COMMIT;
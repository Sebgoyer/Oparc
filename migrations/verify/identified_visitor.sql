BEGIN;

SELECT valid_ticket, can_book FROM identified_visitor WHERE false;

ROLLBACK;
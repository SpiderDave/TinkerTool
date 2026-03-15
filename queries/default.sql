-- ? <-- this is just to consume the unused language parameter
SELECT
    *

FROM
    __category__
    
WHERE
    __column__ LIKE ? ESCAPE '\'
;


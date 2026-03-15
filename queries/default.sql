-- ? <-- this is just to consume the unused language parameter
SELECT
    *

FROM
    __category__
    
WHERE
    __column__ LIKE ? ESCAPE '\' -- adding this single quote to fix incorrect syntax highlighting: '

    AND NOT EXISTS (
        SELECT 1
        FROM blacklist b
        WHERE b.category = '__category__'
          AND b.id = localized.id
    )
;


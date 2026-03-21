SELECT
    *

FROM
    __category__
    
WHERE
    __where__

    AND NOT EXISTS (
        SELECT 1
        FROM blacklist b
        WHERE b.category = '__category__'
          AND b.id = __category__.id
    )
;


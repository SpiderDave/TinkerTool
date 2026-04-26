-- Create a single-row CTE that holds the language parameter.
WITH lang(value) AS (
    SELECT "__language__"
),

-- Build a localized projection of the item table
localized AS (
    SELECT
        item.*, -- include ALL original columns

        -- Add localized variants with unique names
        COALESCE(en_replacename.name, NULLIF(en_name.text, ''), item.name) AS Name_localized

    FROM item

    -- Make lang.value visible to this query
    CROSS JOIN lang

    -- Join translation for name (filtered by chosen language)
    LEFT JOIN translations AS en_name
        ON en_name.key = item.name
       AND en_name.lang = lang.value COLLATE NOCASE

    -- Join replacelist for name
    LEFT JOIN replacelist AS en_replacename
        ON en_replacename.category = "item"
       AND en_replacename.id = item.id
)

-- Final selection with localized search
SELECT
    id

FROM
    localized
    
WHERE
    __where__
    
    AND NOT EXISTS (
        SELECT 1
        FROM blacklist b
        WHERE b.category = 'item'
          AND b.id = localized.id
    )
;


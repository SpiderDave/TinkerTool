-- Create a single-row CTE that holds the language parameter.
WITH lang(value) AS (
    SELECT "__language__"
),

-- Build a localized projection of the item table
localized AS (
    SELECT
        mob.*, -- include ALL original columns

        -- Add localized variants with unique names
        COALESCE(en_replacename.name, NULLIF(en_name.text, ''), mob.name) AS Name_localized

    FROM mob

    -- Make lang.value visible to this query
    CROSS JOIN lang

    -- Join translation for name (filtered by chosen language)
    LEFT JOIN translations AS en_name
        ON en_name.key = mob.name
       AND en_name.lang = lang.value COLLATE NOCASE

    -- Join replacelist for name
    LEFT JOIN replacelist AS en_replacename
        ON en_replacename.category = "mob"
       AND en_replacename.id = mob.id

)

-- Final selection with localized search
SELECT
    *,
    name_localized AS Name,
    name as Name_unlocalized

FROM
    localized
    
WHERE
    __where__

    AND NOT EXISTS (
        SELECT 1
        FROM blacklist b
        WHERE b.category = 'mob'
          AND b.id = localized.id
    )
;


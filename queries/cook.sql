-- Create a single-row CTE that holds the language parameter.
WITH lang(value) AS (
    SELECT ?
),

-- Build a localized projection of the item table
localized AS (
    SELECT
        cook.*, -- include ALL original columns

        -- Add localized variants with unique names
        COALESCE(NULLIF(en_name.text, ''), cook.name) AS Name_localized

    FROM cook

    -- Make lang.value visible to this query
    CROSS JOIN lang

    -- Join translation for name (filtered by chosen language)
    LEFT JOIN translations AS en_name
        ON en_name.key = cook.name
       AND en_name.lang = lang.value COLLATE NOCASE

)

-- Final selection with localized search
SELECT
    *,
    name_localized AS Name,
    name as Name_unlocalized

FROM
    localized
    
WHERE
    "__column__" LIKE ? ESCAPE '\' -- adding this single quote to fix incorrect syntax highlighting: '

    AND NOT EXISTS (
        SELECT 1
        FROM blacklist b
        WHERE b.category = 'cook'
          AND b.id = localized.id
    )
;


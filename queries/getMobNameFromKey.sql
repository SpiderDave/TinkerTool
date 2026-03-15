-- Create a single-row CTE that holds the language parameter.
WITH lang(value) AS (
    SELECT "English"
),

-- Build a localized projection of the table
localized AS (
    SELECT
        mob.name, mob.key,

        -- Add localized variants with unique names
        COALESCE(NULLIF(en_name.text, ''), mob.name) AS Name_localized

    FROM mob

    -- Make lang.value visible to this query
    CROSS JOIN lang

    -- Join translation for name (filtered by chosen language)
    LEFT JOIN translations AS en_name
        ON en_name.key = mob.name
       AND en_name.lang = lang.value COLLATE NOCASE
)

-- Final selection with localized search
SELECT DISTINCT
    name_localized AS Name

FROM
    localized

WHERE
    key = ?

LIMIT 1

;


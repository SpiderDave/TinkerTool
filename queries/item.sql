-- Create a single-row CTE that holds the language parameter.
WITH lang(value) AS (
    SELECT ?
),

-- Build a localized projection of the item table
localized AS (
    SELECT
        item.*, -- include ALL original columns

        -- Add localized variants with unique names
        COALESCE(NULLIF(en_name.text, ''), item.name) AS Name_localized,
        COALESCE(NULLIF(en_desc.text, ''), item.description) AS Description_localized,
        COALESCE(NULLIF(en_gender.text, ''), item.gender) AS Gender_localized,
        COALESCE(NULLIF(en_setdesc.text, ''), item.'set description') AS "Set Description_localized"

    FROM item

    -- Make lang.value visible to this query
    CROSS JOIN lang

    -- Join translation for name (filtered by chosen language)
    LEFT JOIN translations AS en_name
        ON en_name.key = item.name
       AND en_name.lang = lang.value COLLATE NOCASE

    -- Join translation for description
    LEFT JOIN translations AS en_desc
        ON en_desc.key = item.description
       AND en_desc.lang = lang.value COLLATE NOCASE

    -- Join translation for set description
    LEFT JOIN translations AS en_setdesc
        ON en_setdesc.key = item.'set description'
       AND en_setdesc.lang = lang.value COLLATE NOCASE

    -- Join translation for gender
    LEFT JOIN translations AS en_gender
        ON en_gender.key = item.gender
       AND en_gender.lang = lang.value COLLATE NOCASE
)

-- Final selection with localized search
SELECT DISTINCT
    *,
    name_localized AS Name,
    gender_localized AS Gender,
    description_localized AS Description,
    name as Name_unlocalized,
    description as Description_unlocalized,
    gender as Gender_unlocalized

FROM
    localized
    
WHERE
    __column__ LIKE ? ESCAPE '\' -- adding this single quote to fix incorrect syntax highlighting: '

    AND NOT EXISTS (
        SELECT 1
        FROM blacklist b
        WHERE b.category = 'item'
          AND b.id = localized.id
    )
;


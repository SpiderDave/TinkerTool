-- Create a single-row CTE that holds the language parameter.
WITH lang(value) AS (
    SELECT "__language__"
),

-- Build a localized projection of the item table
localized AS (
    SELECT
        enchant.*, -- include ALL original columns

        -- Add localized variants with unique names
        COALESCE(en_replacename.name, NULLIF(en_name.text, ''), enchant.name) AS Name_localized,
        COALESCE(NULLIF(en_desc.text, ''), enchant.description) AS Description_localized

    FROM enchant

    -- Make lang.value visible to this query
    CROSS JOIN lang

    -- Join translation for name (filtered by chosen language)
    LEFT JOIN translations AS en_name
        ON en_name.key = enchant.name
       AND en_name.lang = lang.value COLLATE NOCASE

    -- Join replacelist for name
    LEFT JOIN replacelist AS en_replacename
        ON en_replacename.category = "enchant"
       AND en_replacename.id = enchant.id

    -- Join translation for description
    LEFT JOIN translations AS en_desc
        ON en_desc.key = enchant.description
       AND en_desc.lang = lang.value COLLATE NOCASE
)

-- Final selection with localized search
SELECT
    *,
    name_localized AS Name,
    description_localized AS Description,
    name as Name_unlocalized,
    description as Description_unlocalized

FROM
    localized
    
WHERE
    __where__

    AND NOT EXISTS (
        SELECT 1
        FROM blacklist b
        WHERE b.category = 'enchant'
          AND b.id = localized.id
    )
;


-- Create a single-row CTE that holds the language parameter.
WITH lang(value) AS (
    SELECT ?
),

-- Build a localized projection of the item table
localized AS (
    SELECT
        quest.*, -- include ALL original columns

        -- Add localized variants with unique names
        COALESCE(NULLIF(en_name.text, ''), quest.title) AS Title_localized,
        COALESCE(NULLIF(en_desc.text, ''), quest.description) AS Description_localized

    FROM quest

    -- Make lang.value visible to this query
    CROSS JOIN lang

    -- Join translation for name (filtered by chosen language)
    LEFT JOIN translations AS en_name
        ON en_name.key = quest.title
       AND en_name.lang = lang.value COLLATE NOCASE

    -- Join translation for description
    LEFT JOIN translations AS en_desc
        ON en_desc.key = quest.description
       AND en_desc.lang = lang.value COLLATE NOCASE
)

-- Final selection with localized search
SELECT
    *,
    title_localized AS Title,
    description_localized AS Description,
    title as Title_unlocalized,
    description as Description_unlocalized

FROM
    localized
    
WHERE
    __column__ LIKE ? ESCAPE '\' -- adding this single quote to fix incorrect syntax highlighting: '

    AND NOT EXISTS (
        SELECT 1
        FROM blacklist b
        WHERE b.category = 'quest'
          AND b.id = localized.id
    )
;


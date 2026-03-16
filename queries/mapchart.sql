-- Create a single-row CTE that holds the language parameter.
WITH lang(value) AS (
    SELECT ?
),

-- Build a localized projection of the item table
localized AS (
    SELECT
        mapchart.*, -- include ALL original columns

        -- Add localized variants with unique names
        COALESCE(NULLIF(en_desc.text, ''), mapchart.description) AS Description_localized

    FROM mapchart

    -- Make lang.value visible to this query
    CROSS JOIN lang

    -- Join translation for description
    LEFT JOIN translations AS en_desc
        ON en_desc.key = mapchart.description
       AND en_desc.lang = lang.value COLLATE NOCASE

)

-- Final selection with localized search
SELECT
    *,
    description_localized AS Description,
    description as Description_unlocalized

FROM
    localized
    
WHERE
    "__column__" LIKE ? ESCAPE '\' -- adding this single quote to fix incorrect syntax highlighting: '

    AND NOT EXISTS (
        SELECT 1
        FROM blacklist b
        WHERE b.category = 'mapchart'
          AND b.id = localized.id
    )
;


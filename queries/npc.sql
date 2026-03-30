-- Create a single-row CTE that holds the language parameter.
WITH lang(value) AS (
    SELECT "__language__"
),

-- Build a localized projection of the item table
localized AS (
    SELECT
        npc.*, -- include ALL original columns

        -- Add localized variants with unique names
        COALESCE(en_replacename.name, NULLIF(en_name.text, ''), npc.name) AS Name_localized,
        COALESCE(NULLIF(en_first_dialogue.text, ''), npc.'First Dialogue') AS "First Dialogue_localized"

    FROM npc

    -- Make lang.value visible to this query
    CROSS JOIN lang

    -- Join translation for name (filtered by chosen language)
    LEFT JOIN translations AS en_name
        ON en_name.key = npc.name
       AND en_name.lang = lang.value COLLATE NOCASE

    -- Join replacelist for name
    LEFT JOIN replacelist AS en_replacename
        ON en_replacename.category = "npc"
       AND en_replacename.id = npc.id

    LEFT JOIN translations AS en_first_dialogue
        ON en_first_dialogue.key = npc.'First Dialogue'
       AND en_first_dialogue.lang = lang.value COLLATE NOCASE
)

-- Final selection with localized search
SELECT
    *,
    name_localized AS Name,
    localized.'First Dialogue_localized' AS "First Dialogue",
    name as Name_unlocalized,
    localized.'First Dialogue' as "First Dialogue_unlocalized"

FROM
    localized
    
WHERE
    __where__

    AND NOT EXISTS (
        SELECT 1
        FROM blacklist b
        WHERE b.category = 'npc'
          AND b.id = localized.id
    )
;


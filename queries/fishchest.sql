WITH lang(value) AS (
    SELECT ?
),

-- Collect all item/fish/biome references
all_pairs AS (
    -- Items via pools
    SELECT DISTINCT i.key AS item_key, b.key AS biome_key
    FROM fish f
    JOIN item_pool ip
      ON f.loot LIKE '%E_ITEM_POOLS.' || ip.key || '%'
    JOIN item i
      ON ip.items LIKE '%E_ITEMS.' || i.key || '%'
    JOIN biome b
      ON b."fish chests" LIKE '%' || f.key || '%'

    UNION

    -- Direct items (not in pools)
    SELECT DISTINCT i.key AS item_key, b.key AS biome_key
    FROM fish f
    JOIN item i
      ON f.loot LIKE '%E_ITEMS.' || i.key || '%'
    JOIN biome b
      ON b."fish chests" LIKE '%' || f.key || '%'
)

SELECT DISTINCT
    COALESCE(NULLIF(en_item_name.text, ''), i.name) AS item_name,
    COALESCE(NULLIF(en_biome_name.text, ''), b.name) AS biome_name

FROM all_pairs p

JOIN item i
  ON i.key = p.item_key

JOIN biome b
  ON b.key = p.biome_key

CROSS JOIN lang

LEFT JOIN translations AS en_item_name
  ON en_item_name.key = i.name
 AND en_item_name.lang = lang.value COLLATE NOCASE

LEFT JOIN translations AS en_biome_name
  ON en_biome_name.key = b.name
 AND en_biome_name.lang = lang.value COLLATE NOCASE

WHERE "__column__" LIKE ? ESCAPE '\' -- adding this single quote to fix incorrect syntax highlighting: '

  AND NOT EXISTS (
      SELECT 1
      FROM blacklist bl
      WHERE bl.category = 'item'
        AND bl.id = i.id
  )

  AND NOT EXISTS (
      SELECT 1
      FROM blacklist bl
      WHERE bl.category = 'biome'
        AND bl.id = b.id
  )

ORDER BY item_name;
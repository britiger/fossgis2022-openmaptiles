
CREATE OR REPLACE FUNCTION layer_gas(bbox geometry, zoom_level integer, pixel_width numeric)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                pipeline text,
                marker   text,
                substance text,
                pipeline_ref text,
                ref text,
                operator text
            )
AS
$$
SELECT osm_id,
        geometry,
        pipeline,
        marker,
        COALESCE(NULLIF(utility,''), NULLIF(substance,'')) AS substance,
        pipeline_ref,
        ref,
        operator
FROM osm_gas_point
WHERE zoom_level >= 12
  AND
   (COALESCE(NULLIF(utility,''), NULLIF(substance,'')) = 'gas' 
        OR COALESCE(NULLIF(utility,''), NULLIF(substance,'')) IS NULL);

$$ LANGUAGE SQL STABLE
                PARALLEL SAFE;
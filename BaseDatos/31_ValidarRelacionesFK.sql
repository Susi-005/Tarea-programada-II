USE TareaProgramada2;
GO

SELECT
    FK.name AS NombreFK,
    OBJECT_NAME(FK.parent_object_id) AS TablaOrigen,
    COL_NAME(FKC.parent_object_id, FKC.parent_column_id) AS ColumnaOrigen,
    OBJECT_NAME(FK.referenced_object_id) AS TablaDestino,
    COL_NAME(FKC.referenced_object_id, FKC.referenced_column_id) AS ColumnaDestino
FROM sys.foreign_keys AS FK

INNER JOIN sys.foreign_key_columns AS FKC
    ON FK.object_id = FKC.constraint_object_id

ORDER BY
    TablaOrigen,
    NombreFK;
GO
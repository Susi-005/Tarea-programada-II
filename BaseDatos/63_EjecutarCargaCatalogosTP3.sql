USE TareaProgramada2;
DECLARE @Datos XML, @rc INT;

SELECT @Datos = CAST(BulkColumn AS XML)
FROM OPENROWSET(BULK 'C:\CDatosTP2\CatalogosTarea3.xml', SINGLE_BLOB) AS Archivo;

EXEC dbo.CargarCatalogosTP3DesdeXML @Datos = @Datos, @outResultCode = @rc OUTPUT;

SELECT @rc AS Resultado;                                 -- debe ser 0
SELECT COUNT(*) AS TiposMovimiento FROM dbo.TipoMovimiento;   -- debe ser 18
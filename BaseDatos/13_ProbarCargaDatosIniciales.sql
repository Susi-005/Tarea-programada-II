USE TareaProgramada2;
GO

DECLARE @Datos XML;
DECLARE @Resultado INT;

SELECT @Datos = CAST(BulkColumn AS XML)
FROM OPENROWSET
(
    BULK 'C:\CDatosTP2\DatosIniciales.xml',
    SINGLE_BLOB
) AS Archivo;

EXEC dbo.CargarDatosInicialesDesdeXML
    @Datos = @Datos,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS Resultado;
GO
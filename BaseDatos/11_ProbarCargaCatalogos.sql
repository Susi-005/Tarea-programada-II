USE TareaProgramada2;
GO

DECLARE @Datos XML;
DECLARE @Resultado INT;

SELECT @Datos = CAST(BulkColumn AS XML)
FROM OPENROWSET
(
    BULK 'C:\CDatosTP2\Catalogos.xml',
    SINGLE_BLOB
) AS Archivo;

EXEC dbo.CargarCatalogosDesdeXML
    @Datos = @Datos,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS Resultado;
GO

/*
IMPORTANTE 
Aunque el archivo de Catalogos.xml existe dentro del repositorio, SQL no me dejo leerlo desde ahí, así que tuve que crear una carpeta (CDatosTP2) 
directamente en el disco local y ahí copiar el archivo de catalogos, para que este script corra se debe cambiar el path según la computadora en la
que este corriendo 
*/
USE TareaProgramada2;
GO

DECLARE @Datos XML;
DECLARE @Resultado INT;

/* Carga el XML desde la carpeta local usada para pruebas. */
SELECT @Datos = CAST(BulkColumn AS XML)
FROM OPENROWSET
(
    BULK 'C:\CDatosTP2\DatosIniciales.xml',
    SINGLE_BLOB
) AS Archivo;

/* Ejecuta el SP de carga de beneficiarios. */
EXEC dbo.CargarBeneficiariosDesdeXML
    @Datos = @Datos,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoCarga;


/* Verifica el beneficiario cargado. */
SELECT
    B.id,
    C.NumeroCuenta,
    P.Nombre,
    P.ValorDocumentoIdentidad,
    PA.Nombre AS Parentesco,
    B.Porcentaje,
    B.Enabled,
    B.FechaDesactivacion
FROM dbo.Beneficiario AS B

INNER JOIN dbo.Cuenta AS C
    ON C.id = B.idCuenta

INNER JOIN dbo.Persona AS P
    ON P.id = B.idPersona

INNER JOIN dbo.Parentesco AS PA
    ON PA.id = B.idParentesco

WHERE C.NumeroCuenta = '11000001';
GO
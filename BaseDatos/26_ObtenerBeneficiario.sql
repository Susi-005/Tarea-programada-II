USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.ObtenerBeneficiario
    @inIdBeneficiario INT,
    @inIdCuenta       INT,
    @outResultCode    INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Beneficiario
                       WHERE id = @inIdBeneficiario
                         AND idCuenta = @inIdCuenta
                         AND Enabled = 1)
        BEGIN
            SET @outResultCode = 50003;   -- no existe, está inactivo o no es de esta cuenta
            RETURN;
        END;

        SELECT
            B.id,
            P.Nombre,
            P.ValorDocumentoIdentidad,
            P.FechaNacimiento,
            P.Email,
            B.idParentesco,
            B.Porcentaje,
            (SELECT NumeroTelefono FROM dbo.PersonaTelefono
             WHERE idPersona = P.id ORDER BY id
             OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY) AS Telefono1,
            (SELECT NumeroTelefono FROM dbo.PersonaTelefono
             WHERE idPersona = P.id ORDER BY id
             OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY) AS Telefono2
        FROM dbo.Beneficiario AS B
        INNER JOIN dbo.Persona AS P ON P.id = B.idPersona
        WHERE B.id = @inIdBeneficiario;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50005;
    END CATCH;
END;
GO
USE TareaProgramada2;
GO

CREATE PROCEDURE dbo.ListarBeneficiarios
    @idCuenta INT,
    @outResultCode INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        SELECT
            B.id,
            P.Nombre,
            P.ValorDocumentoIdentidad,
            P.FechaNacimiento,
            P.Email,
            PA.Nombre AS Parentesco,
            B.Porcentaje,
            B.Enabled,
            B.FechaDesactivacion
        FROM dbo.Beneficiario AS B

        INNER JOIN dbo.Persona AS P
            ON P.id = B.idPersona

        INNER JOIN dbo.Parentesco AS PA
            ON PA.id = B.idParentesco

        WHERE B.idCuenta = @idCuenta
          AND B.Enabled = 1

        ORDER BY P.Nombre ASC;
    END TRY

    BEGIN CATCH
        SET @outResultCode = ERROR_NUMBER();
    END CATCH
END;
GO
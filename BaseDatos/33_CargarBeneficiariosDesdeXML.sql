USE TareaProgramada2;
GO

CREATE PROCEDURE dbo.CargarBeneficiariosDesdeXML
    @Datos XML,
    @outResultCode INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        BEGIN TRANSACTION;

        INSERT INTO dbo.Beneficiario
        (
            idCuenta,
            idPersona,
            idParentesco,
            Porcentaje,
            Enabled,
            FechaDesactivacion
        )
        SELECT
            C.id,
            P.id,
            X.B.value('@ParentezcoId', 'INT'),
            X.B.value('@Porcentaje', 'INT'),
            1,
            NULL
        FROM @Datos.nodes
        (
            '/DatosIniciales/Beneficiarios/Beneficiario'
        ) AS X(B)

        INNER JOIN dbo.Cuenta AS C
            ON C.NumeroCuenta =
               X.B.value('@NumeroCuenta', 'VARCHAR(32)')

        INNER JOIN dbo.Persona AS P
            ON P.ValorDocumentoIdentidad =
               X.B.value(
                   '@ValorDocumentoIdentidadBeneficiario',
                   'VARCHAR(32)'
               )

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Beneficiario AS BEN
            WHERE BEN.idCuenta = C.id
              AND BEN.idPersona = P.id
              AND BEN.Enabled = 1
        );

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        SET @outResultCode = ERROR_NUMBER();
    END CATCH
END;
GO
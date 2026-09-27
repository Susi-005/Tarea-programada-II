USE TareaProgramada2;
GO

CREATE PROCEDURE dbo.EliminarBeneficiario
    @idBeneficiario INT,
    @outResultCode INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        /* Valida que el beneficiario exista. */
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Beneficiario
            WHERE id = @idBeneficiario
        )
        BEGIN
            SET @outResultCode = 1;
            RETURN;
        END;

        /* Valida que todavía esté activo. */
        IF EXISTS
        (
            SELECT 1
            FROM dbo.Beneficiario
            WHERE id = @idBeneficiario
              AND Enabled = 0
        )
        BEGIN
            SET @outResultCode = 2;
            RETURN;
        END;

        BEGIN TRANSACTION;

        UPDATE dbo.Beneficiario
        SET
            Enabled = 0,
            FechaDesactivacion = GETDATE()
        WHERE id = @idBeneficiario;

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
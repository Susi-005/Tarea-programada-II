USE TareaProgramada2;
GO

CREATE PROCEDURE dbo.CalcularPorcentajeBeneficiarios
    @idCuenta INT,
    @outSumaPorcentajes INT OUTPUT,
    @outResultCode INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;
        SET @outSumaPorcentajes = 0;

        /* Valida que la cuenta exista. */
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Cuenta
            WHERE id = @idCuenta
        )
        BEGIN
            SET @outResultCode = 1;
            RETURN;
        END;

        /*
            Suma únicamente los porcentajes
            de beneficiarios activos.
        */
        SELECT
            @outSumaPorcentajes = ISNULL(SUM(Porcentaje), 0)
        FROM dbo.Beneficiario
        WHERE idCuenta = @idCuenta
          AND Enabled = 1;

    END TRY

    BEGIN CATCH
        SET @outResultCode = ERROR_NUMBER();
    END CATCH
END;
GO
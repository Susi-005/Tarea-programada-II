USE TareaProgramada2;
GO

CREATE PROCEDURE dbo.ConsultarUltimos8EstadosCuenta
    @idCuenta INT,
    @outResultCode INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

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
            Devuelve únicamente los últimos
            8 estados de cuenta.
        */
        SELECT TOP 8
            EC.id,
            EC.FechaInicio,
            EC.FechaFin,
            EC.SaldoInicial,
            EC.SaldoFinal,
            EC.InteresesAcumulados,
            EC.CantidadRetiros,
            EC.CantidadDepositos
        FROM dbo.EstadoCuenta AS EC
        WHERE EC.idCuenta = @idCuenta
        ORDER BY
            EC.FechaFin DESC,
            EC.id DESC;

    END TRY

    BEGIN CATCH
        SET @outResultCode = ERROR_NUMBER();
    END CATCH
END;
GO
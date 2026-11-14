USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.ObtenerEstadoCuenta
    @inIdEstado    INT,
    @inIdCuenta    INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.EstadoCuenta
                       WHERE id = @inIdEstado
                         AND idCuenta = @inIdCuenta)
        BEGIN
            SET @outResultCode = 50003;   -- no existe o no es de esta cuenta
            RETURN;
        END;

        SELECT
            EC.id,
            C.NumeroCuenta,
            EC.FechaInicio,
            EC.FechaFin,
            EC.SaldoInicial,
            EC.SaldoMinimo,
            EC.SaldoFinal,
            EC.InteresesAcumulados,
            EC.CantidadRetiros,
            EC.CantidadDepositos,
            EC.CantidadOperacionesATM,
            EC.CantidadOperacionesHumano,
            EC.CantidadOperacionesSinpe
        FROM dbo.EstadoCuenta AS EC
        INNER JOIN dbo.Cuenta AS C ON C.id = EC.idCuenta
        WHERE EC.id = @inIdEstado;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50005;
    END CATCH;
END;
GO
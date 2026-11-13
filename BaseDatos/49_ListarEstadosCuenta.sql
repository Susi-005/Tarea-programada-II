USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.ListarEstadosCuenta
    @inIdCuenta    INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            EC.id,
            EC.FechaInicio,
            EC.FechaFin,
            EC.SaldoInicial,
            EC.SaldoMinimo,
            EC.SaldoFinal,
            EC.InteresesAcumulados,
            EC.CantidadRetiros,
            EC.CantidadDepositos
        FROM dbo.EstadoCuenta AS EC
        WHERE EC.idCuenta = @inIdCuenta
        ORDER BY EC.FechaFin DESC, EC.id DESC;   -- el más reciente primero

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50005;
    END CATCH;
END;
GO
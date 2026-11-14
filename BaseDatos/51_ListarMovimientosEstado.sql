USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.ListarMovimientosEstado
    @inIdEstado    INT,
    @inIdCuenta    INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @fechaInicio DATE, @fechaFin DATE;

        SELECT @fechaInicio = FechaInicio,
               @fechaFin    = FechaFin
        FROM dbo.EstadoCuenta
        WHERE id = @inIdEstado
          AND idCuenta = @inIdCuenta;

        IF @fechaInicio IS NULL
        BEGIN
            SET @outResultCode = 50003;   -- no existe o no es de esta cuenta
            RETURN;
        END;

        SELECT
            M.id,
            M.Fecha,
            TM.Nombre     AS TipoMovimiento,
            TM.TipoAccion,
            M.Monto,
            M.Descripcion,
            M.NuevoSaldo
        FROM dbo.Movimiento AS M
        INNER JOIN dbo.TipoMovimiento AS TM ON TM.id = M.idTipoMovimiento
        WHERE M.idCuenta = @inIdCuenta
          AND M.Fecha >= @fechaInicio
          AND M.Fecha <  DATEADD(DAY, 1, @fechaFin)
        ORDER BY M.Fecha ASC, M.id ASC;   -- orden cronológico

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50005;
    END CATCH;
END;
GO
USE TareaProgramada2;
GO

BEGIN TRANSACTION;


/* =====================================================
   TIPOS DE MOVIMIENTO DE PRUEBA
   ===================================================== */

INSERT INTO dbo.TipoMovimiento
(
    id,
    Nombre,
    TipoAccion,
    FlagGeneraComprobante
)
VALUES
(9101, 'Compra', 'DEBITO', 1),
(9102, 'Retiro ATM', 'DEBITO', 1),
(9103, 'Deposito Ventana', 'CREDITO', 1),
(9104, 'Retiro Sinpe', 'DEBITO', 1);


/* =====================================================
   MOSTRAR CUENTAS Y PERIODOS DISPONIBLES
   ===================================================== */

SELECT TOP 10
    C.id AS idCuenta,
    C.NumeroCuenta,
    C.Saldo,
    EC.id AS idEstadoCuenta,
    EC.FechaInicio,
    EC.FechaFin,
    EC.CantidadOperacionesATM,
    EC.CantidadOperacionesHumano,
    EC.CantidadOperacionesSinpe
FROM dbo.Cuenta C
INNER JOIN dbo.EstadoCuenta EC
    ON EC.idCuenta = C.id
ORDER BY C.id, EC.FechaInicio;


/* =====================================================
   IMPORTANTE:
   CAMBIAR idCuenta Y FECHAS POR UNA FILA DEL SELECT
   ===================================================== */

DECLARE @R1 INT;
DECLARE @R2 INT;
DECLARE @R3 INT;
DECLARE @R4 INT;


/* Compra */

EXEC dbo.AplicarMovimiento
    @idCuenta = 1,
    @idTipoMovimiento = 9101,
    @Fecha = '2026-03-20',
    @Monto = 1000,
    @Descripcion = 'Compra de prueba',
    @outResultCode = @R1 OUTPUT;


/* Retiro ATM */

EXEC dbo.AplicarMovimiento
    @idCuenta = 1,
    @idTipoMovimiento = 9102,
    @Fecha = '2026-03-21',
    @Monto = 500,
    @Descripcion = 'Retiro ATM de prueba',
    @outResultCode = @R2 OUTPUT;


/* Deposito por ventanilla */

EXEC dbo.AplicarMovimiento
    @idCuenta = 1,
    @idTipoMovimiento = 9103,
    @Fecha = '2026-03-22',
    @Monto = 2000,
    @Descripcion = 'Deposito Ventana de prueba',
    @outResultCode = @R3 OUTPUT;


/* Retiro SINPE */

EXEC dbo.AplicarMovimiento
    @idCuenta = 1,
    @idTipoMovimiento = 9104,
    @Fecha = '2026-03-23',
    @Monto = 800,
    @Descripcion = 'Retiro Sinpe de prueba',
    @outResultCode = @R4 OUTPUT;


/* =====================================================
   RESULTADOS DE LOS SP
   ===================================================== */

SELECT
    @R1 AS ResultadoCompra,
    @R2 AS ResultadoATM,
    @R3 AS ResultadoVentana,
    @R4 AS ResultadoSinpe;


/* =====================================================
   REVISAR MOVIMIENTOS
   ===================================================== */

SELECT
    M.id,
    TM.Nombre AS TipoMovimiento,
    M.Fecha,
    M.Monto,
    M.Descripcion,
    M.NuevoSaldo
FROM dbo.Movimiento M

INNER JOIN dbo.TipoMovimiento TM
    ON TM.id = M.idTipoMovimiento

WHERE M.idCuenta = 1
  AND M.idTipoMovimiento IN
  (
      9101,
      9102,
      9103,
      9104
  )

ORDER BY M.Fecha;


/* =====================================================
   REVISAR CONTADORES
   ===================================================== */

SELECT
    EC.id,
    EC.FechaInicio,
    EC.FechaFin,
    EC.SaldoInicial,
    EC.SaldoFinal,
    EC.SaldoMinimo,
    EC.CantidadOperacionesATM,
    EC.CantidadOperacionesHumano,
    EC.CantidadOperacionesSinpe
FROM dbo.EstadoCuenta EC

WHERE EC.idCuenta = 1
  AND '2026-03-20'
      BETWEEN EC.FechaInicio AND EC.FechaFin;


/* =====================================================
   DESHACER TODA LA PRUEBA
   ===================================================== */

ROLLBACK TRANSACTION;
GO







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
(
    9201,
    'Retiro Sinpe',
    'DEBITO',
    1
),
(
    9202,
    'Comision Sinpe',
    'DEBITO',
    0
);


/* =====================================================
   CONFIGURAR COMISION DE PRUEBA
   ===================================================== */

UPDATE dbo.TipoCuentaAhorro
SET
    LimiteDiarioSinpe = 100000,
    ComisionSinpe = 500
WHERE id = 1;


/* =====================================================
   VER UNA CUENTA CON ESTADO DISPONIBLE
   ===================================================== */

SELECT TOP 5
    C.id AS idCuenta,
    C.NumeroCuenta,
    C.Saldo,
    C.idTipoCuentaAhorro,
    EC.id AS idEstadoCuenta,
    EC.FechaInicio,
    EC.FechaFin
FROM dbo.Cuenta C

INNER JOIN dbo.EstadoCuenta EC
    ON EC.idCuenta = C.id

WHERE C.idTipoCuentaAhorro = 1

ORDER BY C.id, EC.FechaInicio;


/* =====================================================
   PRUEBA SINPE
   USAMOS idCuenta = 1 COMO EJEMPLO
   FECHA: 2026-03-20
   ===================================================== */

DECLARE @R1 INT;
DECLARE @R2 INT;
DECLARE @R3 INT;


/* Primer retiro: 60.000 */

EXEC dbo.AplicarMovimiento
    @idCuenta = 1,
    @idTipoMovimiento = 9201,
    @Fecha = '2026-03-20',
    @Monto = 60000,
    @Descripcion = 'Retiro SINPE prueba 1',
    @outResultCode = @R1 OUTPUT;


/* Segundo retiro: 30.000 */

EXEC dbo.AplicarMovimiento
    @idCuenta = 1,
    @idTipoMovimiento = 9201,
    @Fecha = '2026-03-20',
    @Monto = 30000,
    @Descripcion = 'Retiro SINPE prueba 2',
    @outResultCode = @R2 OUTPUT;


/* Tercer retiro: 20.000 */

EXEC dbo.AplicarMovimiento
    @idCuenta = 1,
    @idTipoMovimiento = 9201,
    @Fecha = '2026-03-20',
    @Monto = 20000,
    @Descripcion = 'Retiro SINPE prueba 3',
    @outResultCode = @R3 OUTPUT;


/* =====================================================
   REVISAR CODIGOS DE RESULTADO
   ===================================================== */

SELECT
    @R1 AS ResultadoSinpe1,
    @R2 AS ResultadoSinpe2,
    @R3 AS ResultadoSinpe3;


/* =====================================================
   REVISAR MOVIMIENTOS GENERADOS
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
  AND M.Fecha = '2026-03-20'
  AND M.idTipoMovimiento IN
  (
      9201,
      9202
  )

ORDER BY M.id;


/* =====================================================
   REVISAR SALDO FINAL
   ===================================================== */

SELECT
    id,
    NumeroCuenta,
    Saldo
FROM dbo.Cuenta
WHERE id = 1;


/* =====================================================
   REVISAR CONTADOR SINPE
   ===================================================== */

SELECT
    id,
    idCuenta,
    FechaInicio,
    FechaFin,
    SaldoFinal,
    SaldoMinimo,
    CantidadOperacionesSinpe
FROM dbo.EstadoCuenta

WHERE idCuenta = 1
  AND '2026-03-20'
      BETWEEN FechaInicio AND FechaFin;


/* =====================================================
   DESHACER TODA LA PRUEBA
   ===================================================== */

ROLLBACK TRANSACTION;
GO
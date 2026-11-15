USE TareaProgramada2;
GO

BEGIN TRANSACTION;


/*
   TIPO DE MOVIMIENTO DE INTERESES DE PRUEBA
*/

INSERT INTO dbo.TipoMovimiento
(
    id,
    Nombre,
    TipoAccion,
    FlagGeneraComprobante
)
VALUES
(
    9301,
    'Intereses mensuales',
    'CREDITO',
    0
);


/* =====================================================
   CREAR CUENTA CONTROLADA DE PRUEBA
   EL TRIGGER CREARA SU ESTADO DE CUENTA
   ===================================================== */

INSERT INTO dbo.Cuenta
(
    idPersona,
    idTipoCuentaAhorro,
    NumeroCuenta,
    FechaCreacion,
    Saldo
)
VALUES
(
    1,
    1,
    '99999980',
    '2026-03-12',
    200000
);


/* =====================================================
   OBTENER ID DE CUENTA Y ESTADO CREADOS
   ===================================================== */

DECLARE @idCuentaPrueba INT;
DECLARE @idEstadoPrueba INT;
DECLARE @FechaFinPrueba DATE;
DECLARE @Resultado INT;

SELECT
    @idCuentaPrueba = id
FROM dbo.Cuenta
WHERE NumeroCuenta = '99999980';

SELECT
    @idEstadoPrueba = id,
    @FechaFinPrueba = FechaFin
FROM dbo.EstadoCuenta
WHERE idCuenta = @idCuentaPrueba;


/* =====================================================
   SIMULAR QUE EL SALDO MINIMO DEL MES FUE 120000
   ===================================================== */

UPDATE dbo.EstadoCuenta
SET SaldoMinimo = 120000
WHERE id = @idEstadoPrueba;


/* =====================================================
   VER DATOS ANTES DEL CIERRE
   ===================================================== */

SELECT
    EC.id AS idEstadoCuenta,
    EC.FechaInicio,
    EC.FechaFin,
    EC.SaldoMinimo,
    C.Saldo AS SaldoActual,
    TCA.Interes AS TasaAnual
FROM dbo.EstadoCuenta EC

INNER JOIN dbo.Cuenta C
    ON C.id = EC.idCuenta

INNER JOIN dbo.TipoCuentaAhorro TCA
    ON TCA.id = C.idTipoCuentaAhorro

WHERE EC.id = @idEstadoPrueba;


/* =====================================================
   EJECUTAR CIERRE
   ===================================================== */

EXEC dbo.CerrarEstadoCuenta
    @idEstadoCuenta = @idEstadoPrueba,
    @FechaCierre = @FechaFinPrueba,
    @outResultCode = @Resultado OUTPUT;

SELECT
    @Resultado AS Resultado;


/* =====================================================
   REVISAR MOVIMIENTO DE INTERESES
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

WHERE M.idCuenta = @idCuentaPrueba

ORDER BY M.id;


/* =====================================================
   REVISAR ESTADO DE CUENTA
   ===================================================== */

SELECT
    id,
    FechaInicio,
    FechaFin,
    SaldoMinimo,
    InteresesAcumulados,
    SaldoFinal
FROM dbo.EstadoCuenta
WHERE id = @idEstadoPrueba;


/* =====================================================
   REVISAR SALDO DE CUENTA
   ===================================================== */

SELECT
    id,
    NumeroCuenta,
    Saldo
FROM dbo.Cuenta
WHERE id = @idCuentaPrueba;


/* =====================================================
   DESHACER TODA LA PRUEBA
   ===================================================== */

ROLLBACK TRANSACTION;
GO


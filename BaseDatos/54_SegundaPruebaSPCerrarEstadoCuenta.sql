USE TareaProgramada2;
GO

BEGIN TRANSACTION;


/* 
   TIPOS DE MOVIMIENTO DE PRUEBA
*/

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.TipoMovimiento
    WHERE id = 9401
)
BEGIN
    INSERT INTO dbo.TipoMovimiento
    (
        id,
        Nombre,
        TipoAccion,
        FlagGeneraComprobante
    )
    VALUES
    (9401, 'Intereses mensuales', 'CREDITO', 0);
END;


IF NOT EXISTS
(
    SELECT 1
    FROM dbo.TipoMovimiento
    WHERE id = 9402
)
BEGIN
    INSERT INTO dbo.TipoMovimiento
    (
        id,
        Nombre,
        TipoAccion,
        FlagGeneraComprobante
    )
    VALUES
    (9402, 'Comision ATM', 'DEBITO', 0);
END;


IF NOT EXISTS
(
    SELECT 1
    FROM dbo.TipoMovimiento
    WHERE id = 9403
)
BEGIN
    INSERT INTO dbo.TipoMovimiento
    (
        id,
        Nombre,
        TipoAccion,
        FlagGeneraComprobante
    )
    VALUES
    (9403, 'Comision Humano', 'DEBITO', 0);
END;


IF NOT EXISTS
(
    SELECT 1
    FROM dbo.TipoMovimiento
    WHERE id = 9404
)
BEGIN
    INSERT INTO dbo.TipoMovimiento
    (
        id,
        Nombre,
        TipoAccion,
        FlagGeneraComprobante
    )
    VALUES
    (9404, 'Multa saldo minimo', 'DEBITO', 0);
END;


IF NOT EXISTS
(
    SELECT 1
    FROM dbo.TipoMovimiento
    WHERE id = 9405
)
BEGIN
    INSERT INTO dbo.TipoMovimiento
    (
        id,
        Nombre,
        TipoAccion,
        FlagGeneraComprobante
    )
    VALUES
    (9405, 'Cargo por servicio', 'DEBITO', 0);
END;


/* =====================================================
   CREAR CUENTA DE PRUEBA
   TIPO DE CUENTA 1
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
    '99999970',
    '2026-03-12',
    100000
);


/* =====================================================
   OBTENER CUENTA Y ESTADO CREADO POR TRIGGER
   ===================================================== */

DECLARE @idCuentaPrueba INT;
DECLARE @idEstadoPrueba INT;
DECLARE @FechaFinPrueba DATE;
DECLARE @Resultado INT;

SELECT
    @idCuentaPrueba = id
FROM dbo.Cuenta
WHERE NumeroCuenta = '99999970';

SELECT
    @idEstadoPrueba = id,
    @FechaFinPrueba = FechaFin
FROM dbo.EstadoCuenta
WHERE idCuenta = @idCuentaPrueba;


/* =====================================================
   FORZAR CONDICIONES PARA GENERAR TODOS LOS CARGOS
   ===================================================== */

UPDATE dbo.EstadoCuenta
SET
    SaldoMinimo = 20000,
    CantidadOperacionesATM = 12,
    CantidadOperacionesHumano = 7
WHERE id = @idEstadoPrueba;


/* =====================================================
   DATOS ANTES DEL CIERRE
   ===================================================== */

SELECT
    EC.id AS idEstadoCuenta,
    EC.FechaInicio,
    EC.FechaFin,
    EC.SaldoMinimo,
    EC.CantidadOperacionesATM,
    EC.CantidadOperacionesHumano,
    C.Saldo AS SaldoActual,
    TCA.SaldoMinimo AS SaldoMinimoPermitido,
    TCA.MultaSaldoMin,
    TCA.NumRetirosAutomatico,
    TCA.ComisionAutomatico,
    TCA.NumRetirosHumano,
    TCA.ComisionHumano,
    TCA.Interes,
    TCA.CargoAnual
FROM dbo.EstadoCuenta EC

INNER JOIN dbo.Cuenta C
    ON C.id = EC.idCuenta

INNER JOIN dbo.TipoCuentaAhorro TCA
    ON TCA.id = C.idTipoCuentaAhorro

WHERE EC.id = @idEstadoPrueba;


/* =====================================================
   CERRAR ESTADO
   ===================================================== */

EXEC dbo.CerrarEstadoCuenta
    @idEstadoCuenta = @idEstadoPrueba,
    @FechaCierre = @FechaFinPrueba,
    @outResultCode = @Resultado OUTPUT;

SELECT
    @Resultado AS Resultado;


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

WHERE M.idCuenta = @idCuentaPrueba

ORDER BY M.id;


/* =====================================================
   REVISAR ESTADO CERRADO Y NUEVO ESTADO
   ===================================================== */

SELECT
    id,
    idCuenta,
    FechaInicio,
    FechaFin,
    SaldoInicial,
    SaldoMinimo,
    SaldoFinal,
    InteresesAcumulados,
    CantidadOperacionesATM,
    CantidadOperacionesHumano,
    CantidadOperacionesSinpe
FROM dbo.EstadoCuenta
WHERE idCuenta = @idCuentaPrueba
ORDER BY FechaInicio;


/* =====================================================
   REVISAR SALDO FINAL DE CUENTA
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
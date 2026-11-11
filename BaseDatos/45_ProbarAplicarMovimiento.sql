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
    9001,
    'Deposito de prueba',
    'CREDITO',
    1
),
(
    9002,
    'Retiro de prueba',
    'DEBITO',
    1
);


/* =====================================================
   BUSCAR UNA CUENTA Y UN ESTADO VIGENTE
   ===================================================== */

SELECT TOP 5
    C.id AS idCuenta,
    C.NumeroCuenta,
    C.Saldo,
    EC.id AS idEstadoCuenta,
    EC.FechaInicio,
    EC.FechaFin,
    EC.SaldoFinal,
    EC.SaldoMinimo
FROM dbo.Cuenta C
INNER JOIN dbo.EstadoCuenta EC
    ON EC.idCuenta = C.id
ORDER BY C.id, EC.FechaInicio;



DECLARE @ResultadoCredito INT;

EXEC dbo.AplicarMovimiento
    @idCuenta = 1,
    @idTipoMovimiento = 9001,
    @Fecha = '2020-11-09',
    @Monto = 5000,
    @Descripcion = 'Deposito de prueba',
    @outResultCode = @ResultadoCredito OUTPUT;

SELECT @ResultadoCredito AS ResultadoCredito;

SELECT
    id,
    NumeroCuenta,
    Saldo
FROM dbo.Cuenta
WHERE id = 1;


SELECT TOP 1
    id,
    idCuenta,
    idTipoMovimiento,
    idComprobante,
    Fecha,
    Monto,
    Descripcion,
    NuevoSaldo
FROM dbo.Movimiento
WHERE idCuenta = 1
ORDER BY id DESC;


SELECT TOP 1
    *
FROM dbo.Comprobante
WHERE idCuenta = 1
ORDER BY id DESC;


DECLARE @ResultadoDebito INT;

EXEC dbo.AplicarMovimiento
    @idCuenta = 1,
    @idTipoMovimiento = 9002,
    @Fecha = '2020-11-09',
    @Monto = 2000,
    @Descripcion = 'Retiro de prueba',
    @outResultCode = @ResultadoDebito OUTPUT;

SELECT @ResultadoDebito AS ResultadoDebito;

SELECT
    id,
    NumeroCuenta,
    Saldo
FROM dbo.Cuenta
WHERE id = 1;


SELECT TOP 2
    id,
    idTipoMovimiento,
    Fecha,
    Monto,
    NuevoSaldo
FROM dbo.Movimiento
WHERE idCuenta = 1
ORDER BY id DESC;
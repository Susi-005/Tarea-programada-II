USE TareaProgramada2;
GO

BEGIN TRANSACTION;


/* =====================================================
   INSERTAR DOS CUENTAS DE PRUEBA
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
    '99999991',
    '2026-11-05',
    75000
),
(
    2,
    1,
    '99999992',
    '2026-11-20',
    100000
);


/* =====================================================
   COMPROBAR LOS ESTADOS CREADOS POR EL TRIGGER
   ===================================================== */

SELECT
    C.NumeroCuenta,
    C.FechaCreacion,
    EC.FechaInicio,
    EC.FechaFin,
    EC.SaldoInicial,
    EC.SaldoMinimo,
    EC.SaldoFinal
FROM dbo.Cuenta C

INNER JOIN dbo.EstadoCuenta EC
    ON EC.idCuenta = C.id

WHERE C.NumeroCuenta IN
(
    '99999991',
    '99999992'
)

ORDER BY C.NumeroCuenta;


/* =====================================================
   DESHACER LA PRUEBA
   ===================================================== */

ROLLBACK TRANSACTION;
GO
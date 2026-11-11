USE TareaProgramada2;
GO

BEGIN TRANSACTION;

/* Crear cuenta de prueba */

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
    '99999999',
    '2026-11-10',
    50000
);


/* Ver la cuenta recién creada */

SELECT
    id,
    NumeroCuenta,
    FechaCreacion,
    Saldo
FROM dbo.Cuenta
WHERE NumeroCuenta = '99999999';


/* Ver si el trigger creó automáticamente el estado de cuenta */

SELECT
    EC.id,
    EC.idCuenta,
    EC.FechaInicio,
    EC.FechaFin,
    EC.SaldoInicial,
    EC.SaldoFinal,
    EC.SaldoMinimo,
    EC.InteresesAcumulados,
    EC.CantidadOperacionesATM,
    EC.CantidadOperacionesHumano,
    EC.CantidadOperacionesSinpe
FROM dbo.EstadoCuenta EC
INNER JOIN dbo.Cuenta C
    ON C.id = EC.idCuenta
WHERE C.NumeroCuenta = '99999999';


/* Borrar toda la prueba */

ROLLBACK TRANSACTION;
GO
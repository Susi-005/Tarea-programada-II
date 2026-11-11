SELECT TOP 5
    id,
    NumeroCuenta,
    FechaCreacion,
    Saldo
FROM dbo.Cuenta
ORDER BY id;

USE TareaProgramada2;
GO

BEGIN TRANSACTION;

DECLARE @Resultado INT;

EXEC dbo.AbrirEstadoCuenta
    @idCuenta = 1,
    @FechaInicio = '2026-12-11',
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS Resultado;


/* Ver el estado creado */

SELECT
    id,
    idCuenta,
    FechaInicio,
    FechaFin,
    SaldoInicial,
    SaldoFinal,
    SaldoMinimo,
    InteresesAcumulados,
    CantidadOperacionesATM,
    CantidadOperacionesHumano,
    CantidadOperacionesSinpe
FROM dbo.EstadoCuenta
WHERE idCuenta = 3
  AND FechaInicio = '2026-12-11';


ROLLBACK TRANSACTION;
GO

USE TareaProgramada2;
GO

BEGIN TRANSACTION;

DECLARE @Resultado1 INT;
DECLARE @Resultado2 INT;


/* Primera apertura: debería funcionar */

EXEC dbo.AbrirEstadoCuenta
    @idCuenta = 1,
    @FechaInicio = '2026-12-11',
    @outResultCode = @Resultado1 OUTPUT;

SELECT @Resultado1 AS ResultadoPrimeraApertura;


/* Segunda apertura del mismo período: debería rechazarse */

EXEC dbo.AbrirEstadoCuenta
    @idCuenta = 1,
    @FechaInicio = '2026-12-11',
    @outResultCode = @Resultado2 OUTPUT;

SELECT @Resultado2 AS ResultadoSegundaApertura;


/* Revisar cuántos estados quedaron con esa fecha */

SELECT
    COUNT(*) AS CantidadEstados
FROM dbo.EstadoCuenta
WHERE idCuenta = 3
  AND FechaInicio = '2026-12-11';


ROLLBACK TRANSACTION;
GO
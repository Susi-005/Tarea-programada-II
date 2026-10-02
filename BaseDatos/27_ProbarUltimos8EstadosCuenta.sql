USE TareaProgramada2;
GO

BEGIN TRANSACTION;

DECLARE @idCuenta INT;
DECLARE @Resultado INT;

/* Busca la cuenta cargada desde el XML. */
SELECT @idCuenta = id
FROM dbo.Cuenta
WHERE NumeroCuenta = '11000001';


/* =====================================================
   INSERTAR 10 ESTADOS DE CUENTA DE PRUEBA
   ===================================================== */

INSERT INTO dbo.EstadoCuenta
(
    idCuenta,
    FechaInicio,
    FechaFin,
    SaldoInicial,
    SaldoFinal,
    InteresesAcumulados,
    CantidadRetiros,
    CantidadDepositos
)
VALUES
(@idCuenta, '2025-01-01', '2025-01-31', 100000, 110000, 1000, 1, 2),
(@idCuenta, '2025-02-01', '2025-02-28', 110000, 120000, 1100, 2, 3),
(@idCuenta, '2025-03-01', '2025-03-31', 120000, 130000, 1200, 1, 4),
(@idCuenta, '2025-04-01', '2025-04-30', 130000, 140000, 1300, 3, 2),
(@idCuenta, '2025-05-01', '2025-05-31', 140000, 150000, 1400, 2, 5),
(@idCuenta, '2025-06-01', '2025-06-30', 150000, 160000, 1500, 4, 3),
(@idCuenta, '2025-07-01', '2025-07-31', 160000, 170000, 1600, 1, 6),
(@idCuenta, '2025-08-01', '2025-08-31', 170000, 180000, 1700, 2, 4),
(@idCuenta, '2025-09-01', '2025-09-30', 180000, 190000, 1800, 3, 5),
(@idCuenta, '2025-10-01', '2025-10-31', 190000, 200000, 1900, 2, 6);


/* =====================================================
   EJECUTAR EL SP
   ===================================================== */

EXEC dbo.ConsultarUltimos8EstadosCuenta
    @idCuenta = @idCuenta,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoConsulta;


/* Limpia los datos utilizados en la prueba. */
ROLLBACK TRANSACTION;
GO
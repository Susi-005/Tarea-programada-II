USE TareaProgramada2;
GO

/* =====================================================
   LIMPIAR CUALQUIER TRANSACCION ANTERIOR
   ===================================================== */

IF @@TRANCOUNT > 0
BEGIN
    ROLLBACK TRANSACTION;
END;
GO


BEGIN TRANSACTION;


/* =====================================================
   1. CREAR PERSONA DE PRUEBA
   ===================================================== */

INSERT INTO dbo.Persona
(
    idTipoDocumentoIdentidad,
    Nombre,
    ValorDocumentoIdentidad,
    FechaNacimiento,
    Email
)
VALUES
(
    1,
    'Persona Prueba Batch',
    '999999999',
    '1990-01-01',
    'prueba.batch@ejemplo.com'
);


/* =====================================================
   2. OBTENER PERSONA
   ===================================================== */

DECLARE @idPersonaPrueba INT;

SELECT
    @idPersonaPrueba = id
FROM dbo.Persona
WHERE ValorDocumentoIdentidad = '999999999';


/* =====================================================
   3. CREAR DOS CUENTAS

   Al insertarlas, el trigger crea su primer EstadoCuenta.
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
    @idPersonaPrueba,
    1,
    '99999101',
    '2026-03-01',
    200000
),
(
    @idPersonaPrueba,
    1,
    '99999102',
    '2026-03-01',
    300000
);


/* =====================================================
   4. PREPARAR LOS ESTADOS PARA EL CIERRE
   ===================================================== */

UPDATE EC
SET
    EC.SaldoInicial = C.Saldo,
    EC.SaldoFinal = C.Saldo,
    EC.SaldoMinimo = C.Saldo
FROM dbo.EstadoCuenta EC

INNER JOIN dbo.Cuenta C
    ON C.id = EC.idCuenta

WHERE C.NumeroCuenta IN
(
    '99999101',
    '99999102'
);


/* =====================================================
   5. VER ESTADOS ANTES DEL BATCH
   ===================================================== */

SELECT
    EC.id AS idEstadoCuenta,
    C.NumeroCuenta,
    EC.FechaInicio,
    EC.FechaFin,
    EC.SaldoInicial,
    EC.SaldoMinimo,
    EC.SaldoFinal
FROM dbo.EstadoCuenta EC

INNER JOIN dbo.Cuenta C
    ON C.id = EC.idCuenta

WHERE C.NumeroCuenta IN
(
    '99999101',
    '99999102'
)

ORDER BY EC.id;


/* =====================================================
   6. EJECUTAR BATCH DE CIERRE DEL 01-04-2026
   ===================================================== */

DECLARE @ResultadoBatch INT;

EXEC dbo.ProcesarCierresDia
    @FechaOperacion = '2026-04-01',
    @outResultCode = @ResultadoBatch OUTPUT;

SELECT
    @ResultadoBatch AS ResultadoPrimeraEjecucion;


/* =====================================================
   7. VER CONTROL DEL PROCESO
   ===================================================== */

SELECT
    id,
    FechaOperacion,
    UltimoIdProcesado,
    CantidadProcesar,
    CantidadProcesada,
    Finalizado,
    FechaHoraInicio,
    FechaHoraFin
FROM dbo.ControlProcesoSimulacion
WHERE FechaOperacion = '2026-04-01';


/* =====================================================
   8. VER ESTADOS CERRADOS Y NUEVOS
   ===================================================== */

SELECT
    C.NumeroCuenta,
    EC.id,
    EC.FechaInicio,
    EC.FechaFin,
    EC.SaldoInicial,
    EC.SaldoMinimo,
    EC.SaldoFinal,
    EC.InteresesAcumulados
FROM dbo.EstadoCuenta EC

INNER JOIN dbo.Cuenta C
    ON C.id = EC.idCuenta

WHERE C.NumeroCuenta IN
(
    '99999101',
    '99999102'
)

ORDER BY
    C.NumeroCuenta,
    EC.FechaInicio;


/* =====================================================
   9. INTENTAR CORRER EL MISMO BATCH OTRA VEZ
   ===================================================== */

DECLARE @ResultadoSegundaEjecucion INT;

EXEC dbo.ProcesarCierresDia
    @FechaOperacion = '2026-04-01',
    @outResultCode = @ResultadoSegundaEjecucion OUTPUT;

SELECT
    @ResultadoSegundaEjecucion
        AS ResultadoSegundaEjecucion;


/* =====================================================
   10. DESHACER TODA LA PRUEBA
   ===================================================== */

ROLLBACK TRANSACTION;
GO
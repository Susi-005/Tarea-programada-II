USE TareaProgramada2;
GO

/* =====================================================
   POR SEGURIDAD: NO DEJAR TRANSACCIONES ANTERIORES
   ===================================================== */

IF @@TRANCOUNT > 0
BEGIN
    ROLLBACK TRANSACTION;
END;
GO


DECLARE @DatosCompletos XML;
DECLARE @DatosPrueba XML;
DECLARE @Resultado INT;


/* =====================================================
   LEER XML OFICIAL
   ===================================================== */

SELECT
    @DatosCompletos = CAST(BulkColumn AS XML)
FROM OPENROWSET
(
    BULK 'C:\CDatosTP2\OperacionesTarea3.xml',
    SINGLE_BLOB
) AS Archivo;


/* =====================================================
   TOMAR SOLO LOS PRIMEROS 4 DIAS DEL XML

   01-03-2026
   02-03-2026
   03-03-2026
   04-03-2026
   ===================================================== */

SET @DatosPrueba =
    @DatosCompletos.query
    (
        '<Operaciones>
        {
            /Operaciones/FechaOperacion[position() <= 4]
        }
        </Operaciones>'
    );


/* =====================================================
   VERIFICAR QUE REALMENTE TOMAMOS 4 FECHAS
   ===================================================== */

SELECT
    @DatosPrueba.value
    (
        'count(/Operaciones/FechaOperacion)',
        'INT'
    ) AS CantidadFechas;


/* =====================================================
   INICIAR PRUEBA
   ===================================================== */

BEGIN TRANSACTION;


/* =====================================================
   EJECUTAR SIMULACION
   ===================================================== */

EXEC dbo.ProcesarSimulacionXML
    @Datos = @DatosPrueba,
    @outResultCode = @Resultado OUTPUT;

SELECT
    @Resultado AS ResultadoSimulacion;


/* =====================================================
   1. PERSONAS CREADAS
   ===================================================== */

SELECT
    id,
    Nombre,
    ValorDocumentoIdentidad,
    FechaNacimiento,
    Email
FROM dbo.Persona
WHERE ValorDocumentoIdentidad IN
(
    '117250431',
    '205430876',
    '109870345',
    '118900456',
    '206540321',
    '304560129',
    '503210765'
)
ORDER BY id;


/* =====================================================
   2. CUENTAS CREADAS
   ===================================================== */

SELECT
    id,
    NumeroCuenta,
    FechaCreacion,
    Saldo,
    idTipoCuentaAhorro
FROM dbo.Cuenta
WHERE NumeroCuenta IN
(
    '11000001',
    '11000002',
    '11000003'
)
ORDER BY NumeroCuenta;


/* =====================================================
   3. BENEFICIARIOS
   ===================================================== */

SELECT
    C.NumeroCuenta,
    P.Nombre AS Beneficiario,
    B.Porcentaje,
    B.Enabled
FROM dbo.Beneficiario B

INNER JOIN dbo.Cuenta C
    ON C.id = B.idCuenta

INNER JOIN dbo.Persona P
    ON P.id = B.idPersona

WHERE C.NumeroCuenta IN
(
    '11000001',
    '11000002',
    '11000003'
)

ORDER BY
    C.NumeroCuenta,
    B.id;


/* =====================================================
   4. USUARIOS Y CUENTAS PERMITIDAS
   ===================================================== */

SELECT
    U.NombreUsuario,
    C.NumeroCuenta
FROM dbo.UsuarioCuenta UC

INNER JOIN dbo.Usuario U
    ON U.id = UC.idUsuario

INNER JOIN dbo.Cuenta C
    ON C.id = UC.idCuenta

WHERE U.NombreUsuario IN
(
    'amora',
    'cvargas',
    'mrojas'
)

ORDER BY U.NombreUsuario;


/* =====================================================
   5. MOVIMIENTOS
   ===================================================== */

SELECT
    C.NumeroCuenta,
    TM.Nombre AS TipoMovimiento,
    M.Fecha,
    M.Monto,
    M.Descripcion,
    M.NuevoSaldo
FROM dbo.Movimiento M

INNER JOIN dbo.Cuenta C
    ON C.id = M.idCuenta

INNER JOIN dbo.TipoMovimiento TM
    ON TM.id = M.idTipoMovimiento

WHERE C.NumeroCuenta IN
(
    '11000001',
    '11000002',
    '11000003'
)

ORDER BY
    M.Fecha,
    M.id;


/* =====================================================
   6. PRIMEROS ESTADOS DE CUENTA
   ===================================================== */

SELECT
    C.NumeroCuenta,
    EC.FechaInicio,
    EC.FechaFin,
    EC.SaldoInicial,
    EC.SaldoMinimo,
    EC.SaldoFinal,
    EC.CantidadOperacionesATM,
    EC.CantidadOperacionesHumano,
    EC.CantidadOperacionesSinpe
FROM dbo.EstadoCuenta EC

INNER JOIN dbo.Cuenta C
    ON C.id = EC.idCuenta

WHERE C.NumeroCuenta IN
(
    '11000001',
    '11000002',
    '11000003'
)

ORDER BY C.NumeroCuenta;


/* =====================================================
   DESHACER TODA LA PRUEBA
   ===================================================== */

ROLLBACK TRANSACTION;
GO
USE TareaProgramada2;
GO

DECLARE @Datos XML;
DECLARE @Resultado INT;


/* =====================================================
   LEER XML OFICIAL DE OPERACIONES TP3
   ===================================================== */

SELECT
    @Datos = CAST(BulkColumn AS XML)

FROM OPENROWSET
(
    BULK 'C:\CDatosTP2\OperacionesTarea3.xml',
    SINGLE_BLOB
) AS Archivo;


/* =====================================================
   MOSTRAR INFORMACION DEL XML ANTES DE PROCESAR
   ===================================================== */

SELECT
    @Datos.value
    (
        'count(/Operaciones/FechaOperacion)',
        'INT'
    ) AS FechasConDatos,

    @Datos.value
    (
        'count(/Operaciones/FechaOperacion/Persona)',
        'INT'
    ) AS PersonasXML,

    @Datos.value
    (
        'count(/Operaciones/FechaOperacion/Cuenta)',
        'INT'
    ) AS CuentasXML,

    @Datos.value
    (
        'count(/Operaciones/FechaOperacion/Beneficiario)',
        'INT'
    ) AS BeneficiariosXML,

    @Datos.value
    (
        'count(/Operaciones/FechaOperacion/Usuario)',
        'INT'
    ) AS UsuariosXML,

    @Datos.value
    (
        'count(/Operaciones/FechaOperacion/UsuarioPuedeVer)',
        'INT'
    ) AS UsuarioCuentaXML,

    @Datos.value
    (
        'count(/Operaciones/FechaOperacion/Movimientos)',
        'INT'
    ) AS MovimientosXML;


/* =====================================================
   EJECUTAR SIMULACION COMPLETA
   ===================================================== */

EXEC dbo.ProcesarSimulacionXML
    @Datos = @Datos,
    @outResultCode = @Resultado OUTPUT;


/* =====================================================
   RESULTADO GENERAL
   ===================================================== */

SELECT
    @Resultado AS ResultadoSimulacion;
GO


SELECT
    MIN(FechaOperacion) AS PrimeraFecha,
    MAX(FechaOperacion) AS UltimaFecha
FROM dbo.ControlProcesoSimulacion;


SELECT
    COUNT(*) AS CantidadCuentas
FROM dbo.Cuenta;




SELECT
    NumeroCuenta,
    FechaCreacion,
    Saldo,
    idTipoCuentaAhorro
FROM dbo.Cuenta
ORDER BY NumeroCuenta;

SELECT
    COUNT(*) AS TotalMovimientos
FROM dbo.Movimiento;





SELECT
    TM.Nombre,
    COUNT(*) AS Cantidad
FROM dbo.Movimiento M

INNER JOIN dbo.TipoMovimiento TM
    ON TM.id = M.idTipoMovimiento

GROUP BY
    TM.Nombre

ORDER BY
    TM.Nombre;





    SELECT
    C.NumeroCuenta,
    COUNT(*) AS CantidadEstados
FROM dbo.EstadoCuenta EC

INNER JOIN dbo.Cuenta C
    ON C.id = EC.idCuenta

GROUP BY
    C.NumeroCuenta

ORDER BY
    C.NumeroCuenta;





    SELECT
    C.NumeroCuenta,
    EC.FechaInicio,
    EC.FechaFin,
    EC.SaldoInicial,
    EC.SaldoMinimo,
    EC.SaldoFinal,
    EC.InteresesAcumulados,
    EC.CantidadOperacionesATM,
    EC.CantidadOperacionesHumano,
    EC.CantidadOperacionesSinpe
FROM dbo.EstadoCuenta EC

INNER JOIN dbo.Cuenta C
    ON C.id = EC.idCuenta

ORDER BY
    C.NumeroCuenta,
    EC.FechaInicio;




    SELECT
        C.NumeroCuenta,
        SUM(B.Porcentaje) AS PorcentajeTotal
    FROM dbo.Beneficiario B

    INNER JOIN dbo.Cuenta C
        ON C.id = B.idCuenta

    WHERE B.Enabled = 1

    GROUP BY
        C.NumeroCuenta

    ORDER BY
        C.NumeroCuenta;






        SELECT
            COUNT(*) AS DiasProcesados,
            SUM
            (
                CASE
                    WHEN Finalizado = 1 THEN 1
                    ELSE 0
                END
            ) AS DiasFinalizados
        FROM dbo.ControlProcesoSimulacion;
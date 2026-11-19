USE TareaProgramada2;
GO


--   1. CONTEOS GENERALES

SELECT
    (SELECT COUNT(*) FROM dbo.Persona)
        AS Personas,

    (SELECT COUNT(*) FROM dbo.Cuenta)
        AS Cuentas,

    (SELECT COUNT(*) FROM dbo.Beneficiario)
        AS Beneficiarios,

    (SELECT COUNT(*) FROM dbo.UsuarioCuenta)
        AS RelacionesUsuarioCuenta,

    (SELECT COUNT(*) FROM dbo.Movimiento)
        AS Movimientos,

    (SELECT COUNT(*) FROM dbo.EstadoCuenta)
        AS EstadosCuenta,

    (SELECT COUNT(*) FROM dbo.ControlProcesoSimulacion)
        AS ProcesosControlados;
GO



--  2. CONTROL DE LOS 122 DIAS

SELECT
    COUNT(*) AS DiasProcesados,

    SUM
    (
        CASE
            WHEN Finalizado = 1 THEN 1
            ELSE 0
        END
    ) AS DiasFinalizados,

    MIN(FechaOperacion) AS PrimeraFecha,

    MAX(FechaOperacion) AS UltimaFecha

FROM dbo.ControlProcesoSimulacion;
GO

 -- 3. VERIFICAR QUE NO HAYA FECHAS DUPLICADAS EN EL CONTROL

SELECT
    FechaOperacion,
    COUNT(*) AS Cantidad

FROM dbo.ControlProcesoSimulacion

GROUP BY FechaOperacion

HAVING COUNT(*) > 1;
GO


-- 4. VERIFICAR NUMEROS DE CUENTA DUPLICADOS

SELECT
    NumeroCuenta,
    COUNT(*) AS Cantidad

FROM dbo.Cuenta

GROUP BY NumeroCuenta

HAVING COUNT(*) > 1;
GO


 -- 5. VERIFICAR PERSONAS DUPLICADAS POR DOCUMENTO

SELECT
    ValorDocumentoIdentidad,
    COUNT(*) AS Cantidad

FROM dbo.Persona

GROUP BY ValorDocumentoIdentidad

HAVING COUNT(*) > 1;
GO


-- 6. VERIFICAR USUARIO - CUENTA DUPLICADO

SELECT
    idUsuario,
    idCuenta,
    COUNT(*) AS Cantidad

FROM dbo.UsuarioCuenta

GROUP BY
    idUsuario,
    idCuenta

HAVING COUNT(*) > 1;
GO


-- 7. BENEFICIARIOS ACTIVOS DEBEN SUMAR 100

SELECT
    C.NumeroCuenta,
    SUM(B.Porcentaje) AS PorcentajeTotal

FROM dbo.Beneficiario B

INNER JOIN dbo.Cuenta C
    ON C.id = B.idCuenta

WHERE B.Enabled = 1

GROUP BY C.NumeroCuenta

HAVING SUM(B.Porcentaje) <> 100;
GO


 --8. CUENTAS Y SALDOS FINALES

SELECT
    C.NumeroCuenta,
    C.FechaCreacion,
    TCA.Nombre AS TipoCuenta,
    C.Saldo

FROM dbo.Cuenta C

INNER JOIN dbo.TipoCuentaAhorro TCA
    ON TCA.id = C.idTipoCuentaAhorro

ORDER BY C.NumeroCuenta;
GO


-- 9. CANTIDAD DE ESTADOS POR CUENTA

SELECT
    C.NumeroCuenta,
    COUNT(*) AS CantidadEstados

FROM dbo.EstadoCuenta EC

INNER JOIN dbo.Cuenta C
    ON C.id = EC.idCuenta

GROUP BY C.NumeroCuenta

ORDER BY C.NumeroCuenta;
GO


 -- 10. DETALLE DE ESTADOS
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
GO


--11. MOVIMIENTOS POR TIPO

SELECT
    TM.Nombre,
    COUNT(*) AS Cantidad

FROM dbo.Movimiento M

INNER JOIN dbo.TipoMovimiento TM
    ON TM.id = M.idTipoMovimiento

GROUP BY TM.Nombre

ORDER BY TM.Nombre;
GO



  -- 12. MOVIMIENTOS CON NUEVO SALDO


SELECT
    C.NumeroCuenta,
    M.Fecha,
    TM.Nombre AS TipoMovimiento,
    M.Monto,
    M.Descripcion,
    M.NuevoSaldo

FROM dbo.Movimiento M

INNER JOIN dbo.Cuenta C
    ON C.id = M.idCuenta

INNER JOIN dbo.TipoMovimiento TM
    ON TM.id = M.idTipoMovimiento

ORDER BY
    C.NumeroCuenta,
    M.Fecha,
    M.id;
GO



--   13. COMPROBANTES GENERADOS


SELECT
    COUNT(*) AS CantidadComprobantes

FROM dbo.Comprobante;
GO


--   14. MOVIMIENTOS QUE DEBERIAN GENERAR COMPROBANTE


SELECT
    TM.Nombre,
    COUNT(*) AS Cantidad

FROM dbo.Movimiento M

INNER JOIN dbo.TipoMovimiento TM
    ON TM.id = M.idTipoMovimiento

WHERE TM.FlagGeneraComprobante = 1

GROUP BY TM.Nombre

ORDER BY TM.Nombre;
GO



--   15. PROCESOS NO FINALIZADOS


SELECT
    *

FROM dbo.ControlProcesoSimulacion

WHERE Finalizado = 0;
GO


--   16. CONTROL CON CANTIDADES INCONSISTENTES


SELECT
    *

FROM dbo.ControlProcesoSimulacion

WHERE CantidadProcesada <> CantidadProcesar;
GO
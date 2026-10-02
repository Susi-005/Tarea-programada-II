USE TareaProgramada2;
GO

/* =====================================================
   VALIDAR CANTIDADES DE CATÁLOGOS
   ===================================================== */

SELECT
    (SELECT COUNT(*) FROM dbo.TipoDocumentoIdentidad)
        AS CantidadTiposDocumento,

    (SELECT COUNT(*) FROM dbo.TipoMoneda)
        AS CantidadMonedas,

    (SELECT COUNT(*) FROM dbo.Parentesco)
        AS CantidadParentescos,

    (SELECT COUNT(*) FROM dbo.TipoCuentaAhorro)
        AS CantidadTiposCuenta,

    (SELECT COUNT(*) FROM dbo.TipoOperacion)
        AS CantidadTiposOperacion;
GO


/* =====================================================
   VALIDAR DATOS NO CATÁLOGO
   ===================================================== */

SELECT
    (SELECT COUNT(*) FROM dbo.Persona)
        AS CantidadPersonas,

    (SELECT COUNT(*) FROM dbo.PersonaTelefono)
        AS CantidadTelefonos,

    (SELECT COUNT(*) FROM dbo.Cuenta)
        AS CantidadCuentas,

    (SELECT COUNT(*) FROM dbo.Usuario)
        AS CantidadUsuarios,

    (SELECT COUNT(*) FROM dbo.UsuarioCuenta)
        AS CantidadRelacionesUsuarioCuenta,

    (SELECT COUNT(*) FROM dbo.EstadoCuenta)
        AS CantidadEstadosCuenta;
GO


/* =====================================================
   VALIDAR PERSONAS CARGADAS DESDE XML
   ===================================================== */

SELECT
    P.id,
    P.Nombre,
    P.ValorDocumentoIdentidad,
    P.FechaNacimiento,
    P.Email
FROM dbo.Persona AS P
ORDER BY P.id;
GO


/* =====================================================
   VALIDAR CUENTA Y PROPIETARIO
   ===================================================== */

SELECT
    C.NumeroCuenta,
    P.Nombre AS Propietario,
    P.ValorDocumentoIdentidad,
    TC.Nombre AS TipoCuenta,
    C.FechaCreacion,
    C.Saldo
FROM dbo.Cuenta AS C

INNER JOIN dbo.Persona AS P
    ON P.id = C.idPersona

INNER JOIN dbo.TipoCuentaAhorro AS TC
    ON TC.id = C.idTipoCuentaAhorro;
GO


/* =====================================================
   VALIDAR USUARIO Y CUENTA PERMITIDA
   ===================================================== */

SELECT
    U.NombreUsuario,
    C.NumeroCuenta
FROM dbo.UsuarioCuenta AS UC

INNER JOIN dbo.Usuario AS U
    ON U.id = UC.idUsuario

INNER JOIN dbo.Cuenta AS C
    ON C.id = UC.idCuenta;
GO
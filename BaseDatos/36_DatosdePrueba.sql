USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.CargarNoCatalogosDesdeXML
    @Datos XML,
    @outResultCode INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        BEGIN TRANSACTION;

        /* =====================================================
           1. PERSONAS
           ===================================================== */

        INSERT INTO dbo.Persona
        (
            idTipoDocumentoIdentidad,
            Nombre,
            ValorDocumentoIdentidad,
            FechaNacimiento,
            Email
        )
        SELECT
            X.P.value('@TipoDocuIdentidad', 'INT'),
            X.P.value('@Nombre', 'VARCHAR(64)'),
            X.P.value('@ValorDocumentoIdentidad', 'VARCHAR(32)'),
            X.P.value('@FechaNacimiento', 'DATE'),
            X.P.value('@Email', 'VARCHAR(128)')
        FROM @Datos.nodes('/NoCatalogos/Personas/Persona') AS X(P)
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Persona AS P
            WHERE P.ValorDocumentoIdentidad =
                  X.P.value('@ValorDocumentoIdentidad', 'VARCHAR(32)')
        );


        /* =====================================================
           2. TELÉFONO 1
           ===================================================== */

        INSERT INTO dbo.PersonaTelefono
        (
            idPersona,
            NumeroTelefono
        )
        SELECT
            P.id,
            X.P.value('@telefono1', 'VARCHAR(16)')
        FROM @Datos.nodes('/NoCatalogos/Personas/Persona') AS X(P)

        INNER JOIN dbo.Persona AS P
            ON P.ValorDocumentoIdentidad =
               X.P.value('@ValorDocumentoIdentidad', 'VARCHAR(32)')

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.PersonaTelefono AS PT
            WHERE PT.idPersona = P.id
              AND PT.NumeroTelefono =
                  X.P.value('@telefono1', 'VARCHAR(16)')
        );


        /* =====================================================
           3. TELÉFONO 2
           ===================================================== */

        INSERT INTO dbo.PersonaTelefono
        (
            idPersona,
            NumeroTelefono
        )
        SELECT
            P.id,
            X.P.value('@telefono2', 'VARCHAR(16)')
        FROM @Datos.nodes('/NoCatalogos/Personas/Persona') AS X(P)

        INNER JOIN dbo.Persona AS P
            ON P.ValorDocumentoIdentidad =
               X.P.value('@ValorDocumentoIdentidad', 'VARCHAR(32)')

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.PersonaTelefono AS PT
            WHERE PT.idPersona = P.id
              AND PT.NumeroTelefono =
                  X.P.value('@telefono2', 'VARCHAR(16)')
        );


        /* =====================================================
           4. CUENTAS
           ===================================================== */

        INSERT INTO dbo.Cuenta
        (
            idPersona,
            idTipoCuentaAhorro,
            NumeroCuenta,
            FechaCreacion,
            Saldo
        )
        SELECT
            P.id,
            X.C.value('@TipoCuentaId', 'INT'),
            X.C.value('@NumeroCuenta', 'VARCHAR(32)'),
            X.C.value('@FechaCreacion', 'DATE'),
            X.C.value('@Saldo', 'MONEY')
        FROM @Datos.nodes('/NoCatalogos/Cuentas/Cuenta') AS X(C)

        INNER JOIN dbo.Persona AS P
            ON P.ValorDocumentoIdentidad =
               X.C.value(
                   '@ValorDocumentoIdentidadDelCliente',
                   'VARCHAR(32)'
               )

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Cuenta AS C
            WHERE C.NumeroCuenta =
                  X.C.value('@NumeroCuenta', 'VARCHAR(32)')
        );


        /* =====================================================
           5. BENEFICIARIOS
           ===================================================== */

        INSERT INTO dbo.Beneficiario
        (
            idCuenta,
            idPersona,
            idParentesco,
            Porcentaje,
            Enabled,
            FechaDesactivacion
        )
        SELECT
            C.id,
            P.id,
            X.B.value('@IdParentezco', 'INT'),
            X.B.value('@Porcentaje', 'INT'),
            1,
            NULL
        FROM @Datos.nodes('/NoCatalogos/Beneficiarios/Beneficiario') AS X(B)

        INNER JOIN dbo.Cuenta AS C
            ON C.NumeroCuenta =
               X.B.value('@NumeroCuenta', 'VARCHAR(32)')

        INNER JOIN dbo.Persona AS P
            ON P.ValorDocumentoIdentidad =
               X.B.value(
                   '@ValorDocumentoIdentidadBeneficiario',
                   'VARCHAR(32)'
               )

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Beneficiario AS B
            WHERE B.idCuenta = C.id
              AND B.idPersona = P.id
              AND B.Enabled = 1
        );


        /* =====================================================
           6. ESTADOS DE CUENTA
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
        SELECT
            C.id,
            X.E.value('@fechaInicio', 'DATE'),
            X.E.value('@fechafin', 'DATE'),
            X.E.value('@saldoinicial', 'MONEY'),
            X.E.value('@saldo_final', 'MONEY'),
            X.E.value('@interesesAcumulados', 'MONEY'),
            X.E.value('@cantRetiros', 'INT'),
            X.E.value('@cantDepositos', 'INT')
        FROM @Datos.nodes
        (
            '/NoCatalogos/Estados_de_Cuenta/Estado_de_Cuenta'
        ) AS X(E)

        INNER JOIN dbo.Cuenta AS C
            ON C.NumeroCuenta =
               X.E.value('@NumeroCuenta', 'VARCHAR(32)')

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.EstadoCuenta AS EC
            WHERE EC.idCuenta = C.id
              AND EC.FechaInicio =
                  X.E.value('@fechaInicio', 'DATE')
              AND EC.FechaFin =
                  X.E.value('@fechafin', 'DATE')
        );


        /* =====================================================
           7. USUARIOS
           ===================================================== */

        INSERT INTO dbo.Usuario
        (
            NombreUsuario,
            Contrasena,
            EsAdministrador
        )
        SELECT
            X.U.value('@User', 'VARCHAR(64)'),
            X.U.value('@Pass', 'VARCHAR(128)'),
            X.U.value('@EsAdministrador', 'BIT')
        FROM @Datos.nodes('/NoCatalogos/Usuarios/Usuario') AS X(U)

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Usuario AS U
            WHERE U.NombreUsuario =
                  X.U.value('@User', 'VARCHAR(64)')
        );


        /* =====================================================
           8. USUARIO - CUENTA
           ===================================================== */

        INSERT INTO dbo.UsuarioCuenta
        (
            idUsuario,
            idCuenta
        )
        SELECT
            U.id,
            C.id
        FROM @Datos.nodes
        (
            '/NoCatalogos/Usuarios_Ver/UsuarioPuedeVer'
        ) AS X(UC)

        INNER JOIN dbo.Usuario AS U
            ON U.NombreUsuario =
               X.UC.value('@User', 'VARCHAR(64)')

        INNER JOIN dbo.Cuenta AS C
            ON C.NumeroCuenta =
               X.UC.value('@NumeroCuenta', 'VARCHAR(32)')

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.UsuarioCuenta AS UCC
            WHERE UCC.idUsuario = U.id
              AND UCC.idCuenta = C.id
        );


        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        SET @outResultCode = ERROR_NUMBER();

    END CATCH
END;
GO
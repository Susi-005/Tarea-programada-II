USE TareaProgramada2;
GO

CREATE PROCEDURE dbo.CargarDatosInicialesDesdeXML
    @Datos XML,
    @outResultCode INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        BEGIN TRANSACTION;

        /* =====================================================
           1. CARGAR PERSONAS
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
            X.Nodo.value('@TipoDocuIdentidad', 'INT'),
            X.Nodo.value('@Nombre', 'VARCHAR(64)'),
            X.Nodo.value('@ValorDocumentoIdentidad', 'VARCHAR(32)'),
            X.Nodo.value('@FechaNacimiento', 'DATE'),
            X.Nodo.value('@Email', 'VARCHAR(128)')
        FROM @Datos.nodes(
            '/DatosIniciales/Personas/Persona'
        ) AS X(Nodo)
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Persona AS P
            WHERE P.ValorDocumentoIdentidad =
                X.Nodo.value('@ValorDocumentoIdentidad', 'VARCHAR(32)')
        );


        /* =====================================================
           2. CARGAR TELEFONO 1
           ===================================================== */

        INSERT INTO dbo.PersonaTelefono
        (
            idPersona,
            NumeroTelefono
        )
        SELECT
            P.id,
            X.Nodo.value('@telefono1', 'VARCHAR(16)')
        FROM @Datos.nodes(
            '/DatosIniciales/Personas/Persona'
        ) AS X(Nodo)

        INNER JOIN dbo.Persona AS P
            ON P.ValorDocumentoIdentidad =
               X.Nodo.value('@ValorDocumentoIdentidad', 'VARCHAR(32)')

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.PersonaTelefono AS PT
            WHERE PT.idPersona = P.id
              AND PT.NumeroTelefono =
                  X.Nodo.value('@telefono1', 'VARCHAR(16)')
        );


        /* =====================================================
           3. CARGAR TELEFONO 2
           ===================================================== */

        INSERT INTO dbo.PersonaTelefono
        (
            idPersona,
            NumeroTelefono
        )
        SELECT
            P.id,
            X.Nodo.value('@telefono2', 'VARCHAR(16)')
        FROM @Datos.nodes(
            '/DatosIniciales/Personas/Persona'
        ) AS X(Nodo)

        INNER JOIN dbo.Persona AS P
            ON P.ValorDocumentoIdentidad =
               X.Nodo.value('@ValorDocumentoIdentidad', 'VARCHAR(32)')

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.PersonaTelefono AS PT
            WHERE PT.idPersona = P.id
              AND PT.NumeroTelefono =
                  X.Nodo.value('@telefono2', 'VARCHAR(16)')
        );


        /* =====================================================
           4. CARGAR CUENTAS
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
            X.Nodo.value('@TipoCuentaId', 'INT'),
            X.Nodo.value('@NumeroCuenta', 'VARCHAR(32)'),
            X.Nodo.value('@FechaCreacion', 'DATE'),
            X.Nodo.value('@Saldo', 'MONEY')
        FROM @Datos.nodes(
            '/DatosIniciales/Cuentas/Cuenta'
        ) AS X(Nodo)

        INNER JOIN dbo.Persona AS P
            ON P.ValorDocumentoIdentidad =
               X.Nodo.value(
                   '@ValorDocumentoIdentidadDelCliente',
                   'VARCHAR(32)'
               )

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Cuenta AS C
            WHERE C.NumeroCuenta =
                X.Nodo.value('@NumeroCuenta', 'VARCHAR(32)')
        );


        /* =====================================================
           5. CARGAR USUARIOS
           ===================================================== */

        INSERT INTO dbo.Usuario
        (
            NombreUsuario,
            Contrasena,
            EsAdministrador
        )
        SELECT
            X.Nodo.value('@User', 'VARCHAR(64)'),
            X.Nodo.value('@Pass', 'VARCHAR(128)'),
            X.Nodo.value('@EsAdministrador', 'BIT')
        FROM @Datos.nodes(
            '/DatosIniciales/Usuarios/Usuario'
        ) AS X(Nodo)

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Usuario AS U
            WHERE U.NombreUsuario =
                X.Nodo.value('@User', 'VARCHAR(64)')
        );


        /* =====================================================
           6. RELACIONAR USUARIOS CON CUENTAS
           ===================================================== */

        INSERT INTO dbo.UsuarioCuenta
        (
            idUsuario,
            idCuenta
        )
        SELECT
            U.id,
            C.id
        FROM @Datos.nodes(
            '/DatosIniciales/Usuarios_Ver/UsuarioPuedeVer'
        ) AS X(Nodo)

        INNER JOIN dbo.Usuario AS U
            ON U.NombreUsuario =
               X.Nodo.value('@User', 'VARCHAR(64)')

        INNER JOIN dbo.Cuenta AS C
            ON C.NumeroCuenta =
               X.Nodo.value('@NumeroCuenta', 'VARCHAR(32)')

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.UsuarioCuenta AS UC
            WHERE UC.idUsuario = U.id
              AND UC.idCuenta = C.id
        );


        /* =====================================================
           7. CARGAR ESTADOS DE CUENTA
           ===================================================== */

        INSERT INTO dbo.EstadoCuenta
        (
            idCuenta,
            FechaInicio,
            FechaFin,
            SaldoInicial,
            SaldoFinal
        )
        SELECT
            C.id,
            X.Nodo.value('@fechaInicio', 'DATE'),
            X.Nodo.value('@fechafin', 'DATE'),
            X.Nodo.value('@saldoinicial', 'MONEY'),
            X.Nodo.value('@saldo_final', 'MONEY')
        FROM @Datos.nodes(
            '/DatosIniciales/Estados_de_Cuenta/Estado_de_Cuenta'
        ) AS X(Nodo)

        INNER JOIN dbo.Cuenta AS C
            ON C.NumeroCuenta =
               X.Nodo.value('@NumeroCuenta', 'VARCHAR(32)')

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.EstadoCuenta AS EC
            WHERE EC.idCuenta = C.id
              AND EC.FechaInicio =
                  X.Nodo.value('@fechaInicio', 'DATE')
              AND EC.FechaFin =
                  X.Nodo.value('@fechafin', 'DATE')
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
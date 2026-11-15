USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.ProcesarSimulacionXML
    @Datos XML,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SET @outResultCode = 0;


        /* =====================================================
           VARIABLES GENERALES DE LA SIMULACION
           ===================================================== */

        DECLARE
            @FechaInicial DATE,
            @FechaFinal DATE,
            @FechaActual DATE;


        /* =====================================================
           VARIABLES PARA MOVIMIENTOS
           ===================================================== */

        DECLARE
            @SecMovimiento INT,
            @UltimoSecMovimiento INT,
            @CodigoCuenta VARCHAR(32),
            @NombreMovimiento VARCHAR(64),
            @Monto MONEY,
            @Descripcion VARCHAR(256),
            @idCuenta INT,
            @idTipoMovimiento INT,
            @ResultadoMovimiento INT;


        /* =====================================================
           VARIABLES PARA CIERRES
           ===================================================== */

        DECLARE
            @SecEstado INT,
            @UltimoSecEstado INT,
            @idEstadoCuenta INT,
            @ResultadoCierre INT;


        /* =====================================================
           TABLA VARIABLE PARA MOVIMIENTOS DE CADA DIA
           ===================================================== */

        DECLARE @MovimientosDia TABLE
        (
            Sec INT IDENTITY(1,1) NOT NULL,
            CodigoCuenta VARCHAR(32) NOT NULL,
            TipoMovimiento VARCHAR(64) NOT NULL,
            Monto MONEY NOT NULL,
            Descripcion VARCHAR(256) NOT NULL
        );


        /* =====================================================
           TABLA VARIABLE PARA ESTADOS QUE CIERRAN EN EL DIA
           ===================================================== */

        DECLARE @EstadosCerrar TABLE
        (
            Sec INT IDENTITY(1,1) NOT NULL,
            idEstadoCuenta INT NOT NULL
        );


        /* =====================================================
           OBTENER PRIMERA Y ULTIMA FECHA DEL XML
           ===================================================== */

        SELECT
            @FechaInicial =
                MIN
                (
                    X.Nodo.value('@Fecha', 'DATE')
                ),

            @FechaFinal =
                MAX
                (
                    X.Nodo.value('@Fecha', 'DATE')
                )

        FROM @Datos.nodes
        (
            '/Operaciones/FechaOperacion'
        ) AS X(Nodo);


        /* =====================================================
           VALIDAR XML
           ===================================================== */

        IF @FechaInicial IS NULL
           OR @FechaFinal IS NULL
        BEGIN
            SET @outResultCode = 50001;
            RETURN;
        END;


        /* =====================================================
           INICIAR SIMULACION
           ===================================================== */

        SET @FechaActual = @FechaInicial;


        /* =====================================================
           RECORRER TODAS LAS FECHAS CONSECUTIVAMENTE
           ===================================================== */

        WHILE @FechaActual <= @FechaFinal
        BEGIN


            /* =================================================
               1. PERSONAS
               ================================================= */

            INSERT INTO dbo.Persona
            (
                idTipoDocumentoIdentidad,
                Nombre,
                ValorDocumentoIdentidad,
                FechaNacimiento,
                Email
            )

            SELECT
                X.Nodo.value
                (
                    '@TipoDocuIdentidad',
                    'INT'
                ),

                X.Nodo.value
                (
                    '@Nombre',
                    'VARCHAR(64)'
                ),

                X.Nodo.value
                (
                    '@ValorDocumentoIdentidad',
                    'VARCHAR(32)'
                ),

                X.Nodo.value
                (
                    '@FechaNacimiento',
                    'DATE'
                ),

                X.Nodo.value
                (
                    '@Email',
                    'VARCHAR(128)'
                )

            FROM @Datos.nodes
            (
                '/Operaciones/FechaOperacion/Persona'
            ) AS X(Nodo)

            WHERE
                X.Nodo.value
                (
                    '(../@Fecha)[1]',
                    'DATE'
                ) = @FechaActual

                AND NOT EXISTS
                (
                    SELECT 1
                    FROM dbo.Persona P

                    WHERE P.ValorDocumentoIdentidad =
                        X.Nodo.value
                        (
                            '@ValorDocumentoIdentidad',
                            'VARCHAR(32)'
                        )
                );


            /* =================================================
               2. TELEFONO PRINCIPAL
               ================================================= */

            INSERT INTO dbo.PersonaTelefono
            (
                idPersona,
                NumeroTelefono
            )

            SELECT
                P.id,

                X.Nodo.value
                (
                    '@telefono1',
                    'VARCHAR(16)'
                )

            FROM @Datos.nodes
            (
                '/Operaciones/FechaOperacion/Persona'
            ) AS X(Nodo)

            INNER JOIN dbo.Persona P
                ON P.ValorDocumentoIdentidad =
                   X.Nodo.value
                   (
                       '@ValorDocumentoIdentidad',
                       'VARCHAR(32)'
                   )

            WHERE
                X.Nodo.value
                (
                    '(../@Fecha)[1]',
                    'DATE'
                ) = @FechaActual

                AND NOT EXISTS
                (
                    SELECT 1

                    FROM dbo.PersonaTelefono PT

                    WHERE PT.idPersona = P.id

                      AND PT.NumeroTelefono =
                          X.Nodo.value
                          (
                              '@telefono1',
                              'VARCHAR(16)'
                          )
                );


            /* =================================================
               3. TELEFONO SECUNDARIO
               ================================================= */

            INSERT INTO dbo.PersonaTelefono
            (
                idPersona,
                NumeroTelefono
            )

            SELECT
                P.id,

                X.Nodo.value
                (
                    '@telefono2',
                    'VARCHAR(16)'
                )

            FROM @Datos.nodes
            (
                '/Operaciones/FechaOperacion/Persona'
            ) AS X(Nodo)

            INNER JOIN dbo.Persona P
                ON P.ValorDocumentoIdentidad =
                   X.Nodo.value
                   (
                       '@ValorDocumentoIdentidad',
                       'VARCHAR(32)'
                   )

            WHERE
                X.Nodo.value
                (
                    '(../@Fecha)[1]',
                    'DATE'
                ) = @FechaActual

                AND NOT EXISTS
                (
                    SELECT 1

                    FROM dbo.PersonaTelefono PT

                    WHERE PT.idPersona = P.id

                      AND PT.NumeroTelefono =
                          X.Nodo.value
                          (
                              '@telefono2',
                              'VARCHAR(16)'
                          )
                );


            /* =================================================
               4. CUENTAS

               El trigger crea automáticamente el primer
               estado de cuenta.
               ================================================= */

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

                X.Nodo.value
                (
                    '@TipoCuentaId',
                    'INT'
                ),

                X.Nodo.value
                (
                    '@NumeroCuenta',
                    'VARCHAR(32)'
                ),

                X.Nodo.value
                (
                    '@FechaCreacion',
                    'DATE'
                ),

                X.Nodo.value
                (
                    '@Saldo',
                    'MONEY'
                )

            FROM @Datos.nodes
            (
                '/Operaciones/FechaOperacion/Cuenta'
            ) AS X(Nodo)

            INNER JOIN dbo.Persona P
                ON P.ValorDocumentoIdentidad =
                   X.Nodo.value
                   (
                       '@ValorDocumentoIdentidadDelCliente',
                       'VARCHAR(32)'
                   )

            WHERE
                X.Nodo.value
                (
                    '(../@Fecha)[1]',
                    'DATE'
                ) = @FechaActual

                AND NOT EXISTS
                (
                    SELECT 1

                    FROM dbo.Cuenta C

                    WHERE C.NumeroCuenta =
                        X.Nodo.value
                        (
                            '@NumeroCuenta',
                            'VARCHAR(32)'
                        )
                );


            /* =================================================
               5. BENEFICIARIOS
               ================================================= */

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

                X.Nodo.value
                (
                    '@IdParentezco',
                    'INT'
                ),

                X.Nodo.value
                (
                    '@Porcentaje',
                    'INT'
                ),

                1,
                NULL

            FROM @Datos.nodes
            (
                '/Operaciones/FechaOperacion/Beneficiario'
            ) AS X(Nodo)

            INNER JOIN dbo.Cuenta C
                ON C.NumeroCuenta =
                   X.Nodo.value
                   (
                       '@NumeroCuenta',
                       'VARCHAR(32)'
                   )

            INNER JOIN dbo.Persona P
                ON P.ValorDocumentoIdentidad =
                   X.Nodo.value
                   (
                       '@ValorDocumentoIdentidadBeneficiario',
                       'VARCHAR(32)'
                   )

            WHERE
                X.Nodo.value
                (
                    '(../@Fecha)[1]',
                    'DATE'
                ) = @FechaActual

                AND NOT EXISTS
                (
                    SELECT 1

                    FROM dbo.Beneficiario B

                    WHERE B.idCuenta = C.id
                      AND B.idPersona = P.id
                      AND B.Enabled = 1
                );


            /* =================================================
               6. USUARIOS
               ================================================= */

            INSERT INTO dbo.Usuario
            (
                NombreUsuario,
                Contrasena,
                EsAdministrador
            )

            SELECT
                X.Nodo.value
                (
                    '@User',
                    'VARCHAR(64)'
                ),

                X.Nodo.value
                (
                    '@Pass',
                    'VARCHAR(128)'
                ),

                X.Nodo.value
                (
                    '@EsAdministrador',
                    'BIT'
                )

            FROM @Datos.nodes
            (
                '/Operaciones/FechaOperacion/Usuario'
            ) AS X(Nodo)

            WHERE
                X.Nodo.value
                (
                    '(../@Fecha)[1]',
                    'DATE'
                ) = @FechaActual

                AND NOT EXISTS
                (
                    SELECT 1

                    FROM dbo.Usuario U

                    WHERE U.NombreUsuario =
                        X.Nodo.value
                        (
                            '@User',
                            'VARCHAR(64)'
                        )
                );


            /* =================================================
               7. RELACION USUARIO - CUENTA
               ================================================= */

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
                '/Operaciones/FechaOperacion/UsuarioPuedeVer'
            ) AS X(Nodo)

            INNER JOIN dbo.Usuario U
                ON U.NombreUsuario =
                   X.Nodo.value
                   (
                       '@User',
                       'VARCHAR(64)'
                   )

            INNER JOIN dbo.Cuenta C
                ON C.NumeroCuenta =
                   X.Nodo.value
                   (
                       '@NumeroCuenta',
                       'VARCHAR(32)'
                   )

            WHERE
                X.Nodo.value
                (
                    '(../@Fecha)[1]',
                    'DATE'
                ) = @FechaActual

                AND NOT EXISTS
                (
                    SELECT 1

                    FROM dbo.UsuarioCuenta UC

                    WHERE UC.idUsuario = U.id
                      AND UC.idCuenta = C.id
                );


            /* =================================================
               8. LIMPIAR MOVIMIENTOS DEL DIA ANTERIOR
               ================================================= */

            DELETE FROM @MovimientosDia;


            /* =================================================
               9. CARGAR MOVIMIENTOS DEL DIA
               ================================================= */

            INSERT INTO @MovimientosDia
            (
                CodigoCuenta,
                TipoMovimiento,
                Monto,
                Descripcion
            )

            SELECT
                X.Nodo.value
                (
                    '@CodigoCuenta',
                    'VARCHAR(32)'
                ),

                X.Nodo.value
                (
                    '@Tipo',
                    'VARCHAR(64)'
                ),

                X.Nodo.value
                (
                    '@Monto',
                    'MONEY'
                ),

                X.Nodo.value
                (
                    '@Descripcion',
                    'VARCHAR(256)'
                )

            FROM @Datos.nodes
            (
                '/Operaciones/FechaOperacion/Movimientos'
            ) AS X(Nodo)

            WHERE
                X.Nodo.value
                (
                    '(../@Fecha)[1]',
                    'DATE'
                ) = @FechaActual;


            /* =================================================
               10. OBTENER PRIMER Y ULTIMO SEC REAL

               IMPORTANTE:
               DELETE no reinicia el IDENTITY de la tabla
               variable. Por eso NO asumimos Sec = 1.
               ================================================= */

            SELECT
                @SecMovimiento = MIN(Sec),
                @UltimoSecMovimiento = MAX(Sec)
            FROM @MovimientosDia;


            /* =================================================
               11. APLICAR MOVIMIENTOS UNO A UNO
               ================================================= */

            WHILE @SecMovimiento IS NOT NULL
              AND @SecMovimiento <= @UltimoSecMovimiento
            BEGIN

                SET @CodigoCuenta = NULL;
                SET @NombreMovimiento = NULL;
                SET @Monto = NULL;
                SET @Descripcion = NULL;
                SET @idCuenta = NULL;
                SET @idTipoMovimiento = NULL;
                SET @ResultadoMovimiento = 0;


                SELECT
                    @CodigoCuenta = CodigoCuenta,
                    @NombreMovimiento = TipoMovimiento,
                    @Monto = Monto,
                    @Descripcion = Descripcion

                FROM @MovimientosDia

                WHERE Sec = @SecMovimiento;


                /* Buscar cuenta */

                SELECT
                    @idCuenta = id

                FROM dbo.Cuenta

                WHERE NumeroCuenta = @CodigoCuenta;


                /* Buscar tipo de movimiento */

                SELECT
                    @idTipoMovimiento = id

                FROM dbo.TipoMovimiento

                WHERE Nombre = @NombreMovimiento;


                /* Validar existencia */

                IF @idCuenta IS NULL
                   OR @idTipoMovimiento IS NULL
                BEGIN

                    SET @outResultCode = 50002;
                    RETURN;

                END;


                /* Aplicar movimiento */

                EXEC dbo.AplicarMovimiento
                    @idCuenta = @idCuenta,
                    @idTipoMovimiento = @idTipoMovimiento,
                    @Fecha = @FechaActual,
                    @Monto = @Monto,
                    @Descripcion = @Descripcion,
                    @outResultCode =
                        @ResultadoMovimiento OUTPUT;


                IF @ResultadoMovimiento <> 0
                BEGIN

                    SET @outResultCode =
                        @ResultadoMovimiento;

                    RETURN;

                END;


                SET @SecMovimiento =
                    @SecMovimiento + 1;

            END;


            /* =================================================
               12. LIMPIAR ESTADOS DEL DIA ANTERIOR
               ================================================= */

            DELETE FROM @EstadosCerrar;


            /* =================================================
               13. BUSCAR ESTADOS QUE CIERRAN HOY
               ================================================= */

            INSERT INTO @EstadosCerrar
            (
                idEstadoCuenta
            )

            SELECT
                EC.id

            FROM dbo.EstadoCuenta EC

            WHERE EC.FechaFin = @FechaActual;


            /* =================================================
               14. OBTENER PRIMER Y ULTIMO SEC DE ESTADOS

               Igual que movimientos, NO asumimos Sec = 1.
               ================================================= */

            SELECT
                @SecEstado = MIN(Sec),
                @UltimoSecEstado = MAX(Sec)

            FROM @EstadosCerrar;


            /* =================================================
               15. CERRAR ESTADOS DEL DIA
               ================================================= */

            WHILE @SecEstado IS NOT NULL
              AND @SecEstado <= @UltimoSecEstado
            BEGIN

                SET @idEstadoCuenta = NULL;
                SET @ResultadoCierre = 0;


                SELECT
                    @idEstadoCuenta = idEstadoCuenta

                FROM @EstadosCerrar

                WHERE Sec = @SecEstado;


                EXEC dbo.CerrarEstadoCuenta
                    @idEstadoCuenta = @idEstadoCuenta,
                    @FechaCierre = @FechaActual,
                    @outResultCode =
                        @ResultadoCierre OUTPUT;


                IF @ResultadoCierre <> 0
                BEGIN

                    SET @outResultCode =
                        @ResultadoCierre;

                    RETURN;

                END;


                SET @SecEstado =
                    @SecEstado + 1;

            END;


            /* =================================================
               16. AVANZAR AL SIGUIENTE DIA

               Incluso si el XML no contiene un nodo para
               esa fecha.
               ================================================= */

            SET @FechaActual =
                DATEADD
                (
                    DAY,
                    1,
                    @FechaActual
                );

        END;


    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;


        SET @outResultCode =
            ERROR_NUMBER();

    END CATCH

END;
GO
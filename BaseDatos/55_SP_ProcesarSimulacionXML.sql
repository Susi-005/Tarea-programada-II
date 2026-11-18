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

        DECLARE
            @FechaInicial DATE,
            @FechaFinal DATE,
            @FechaActual DATE,

            @ExisteControl BIT,
            @FechaFinalizada BIT,

            @SecMovimiento INT,
            @UltimoSecMovimiento INT,
            @CodigoCuenta VARCHAR(32),
            @NombreMovimiento VARCHAR(64),
            @Monto MONEY,
            @Descripcion VARCHAR(256),
            @idCuenta INT,
            @idTipoMovimiento INT,
            @ResultadoMovimiento INT,
            @ResultadoBatch INT;


        /* =====================================================
           MOVIMIENTOS DEL DIA
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
           PRIMERA Y ULTIMA FECHA
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


        IF @FechaInicial IS NULL
           OR @FechaFinal IS NULL
        BEGIN
            SET @outResultCode = 50001;
            RETURN;
        END;


        SET @FechaActual = @FechaInicial;


        /* =====================================================
           RECORRER TODAS LAS FECHAS
           ===================================================== */

        WHILE @FechaActual <= @FechaFinal
        BEGIN

            SET @ExisteControl = 0;
            SET @FechaFinalizada = 0;


            /* =================================================
               REVISAR CONTROL DEL DIA
               ================================================= */

            SELECT
                @ExisteControl = 1,
                @FechaFinalizada = Finalizado
            FROM dbo.ControlProcesoSimulacion
            WHERE FechaOperacion = @FechaActual;


            /* =================================================
               SI YA FINALIZO, NO SE PROCESA NUEVAMENTE
               ================================================= */

            IF @ExisteControl = 0
               OR @FechaFinalizada = 0
            BEGIN


                /* =============================================
                   SI NO EXISTE CONTROL:
                   ES UNA FECHA NUEVA

                   AQUÍ SI PROCESAMOS XML Y MOVIMIENTOS
                   ============================================= */

                IF @ExisteControl = 0
                BEGIN


                    /* =========================================
                       1. PERSONAS
                       ========================================= */

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


                    /* =========================================
                       2. TELEFONO 1
                       ========================================= */

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


                    /* =========================================
                       3. TELEFONO 2
                       ========================================= */

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


                    /* =========================================
                       4. CUENTAS
                       ========================================= */

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


                    /* =========================================
                       5. BENEFICIARIOS
                       ========================================= */

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


                    /* =========================================
                       6. USUARIOS
                       ========================================= */

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


                    /* =========================================
                       7. USUARIO - CUENTA
                       ========================================= */

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


                    /* =========================================
                       8. MOVIMIENTOS DEL DIA
                       ========================================= */

                    DELETE FROM @MovimientosDia;


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


                    SELECT
                        @SecMovimiento = MIN(Sec),
                        @UltimoSecMovimiento = MAX(Sec)

                    FROM @MovimientosDia;


                    /* =========================================
                       9. APLICAR MOVIMIENTOS
                       ========================================= */

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


                        SELECT
                            @idCuenta = id
                        FROM dbo.Cuenta
                        WHERE NumeroCuenta = @CodigoCuenta;


                        SELECT
                            @idTipoMovimiento = id
                        FROM dbo.TipoMovimiento
                        WHERE Nombre = @NombreMovimiento;


                        IF @idCuenta IS NULL
                           OR @idTipoMovimiento IS NULL
                        BEGIN

                            SET @outResultCode = 50002;
                            RETURN;

                        END;


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

                END;


                /* =============================================
                   PROCESO BATCH

                   Si la fecha era nueva:
                   inicia normalmente.

                   Si estaba incompleta:
                   ProcesarCierresDia continúa desde
                   UltimoIdProcesado.
                   ============================================= */

                SET @ResultadoBatch = 0;


                EXEC dbo.ProcesarCierresDia
                    @FechaOperacion = @FechaActual,
                    @outResultCode = @ResultadoBatch OUTPUT;


                IF @ResultadoBatch <> 0
                BEGIN

                    SET @outResultCode =
                        @ResultadoBatch;

                    RETURN;

                END;

            END;


            /* =================================================
               SIGUIENTE FECHA

               Si ya estaba Finalizado = 1 simplemente llegamos
               hasta aquí sin insertar ni modificar nada.
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
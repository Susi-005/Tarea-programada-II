USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.CerrarEstadoCuenta
    @idEstadoCuenta INT,
    @FechaCierre DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SET @outResultCode = 0;

        DECLARE
            @idCuenta INT,
            @FechaFin DATE,
            @FechaInicioNuevo DATE,
            @FechaFinNuevo DATE,

            @SaldoMinimoPeriodo MONEY,
            @SaldoActual MONEY,
            @NuevoSaldo MONEY,

            @TasaInteresAnual DECIMAL(5,2),
            @InteresMensual MONEY,

            @SaldoMinimoPermitido MONEY,
            @MultaSaldoMin MONEY,

            @NumRetirosHumano INT,
            @NumRetirosAutomatico INT,

            @ComisionHumano MONEY,
            @ComisionAutomatico MONEY,

            @CantidadATM INT,
            @CantidadHumano INT,

            @ExcesoATM INT,
            @ExcesoHumano INT,

            @MontoComisionATM MONEY,
            @MontoComisionHumano MONEY,

            @CargoMensual MONEY,

            @idTipoInteres INT,
            @idTipoComisionATM INT,
            @idTipoComisionHumano INT,
            @idTipoMultaSaldo INT,
            @idTipoCargoServicio INT;


        /* =====================================================
           VALIDAR ESTADO DE CUENTA
           ===================================================== */

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.EstadoCuenta
            WHERE id = @idEstadoCuenta
        )
        BEGIN
            SET @outResultCode = 50001;
            RETURN;
        END;


        /* =====================================================
           OBTENER INFORMACION
           ===================================================== */

        SELECT
            @idCuenta = EC.idCuenta,
            @FechaFin = EC.FechaFin,
            @SaldoMinimoPeriodo = EC.SaldoMinimo,

            @CantidadATM = EC.CantidadOperacionesATM,
            @CantidadHumano = EC.CantidadOperacionesHumano,

            @SaldoActual = C.Saldo,

            @TasaInteresAnual = TCA.TasaInteresAnual,
            @SaldoMinimoPermitido = TCA.SaldoMinimo,
            @MultaSaldoMin = TCA.MultaSaldoMin,

            @NumRetirosHumano = TCA.NumRetirosHumano,
            @NumRetirosAutomatico = TCA.NumRetirosAutomatico,

            @ComisionHumano = TCA.ComisionHumano,
            @ComisionAutomatico = TCA.ComisionAutomatico,

            @CargoMensual = TCA.CargoMensual

        FROM dbo.EstadoCuenta EC

        INNER JOIN dbo.Cuenta C
            ON C.id = EC.idCuenta

        INNER JOIN dbo.TipoCuentaAhorro TCA
            ON TCA.id = C.idTipoCuentaAhorro

        WHERE EC.id = @idEstadoCuenta;


        /* =====================================================
           VALIDAR FECHA DE CIERRE
           ===================================================== */

        IF @FechaCierre <> @FechaFin
        BEGIN
            SET @outResultCode = 50002;
            RETURN;
        END;


        /* =====================================================
           BUSCAR TIPOS DE MOVIMIENTO REALES DE TP3
           ===================================================== */

        SELECT @idTipoInteres = id
        FROM dbo.TipoMovimiento
        WHERE Nombre = 'Intereses Mensuales';


        SELECT @idTipoComisionATM = id
        FROM dbo.TipoMovimiento
        WHERE Nombre = 'Comision Exceso ATM';


        SELECT @idTipoComisionHumano = id
        FROM dbo.TipoMovimiento
        WHERE Nombre = 'Comision Exceso Ventana';


        SELECT @idTipoMultaSaldo = id
        FROM dbo.TipoMovimiento
        WHERE Nombre = 'Multa Saldo Minimo';


        SELECT @idTipoCargoServicio = id
        FROM dbo.TipoMovimiento
        WHERE Nombre = 'Cargo Servicio Mensual';


        IF @idTipoInteres IS NULL
           OR @idTipoComisionATM IS NULL
           OR @idTipoComisionHumano IS NULL
           OR @idTipoMultaSaldo IS NULL
           OR @idTipoCargoServicio IS NULL
        BEGIN
            SET @outResultCode = 50003;
            RETURN;
        END;


        /* =====================================================
           CALCULAR INTERESES
           ===================================================== */

        SET @InteresMensual =
            @SaldoMinimoPeriodo
            * (@TasaInteresAnual / 100.0)
            / 12.0;


        /* =====================================================
           CALCULAR EXCESO ATM
           ===================================================== */

        SET @ExcesoATM =
            @CantidadATM - @NumRetirosAutomatico;

        IF @ExcesoATM < 0
        BEGIN
            SET @ExcesoATM = 0;
        END;

        SET @MontoComisionATM =
            @ExcesoATM * @ComisionAutomatico;


        /* =====================================================
           CALCULAR EXCESO CAJERO HUMANO
           ===================================================== */

        SET @ExcesoHumano =
            @CantidadHumano - @NumRetirosHumano;

        IF @ExcesoHumano < 0
        BEGIN
            SET @ExcesoHumano = 0;
        END;

        SET @MontoComisionHumano =
            @ExcesoHumano * @ComisionHumano;


        /* =====================================================
           FECHAS DEL SIGUIENTE ESTADO
           ===================================================== */

        SET @FechaInicioNuevo =
            DATEADD(DAY, 1, @FechaFin);

        SET @FechaFinNuevo =
            DATEADD
            (
                DAY,
                -1,
                DATEADD
                (
                    MONTH,
                    1,
                    @FechaInicioNuevo
                )
            );


        /* =====================================================
           TRANSACCION DE CIERRE Y APERTURA
           ===================================================== */

        BEGIN TRANSACTION;


            /* =================================================
               1. INTERESES
               ================================================= */

            IF @InteresMensual > 0
            BEGIN

                SET @NuevoSaldo =
                    @SaldoActual + @InteresMensual;

                INSERT INTO dbo.Movimiento
                (
                    idCuenta,
                    idTipoMovimiento,
                    idComprobante,
                    Fecha,
                    Monto,
                    Descripcion,
                    NuevoSaldo
                )
                VALUES
                (
                    @idCuenta,
                    @idTipoInteres,
                    NULL,
                    @FechaCierre,
                    @InteresMensual,
                    'Intereses Mensuales',
                    @NuevoSaldo
                );

                SET @SaldoActual = @NuevoSaldo;

            END;


            /* =================================================
               2. COMISION EXCESO ATM
               ================================================= */

            IF @MontoComisionATM > 0
            BEGIN

                SET @NuevoSaldo =
                    @SaldoActual - @MontoComisionATM;

                INSERT INTO dbo.Movimiento
                (
                    idCuenta,
                    idTipoMovimiento,
                    idComprobante,
                    Fecha,
                    Monto,
                    Descripcion,
                    NuevoSaldo
                )
                VALUES
                (
                    @idCuenta,
                    @idTipoComisionATM,
                    NULL,
                    @FechaCierre,
                    @MontoComisionATM,
                    'Comision por exceso de operaciones ATM',
                    @NuevoSaldo
                );

                SET @SaldoActual = @NuevoSaldo;

            END;


            /* =================================================
               3. COMISION EXCESO VENTANA
               ================================================= */

            IF @MontoComisionHumano > 0
            BEGIN

                SET @NuevoSaldo =
                    @SaldoActual - @MontoComisionHumano;

                INSERT INTO dbo.Movimiento
                (
                    idCuenta,
                    idTipoMovimiento,
                    idComprobante,
                    Fecha,
                    Monto,
                    Descripcion,
                    NuevoSaldo
                )
                VALUES
                (
                    @idCuenta,
                    @idTipoComisionHumano,
                    NULL,
                    @FechaCierre,
                    @MontoComisionHumano,
                    'Comision por exceso de operaciones en ventana',
                    @NuevoSaldo
                );

                SET @SaldoActual = @NuevoSaldo;

            END;


            /* =================================================
               4. MULTA SALDO MINIMO
               ================================================= */

            IF @SaldoMinimoPeriodo < @SaldoMinimoPermitido
            BEGIN

                SET @NuevoSaldo =
                    @SaldoActual - @MultaSaldoMin;

                INSERT INTO dbo.Movimiento
                (
                    idCuenta,
                    idTipoMovimiento,
                    idComprobante,
                    Fecha,
                    Monto,
                    Descripcion,
                    NuevoSaldo
                )
                VALUES
                (
                    @idCuenta,
                    @idTipoMultaSaldo,
                    NULL,
                    @FechaCierre,
                    @MultaSaldoMin,
                    'Multa por incumplimiento de saldo minimo',
                    @NuevoSaldo
                );

                SET @SaldoActual = @NuevoSaldo;

            END;


            /* =================================================
               5. CARGO SERVICIO MENSUAL
               ================================================= */

            IF @CargoMensual > 0
            BEGIN

                SET @NuevoSaldo =
                    @SaldoActual - @CargoMensual;

                INSERT INTO dbo.Movimiento
                (
                    idCuenta,
                    idTipoMovimiento,
                    idComprobante,
                    Fecha,
                    Monto,
                    Descripcion,
                    NuevoSaldo
                )
                VALUES
                (
                    @idCuenta,
                    @idTipoCargoServicio,
                    NULL,
                    @FechaCierre,
                    @CargoMensual,
                    'Cargo Servicio Mensual',
                    @NuevoSaldo
                );

                SET @SaldoActual = @NuevoSaldo;

            END;


            /* =================================================
               6. ACTUALIZAR CUENTA
               ================================================= */

            UPDATE dbo.Cuenta
            SET Saldo = @SaldoActual
            WHERE id = @idCuenta;


            /* =================================================
               7. FINALIZAR ESTADO ACTUAL
               ================================================= */

            UPDATE dbo.EstadoCuenta
            SET
                InteresesAcumulados = @InteresMensual,
                SaldoFinal = @SaldoActual
            WHERE id = @idEstadoCuenta;


            /* =================================================
               8. ABRIR SIGUIENTE ESTADO
               ================================================= */

            INSERT INTO dbo.EstadoCuenta
            (
                idCuenta,
                FechaInicio,
                FechaFin,
                SaldoInicial,
                SaldoFinal,
                InteresesAcumulados,
                CantidadRetiros,
                CantidadDepositos,
                SaldoMinimo,
                CantidadOperacionesATM,
                CantidadOperacionesHumano,
                CantidadOperacionesSinpe
            )
            VALUES
            (
                @idCuenta,
                @FechaInicioNuevo,
                @FechaFinNuevo,
                @SaldoActual,
                @SaldoActual,
                0,
                0,
                0,
                @SaldoActual,
                0,
                0,
                0
            );


        COMMIT TRANSACTION;


    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        SET @outResultCode = 50005;

    END CATCH
END;
GO
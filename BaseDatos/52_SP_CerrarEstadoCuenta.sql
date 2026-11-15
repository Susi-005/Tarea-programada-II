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

            @TasaInteres DECIMAL(5,2),
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

            @CargoAnual MONEY,
            @CargoServicio MONEY,

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
           OBTENER INFORMACION DEL ESTADO, CUENTA Y TIPO
           ===================================================== */

        SELECT
            @idCuenta = EC.idCuenta,
            @FechaFin = EC.FechaFin,
            @SaldoMinimoPeriodo = EC.SaldoMinimo,

            @CantidadATM = EC.CantidadOperacionesATM,
            @CantidadHumano = EC.CantidadOperacionesHumano,

            @SaldoActual = C.Saldo,

            @TasaInteres = TCA.Interes,
            @SaldoMinimoPermitido = TCA.SaldoMinimo,
            @MultaSaldoMin = TCA.MultaSaldoMin,

            @NumRetirosHumano = TCA.NumRetirosHumano,
            @NumRetirosAutomatico = TCA.NumRetirosAutomatico,

            @ComisionHumano = TCA.ComisionHumano,
            @ComisionAutomatico = TCA.ComisionAutomatico,

            @CargoAnual = TCA.CargoAnual

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
           BUSCAR TIPOS DE MOVIMIENTO
           ===================================================== */

        SELECT @idTipoInteres = id
        FROM dbo.TipoMovimiento
        WHERE Nombre = 'Intereses mensuales';


        SELECT @idTipoComisionATM = id
        FROM dbo.TipoMovimiento
        WHERE Nombre = 'Comision ATM';


        SELECT @idTipoComisionHumano = id
        FROM dbo.TipoMovimiento
        WHERE Nombre = 'Comision Humano';


        SELECT @idTipoMultaSaldo = id
        FROM dbo.TipoMovimiento
        WHERE Nombre = 'Multa saldo minimo';


        SELECT @idTipoCargoServicio = id
        FROM dbo.TipoMovimiento
        WHERE Nombre = 'Cargo por servicio';


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
            * (@TasaInteres / 100.0)
            / 12.0;


        /* =====================================================
           CALCULAR EXCESOS ATM
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
           CALCULAR EXCESOS CAJERO HUMANO
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
           CARGO POR SERVICIO

           El modelo heredado utiliza CargoAnual.
           Se convierte a monto mensual.
           ===================================================== */

        SET @CargoServicio =
            @CargoAnual / 12.0;


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
           TRANSACCION COMPLETA DEL CIERRE
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
                    'Intereses mensuales',
                    @NuevoSaldo
                );


                SET @SaldoActual = @NuevoSaldo;

            END;


            /* =================================================
               2. COMISION POR EXCESO ATM
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
               3. COMISION POR EXCESO CAJERO HUMANO
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
                    'Comision por exceso de operaciones en cajero humano',
                    @NuevoSaldo
                );


                SET @SaldoActual = @NuevoSaldo;

            END;


            /* =================================================
               4. MULTA POR SALDO MINIMO
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
               5. CARGO POR SERVICIO
               ================================================= */

            IF @CargoServicio > 0
            BEGIN

                SET @NuevoSaldo =
                    @SaldoActual - @CargoServicio;


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
                    @CargoServicio,
                    'Cargo por servicio',
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
               8. ABRIR NUEVO ESTADO DE CUENTA
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
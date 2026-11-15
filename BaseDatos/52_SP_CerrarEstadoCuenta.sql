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
            @SaldoMinimo MONEY,
            @SaldoActual MONEY,
            @TasaInteres DECIMAL(5,2),
            @InteresMensual MONEY,
            @NuevoSaldo MONEY,
            @idTipoMovimientoInteres INT;


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
           OBTENER DATOS DEL ESTADO Y LA CUENTA
           ===================================================== */

        SELECT
            @idCuenta = EC.idCuenta,
            @FechaFin = EC.FechaFin,
            @SaldoMinimo = EC.SaldoMinimo,
            @SaldoActual = C.Saldo,
            @TasaInteres = TCA.Interes

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
           BUSCAR TIPO DE MOVIMIENTO DE INTERESES
           ===================================================== */

        SELECT
            @idTipoMovimientoInteres = id
        FROM dbo.TipoMovimiento
        WHERE Nombre = 'Intereses mensuales';


        IF @idTipoMovimientoInteres IS NULL
        BEGIN
            SET @outResultCode = 50003;
            RETURN;
        END;


        /* =====================================================
           CALCULAR INTERES MENSUAL

           saldo mínimo × tasa anual / 100 / 12
           ===================================================== */

        SET @InteresMensual =
            @SaldoMinimo *
            (@TasaInteres / 100.0) /
            12.0;


        SET @NuevoSaldo =
            @SaldoActual + @InteresMensual;


        /* =====================================================
           TRANSACCION DE CIERRE
           ===================================================== */

        BEGIN TRANSACTION;


            /* Movimiento de intereses */

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
                @idTipoMovimientoInteres,
                NULL,
                @FechaCierre,
                @InteresMensual,
                'Intereses mensuales',
                @NuevoSaldo
            );


            /* Actualizar saldo de la cuenta */

            UPDATE dbo.Cuenta
            SET Saldo = @NuevoSaldo
            WHERE id = @idCuenta;


            /* Actualizar estado de cuenta */

            UPDATE dbo.EstadoCuenta
            SET
                InteresesAcumulados = @InteresMensual,
                SaldoFinal = @NuevoSaldo
            WHERE id = @idEstadoCuenta;


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
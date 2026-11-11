USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.AbrirEstadoCuenta
    @idCuenta INT,
    @FechaInicio DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SET @outResultCode = 0;

        DECLARE
            @SaldoActual MONEY,
            @FechaFin DATE;


        /* =====================================================
           VALIDAR QUE LA CUENTA EXISTA
           ===================================================== */

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Cuenta
            WHERE id = @idCuenta
        )
        BEGIN
            SET @outResultCode = 50001;
            RETURN;
        END;


        /* =====================================================
           OBTENER SALDO ACTUAL
           ===================================================== */

        SELECT
            @SaldoActual = Saldo
        FROM dbo.Cuenta
        WHERE id = @idCuenta;


        /* =====================================================
           CALCULAR FECHA FINAL DEL NUEVO PERIODO
           ===================================================== */

        SET @FechaFin =
            DATEADD
            (
                DAY,
                -1,
                DATEADD
                (
                    MONTH,
                    1,
                    @FechaInicio
                )
            );


        /* =====================================================
           EVITAR DUPLICAR EL MISMO PERIODO
           ===================================================== */

        IF EXISTS
        (
            SELECT 1
            FROM dbo.EstadoCuenta
            WHERE idCuenta = @idCuenta
              AND FechaInicio = @FechaInicio
        )
        BEGIN
            SET @outResultCode = 50002;
            RETURN;
        END;


        /* =====================================================
           CREAR EL NUEVO ESTADO DE CUENTA
           ===================================================== */

        BEGIN TRANSACTION;


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
                @FechaInicio,
                @FechaFin,
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
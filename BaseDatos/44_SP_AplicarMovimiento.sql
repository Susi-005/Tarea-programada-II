USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.AplicarMovimiento
    @idCuenta INT,
    @idTipoMovimiento INT,
    @Fecha DATE,
    @Monto MONEY,
    @Descripcion VARCHAR(256),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SET @outResultCode = 0;

        DECLARE
            @SaldoActual MONEY,
            @NuevoSaldo MONEY,
            @TipoAccion VARCHAR(8),
            @NombreTipoMovimiento VARCHAR(64),
            @GeneraComprobante BIT,
            @idComprobante INT = NULL,
            @idEstadoCuenta INT;


        /* =====================================================
           VALIDAR CUENTA
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
           VALIDAR TIPO DE MOVIMIENTO
           ===================================================== */

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.TipoMovimiento
            WHERE id = @idTipoMovimiento
        )
        BEGIN
            SET @outResultCode = 50002;
            RETURN;
        END;


        /* =====================================================
           VALIDAR MONTO
           ===================================================== */

        IF @Monto <= 0
        BEGIN
            SET @outResultCode = 50003;
            RETURN;
        END;


        /* =====================================================
           OBTENER DATOS DE LA CUENTA
           ===================================================== */

        SELECT
            @SaldoActual = Saldo
        FROM dbo.Cuenta
        WHERE id = @idCuenta;


        /* =====================================================
           OBTENER DATOS DEL TIPO DE MOVIMIENTO
           ===================================================== */

        SELECT
            @TipoAccion = TipoAccion,
            @NombreTipoMovimiento = Nombre,
            @GeneraComprobante = FlagGeneraComprobante
        FROM dbo.TipoMovimiento
        WHERE id = @idTipoMovimiento;


        /* =====================================================
           BUSCAR ESTADO DE CUENTA ACTIVO PARA LA FECHA
           ===================================================== */

        SELECT
            @idEstadoCuenta = id
        FROM dbo.EstadoCuenta
        WHERE idCuenta = @idCuenta
          AND @Fecha BETWEEN FechaInicio AND FechaFin;


        IF @idEstadoCuenta IS NULL
        BEGIN
            SET @outResultCode = 50004;
            RETURN;
        END;


        /* =====================================================
           CALCULAR NUEVO SALDO
           ===================================================== */

        IF @TipoAccion = 'CREDITO'
        BEGIN
            SET @NuevoSaldo = @SaldoActual + @Monto;
        END
        ELSE
        BEGIN
            SET @NuevoSaldo = @SaldoActual - @Monto;
        END;


        /* =====================================================
           TRANSACCION
           ===================================================== */

        BEGIN TRANSACTION;


            /* =================================================
               CREAR COMPROBANTE SI CORRESPONDE
               ================================================= */

            IF @GeneraComprobante = 1
            BEGIN

                INSERT INTO dbo.Comprobante
                (
                    idCuenta,
                    Fecha,
                    Texto
                )
                VALUES
                (
                    @idCuenta,
                    @Fecha,
                    @Descripcion
                );

                SET @idComprobante = SCOPE_IDENTITY();

            END;


            /* =================================================
               REGISTRAR MOVIMIENTO
               ================================================= */

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
                @idTipoMovimiento,
                @idComprobante,
                @Fecha,
                @Monto,
                @Descripcion,
                @NuevoSaldo
            );


            /* =================================================
               ACTUALIZAR SALDO DE LA CUENTA
               ================================================= */

            UPDATE dbo.Cuenta
            SET Saldo = @NuevoSaldo
            WHERE id = @idCuenta;


            /* =================================================
               ACTUALIZAR ESTADO DE CUENTA
               ================================================= */

            UPDATE dbo.EstadoCuenta
            SET
                SaldoFinal = @NuevoSaldo,

                SaldoMinimo =
                    CASE
                        WHEN @NuevoSaldo < SaldoMinimo
                            THEN @NuevoSaldo
                        ELSE SaldoMinimo
                    END,

                CantidadOperacionesATM =
                    CantidadOperacionesATM +
                    CASE
                        WHEN @NombreTipoMovimiento = 'Retiro ATM'
                            THEN 1
                        ELSE 0
                    END,

                CantidadOperacionesHumano =
                    CantidadOperacionesHumano +
                    CASE
                        WHEN @NombreTipoMovimiento = 'Deposito Ventana'
                          OR @NombreTipoMovimiento = 'Retiro Ventana'
                            THEN 1
                        ELSE 0
                    END,

                CantidadOperacionesSinpe =
                    CantidadOperacionesSinpe +
                    CASE
                        WHEN @NombreTipoMovimiento = 'Retiro Sinpe'
                          OR @NombreTipoMovimiento = 'Deposito Sinpe'
                            THEN 1
                        ELSE 0
                    END

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
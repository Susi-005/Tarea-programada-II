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
            @idEstadoCuenta INT,

            @MontoMaxSinpeDiario MONEY,
            @ComisionSinpe MONEY,
            @AcumuladoSinpeDia MONEY = 0,
            @TotalSinpeConMovimiento MONEY = 0,

            @idTipoMovimientoComisionSinpe INT,
            @SaldoDespuesComision MONEY,

            @FechaCreacion DATE,
            @EsMovimientoDiaCreacion BIT = 0;


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
           DATOS DE CUENTA Y TIPO DE CUENTA
           ===================================================== */

        SELECT
            @SaldoActual = C.Saldo,
            @FechaCreacion = C.FechaCreacion,
            @MontoMaxSinpeDiario = TCA.MontoMaxSinpeDiario,
            @ComisionSinpe = TCA.ComisionSinpe
        FROM dbo.Cuenta C

        INNER JOIN dbo.TipoCuentaAhorro TCA
            ON TCA.id = C.idTipoCuentaAhorro

        WHERE C.id = @idCuenta;


        /* =====================================================
           DATOS DEL TIPO DE MOVIMIENTO
           ===================================================== */

        SELECT
            @TipoAccion = TM.TipoAccion,
            @NombreTipoMovimiento = TM.Nombre,
            @GeneraComprobante = TM.FlagGeneraComprobante
        FROM dbo.TipoMovimiento TM
        WHERE TM.id = @idTipoMovimiento;


   /* =====================================================
   BUSCAR ESTADO QUE CORRESPONDE A LA FECHA
   ===================================================== */

SELECT
    @idEstadoCuenta = EC.id
FROM dbo.EstadoCuenta EC
WHERE EC.idCuenta = @idCuenta
  AND @Fecha BETWEEN EC.FechaInicio AND EC.FechaFin;


/* =====================================================
   CASO ESPECIAL:
   MOVIMIENTO EL MISMO DIA DE CREACION
   ===================================================== */

IF @idEstadoCuenta IS NULL
   AND @Fecha = @FechaCreacion
BEGIN

    SELECT TOP 1
        @idEstadoCuenta = EC.id
    FROM dbo.EstadoCuenta EC
    WHERE EC.idCuenta = @idCuenta
    ORDER BY EC.FechaInicio;

    SET @EsMovimientoDiaCreacion = 1;

END;


/* =====================================================
   SI NO EXISTE ESTADO APLICABLE, RECHAZAR
   ===================================================== */

IF @idEstadoCuenta IS NULL
BEGIN
    SET @outResultCode = 50004;
    RETURN;
END;


        /* =====================================================
           CONTROL DIARIO DE RETIROS SINPE
           ===================================================== */

        IF @NombreTipoMovimiento = 'Retiro Sinpe'
        BEGIN

            SELECT
                @AcumuladoSinpeDia =
                    ISNULL(SUM(M.Monto), 0)
            FROM dbo.Movimiento M

            INNER JOIN dbo.TipoMovimiento TM
                ON TM.id = M.idTipoMovimiento

            WHERE M.idCuenta = @idCuenta
              AND CAST(M.Fecha AS DATE) = @Fecha
              AND TM.Nombre = 'Retiro Sinpe';


            SET @TotalSinpeConMovimiento =
                @AcumuladoSinpeDia + @Monto;


            IF @TotalSinpeConMovimiento > @MontoMaxSinpeDiario
            BEGIN

                SELECT
                    @idTipoMovimientoComisionSinpe = id
                FROM dbo.TipoMovimiento
                WHERE Nombre = 'Comision Sinpe';


                IF @idTipoMovimientoComisionSinpe IS NULL
                BEGIN
                    SET @outResultCode = 50006;
                    RETURN;
                END;

            END;

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
               GENERAR COMPROBANTE SI CORRESPONDE
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
               MOVIMIENTO PRINCIPAL
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
               ACTUALIZAR CUENTA
               ================================================= */

            UPDATE dbo.Cuenta
            SET Saldo = @NuevoSaldo
            WHERE id = @idCuenta;


            /* =================================================
               ACTUALIZAR ESTADO DE CUENTA
               ================================================= */

            IF @EsMovimientoDiaCreacion = 1
            BEGIN

                /*
                   El movimiento ocurrió antes de iniciar formalmente
                   el primer período.

                   El saldo resultante se convierte en el saldo
                   con que empieza el primer estado de cuenta.
                */

                UPDATE dbo.EstadoCuenta
                SET
                    SaldoInicial = @NuevoSaldo,
                    SaldoFinal = @NuevoSaldo,
                    SaldoMinimo = @NuevoSaldo
                WHERE id = @idEstadoCuenta;

            END
            ELSE
            BEGIN

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
                              OR @NombreTipoMovimiento = 'Deposito ATM'
                                THEN 1
                            ELSE 0
                        END,

                    CantidadOperacionesHumano =
                        CantidadOperacionesHumano +
                        CASE
                            WHEN @NombreTipoMovimiento = 'Retiro Ventana'
                              OR @NombreTipoMovimiento = 'Deposito Ventana'
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

            END;


            /* =================================================
               COMISION AUTOMATICA SINPE
               ================================================= */

            IF @NombreTipoMovimiento = 'Retiro Sinpe'
               AND @TotalSinpeConMovimiento > @MontoMaxSinpeDiario
               AND @ComisionSinpe > 0
            BEGIN

                SET @SaldoDespuesComision =
                    @NuevoSaldo - @ComisionSinpe;


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
                    @idTipoMovimientoComisionSinpe,
                    NULL,
                    @Fecha,
                    @ComisionSinpe,
                    'Comision por exceso de limite diario SINPE',
                    @SaldoDespuesComision
                );


                UPDATE dbo.Cuenta
                SET Saldo = @SaldoDespuesComision
                WHERE id = @idCuenta;


                UPDATE dbo.EstadoCuenta
                SET
                    SaldoFinal = @SaldoDespuesComision,

                    SaldoMinimo =
                        CASE
                            WHEN @SaldoDespuesComision < SaldoMinimo
                                THEN @SaldoDespuesComision
                            ELSE SaldoMinimo
                        END

                WHERE id = @idEstadoCuenta;

            END;


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
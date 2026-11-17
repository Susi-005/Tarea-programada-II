USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.ProcesarCierresDia
    @FechaOperacion DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SET @outResultCode = 0;

        DECLARE
            @idControl INT,
            @UltimoIdProcesado INT,
            @CantidadProcesar INT,
            @CantidadProcesada INT,
            @idEstadoCuenta INT,
            @ResultadoCierre INT;


        /* =====================================================
           VALIDAR SI EL PROCESO YA FINALIZO PARA ESTA FECHA
           ===================================================== */

        IF EXISTS
        (
            SELECT 1
            FROM dbo.ControlProcesoSimulacion
            WHERE FechaOperacion = @FechaOperacion
              AND Finalizado = 1
        )
        BEGIN
            SET @outResultCode = 50020;
            RETURN;
        END;


        /* =====================================================
           SI NO EXISTE CONTROL PARA LA FECHA, CREARLO
           ===================================================== */

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.ControlProcesoSimulacion
            WHERE FechaOperacion = @FechaOperacion
        )
        BEGIN

            SELECT
                @CantidadProcesar = COUNT(*)
            FROM dbo.EstadoCuenta
            WHERE FechaFin = @FechaOperacion;


            INSERT INTO dbo.ControlProcesoSimulacion
            (
                FechaOperacion,
                UltimoIdProcesado,
                CantidadProcesar,
                CantidadProcesada,
                Finalizado,
                FechaHoraInicio,
                FechaHoraFin
            )
            VALUES
            (
                @FechaOperacion,
                0,
                @CantidadProcesar,
                0,
                0,
                GETDATE(),
                NULL
            );

        END;


        /* =====================================================
           OBTENER ESTADO ACTUAL DEL CONTROL
           ===================================================== */

        SELECT
            @idControl = id,
            @UltimoIdProcesado = UltimoIdProcesado,
            @CantidadProcesar = CantidadProcesar,
            @CantidadProcesada = CantidadProcesada
        FROM dbo.ControlProcesoSimulacion
        WHERE FechaOperacion = @FechaOperacion;


        /* =====================================================
           BUSCAR SIGUIENTE ESTADO A PROCESAR

           Siempre toma una PK mayor que la ultima procesada.
           ===================================================== */

        SELECT TOP 1
            @idEstadoCuenta = id
        FROM dbo.EstadoCuenta
        WHERE FechaFin = @FechaOperacion
          AND id > @UltimoIdProcesado
        ORDER BY id;


        /* =====================================================
           PROCESAR UNO POR UNO
           ===================================================== */

        WHILE @idEstadoCuenta IS NOT NULL
        BEGIN

            SET @ResultadoCierre = 0;


            EXEC dbo.CerrarEstadoCuenta
                @idEstadoCuenta = @idEstadoCuenta,
                @FechaCierre = @FechaOperacion,
                @outResultCode = @ResultadoCierre OUTPUT;


            /* =================================================
               SI FALLA UNA CUENTA, DETENER

               El control conserva la ultima PK exitosa.
               ================================================= */

            IF @ResultadoCierre <> 0
            BEGIN

                SET @outResultCode = @ResultadoCierre;
                RETURN;

            END;


            /* =================================================
               ACTUALIZAR PROGRESO DEL BATCH
               ================================================= */

            SET @CantidadProcesada =
                @CantidadProcesada + 1;


            UPDATE dbo.ControlProcesoSimulacion
            SET
                UltimoIdProcesado = @idEstadoCuenta,
                CantidadProcesada = @CantidadProcesada
            WHERE id = @idControl;


            SET @UltimoIdProcesado =
                @idEstadoCuenta;


            /* =================================================
               BUSCAR SIGUIENTE PK
               ================================================= */

            SET @idEstadoCuenta = NULL;


            SELECT TOP 1
                @idEstadoCuenta = id
            FROM dbo.EstadoCuenta
            WHERE FechaFin = @FechaOperacion
              AND id > @UltimoIdProcesado
            ORDER BY id;

        END;


        /* =====================================================
           MARCAR PROCESO COMO FINALIZADO
           ===================================================== */

        UPDATE dbo.ControlProcesoSimulacion
        SET
            Finalizado = 1,
            FechaHoraFin = GETDATE()
        WHERE id = @idControl;


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
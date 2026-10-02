USE TareaProgramada2;
GO

CREATE PROCEDURE dbo.RegistrarBitacora
    @idUsuario INT,
    @idTipoOperacion INT,
    @IP VARCHAR(64),
    @DatosAntes VARCHAR(2048) = NULL,
    @DatosDespues VARCHAR(2048) = NULL,
    @outResultCode INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        /* Valida que el usuario exista. */
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Usuario
            WHERE id = @idUsuario
        )
        BEGIN
            SET @outResultCode = 1;
            RETURN;
        END;

        /* Valida que el tipo de operación exista. */
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.TipoOperacion
            WHERE id = @idTipoOperacion
        )
        BEGIN
            SET @outResultCode = 2;
            RETURN;
        END;

        BEGIN TRANSACTION;

        INSERT INTO dbo.Bitacora
        (
            idUsuario,
            idTipoOperacion,
            IP,
            FechaHora,
            DatosAntes,
            DatosDespues
        )
        VALUES
        (
            @idUsuario,
            @idTipoOperacion,
            @IP,
            GETDATE(),
            @DatosAntes,
            @DatosDespues
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
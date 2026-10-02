USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.ValidarLogin
    @inNombreUsuario VARCHAR(64),
    @inContrasena    VARCHAR(128),
    @inIP            VARCHAR(64),
    @outResultCode   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @idUsuario INT,
                @esAdmin   BIT;

        SELECT @idUsuario = U.id,
               @esAdmin   = U.EsAdministrador
        FROM dbo.Usuario AS U
        WHERE U.NombreUsuario = @inNombreUsuario
          AND U.Contrasena = @inContrasena COLLATE Latin1_General_CS_AS;

        IF @idUsuario IS NULL
        BEGIN
            SET @outResultCode = 50001;   -- usuario o contraseña incorrectos
            RETURN;
        END;

        -- Pendiente (día 30): registrar el login en la bitácora
        -- (idUsuario, IdTipoOperacion = 1, @inIP, fecha y hora)

        SELECT @idUsuario AS IdUsuario,
               @esAdmin   AS EsAdministrador;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50005;       -- error de base de datos
    END CATCH;
END;
GO

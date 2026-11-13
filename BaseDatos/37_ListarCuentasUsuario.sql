USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.ListarCuentasUsuario
    @inIdUsuario   INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            C.id           AS IdCuenta,
            C.NumeroCuenta,
            TC.Nombre      AS TipoCuenta,
            M.Nombre       AS Moneda,
            C.Saldo
        FROM dbo.UsuarioCuenta AS UC
        INNER JOIN dbo.Cuenta AS C            ON C.id  = UC.idCuenta
        INNER JOIN dbo.TipoCuentaAhorro AS TC ON TC.id = C.idTipoCuentaAhorro
        INNER JOIN dbo.TipoMoneda AS M        ON M.id  = TC.idTipoMoneda
        WHERE UC.idUsuario = @inIdUsuario
        ORDER BY C.NumeroCuenta;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50005;
    END CATCH;
END;
GO



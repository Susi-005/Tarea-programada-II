USE TareaProgramada2;
GO

CREATE PROCEDURE dbo.InsertarBeneficiario
    @idCuenta INT,
    @Nombre VARCHAR(64),
    @ValorDocumentoIdentidad VARCHAR(32),
    @FechaNacimiento DATE,
    @Email VARCHAR(128),
    @Telefono1 VARCHAR(16),
    @Telefono2 VARCHAR(16),
    @idParentesco INT,
    @Porcentaje INT,
    @outResultCode INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        /* Valida que la cuenta exista. */
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Cuenta
            WHERE id = @idCuenta
        )
        BEGIN
            SET @outResultCode = 1;
            RETURN;
        END;

        /* Valida el porcentaje. */
        IF @Porcentaje < 0 OR @Porcentaje > 100
        BEGIN
            SET @outResultCode = 2;
            RETURN;
        END;

        /* Valida máximo 3 beneficiarios activos por cuenta. */
        IF
        (
            SELECT COUNT(*)
            FROM dbo.Beneficiario
            WHERE idCuenta = @idCuenta
              AND Enabled = 1
        ) >= 3
        BEGIN
            SET @outResultCode = 3;
            RETURN;
        END;

        /* Valida que el parentesco exista. */
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Parentesco
            WHERE id = @idParentesco
        )
        BEGIN
            SET @outResultCode = 4;
            RETURN;
        END;

        BEGIN TRANSACTION;

        DECLARE @idPersona INT;

        /* Busca si la persona ya existe por documento. */
        SELECT @idPersona = id
        FROM dbo.Persona
        WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad;

        /* Si no existe, la crea. */
        IF @idPersona IS NULL
        BEGIN
            INSERT INTO dbo.Persona
            (
                idTipoDocumentoIdentidad,
                Nombre,
                ValorDocumentoIdentidad,
                FechaNacimiento,
                Email
            )
            VALUES
            (
                1,
                @Nombre,
                @ValorDocumentoIdentidad,
                @FechaNacimiento,
                @Email
            );

            SET @idPersona = SCOPE_IDENTITY();

            INSERT INTO dbo.PersonaTelefono
            (
                idPersona,
                NumeroTelefono
            )
            VALUES
            (
                @idPersona,
                @Telefono1
            );

            INSERT INTO dbo.PersonaTelefono
            (
                idPersona,
                NumeroTelefono
            )
            VALUES
            (
                @idPersona,
                @Telefono2
            );
        END;

        /* Inserta la relación como beneficiario. */
        INSERT INTO dbo.Beneficiario
        (
            idCuenta,
            idPersona,
            idParentesco,
            Porcentaje,
            Enabled,
            FechaDesactivacion
        )
        VALUES
        (
            @idCuenta,
            @idPersona,
            @idParentesco,
            @Porcentaje,
            1,
            NULL
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
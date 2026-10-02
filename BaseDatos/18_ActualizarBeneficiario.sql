USE TareaProgramada2;
GO

CREATE PROCEDURE dbo.ActualizarBeneficiario
    @idBeneficiario INT,
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

        /* Valida que el beneficiario exista y esté activo. */
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Beneficiario
            WHERE id = @idBeneficiario
              AND Enabled = 1
        )
        BEGIN
            SET @outResultCode = 1;
            RETURN;
        END;

        /* Valida porcentaje. */
        IF @Porcentaje < 0 OR @Porcentaje > 100
        BEGIN
            SET @outResultCode = 2;
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
            SET @outResultCode = 3;
            RETURN;
        END;

        DECLARE @idPersona INT;

        SELECT @idPersona = idPersona
        FROM dbo.Beneficiario
        WHERE id = @idBeneficiario;

        /*
            Evita colocar a esta persona un documento
            que ya pertenece a otra persona.
        */
        IF EXISTS
        (
            SELECT 1
            FROM dbo.Persona
            WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad
              AND id <> @idPersona
        )
        BEGIN
            SET @outResultCode = 4;
            RETURN;
        END;

        BEGIN TRANSACTION;

        /* Actualiza los datos personales. */
        UPDATE dbo.Persona
        SET
            Nombre = @Nombre,
            ValorDocumentoIdentidad = @ValorDocumentoIdentidad,
            FechaNacimiento = @FechaNacimiento,
            Email = @Email
        WHERE id = @idPersona;

        /* Busca los dos teléfonos de la persona. */
        DECLARE @idTelefono1 INT;
        DECLARE @idTelefono2 INT;

        SELECT TOP 1
            @idTelefono1 = id
        FROM dbo.PersonaTelefono
        WHERE idPersona = @idPersona
        ORDER BY id;

        SELECT TOP 1
            @idTelefono2 = id
        FROM dbo.PersonaTelefono
        WHERE idPersona = @idPersona
          AND id <> @idTelefono1
        ORDER BY id;

        /* Actualiza primer teléfono. */
        IF @idTelefono1 IS NOT NULL
        BEGIN
            UPDATE dbo.PersonaTelefono
            SET NumeroTelefono = @Telefono1
            WHERE id = @idTelefono1;
        END;

        /* Actualiza segundo teléfono. */
        IF @idTelefono2 IS NOT NULL
        BEGIN
            UPDATE dbo.PersonaTelefono
            SET NumeroTelefono = @Telefono2
            WHERE id = @idTelefono2;
        END;

        /* Actualiza los datos propios del beneficiario. */
        UPDATE dbo.Beneficiario
        SET
            idParentesco = @idParentesco,
            Porcentaje = @Porcentaje
        WHERE id = @idBeneficiario;

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
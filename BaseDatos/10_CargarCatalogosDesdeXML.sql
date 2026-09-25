USE TareaProgramada2;
GO

CREATE PROCEDURE dbo.CargarCatalogosDesdeXML
    @Datos XML,
    @outResultCode INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        BEGIN TRANSACTION;

        -- Carga el catálogo de tipos de documento.
        INSERT INTO dbo.TipoDocumentoIdentidad
        (
            id,
            Nombre
        )
        SELECT
            X.Nodo.value('@Id', 'INT'),
            X.Nodo.value('@Nombre', 'VARCHAR(32)')
        FROM @Datos.nodes(
            '/Catalogos/Tipo_Doc/TipoDocuIdentidad'
        ) AS X(Nodo)
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.TipoDocumentoIdentidad AS TDI
            WHERE TDI.id = X.Nodo.value('@Id', 'INT')
        );

        -- Carga el catálogo de monedas.
        INSERT INTO dbo.TipoMoneda
        (
            id,
            Nombre,
            Simbolo
        )
        SELECT
            X.Nodo.value('@Id', 'INT'),
            X.Nodo.value('@Nombre', 'VARCHAR(32)'),
            X.Nodo.value('@Simbolo', 'VARCHAR(8)')
        FROM @Datos.nodes(
            '/Catalogos/Tipo_Moneda/TipoMoneda'
        ) AS X(Nodo)
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.TipoMoneda AS TM
            WHERE TM.id = X.Nodo.value('@Id', 'INT')
        );

        -- Carga el catálogo de parentescos.
        INSERT INTO dbo.Parentesco
        (
            id,
            Nombre
        )
        SELECT
            X.Nodo.value('@Id', 'INT'),
            X.Nodo.value('@Nombre', 'VARCHAR(32)')
        FROM @Datos.nodes(
            '/Catalogos/Parentezcos/Parentezco'
        ) AS X(Nodo)
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Parentesco AS P
            WHERE P.id = X.Nodo.value('@Id', 'INT')
        );

        -- Carga el catálogo de tipos de cuenta de ahorro.
        INSERT INTO dbo.TipoCuentaAhorro
        (
            id,
            Nombre,
            idTipoMoneda,
            SaldoMinimo,
            MultaSaldoMin,
            CargoAnual,
            NumRetirosHumano,
            NumRetirosAutomatico,
            ComisionHumano,
            ComisionAutomatico,
            Interes
        )
        SELECT
            X.Nodo.value('@Id', 'INT'),
            X.Nodo.value('@Nombre', 'VARCHAR(32)'),
            X.Nodo.value('@IdTipoMoneda', 'INT'),
            X.Nodo.value('@SaldoMinimo', 'MONEY'),
            X.Nodo.value('@MultaSaldoMin', 'MONEY'),
            X.Nodo.value('@CargoAnual', 'MONEY'),
            X.Nodo.value('@NumRetirosHumano', 'INT'),
            X.Nodo.value('@NumRetirosAutomatico', 'INT'),
            X.Nodo.value('@comisionHumano', 'MONEY'),
            X.Nodo.value('@comisionAutomatico', 'MONEY'),
            X.Nodo.value('@interes', 'DECIMAL(5, 2)')
        FROM @Datos.nodes(
            '/Catalogos/Tipo_Cuenta_Ahorros/TipoCuentaAhorro'
        ) AS X(Nodo)
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.TipoCuentaAhorro AS TCA
            WHERE TCA.id = X.Nodo.value('@Id', 'INT')
        );

        -- Carga el catálogo de tipos de operación.
        INSERT INTO dbo.TipoOperacion
        (
            id,
            Nombre
        )
        SELECT
            X.Nodo.value('@Id', 'INT'),
            X.Nodo.value('@Nombre', 'VARCHAR(64)')
        FROM @Datos.nodes(
            '/Catalogos/TipoOperaciones/TipoOperacion'
        ) AS X(Nodo)
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.TipoOperacion AS TOPE
            WHERE TOPE.id = X.Nodo.value('@Id', 'INT')
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
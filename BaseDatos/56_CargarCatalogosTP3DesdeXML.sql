USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.CargarCatalogosTP3DesdeXML
    @Datos XML,
    @outResultCode INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SET @outResultCode = 0;

        BEGIN TRANSACTION;


        /* =====================================================
           TIPOS DE DOCUMENTO
           ===================================================== */

        INSERT INTO dbo.TipoDocumentoIdentidad
        (
            id,
            Nombre
        )
        SELECT
            X.Nodo.value('@Id', 'INT'),
            X.Nodo.value('@Nombre', 'VARCHAR(32)')
        FROM @Datos.nodes
        (
            '/Catalogos/Tipo_Doc/TipoDocuIdentidad'
        ) AS X(Nodo)
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.TipoDocumentoIdentidad T
            WHERE T.id =
                X.Nodo.value('@Id', 'INT')
        );


        /* =====================================================
           MONEDAS
           ===================================================== */

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
        FROM @Datos.nodes
        (
            '/Catalogos/Tipo_Moneda/TipoMoneda'
        ) AS X(Nodo)
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.TipoMoneda T
            WHERE T.id =
                X.Nodo.value('@Id', 'INT')
        );


        /* =====================================================
           PARENTESCOS
           ===================================================== */

        INSERT INTO dbo.Parentesco
        (
            id,
            Nombre
        )
        SELECT
            X.Nodo.value('@Id', 'INT'),
            X.Nodo.value('@Nombre', 'VARCHAR(32)')
        FROM @Datos.nodes
        (
            '/Catalogos/Parentezcos/Parentezco'
        ) AS X(Nodo)
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Parentesco P
            WHERE P.id =
                X.Nodo.value('@Id', 'INT')
        );


        /* =====================================================
           ACTUALIZAR TIPOS DE CUENTA EXISTENTES
           ===================================================== */

        UPDATE TCA
        SET
            TCA.Nombre =
                X.Nodo.value('@Nombre', 'VARCHAR(32)'),

            TCA.idTipoMoneda =
                X.Nodo.value('@IdTipoMoneda', 'INT'),

            TCA.SaldoMinimo =
                X.Nodo.value('@SaldoMinimo', 'MONEY'),

            TCA.MultaSaldoMin =
                X.Nodo.value('@MultaSaldoMin', 'MONEY'),

            TCA.CargoAnual =
                X.Nodo.value('@CargoMensual', 'MONEY'),

            TCA.NumRetirosHumano =
                X.Nodo.value('@NumRetirosHumano', 'INT'),

            TCA.NumRetirosAutomatico =
                X.Nodo.value('@NumRetirosAutomatico', 'INT'),

            TCA.ComisionHumano =
                X.Nodo.value('@ComisionHumano', 'MONEY'),

            TCA.ComisionAutomatico =
                X.Nodo.value('@ComisionAutomatico', 'MONEY'),

            TCA.Interes =
                X.Nodo.value
                (
                    '@TasaInteresAnual',
                    'DECIMAL(5,2)'
                ),

            TCA.CargoMensual =
                X.Nodo.value('@CargoMensual', 'MONEY'),

            TCA.MontoMaxSinpeDiario =
                X.Nodo.value('@MontoMaxSinpeDiario', 'MONEY'),

            TCA.ComisionSinpe =
                X.Nodo.value('@ComisionSinpe', 'MONEY'),

            TCA.TasaInteresAnual =
                X.Nodo.value
                (
                    '@TasaInteresAnual',
                    'DECIMAL(5,2)'
                )

        FROM dbo.TipoCuentaAhorro TCA

        CROSS APPLY @Datos.nodes
        (
            '/Catalogos/Tipo_Cuenta_Ahorros/TipoCuentaAhorro'
        ) AS X(Nodo)

        WHERE TCA.id =
            X.Nodo.value('@Id', 'INT');


        /* =====================================================
           INSERTAR TIPOS DE CUENTA NUEVOS
           ===================================================== */

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
            Interes,
            CargoMensual,
            MontoMaxSinpeDiario,
            ComisionSinpe,
            TasaInteresAnual
        )
        SELECT
            X.Nodo.value('@Id', 'INT'),
            X.Nodo.value('@Nombre', 'VARCHAR(32)'),
            X.Nodo.value('@IdTipoMoneda', 'INT'),
            X.Nodo.value('@SaldoMinimo', 'MONEY'),
            X.Nodo.value('@MultaSaldoMin', 'MONEY'),

            /* Campos heredados */
            X.Nodo.value('@CargoMensual', 'MONEY'),

            X.Nodo.value('@NumRetirosHumano', 'INT'),
            X.Nodo.value('@NumRetirosAutomatico', 'INT'),
            X.Nodo.value('@ComisionHumano', 'MONEY'),
            X.Nodo.value('@ComisionAutomatico', 'MONEY'),

            X.Nodo.value
            (
                '@TasaInteresAnual',
                'DECIMAL(5,2)'
            ),

            /* Campos TP3 */
            X.Nodo.value('@CargoMensual', 'MONEY'),
            X.Nodo.value('@MontoMaxSinpeDiario', 'MONEY'),
            X.Nodo.value('@ComisionSinpe', 'MONEY'),
            X.Nodo.value
            (
                '@TasaInteresAnual',
                'DECIMAL(5,2)'
            )

        FROM @Datos.nodes
        (
            '/Catalogos/Tipo_Cuenta_Ahorros/TipoCuentaAhorro'
        ) AS X(Nodo)

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.TipoCuentaAhorro TCA
            WHERE TCA.id =
                X.Nodo.value('@Id', 'INT')
        );


        /* =====================================================
           INSERTAR TIPOS DE MOVIMIENTO NUEVOS
           ===================================================== */

        INSERT INTO dbo.TipoMovimiento
        (
            id,
            Nombre,
            TipoAccion,
            FlagGeneraComprobante
        )
        SELECT
            X.Nodo.value('@Id', 'INT'),
            X.Nodo.value('@Nombre', 'VARCHAR(64)'),

            UPPER
            (
                X.Nodo.value('@Accion', 'VARCHAR(8)')
            ),

            X.Nodo.value
            (
                '@flagGeneraComprobante',
                'BIT'
            )

        FROM @Datos.nodes
        (
            '/Catalogos/Tipos_Movimiento/TipoMovimiento'
        ) AS X(Nodo)

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.TipoMovimiento TM
            WHERE TM.id =
                X.Nodo.value('@Id', 'INT')
        );


        /* =====================================================
           ACTUALIZAR TIPOS DE MOVIMIENTO EXISTENTES
           ===================================================== */

        UPDATE TM
        SET
            TM.Nombre =
                X.Nodo.value('@Nombre', 'VARCHAR(64)'),

            TM.TipoAccion =
                UPPER
                (
                    X.Nodo.value('@Accion', 'VARCHAR(8)')
                ),

            TM.FlagGeneraComprobante =
                X.Nodo.value
                (
                    '@flagGeneraComprobante',
                    'BIT'
                )

        FROM dbo.TipoMovimiento TM

        CROSS APPLY @Datos.nodes
        (
            '/Catalogos/Tipos_Movimiento/TipoMovimiento'
        ) AS X(Nodo)

        WHERE TM.id =
            X.Nodo.value('@Id', 'INT');


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
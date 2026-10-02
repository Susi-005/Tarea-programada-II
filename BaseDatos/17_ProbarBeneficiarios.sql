USE TareaProgramada2;
GO

BEGIN TRANSACTION;

DECLARE @idCuenta INT;
DECLARE @Resultado INT;

/* Busca la cuenta cargada desde el XML. */
SELECT @idCuenta = id
FROM dbo.Cuenta
WHERE NumeroCuenta = '11000001';


/* =====================================================
   PRUEBA 1: INSERTAR PRIMER BENEFICIARIO
   ===================================================== */

EXEC dbo.InsertarBeneficiario
    @idCuenta = @idCuenta,
    @Nombre = 'Ana Prueba',
    @ValorDocumentoIdentidad = '900000001',
    @FechaNacimiento = '1990-01-10',
    @Email = 'ana@prueba.com',
    @Telefono1 = '80000001',
    @Telefono2 = '80000002',
    @idParentesco = 5,
    @Porcentaje = 30,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoBeneficiario1;


/* =====================================================
   PRUEBA 2: INSERTAR SEGUNDO BENEFICIARIO
   ===================================================== */

EXEC dbo.InsertarBeneficiario
    @idCuenta = @idCuenta,
    @Nombre = 'Carlos Prueba',
    @ValorDocumentoIdentidad = '900000002',
    @FechaNacimiento = '1991-02-15',
    @Email = 'carlos@prueba.com',
    @Telefono1 = '80000003',
    @Telefono2 = '80000004',
    @idParentesco = 3,
    @Porcentaje = 30,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoBeneficiario2;


/* =====================================================
   PRUEBA 3: INSERTAR TERCER BENEFICIARIO
   ===================================================== */

EXEC dbo.InsertarBeneficiario
    @idCuenta = @idCuenta,
    @Nombre = 'Maria Prueba',
    @ValorDocumentoIdentidad = '900000003',
    @FechaNacimiento = '1992-03-20',
    @Email = 'maria@prueba.com',
    @Telefono1 = '80000005',
    @Telefono2 = '80000006',
    @idParentesco = 4,
    @Porcentaje = 40,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoBeneficiario3;


/* =====================================================
   PRUEBA 4: INTENTAR INSERTAR UN CUARTO BENEFICIARIO
   ===================================================== */

EXEC dbo.InsertarBeneficiario
    @idCuenta = @idCuenta,
    @Nombre = 'Luis Prueba',
    @ValorDocumentoIdentidad = '900000004',
    @FechaNacimiento = '1993-04-25',
    @Email = 'luis@prueba.com',
    @Telefono1 = '80000007',
    @Telefono2 = '80000008',
    @idParentesco = 7,
    @Porcentaje = 10,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoBeneficiario4;


/* =====================================================
   PRUEBA DEL LISTADO
   ===================================================== */

DECLARE @ResultadoLista INT;

EXEC dbo.ListarBeneficiarios
    @idCuenta = @idCuenta,
    @outResultCode = @ResultadoLista OUTPUT;

SELECT @ResultadoLista AS ResultadoListado;


/* Elimina todos los cambios realizados durante esta prueba. */
ROLLBACK TRANSACTION;
GO
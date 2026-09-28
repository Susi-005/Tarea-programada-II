USE TareaProgramada2;
GO

BEGIN TRANSACTION;

DECLARE @idCuenta INT;
DECLARE @Resultado INT;
DECLARE @SumaPorcentajes INT;
DECLARE @idBeneficiario3 INT;

/* Busca la cuenta cargada desde el XML. */
SELECT @idCuenta = id
FROM dbo.Cuenta
WHERE NumeroCuenta = '11000001';


/* =====================================================
   PASO 1: INSERTAR TRES BENEFICIARIOS
   30 + 30 + 40 = 100
   ===================================================== */

EXEC dbo.InsertarBeneficiario
    @idCuenta = @idCuenta,
    @Nombre = 'Ana Prueba',
    @ValorDocumentoIdentidad = '900000021',
    @FechaNacimiento = '1990-01-10',
    @Email = 'ana28@prueba.com',
    @Telefono1 = '81000001',
    @Telefono2 = '81000002',
    @idParentesco = 5,
    @Porcentaje = 30,
    @outResultCode = @Resultado OUTPUT;

EXEC dbo.InsertarBeneficiario
    @idCuenta = @idCuenta,
    @Nombre = 'Carlos Prueba',
    @ValorDocumentoIdentidad = '900000022',
    @FechaNacimiento = '1991-02-15',
    @Email = 'carlos28@prueba.com',
    @Telefono1 = '81000003',
    @Telefono2 = '81000004',
    @idParentesco = 3,
    @Porcentaje = 30,
    @outResultCode = @Resultado OUTPUT;

EXEC dbo.InsertarBeneficiario
    @idCuenta = @idCuenta,
    @Nombre = 'Maria Prueba',
    @ValorDocumentoIdentidad = '900000023',
    @FechaNacimiento = '1992-03-20',
    @Email = 'maria28@prueba.com',
    @Telefono1 = '81000005',
    @Telefono2 = '81000006',
    @idParentesco = 4,
    @Porcentaje = 40,
    @outResultCode = @Resultado OUTPUT;


/* =====================================================
   PASO 2: CONSULTAR SUMA
   ESPERADO = 100
   ===================================================== */

EXEC dbo.CalcularPorcentajeBeneficiarios
    @idCuenta = @idCuenta,
    @outSumaPorcentajes = @SumaPorcentajes OUTPUT,
    @outResultCode = @Resultado OUTPUT;

SELECT
    @SumaPorcentajes AS SumaEsperada100,
    @Resultado AS ResultadoConsulta1;


/* =====================================================
   PASO 3: CAMBIAR EL TERCER BENEFICIARIO
   DE 40 A 10
   NUEVA SUMA = 70
   ===================================================== */

SELECT @idBeneficiario3 = B.id
FROM dbo.Beneficiario AS B
INNER JOIN dbo.Persona AS P
    ON P.id = B.idPersona
WHERE P.ValorDocumentoIdentidad = '900000023'
  AND B.idCuenta = @idCuenta;

EXEC dbo.ActualizarBeneficiario
    @idBeneficiario = @idBeneficiario3,
    @Nombre = 'Maria Prueba',
    @ValorDocumentoIdentidad = '900000023',
    @FechaNacimiento = '1992-03-20',
    @Email = 'maria28@prueba.com',
    @Telefono1 = '81000005',
    @Telefono2 = '81000006',
    @idParentesco = 4,
    @Porcentaje = 10,
    @outResultCode = @Resultado OUTPUT;


/* Consulta nuevamente. */

EXEC dbo.CalcularPorcentajeBeneficiarios
    @idCuenta = @idCuenta,
    @outSumaPorcentajes = @SumaPorcentajes OUTPUT,
    @outResultCode = @Resultado OUTPUT;

SELECT
    @SumaPorcentajes AS SumaEsperada70,
    @Resultado AS ResultadoConsulta2;


/* =====================================================
   PASO 4: ELIMINAR LOGICAMENTE A MARIA
   QUEDAN 30 + 30 = 60
   ===================================================== */

EXEC dbo.EliminarBeneficiario
    @idBeneficiario = @idBeneficiario3,
    @outResultCode = @Resultado OUTPUT;


/* Consulta nuevamente. */

EXEC dbo.CalcularPorcentajeBeneficiarios
    @idCuenta = @idCuenta,
    @outSumaPorcentajes = @SumaPorcentajes OUTPUT,
    @outResultCode = @Resultado OUTPUT;

SELECT
    @SumaPorcentajes AS SumaEsperada60,
    @Resultado AS ResultadoConsulta3;


/* Limpia todos los datos utilizados en la prueba. */
ROLLBACK TRANSACTION;
GO
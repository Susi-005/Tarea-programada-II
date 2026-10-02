USE TareaProgramada2;
GO

BEGIN TRANSACTION;

DECLARE @idCuenta INT;
DECLARE @Resultado INT;
DECLARE @idBeneficiario INT;

/* Busca la cuenta de prueba */
SELECT @idCuenta = id
FROM dbo.Cuenta
WHERE NumeroCuenta = '11000001';


/* =====================================================
   PASO 1: CREAR BENEFICIARIO DE PRUEBA
   ===================================================== */

EXEC dbo.InsertarBeneficiario
    @idCuenta = @idCuenta,
    @Nombre = 'Pedro Prueba',
    @ValorDocumentoIdentidad = '900000010',
    @FechaNacimiento = '1990-05-10',
    @Email = 'pedro@prueba.com',
    @Telefono1 = '81111111',
    @Telefono2 = '82222222',
    @idParentesco = 5,
    @Porcentaje = 25,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoInsercion;


/* Busca el id del beneficiario recién creado */
SELECT @idBeneficiario = B.id
FROM dbo.Beneficiario AS B
INNER JOIN dbo.Persona AS P
    ON P.id = B.idPersona
WHERE P.ValorDocumentoIdentidad = '900000010'
  AND B.idCuenta = @idCuenta;


/* =====================================================
   PASO 2: ACTUALIZAR BENEFICIARIO
   ===================================================== */

EXEC dbo.ActualizarBeneficiario
    @idBeneficiario = @idBeneficiario,
    @Nombre = 'Pedro Actualizado',
    @ValorDocumentoIdentidad = '900000010',
    @FechaNacimiento = '1990-05-10',
    @Email = 'pedroactualizado@prueba.com',
    @Telefono1 = '83333333',
    @Telefono2 = '84444444',
    @idParentesco = 3,
    @Porcentaje = 40,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoActualizacion;


/* Verifica cómo quedó después de actualizar */
SELECT
    B.id,
    P.Nombre,
    P.ValorDocumentoIdentidad,
    P.FechaNacimiento,
    P.Email,
    PA.Nombre AS Parentesco,
    B.Porcentaje,
    B.Enabled,
    B.FechaDesactivacion
FROM dbo.Beneficiario AS B
INNER JOIN dbo.Persona AS P
    ON P.id = B.idPersona
INNER JOIN dbo.Parentesco AS PA
    ON PA.id = B.idParentesco
WHERE B.id = @idBeneficiario;


/* =====================================================
   PASO 3: ELIMINACIÓN LÓGICA
   ===================================================== */

EXEC dbo.EliminarBeneficiario
    @idBeneficiario = @idBeneficiario,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoEliminacion;


/* Verifica que NO se borró físicamente */
SELECT
    id,
    Enabled,
    FechaDesactivacion
FROM dbo.Beneficiario
WHERE id = @idBeneficiario;


/* =====================================================
   PASO 4: PROBAR LISTADO
   ===================================================== */

DECLARE @ResultadoListado INT;

EXEC dbo.ListarBeneficiarios
    @idCuenta = @idCuenta,
    @outResultCode = @ResultadoListado OUTPUT;

SELECT @ResultadoListado AS ResultadoListado;


/* Limpia todos los datos de prueba */
ROLLBACK TRANSACTION;
GO
USE TareaProgramada2;
GO

BEGIN TRANSACTION;

DECLARE @idUsuario INT;
DECLARE @Resultado INT;

/* Busca el usuario jaguero */
SELECT @idUsuario = id
FROM dbo.Usuario
WHERE NombreUsuario = 'jaguero';


/* =====================================================
   PRUEBA 1: LOGIN
   TipoOperacion = 1
   ===================================================== */

EXEC dbo.RegistrarBitacora
    @idUsuario = @idUsuario,
    @idTipoOperacion = 1,
    @IP = '127.0.0.1',
    @DatosAntes = NULL,
    @DatosDespues = NULL,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoLogin;


/* =====================================================
   PRUEBA 2: LOGOUT
   TipoOperacion = 2
   ===================================================== */

EXEC dbo.RegistrarBitacora
    @idUsuario = @idUsuario,
    @idTipoOperacion = 2,
    @IP = '127.0.0.1',
    @DatosAntes = NULL,
    @DatosDespues = NULL,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoLogout;


/* =====================================================
   PRUEBA 3: AGREGAR BENEFICIARIO
   TipoOperacion = 3
   ===================================================== */

EXEC dbo.RegistrarBitacora
    @idUsuario = @idUsuario,
    @idTipoOperacion = 3,
    @IP = '127.0.0.1',
    @DatosAntes = NULL,
    @DatosDespues =
        '{"Nombre":"Ana Prueba","Parentesco":"Hermana","Porcentaje":30}',
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoAgregarBeneficiario;


/* =====================================================
   PRUEBA 4: ACTUALIZAR BENEFICIARIO
   TipoOperacion = 4
   ===================================================== */

EXEC dbo.RegistrarBitacora
    @idUsuario = @idUsuario,
    @idTipoOperacion = 4,
    @IP = '127.0.0.1',
    @DatosAntes =
        '{"Nombre":"Ana Prueba","Parentesco":"Hermana","Porcentaje":30}',
    @DatosDespues =
        '{"Nombre":"Ana Actualizada","Parentesco":"Hermana","Porcentaje":40}',
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoActualizarBeneficiario;


/* =====================================================
   PRUEBA 5: ELIMINAR BENEFICIARIO
   TipoOperacion = 5
   ===================================================== */

EXEC dbo.RegistrarBitacora
    @idUsuario = @idUsuario,
    @idTipoOperacion = 5,
    @IP = '127.0.0.1',
    @DatosAntes =
        '{"Nombre":"Ana Actualizada","Parentesco":"Hermana","Porcentaje":40,"Enabled":1}',
    @DatosDespues =
        '{"Nombre":"Ana Actualizada","Parentesco":"Hermana","Porcentaje":40,"Enabled":0}',
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoEliminarBeneficiario;


/* =====================================================
   PRUEBA 6: CONSULTAR ESTADO DE CUENTA
   TipoOperacion = 7
   ===================================================== */

EXEC dbo.RegistrarBitacora
    @idUsuario = @idUsuario,
    @idTipoOperacion = 7,
    @IP = '127.0.0.1',
    @DatosAntes = NULL,
    @DatosDespues = NULL,
    @outResultCode = @Resultado OUTPUT;

SELECT @Resultado AS ResultadoConsultaEstado;


/* =====================================================
   VERIFICAR LOS REGISTROS
   ===================================================== */

SELECT
    B.id,
    U.NombreUsuario,
    TOPE.Nombre AS TipoOperacion,
    B.IP,
    B.FechaHora,
    B.DatosAntes,
    B.DatosDespues
FROM dbo.Bitacora AS B

INNER JOIN dbo.Usuario AS U
    ON U.id = B.idUsuario

INNER JOIN dbo.TipoOperacion AS TOPE
    ON TOPE.id = B.idTipoOperacion

WHERE B.idUsuario = @idUsuario

ORDER BY B.id DESC;


/* Limpia los datos de prueba */
ROLLBACK TRANSACTION;
GO
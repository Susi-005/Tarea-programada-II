import pyodbc
from flask import current_app, session
import json

def conectar():
    c = current_app.config
    cadena = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={c['DB_SERVER']};DATABASE={c['DB_NAME']};"
        f"UID={c['DB_USER']};PWD={c['DB_PASSWORD']};"
        "TrustServerCertificate=yes;"
    )
    if c["DB_USER"]:
        cadena += f"UID={c['DB_USER']};PWD={c['DB_PASSWORD']};"
    else:
        cadena += "Trusted_Connection=yes;"
    return pyodbc.connect(cadena)

def ejecutar_sp(nombre, params=()):
    """Ejecuta dbo.<nombre> y devuelve (codigo_resultado, filas)."""
    marcadores = "".join("?, " for _ in params)
    sql = (
        "SET NOCOUNT ON; DECLARE @rc INT; "
        f"EXEC dbo.{nombre} {marcadores}@outResultCode = @rc OUTPUT; "
        "SELECT @rc AS ResultCode;"
    )
    conn = conectar()
    try:
        cursor = conn.cursor()
        cursor.execute(sql, params)
        conjuntos = []
        while True:
            if cursor.description:
                columnas = [col[0] for col in cursor.description]
                conjuntos.append([dict(zip(columnas, f)) for f in cursor.fetchall()])
            if not cursor.nextset():
                break
        conn.commit()
        codigo = conjuntos.pop()[0]["ResultCode"]
        filas = conjuntos[0] if conjuntos else []
        return codigo, filas
    finally:
        conn.close()

# Tipos de operación (catálogo TipoOperacion)
LOGIN, LOGOUT = 1, 2
AGREGAR_BENEF, ACTUALIZAR_BENEF, ELIMINAR_BENEF, ACTUALIZAR_PORCENTAJE = 3, 4, 5, 6
CONSULTAR_ESTADOS = 7


def registrar_bitacora(id_tipo, ip=None, antes=None, despues=None):
    """Registra un evento en la bitácora. Si falla, no detiene la aplicación."""
    def a_json(d):
        return json.dumps(d, ensure_ascii=False, default=str) if d else None
    try:
        ejecutar_sp("RegistrarBitacora", (
            session["id_usuario"], id_tipo, ip, a_json(antes), a_json(despues)
        ))
    except Exception as e:
        print("ERROR BITACORA:", e)
import pyodbc
from flask import current_app

def conectar():
    c = current_app.config
    cadena = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={c['DB_SERVER']};DATABASE={c['DB_NAME']};"
        f"UID={c['DB_USER']};PWD={c['DB_PASSWORD']};"
        "TrustServerCertificate=yes;"
    )
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
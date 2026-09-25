import pyodbc
from flask import current_app

def conectar():
    c = current_app.config
    cadena = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={c['100.94.199.34,1433']};DATABASE={c['Tarea programada II']};"
        f"UID={c['Luis Aguilar']};PWD={c['TareaProgramada2']};"
        "TrustServerCertificate=yes;"
    )
    return pyodbc.connect(cadena)

def ejecutar_sp(nombre, params=()):
    if current_app.config["MODO_SIN_BD"]:
        return _simular(nombre, params)

    marcadores = ", ".join("?" for _ in params)
    conn = conectar()
    try:
        cursor = conn.cursor()
        cursor.execute(f"EXEC {nombre} {marcadores}", params)
        while cursor.description is None and cursor.nextset():
            pass
        filas = []
        if cursor.description:
            columnas = [col[0] for col in cursor.description]
            filas = [dict(zip(columnas, f)) for f in cursor.fetchall()]
        conn.commit()
        return filas
    finally:
        conn.close()


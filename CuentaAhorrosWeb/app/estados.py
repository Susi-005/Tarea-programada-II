from flask import Blueprint, render_template, redirect, url_for, session, flash, request
from app.db import ejecutar_sp, registrar_bitacora, CONSULTAR_ESTADOS

estados_bp = Blueprint("estados", __name__)


@estados_bp.route("/estados")
def listar():
    if "id_cuenta" not in session:
        return redirect(url_for("inicio"))

    codigo, estados = ejecutar_sp("ListarEstadosCuenta", (session["id_cuenta"],))
    if codigo != 0:
        flash("No se pudieron consultar los estados de cuenta.", "error")
        estados = []

    registrar_bitacora(CONSULTAR_ESTADOS, ip=request.remote_addr)
    return render_template("EstadosCuenta.html", estados=estados,
                           cuenta=session.get("cuenta"))


@estados_bp.route("/estados/<int:id_estado>")
def detalle(id_estado):
    if "id_cuenta" not in session:
        return redirect(url_for("inicio"))

    # Día 9: encabezado del estado. Día 10: movimientos.
    return f"Detalle del estado de cuenta {id_estado} (en construcción)"
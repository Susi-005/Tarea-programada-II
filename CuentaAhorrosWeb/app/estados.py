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

    codigo, filas = ejecutar_sp("ObtenerEstadoCuenta", (id_estado, session["id_cuenta"]))
    if codigo != 0 or not filas:
        flash("El estado de cuenta no existe o no pertenece a su cuenta.", "error")
        return redirect(url_for("estados.listar"))

    codigo, movimientos = ejecutar_sp("ListarMovimientosEstado",
                                    (id_estado, session["id_cuenta"]))
    if codigo != 0:
        flash("No se pudieron consultar los movimientos.", "error")
        movimientos = []
    return render_template("DetalleEstado.html", estado=filas[0], movimientos=movimientos)
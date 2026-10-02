from flask import Blueprint, render_template, redirect, url_for, session, flash, request
from app.db import ejecutar_sp, registrar_bitacora, CONSULTAR_ESTADOS

estados_bp = Blueprint("estados", __name__)

@estados_bp.route("/estados")
def listar():
    if "id_cuenta" not in session:
        return redirect(url_for("inicio"))

    codigo, estados = ejecutar_sp("ConsultarUltimos8EstadosCuenta", (session["id_cuenta"],))
    if codigo != 0:
        flash("No se pudieron consultar los estados de cuenta.", "error")
        estados = []

    registrar_bitacora(CONSULTAR_ESTADOS, ip=request.remote_addr)
    return render_template("EstadosCuenta.html", estados=estados)


from flask import Blueprint, render_template, redirect, url_for, session, flash
from app.db import ejecutar_sp

cuentas_bp = Blueprint("cuentas", __name__)


def obtener_cuentas():
    codigo, cuentas = ejecutar_sp("ListarCuentasUsuario", (session["id_usuario"],))
    return cuentas if codigo == 0 else None


def guardar_cuenta(c, varias):
    session["id_cuenta"] = c["IdCuenta"]
    session["cuenta"] = {
        "NumeroCuenta": c["NumeroCuenta"],
        "TipoCuenta": c["TipoCuenta"],
        "Moneda": c["Moneda"],
    }
    session["varias_cuentas"] = varias


@cuentas_bp.route("/cuentas")
def seleccionar():
    if "id_usuario" not in session:
        return redirect(url_for("auth.login"))

    cuentas = obtener_cuentas()
    if cuentas is None:
        flash("No se pudieron consultar sus cuentas.", "error")
        cuentas = []

    # Con una sola cuenta no hace falta elegir
    if len(cuentas) == 1:
        guardar_cuenta(cuentas[0], varias=False)
        return redirect(url_for("inicio"))

    return render_template("SeleccionCuenta.html", cuentas=cuentas)


@cuentas_bp.route("/cuentas/<int:id_cuenta>")
def elegir(id_cuenta):
    if "id_usuario" not in session:
        return redirect(url_for("auth.login"))

    cuentas = obtener_cuentas() or []
    elegida = next((c for c in cuentas if c["IdCuenta"] == id_cuenta), None)

    if not elegida:
        flash("No tiene acceso a esa cuenta.", "error")
        return redirect(url_for("cuentas.seleccionar"))

    guardar_cuenta(elegida, varias=len(cuentas) > 1)
    return redirect(url_for("inicio"))
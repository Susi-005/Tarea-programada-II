from flask import Blueprint, render_template, redirect, url_for, session, flash
from app.db import ejecutar_sp

cuentas_bp = Blueprint("cuentas", __name__)


@cuentas_bp.route("/cuentas")
def seleccionar():
    if "id_usuario" not in session:
        return redirect(url_for("auth.login"))

    return "Selección de cuenta (en construcción)"
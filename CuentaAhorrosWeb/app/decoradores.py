from functools import wraps
from flask import session, redirect, url_for, flash


def login_requerido(f):
    """La página exige haber iniciado sesión."""
    @wraps(f)
    def envoltura(*args, **kwargs):
        if "id_usuario" not in session:
            flash("Debe iniciar sesión para continuar.")
            return redirect(url_for("auth.login"))
        return f(*args, **kwargs)
    return envoltura


def cuenta_requerida(f):
    """La página exige sesión de cliente y una cuenta seleccionada."""
    @wraps(f)
    def envoltura(*args, **kwargs):
        if "id_usuario" not in session:
            flash("Debe iniciar sesión para continuar.")
            return redirect(url_for("auth.login"))
        if session.get("es_admin"):
            return redirect(url_for("inicio"))
        if "id_cuenta" not in session:
            flash("Seleccione una cuenta para continuar.", "error")
            return redirect(url_for("cuentas.seleccionar"))
        return f(*args, **kwargs)
    return envoltura
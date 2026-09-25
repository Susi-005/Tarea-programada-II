from flask import (Blueprint, render_template, request,
                   redirect, url_for, session, flash)
from app.db import ejecutar_sp

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        usuario = request.form.get("usuario", "").strip()
        password = request.form.get("password", "")

        if not usuario or not password:
            flash("Debe ingresar usuario y contraseña.")
            return render_template("login.html", usuario=usuario)

        try:
            filas = ejecutar_sp("SP_Login", (usuario, password, request.remote_addr))
        except Exception:
            flash("No se pudo conectar con la base de datos.")
            return render_template("login.html", usuario=usuario)

        fila = filas[0] if filas else None
        if fila and fila["ResultCode"] == 0:
            session.clear()
            session["id_usuario"] = fila["IdUsuario"]
            session["usuario"] = usuario
            session["es_admin"] = bool(fila["EsAdministrador"])
            return redirect(url_for("inicio"))

        flash("Usuario o contraseña incorrectos.")
        return render_template("login.html", usuario=usuario)

    return render_template("login.html")

@auth_bp.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("auth.login"))
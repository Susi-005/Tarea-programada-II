import pyodbc
from flask import Flask, session, redirect, url_for, render_template
from config import Config
from app.db import ejecutar_sp
from app.cuentas import cuentas_bp

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    from app.auth import auth_bp
    from app.beneficiarios import benef_bp
    from app.estados import estados_bp
    from app.decoradores import login_requerido
    app.register_blueprint(estados_bp)
    app.register_blueprint(benef_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(cuentas_bp)

    @app.route("/")
    @login_requerido
    def inicio():
        if session.get("es_admin"):
            return render_template("MenuPrincipalAdmin.html")

        if "id_cuenta" not in session:
            return redirect(url_for("cuentas.seleccionar"))

        _, beneficiarios = ejecutar_sp("ListarBeneficiarios", (session["id_cuenta"],))
        alerta_porcentajes = sum(b["Porcentaje"] for b in beneficiarios) != 100

        return render_template("MenuPrincipalUsuario.html",
                               cuenta=session.get("cuenta"),
                               alerta_porcentajes=alerta_porcentajes)

    @app.errorhandler(pyodbc.Error)
    def error_bd(e):
        print("ERROR BD:", e)
        return render_template("Error.html",
                               mensaje="No se pudo conectar con la base de datos. Intente de nuevo más tarde."), 500

    @app.errorhandler(404)
    def no_encontrada(e):
        return render_template("Error.html",
                               mensaje="La página que busca no existe."), 404

    return app
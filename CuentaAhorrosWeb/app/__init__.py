from flask import Flask, session, redirect, url_for, render_template
from config import Config
from app.db import ejecutar_sp

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    from app.auth import auth_bp
    from app.beneficiarios import benef_bp
    app.register_blueprint(benef_bp)
    app.register_blueprint(auth_bp)

    @app.route("/")
    def inicio():
        if "id_usuario" not in session:
            return redirect(url_for("auth.login"))

        if session.get("es_admin"):
            return render_template("MenuPrincipalAdmin.html")

        codigo, filas = ejecutar_sp("ObtenerCuentaUsuario", (session["id_usuario"],))
        cuenta = filas[0] if codigo == 0 and filas else None
        if cuenta:
            session["id_cuenta"] = cuenta["IdCuenta"]

        alerta_porcentajes = False
        return render_template("MenuPrincipalUsuario.html",
                               cuenta=cuenta,
                               alerta_porcentajes=alerta_porcentajes)

    return app

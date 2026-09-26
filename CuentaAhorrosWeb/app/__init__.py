from flask import Flask, session, redirect, url_for, render_template
from config import Config

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    from app.auth import auth_bp
    app.register_blueprint(auth_bp)

    @app.route("/")
    def inicio():
        if "id_usuario" not in session:
            return redirect(url_for("auth.login"))

        if session.get("es_admin"):
            return render_template("MenuPrincipalAdmin.html")

        cuenta = None               # se llena con el SP de cuentas
        alerta_porcentajes = False  
        return render_template("MenuPrincipalUsuario.html",
                               cuenta=cuenta,
                               alerta_porcentajes=alerta_porcentajes)

    return app
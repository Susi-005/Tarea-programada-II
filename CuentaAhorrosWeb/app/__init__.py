from flask import Flask, session, redirect, url_for
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
        return f"Bienvenido, {session['usuario']} | <a href='{url_for('auth.logout')}'>Cerrar sesión</a>"

    return app
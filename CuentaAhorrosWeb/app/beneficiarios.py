import re
from datetime import date
from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.db import ejecutar_sp

benef_bp = Blueprint("beneficiarios", __name__)

MENSAJES_INSERTAR = {
    1: "La cuenta no existe.",
    2: "El porcentaje debe estar entre 0 y 100.",
    3: "La cuenta ya tiene 3 beneficiarios activos.",
    4: "El parentesco no es válido.",
}

CAMPOS = ("nombre", "documento", "fecha", "email",
          "telefono1", "telefono2", "parentesco", "porcentaje")


def validar(d):
    errores = []
    if not d["nombre"] or len(d["nombre"]) > 40:
        errores.append("El nombre es obligatorio y debe tener máximo 40 caracteres.")
    if not d["documento"].isdigit() or len(d["documento"]) > 20:
        errores.append("El documento debe ser numérico y de máximo 20 dígitos.")
    try:
        if date.fromisoformat(d["fecha"]) > date.today():
            errores.append("La fecha de nacimiento no puede ser futura.")
    except ValueError:
        errores.append("La fecha de nacimiento no es válida.")
    if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", d["email"]):
        errores.append("El email no es válido.")
    if not all(d[t].isdigit() and 8 <= len(d[t]) <= 16 for t in ("telefono1", "telefono2")):
        errores.append("Los dos teléfonos deben ser numéricos, de 8 a 16 dígitos.")
    if not d["parentesco"].isdigit():
        errores.append("Seleccione un parentesco.")
    if not d["porcentaje"].isdigit() or not 1 <= int(d["porcentaje"]) <= 100:
        errores.append("El porcentaje debe ser un número entero entre 1 y 100.")
    return errores


def pantalla(datos=None):
    _, beneficiarios = ejecutar_sp("ListarBeneficiarios", (session["id_cuenta"],))
    _, parentescos = ejecutar_sp("ListarParentescos")
    suma = sum(b["Porcentaje"] for b in beneficiarios)
    return render_template("Beneficiarios.html", beneficiarios=beneficiarios,
                           parentescos=parentescos, suma=suma, datos=datos or {})


@benef_bp.route("/beneficiarios")
def listar():
    if "id_cuenta" not in session:
        return redirect(url_for("inicio"))
    return pantalla()


@benef_bp.route("/beneficiarios/agregar", methods=["POST"])
def agregar():
    if "id_cuenta" not in session:
        return redirect(url_for("inicio"))

    datos = {c: request.form.get(c, "").strip() for c in CAMPOS}
    errores = validar(datos)
    if errores:
        for e in errores:
            flash(e, "error")
        return pantalla(datos)

    codigo, _ = ejecutar_sp("InsertarBeneficiario", (
        session["id_cuenta"], datos["nombre"], datos["documento"], datos["fecha"],
        datos["email"], datos["telefono1"], datos["telefono2"],
        int(datos["parentesco"]), int(datos["porcentaje"]),
    ))

    if codigo == 0:
        flash("Beneficiario agregado correctamente.", "ok")
        return redirect(url_for("beneficiarios.listar"))

    flash(MENSAJES_INSERTAR.get(codigo, f"Error de base de datos ({codigo})."), "error")
    return pantalla(datos)
import re
from datetime import date
from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.db import (ejecutar_sp, registrar_bitacora,
                    AGREGAR_BENEF, ACTUALIZAR_BENEF, ELIMINAR_BENEF, ACTUALIZAR_PORCENTAJE)

benef_bp = Blueprint("beneficiarios", __name__)

MENSAJES_INSERTAR = {
    1: "La cuenta no existe.",
    2: "El porcentaje debe estar entre 0 y 100.",
    3: "La cuenta ya tiene 3 beneficiarios activos.",
    4: "El parentesco no es válido.",
}

MENSAJES_ACTUALIZAR = {
    1: "El beneficiario no existe o ya fue eliminado.",
    2: "El porcentaje debe estar entre 0 y 100.",
    3: "El parentesco no es válido.",
    4: "Ese documento ya pertenece a otra persona.",
}

MENSAJES_ELIMINAR = {
    1: "El beneficiario no existe.",
    2: "El beneficiario ya estaba eliminado.",
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


def pantalla(datos=None, editando=None):
    _, beneficiarios = ejecutar_sp("ListarBeneficiarios", (session["id_cuenta"],))
    _, parentescos = ejecutar_sp("ListarParentescos")
    suma = sum(b["Porcentaje"] for b in beneficiarios)
    return render_template("Beneficiarios.html", beneficiarios=beneficiarios,
                           parentescos=parentescos, suma=suma,
                           datos=datos or {}, editando=editando)


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

def obtener(id_benef):
    """Devuelve el beneficiario solo si pertenece a la cuenta del usuario."""
    codigo, filas = ejecutar_sp("ObtenerBeneficiario", (id_benef, session["id_cuenta"]))
    return filas[0] if codigo == 0 and filas else None

def a_formulario(actual):
    return {
        "nombre": actual["Nombre"],
        "documento": actual["ValorDocumentoIdentidad"],
        "fecha": str(actual["FechaNacimiento"]),
        "email": actual["Email"],
        "telefono1": actual["Telefono1"] or "",
        "telefono2": actual["Telefono2"] or "",
        "parentesco": str(actual["idParentesco"]),
        "porcentaje": str(actual["Porcentaje"]),
    }

@benef_bp.route("/beneficiarios/<int:id_benef>/editar", methods=["GET", "POST"])
def editar(id_benef):
    if "id_cuenta" not in session:
        return redirect(url_for("inicio"))

    actual = obtener(id_benef)
    if not actual:
        flash("El beneficiario no existe o no pertenece a su cuenta.", "error")
        return redirect(url_for("beneficiarios.listar"))

    antes = a_formulario(actual)

    if request.method == "GET":
        return pantalla(antes, editando=id_benef)

    datos = {c: request.form.get(c, "").strip() for c in CAMPOS}
    errores = validar(datos)
    if errores:
        for e in errores:
            flash(e, "error")
        return pantalla(datos, editando=id_benef)

    codigo, _ = ejecutar_sp("ActualizarBeneficiario", (
        id_benef, datos["nombre"], datos["documento"], datos["fecha"],
        datos["email"], datos["telefono1"], datos["telefono2"],
        int(datos["parentesco"]), int(datos["porcentaje"]),
    ))

    if codigo == 0:
        cambios = [c for c in CAMPOS if antes[c] != datos[c]]
        tipo = ACTUALIZAR_PORCENTAJE if cambios == ["porcentaje"] else ACTUALIZAR_BENEF
        registrar_bitacora(tipo, ip=request.remote_addr, antes=antes, despues=datos)
        flash("Beneficiario actualizado correctamente.", "ok")
        return redirect(url_for("beneficiarios.listar"))

    flash(MENSAJES_ACTUALIZAR.get(codigo, f"Error de base de datos ({codigo})."), "error")
    return pantalla(datos, editando=id_benef)


@benef_bp.route("/beneficiarios/<int:id_benef>/eliminar", methods=["POST"])
def eliminar(id_benef):
    if "id_cuenta" not in session:
        return redirect(url_for("inicio"))

    actual = obtener(id_benef)
    if not actual:
        flash("El beneficiario no existe o no pertenece a su cuenta.", "error")
        return redirect(url_for("beneficiarios.listar"))

    codigo, _ = ejecutar_sp("EliminarBeneficiario", (id_benef,))
    if codigo == 0:
        antes = a_formulario(actual)
        registrar_bitacora(ELIMINAR_BENEF, ip=request.remote_addr,
                           antes=antes, despues={**antes, "activo": False})
        flash("Beneficiario eliminado correctamente.", "ok")
    else:
        flash(MENSAJES_ELIMINAR.get(codigo, f"Error de base de datos ({codigo})."), "error")
    return redirect(url_for("beneficiarios.listar"))
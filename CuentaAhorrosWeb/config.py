from pathlib import Path
from dotenv import dotenv_values

valores = dotenv_values(Path(__file__).parent / ".env")

class Config:
    SECRET_KEY = valores.get("SECRET_KEY", "1234")
    DB_SERVER = valores.get("DB_SERVER")
    DB_NAME = valores.get("DB_NAME")
    DB_USER = valores.get("DB_USER")
    DB_PASSWORD = valores.get("DB_PASSWORD")

print("DB_SERVER =", Config.DB_SERVER, "| DB_NAME =", Config.DB_NAME)


# Usuario	|   Contraseña  |   admin?
# jaguero	|   LaFacil     |   0
# fquiros	|   MyPass123*  |   1
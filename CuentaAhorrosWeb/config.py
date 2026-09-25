import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "1234")
    DB_SERVER = os.getenv("100.94.199.34,1433")
    DB_NAME = os.getenv("Tarea programada II")
    DB_USER = os.getenv("Luis Aguilar")
    DB_PASSWORD = os.getenv("TareaProgramada2")
    MODO_SIN_BD = os.getenv("MODO_SIN_BD", "0") == "1"

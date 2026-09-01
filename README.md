Markdown
<div align="center">
  <h1>[Nombre de la Asignatura]</h1>
  <h2>Proyecto: Bitácora Móvil de Redes</h2>
</div>

**Integrantes del Equipo:**
* [Nombre y Apellidos del Integrante 1]
* [Nombre y Apellidos del Integrante 2]
* [Nombre y Apellidos del Integrante 3]

**Fecha:** [Día] de [Mes] de 202X

---

## 📖 Introducción y Justificación
La administración eficiente de redes y dispositivos es fundamental en cualquier entorno tecnológico. Este proyecto surge de la necesidad de contar con una herramienta móvil que permita registrar, segmentar y consultar el inventario de equipos de red en tiempo real.

La justificación de esta aplicación radica en agilizar el proceso de gestión de direcciones IP y direcciones MAC, reduciendo errores humanos de captura mediante validaciones estrictas y ofreciendo un buscador unificado para encontrar rápidamente cualquier equipo en la infraestructura.

---

## 🚀 Guía de Instalación y Ejecución

Para ejecutar este proyecto en tu entorno local, sigue estos pasos:

1. **Clonar el repositorio:**
   ```bash
   git clone [https://github.com/ptmgamboa/Bitacora-de-redes.git](https://github.com/ptmgamboa/Bitacora-de-redes.git)
Entrar a la carpeta del proyecto:

Bash
cd Bitacora-de-redes
Instalar las dependencias de Flutter:

Bash
flutter pub get
Configurar la Base de Datos:
Crear el archivo lib/core/constants.dart con las credenciales de Supabase:

Dart
class Constants {
static const String supabaseUrl = 'TU_URL_AQUI';
static const String supabaseAnonKey = 'TU_KEY_AQUI';
}
Ejecutar la aplicación (asegúrate de tener un emulador abierto o dispositivo físico conectado):

Bash
flutter run
🔐 Credenciales de Prueba
Para evaluar el sistema, la autenticación está configurada con un acceso de prueba exclusivo.

Correo: prueba@gmail.com

Contraseña: 12345678

📸 Evidencias de Funcionamiento
1. Autenticación e Inicio de Sesión
2. Gestión de Redes (CRUD de Segmentos)
3. Inventario de Dispositivos (CRUD de Equipos)
4. Buscador Unificado (Filtros en tiempo real)
   ⚙️ Arquitectura y Validaciones Técnicas
   Base de Datos (Supabase): Relacional. Tabla redes y tabla dispositivos vinculadas mediante llave foránea (red_id).

Reglas de Captura Estricta:

Segmento (Red): Requiere notación CIDR exacta (ej. 192.168.1.0/24).

IP (Dispositivo): 4 octetos numéricos exactos en rango 0-255.

Dirección MAC: Autocompletado integrado de XX:XX:XX:XX:XX:XX.

🧠 Conclusiones Individuales
[Nombre del Integrante 1]:

"[Escribe aquí tu conclusión personal. Ej: Al desarrollar esta aplicación comprendí la importancia de conectar una interfaz móvil con una base de datos en tiempo real...]"

[Nombre del Integrante 2]:

"[Escribe aquí tu conclusión personal. Ej: Mi aportación en el proyecto me permitió entender cómo aplicar validaciones estrictas para evitar errores de usuario...]"

[Nombre del Integrante 3]:

"[Escribe aquí tu conclusión personal. Ej: La experiencia de trabajar con Flutter y GitHub en equipo me enseñó a llevar un mejor control de versiones y diseño de UI...]"
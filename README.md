<div align="center">
  <img width="600" alt="portada zacek" src="https://github.com/user-attachments/assets/bf6937c0-0070-4095-88e9-c84ccebba7cd" />
</div>

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

 ```Bash
    cd Bitacora-de-redes
 ```
Instalar las dependencias de Flutter:
 ```Bash
    flutter pub get
 ```
Configurar la Base de Datos:

Crear el archivo lib/core/constants.dart con las credenciales de Supabase:

 ```Dart
class Constants {
  static const String supabaseUrl = 'TU_URL_AQUI';
  static const String supabaseAnonKey = 'TU_KEY_AQUI';
}
 ```
Ejecutar la aplicación (asegúrate de tener un emulador abierto o dispositivo físico conectado):

 ```Bash
flutter run
 ```
---
🔐 Credenciales de Prueba
Para evaluar el sistema, la autenticación está configurada con un acceso de prueba exclusivo.

Correo: prueba@gmail.com 

Contraseña: 12345678

---
📸 Evidencias de Funcionamiento
### 1. Autenticación e Inicio de Sesión
Pantalla principal de acceso al sistema restringido utilizando las credenciales de prueba. Se bloquea el acceso a usuarios no autorizados.
<div align="center">
  <img width="300" alt="Login" src="https://github.com/user-attachments/assets/bb12205a-78b8-4308-9e8b-13294946f4e5" />
</div>

### 2. Agregar Red (Creación de Segmentos)
Formulario para registrar una nueva subred, donde se valida de forma estricta que el segmento ingresado cumpla con la notación CIDR y el teclado se adapta automáticamente.
<div align="center">
  <img width="300" alt="Agregar Red" src="https://github.com/user-attachments/assets/90a00586-c046-4e8a-98eb-3400b085f3cf" />
</div>

### 3. Modificar Red
Interfaz que permite editar los detalles de una red existente, manteniendo la integridad de los datos y actualizando la base de datos en tiempo real.
<div align="center">
  <img width="300" alt="Modificar Red" src="https://github.com/user-attachments/assets/60e295a8-3a99-4deb-9dbd-9144019e1c35" />
</div>

### 4. Inventario de Dispositivos
Vista general del inventario físico, mostrando todos los equipos registrados, su dirección IP, MAC y a qué red se encuentran asociados.
<div align="center">
  <img width="300" alt="Inventario Dispositivos" src="https://github.com/user-attachments/assets/c8699307-8178-4971-b631-391fb87733cb" />
</div>

### 5. Agregar Dispositivo
Captura de un nuevo equipo que incluye validaciones para IPv4 y un autocompletado inteligente que inserta los dos puntos (:) automáticamente al escribir la dirección MAC.
<div align="center">
  <img width="300" alt="Agregar Dispositivo" src="https://github.com/user-attachments/assets/3d3a521e-e77d-4eb7-99b2-a9fc6c85cd8b" />
</div>

### 6. Eliminar Dispositivo
Proceso para dar de baja un equipo del inventario de forma segura, actualizando la lista al instante.
<div align="center">
  <img width="300" alt="Eliminar Dispositivo" src="https://github.com/user-attachments/assets/5e43eac9-2187-48c1-995c-798367af6f91" />
</div>

### 7. Buscador Unificado
Uso de la barra de búsqueda global, la cual filtra los resultados instantáneamente evaluando coincidencias en IP, MAC, nombre o fabricante del dispositivo.
<div align="center">
  <img width="300" alt="Buscador" src="https://github.com/user-attachments/assets/1f00b0d6-2401-452e-b6be-660ac82079ff" />
</div>


---
### ⚙️ Arquitectura y Validaciones Técnicas
Base de Datos (Supabase): Relacional. Tabla redes y tabla dispositivos vinculadas mediante llave foránea (red_id).

Reglas de Captura Estricta:

Segmento (Red): Requiere notación CIDR exacta (ej. 192.168.1.0/24).

IP (Dispositivo): 4 octetos numéricos exactos en rango 0-255.

Dirección MAC: Autocompletado integrado de XX:XX:XX:XX:XX:XX.


---

### 🧠 Conclusiones Individuales
Beltrán Bastida Braulio Santiago:

El desarrollo de esta bitácora móvil nos permitió poner en práctica lo aprendido sobre administración de redes y desarrollo de software en un proyecto real. Logramos crear una aplicación fácil de usar que cumple con todos los requisitos, permitiendo registrar y modificar redes, gestionar el inventario de dispositivos y validar que datos clave como la IP o la MAC se ingresen de forma correcta sin errores. Además, la experiencia de trabajar en equipo mediante GitHub nos ayudó a coordinar los cambios de cada integrante y a mantener el código organizado. En general, este proyecto nos deja una herramienta muy útil para controlar la información de una infraestructura de red y refuerza nuestras habilidades para crear soluciones móviles prácticas.

Garcia Garcia César Eduardo:

Este proyecto me permitió consolidar mis conocimientos en la conexión de una interfaz móvil con Supabase, además de aprender a gestionar repositorios públicos, sincronizar ramas y colaborar eficientemente usando comandos de Git y GitHub ya que era algo nuevo para mi y creia que era dificil, pero al ponerlo a prueba es muy facil de entender.

Gómez Marván Abraham Raul:

Dentro de la práctica, integrar la bitácora de redes era una solución eficiente para poder segmentar bien las redes, el detalle fue optimizar esto mediante flutter puesto que debíamos tener un inventario estructurado en flutter y supabase, tuvimos que tener en cuenta toda la lista de cotejo aunque nos centramos mucho en detalles como la limitación de errores humanos en la captura de direcciones IP, MAC y subredes gracias a usar validaciones estrictas y relaciones de llaves foráneas, el enfoque cerrado que le dimos garantizó que sólo los usuarios autorizados podían gestionar la infraestructura de la red resguardando la información crítica del sistema.

Ruiz Rincón José luis:

Trabajar en esta aplicación fue una gran oportunidad para conectar la teoría con una solución práctica y funcional. Nos enfocamos en que el sistema fuera intuitivo y confiable, asegurando que el registro de los equipos y la información de la red no presentaran fallas al momento de capturar los datos. Más allá del código, fue clave aprender a coordinarnos en equipo para integrar las ideas de todos y entregar un proyecto completo que cumpliera con lo solicitado. Al final, logramos una herramienta sólida que simplifica el control de la red y nos demuestra la capacidad que tenemos para resolver problemas reales mediante el desarrollo de software.

# Bitácora Móvil de Redes

Aplicación móvil desarrollada en Flutter orientada a la gestión y segmentación de redes, con control de inventario de dispositivos. Utiliza Supabase como backend (BaaS) para el almacenamiento de datos relacional y autenticación de usuarios.

## Arquitectura y Base de Datos
* **Tabla `redes`**: Almacena los segmentos lógicos (ID, Nombre, Segmento, Fecha de creación).
* **Tabla `dispositivos`**: Vinculada a las redes mediante una llave foránea (`red_id`), almacena el inventario físico (Nombre, MAC única, Fabricante, Ubicación, IP IPv4).
* **Autenticación**: Sistema de acceso cerrado exclusivo para docentes y administradores. No existe registro público.

## Funcionalidades Principales
* **Gestor de Redes (CRUD)**: Creación, lectura, actualización y eliminación de subredes.
* **Gestor de Dispositivos (CRUD)**: Formulario de captura que asocia equipos a una red existente mediante menús desplegables para evitar errores de tipeo.
* **Buscador Unificado**: Barra de búsqueda global que filtra en tiempo real evaluando coincidencias simultáneas en IP, MAC, Nombre, Fabricante y Ubicación.

## Guía de Captura y Validaciones

El sistema incluye validación estricta a nivel de interfaz (Regex).

| Campo | Regla de Captura | Ejemplo Correcto | Dará Error (Evitar) |
| :--- | :--- | :--- | :--- |
| **Segmento (Red)** | 4 octetos separados por puntos + diagonal (`/`) + prefijo de red (0-32). | `192.168.1.0/24` | `192.168.1.0` (Falta prefijo)<br>`10.0.0.0 /8` (Espacio extra) |
| **IP (Dispositivo)** | 4 octetos numéricos exactos en rango 0-255. | `192.168.1.15` | `192.168.1.256` (Fuera de límite) |
| **Dirección MAC** | 6 pares de caracteres alfanuméricos separados por dos puntos (`:`). | `00:1A:2B:3C:4D:5E` | `00-1A-2B-3C-4D-5E` (Uso de guiones) |


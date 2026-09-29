# App Segura

Prototipo Flutter con autenticación simulada y captura de imágenes con la cámara.

## Acceso de prueba

| Usuario | Contraseña |
| --- | --- |
| `edison` | `Edison123` |
| `nicolas` | `Nicolas123` |

El usuario es indiferente a mayúsculas y espacios al inicio o al final; la
contraseña distingue mayúsculas y debe tener al menos seis caracteres.
Las cuentas existen solo dentro de la aplicación: no hay servidor ni API.

La sesión se guarda mediante `flutter_secure_storage` y vence cinco minutos
después de iniciar sesión. Al vencer, se cierra y se eliminan sus datos locales.

Para ejecutar: `flutter pub get` y `flutter run`.

En `flutter run` (modo debug), el panel muestra los primeros caracteres del
token y la hora local de vencimiento. El token completo no se presenta en
pantalla; se conserva en `flutter_secure_storage` bajo la clave `session_token`.
El panel de diagnóstico no aparece en builds de producción.

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

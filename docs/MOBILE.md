# Preparación móvil

Compatibility, orientación horizontal, canvas_items a 1280 × 720, anclajes y
márgenes derivados del área segura en Android/iOS. Entrada multitáctil con
botones excluidos del área de dirección. Perder el foco pausa y limpia los dedos.

## Rendimiento

- Cuatro tapas físicas, bancos estáticos y pocos obstáculos móviles.
- IA a 5 Hz, HUD a 10 Hz y física fija a 60 Hz.
- Geometría y dibujos creados una vez; sin partículas ni creación continua de
  objetos. No se necesita pooling para esta versión.
- Calidad baja omite plantas decorativas. 30/60 FPS limita render, no cambia
  la física ni acredita rendimiento en móviles.
- Un reproductor por categoría limita las voces simultáneas a seis.

## Android

1. Instalar plantillas de exportación de la misma versión de Godot.
2. Configurar Java y Android SDK en los ajustes del editor para esa versión.
3. Revisar el perfil Android. `com.taparacing.game` es un identificador provisional.
4. Crear `builds/android` y exportar un APK de depuración para probar.
5. Para distribuir, configurar firma propia y formato requerido por la tienda.

Se generó `builds/android/tapa-racing.apk` con firma de depuración, verificada
por apksigner (v1/v2/v3). El manifiesto confirma ARM64, Android mínimo 21,
objetivo 34, orientación horizontal y vibración. Es una compilación de pruebas,
no para publicar en tiendas. No se detectaron teléfonos conectados: falta probar
la instalación y ejecución física.

Las herramientas están aisladas en `.tools/`: JDK 17, Build Tools 34,
Platform Tools y Godot 4.3 portátil. No se modificó el PATH ni Java del sistema.
La clave `.tools/debug.keystore` es de depuración, está excluida del repositorio
y no se incluye en el APK. No contiene credenciales de tienda.

Para repetir la preparación y exportación en Windows:

```powershell
python tools/setup_android.py
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build_debug.ps1 -GodotDirectory "RUTA_AL_MOTOR_4.3"
powershell -NoProfile -ExecutionPolicy Bypass -File tools/smoke_export.ps1
```

Los scripts descargan herramientas oficiales, exportan Android y Windows,
verifican la firma y prueban el ejecutable fuera del proyecto. Las plantillas
se descargan selectivamente y zipfile verifica sus CRC. No ejecutes importaciones
o exportaciones simultáneas sobre la misma carpeta.

Con un teléfono autorizado para depuración USB, puedes instalar manualmente:

```powershell
.tools/sdk/platform-tools/adb.exe devices
.tools/sdk/platform-tools/adb.exe install -r builds/android/tapa-racing.apk
```

Referencia: [exportación Android con Godot 4.3](https://docs.godotengine.org/en/4.3/tutorials/export/exporting_for_android.html).

## iOS

Perfil inicial ARM64 con identificador provisional. Completar equipo, firma y
aprovisionamiento en un Mac con Xcode y las plantillas correspondientes.
No se generó ni firmó una aplicación iOS desde este entorno Windows.

## Validación pendiente

- Medir frame time, memoria, temperatura y batería en dispositivos reales.
- Probar 30/60 FPS, tablets 4:3, teléfonos anchos, notch y bloqueo/reanudación.
- Mantener dirección y pulsar boost simultáneamente; dedos opuestos y soltar
  sobre botones. Verificar volumen, vibración y modo silencioso.
- Completar carreras a mano en tres dificultades y ajustar el equilibrio.
- Persistencia tras cerrar/reabrir, interrupciones al guardar y actualizaciones.
- Sustituir arte/audio provisionales y completar requisitos de tienda y firma.

La validación de escritorio no sustituye estas pruebas de hardware.

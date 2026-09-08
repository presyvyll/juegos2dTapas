# Fases de mejora visual

Actualización: 8 de septiembre de 2026. Godot 4.3, Android, Compatibility.

## Implementación

| Fase | Resultado |
| --- | --- |
| 1. Profundidad | Orillas con borde, sombra y luz; rocas con volumen procedural. |
| 2. Entorno animado | Hojas con balanceo de dibujo, chorros con trazos móviles y remolinos con arcos giratorios. `AmbientMotion` mantiene intactas las transformaciones físicas. |
| 3. Impactos y velocidad | Destello breve para impactos fuertes y estelas de turbo orientadas por el movimiento, reutilizando el pool existente. |
| 4. Cámara | Anticipación limitada a 180 unidades, zoom suave por velocidad y vibración proporcional a la fuerza del impacto. |
| 5. Agua | Reflejos procedurales localizados: hasta diez arcos en calidad alta y cinco en baja, además de la espuma existente. |
| 6. Interfaz | HUD más compacto con velocidad junto a los datos de carrera; transición de opacidad de 0,16 segundos entre páginas del menú. |
| 7. Optimización | Pool de 48/96 efectos que deja de procesarse cuando está vacío; amortiguación calculada una vez por actualización; escudo redibujado al cambiar de estado. |

Las animaciones ambientales solicitan redibujado como máximo a 20 Hz en calidad
alta y 10 Hz en baja. Fuera de cámara comprueban visibilidad cada 0,25 segundos;
su reloj ligero sigue avanzando. No se añadieron luces ni shaders de pantalla
completa. Los límites de efectos incluyen los nuevos destellos.

Se mantienen colisiones, fuerzas, parámetros del turbo, recompensas y progresión.
La cámara y la presentación cambian únicamente la vista del juego.

## Comprobaciones de esta actualización

- Integración de carreras: cero fallos.
- Presentación y pool: capacidad acotada, activación al emitir y suspensión al
  expirar; cero fallos.
- HUD táctil: dirección, turbo y pausa; cero fallos.
- Interfaz renderizada en cinco resoluciones, desde 1280×720 hasta 2340×1080:
  controles dentro de pantalla y cero fallos.
- Veinte reinicios rápidos sin nodos retenidos.
- Ciclo móvil: pausa, regreso, guardado y ajustes de FPS; cero fallos.
- Capturas de pantallas generadas con Compatibility y carrera inspeccionada.

Los registros de esta actualización están en `builds/logs/visual-*.log`.
Se corrigió la resolución de `SaveManager` en el reloj ambiental durante la carga
de pruebas independientes. La integración se repitió comprobando también que el
registro no contuviera errores de scripts, además del contador de fallos.
Estas pruebas se ejecutaron en escritorio. Quedan pendientes mediciones de FPS,
temperatura, consumo y respuesta táctil en un teléfono Android físico.

## Artefactos

El APK de depuración actualizado es `builds/android/tapa-racing.apk` (ARM64).
El AAB y el APK para emulador anteriores no incluyen estas últimas mejoras;
deben regenerarse cuando se necesiten. No se publicó una versión en una tienda.

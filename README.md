# Tapa Racing · prototipo jugable 0.1

Juego 2D con Godot 4.3, GDScript y Compatibility. Arte geométrico y audio
sintetizado localmente; sin plugins ni dependencias de arte externo.

## Archivos listos para probar

Las compilaciones siguientes se generan localmente y no se incluyen en Git.
Para crearlas después de clonar el repositorio, consulta [preparación móvil](docs/MOBILE.md).

- **Android:** `builds/android/tapa-racing.apk`, APK ARM64 de depuración (~25 MB).
- **Windows:** `builds/windows/TapaRacing.exe`, ejecutable autónomo (~85 MB).

El APK tiene firma de depuración verificada. El ejecutable pasó pruebas de arranque
y carreras con los recursos empaquetados. Aún falta validación en teléfono físico;
no son compilaciones para publicar en tiendas. Hashes: `builds/artifacts.json`.

## Jugar

Importa `project.godot` y pulsa **F5**. El menú permite elegir tapa, circuito y
dificultad. **JUGAR** inicia una carrera contra tres rivales. Al llegar se muestra
tu puesto, tiempo y monedas; puedes reiniciar o volver al menú.

| Control | Acción |
| --- | --- |
| A/D o flechas | Dirección lateral respecto de la corriente |
| Espacio / BOOST | Boost con energía regenerable |
| Mitad izquierda/derecha | Dirección táctil multitáctil |
| Deslizamiento horizontal rápido | Impulso lateral con enfriamiento |
| Esc / Pausa | Pausar y continuar |
| R | Reiniciar durante la carrera |

La corriente avanza automáticamente. Cada circuito tiene una vuelta de unos
60–90 segundos; los Resources admiten de una a tres vueltas. Tres vueltas duran
más tiempo. Los pequeños saltos de agua son una elevación visual arcade con
impulso; no permiten saltar obstáculos ni simulan física tridimensional.

## Contenido

- Dos circuitos: Fuente Caribe y Canal Cascada, este último por 200 monedas.
  Curvas, pasos anchos/estrechos e islas con dos rutas.
- Corrientes, remolinos, chorros, pequeños desniveles, piedras, ramas, hojas y
  obstáculos móviles. Colisiones entre tapas.
- Tres rivales con cambios de ruta, errores y boost. Dificultades fácil/normal/difácil.
- Checkpoints ordenados, vueltas, clasificación, meta, HUD, pausa y resultados.
- Seis tapas equilibradas mediante multiplicadores moderados: dos iniciales y
  cuatro desbloqueables. Diseño Perla opcional puramente visual.
- Premios de 80/45/25/15 monedas por puesto. Sin compras reales.
- Guardado versionado con respaldo: monedas, desbloqueos, selección, mejores
  tiempos por circuito/dificultad/vueltas y configuración.
- Música y cinco categorías de efectos provisionales; volumen, vibración,
  calidad alta/baja y límite de 30/60 FPS.

## Arquitectura y archivos

| Ruta | Responsabilidad |
| --- | --- |
| scenes/actors/player_cap.tscn | Composición de tapa, entrada, física, visual y cámara |
| scripts/actors/cap.gd | Movimiento, boost, colisiones y señales |
| scripts/physics/cap_motion.gd | Integración arcade independiente del teclado |
| scripts/input/ | Jugador táctil/teclado y controlador IA |
| scripts/resources/, data/ | Configuración de física, seis tapas y dos circuitos |
| scripts/water/, scenes/water/ | WaterCurrentArea, WhirlpoolArea y WaterDrop |
| scripts/obstacles/, scenes/obstacles/ | Cinco obstáculos reutilizables |
| scripts/levels/race_track.gd | Construcción determinista del circuito |
| scripts/levels/race.gd | Composición y ciclo de vida de la partida |
| scripts/race/ | Checkpoints, vueltas, clasificación y llegada |
| scripts/camera/ | Seguimiento, anticipación y zoom |
| scripts/ui/, ui/ | Menú, selección, ajustes, HUD y resultados |
| scripts/services/ | Catálogo, SaveManager y AudioManager |
| assets/, audio/ | Icono vectorial y sonidos reemplazables |
| tests/ | Física, integración y capturas |
| export_presets.cfg | Perfiles iniciales Android/iOS |

RacingCap recibe órdenes de un controlador y las pasa a CapMotion. La IA comparte
la física del jugador. Los visuales son hijos reemplazables. Las áreas registran
entrada/salida por señales y sus fuerzas se promedian al solaparse. RaceSession
administra progreso y emite resultados; race.gd entrega la recompensa una sola
vez. Solo audio y guardado son autoloads. La separación permite controladores
futuros, pero no hay código de red ni se acredita determinismo para multiplayer.

El canal original `levels/prototype_channel.tscn` sigue disponible para F6.

## Estado de fases

| Fases | Estado |
| --- | --- |
| 1–2 | Estructura y canal inicial conservados |
| 3–4 | Física, agua, boost y controles implementados |
| 5–6 | Circuitos, obstáculos, remolinos y desniveles implementados |
| 7–9 | IA, carreras, vueltas, meta y HUD implementados |
| 10–11 | Menús, tapas, progresión y guardado implementados |
| 12 | Calidad, 30/60 FPS, áreas seguras y exportación Android/Windows verificadas; hardware e iOS pendientes |
| 13 | 38 carreras automatizadas, ciclo móvil simulado y pruebas del ejecutable; dispositivos reales pendientes |

## Pruebas

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/test_motion.gd
godot --headless --path . --fixed-fps 60 --script tests/test_game.gd
godot --headless --path . --fixed-fps 60 --script tests/test_matrix.gd
godot --headless --path . --script tests/test_mobile_lifecycle.gd
godot --headless --path . --fixed-fps 60 --script tests/test_transitions.gd
godot --path . --script tests/capture_screens.gd
```

La prueba integrada usa `user://automated_test_save.json`, separada de la partida
real. Comprueba compras, respaldo, entrada, menús, pausa, dos carreras completas
con autopiloto de prueba para el jugador, checkpoints, vueltas y recompensa única.
Las capturas se escriben en `user://` sin modificar la partida.

Consulta [validación](docs/VALIDATION.md) y [preparación móvil](docs/MOBILE.md).

## Guardado y ajuste

Partida: `user://tapa_racing_v1.json`, con respaldo `.bak` y escritura temporal.
En Windows: `%APPDATA%/Godot/app_userdata/Tapa Racing/`. Una compra que no puede
guardarse se revierte. Si falla el guardado de resultados, las monedas quedan en
memoria y aparece un mensaje. Conserva una copia antes de editar el archivo.

Ajusta la física base en `data/caps/prototype.tres`; las seis definiciones aplican
multiplicadores. Las áreas exponen parámetros en el inspector. Los Resources de
circuitos definen longitud, ancho, curvas, semilla y vueltas.

## Últimas correcciones

El boost responde al segundo dedo mientras el primero dirige. El botón Atrás de
Android gestiona pausa/menús y la suspensión guarda el progreso y pausa la física.
El cargador rechaza tipos inválidos de saldo y preserva el respaldo sano tras
recuperar una partida corrupta. Estas rutas tienen pruebas de regresión.

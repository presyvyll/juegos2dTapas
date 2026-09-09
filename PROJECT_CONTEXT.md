# Contexto del proyecto

## Etapa de contenido actual

- Diseño: CONTENT_DESIGN.md, BALANCE_NOTES.md, ART_ASSET_REQUIREMENTS.md.
- Etapas A–C: 18 tapas, 18 habilidades, 18 apariencias, diez perfiles y diez rivales
  en data/arcade_content.tres. Sigue siendo un manifiesto en preparación.
- Etapa D implementada: **quince pistas jugables y seis tapas activas**.
  Detalles, acceso y pruebas: docs/ETAPA_D_CIRCUITOS.md.
- data/catalog.tres referencia fichas ligeras en data/circuit_entries. Cada ficha
  usa layout_path (cadena); RacingCatalog.load_circuit carga/copia solo el trazado
  seleccionado en data/circuits. No añadir ExtResource del layout a las fichas.
- Diez circuitos nuevos: jardin, plaza, canal_turbo, express, templo, neon,
  laberinto, ojo, titan, eclipse. Los cinco IDs originales se conservan.
- Acceso provisional por monedas mediante SaveManager existente. Jardín y Plaza
  cuestan cero. No activar requisitos de copa antes de implementar campeonatos.
- Ojo usa pulse_depth/pulse_period en WhirlpoolArea; cero mantiene fuerza anterior.
  Eclipse tiene señalización configurable de secciones, pero no evento de Pixel.
- RaceTrack recoloca recogibles bloqueados por islas o barridos de obstáculos.
- No se reescribieron físicas/IA. Habilidades, perfiles, XP/niveles, campeones y
  copas todavía no ejecutan lógica de juego. Siguiente etapa E: cinco copas con
  sesión/persistencia, después F–I según diseño. No activar el roster nuevo sin
  migración de compras y ejecución de habilidades.
- test_content_data espera 6 tapas/15 pistas; test_circuit_loading protege carga
  diferida, liberación, coherencia de fichas y pulsación. test_all_courses comprueba
  geometría y ocho recogibles accesibles. test_matrix cubre 285 carreras/1140
  llegadas, con filtro -- --circuit=ID; desactiva solo dibujo durante headless.
- Estado de pruebas y builds: CONTENT_IMPLEMENTATION_REPORT.md. Validación física
  Android y balance manual pendientes; no confundir mediciones Windows con móvil.
- Etapa D validada: 285 carreras, 1 140 llegadas, cero fallos; resumen en
  docs/stage_d_validation_summary.json y log stage-d-matrix-final.log. APK ARM64
  y x86_64 regenerados y firmados; carga/geometría también pasan sobre assets del APK.

## Base jugable

- Godot 4.3 estable, GDScript, Compatibility; objetivo Android. No cambiar físicas
  ni reescribir IA. Arte procedural existente, sin plugins.
- Escena compartida: `levels/race.tscn`, construida por `scripts/levels/race.gd`.
  `RaceTrack` genera canal y elementos; `RaceSession` gestiona doce checkpoints,
  meta, clasificación y una a tres vueltas. Avance por el eje -Y.
- Las cinco pistas originales siguen activas: Fuente Central (`fuente`), Canal Tropical
  (`tropical`), Remolino Azul (`remolino`), Cascada Extrema (`cascada`) y Tormenta
  Caribeña (`tormenta`). Todos usan `CircuitDefinition` y `CircuitFeature` con escenas
  compartidas. Detalles y precios: `docs/NUEVAS_PISTAS.md`.
- `fuente` y `cascada` conservan IDs y desbloqueos; `record_version = 2` evita mezclar
  récords con sus trazados antiguos. Usar `CircuitDefinition.record_key()`.
- La IA sigue centro/anchura y esquiva obstáculos a 5 Hz. Recuperación tras un
  segundo fuera del canal o al omitir un checkpoint; vuelve antes del pendiente,
  sin conceder progreso. Regresión concreta: `test_storm_finish.gd`.
  No hay bifurcaciones externas:
  las alternativas rodean islas dentro del canal.
- Presupuesto máximo actual: 28 elementos, doce sólidos, VFX 48/96. Lluvia de
  Tormenta: 16/36 trazos en baja/alta en la zona del agua que sigue a cámara.
- Pruebas: `test_all_courses.gd` (geometría/ambas calidades/récords),
  `test_matrix.gd` (285 carreras en quince pistas, filtro `-- --circuit=ID`),
  `test_android_layouts.gd` (cinco resoluciones), y regresiones del runner
  `tools/test_android.ps1`. Logs actuales: `builds/logs/stage-d-*.log`.
  Validación histórica de las primeras cinco: 95 carreras, 380 llegadas, cero fallos; ver
  `courses-matrix-final.log` y `docs/course_validation_summary.json`. El log
  `courses-matrix.log` conserva el fallo inicial ya corregido, no el resultado final.
- Motor local `.tools/godot/Godot_v4.3-stable_win64_console.exe`; presets de
  depuración `Android` (ARM64) y `Android Emulator` (x86_64). Usar exportación directa;
  `tools/build_debug.ps1` todavía depende por defecto de una ruta temporal antigua.
- APK: `builds/android/tapa-racing.apk` y `tapa-racing-emulator.apk`. El AAB previo
  está desactualizado. No se acreditó rendimiento en un teléfono físico.
- Emulador local `TapaRacing_Test`; SDK `.tools/sdk`. ADB local con `-P 5038`, destino
  `127.0.0.1:5555`, evita el conflicto con el ADB antiguo del sistema.
- Compilaciones, SDK y claves se excluyen de Git. Revisar siempre estado/diff antes
  de continuar; los cambios de las pistas aún no se han publicado en GitHub.

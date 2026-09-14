# Contexto del proyecto

## Etapa actual: evolución fases 3–8 implementadas, sin pruebas todavía

Actualización 2026-09-13: menú/Garage y feedback de carrera modernizados; seis perfiles
de IA activos y dificultad Experto. 64 carreras/256 llegadas validadas en la entrega
de IA; falta Android físico y estabilizar calidad alta. Auditoría actual:
docs/AUDITORIA_EVOLUCION.md. Combos y ghost siguen pendientes. Fase 2: señal de swipe aplicado
reutiliza HUD, audio, haptics y pool VFX sin modificar fuerza/cooldown.
Actualización 2026-09-14: ondas decorativas acotadas al viewport en WaterSurface;
248–398 draw calls y 60 FPS observados en PC (antes 1.073–1.236 draw calls).
Pruebas de límites visuales y carreras pasan; falta medición en Android físico.

Fase 3 implementada (pendiente de pruebas): Perfect Shot clasifica el swipe lateral
aceptado en Weak/Good/Great/Perfect por duración y alineación horizontal. Configuración
en data/perfect_shot/default.tres; feedback en HUD/audio/haptics y pool VFX existente.
No cambia fuerza, cooldown, monedas ni XP. No añade lanzamiento por arrastrar/soltar.
Por instrucción del usuario, aplazar pruebas y ejecución hasta el final de las fases
de desarrollo. El APK instalado corresponde todavía a la fase 2.

Fase 4 implementada (pendiente de pruebas): CapDefinition.resolve_physics centraliza
los cinco multiplicadores existentes y añade rebote, fricción, estabilidad lateral e
impulso lateral con valores neutros. CapPhysicsConfig sigue siendo la base compartida.
apply_definition recalcula desde una copia base: corrige la acumulación al sustituir
la tapa provisional de un rival de copa. Garage muestra cinco índices reales y los
cuatro valores adicionales; CapRatings 1–10 permanece como dato de diseño del catálogo
futuro. No se activan las 18 tapas ni se migran IDs/desbloqueos en esta etapa.

Fase 5 implementada (sin pruebas): CapAbilityRuntime mantiene estado por corredor.
Las seis tapas actuales enlazan las habilidades de sus equivalentes de diseño:
sol/chispa, coral/coral, menta/burbuja, oceano/rayo, uva/brasa, coco/titan. Activación
automática por salida, impacto, entrada en corriente, adelantamiento o turbo; timers
solo avanzan durante conducción activa. Recursos base inmutables, HUD y Garage
muestran habilidades reales. Las otras doce habilidades siguen sin integración.

Fase 6 (sin pruebas): Garage compara los cinco índices con la tapa equipada y
permite alternar habilidad/estadísticas sin salir del carrusel. Compra, equipamiento,
Perla, bloqueos y swipe existentes conservados. MEJORAR sigue deshabilitado hasta
implementar niveles/economía en fase 7; integrado en la actualización siguiente.

Fase 7 implementada (sin pruebas): progreso por tapa con XP y niveles 1–5, Resource
data/progression/default.tres. XP por llegada 30/24/18/12; requisitos acumulados
0/100/250/450/700 XP y costes 100/175/250/350 monedas. Cada nivel añade 1% de la base
de aceleración/control, hasta 4%; no cambia velocidad máxima, turbo ni habilidades.
Garage permite comprar mejoras; comparaciones y jugador usan el nivel guardado.
SaveManager escribe esquema 2 en el mismo archivo y acepta v1 sin progreso previo.
XP integrada en la transacción de copa y resultado libre; rollback y reintento de
guardado libre. Nivel/XP visibles en Garage, menú y resultados. Balance, migración,
regresiones y compilación aplazados al cierre por instrucción del usuario.

Fase 8 implementada (sin pruebas): ChampionshipPage integra CupRoute, tarjeta de
pista, preparación, swipe en cabecera, campeón final y retorno al mapa entre rondas.
CupProgress conserva en championships.track_records estrellas/mejor tiempo por copa
y número de ronda; se actualizan en la misma transacción que resultado/XP. La ruta
jugable sigue exclusivamente active.rounds y las fases existentes, sin saltar rondas.
Históricos antiguos sin detalle de rondas no reciben estrellas inventadas. El mapa
usa entradas ligeras y preview ilustrativa, sin cargar geometría ni escenas de carrera.

- F: introducciones de cinco campeones solo en la final de cada copa. ChampionIntro
  reutiliza retrato del corredor activo, frase y color de ChampionshipDefinition.
  Dura 2,5 s; después de verla se puede saltar. seen_champion_intros en SaveManager
  conserva IDs vistos, valida partidas antiguas y revierte escrituras fallidas.
- Durante la intro, RaceSession queda detenido y todos los corredores inactivos.
  Se enfoca al campeón; al finalizar se restauran cámara, HUD, controles y cuenta
  atrás. La pausa detiene la intro y mantiene accesible su menú.
- Pruebas F: diez presentaciones (baja/alta, cinco resoluciones), guardado/salto,
  pausa, 22 carreras/88 llegadas y regresiones, cero fallos. También probadas con
  assets del APK. Docs: docs/ETAPA_F_CAMPEONES.md; logs: builds/logs/stage-f-*.log.

- Activos: seis tapas originales, quince pistas y cinco copas con progreso guardado.
  Diseño: CONTENT_DESIGN.md. Estado: CONTENT_IMPLEMENTATION_REPORT.md.
- Pistas D: data/circuit_entries contiene fichas ligeras; layout_path es una cadena.
  RacingCatalog.load_circuit carga y copia solo el trazado seleccionado.
- Copas E: data/championships/bronce, plata, oro, maestra, leyenda; registradas en
  data/catalog.tres. Menú COPAS, 22 carreras, vueltas 1/1/2/2/3, puntos 10/7/4/2.
  Podio desbloquea siguiente copa y entrega premio único de 150/250/350/500/700.
- CupProgress valida resultados y deriva clasificación/desempates. SaveManager
  guarda championships.active y completed en el JSON v1, con transacciones que
  revierten progreso/monedas si fallan. Admite guardados anteriores y backup.
- Fases ready/racing/results/complete. Cerrar a mitad repite la carrera pendiente;
  en resultados reanuda sin repetir. Una participación activa; carrera libre aislada
  mediante intención transitoria cup_race_requested.
- Race espera cuatro llegadas o 180 segundos por vuelta. DNF no concede puntos ni
  se convierte en llegada. Se muestran última ronda y clasificación acumulada.
  Las copas fijan sus vueltas/dificultad y no alteran ajustes de carrera libre.
- Rivales fijos por copa, con nombres del diseño y tapas originales configuradas en
  legacy_rival_cap_ids. NO ejecutan todavía habilidades ni perfiles nuevos.
- Usar Array[String] en listas de pistas/rivales de ChampionshipDefinition:
  las PackedStringArray se perdían en el export binario Android observado.
  El flujo y la lógica pasan con los recursos extraídos del APK corregido.
- Pruebas E: test_championships, test_cup_flow, test_cup_races (22 carreras,
  88 llegadas, cero fallos), test_cup_layouts (cinco resoluciones), más regresiones.
  Evidencia: builds/logs/stage-e-*.log, docs/ETAPA_E_COPAS.md.
- APK ARM64 y x86_64 regenerados y firmas verificadas. Falta Android físico.
- Siguiente G–I: migración,
  desbloqueos, interfaz y balance. XP, niveles, premios de tapas/cosméticos y
  habilidades siguen pendientes; no anunciarlos como activos.
- data/arcade_content.tres sigue siendo preparación A–C: 18 tapas, 18 habilidades,
  18 apariencias, diez perfiles y diez rivales. No reemplazar roster sin migración.
- Las pistas de carrera libre conservan compras provisionales, incluidos Jardín
  y Plaza por cero monedas. Dentro de una copa no se cobra cada pista.
- No reescribir físicas/IA ni duplicar escenas. RaceTrack recoloca recogibles
  bloqueados; Ojo usa remolinos pulsantes y Eclipse señaliza secciones, pero no
  emite todavía el evento de habilidad de Pixel.
- Validación D histórica: 285 carreras / 1140 llegadas / cero fallos en quince pistas.
  docs/stage_d_validation_summary.json. La matriz desactiva solo presentación.
- Commit D publicado en main: 174a25a. Mantener commits separados por etapa.

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

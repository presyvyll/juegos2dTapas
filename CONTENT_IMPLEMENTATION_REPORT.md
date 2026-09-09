# Reporte de contenido — etapa E

**Cinco copas jugables con progreso y guardado**, además de quince pistas y seis
tapas originales. Ver [ETAPA_E_COPAS](docs/ETAPA_E_COPAS.md) para reglas y uso.

- Bronce, Plata, Oro, Maestra y Leyenda: 22 carreras, participantes fijos y vueltas
  configuradas. Puntos 10/7/4/2, DNF, desempates, clasificación y podio acumulado.
- Podio abre la siguiente copa; premios de monedas únicos. Cerrar y reanudar
  conserva rondas completadas. Fallos de escritura revierten puntos/progreso y
  monedas; backup y guardados v1 anteriores conservan compatibilidad.
- **22 carreras / 88 llegadas / cero fallos** con físicas e IA reales bajo
  autopiloto de prueba. Progresión, repetición de premios, timeout, botones de
  continuar/reanudar y recuperación del backup también pasan.
- Pantallas de copas y resultados: cinco resoluciones, cero fallos. Se corrigieron
  desbordamientos y el tamaño del mensaje de espera. Captura:
  builds/stage-e/cup_results.png. Logs finales: stage-e-layouts-delivery.log.
- Regresiones de juego, vueltas, ciclo móvil, transiciones, datos y carga: pasan.
- Se detectaron listas PackedStringArray vacías en los recursos binarios del APK.
  Las listas de ChampionshipDefinition usan ahora Array[String]. Se verificaron
  las cinco listas exportadas y pasan las pruebas de lógica/navegación usando
  directamente los assets extraídos del APK. No se confundió exportar con validar.
- Logs APK válidos: stage-e-apk-final-test_championships.log,
  stage-e-apk-final-test_cup_flow.log y stage-e-apk-validation-final.log.
  stage-e-apk-flow.log conserva el fallo previo ya corregido.

APK ARM64: 25 107 510 bytes, SHA-256
26e5957ec90bc713676d52b0dfd9d3a5cb9eb5cf31e1c7a2c16c44f432bb2131.
APK x86_64: 27 483 184 bytes, SHA-256
c986b80dccad01699a4a28b7bdae32ac672e59f8ef0ab12bf3240152a54b40bd.
Ambos están en builds/android y sus firmas de depuración están verificadas.
El AAB y ejecutable Windows anteriores no se regeneraron.

Pendiente: Android físico, presentación de campeones (F), migración del roster,
XP/niveles, habilidades y premios de tapas/cosméticos. Los rivales de copa usan
nombres del diseño, las seis tapas anteriores y la IA común. Las compras de pistas
en carrera libre conservan la política temporal de D.

## Histórico: etapa D

La implementación incorpora **quince pistas jugables**, seis tapas activas y carga
del trazado elegido bajo demanda. Los datos A–C de nuevas tapas/habilidades siguen
en preparación. Próxima etapa E: cinco copas con sesión y persistencia.

## Entrega D

- Diez layouts nuevos, quince fichas ligeras y catálogo actualizado.
- Todos comparten RaceTrack, RaceSession, CapAIController y levels/race.tscn.
- Remolinos pulsantes configurables en Ojo; flores, pilares y balizas procedurales;
  secciones señalizadas en Eclipse. Sin shaders ni nuevas escenas de carrera.
- Ocho recogibles por pista: se reubican si coinciden con una isla o el barrido
  de un obstáculo móvil, sin cambiar sus efectos.
- Acceso temporal por monedas; Jardín y Plaza cuestan cero. Se conservan IDs,
  compras y versiones de récord existentes. No se exigen copas inexistentes.
- Detalles, tabla de pistas y reproducción: [ETAPA_D_CIRCUITOS](docs/ETAPA_D_CIRCUITOS.md).

## Evidencia D

- Carga bajo demanda, liberación de layouts, coherencia de metadata, copias de
  vueltas y fuerza pulsante: cero fallos en test_circuit_loading.
- Geometría, cuatro spawns, doce checkpoints, meta, ocho recogibles accesibles y
  presupuesto de quince pistas × dos calidades: cero fallos en test_all_courses.
- Selector de quince pistas en cinco resoluciones: cero fallos en test_android_layouts.
- Regresiones de datos, juego, configuración, Tropical, power-ups y llegada en
  Tormenta: cero fallos. Logs builds/logs/stage-d-*.log.
- Matriz final: **285 carreras, 1 140 llegadas, cero fallos**. Quince pistas ×
  seis tapas × tres dificultades, más quince carreras de tres vueltas. Jugador
  con autopiloto de prueba; se desactiva solo presentación en modo headless.
  Resumen: [stage_d_validation_summary.json](docs/stage_d_validation_summary.json).
  Log: builds/logs/stage-d-matrix-final.log; detalle: builds/stage-d/matrix_results.json.
  stage-d-matrix.log conserva la ejecución interrumpida antes de corregir recogibles.
- Renderizado de treinta vistas e inspección de Jardín, Templo, Neón, Ojo y Eclipse.
  Capturas de calidad alta: builds/stage-d/course_*_high.png.
- Treinta mediciones Windows: construcción de escena entre 92.162 y 542.703 ms;
  máximo incremento de memoria estática observado 27 884 016 bytes. Incluye
  calentamiento y ejecución concurrente de pruebas; no es benchmark Android.
  Datos: [stage_d_loading_metrics.json](docs/stage_d_loading_metrics.json).

## Compilaciones D

- ARM64: builds/android/tapa-racing.apk, 25 085 600 bytes.
  SHA-256: 88191a66303196ebeefb950cb5c1533c479650c19cbb797c7acde532960bf806.
- Emulador x86_64: builds/android/tapa-racing-emulator.apk, 27 461 274 bytes.
  SHA-256: 9d66484356fa6f6bac40fc88f7a86373547650a86050f86f4018a0baeec50356.
- Ambas firmas de depuración verificadas con apksigner. Los APK contienen las
  quince fichas y quince layouts; las pruebas de carga y geometría también pasan
  usando los recursos extraídos del APK ARM64 en Godot de Windows.
- La primera exportación falló al acceder al APK temporal; se comprobó su ZIP y
  la repetición terminó correctamente. Logs finales: stage-d-export-delivery-*.
- El AAB y ejecutable Windows previos no corresponden a esta entrega. No se publicó
  código en GitHub ni se instaló automáticamente el APK en un dispositivo.

## Pendiente

Prueba táctil y rendimiento en Android físico, balance competitivo, copas,
campeones, habilidades, perfiles de IA personalizados y migración del roster.
Las etiquetas de precisión no disparan todavía la habilidad de Pixel. Los
obstáculos del circuito activo permanecen instanciados: no hay streaming por sectores.

---

## Histórico: entrega A–C (antes de integrar las quince pistas)

Se completaron el diseño global y el primer bloque de Resources. El manifiesto
`data/arcade_content.tres` es contenido en preparación: **no reemplaza el catálogo
jugable**, que conserva seis tapas y cinco pistas. No se presenta una habilidad,
copa, nivel o desbloqueo como operativo antes de integrar su ejecución.

| Entregable | Resultado verificable |
| --- | --- |
| 1. Tapas | 18 Resources CapDefinition, 36 puntos cada una, distribución 3/3/3/3/2/2/2. |
| 2. Habilidades | 18 CapAbilityDefinition con condiciones, magnitudes, duraciones y límites; ejecución pendiente. |
| 3. Rivales | 10 RivalDefinition con tapa, personalidad, frases y power-ups favoritos. |
| 4. AI Profiles | 10 AIProfile configurados; conexión al controlador pendiente. |
| 5. Circuitos | 15 diseñados; permanecen cinco jugables. Diez nuevos layouts pendientes de etapa D. |
| 6. Copas | Cinco diseñadas; modelo ChampionshipDefinition creado. Sesión y cinco Resources de copa pendientes. |
| 7. Bosses | Cinco de los diez rivales están identificados como campeones; presentación y premios pendientes. |
| 8. Resources | 75 archivos .tres: 18 tapas, 18 habilidades, 18 apariencias, diez perfiles, diez rivales y un manifiesto; además 18 ratings embebidos. |
| 9. Escenas modificadas | Ninguna .tscn en este bloque. Se reutilizan dibujo y preview existentes. |
| 10. Scripts modificados | CapDefinition, CircuitDefinition y RacingCatalogData ampliados; runner test_android.ps1 incluye validación de contenido. |
| 11. Nuevos scripts | cap_ratings.gd, cap_ability_definition.gd, ai_profile.gd, rival_definition.gd, championship_definition.gd; test_content_data.gd y capture_content.gd. |
| 12. Sistemas reutilizados | Resources, catálogo, CapAppearance/CapArt/CapPreview, multiplicadores físicos existentes, SaveManager y pruebas. |
| 13. Assets pendientes | Arte definitivo y audio opcional listados en ART_ASSET_REQUIREMENTS.md; placeholders reales renderizados. |
| 14. Problemas encontrados | No existen XP/niveles/copas pese a la premisa inicial; el catálogo actual carga los trazados completos. La captura aislada adelantaba la carga de servicios. |
| 15. Correcciones | Diseño adapta las copas a cuatro corredores y prevé carga bajo demanda; script de captura carga la interfaz después de los autoloads. Sin cambios de física. |
| 16. Balance pendiente | Activar habilidades y perfiles, probar victorias/tiempos por semilla y pista, y jugar con controles táctiles. Un presupuesto igual no prueba equilibrio competitivo. |
| 17. Siguiente paso | Etapa D: diez layouts y catálogo ligero; después copas, campeones, migración/desbloqueos, UI y balance. |

## Evidencia

- Importación de Godot 4.3: sin errores.
- `test_content_data.gd`: cero fallos; IDs, referencias, presupuestos, rarezas,
  condiciones de desbloqueo, no dominancia, perfiles, cinco campeones, serialización
  de Resources y conservación de compras del guardado actual.
- Regresiones `test_game.gd`, `test_arcade.gd` y `test_race_setup.gd`: cero fallos.
- `capture_content.gd`: renderizó las 18 tapas y se inspeccionó la imagen.
  Vista: `builds/arcade_content.png`. Es una hoja de revisión, no un menú nuevo.
- Logs finales: `builds/logs/content-data.log`, `content-test_*.log` y
  `content-capture-final.log`. `content-capture.log` conserva el error inicial del
  script de captura, ya corregido.

No se generó un APK nuevo para estos datos en preparación. Los APK anteriores
siguen correspondiendo al juego de cinco pistas. No se publicó código en GitHub.

# Auditoría de evolución — 13 septiembre 2026

## A. Estado y alcance

Godot 4.3 Compatibility, Android horizontal, cuatro corredores, seis tapas activas,
quince pistas y cinco copas persistentes. Escena principal `ui/main_menu.tscn`;
carrera compartida `levels/race.tscn`. UI construida con scripts y Containers.
Base auditada: main `1e32d42`, con los cambios recientes ya publicados.
Godot AI está instalado pero no habilitado en project.godot; esta sesión no dispone
de herramientas MCP Godot. La inspección combina archivos, CLI y ejecución real;
no se afirma haber inspeccionado el editor mediante MCP.

## B–D. Inventario: existente, parcial y faltante

| Sistema | Estado y reutilización |
|---|---|
| Estructura/escenas | Separación de actors, input, physics, race, resources, visuals, UI y servicios. |
| Carrera | RaceSession: salida, clasificación, checkpoints ordenados, vueltas, meta. |
| Tapas | CapDefinition y CapAppearance; seis activas, catálogo ampliado preparado sin migrar. |
| Física | CapMotion/CapPhysicsConfig: corriente, aceleración, control, peso, rebote, fricción e impulso. |
| Controles | Dirección sostenida, swipe lateral y turbo; NO existe arrastrar/apuntar/soltar con potencia. |
| Pistas | Recursos ligeros y carga diferida del trazado, obstáculos/corrientes/saltos reutilizables. |
| IA | Un controlador, seis personalidades, cuatro dificultades, perfiles de bosses, recuperación válida. |
| Cámara | Anticipación, seguimiento suave, shake acotado, zoom por velocidad/turbo/meta. |
| UI/Garage | Menú, retratos, swipe, barras y compra/equipamiento; nivel y mejorar deshabilitados. |
| Copas | Cinco copas, 22 carreras, clasificación acumulada, reanudación y premio único por podio. |
| Mapa visual | cup_route, circuit_preview y track_selection existen pero no están integrados al menú. |
| Bosses | Perfiles compartidos e intro de final; sin fases ni habilidades individuales activas. |
| Audio | AudioManager, seis categorías, voces acotadas y recursos WAV reutilizables. |
| Partículas | WaterVFXPool 48/96; ráfagas, estelas, ondas, impactos, turbo y aterrizajes. |
| Progreso/guardado | SaveManager JSON v1, backup, monedas, compras, récords, copas y rollback. Sin XP/niveles. |
| Habilidades | Turbo activo; escudo/recarga automáticos al recoger. Recursos futuros no equivalen a ejecución. |
| Assets | Arte de tapas y agua procedural, icono SVG, audio local; sin nuevos assets externos en esta fase. |
| Android | APK ARM64/x86_64 debug, controles multitáctiles, safe areas, pausa/foco y haptics configurables. |
| Rendimiento | IA medida <0,1 ms/decisión en PC. Calidad alta no estable; falta dispositivo físico. |
| Nuevos sistemas | Perfect Shot, combos, ghost, photo finish, XP, mejoras, desafíos, ranking y eventos faltan. |

## E. Riesgos técnicos

- La mecánica de lanzamiento propuesta difiere de la carrera continua actual. Debe prototiparse
  como acción acotada, sin sustituir los controles ni aplicar bonos económicos antes de validar.
- Tres vueltas pueden superar 120 s: la duración objetivo requiere decidir formato por copa.
- Las estrellas actuales son presentación del puesto, no un histórico persistente por pista.
- No se puede prometer precisión de photo finish de milisegundos con llegadas muestreadas a 60 Hz.
- La calidad alta registró caídas importantes en PC. No extrapolar esos FPS a teléfonos.
- El emulador sufre conflictos entre ADB 32 del sistema y ADB 41 local; la compilación no prueba arranque.

## F. Deuda técnica

- PROJECT_CONTEXT y el reporte principal todavía describían solo la etapa F.
- SelectionPage conserva la selección antigua de tapas junto al Garage activo; consolidar después de pruebas.
- CapVisual/prototype_channel y componentes de mapa no conectados necesitan clasificación antes de borrarlos.
- RaceTrack dibuja decoraciones de todo el circuito desde un solo nodo; candidato a partición visual y culling,
  pendiente de medición comparativa. No cambiar colisiones al optimizar dibujo.
- El export incluía el addon de herramientas de desarrollo. Excluirlo del paquete del juego.

## G. Arquitectura recomendada

Conservar RaceSession, CapMotion, AIProfile, CapDefinition, SaveManager, AudioManager y WaterVFXPool.
Usar señales desde acciones realmente aplicadas para presentación, combos y futura puntuación.
Extender el guardado versionado con migraciones y transacciones; no crear otro PlayerProfile paralelo.
Activar habilidades mediante componentes y recursos existentes, con estado por corredor.
Ghost: muestreo acotado de transformaciones, reproducción sin colisiones y clave de versión de pista.
Desafíos: condiciones/recompensas declarativas, sin backend en esta etapa.

## H–I. Prioridad y cambios inmediatos

1. Verificar runtime y builds; mantener pruebas de checkpoints, guardado y controles.
2. Completar huecos de feedback sobre las señales existentes. Primer módulo: swipe aplicado.
3. Separar herramientas de editor del APK y actualizar el contexto del proyecto.
4. Prototipar Perfect Shot sin XP ni bonos de velocidad; validar comprensión y compatibilidad táctil.
5. Integrar mapa ya preparado antes de crear más pantallas; después progreso y habilidades.

## J. Roadmap orientativo

Estimaciones en ciclos de implementación + ejecución + corrección, no fechas de entrega.

| Fase | Alcance restante | Ciclos estimados |
|---|---|---|
| 1 | Auditoría, límites MCP y línea base | 1 |
| 2 | Huecos de feedback y validación Android | 2–3 |
| 3 | Prototipo y clasificación Perfect Shot | 2–4 |
| 4 | Consolidar stats y migración del catálogo | 2–3 |
| 5 | Activar habilidades con balance y pruebas | 4–6 |
| 6 | Garage: integrar mejoras reales y comparación | 2–3 |
| 7 | XP, niveles y economía transaccional | 3–5 |
| 8 | Integrar mapa visual y progreso de copas | 2–4 |
| 9 | Comportamientos de boss sobre IA común | 2–4 |
| 10 | Combos acotados y feedback | 2–3 |
| 11 | Grabación/reproducción ghost y presupuesto | 3–5 |
| 12 | Desafíos declarativos y persistencia | 2–4 |
| 13 | Perfilado en teléfonos y optimización visual | 3–6 |
| 14 | Balance humano, accesibilidad y pulido | 3–6 |

No iniciar todas las fases simultáneamente. Reestimar después del prototipo de lanzamiento.

## Ejecución de fase 2 — 14 septiembre

- Swipe: feedback solo cuando se aplica el impulso; fuerza y cooldown conservados.
- Export: Godot AI permanece en el repositorio pero no se incluye en los APK.
- Ondas estáticas: trasladadas al WaterSurface existente y limitadas al viewport;
  las colisiones, bancos y obstáculos no cambian. Queda pendiente estudiar las
  decoraciones de orilla si el perfilado móvil lo requiere.
- Medición PC 1280×720 con cuatro corredores: antes 1.073–1.236 draw calls,
  después 248–398. Las ocho muestras posteriores dieron 60 FPS en baja/alta.
  No es una garantía de rendimiento en teléfonos ni una comparación de trayectorias idénticas.
- Pruebas: swipe headless/render, límites de ondas en tres resoluciones y
  comienzo/medio/meta, carreras completas y tres vueltas: cero fallos finales.
  Evidencias: builds/logs/audit-swipe-final.log, audit-swipe-render.log,
  audit-water-culling.log, audit-game-culling.log y audit-render-culling.log.
- APK 0.2.0 ARM64/x86_64 regenerados y firmas verificadas. Instalación conservando
  datos y apertura en TapaRacing_Test comprobadas; menú, preparación, carrera y pausa
  visibles a 1280×720. No se certifica una carrera completa manual en Android.
- Limitación pendiente: SwiftShader registra exceso de uniforms al compilar
  SceneShaderGLES3; el juego 2D se dibuja, pero los tiempos EGL observados rondan
  150–250 ms por cuadro. También aparece can_process fuera del árbol al navegar.
  No hay SCRIPT ERROR ni FATAL EXCEPTION en el log del proceso revisado.
  Investigar las transiciones y repetir con GPU acelerada/teléfono antes de aprobar
  rendimiento Android. Evidencia: builds/logs/audit-android-runtime.log.
- Emulador recuperado sin borrar datos: crash-report-mode disabled, no-metrics,
  puertos 5574/5575, ADB local puerto 5045 hacia 127.0.0.1:5575; override 720×1280.

## Fase 3 — Perfect Shot (implementado, sin validar)

- Se clasifica el gesto lateral existente al superar su umbral de 65 px antes de
  300 ms; no se cambia a lanzamiento por arrastrar y soltar. Perfect: hasta 140 ms
  y alineación horizontal ≥0,96; Great: 210 ms/0,90; Good: 280 ms/0,75; resto Weak.
  Valores configurables en Resource y provisionales hasta las pruebas de juego.
- La señal de clasificación se emite solo al aplicar un impulso fuera del cooldown.
  La lectura consume también su calificación; limpiar controles elimina ambos datos.
  HUD, audio, vibración opcional y partículas reutilizados, sin bonus físico ni XP.
- Por petición del usuario no se ejecutan pruebas, juego ni exportaciones en esta
  etapa. Al cierre validar gestos diagonales/rápidos/lentos, multitouch, cooldown,
  pausa/salida/meta, prioridades del HUD y rendimiento/responsive en Android.

## Fase 4 — Estadísticas (implementado, sin validar)

- CapDefinition configura velocidad, aceleración, control, peso, turbo, rebote,
  fricción, estabilidad e impulso lateral; resolve_physics genera la configuración
  efectiva sin mutar el recurso base. Los cuatro multiplicadores nuevos valen 1.
- Estabilidad significa amortiguación lateral del agua. No introduce salud ni
  resistencia al daño. El límite de velocidad y las ecuaciones de movimiento siguen
  en CapPhysicsConfig/CapMotion; los ratings 1–10 no sustituyen valores físicos.
- Se evita aplicar dos veces multiplicadores al cambiar una definición: los rivales
  de copa usan su tapa final desde la base, sin acumular la provisional. Esta corrección
  puede modificar su rendimiento anterior y requiere revisar el balance al cierre.
- Garage consume índices desde CapDefinition y muestra rebote/fricción/estabilidad/
  impulso calculados con la misma base que player_cap.tscn. Turbo reemplaza el N/D.
- IDs, precios, partidas y catálogo activo conservados. Activación de las 18 tapas
  aplazada a su integración de habilidades/desbloqueos. No se ejecutaron pruebas ni
  exportación; revisar valores heredados, reemplazo de definiciones, copas, límites
  del Garage y guardado junto a las demás fases al finalizar el desarrollo.

## Fase 5 — Habilidades del catálogo activo (sin validar)

- Estado por corredor en CapAbilityRuntime: duración, cooldown, usos y disparadores;
  recursos compartidos inmutables. Configuración mediante los seis recursos ya
  definidos para los equivalentes de las tapas actuales, conservando IDs y compras.
- Sol: aceleración inicial; Coral: recuperación tras impacto; Menta: menor fuerza
  lateral de corrientes; Océano: velocidad tras adelantar; Uva: turbo más corto y
  potente; Coco: reducción temporal del empuje recibido después de un impacto.
- IA y jugador usan las mismas condiciones. Posiciones muestreadas a 6,7 Hz con
  standings existente. No hay búsquedas globales, nodos de efectos por activación,
  botones adicionales ni colisiones desactivadas. El escudo recogido sigue igual.
- Habilidades automáticas visibles en HUD/Garage con VFX, audio y haptics existentes.
  Aplazadas las doce habilidades del catálogo no activo y sus eventos específicos.
- Sin ejecución ni exportación por petición del usuario. Al cierre: comprobar
  duración/cooldown/usos, pausas, intro/countdown/meta, solapamientos de corrientes,
  turbo + powerups, adelantamientos/recuperaciones y balance de las seis tapas.

## Fase 6 — Garage (integración visual, sin validar)

- Comparación de velocidad, aceleración, control, peso y turbo frente a la tapa
  equipada, incluso en tapas bloqueadas. Diferencias numéricas neutrales: el peso
  no se presenta como una mejora universal. Equipar actualiza la referencia.
- Botón HABILIDAD/ESTADÍSTICAS para alternar descripción real y parámetros de
  movimiento; conserva el modo al recorrer tapas. Retrato, swipe, flechas, compra,
  equipamiento y apariencia Perla reutilizan los sistemas existentes.
- Dependencia pendiente: activar MEJORAR después de implementar niveles y economía
  transaccional en fase 7. No se ofrecen compras de mejoras sin efecto.
- Sin pruebas ni compilación. Al cierre validar comparación tras equipar/compra,
  guardado fallido, cambios rápidos, descripciones largas y tamaños Android.

## Fase 7 — Progresión y mejoras (sin validar)

- XP individual por tapa: 30/24/18/12 por llegada en las cuatro posiciones; una ronda
  de copa no terminada no da XP. No se consume la XP al mejorar ni se concede por
  abandonar. Sin XP retroactiva para resultados de partidas antiguas.
- Cinco niveles; XP acumulada 0/100/250/450/700 y costes de mejora 100/175/250/350
  monedas. Aceleración y control ganan 1% de la base por nivel, máximo 4%; velocidad
  máxima y habilidades no escalan. Valores provisionales en Resource compartido.
- MEJORAR activo en Garage con coste/requisitos; comparación de estadísticas con
  niveles actuales. El jugador recibe su nivel al iniciar; NPC conservan nivel base.
  Nivel y XP individual visibles en menú, Garage y resultados.
- Guardado esquema 2, misma ruta: lectura de versiones 1/2, saneamiento de progreso
  por IDs desbloqueados y límite del nivel según XP. Copas guardan XP junto a ronda
  y recompensa. Resultados libres revierten monedas/XP/récord ante fallo y ofrecen
  reintento; el controlador evita volver a acreditar un resultado ya guardado.
- Sin pruebas ni exportación. Validación final pendiente: migración/backup, datos
  malformados, guardado fallido/reintentos, compra y doble toque, límites de nivel,
  copas repetidas/DNF, balance frente a NPC base, layout y compatibilidad Android.

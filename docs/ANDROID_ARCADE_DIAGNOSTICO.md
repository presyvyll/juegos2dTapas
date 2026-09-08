# Diagnóstico técnico y visual · Android arcade

Base revisada: commit `d8ed704`, Godot `4.3.stable.official.77dcf97d8`.
Esta entrega cubre el análisis y el plan previo a la implementación. El nuevo
alcance es exclusivamente Android. No se cambia el motor ni la jugabilidad.

## Conclusión

La base jugable es reutilizable. El mayor salto de calidad vendrá de una capa
visual expresiva, feedback de agua/impactos y una jerarquía de interfaz más clara.
No hace falta reescribir física, carreras, IA ni guardado para conseguirlo.

## Mapa del proyecto y estado

| Sistema | Archivos principales | Diagnóstico |
| --- | --- | --- |
| Entrada y menús | `ui/main_menu.tscn`, `scripts/ui/` | Funcionales; presentación estática y botones con jerarquía similar. UI construida por código. |
| Carrera | `levels/race.tscn`, `scripts/levels/race.gd` | Compone pista, cuatro tapas, checkpoints y HUD; buen lugar para conectar eventos visuales. |
| Tapa | `scenes/actors/player_cap.tscn`, `scripts/actors/cap.gd` | Composición aprovechable, pero el actor aún escribe directamente la escala, posición y giro del visual. |
| Física | `scripts/physics/cap_motion.gd` | Arcade, corriente automática, resistencia y rebote. Mantener sus valores durante el primer bloque visual. |
| Turbo | `cap.gd`, `cap_physics_config.gd` | Ya existe: energía, recarga, impulso, multiplicador, sonido y vibración. Duración/coste/recarga aún están fijados en código. |
| Controles | `scripts/input/player_input.gd` | Touch, drag, segundo dedo para boost, limpieza de toques y teclado de prueba. No son exclusivamente de teclado. |
| IA | `scripts/input/ai_controller.gd` | Tres rivales, decisiones a 5 Hz, rutas, obstáculos, errores y boost. No requiere reescritura visual. |
| Progreso | `scripts/race/` | Checkpoints ordenados, vueltas, clasificación y resultados implementados. |
| Pista | `scripts/levels/race_track.gd` | Dos pistas parametrizadas; buena separación entre geometría y carreras. Apariencia repetitiva y plana. |
| Agua/obstáculos | `scripts/water/`, `scripts/obstacles/` | Corrientes, remolinos, chorros, desniveles y cinco obstáculos. El movimiento físico supera al feedback visual. |
| Cámara | `scripts/camera/race_camera.gd` | Seguimiento suave, anticipación y zoom de turbo existentes. Sin impacto, entrada ni celebración. |
| Apariencia | `cap_visual.gd`, `cap_preview.gd` | Las seis tapas comparten silueta y símbolo T; se distinguen principalmente por color. Dibujo duplicado entre juego y selector. |
| Datos | `scripts/resources/`, `data/` | Resources bien encaminados; falta apariencia, personalidad y habilidad. Catálogo y guardado enumeran IDs en código. |
| Audio/guardado | `scripts/services/` | Seis voces acotadas, volúmenes, persistencia y respaldo. Audio provisional; vibración desactivable. |
| Resolución | `project.godot`, `ui_style.gd` | Landscape, 1280 × 720, canvas_items/expand, márgenes seguros. Falta validar toda la matriz Android solicitada. |
| Exportación | `export_presets.cfg`, `tools/` | APK ARM64 de depuración existente. Sin perfil AAB/Gradle listo. El script de compilación también genera Windows. |

## Problemas y límites concretos

1. **Identidad visual débil:** no hay expresiones, patrones ni accesorios. Las
   tapas miden aproximadamente 46 unidades de diámetro y tienen poco detalle
   reconocible. Aumentar legibilidad visual sin alterar inicialmente los colliders.
2. **Impactos poco perceptibles:** `wall_hit` solo entrega intensidad. Para una
   salpicadura direccional faltan punto, normal y tipo de contacto. No hay ondas,
   estelas, flashes ni squash de colisión; el salto solo escala/desplaza el dibujo.
3. **Conflicto potencial de animación:** agregar tweens sobre `Visual.scale` se
   enfrentaría a la asignación de cada frame en `cap.gd`. Primero crear un
   controlador visual que componga salto, impacto, turbo y celebración.
4. **Sustitución de arte no completamente transparente:** el actor espera una
   propiedad `tint`. Reemplazar directamente Visual por Sprite2D rompería ese
   contrato. Mantener un nodo contenedor visual con interfaz estable.
5. **Turbo parcialmente configurable:** coste 0.45, duración 0.9 s, recarga
   0.105/s y multiplicador 1.6 están en el actor. Pasarlos a un Resource conservando
   exactamente esos valores antes de ajustar sensaciones.
6. **Respuesta táctil:** la entrada se recibe por eventos, pero disponibilidad y
   rectángulo del boost se actualizan desde el HUD a 10 Hz. Puede haber hasta
   unos 100 ms de desfase al habilitarlo o tras redimensionar. Separar la entrada
   del refresco informativo del HUD. Revisar también pausa con otro dedo activo.
7. **Escalabilidad incompleta de tapas:** añadir un Resource requiere cambiar
   listas en `catalog.gd` y `save_manager.gd`. Usar un catálogo de datos compartido
   y preservar los IDs existentes para no perder desbloqueos.
8. **Rendimiento no acreditado en Android:** no hay teléfono conectado. El modo
   bajo solo omite plantas; no define todavía presupuestos de VFX ni shaders.
   Toda la pista se dibuja en un nodo; animarla con redraw completo cada frame
   sería un riesgo. Separar agua animada y efectos locales de geometría estática.
9. **Inicio/final funcionales pero sin espectáculo:** cuenta atrás textual y panel
   de resultados. No hay animación de entrada, celebración ni cámara del ganador.
10. **AAB pendiente:** el APK actual usa plantilla sin Gradle y target SDK 34.
    Preparar un flujo Android separado para AAB; revisar requisitos vigentes de
    Google Play y bibliotecas nativas antes de considerarlo publicable. No basta
    cambiar la extensión del APK. Conservar la clave de depuración existente.

Se observó configuración histórica de otras plataformas. No se modificó ni se
ejecutó durante esta auditoría; queda fuera del nuevo desarrollo Android.

## Dirección artística original propuesta

Un torneo de tapas en una fuente de barrio: contornos oscuros, caras grandes,
patrones claros y salpicaduras gráficas. Agua turquesa como fondo; amarillo/coral
para acciones y violeta para poderes. Mantener la pista despejada y limitar los
flashes. La energía arcade vendrá del ritmo, anticipación y contraste, con
gráficos, expresiones, textos y sonidos propios.

Personalidades iniciales propuestas: Sol equilibrada, Coral atrevida, Menta ágil,
Océano tecnológica, Uva elegante y Coco excéntrica. Son direcciones visuales;
no implican cambiar todavía sus estadísticas.

## Plan priorizado

| Prioridad | Bloque | Resultado y criterio de cierre |
| --- | --- | --- |
| Alta · primero | Apariencia compartida y feedback | `CapAppearance` Resource y `CapPresentation` en un contenedor estable; seis identidades, squash, salpicadura y estela. Mismas colisiones, tiempos y controles que la base. |
| Alta | VFX con reutilización | Pool acotado de impactos/ondas; efectos fuera de pantalla omitidos. Presupuesto inicial propuesto: 12 ráfagas y 96 partículas en alta, 6/48 en baja; ajustar con medición, no tratarlo como garantía de FPS. |
| Alta | Turbo y entrada | Configuración reutilizable, señales de activación/final, botón cómodo y segundo dedo independiente del HUD. Pruebas de energía, pausa, pulsaciones rápidas y recarga. |
| Alta | HUD e inicio | Posición destacada, progreso, turbo y espacio reservado para poder; ocultar instrucciones de teclado en Android. 3–2–1–¡CORRE! con escala y splash reutilizados. |
| Alta | Resoluciones y cámara | Capturas/pruebas a 1280×720, 1440×720, 1560×720 y 1600×720, más 2340×1080/2400×1080. Shake corto y limitado, zoom sin ocultar obstáculos; validar notch/DPI físicamente. |
| Media | Menú, selector y victoria | Jugar con mayor peso visual, misma apariencia en selector/carrera, atributos legibles, celebración y cámara del ganador después de terminar el jugador. |
| Media | Escenario vivo | Agua animada independiente, espuma de chorros y remolinos legibles; decoraciones fuera de las rutas. Medir antes de añadir shaders complejos. |
| Media | Power-ups reutilizables | Resource de definición, pickup, controlador de efectos con duración/expiración y señal al HUD. Empezar con recarga de turbo y escudo; sin apilar multiplicadores ilimitados. |
| Media | AAB y validación Android | Separar compilación Android del flujo antiguo, preparar Gradle/AAB y verificar firma/paquete. Sin publicación ni rotación de claves. |
| Baja | Expansión | Más accesorios, poderes ofensivos, logros, tienda visual y rankings, una vez estables lectura y rendimiento. |

Los componentes propuestos son adiciones locales. No se moverán carpetas ni se
eliminarán escenas funcionales por estética organizativa. Los VFX escucharán
señales; la física conservará la autoridad sobre colisiones y movimiento.

## Assets para producción artística

Dimensiones iniciales recomendadas, a confirmar tras el primer pase visual:

| Asset propuesto | Formato y tamaño | Uso |
| --- | --- | --- |
| `cap_<id>_body` y `cap_<id>_face` | PNG transparente 256×256 por capa, pivote común | Seis tapas; silueta clara a 48–64 unidades lógicas. |
| `cap_<id>_portrait` | PNG 512×512 | Selector y resultados; puede derivarse de las capas. |
| `water_fx_atlas` | PNG 512×512, celdas 64×64 | Gotas, burbujas, ondas, espuma y estelas. |
| `arcade_impact_atlas` | PNG 512×512, celdas 128×128 | Impacto, turbo y celebración; pocas transparencias superpuestas. |
| `powerup_icons` | PNG 128×128 por icono | Turbo y escudo iniciales. |
| `track_tiles` / `track_props` | PNG 256×256 y 128–256 px | Agua repetible, bordes, hojas, piedras y objetos urbanos. |
| `ui_panels` | PNG 256×256 con márgenes de nine-patch | Paneles originales y escalables. Textos como Label, no incrustados. |
| Audio de carrera | Fuentes WAV; música/ambiente en formato apropiado tras medición | Inicio, colisión, turbo, pickup y victoria originales. |

Conservar los placeholders actuales como referencia. El primer bloque puede
usarlos mejorados mediante dibujo procedural; no depende de un artista ni de
descargar assets externos. No se requiere crear imágenes raster en esta auditoría.

## Verificación de esta auditoría

- Versión instalada comprobada: Godot 4.3; repositorio limpio al comenzar.
- Prueba `tests/test_game.gd` ejecutada nuevamente: cero fallos, incluyendo las
  dos carreras completas, entradas, compras, respaldo, vueltas y recompensa única.
- `tests/capture_screens.gd` ejecutado con render real Compatibility; revisados
  menú, tapas, carrera y resultados. Las capturas son de presentación controlada,
  no una medición de latencia ni una partida manual en Android.
- La matriz histórica de 38 carreras está documentada; no se repitió aquí al
  no haber cambios de jugabilidad. No se confunde con validación de rendimiento.
- ADB no detectó dispositivos. 60 FPS, densidades físicas, haptics y requisitos
  de distribución permanecen pendientes de pruebas específicas.

## Cierre de fases

**Fase 1:** inspección completada. **Fase 2:** diagnóstico documentado.
**Fase 3:** plan priorizado preparado. **Fase 4:** aún no iniciada, respetando la
petición de presentar primero el diagnóstico.

Archivo creado: `docs/ANDROID_ARCADE_DIAGNOSTICO.md`. No se modificaron scripts,
escenas, assets, configuración ni claves. No se crearon escenas o scripts nuevos
de juego. No aparecieron errores de ejecución en las pruebas realizadas; las
carencias y riesgos anteriores siguen pendientes de implementación.

Siguiente bloque concreto: apariencia reutilizable de tapas, respuesta visual
de impacto y turbo con pool pequeño de efectos, conservando los parámetros
actuales de física y verificando regresiones antes del rediseño del HUD.

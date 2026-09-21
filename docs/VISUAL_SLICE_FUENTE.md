# Fuente Central: entorno, iteración 1 (20 septiembre 2026)

Dirección: cartoon procedural, agua turquesa, piedra crema y jardines verdes.
La carrera compartida y Sol son la referencia. Esta iteración mejora exclusivamente
el paseo exterior de Fuente Central: pavimento, jardineras elevadas, sombras,
vegetación animada y desplazamiento relativo limitado de las copas de los árboles.

RaceTrack crea un único nodo fountain_environment para el ID fuente, detrás de
la pista. No añade cuerpos físicos ni modifica cámara, controles o guardados.
El dibujo se limita a las filas del viewport más un margen; actualización 10 Hz
en baja, 20 Hz en alta. Reutiliza Theme/CanvasItem del proyecto, sin texturas nuevas,
luces ni postprocesado. Parallax decorativo limitado a 24 unidades fuera del canal.

Validación: test_all_courses (15 pistas, ambas calidades), test_water_culling y
test_race_render con capturas inspeccionadas. Cero errores en estas pruebas.
GTX 1650, 1280x720, cuatro muestras por calidad en la última ejecución:
- Baja: 60 FPS, 304–329 draw calls, memoria estática alrededor de 59,6 MB.
- Alta: 60 FPS, 503–509 draw calls, memoria estática alrededor de 59,7 MB.
- Base observada antes del cambio: 260–290 llamadas en baja, 353–395 en alta.
Las escenas móviles varían entre muestras; no es un benchmark determinista.
Una ejecución intermedia registró 56 FPS en una muestra de alta.
Estas medidas no acreditan 60 FPS en Android ni coste GPU en teléfono.

## Estela de turbo, iteración 3

CapPresentation conserva una trayectoria global corta durante el turbo y la dibuja
en dos líneas del color propio de cada apariencia: halo ancho y núcleo luminoso.
La primera muestra se extiende 38 unidades detrás de la velocidad para responder
en el mismo instante, incluso con pocos frames. El historial queda limitado a 9
puntos en baja y 16 en alta, desaparece en 0,38 segundos y añade como máximo dos
draw calls por tapa que esté acelerando. El pool existente sigue aportando espuma;
no se crean nodos, tweens, partículas ni recursos durante la carrera.
La carrera móvil automatizada mantuvo 60 FPS en las ocho muestras posteriores:
315–340 draw calls en baja y 445–523 en alta, con cuatro corredores e IA activa.

## Agua, iteración 2

WaterSurface añade en el parche visible una banda central profunda, dos bordes
someros y dos líneas de corriente. La opacidad máxima es 13% y los elementos se
dibujan antes que ondas y lluvia para preservar la lectura de rocas, recogibles y
corredores. Son un polígono y cuatro polilíneas compartidas por actualización, sin
shader, viewport texture ni nodos adicionales. La captura final confirmó contraste
claro de obstáculos en baja y alta. Medición final: 268–334 draw calls en baja y
393–508 en alta, 59–61 FPS en PC; el rango incluye IA, partículas y cámara móvil.

Graphify consultado antes/después y actualizado. La versión instalada omite .gd:
su grafo documental no verifica las nuevas dependencias GDScript.
Serena/Godot MCP no estaban disponibles.

## Hit flash, iteración 4

Los impactos de fuerza 120 o superior activan un destello blanco cálido sobre la
ilustración completa del corredor. HitFlashEffect es reutilizable con cualquier
CanvasItem y asigna una instancia de material por objetivo; el shader compartido
sólo hace una mezcla de color. El destello dura entre 0,055 y 0,09 segundos según
la fuerza y actualiza el uniforme únicamente mientras está activo. No crea nodos,
partículas ni tweens durante la carrera y no modifica física o colisiones.
La captura dedicada confirmó el flash sólo en el objetivo sobre agua turquesa.
Validación final: test_race_feedback, test_arcade y 15 circuitos en baja/alta sin
fallos. La carrera móvil mantuvo 60–61 FPS en PC: 338–355 draw calls en baja y
495–523 en alta, con unos 59,7 MB de memoria estática. Falta medir en Android.

## Microinteracciones HUD, iteración 5

El cambio de posición ahora comunica dirección: al adelantar, el puesto crece y
pulsa en verde agua; al perder posición, se comprime y vira brevemente a coral.
El resumen de vuelta recibe un pulso dorado independiente y los recogibles hacen
aparecer una confirmación coloreada sobre la carga de turbo. Esta confirmación
tiene prioridad durante 1,5 segundos y después devuelve la cuenta de la burbuja.
Las animaciones sólo crean tweens al ocurrir el evento, respetan la pausa y no
añaden nodos ni procesamiento continuo. Se amplió el ancho reservado del puesto
para impedir solapamientos durante el pulso.
La captura final confirmó lectura limpia a 1280x720. Las cinco relaciones de
aspecto, controles táctiles y feedback pasaron sin fallos. Medición móvil en PC:
60–61 FPS, 303–354 draw calls en baja y 478–523 en alta, unos 59,6–59,9 MB.

## Meta y resultados, iteración 6

Al cruzar la meta, una sola capa procedural dibuja durante 0,85 segundos un aro,
rayos y confeti centrados en el corredor. La densidad baja de 20 a 12 piezas en
calidad baja y de 12 a 8 para puestos fuera de la victoria; el refresco también
se limita a 30 Hz en baja. El efecto conserva el anuncio, vibración, cámara y VFX
existentes, y desaparece antes de dejar el panel interactivo asentado.

El resultado ahora prioriza retrato y puesto del jugador, seguido por tres tarjetas
de tiempo, monedas y XP. Récord, combo, nivel, ghost y clasificación quedan en un
segundo nivel, con el jugador marcado por una flecha. Las dos acciones finales se
presentan en paralelo y el panel reduce su altura para eliminar espacio vacío.
La recompensa continúa guardándose antes de iniciar la transición visual.
Las capturas finales de celebración y panel fueron inspeccionadas a 1280x720. El
estallido estabilizado mantuvo 60 FPS y 453 draw calls en alta. La carrera normal
midió 60 FPS, 281–342 draw calls en baja y 475–529 en alta, con unos 59,8–59,9 MB.
Feedback, layouts generales y layouts de copa pasaron en cinco resoluciones.

## Anticipación de obstáculos, iteración 7

Rocas, ramas, islas y obstáculos móviles reciben una capa visual compartida que
dibuja una base de espuma y dos chevrones antes de la zona sólida. Los móviles
añaden su recorrido lateral discontinuo, extremos de trayectoria y una estela que
indica el sentido actual. Todo se dibuja detrás del obstáculo y queda separado de
la colisión; no cambia radios, posiciones, frecuencia ni espacio navegable.

Cada obstáculo usa un solo CanvasItem. Sólo los móviles se actualizan y reutilizan
AmbientMotion: culling fuera de cámara y refresco a 10 Hz en baja o 20 Hz en alta.
La captura de Neon confirmó lectura del barrido sobre agua oscura sin competir con
el pickup. Los 15 circuitos pasaron en ambas calidades y mantuvieron sus márgenes.
Medición final de carrera: 60 FPS y 272–340 draw calls en baja; 59–62 FPS y
470–516 en alta, con unos 59,7–59,9 MB de memoria estática en PC.

## Contacto con orillas, iteración 8

Las paredes del canal se identifican ahora como grupo visual sin modificar sus
segmentos ni capas físicas. RacingCap emite un evento limitado a 10 Hz cuando la
tapa roza una orilla con fuerza superior a 8. El rozamiento produce tres trazos
breves de espuma y una vibración horizontal máxima de 1,6 px; contactos de fuerza
120 o superior dibujan una doble onda orientada hacia el canal y conservan el hit
flash, partículas, sonido, cámara y hápticos ya existentes.

Los efectos usan dos tipos nuevos dentro del mismo WaterVFXPool de capacidad fija.
No crean nodos durante la carrera, se descartan fuera de cámara y se apagan con el
pool. Las capturas de Fuente Central confirmaron que espuma, onda y corredor siguen
legibles sobre agua y piedra sin convertir el roce suave en un impacto fuerte.
La carrera de referencia mantuvo 60 FPS: 284–341 draw calls en baja y 465–522 en
alta, con 59,8–60,0 MB de memoria estática en PC.

## Anticipación de agua, iteración 9

Las corrientes dibujan ahora fuera de su collider una línea de entrada discontinua
y chevrones de aproximación. El código de color distingue impulso turquesa,
ralentización coral y corriente neutra clara; las zonas rápidas usan doble chevrón.
Las franjas de salto reciben avisos dorados antes del desnivel.

Los remolinos conservan sus espirales animadas y suman perímetro de peligro dorado,
dos chevrones frontales y un núcleo oscuro que aclara la dirección de riesgo. No se
añaden procesos a corrientes estáticas ni se modifican fuerza, radio, collider,
velocidad máxima o pulsos. Las capturas de Canal Turbo y Remolino confirmaron que
las señales se leen antes de entrar y no tapan corredores ni recogibles.
Medición final: 60 FPS, 281–314 draw calls en baja y 503–523 en alta, con
59,9–60,2 MB de memoria estática en PC. Culling de agua y feedback sin fallos.

## Arranque y trazada inicial, iteración 10

La salida incorpora una parrilla ajedrezada, cuatro cajones visuales y una guía
dorada que sigue el centro de la primera curva. Dibujo y gameplay comparten ahora
`RaceTrack.starting_slot`, manteniendo exactamente las posiciones previas.

El HUD añade un semáforo de tres luces sincronizado con el countdown existente,
una instrucción breve y una composición vertical que deja libre la fila de tapas.
En cero las luces cambian a turquesa, aparece «¡SALIDA LIMPIA!» y las cuatro tapas
producen espuma de lanzamiento mediante el pool existente. No cambia la duración
3–2–1–0 ni el frame en que se activan controles, IA y física.

La parrilla vive en un CanvasItem independiente para que el renderer la descarte
al quedar fuera de cámara. La carrera midió 318–346 draw calls en baja y 462–511
en alta, con unos 60,3–60,5 MB de memoria estática en PC. Esta sesión quedó
limitada globalmente a 30 FPS: una escena de menú independiente también marcó
30 FPS con sólo 87 draw calls, por lo que el frame rate no permite atribuir una
regresión a esta iteración. Feedback, circuitos y layouts se validaron sin fallos.

Pendiente: medir en Android y reducir llamadas de decoración mediante agrupación
o sprites si el presupuesto del dispositivo lo exige. Próxima mejora visual:
refuerzo visual de checkpoints y progreso entre secciones del circuito.
La vertical slice completa (HUD, resultados, etc.) aún no se declara terminada.

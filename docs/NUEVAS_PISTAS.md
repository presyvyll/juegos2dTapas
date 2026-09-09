# Cinco pistas de carreras

Documento histórico de las primeras cinco pistas. El catálogo actual contiene
[quince circuitos](ETAPA_D_CIRCUITOS.md); consultar ese documento para orden y acceso.

## Contenido disponible

| Pista | ID estable | Dificultad del recorrido | Precio | Elementos / sólidos |
| --- | --- | --- | --- | --- |
| Fuente Central | fuente | Inicial | Gratis | 10 / 6 |
| Canal Tropical | tropical | Media | 100 monedas | 28 / 10 |
| Remolino Azul | remolino | Media-alta | 150 monedas | 25 / 9 |
| Cascada Extrema | cascada | Alta | 200 monedas | 27 / 11 |
| Tormenta Caribeña | tormenta | Alta | 250 monedas | 28 / 12 |

Las cinco se encuentran en **CIRCUITOS**, en ese orden, y usan la preparación de
carrera existente (dificultad de IA y una a tres vueltas). Cada recorrido mide
18 000 unidades y contiene doce checkpoints, siendo el último la meta.

- **Fuente Central:** curvas amplias, seis rocas pequeñas, canal ancho y corrientes
  sin turbulencia. Sustituye el trazado de Fuente Caribe.
- **Canal Tropical:** hojas, ramas, estrechamientos, corrientes laterales y tres
  islas con pasos de distinta anchura.
- **Remolino Azul:** ocho remolinos, seis obstáculos móviles y alternancia de
  zonas lentas y rápidas; agua azul.
- **Cascada Extrema:** cinco saltos, siete chorros diagonales, once obstáculos
  sólidos y cambios de velocidad en curvas más cerradas. Sustituye Canal Cascada.
- **Tormenta Caribeña:** lluvia, agua oscura, objetos flotantes, cuatro islas y diez
  zonas de corriente con velocidad e intensidad distintas y turbulencia temporal.

Los caminos alternativos son pasos por ambos lados de islas dentro del canal,
con diferente margen de maniobra; no son bifurcaciones independientes ni permiten
omitir checkpoints. Se reutilizan arte procedural, música y componentes existentes.

## Arquitectura y configuración

`data/catalog.tres` registra los cinco `CircuitDefinition`; el selector los lee
sin listas específicas en la interfaz. Cada circuito contiene Resources
`CircuitFeature` que referencian escenas compartidas y definen distancia, posición
lateral y ajustes de roca, corriente, remolino u obstáculo móvil.

Los valores cero de los ajustes originales conservan el valor predeterminado;
turbulencia, atracción y desplazamiento usan -1 para conservarlo y permiten cero.
No se duplicaron escenas ni se cambió la integración de físicas. Los defaults de
hojas, chorros, saltos y obstáculos móviles se asignan antes de su configuración.

`RaceTrack` genera orillas y coloca componentes. `RaceSession` conserva vueltas,
orden de checkpoints, meta y premios. Los pickups escalan su posición con la
longitud. La ruta y clasificación siguen avanzando por -Y. La IA conserva su
control a 5 Hz y evasión existentes; una comprobación de límites permite regresar
a la última posición interior anterior al checkpoint pendiente después de un
segundo fuera del canal o tras rebasar un checkpoint sin registrarlo. La recuperación
no concede checkpoints ni vueltas. `test_storm_finish.gd` reproduce la carrera
concreta que detectó este problema durante la matriz inicial.

Los IDs `fuente` y `cascada` conservan desbloqueos y selección en partidas previas.
`record_version = 2` separa sus récords nuevos de los trazados antiguos, que no se
borran del guardado. Los demás circuitos conservan el formato de récord original.
Una modificación futura importante de recorrido debe incrementar esta versión.

## Android

- Máximo actual: 28 elementos de pista, de los cuales como máximo doce son sólidos.
- Pool VFX compartido: 48 efectos en baja y 96 en alta.
- Lluvia: 16 trazos en baja y 36 en alta, dibujados en la zona que sigue a cámara;
  reutiliza la actualización del agua a 10/20 Hz. Sin partículas ni shaders nuevos.
- Animaciones ambientales con menor frecuencia fuera de cámara.
- Cuerpos físicos instanciados para toda la pista; no se añadió un sistema de
  activación por sectores.

No se acreditan FPS, temperatura, consumo ni respuesta táctil en teléfono físico.

## Verificación

`tests/test_all_courses.gd` comprueba las dos calidades, presupuestos de objetos,
spawns, espacio de paso incluso con obstáculos móviles, doce checkpoints, una
meta y rechazo de llegadas que omitan checkpoints. Con renderizado guarda diez
capturas `user://course_<id>_<quality>.png`. También comprueba compatibilidad de
récords entre versiones.

`tests/test_matrix.gd` recorre el catálogo completo: seis tapas × tres dificultades
× cinco pistas, más tres vueltas por pista: **95 carreras, 380 llegadas y cero
fallos en la matriz final**. Resumen: `docs/course_validation_summary.json`.
Usa piloto automático para el jugador y no sustituye una prueba táctil manual.
Puede limitarse con `-- --circuit=remolino`, por ejemplo.

También se ejecutan regresiones de físicas, controles táctiles, power-ups, guardado,
pausa, recuperación de IA y veinte reinicios. El selector de las cinco pistas y
las pantallas del juego se comprueban en cinco resoluciones.

La geometría en ambas calidades, los récords, la recuperación forzada, la carrera
de regresión de Tormenta y las pruebas de interfaz y sistemas compartidos pasaron
sin fallos. Se inspeccionaron capturas de las nuevas pistas, incluida lluvia en baja.

Registros de esta entrega: `builds/logs/courses-*.log`.
El resultado definitivo de la matriz se registra en `courses-matrix-final.log`;
`courses-matrix.log` conserva el fallo detectado antes de corregir la recuperación.

## Compilaciones

Los APK finales se generan en `builds/android/tapa-racing.apk` (ARM64, teléfono) y
`builds/android/tapa-racing-emulator.apk` (x86_64, PC). El AAB anterior requiere
regeneración para incluir las cinco pistas. No se publica una versión en tiendas.
Ambos APK se exportaron con Godot 4.3 y sus firmas de depuración se verificaron.

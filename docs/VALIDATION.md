# Validación

Motor: Godot 4.3 stable en Windows, Compatibility/OpenGL.

## Automatizado

- Importación y compilación de scripts y escenas.
- Corriente base, dirección, límite de velocidad y resistencia del agua.
- Compras, no duplicar cobros, saldo insuficiente y reversión al fallar escritura.
- Guardado, lectura y recuperación de respaldo tras JSON corrupto.
- Toque izquierdo, liberación sobre UI, exclusión de botones y swipe único.
- Navegación por todas las páginas del menú; pausa/reanudación.
- Dos carreras completas con autopiloto de prueba y tres rivales IA.
- Checkpoints fuera de orden rechazados; recompensa única; tres vueltas ordenadas.

Simulación normal: Fuente Caribe entre 61.75 y 69.55 s, Canal Cascada entre
66.72 y 71.63 s. Son tiempos automatizados, no un estudio de equilibrio con jugadores.

## Gráficos

Render de menú, carrusel, ajustes, pista y resultados a 1280 × 720; ajustes a
1024 × 768. Generador: `tests/capture_screens.gd`. Las capturas de pista/resultados
usan posiciones de demostración; la llegada real se prueba por simulación aparte.

## Pendiente

Sesiones manuales prolongadas, equilibrio de todas las tapas/dificultades,
pruebas táctiles físicas, audio/haptics y áreas seguras de dispositivos reales;
firma de distribución, instalación y rendimiento móvil; exportación iOS.

El primer flujo jugable está implementado. Sigue siendo un prototipo, no una
versión lista para tiendas.

## Ampliación de pruebas y exportaciones

- Matriz de **38 carreras y 152 llegadas**, sin fallos: seis tapas × tres
  dificultades × dos circuitos, más dos carreras completas de tres vueltas.
  Una vuelta: 58.92–81.08 s; tres vueltas: 188.17–216.20 s. Informe reproducible:
  `docs/matrix_results.json`. La muestra es determinista; no prueba todas las semillas.
- Pruebas de segundo dedo para boost, tipos corruptos del guardado y protección
  del respaldo sano. Integración completa: cero fallos.
- Ciclo móvil simulado: límite 30/60, pausa al suspender, posición inmóvil durante
  pausa, Atrás para continuar y guardado al suspender: cero fallos.
- Veinte reinicios rápidos con temporizadores pendientes: sin errores de callbacks
  ni nodos retenidos al terminar.
- APK de depuración exportado y verificado por apksigner (v1/v2/v3). Inspección
  del paquete: ARM64, sin tests, herramientas, documentación ni keystore incluidos.
- Windows exportado con PCK incrustado. Arranque de menú, carrera y prueba integrada
  ejecutados desde TEMP, fuera del proyecto: aprobados sin errores ni advertencias.
- No hubo teléfono conectado. Ningún resultado de estas pruebas acredita FPS,
  latencia táctil, temperatura, batería o haptics en hardware móvil real.

Logs de exportación y ejecución: `builds/logs/`. Tamaños y SHA-256:
`builds/artifacts.json`. Ambos artefactos contienen la misma versión del juego.

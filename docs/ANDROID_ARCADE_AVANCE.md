# Desarrollo arcade Android — primer bloque

Registro histórico del primer bloque. Los bloques posteriores y el estado vigente
están en [ANDROID_ENTREGA.md](ANDROID_ENTREGA.md).

Implementación del 7 de septiembre de 2026, posterior al diagnóstico.

## Implementado

- Seis personalidades visuales originales mediante dibujo procedural compartido
  entre carrera y selector. Recursos de apariencia admiten futuras texturas.
- Animación de flotación, inclinación, impacto, salto, aterrizaje y celebración,
  separada de las colisiones y del movimiento físico.
- Estelas, gotas e impactos con almacenamiento fijo de 48 efectos en calidad baja
  y 96 en alta; un solo nodo de dibujo y descarte de emisiones fuera de cámara.
- Vibración visual de cámara breve y limitada ante impactos; cámaras de IA no
  ejecutan seguimiento visual.
- HUD con posición destacada, velocidad, progreso, energía y estado del turbo;
  cuenta regresiva y entrada de resultados animadas.
- Detección táctil del turbo y exclusión de botones consultadas en tiempo real;
  pausa Android mediante toque directo para admitir un segundo dedo.
- Turbo configurable mediante Resource, conservando coste, duración, recarga y
  multiplicador originales. Catálogo de tapas y circuitos definido en recursos.
- El script de compilación genera únicamente Android. Presets heredados y claves
  existentes se conservan.

## Verificación

Godot 4.3 importa el proyecto sin errores. Pasan las pruebas de carreras y guardado,
ciclo móvil y 20 reinicios sin nodos retenidos. Las dos carreras conservan sus
tiempos de simulación anteriores. Se generan capturas con el renderer Compatibility
y se revisa visualmente el HUD y los personajes. `tests/test_arcade.gd` comprueba
personalidades, parámetros originales del turbo y límites del pool.

APK de depuración: `builds/android/tapa-racing.apk`. Se verifica su firma mediante
apksigner en el proceso de compilación. No equivale a una versión de publicación.

## Etapas siguientes

1. Completar dirección visual de menús, entorno, podio y audio de presentación.
2. Incorporar pickups y efectos de power-ups reutilizables, empezando por escudo
   y recarga, con pruebas de duración, consumo y reinicio.
3. Verificar todos los aspectos de pantalla previstos, zonas seguras y controles
   en dispositivos Android reales; medir FPS, memoria, temperatura y haptics.
4. Preparar flujo Gradle/AAB de distribución y documentar firma de lanzamiento.

Este bloque no certifica rendimiento en dispositivos físicos ni compatibilidad
de publicación. No se ha generado AAB ni publicado código o aplicaciones.

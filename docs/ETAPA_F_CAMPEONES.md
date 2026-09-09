# Etapa F — presentación de los cinco campeones

La última carrera de cada copa comienza con una introducción de 2,5 segundos.
Se reutiliza una única pantalla ChampionIntro: retrato de la tapa que participa,
nombre, frase, marco de color, zoom suave del retrato, enfoque de cámara al campeón
y un pulso de agua. No se crean variantes de escena, shaders ni partículas nuevas.

| Copa | Campeón | Frase |
| --- | --- | --- |
| Bronce | Capitán Ola | El agua también enseña |
| Plata | Toro | Esta línea tiene dueño |
| Oro | Volt | La recta empieza antes de verla |
| Maestra | Nyx | Las rutas hablan en silencio |
| Leyenda | Onyx | Cada vuelta cuenta |

Para verlas: COPAS → iniciar/reanudar participación → avanzar hasta la última
carrera. No aparecen en rondas anteriores ni en carrera libre. Los campeones
siguen participando desde la primera ronda con sus identidades originales.

## Comportamiento

- La primera visualización termina automáticamente. Las siguientes ofrecen
  **Saltar presentación**, sin modificar el tiempo normal de cuenta atrás.
- seen_champion_intros almacena los IDs vistos en el JSON v1 existente. Se marca
  al terminar, no al abrir. Si falla la escritura, se revierte la marca; el juego
  continúa y la siguiente primera visualización vuelve a ser completa.
- Se filtran IDs desconocidos y se admiten partidas antiguas sin el campo nuevo.
- Cuenta atrás, reloj y corredores están detenidos durante la introducción.
  Al terminar se restauran cámara del jugador, HUD y controles, y comienza la
  cuenta atrás habitual. No se alteran estadísticas, IA, checkpoints ni premios.
- Pausar o perder el foco detiene también la introducción; el menú de pausa
  permanece accesible. Al continuar reaparece la presentación donde se quedó.
- Los retratos usan las tapas originales configuradas actualmente en las copas.
  Los retratos del roster futuro se integrarán con su migración, sin presentar
  como jugables tapas o habilidades todavía no activadas.

## Configuración y archivos

- ChampionshipDefinition: champion_line y champion_accent, configurables.
- data/championships/*.tres: cinco frases y colores.
- scripts/ui/champion_intro.gd: presentación reutilizable y botón de salto.
- scripts/levels/race.gd: entrada en la final, suspensión/restauración y pausa.
- scripts/services/save_manager.gd: lectura y persistencia de IDs vistos.

## Verificación

- test_champion_presentations: cinco campeones en baja/alta, cinco resoluciones,
  límite de 2,5 s, retrato correcto, cuenta atrás detenida, pausa, cámara/HUD
  restaurados, guardado/recarga, salto, rondas sin intro y escritura fallida:
  cero fallos. También pasa usando los recursos extraídos del APK ARM64.
- test_cup_races: 22 carreras / 88 llegadas, cero fallos, incluidas las cinco finales.
- test_cup_layouts: cinco resoluciones sin desbordamientos tras las introducciones.
- Regresiones de juego, navegación de copas, ciclo móvil y progreso: cero fallos.
- Se inspeccionaron capturas de Capitán Ola, Nyx, Onyx y Volt. El panel aplica
  explícitamente el tema existente para conservar la presentación visual.

Logs: builds/logs/stage-f-*.log. Capturas: builds/stage-f/champion_*_high.png.
El runner tools/test_android.ps1 incorpora la prueba; WithRendering captura vistas.
APK ARM64 y x86_64 regenerados, con firmas de depuración verificadas. Las pruebas
de recursos exportados se ejecutan en Windows; falta validación en Android físico.
El AAB y ejecutable Windows anteriores no se regeneraron.

Siguiente etapa G: migración y desbloqueos del roster. La concesión de tapas,
cosméticos de campeón, XP/niveles y habilidades permanece pendiente; esta etapa
presenta el desafío sin anticipar esos premios.

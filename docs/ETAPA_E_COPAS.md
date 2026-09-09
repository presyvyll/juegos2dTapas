# Etapa E — cinco copas con progreso y guardado

Desde el menú, entrar en **COPAS**, elegir una copa, pulsar **Iniciar copa** y
**Correr / reanudar**. Se mantiene la tapa elegida al iniciar la participación.
La carrera libre sigue disponible desde JUGAR sin modificar la copa guardada.

| Copa | Carreras | Vueltas | IA existente | Premio único por primer podio |
| --- | --- | --- | --- | --- |
| Bronce | Fuente Central, Jardín Acuático, Plaza del Sol | 1 | Fácil | 150 monedas |
| Plata | Canal Tropical, Canal Turbo, Remolino Azul, Cascada Express | 1 | Normal | 250 monedas |
| Oro | Templo Sumergido, Canal Tropical, Laberinto de Agua, Cascada Extrema, Fuente Neón | 2 | Difícil | 350 monedas |
| Maestra | Remolino Azul, Ojo del Torbellino, Cascada del Titán, Tormenta Caribeña, Fuente Neón | 2 | Difícil | 500 monedas |
| Leyenda | Laberinto de Agua, Cascada Extrema, Tormenta Caribeña, Ojo del Torbellino, Circuito Eclipse | 3 | Difícil | 700 monedas |

Bronce está disponible desde el inicio. Un puesto 1–3 desbloquea la siguiente copa.
El mejor puesto se conserva al repetir; el premio por podio no vuelve a entregarse.
Los premios individuales de carrera libre no se añaden en modo copa. Las vueltas
y dificultad de la copa no alteran las preferencias de carrera libre.

## Carrera y clasificación

Cuatro participantes fijos durante toda la copa: jugador y tres rivales, incluido
el campeón previsto en el diseño. Se muestran sus nombres estables; todavía usan
las seis tapas originales y el controlador de IA existente, mediante
legacy_rival_cap_ids. Las habilidades y perfiles del nuevo roster no están activos.

Puntos por llegada: 10, 7, 4 y 2. DNF: cero puntos y tiempo de 180 segundos por vuelta.
Se espera a las cuatro llegadas o al límite de tiempo; acabar con el jugador no
detiene a los demás. El timeout no marca como finalizado a quien no cruzó la meta.
Los DNF se ordenan por checkpoints válidos recorridos y después por ID.

La pantalla muestra resultados de la última carrera y clasificación acumulada.
Desempates: puntos, victorias, segundos puestos, mejor posición en última carrera,
menor tiempo total e ID estable. Continuar se habilita después de cerrar y guardar
la ronda. No se cambian físicas, ruta de IA ni orden de checkpoints.

## Persistencia y recuperación

Se amplía el JSON v1 de SaveManager con championships, manteniendo compatibilidad
con monedas, compras, ajustes y récords antiguos:

- completed: mejor puesto por copa; determina desbloqueo y si ya se cobró el podio.
- active: cup_id, cap_id, fase y lista de resultados completos.
- Fases: ready, racing, results, complete.
- Puntos y desempates se recalculan desde resultados, no desde totales almacenados.

Se guarda antes de lanzar, después de cerrar la ronda y antes de continuar.
Cerrar a mitad de carrera permite repetir **solo esa carrera**: no se guardan
posiciones ni velocidades a mitad del recorrido. Cerrar en resultados permite
revisarlos y continuar sin repetir la ronda.

La transacción guarda participación y monedas juntas mediante temporal y backup
existentes. Si falla, restaura ambos valores y permite reintentar. Repetir una
notificación de resultado no vuelve a sumar puntos ni premios. La lectura valida
IDs, fases, participantes únicos, límites y números finitos; descarta estados
opcionales inválidos conservando el resto de la partida. El backup recupera una
participación si el archivo principal está corrupto.

**Abandonar copa y descartar esta participación** está disponible antes de correr
o al volver al menú durante una carrera. Conserva los mejores puestos anteriores.
Se admite una sola participación activa.

## Archivos

- data/championships/*.tres y data/catalog.tres: las cinco definiciones activas.
- scripts/race/cup_progress.gd: validación, resultados, puntos y desempates.
- scripts/services/save_manager.gd: transacciones y progreso persistente.
- scripts/levels/race.gd: configuración de copa, espera/timeout y resultados.
- scripts/ui/championship_page.gd: selección, reanudación y clasificación.
- scripts/ui/main_menu.gd: acceso COPAS.

Las listas de pistas y rivales usan Array[String]: esta entrega detectó que se
perdían al exportarlas como PackedStringArray. La prueba con los assets del APK
corregido verifica tanto la lógica como la navegación real entre rondas.

## Validación

- test_championships: cinco copas, puntos, requisitos, primeros premios, repetición,
  puestos sin podio, escrituras fallidas/reintento, datos malformados, DNF,
  desempates y lectura de partidas v1: cero fallos.
- test_cup_races: **22 carreras / 88 llegadas**, con las vueltas de cada copa;
  también timeout DNF y aislamiento de carrera libre: cero fallos.
- test_cup_flow: botones reales, espera de rivales, siguiente ronda, salida al menú,
  reanudación, recuperación de backup y carrera libre independiente: cero fallos.
- test_cup_layouts: selector, fases, espera y resultados en cinco resoluciones.
- Regresiones de catálogo/datos, carga de circuitos, juego, vueltas, ciclo móvil
  y transiciones: cero fallos.

Logs: builds/logs/stage-e-*.log. Suite: tools/test_android.ps1 -WithRendering.
La prueba de 22 carreras usa autopiloto y habilita prerrequisitos en una partida
de prueba para cubrir todas las copas; la progresión por podios se prueba aparte.
Los APK de depuración ARM64 y x86_64 se regeneran para esta etapa; todavía falta
validación táctil y de rendimiento en teléfono físico.

## Pendiente según las siguientes etapas

Presentación de campeones (F), migración del roster/desbloqueos (G), interfaz
ampliada y balance (H–I). XP/niveles, tapas ganadas, habilidades y cosméticos de
campeón siguen pendientes: los campos de diseño no conceden esos premios todavía.
Las pistas de carrera libre mantienen sus compras provisionales; el acceso dentro
de la copa depende de la copa, sin cobrar por cada circuito.

# CONTENT_DESIGN — Liga de la Fuente
Estado: diseño general; etapas D–E implementadas (quince pistas y cinco copas con
guardado). Ver CONTENT_IMPLEMENTATION_REPORT.md. Habilidades, roster nuevo y XP
siguen pendientes. La auditoría siguiente describe la base anterior a esas etapas.

## Auditoría de arquitectura
| Concepto solicitado | Equivalente real | Decisión |
| --- | --- | --- |
| CapData | CapDefinition + CapAppearance, seis tapas activas | Ampliar el Resource; conservar multiplicadores y catálogo actuales hasta migración. |
| TrackData | CircuitDefinition + CircuitFeature, cinco pistas | Reutilizar; diez trazados nuevos para llegar a quince. |
| ChampionshipData | No existe | Modelo ChampionshipDefinition; sesión persistente en etapa E. |
| PlayerProgress / XP / niveles | No existen XP ni niveles | Extender SaveManager posteriormente; no crear otro guardado. |
| UnlockSystem | SaveManager.purchase y listas de IDs | Añadir condiciones de copa sobre esas listas, sin sistema paralelo. |
| PowerUps | PowerUpDefinition, shield y recharge | Reutilizar efectos; no hay inventario ni activación manual. |
| AIController | CapAIController único, decisión a 5 Hz | Perfiles configurables; adaptar parámetros, no duplicar scripts. |
| RaceManager | RaceSession + race.gd | Cuatro participantes; preservar orden de checkpoints y meta. |
| Habilidades propias | Solo turbo común y power-ups | CapAbilityDefinition independiente; ejecutor genérico pendiente. |

Godot 4.3 y Android, sin iOS nuevo. Los títulos y conceptos son originales en su
combinación; los assets definitivos no existen. Se mantienen placeholders
procedurales y audio original existente. Las referencias opcionales pueden ser null.

## Identidad y alcance
Liga de la Fuente: pilotos pequeños que convierten canales cotidianos en un
deporte. La personalidad procede de silueta, color, expresión, forma de conducir y
frases cortas. Los rangos son Principiante, Competidor, Rival, Campeón, Maestro y
Leyenda, asociados al inicio y a las cinco copas superadas.

Objetivo temporal a validar: 60–100 minutos de primera campaña con reintentos
moderados; 2–4 horas para dominio, medallas, récords y estilos alternativos. No
prometer varias horas solo contando assets. Las 22 carreras suman 42 vueltas;
a 60–90 segundos por vuelta son 42–63 minutos de conducción sin menús ni reintentos.

## Balance común de las 18 tapas
V = velocidad, A = aceleración, C = control, P = peso, T = turbo, I = impacto.
**Todas suman 36 puntos**, incluidos Eclipse y otras rarezas altas. Rango 1–10.
Ninguna domina otra en los seis atributos. Presupuesto igual es punto de partida,
no prueba de igualdad de resultados; el peso de la velocidad exige pruebas.

| Tapa | Arquetipo | V | A | C | P | T | I | Habilidad | Bloque de desbloqueo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Chispa | Equilibrada | 6 | 8 | 7 | 5 | 6 | 4 | Impulso Inicial | Inicio |
| Rayo | Velocista | 9 | 7 | 4 | 3 | 8 | 5 | Sobrecarga | bronce |
| Titán | Pesada | 5 | 3 | 4 | 9 | 6 | 9 | Muro Móvil | bronce |
| Burbuja | Técnica | 5 | 7 | 9 | 4 | 6 | 5 | Estabilidad Acuática | Inicio |
| Torbellino | Agresiva | 6 | 5 | 6 | 6 | 5 | 8 | Mini Remolino | maestra |
| Fantasma | Especial | 7 | 6 | 8 | 3 | 7 | 5 | Flujo Fantasma | maestra |
| Brasa | Turbo | 7 | 7 | 4 | 4 | 10 | 4 | Turbo Incandescente | plata |
| Neón | Velocista | 8 | 6 | 5 | 4 | 8 | 5 | Ritmo Neón | oro |
| Ancla | Pesada | 4 | 4 | 6 | 10 | 4 | 8 | Peso Muerto | oro |
| Pixel | Técnica | 6 | 6 | 9 | 4 | 6 | 5 | Trayectoria Perfecta | plata |
| Trueno | Agresiva | 7 | 5 | 4 | 7 | 5 | 8 | Golpe de Trueno | oro |
| Coral | Equilibrada | 6 | 7 | 7 | 5 | 5 | 6 | Segundo Aire | Inicio |
| Meteoro | Turbo | 8 | 5 | 4 | 5 | 10 | 4 | Impulso Meteoro | leyenda |
| Glacial | Técnica | 6 | 5 | 10 | 4 | 5 | 6 | Precisión Glacial | maestra |
| Cobra | Velocista | 8 | 7 | 6 | 3 | 7 | 5 | Ataque de Oportunidad | leyenda |
| Roca | Pesada | 5 | 4 | 5 | 9 | 5 | 8 | Inercia | plata |
| Cometa | Equilibrada | 6 | 6 | 6 | 5 | 8 | 5 | Estela Cometa | bronce |
| Eclipse | Especial | 6 | 6 | 7 | 6 | 6 | 5 | Pulso Eclipse | leyenda |

| Tapa | Rareza | Personalidad | Tema visual | Fortaleza / debilidad / estilo |
| --- | --- | --- | --- | --- |
| Chispa | comun | Optimista y competitiva | Naranja solar | Acelera al salir; poco empuje. |
| Rayo | poco_comun | Impaciente | Amarillo eléctrico | Rectas fuertes; sensible a golpes. |
| Titán | poco_comun | Seria y resistente | Metal industrial | Defiende línea; recupera lentamente. |
| Burbuja | comun | Tranquila | Azul cristalino | Control de corrientes; poca masa. |
| Torbellino | epica | Caótica y juguetona | Espiral azul y púrpura | Presiona cerca; turbo discreto. |
| Fantasma | epica | Misteriosa | Blanco azulado | Evita frenadas leves; vulnerable a empujones. |
| Brasa | rara | Explosiva | Rojo y naranja | Picos rápidos; exige orientar antes del turbo. |
| Neón | rara | Presumida | Cian y magenta nocturnos | Premia constancia; pierde racha al chocar. |
| Ancla | rara | Paciente | Azul marino | Resiste impactos; rectas lentas. |
| Pixel | poco_comun | Analítica | Geometría verde y cian | Premia precisión; no gana duelos de masa. |
| Trueno | rara | Desafiante | Grafito y amarillo | Golpea a velocidad; pierde en curvas largas. |
| Coral | comun | Amigable y tenaz | Coral tropical | Recupera ritmo; turbo moderado. |
| Meteoro | epica | Temeraria | Grafito con estela naranja | Salida ofensiva; recarga más lenta durante 4 s. |
| Glacial | rara | Fría y calculadora | Hielo y blanco | Control fino; aceleración discreta. |
| Cobra | epica | Oportunista | Verde brillante | Adelanta por bordes; frágil al contacto. |
| Roca | poco_comun | Imperturbable | Gris y rojo | Conserva avance; poco ágil. |
| Cometa | poco_comun | Aventurera | Azul y naranja | Gestiona energía; exige esperar barra llena. |
| Eclipse | legendaria | Campeona reservada | Negro, violeta y oro | Versátil; una sola oportunidad, sin stats superiores. |

No se renombra silenciosamente el contenido activo. La futura migración de IDs
será sol→chispa, coral→coral, menta→burbuja, oceano→rayo, uva→brasa, coco→titan.
Debe preservar selección, compras y moneda, y ser idempotente. Las tapas ya
compradas seguirán desbloqueadas aunque el nuevo requisito sea una copa.

### Conversión a física
CapRatings contiene seis enteros, separados de CapPhysicsConfig. Convertir
velocidad a 0.94–1.06, aceleración/control/peso/turbo a 0.8–1.2 e impacto a
0.85–1.15. No asignar 8 directamente a current_speed ni multiplicar la física por 8.
Los multiplicadores antiguos siguen válidos si ratings es null. Los 18 Resources
de esta entrega contienen también sus multiplicadores derivados para poder
utilizar apply_definition existente. El impacto y las habilidades requieren su
adaptador antes de presentarse como efectos activos.

## Habilidades: especificación inicial
Los nombres de parámetros siguientes son contratos de datos, no efectos ya
ejecutándose. El executor debe leer trigger y modifiers, nunca comparar nombres
de tapas. Duración/cooldown corren solo durante carrera; pausar los congela.
Sin acumulación del mismo efecto. Una reactivación no alarga indefinidamente
duración. Al reiniciar se limpia todo estado.

| Habilidad | Condición | Duración | Cooldown | Usos por carrera | Modificadores iniciales |
| --- | --- | --- | --- | --- | --- |
| Impulso Inicial | start | 2 s | 0 s | 1 | acceleration: 1.12 |
| Sobrecarga | overtake | 1.5 s | 8 s | Sin límite; condición/cooldown | speed: 1.05 |
| Muro Móvil | impact_received | 1.5 s | 9 s | Sin límite; condición/cooldown | received_push: 0.8 |
| Estabilidad Acuática | current_enter | 2 s | 8 s | Sin límite; condición/cooldown | current_lateral: 0.75 |
| Mini Remolino | near_rival | 0.4 s | 12 s | Sin límite; condición/cooldown | lateral_pulse: 35 |
| Flujo Fantasma | light_obstacle | 1.5 s | 10 s | Sin límite; condición/cooldown | light_slow_floor: 0.92 |
| Turbo Incandescente | turbo | 0.7 s | 0 s | Sin límite; condición/cooldown | turbo_speed: 1.68; turbo_duration: 0.7 |
| Ritmo Neón | clean_driving | 2 s | 10 s | Sin límite; condición/cooldown | speed: 1.04 |
| Peso Muerto | strong_impact | 1 s | 10 s | Sin límite; condición/cooldown | received_push: 0.7 |
| Trayectoria Perfecta | precision_zone | 2 s | 8 s | Sin límite; condición/cooldown | handling: 1.12 |
| Golpe de Trueno | fast_impact | 0.15 s | 6 s | Sin límite; condición/cooldown | outgoing_push: 1.1 |
| Segundo Aire | impact_received | 1.5 s | 7 s | Sin límite; condición/cooldown | acceleration: 1.12 |
| Impulso Meteoro | first_turbo | 0.8 s | 0 s | 1 | turbo_impulse: 1.15; recharge: 0.85 |
| Precisión Glacial | strong_drift | 2 s | 9 s | Sin límite; condición/cooldown | drift_damping: 1.15 |
| Ataque de Oportunidad | side_overtake | 1.5 s | 9 s | Sin límite; condición/cooldown | speed: 1.05 |
| Inercia | adverse_current | 2 s | 8 s | Sin límite; condición/cooldown | adverse_slow_floor: 0.88 |
| Estela Cometa | full_turbo | 0.9 s | 0 s | Sin límite; condición/cooldown | energy_cost: 0.405 |
| Pulso Eclipse | race_midpoint | 2 s | 0 s | 1 | acceleration: 1.1; received_push: 0.85 |

Reglas de condiciones:
- start: una sola activación después de la cuenta atrás, no por cada vuelta.
- overtake: cambio de orden real entre corredores activos, con separación mínima
  de 80 unidades y sin contar reinicios, teleports ni rivales terminados.
- side_overtake: además, línea lateral entre 0.45 y 0.8 del semiancho.
- near_rival: radio 150; pulso único de 35 unidades de velocidad lateral, repartido
  por distancia. No aplicar fuerzas globales ni ignorar escudos.
- clean_driving: cinco segundos sin impacto fuerte, salto de checkpoint ni
  recuperación; la bonificación se corta al chocar.
- precision_zone: atravesar la banda central señalizada de una zona dedicada,
  a menos de 45 unidades del centro y sin golpe durante el segundo anterior.
  La zona aún no existe; no reemplazarla silenciosamente por cualquier checkpoint.
- strong_impact / fast_impact: umbral de 180 de impacto / 300 de velocidad.
- light_obstacle: solo hojas/áreas ligeras, nunca paredes o rocas sólidas.
- adverse_current: solo componente contraria al avance; no anula remolinos enteros.
- strong_drift: velocidad lateral mayor de 90 durante 0.3 s.
- full_turbo: energía al menos 0.99 antes del gasto; costo absoluto 0.405.
- first_turbo: impulso 15% mayor solo una vez; penalización de recarga 15% por 4 s.
- race_midpoint: primera mitad de la distancia total alcanzada; una vez por carrera.

Para resistencias simultáneas se aplica la mayor, no su producto. Escudo existente
sigue anulando empujes. Bonificaciones temporales de velocidad se limitan a 8%
sobre la base; turbo de Brasa usa 1.68 durante 0.7 s en lugar de 1.6 durante 0.9 s.
No atravesar colisiones. Feedback: pulso breve de color y aro/estela del pool
existente, máximo cuatro elementos por activación; icono y nombre corto en HUD.

## Diez rivales y perfiles reutilizables
Los cinco campeones forman parte de estos diez: no se crean quince identidades.
Perfil, tapa favorita y rareza son conceptos independientes.

| Rival | Tapa favorita | Skill 1–10 | Estrategia | Agresión | Riesgo | Turbo | Error por elección de línea | Recuperación |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Milo | chispa | 3 | Aprende arriesgando | 0.15 | 0.25 | 0.3 | 0.22 | 0.4 |
| Luna | pixel | 6 | Línea limpia | 0.2 | 0.35 | 0.45 | 0.08 | 0.8 |
| Capitán Ola | coral | 4 | Turbo de salida | 0.3 | 0.35 | 0.55 | 0.14 | 0.55 |
| Toro | titan | 5 | Defiende su línea | 0.7 | 0.45 | 0.4 | 0.1 | 0.65 |
| Nova | brasa | 5 | Turbo frecuente | 0.35 | 0.7 | 0.85 | 0.12 | 0.6 |
| Kira | cobra | 7 | Adelantamientos laterales | 0.45 | 0.7 | 0.65 | 0.07 | 0.8 |
| Volt | rayo | 7 | Velocidad y adelantamiento | 0.5 | 0.7 | 0.8 | 0.06 | 0.8 |
| Zen | glacial | 8 | Consistencia defensiva | 0.15 | 0.3 | 0.5 | 0.025 | 0.9 |
| Nyx | fantasma | 8 | Rutas y pickups | 0.4 | 0.55 | 0.65 | 0.025 | 0.95 |
| Onyx | eclipse | 10 | Dominio equilibrado | 0.6 | 0.6 | 0.8 | 0.01 | 1 |

AIProfile guarda además pickup_skill, overtake_skill, defensive_skill y
preferred_line. Las probabilidades se evalúan por decisión, nunca por frame.
Error se comprueba al elegir línea, cada 2.5–5 s. Turbo mapea su preferencia a
0.02–0.18 por decisión de 0.2 s cuando sea legal; debe conservar suficiente energía
y evitar dispararlo hacia un obstáculo inmediato. Skills altos reducen error y
anticipan rutas; no añaden velocidad imposible ni inmunidad.

Uso estratégico de power-ups significa elegir acercarse a uno de los ocho pickups
existentes, según necesidad de energía o defensa. No significa guardarlos en un
inventario inexistente. El controlador consulta solo candidatos cercanos a 5 Hz.

## Quince circuitos
La etapa D integra los quince trazados y conserva las cinco pistas anteriores.
Cada pista comparte levels/race.tscn. La tabla describe los requisitos de copa
previstos; el acceso actual usa monedas hasta integrar campeonatos, según
docs/ETAPA_D_CIRCUITOS.md. No se instancian trazados para generar thumbnails.

| ID | Nombre | Dificultad 1–10 | Mecánica principal | Nivel recomendado (no bloqueo) | Acceso | Hazards |
| --- | --- | --- | --- | --- | --- | --- |
| fuente | Fuente Central | 1 | Movimiento | 1 | Inicio | Curvas amplias; pocas rocas |
| jardin | Jardín Acuático | 2 | Hojas y flores | 1 | Inicio | Hojas lentas; corrientes suaves |
| plaza | Plaza del Sol | 3 | Fuente urbana | 2 | Inicio | Chorros espaciados; curvas abiertas |
| tropical | Canal Tropical | 4 | Control lateral | 3 | Bronce | Ramas; hojas; pasos alrededor de islas |
| canal_turbo | Canal Turbo | 4 | Gestión del boost | 4 | Bronce | Franjas rápidas separadas por curvas de frenado |
| remolino | Remolino Azul | 5 | Control de giro | 4 | Bronce | Remolinos y alternancia lenta/rápida |
| express | Cascada Express | 5 | Momentum | 5 | Bronce | Descensos separados por curvas de recuperación |
| templo | Templo Sumergido | 6 | Decisión de ruta | 6 | Plata | Islas alargadas: paso ancho sinuoso o paso estrecho directo |
| neon | Fuente Neón | 7 | Ritmo de velocidad | 7 | Plata | Paleta nocturna; rectas rápidas y salidas técnicas |
| laberinto | Laberinto de Agua | 7 | Lectura de rutas | 8 | Plata | Islas alternadas y estrechamientos; sin cruces ni bucles |
| cascada | Cascada Extrema | 8 | Saltos y chorros | 8 | Plata | Trazado existente; alto riesgo de contactos |
| ojo | Ojo del Torbellino | 8 | Timing de giro | 10 | Oro | Remolino central que pulsa; pasos laterales |
| titan | Cascada del Titán | 8 | Anticipación | 10 | Oro | Objetos móviles y caídas; evita encadenar impactos |
| tormenta | Tormenta Caribeña | 9 | Control bajo presión | 11 | Oro | Lluvia acotada; corrientes cambiantes; islas |
| eclipse | Circuito Eclipse | 10 | Síntesis | 12 | Maestra | Secciones de precisión, turbo, giro y salto, señalizadas |

Carrera libre: una a tres vueltas. Las copas fijan sus propias vueltas.
Reward multiplier de circuito entre 1.0 y 1.15 como máximo, aplicado una vez a la
recompensa base; no multiplicar de nuevo por rareza. AI_difficulty_modifier: -1 en
tutorial, 0 en fáciles/medias y +1 en avanzadas, saturado en 1–10, sin cambiar stats.

### Alternativas compatibles con el canal
Mantener avance monotónico en -Y y checkpoints transversales que cubran ambas
opciones. Islas largas pueden separar una línea directa estrecha de una línea
más ancha con mayor desplazamiento lateral. La diferencia debe medirse en tiempo
y riesgo, no describirse como atajo si ambos tiempos son equivalentes.
No soportar cruces, bucles ni bifurcaciones fuera del canal sin una fase específica.
Señalizar entrada y salida; la IA debe evitar escoger un hueco más estrecho que
su diámetro más margen. Ojo necesita pulsación configurable del remolino; no
inventar que el componente actual ya cambia de radio.

### Carga y Android
La etapa D incorporó entradas ligeras con metadata y ruta de Resource; carga el
trazado elegido bajo demanda y lo libera al salir. No instancia escenas para
thumbnails. test_circuit_loading protege este comportamiento.
Presupuesto inicial por trazado: ≤32 elementos y ≤12 sólidos, conservar pool 48/96
y lluvia 16/36; sin shaders nuevos. Validar memoria y tiempos de carga reales,
y gama media física cuando haya dispositivo.

## Exactamente cinco copas
Cuatro participantes fijos por copa (jugador + tres rivales). El campeón participa
desde el inicio; su presentación especial se reserva para la final. Así no se
cambian identidades en la tabla de puntos a mitad del campeonato.

| Copa | Carreras | IDs de pistas en orden | Vueltas por carrera | Skill | Campeón | Premio único monedas / XP |
| --- | --- | --- | --- | --- | --- | --- |
| Copa Bronce | 3 | fuente, jardin, plaza | 1 | 2–4 | capitan_ola | 150 / 150 |
| Copa Plata | 4 | tropical, canal_turbo, remolino, express | 1 | 4–5 | toro | 250 / 250 |
| Copa Oro | 5 | templo, tropical, laberinto, cascada, neon | 2 | 5–7 | volt | 350 / 350 |
| Copa Maestra | 5 | remolino, ojo, titan, tormenta, neon | 2 | 7–8 | nyx | 500 / 500 |
| Copa Leyenda | 5 | laberinto, cascada, tormenta, ojo, eclipse | 3 | 8–10 | onyx | 700 / 700 |

Rosters propuestos: Bronce (Milo, Luna, Capitán Ola); Plata (Nova, Zen, Toro);
Oro (Kira, Nova, Volt); Maestra (Luna, Zen, Nyx); Leyenda (Kira, Volt, Onyx).
Cualquier tapa del rival utiliza el mismo presupuesto de 36 y las mismas reglas.

Puntos por carrera: **10, 7, 4, 2**; DNF obtiene 0. Desempate determinista:
puntos, victorias, segundos puestos, mejor posición en última carrera, menor
tiempo acumulado, ID estable. DNF tiene tiempo de 180 s × vueltas; entre DNF
se ordena progreso válido y después ID. No convertir un DNF en llegada real.

Mostrar resultados de carrera y clasificación acumulada antes de Continuar.
RaceSession actual avisa al terminar el jugador: ChampionshipSession deberá
esperar las cuatro llegadas o el timeout para cerrar la tabla. No congelar la IA
al mostrar resultados. Guardar la transición una vez, sin duplicar premios.

## Cinco campeones
| Copa | Campeón / tapa | Lección | Intro (≤2.5 s) | Recompensa memorable |
| --- | --- | --- | --- | --- |
| Bronce | Capitán Ola / Coral | Momento del turbo | «El agua también enseña»; retrato y splash | Cometa |
| Plata | Toro / Titán | Defenderse de masa | «Esta línea tiene dueño» | Roca + cosmético Perla existente |
| Oro | Volt / Rayo | Anticipar adelantamientos | «La recta empieza antes de verla» | Trueno |
| Maestra | Nyx / Fantasma | Leer rutas y pickups | «Las rutas hablan en silencio» | Fantasma + estela lunar pendiente de arte |
| Leyenda | Onyx / Eclipse | Combinar todas las técnicas | «Cada vuelta cuenta» | Eclipse + título Leyenda |

Derrotar al campeón significa terminar por delante de él en la final y obtener
podio en la copa. No exige ganar las cinco carreras. Tras ver una intro una vez,
se puede saltar; almacenar el ID visto. Zoom suave, retrato procedural, nombre,
pulso de agua y transición corta. Sin ventajas estadísticas ocultas.

## Progresión, niveles y desbloqueos
| Hito | Dos tapas por podio | Tercera por victoria sobre campeón | Próximo contenido |
| --- | --- | --- | --- |
| Inicio | Chispa, Coral, Burbuja (tres de inicio) | — | Bronce y tres pistas introductorias |
| Copa Bronce | rayo, titan | cometa | Copa Plata |
| Copa Plata | brasa, pixel | roca | Copa Oro |
| Copa Oro | neon, ancla | trueno | Copa Maestra |
| Copa Maestra | torbellino, glacial | fantasma | Copa Leyenda |
| Copa Leyenda | meteoro, cobra | eclipse | Retos de maestría y récords |

Resultado: 3 + 5×3 = 18. Podio desbloquea próxima copa y pistas de su bloque,
sin gasto adicional de monedas. La tercera tapa puede obtenerse repitiendo la
copa; ningún premio memorable depende de azar. Monedas sirven principalmente
para cosméticos. Conservar compras antiguas al migrar, no retirar propiedad.

XP propuesto: 90 por vuelta terminada más 30/20/10/5 por puesto y bonus único de
copa de la tabla. Umbral para nivel L: 30×(L−1)² XP. Nivel máximo inicial 20;
los niveles son prestigio, no una barrera adicional a las copas. Niveles sugeridos
1/3/6/9/12, sin grinding obligatorio. Rango de Leyenda procede de la copa final,
no de acumular horas.

Recompensas de copa se reclaman una vez por ID; recompensas de carrera una vez
por (run_id, race_index). Reanudar guardado durante una carrera repite ese tramo
con misma semilla y sin pago previo; resultados ya consolidados se muestran sin
volver a sumar puntos. Persistir participantes, puntos, puestos, tiempos, pista
actual, recompensas reclamadas y fases intro/carrera/resultados/completa. Una
escritura fallida no concede desbloqueos como si estuvieran guardados.

## UI, audio y debug previstos
- Tapa: nombre, rareza, seis ratings, habilidad, condición de desbloqueo y estado.
- Copa: progreso, pistas, vueltas, rival campeón y premios pendientes.
- Pista: miniatura procedural, dificultad, peligros, vueltas y mejor tiempo.
- Audio opcional: intro rival, boss, victoria, unlock y copa completa. Null es
  válido; reutilizar sonidos propios actuales cuando corresponda.
- Debug solamente: listar/desbloquear/bloquear tapas, cargar pista, completar copa,
  fijar nivel, probar boss y mostrar perfil. Usar guardado de prueba separado y
  no distribuir atajos de progresión en release. Nada de borrar la partida real.

## Entregas verificables
A: modelos compatibles; B: 18 tapas/18 habilidades como datos; C: diez rivales y
diez perfiles. Esta primera entrega los deja en data/arcade_content.tres, usando
RacingCatalogData existente. Es un manifiesto de preparación, no otro sistema de
catálogo ni la lista activa. data/catalog.tres sigue representando el juego vigente.
No activar todavía copas, XP, habilidades o requisitos sin sus ejecutores.

D: diez pistas nuevas y carga bajo demanda; E: cinco copas con sesión/persistencia;
F: presentación de los cinco campeones; G: migración y desbloqueos; H: interfaz;
I: balance, recorrido completo hasta Leyenda y Android. Probar carga y guardado
después de cada entrega. Ver BALANCE_NOTES.md y ART_ASSET_REQUIREMENTS.md.

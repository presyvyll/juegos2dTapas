# BALANCE_NOTES
Estado: balance de diseño; no se ha acreditado equilibrio competitivo de las
habilidades. El juego activo conserva sus seis tapas mientras se integran etapas posteriores.

## Presupuesto y escala
V/A/C/P/T/I tienen rango 1–10 y todas las tapas suman 36. Las sumas por rareza son
idénticas. Los Resources guardan ratings y multiplicadores derivados, comprobados
automáticamente para evitar que las dos representaciones diverjan.
Velocidad: 0.94–1.06; aceleración/control/peso/turbo: 0.8–1.2; impacto: 0.85–1.15.
La curva es lineal entre extremos. Las físicas base siguen siendo las existentes.

El presupuesto no demuestra por sí mismo que 1 punto de velocidad valga 1 de peso.
Priorizar resultados medidos por pista, puesto y consistencia. Evitar compensar
un mal perfil de IA aumentando artificialmente estadísticas de un campeón.

## Razón de cada distribución
| Tapa | V/A/C/P/T/I | Fortaleza, debilidad y propósito | Prueba de balance |
| --- | --- | --- | --- |
| Chispa | 6/8/7/5/6/4 | Acelera al salir; poco empuje. | Probar Impulso Inicial en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Rayo | 9/7/4/3/8/5 | Rectas fuertes; sensible a golpes. | Probar Sobrecarga en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Titán | 5/3/4/9/6/9 | Defiende línea; recupera lentamente. | Probar Muro Móvil en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Burbuja | 5/7/9/4/6/5 | Control de corrientes; poca masa. | Probar Estabilidad Acuática en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Torbellino | 6/5/6/6/5/8 | Presiona cerca; turbo discreto. | Probar Mini Remolino en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Fantasma | 7/6/8/3/7/5 | Evita frenadas leves; vulnerable a empujones. | Probar Flujo Fantasma en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Brasa | 7/7/4/4/10/4 | Picos rápidos; exige orientar antes del turbo. | Probar Turbo Incandescente en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Neón | 8/6/5/4/8/5 | Premia constancia; pierde racha al chocar. | Probar Ritmo Neón en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Ancla | 4/4/6/10/4/8 | Resiste impactos; rectas lentas. | Probar Peso Muerto en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Pixel | 6/6/9/4/6/5 | Premia precisión; no gana duelos de masa. | Probar Trayectoria Perfecta en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Trueno | 7/5/4/7/5/8 | Golpea a velocidad; pierde en curvas largas. | Probar Golpe de Trueno en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Coral | 6/7/7/5/5/6 | Recupera ritmo; turbo moderado. | Probar Segundo Aire en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Meteoro | 8/5/4/5/10/4 | Salida ofensiva; recarga más lenta durante 4 s. | Probar Impulso Meteoro en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Glacial | 6/5/10/4/5/6 | Control fino; aceleración discreta. | Probar Precisión Glacial en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Cobra | 8/7/6/3/7/5 | Adelanta por bordes; frágil al contacto. | Probar Ataque de Oportunidad en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Roca | 5/4/5/9/5/8 | Conserva avance; poco ágil. | Probar Inercia en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Cometa | 6/6/6/5/8/5 | Gestiona energía; exige esperar barra llena. | Probar Estela Cometa en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |
| Eclipse | 6/6/7/6/6/5 | Versátil; una sola oportunidad, sin stats superiores. | Probar Pulso Eclipse en recta, curva y tráfico; comparar con tapa del mismo arquetipo. |

## Riesgos principales
- Velocistas + recarga: comprobar que no mantienen turbo continuo. Tiempo de
  referencia para recargar 0.45 a 0.105/s: 4.29 s, antes de pickups.
- Cometa puede bajar el costo a 0.405, pero solo con energía ≥0.99. Debe ser una
  decisión de ahorro, no un descuento permanente de todos los turbos.
- Brasa: 1.68 durante 0.7 s frente a 1.6 durante 0.9 s. Medir impulso y distancia
  netos; no concluir que la duración menor compensa cualquier pico.
- Meteoro: primer impulso +15% una vez; recarga -15% durante 4 s. Comprobar que
  reiniciar vuelta no rearma el primer impulso.
- Ancla/Titán + escudo: tomar la mayor protección; no multiplicar resistencias.
  La fuerza recibida de compañeros sigue respetando peso y escudo existentes.
- Torbellino: pulso máximo 35, radio 150, cooldown 12 s; no sumar un pulso por frame
  ni por collider. Debe poder evitarse alejándose. No empujar a través de paredes.
- Rayo/Cobra: no activar al alternar posiciones cada frame con el mismo rival;
  usar separación y cooldown. No contar recuperaciones como adelantamientos.
- Neón: la racha se rompe con choque y recuperación. Un golpe recibido no debe
  permitir refrescar indefinidamente la velocidad.
- Pixel depende de zonas de precisión reales, todavía pendientes. No mostrar la
  habilidad como disponible hasta que pueda activarse en pistas señalizadas.
- Fantasma/Roca: reducir solo frenadas indicadas; no borrar colisiones ni anular
  íntegramente fuerzas de remolinos.
- Eclipse tiene 36 puntos y dos segundos de habilidad una vez. Prestigio no es
  superioridad. Debe poder perder frente a Chispa con conducción comparable.

## Matriz futura de balance
1. Separar piloto y tapa: usar el mismo perfil/semilla en cada comparación.
2. Muestrear al menos 20 semillas por tapa, pista y dificultad; registrar llegadas,
   mediana, percentil 90, colisiones, uso de turbo, activaciones y recuperaciones.
3. En carreras de cuatro, comparar tasa de victoria con el 25% esperado bajo
   condiciones simétricas; investigar diferencias persistentes, no muestras pequeñas.
4. Revisar por arquetipo: una técnica puede ganar consistencia en curvas y perder
   tiempo en rectas. Ninguna debería encabezar todos los trazados.
5. Jugar en pantalla táctil: reacción, legibilidad del efecto, error de dirección y
   precisión de activación. La matriz con IA no valida diversión ni control humano.
6. Ajustar primero magnitud/duración/cooldown en Resources, después presupuesto;
   cambiar una familia de parámetros por iteración.
7. Medir duración real de campaña, reintentos y desbloqueos. Los niveles no bloquean
   copas: evitar horas de grinding para suplir escasez de contenido.

## Estado de pruebas
Esta entrega valida esquemas, carga, referencias, 18 presupuestos de 36,
distribución 3/3/3/3/2/2/2 y compatibilidad de guardado. El efecto jugable de las
18 habilidades y los perfiles no está conectado todavía; no se atribuyen resultados
de las cinco pistas anteriores a este nuevo plantel. Probar Android físico queda pendiente.

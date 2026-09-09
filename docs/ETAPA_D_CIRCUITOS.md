# Etapa D — quince circuitos jugables

Se añaden diez trazados a los cinco existentes. Se conservan seis tapas activas,
la física, el controlador de IA, doce checkpoints por vuelta y la escena común
`levels/race.tscn`. Las dieciocho tapas del manifiesto de contenido siguen en preparación.

## Contenido y acceso

Menú **CIRCUITOS → Anterior/Siguiente → Desbloquear/Seleccionar → JUGAR**.
Jardín y Plaza se desbloquean por cero monedas; los demás usan la compra existente.
Los precios siguientes permiten probar el contenido antes de implementar copas.
No se exigen niveles ni podios inexistentes. Las compras anteriores se conservan.

| Circuito | Dificultad | Monedas | Elementos / sólidos | Personalidad |
| --- | --- | --- | --- | --- |
| Fuente Central | 1/10 | 0 | 10 / 6 | Curvas amplias; pocas rocas |
| Jardín Acuático | 2/10 | 0 | 12 / 3 | Hojas lentas; corrientes suaves |
| Plaza del Sol | 3/10 | 0 | 11 / 3 | Chorros espaciados; curvas abiertas |
| Canal Tropical | 4/10 | 100 | 28 / 10 | Ramas; hojas; pasos alrededor de islas |
| Canal Turbo | 4/10 | 160 | 15 / 4 | Franjas rápidas separadas por curvas de frenado |
| Remolino Azul | 5/10 | 150 | 25 / 9 | Remolinos y alternancia lenta/rápida |
| Cascada Express | 5/10 | 200 | 11 / 4 | Descensos separados por curvas de recuperación |
| Templo Sumergido | 6/10 | 240 | 15 / 12 | Islas alargadas: paso ancho sinuoso o paso estrecho directo |
| Fuente Neón | 7/10 | 280 | 14 / 4 | Paleta nocturna; rectas rápidas y salidas técnicas |
| Laberinto de Agua | 7/10 | 280 | 13 / 11 | Islas alternadas y estrechamientos; sin cruces ni bucles |
| Cascada Extrema | 8/10 | 200 | 27 / 11 | Trazado existente; alto riesgo de contactos |
| Ojo del Torbellino | 8/10 | 320 | 11 / 2 | Remolino central que pulsa; pasos laterales |
| Cascada del Titán | 8/10 | 320 | 13 / 5 | Objetos móviles y caídas; evita encadenar impactos |
| Tormenta Caribeña | 9/10 | 250 | 28 / 12 | Lluvia acotada; corrientes cambiantes; islas |
| Circuito Eclipse | 10/10 | 400 | 14 / 6 | Secciones de precisión, turbo, giro y salto, señalizadas |

Todos miden 18 000 unidades y admiten de una a tres vueltas. Las parejas de rocas
en Templo forman grupos alargados rodeables por ambos lados. Laberinto alterna
islas y obliga a leer los pasos; no hay cruces ni bifurcaciones externas. No se
prometen atajos de menor tiempo sin medir rutas equivalentes.

Ojo modula realmente atracción y fuerza tangencial: `pulse_depth` fija la reducción
máxima y `pulse_period` el período. La colisión conserva el radio máximo y la
animación comunica la intensidad; cero pulsación mantiene los remolinos anteriores.
Eclipse señaliza cuatro secciones (precisión, turbo, giro, salto). La primera exige
maniobrar entre obstáculos: **todavía no emite el evento de habilidad de Pixel**.

Jardín añade flores geométricas; Plaza/Templo/Laberinto, pilares; Neón/Eclipse,
balizas coloreadas sin luces ni shaders. Los demás combinan paleta, geometría y
distribución de elementos existentes. Música y assets se reutilizan.

## Estructura reutilizable

- `data/catalog.tres`: referencias a quince fichas `data/circuit_entries/*.tres`.
- Las fichas son CircuitDefinition sin features: nombre, precio, dificultad,
  geometría resumida, versión de récord y `layout_path` como cadena.
- `RacingCatalog.load_circuit(entry)` carga y valida únicamente el layout elegido,
  devuelve una copia y evita que las vueltas modifiquen el Resource compartido.
- `data/circuits/*.tres`: trazados completos con CircuitFeature y escenas compartidas.
- `RaceTrack` aplica los overrides antes de añadir cada componente al árbol.
  No hay escenas de carrera duplicadas ni un segundo controlador de IA.
- Los ocho recogibles buscan espacio libre si la posición original coincide con
  una isla o el recorrido de un obstáculo móvil; conservan sus efectos y cantidad.
- Un layout inválido cancela la entrada y regresa al menú con error en el log.
- Los IDs originales y record_version de Fuente/Cascada se mantienen. No se altera
  la partida ni se migra todavía el roster de tapas.

Para añadir otra pista: crear layout, crear ficha con metadata idéntica y ruta al
layout, registrar solo la ficha en el catálogo y ampliar validación. No referenciar
el layout con ExtResource desde la ficha: eso restauraría la carga anticipada.

## Presupuesto móvil y límites

Máximo actual: 28 elementos y doce sólidos. Se conserva el límite de 32 elementos,
pools VFX 48/96 y lluvia 16/36. Decoración estática con menor densidad en baja;
los remolinos sin pulsación no necesitan reloj físico propio. No se agregan
partículas, shaders, texturas ni cuerpos para la señalización.

Los obstáculos del trazado seleccionado permanecen instanciados. Esta entrega
reduce la carga simultánea de Resources del catálogo, no implementa activación
por sectores. Las mediciones de construcción y memoria son de Windows; no
demuestran FPS ni memoria de un teléfono Android.

## Validación reproducible

```powershell
& .\.tools\godot\Godot_v4.3-stable_win64_console.exe --headless --path . --fixed-fps 60 --script tests/test_circuit_loading.gd
& .\.tools\godot\Godot_v4.3-stable_win64_console.exe --headless --path . --fixed-fps 60 --script tests/test_all_courses.gd
& .\.tools\godot\Godot_v4.3-stable_win64_console.exe --headless --path . --fixed-fps 60 --script tests/test_matrix.gd
```

La matriz cubre 15 × 3 dificultades × 6 tapas, más quince carreras de tres vueltas:
285 carreras / 1 140 llegadas esperadas. El jugador se conduce mediante autopiloto
de prueba; el tacto manual requiere sesión en dispositivo. Puede filtrarse una
pista con `-- --circuit=ojo`.

`test_circuit_loading.gd` comprueba carga diferida, liberación, coherencia de metadata,
copias independientes y fuerza pulsante. `test_all_courses.gd` comprueba geometría,
spawns, margen de paso durante movimiento, orden de gates, meta y presupuesto
en ambas calidades; genera `user://course_loading_metrics.json`.
`test_android_layouts.gd` recorre las quince fichas en cinco resoluciones.

Los resultados finales y el estado de APK están en el reporte de implementación.
Siguiente etapa E: sesión de campeonato y cinco copas. Después, campeones,
migración/desbloqueos, interfaz y balance según el diseño.

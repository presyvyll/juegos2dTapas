# ART_ASSET_REQUIREMENTS
Los siguientes identificadores son tareas de arte, no rutas de archivos.
No existen sprites definitivos para las 18 tapas nuevas. Se utilizan CapArt,
CapPreview y las seis variantes procedurales de CapAppearance con paletas propias.
Texturas opcionales null conservan el dibujo existente; audio null debe ser seguro.

## Tapas
Cada prefijo de la tabla necesita: _SPRITE (64–128 px de referencia), _ICON (64 px),
_PORTRAIT (256 px), _VICTORY, _DEFEAT y _VFX. Usar atlas cuando corresponda;
no hacer dieciocho texturas de 4K. La animación de victoria actual se puede reutilizar
como placeholder. La pose de derrota definitiva sigue pendiente.

| Tapa | Prefijo TODO para los seis assets | Tema | Efecto requerido |
| --- | --- | --- | --- |
| Chispa | TODO_ART_CAP_CHISPA | Naranja solar | TODO_ART_ABILITY_CHISPA: Impulso Inicial |
| Rayo | TODO_ART_CAP_RAYO | Amarillo eléctrico | TODO_ART_ABILITY_RAYO: Sobrecarga |
| Titán | TODO_ART_CAP_TITAN | Metal industrial | TODO_ART_ABILITY_TITAN: Muro Móvil |
| Burbuja | TODO_ART_CAP_BURBUJA | Azul cristalino | TODO_ART_ABILITY_BURBUJA: Estabilidad Acuática |
| Torbellino | TODO_ART_CAP_TORBELLINO | Espiral azul y púrpura | TODO_ART_ABILITY_TORBELLINO: Mini Remolino |
| Fantasma | TODO_ART_CAP_FANTASMA | Blanco azulado | TODO_ART_ABILITY_FANTASMA: Flujo Fantasma |
| Brasa | TODO_ART_CAP_BRASA | Rojo y naranja | TODO_ART_ABILITY_BRASA: Turbo Incandescente |
| Neón | TODO_ART_CAP_NEON | Cian y magenta nocturnos | TODO_ART_ABILITY_NEON: Ritmo Neón |
| Ancla | TODO_ART_CAP_ANCLA | Azul marino | TODO_ART_ABILITY_ANCLA: Peso Muerto |
| Pixel | TODO_ART_CAP_PIXEL | Geometría verde y cian | TODO_ART_ABILITY_PIXEL: Trayectoria Perfecta |
| Trueno | TODO_ART_CAP_TRUENO | Grafito y amarillo | TODO_ART_ABILITY_TRUENO: Golpe de Trueno |
| Coral | TODO_ART_CAP_CORAL | Coral tropical | TODO_ART_ABILITY_CORAL: Segundo Aire |
| Meteoro | TODO_ART_CAP_METEORO | Grafito con estela naranja | TODO_ART_ABILITY_METEORO: Impulso Meteoro |
| Glacial | TODO_ART_CAP_GLACIAL | Hielo y blanco | TODO_ART_ABILITY_GLACIAL: Precisión Glacial |
| Cobra | TODO_ART_CAP_COBRA | Verde brillante | TODO_ART_ABILITY_COBRA: Ataque de Oportunidad |
| Roca | TODO_ART_CAP_ROCA | Gris y rojo | TODO_ART_ABILITY_ROCA: Inercia |
| Cometa | TODO_ART_CAP_COMETA | Azul y naranja | TODO_ART_ABILITY_COMETA: Estela Cometa |
| Eclipse | TODO_ART_CAP_ECLIPSE | Negro, violeta y oro | TODO_ART_ABILITY_ECLIPSE: Pulso Eclipse |

No copiar caras, insignias, siluetas, logos o efectos reconocibles de franquicias.
Accesorios y patrones deben distinguir arquetipos sin ocultar el borde de colisión.

## Circuitos
Cada prefijo requiere _BACKGROUND, _FOREGROUND, _DECORATIONS, _THUMBNAIL y _VFX.
Los obstáculos compartidos existentes ya tienen dibujo procedural. Solo crear
variantes visuales cuando la mecánica lo necesite; no duplicar scripts.

| Circuito | Prefijo TODO | Reutilización / arte específico |
| --- | --- | --- |
| Fuente Central | TODO_ART_TRACK_FUENTE | Trazado y arte procedural disponibles; thumbnail pendiente. Curvas amplias; pocas rocas |
| Jardín Acuático | TODO_ART_TRACK_JARDIN | Trazado pendiente; reutilizar agua y obstáculos existentes. Hojas lentas; corrientes suaves |
| Plaza del Sol | TODO_ART_TRACK_PLAZA | Trazado pendiente; reutilizar agua y obstáculos existentes. Chorros espaciados; curvas abiertas |
| Canal Tropical | TODO_ART_TRACK_TROPICAL | Trazado y arte procedural disponibles; thumbnail pendiente. Ramas; hojas; pasos alrededor de islas |
| Canal Turbo | TODO_ART_TRACK_CANAL_TURBO | Trazado pendiente; reutilizar agua y obstáculos existentes. Franjas rápidas separadas por curvas de frenado |
| Remolino Azul | TODO_ART_TRACK_REMOLINO | Trazado y arte procedural disponibles; thumbnail pendiente. Remolinos y alternancia lenta/rápida |
| Cascada Express | TODO_ART_TRACK_EXPRESS | Trazado pendiente; reutilizar agua y obstáculos existentes. Descensos separados por curvas de recuperación |
| Templo Sumergido | TODO_ART_TRACK_TEMPLO | Trazado pendiente; reutilizar agua y obstáculos existentes. Islas alargadas: paso ancho sinuoso o paso estrecho directo |
| Fuente Neón | TODO_ART_TRACK_NEON | Trazado pendiente; reutilizar agua y obstáculos existentes. Paleta nocturna; rectas rápidas y salidas técnicas |
| Laberinto de Agua | TODO_ART_TRACK_LABERINTO | Trazado pendiente; reutilizar agua y obstáculos existentes. Islas alternadas y estrechamientos; sin cruces ni bucles |
| Cascada Extrema | TODO_ART_TRACK_CASCADA | Trazado y arte procedural disponibles; thumbnail pendiente. Trazado existente; alto riesgo de contactos |
| Ojo del Torbellino | TODO_ART_TRACK_OJO | Trazado pendiente; reutilizar agua y obstáculos existentes. Remolino central que pulsa; pasos laterales |
| Cascada del Titán | TODO_ART_TRACK_TITAN | Trazado pendiente; reutilizar agua y obstáculos existentes. Objetos móviles y caídas; evita encadenar impactos |
| Tormenta Caribeña | TODO_ART_TRACK_TORMENTA | Trazado y arte procedural disponibles; thumbnail pendiente. Lluvia acotada; corrientes cambiantes; islas |
| Circuito Eclipse | TODO_ART_TRACK_ECLIPSE | Trazado pendiente; reutilizar agua y obstáculos existentes. Secciones de precisión, turbo, giro y salto, señalizadas |

## Campeones, copas y UI
Cinco marcos de copa (Bronce/Plata/Oro/Maestra/Leyenda), splash reutilizable de final,
placa de nombre, badge de rareza y título Leyenda. Retratos usan la tapa favorita
del rival mientras no exista arte definitivo. TODO_ART_TRAIL_LUNAR para recompensa
de Nyx; no mostrar un archivo ficticio. Perla ya existe como variante de color.

## Audio seguro
RivalDefinition: intro_audio y victory_audio opcionales.
ChampionshipDefinition: intro_audio, race_audio y complete_audio opcionales.
CapAbilityDefinition: activation_audio opcional. Unlock y XP utilizarán señal del
guardado y un sonido existente o referencia null hasta incorporar audio original.
Mantener la música/sonidos sintetizados del proyecto; no importar audio protegido.
Todo clip pendiente debe poder faltar sin impedir cargar un Resource o una carrera.

# Entrega arcade Android

## Bloques implementados

| Bloque | Resultado | Archivos principales |
| --- | --- | --- |
| Tapas y personalidades | Seis diseños originales, expresiones y accesorios; recursos ampliables y retratos compartidos | `data/appearances/`, `data/catalog.tres`, `scripts/resources/cap_appearance.gd`, `scripts/visuals/cap_art.gd`, `cap_illustration.gd`, `cap_presentation.gd` |
| Movimiento y VFX | Flotación, inclinación, squash/stretch, aterrizaje, estelas, impactos y celebración sin modificar cuerpos físicos | `scripts/actors/cap.gd`, `scripts/vfx/water_vfx_pool.gd` |
| Turbo | Configuración independiente, barra, estado, estela, sonido y haptic; parámetros originales conservados | `scripts/resources/turbo_config.gd`, `data/turbo/default.tres` |
| Power-ups | Resource base extensible; burbuja contra empujones de rivales durante cinco segundos y recarga de media barra | `scripts/resources/powerup_definition.gd`, `scripts/powerups/`, `data/powerups/` |
| Fuente | Espuma animada cercana a cámara; ocho pickups reutilizables por pista, conservando corrientes, obstáculos, hojas, rampas y remolinos | `scripts/visuals/water_surface.gd`, `scripts/levels/race.gd` |
| Cámara y presentación | Entrada suave, zoom de turbo, shake limitado, cuenta atrás con sonido/partículas y enfoque del ganador | `scripts/camera/race_camera.gd`, `scripts/levels/race.gd` |
| HUD y resultados | Posición destacada, estado del power-up, turbo multitáctil, resultados animados y retrato del ganador | `scripts/ui/race_hud.gd` |
| Menús y selector | Fondo arcade original, título, personalidad, estadísticas, habilidad, selección y personalización existentes | `scripts/ui/main_menu.gd`, `menu_backdrop.gd`, `selection_page.gd`, `cap_preview.gd`, `ui_style.gd` |
| Android | Landscape conservado, zonas seguras, controles táctiles, calidad baja/alta, compilación APK y preparación Gradle/AAB | `export_presets.cfg`, `tools/build_debug.ps1`, `build_aab.ps1`, `setup_aab.py` |

No se crearon nuevas escenas `.tscn`: los componentes se instancian en las escenas
existentes. `scenes/actors/player_cap.tscn` enlaza la nueva presentación. Se conservan
los assets previos y el canal prototipo. No se cambió la versión de Godot ni se
trabajó en plataformas Apple. No se publicó código ni aplicaciones.

## Comportamiento de los power-ups

Se recogen por contacto, por el jugador o los rivales, únicamente durante carrera.
Reaparecen a los ocho segundos y se reutiliza el mismo nodo. La recarga nunca supera
el máximo. Recoger otra burbuja renueva hasta cinco segundos, sin acumular duración
ilimitada. La burbuja evita impulsos recibidos de otras tapas; las paredes siguen
siendo sólidas y el contacto físico continúa funcionando. Pausar congela duración
y reaparición; reiniciar crea estado limpio. No hay inventario ni un botón adicional.

Para ampliar el sistema, crear un Resource que herede de `PowerUpDefinition` e
implemente `apply(cap)`, y asignarlo a un `RacingPickup`. El dibujo del icono es un
placeholder procedural reemplazable; no hay dependencias de plugins.

## Verificación y correcciones

Suite reproducible: `./tools/test_android.ps1 -WithRendering`. El runner guarda
logs por prueba y trata los errores de scripts como fallo aunque Godot termine
con código cero.

- Matriz de 38 carreras: seis tapas, tres dificultades, dos circuitos y dos casos
  de tres vueltas; 152 llegadas y cero fallos.
- Integración: compras, guardado, recuperación, entradas, checkpoints, vueltas,
  pausa, recompensa única y carreras completas sin fallos.
- Power-ups: protección, expiración, recarga limitada, recogida única, reaparición,
  bloqueo antes/después de carrera, reinicio y detección física real del Area2D.
- Presentación: seis estilos distintos y pools acotados de 48/96 efectos.
- Ciclo móvil: pausa, regreso, guardado y selección de 30/60 FPS sin fallos.
- HUD táctil: segundo dedo para pausa, liberación de dirección, exclusión de botones
  y disponibilidad del turbo inmediata al recibir energía; cero fallos.
- Transiciones: 20 reinicios rápidos sin nodos retenidos.
- Recursos empaquetados: la integración completa vuelve a pasar con los assets y
  scripts compilados extraídos del APK y del AAB, ejecutados en Godot 4.3 de escritorio.
  Ambos producen las mismas llegadas; esta prueba no ejecuta el binario Android.
- Pantallas: límites de botones y etiquetas comprobados en menú, selector, ajustes,
  HUD, pausa y resultados a 1280×720, 1440×720, 1560×720, 1600×720 y 2340×1080.
  Capturas generadas con Compatibility; revisados selector, carrera y resultados.

Durante el desarrollo se corrigieron inferencias de tipo GDScript en el agua y
en una prueba, la máscara de detección de pickups, un solapamiento residual del
montaje de pruebas, los márgenes mínimos de barras y la espera del daemon Gradle.
La primera compilación AAB detectó que faltaba la plataforma SDK 34.

La simulación sigue usando los valores físicos previos. Los tiempos pueden variar
respecto del primer bloque porque ahora los corredores recogen power-ups.

## Límites verificables

No hay teléfono conectado a ADB. No se acreditan 60 FPS reales, temperatura,
consumo, latencia táctil, vibración ni recortes físicos de cámaras/notches.
`tools/collect_android_metrics.ps1` recoge información de un dispositivo autorizado
sin instalar, borrar ni cambiar su configuración. `gfxinfo` puede no cubrir el
SurfaceView del juego: usar Perfetto para medir los fotogramas del renderizado.

La prueba de tamaños utiliza ventanas de escritorio y coordenadas lógicas de Godot;
no sustituye ensayos con distintas densidades físicas ni zonas seguras Android.

## Compilación y distribución

APK y AAB de depuración generados y firmados con la clave existente. El APK pasa
apksigner (v1/v2/v3); el AAB pasa bundletool y jarsigner. La exportación inicial de
Godot dejó el AAB sin firma: `tools/sign_aab.ps1` completa la firma cuando falta y
verifica el resultado, integrado al final de `build_aab.ps1`. Certificado de pruebas
autofirmado, sin crear ni modificar keystores. Hashes en `builds/artifacts.json`.

Artefactos finales: APK de 24.926.763 bytes y AAB de 24.871.409 bytes. El AAB
firmado se volvió a validar con bundletool 1.15.2, sin errores.

1. Preparar Godot 4.3 y las herramientas locales según `MOBILE.md`.
2. `./tools/build_debug.ps1` genera y verifica el APK de pruebas ARM64.
3. `python tools/setup_aab.py` instala la plantilla oficial Gradle si no existe.
4. Instalar `platforms;android-34` mediante sdkmanager y aceptar su licencia.
5. `./tools/build_aab.ps1` genera un AAB de depuración mediante el preset Android AAB.
6. Para una firma de lanzamiento existente, proporcionar las variables de entorno
   `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` y
   `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`, y ejecutar con `-Release`.

No guardar valores secretos en scripts ni Git. Los keystores, cachés Gradle, builds
y credenciales están excluidos. El flujo no crea ni sustituye claves de lanzamiento.
Referencia técnica: [exportación Android en Godot 4.3](https://docs.godotengine.org/en/4.3/tutorials/export/exporting_for_android.html).

Generar un AAB no significa que esté listo para Google Play. La plantilla 4.3 usa
target SDK 34; la documentación vigente exige API 36 para nuevas apps y actualizaciones
desde el 31 de agosto de 2026. La compatibilidad de bibliotecas nativas con páginas
de memoria de 16 KB también requiere validación. Se conserva Godot 4.3 conforme a
la restricción del proyecto: esa adaptación de distribución requiere un trabajo
específico sobre la cadena de compilación antes de publicar.
Fuentes: [requisito de API](https://developer.android.com/google/play/requirements/target-sdk),
[páginas de 16 KB](https://developer.android.com/guide/practices/page-sizes).

## Assets y continuación

El arte procedural es original y reemplazable. El inventario de tamaños para un
artista está en `ANDROID_ARCADE_DIAGNOSTICO.md`: cuerpos de 256×256, retratos de
512×512, atlas de agua/impactos de 512×512, iconos de 128×128 y paneles nine-patch.
Los campos `body_texture` y `portrait_texture` permiten sustituir las tapas sin
cambiar física. Audio WAV existente reutilizado en inicio, pickups, turbo e impacto.

El siguiente paso externo es jugar y medir en Android real; después, preparar la
compatibilidad actual de publicación y firmar con una clave de lanzamiento del
propietario. No están pendientes más power-ups del alcance acordado: se priorizaron
dos efectos y la arquitectura reutilizable, tal como permite la solicitud.

## Inventario de archivos del desarrollo arcade

- .gitignore
- README.md
- android/.build_version
- android/.gdignore
- data/appearances/coco.tres
- data/appearances/coral.tres
- data/appearances/menta.tres
- data/appearances/oceano.tres
- data/appearances/sol.tres
- data/appearances/uva.tres
- data/caps/coco.tres
- data/caps/coral.tres
- data/caps/menta.tres
- data/caps/oceano.tres
- data/caps/sol.tres
- data/caps/uva.tres
- data/catalog.tres
- data/powerups/recharge.tres
- data/powerups/shield.tres
- data/turbo/default.tres
- docs/ANDROID_ARCADE_AVANCE.md
- docs/ANDROID_ARCADE_DIAGNOSTICO.md
- docs/ANDROID_ENTREGA.md
- export_presets.cfg
- scenes/actors/player_cap.tscn
- scripts/actors/cap.gd
- scripts/camera/race_camera.gd
- scripts/input/player_input.gd
- scripts/levels/race.gd
- scripts/powerups/pickup.gd
- scripts/powerups/recharge_effect.gd
- scripts/powerups/shield_effect.gd
- scripts/resources/cap_appearance.gd
- scripts/resources/cap_definition.gd
- scripts/resources/powerup_definition.gd
- scripts/resources/racing_catalog_data.gd
- scripts/resources/turbo_config.gd
- scripts/services/catalog.gd
- scripts/services/save_manager.gd
- scripts/ui/cap_preview.gd
- scripts/ui/main_menu.gd
- scripts/ui/menu_backdrop.gd
- scripts/ui/race_hud.gd
- scripts/ui/selection_page.gd
- scripts/ui/ui_style.gd
- scripts/vfx/water_vfx_pool.gd
- scripts/visuals/cap_art.gd
- scripts/visuals/cap_illustration.gd
- scripts/visuals/cap_presentation.gd
- scripts/visuals/cap_visual.gd
- scripts/visuals/water_surface.gd
- tests/test_android_layouts.gd
- tests/test_arcade.gd
- tests/test_powerups.gd
- tests/test_touch_hud.gd
- tools/build_aab.ps1
- tools/build_debug.ps1
- tools/collect_android_metrics.ps1
- tools/setup_aab.py
- tools/sign_aab.ps1
- tools/test_android.ps1

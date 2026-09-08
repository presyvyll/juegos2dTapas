# Preparación de carrera — 8 de septiembre de 2026

JUGAR abre una pantalla donde se elige dificultad y de una a tres vueltas antes
de comenzar. Muestra el circuito seleccionado, su récord local para esa combinación
y una explicación breve de dirección, impulso, turbo y pickups. Los cambios se
guardan al iniciar la carrera y las marcas siguen separadas por circuito,
dificultad y vueltas.

La selección de vueltas se aplica a una copia del circuito para mantener intactos
los recursos compartidos. Las partidas anteriores usan una vuelta; valores inválidos
se descartan. Las pruebas detectaron y corrigieron la conversión de números JSON
a flotantes, que inicialmente hacía perder la selección guardada.

Archivos: `scripts/ui/race_setup.gd` (nuevo), `main_menu.gd`, `settings_page.gd`,
`scripts/services/save_manager.gd` y `scripts/levels/race.gd`. No hay nuevas escenas.
Pruebas: `tests/test_race_setup.gd`, integración existente y límites de interfaz
en cinco resoluciones. El runner `tools/test_android.ps1` incluye la prueba nueva.

El APK ARM64 se actualiza para teléfonos; el preset Android Emulator permite
generar el APK x86_64 para probar en el emulador de Windows. El AAB de la entrega
arcade anterior debe regenerarse antes de distribuir estas funcionalidades.

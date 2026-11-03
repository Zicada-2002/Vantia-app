# Guía de contribución

## Ramas
- `main`: protegida, siempre desplegable.
- `feat/F-xx-descripcion`, `fix/descripcion`, `chore/descripcion`, `docs/descripcion`.

## Commits (Conventional Commits)
```
feat(payments): F-21 formulario de pago en efectivo
fix(auth): reenviar verificación respeta el cooldown
chore(ci): cachear dependencias de pub
```
Tipos: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`, `perf`, `style`.

## Pull requests
1. Un PR por feature (`F-xx`), enlazado a su issue con `Closes #n`.
2. CI en verde: `dart format`, `flutter analyze`, `flutter test`.
3. Al menos una aprobación. Merge con **squash**.
4. Capturas o video si hay cambios de UI (modo claro y oscuro).

## Definition of Done
- [ ] Criterios de aceptación del issue cumplidos
- [ ] Tests (unit y widget) de la lógica nueva
- [ ] Textos en `app_es.arb`, nunca en el código
- [ ] Montos en céntimos y fechas en America/Lima
- [ ] Reglas de Firestore y Storage actualizadas y testeadas, si aplica
- [ ] Sin warnings de `flutter analyze`

## Estilo
- `flutter_lints` + `very_good_analysis`.
- Feature-first ([docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)).
- Prohibido el acceso a Firestore desde widgets: solo a través de repositorios.

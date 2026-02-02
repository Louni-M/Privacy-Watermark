# Memory - Passport Filigrane

## 2026-02-02 Track: mvp_20260201 (MVP Passport Filigrane)

### Key Learnings
- **Flet & Mocking**: Tester les contrôles Flet sans lancer l'app nécessite de mocker intensivement `ft.Page` et d'inspecter l'arbre des contrôles via `page.add.call_args`.
- **Pillow & Alpha Composite**: Pour un tiling propre avec rotation, il est plus efficace de créer un "stamp" pivoté et de le coller en boucle plutôt que de pivoter un calque géant.
- **Réactivité**: Un debounce de 200ms est le "sweet spot" entre fluidité perçue et charge CPU sur macOS lors de la manipulation de sliders.
- **MacOS Permissions**: L'accès aux fichiers peut parfois échouer silencieusement si l'app n'est pas lancée depuis un terminal avec les accès "Full Disk Access" ou si on tente d'accéder à des dossiers protégés sans dialogue explicite.

### Patterns Discovered
- **Debounce Pattern (Flet)**: Utiliser `threading.Timer(delay, task)` avec `.cancel()` au début de chaque appel pour éviter les rafales de mises à jour UI.
- **Mock FilePicker handler**: Pour tester les actions asynchrones de FilePicker, il faut invoquer manuellement le callback stocké dans `on_result` avec un mock de `FilePickerResultEvent`.

### Issues Encountered
- **AttributeError: module 'flet_core.colors' has no attribute 'SUCCESS'**: `SUCCESS` n'existe pas dans toutes les versions de Flet, préférer `ft.colors.GREEN`.
- **TypeError: 'EventHandler' object is not callable**: Flet enveloppe parfois les callbacks. Il faut accéder à `.handler` ou gérer le type si on les appelle manuellement en test.

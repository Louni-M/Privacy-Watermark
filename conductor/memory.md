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

## 2026-02-02 Track: pdf_support_20260202 (Support PDF)

### Key Learnings
- **PDF Core Management**: PyMuPDF (`fitz`) est extrêmement rapide pour le rendu, mais nécessite une gestion fine des PixMaps pour éviter les fuites de mémoire lors du traitement de gros fichiers.
- **Multi-Format Export**: Séparer la logique de sauvegarde (`save_watermarked_pdf` vs `save_pdf_as_images`) permet une meilleure flexibilité UI sans alourdir le code principal.
- **Debounce Efficiency**: Le passage à une structure de classe a simplifié la gestion du `Timer` pour le debounce, évitant les conflits de variables globales.

### Patterns Discovered
- **Shared Rendering Pattern**: `apply_watermark_to_pil_image` sert de pont unique entre le moteur Pillow (image) et Fitz (PDF page-by-page), garantissant un rendu visuel identique sur tous les supports.
- **Class-Based UI Wrapper**: Encapsuler l'app Flet dans une classe (`PassportFiligraneApp`) facilite l'accès aux états (`self.pdf_doc`) sans passer par des `nonlocal`.

### Issues Encountered
- **Flet Callback Wrapping**: Les `EventHandler` de Flet ne sont pas toujours directement appelables en test. Un helper `call_handler` est nécessaire pour inspecter `.handler` ou `.func`.
- **Indentation & Async**: Attention à l'indentation lors de l'utilisation de `Timer`, qui peut masquer des erreurs de logique si les callbacks accèdent à des variables modifiées prématurément.

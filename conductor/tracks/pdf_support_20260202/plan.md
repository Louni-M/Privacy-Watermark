# Plan: Support PDF pour Passport Filigrane

## Phase 1: Setup & Dépendances [checkpoint: 754e076]

- [x] Task 1.1: Ajouter PyMuPDF aux dépendances [2e3df45]
  - [x] Mettre à jour `requirements.txt` avec `pymupdf>=1.24.0`
  - [x] Mettre à jour `tech-stack.md` avec la documentation PyMuPDF
  - [x] Vérifier l'installation avec `pip install -r requirements.txt`

- [ ] Task: Conductor - User Manual Verification 'Phase 1: Setup & Dépendances' (Protocol in workflow.md)

## Phase 2: Module de traitement PDF (Core)

- [x] Task 2.1: Écrire les tests pour le chargement PDF
  - [x] Test: charger un PDF valide et obtenir le nombre de pages
  - [x] Test: charger un PDF protégé retourne une erreur appropriée
  - [x] Test: charger un PDF corrompu retourne une erreur appropriée
  - [x] Vérifier que les tests échouent (Red Phase)

- [x] Task 2.2: Implémenter le chargement PDF [5057be5]
  - [x] Créer fonction `load_pdf(file_path)` retournant un objet document et le nombre de pages
  - [x] Gérer les exceptions pour PDF protégés (`fitz.PasswordError`)
  - [x] Gérer les exceptions pour PDF corrompus
  - [x] Vérifier que les tests passent (Green Phase)

- [x] Task 2.3: Écrire les tests pour le rendu de page en image
  - [x] Test: convertir la première page d'un PDF en image PIL
  - [x] Test: vérifier les dimensions de l'image générée
  - [x] Vérifier que les tests échouent (Red Phase)

- [x] Task 2.4: Implémenter le rendu de page en image [10e9015]
  - [x] Créer fonction `pdf_page_to_image(doc, page_num)` retournant une image PIL
  - [x] Utiliser `page.get_pixmap()` de PyMuPDF
  - [x] Vérifier que les tests passent (Green Phase)

- [x] Task 2.5: Écrire les tests pour l'application du filigrane sur PDF
  - [x] Test: appliquer un filigrane sur toutes les pages d'un PDF
  - [x] Test: vérifier que le filigrane est visible sur chaque page
  - [x] Vérifier que les tests échouent (Red Phase)

- [x] Task 2.6: Implémenter l'application du filigrane sur PDF [144a04d]
  - [x] Créer fonction `apply_watermark_to_pdf(doc, watermark_params)`
  - [x] Réutiliser la logique de filigrane existante pour chaque page
  - [x] Vérifier que les tests passent (Green Phase)

- [ ] Task: Conductor - User Manual Verification 'Phase 2: Module de traitement PDF' (Protocol in workflow.md)

## Phase 3: Intégration UI

- [ ] Task 3.1: Écrire les tests pour la détection du type de fichier
  - [ ] Test: détecter un fichier image (jpg, png)
  - [ ] Test: détecter un fichier PDF
  - [ ] Vérifier que les tests échouent (Red Phase)

- [ ] Task 3.2: Implémenter la détection du type de fichier
  - [ ] Créer fonction `detect_file_type(file_path)` retournant "image" ou "pdf"
  - [ ] Mettre à jour le FilePicker pour accepter `.pdf`
  - [ ] Vérifier que les tests passent (Green Phase)

- [ ] Task 3.3: Adapter l'UI pour afficher les informations PDF
  - [ ] Afficher "PDF (X pages)" quand un PDF est chargé
  - [ ] Afficher la prévisualisation de la première page
  - [ ] Conserver le comportement existant pour les images

- [ ] Task 3.4: Ajouter le sélecteur de format d'export
  - [ ] Créer un composant Dropdown ou RadioButtons pour le choix du format
  - [ ] Visible uniquement quand un PDF est chargé
  - [ ] Options: "Exporter en PDF" / "Exporter en Images (JPG)"

- [ ] Task: Conductor - User Manual Verification 'Phase 3: Intégration UI' (Protocol in workflow.md)

## Phase 4: Export PDF

- [ ] Task 4.1: Écrire les tests pour l'export PDF
  - [ ] Test: exporter un PDF filigrané au format PDF
  - [ ] Test: exporter un PDF filigrané en images JPG séparées
  - [ ] Test: vérifier la qualité des images exportées (90)
  - [ ] Vérifier que les tests échouent (Red Phase)

- [ ] Task 4.2: Implémenter l'export PDF vers PDF
  - [ ] Créer fonction `save_watermarked_pdf(doc, output_path)`
  - [ ] Utiliser `doc.save()` de PyMuPDF
  - [ ] Intégrer avec le FilePicker pour la sauvegarde
  - [ ] Vérifier que les tests passent (Green Phase)

- [ ] Task 4.3: Implémenter l'export PDF vers Images
  - [ ] Créer fonction `save_pdf_as_images(doc, output_dir, base_name)`
  - [ ] Générer un fichier JPG par page (qualité 90)
  - [ ] Nommage: `{base_name}_page_001.jpg`, etc.
  - [ ] Vérifier que les tests passent (Green Phase)

- [ ] Task: Conductor - User Manual Verification 'Phase 4: Export PDF' (Protocol in workflow.md)

## Phase 5: Gestion d'erreurs & Polish

- [ ] Task 5.1: Implémenter les messages d'erreur SnackBar
  - [ ] Message pour PDF protégé par mot de passe
  - [ ] Message pour PDF corrompu/illisible
  - [ ] Vérifier la cohérence avec les erreurs images existantes

- [ ] Task 5.2: Tests d'intégration end-to-end
  - [ ] Test: workflow complet image (régression)
  - [ ] Test: workflow complet PDF vers PDF
  - [ ] Test: workflow complet PDF vers Images

- [ ] Task 5.3: Revue de code et refactoring
  - [ ] Vérifier la couverture de tests (>80%)
  - [ ] Nettoyer le code et ajouter les docstrings manquants
  - [ ] Mettre à jour la documentation si nécessaire

- [ ] Task: Conductor - User Manual Verification 'Phase 5: Gestion d'erreurs & Polish' (Protocol in workflow.md)

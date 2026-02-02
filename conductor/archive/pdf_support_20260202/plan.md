# Plan: Support PDF pour Passport Filigrane

## Phase 1: Setup & Dépendances [checkpoint: 754e076]

- [x] Task 1.1: Ajouter PyMuPDF aux dépendances [2e3df45]
  - [x] Mettre à jour `requirements.txt` avec `pymupdf>=1.24.0`
  - [x] Mettre à jour `tech-stack.md` avec la documentation PyMuPDF
  - [x] Vérifier l'installation avec `pip install -r requirements.txt`

- [ ] Task: Conductor - User Manual Verification 'Phase 1: Setup & Dépendances' (Protocol in workflow.md)

## Phase 2: Module de traitement PDF (Core) [checkpoint: 7214131]

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

## Phase 3: Intégration UI [checkpoint: f2730c7]

- [x] Task 3.1: Écrire les tests pour la détection du type de fichier [a76fb24]
  - [x] Test: détecter un fichier image (jpg, png)
  - [x] Test: détecter un fichier PDF
  - [x] Vérifier que les tests échouent (Red Phase)

- [x] Task 3.2: Implémenter la détection du type de fichier [a76fb24]
  - [x] Créer fonction `detect_file_type(file_path)` retournant "image" ou "pdf"
  - [x] Mettre à jour le FilePicker pour accepter `.pdf`
  - [x] Vérifier que les tests passent (Green Phase)

- [x] Task 3.3: Adapter l'UI pour afficher les informations PDF [a76fb24]
  - [x] Afficher "PDF (X pages)" quand un PDF est chargé
  - [x] Afficher la prévisualisation de la première page
  - [x] Conserver le comportement existant pour les images

- [x] Task 3.4: Ajouter le sélecteur de format d'export [a76fb24]
  - [x] Créer un composant Dropdown ou RadioButtons pour le choix du format
  - [x] Visible uniquement quand un PDF est chargé
  - [x] Options: "Exporter en PDF" / "Exporter en Images (JPG)"

- [ ] Task: Conductor - User Manual Verification 'Phase 3: Intégration UI' (Protocol in workflow.md)

## Phase 4: Export PDF [checkpoint: 36362d0]

- [x] Task 4.1: Écrire les tests pour l'export PDF [a76fb24]
  - [x] Test: exporter un PDF filigrané au format PDF
  - [x] Test: exporter un PDF filigrané en images JPG séparées
  - [x] Test: vérifier la qualité des images exportées (90)
  - [x] Vérifier que les tests passent (Green Phase)

- [x] Task 4.2: Implémenter l'export PDF vers PDF [36362d0]
  - [x] Créer fonction `save_watermarked_pdf(doc, output_path)`
  - [x] Utiliser `doc.save()` de PyMuPDF
  - [x] Intégrer avec le FilePicker pour la sauvegarde
  - [x] Vérifier que les tests passent (Green Phase)

- [x] Task 4.3: Implémenter l'export PDF vers Images [36362d0]
  - [x] Créer fonction `save_pdf_as_images(doc, output_dir, base_name)`
  - [x] Générer un fichier JPG par page (qualité 90)
  - [x] Nommage: `{base_name}_page_001.jpg`, etc.
  - [x] Intégrer avec le FilePicker pour la sauvegarde
  - [x] Vérifier que les tests passent (Green Phase)

- [ ] Task: Conductor - User Manual Verification 'Phase 4: Export PDF' (Protocol in workflow.md)

## Phase 5: Gestion d'erreurs & Polish
## Phase 5: Gestion d'erreurs & Polish [~]

## Phase 5: Gestion d'erreurs & Polish [checkpoint: 2413a88]

- [x] Task 5.1: Implémenter les messages d'erreur SnackBar [2413a88]
  - [x] Message pour PDF protégé par mot de passe
  - [x] Message pour PDF corrompu/illisible
  - [x] Vérifier la cohérence avec les erreurs images existantes

- [x] Phase 6: Options de Style (Couleur) [checkpoint: 22b43ae]
    - [x] Task 6.1: Color Tests (Implemented & Verified)
    - [x] Task 6.2: Rendering Support (Implemented & Verified)
    - [x] Task 6.3: UI Integration (Implemented)

- [x] Task: Conductor - User Manual Verification 'Phase 5: Gestion d'erreurs & Polish' (Protocol in workflow.md)

## Phase 6: Options de Style (Couleur) [checkpoint: 22b43ae]

- [x] Task 6.1: Écrire les tests pour la sélection de couleur [22b43ae]
  - [x] Test: appliquer un filigrane blanc, noir et gris
  - [x] Vérifier que la couleur est correctement transmise au moteur de rendu

- [x] Task 6.2: Mettre à jour le moteur de rendu PDF/Image [22b43ae]
  - [x] Adapter `apply_watermark_to_pil_image` pour accepter un paramètre `color`
  - [x] Gérer les options: "Blanc", "Noir", "Gris"

- [x] Task 6.3: Intégrer le sélecteur dans l'UI [22b43ae]
  - [x] Ajouter un Dropdown pour la couleur (Blanc par défaut)
  - [x] Mettre à jour `update_preview` pour prendre en compte la couleur

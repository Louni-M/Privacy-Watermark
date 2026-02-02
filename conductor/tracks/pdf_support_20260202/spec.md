# Spec: Support PDF pour Passport Filigrane

## Overview

Étendre l'application Passport Filigrane pour supporter le filigranage de fichiers PDF en plus des images existantes (JPG, PNG). Cette fonctionnalité permet aux utilisateurs de protéger leurs documents d'identité au format PDF avec le même système de filigrane diagonal répétitif.

## Functional Requirements

### FR-1: Import de fichiers PDF
- Le FilePicker existant doit accepter les fichiers PDF en plus des formats images (JPG, PNG, JPEG).
- L'application détecte automatiquement le type de fichier et adapte son comportement.
- Les extensions acceptées sont : `.jpg`, `.jpeg`, `.png`, `.pdf`.

### FR-2: Traitement PDF multi-pages
- Toutes les pages du PDF sont filigranées automatiquement avec les mêmes paramètres.
- La prévisualisation affiche uniquement la première page du PDF.
- L'interface affiche le nombre total de pages du PDF chargé.

### FR-3: Prévisualisation PDF
- La première page du PDF est convertie en image pour la prévisualisation.
- Les contrôles de filigrane (texte, opacité, taille, espacement) s'appliquent en temps réel sur la prévisualisation.
- Le comportement de debounce (200ms) existant est conservé.

### FR-4: Export flexible
- **Export PDF** : Le PDF filigrané est sauvegardé au format PDF.
- **Export Images** : Chaque page du PDF est exportée en image JPG séparée (qualité 90).
- L'utilisateur choisit le format d'export via l'interface.
- Pour les images sources (non-PDF), le comportement d'export actuel (JPG) est conservé.

### FR-5: Gestion d'erreurs PDF
- Les PDF protégés par mot de passe affichent une erreur SnackBar : "Ce PDF est protégé par mot de passe et ne peut pas être ouvert."
- Les PDF corrompus ou illisibles affichent une erreur SnackBar : "Impossible de lire ce fichier PDF."
- Cohérent avec la gestion d'erreurs existante pour les images.

## Non-Functional Requirements

### NFR-1: Performance
- Temps de chargement d'un PDF < 3 secondes pour un document de 10 pages.
- Temps d'export < 5 secondes pour un PDF de 10 pages.

### NFR-2: Dépendances
- Nouvelle dépendance : PyMuPDF (`fitz`) pour le traitement PDF.
- Mise à jour de `requirements.txt` requise.

## Tech Stack Update

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| Traitement PDF | PyMuPDF (fitz) | Lecture, rendu et écriture de fichiers PDF |

## UI Changes

### Indicateur de type de fichier
- Afficher "Image" ou "PDF (X pages)" selon le fichier chargé.

### Sélecteur de format d'export (PDF uniquement)
- Visible uniquement quand un PDF est chargé.
- Options : "Exporter en PDF" / "Exporter en Images (JPG)".
- Peut être un `Dropdown` ou des `RadioButtons`.

## Acceptance Criteria

- [ ] AC-1: L'utilisateur peut sélectionner un fichier PDF via le FilePicker existant.
- [ ] AC-2: La première page du PDF s'affiche en prévisualisation avec le filigrane.
- [ ] AC-3: Les contrôles (texte, opacité, taille, espacement) modifient la prévisualisation en temps réel.
- [ ] AC-4: L'utilisateur peut exporter le PDF filigrané au format PDF.
- [ ] AC-5: L'utilisateur peut exporter le PDF filigrané en images JPG séparées.
- [ ] AC-6: Un PDF protégé par mot de passe affiche un message d'erreur approprié.
- [ ] AC-7: Un PDF corrompu affiche un message d'erreur approprié.
- [ ] AC-8: Les images (JPG/PNG) continuent de fonctionner comme avant.

## Out of Scope

- Saisie de mot de passe pour PDF protégés.
- Sélection de pages spécifiques à filigraner.
- Navigation entre les pages pour la prévisualisation.
- Support des PDF avec formulaires interactifs.
- OCR ou extraction de texte du PDF.

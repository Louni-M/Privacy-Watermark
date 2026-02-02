# Initial Concept

Application macOS locale pour filigraner des documents d'identité (protection vie privée), sans utiliser Xcode.

## Stack Technique
- **Langage:** Python 3.x
- **UI Framework:** Flet (UI moderne et réactive style Flutter)
- **Traitement d'image:** Pillow (PIL)

## Architecture de l'Interface
Une fenêtre desktop avec deux colonnes :
- **Colonne gauche:** Contrôles (Texte du filigrane, Slider Opacité, Slider Taille Police, Slider Espacement)
- **Colonne droite:** Zone de prévisualisation de l'image

---

# Product Guide - Passport Filigrane

## Vision

Passport Filigrane est une application macOS locale permettant de filigraner des documents d'identité pour protéger la vie privée des utilisateurs. L'application offre une interface moderne et intuitive pour ajouter des filigranes textuels répétitifs en diagonale sur des images, empêchant leur réutilisation frauduleuse.

## Utilisateurs Cibles

### Particuliers
- Personnes partageant régulièrement des documents d'identité en ligne (locations, inscriptions, démarches administratives)
- Utilisateurs soucieux de leur vie privée numérique

### Professionnels
- Agents immobiliers manipulant des pièces d'identité de locataires
- Services RH traitant des documents d'employés
- Notaires et professions juridiques
- Tout professionnel ayant l'obligation de protéger les données personnelles de tiers

## Fonctionnalités

### v1.0 (MVP) - [x]
- **Sélection de fichier** : Import via FilePicker (formats JPG/PNG/JPEG/PDF).
- **Contrôles du filigrane** :
  - Texte personnalisable avec mise à jour temps réel.
  - Opacité ajustable (0-100%).
  - Taille de police ajustable (12-72px).
  - Espacement ajustable (50-300px) dynamisant la densité du tiling.
  - **Couleur personnalisable** : Blanc (par défaut), Noir, Gris.
- **Prévisualisation en temps réel** : Affichage via `src_base64` avec debounce de 200ms pour la fluidité.
- **Gestion des erreurs** : Notifications via SnackBar pour les erreurs de format, de corruption ou de permissions.
- **Export** : Sauvegarde JPEG (qualité 90) via FilePicker.

### v1.1 (PDF Support & Style) - [x]
- **Support PDF** : Import et filigranage de fichiers PDF multi-pages (via PyMuPDF).
- **Options de Couleur** : Choix de la couleur du texte (Blanc, Noir, Gris).
- **Export Flexible** : Sauvegarde au format PDF ou en séquence d'images JPG.
- **Détails PDF** : Affichage du nombre de pages.
- **Préréglages de filigrane** : Textes prédéfinis ("COPIE", "NE PAS DIFFUSER", "À L'USAGE EXCLUSIF DE [nom]")
- **Traitement par lot (batch)** : Filigraner plusieurs images en une seule opération
- **Historique** : Mémorisation des textes et paramètres récemment utilisés

## Stack Technique

| Composant | Technologie |
|-----------|-------------|
| Langage | Python 3.x |
| UI Framework | Flet |
| Traitement d'image | Pillow (PIL) |
| Polices | Système (Arial/Helvetica) |

## Architecture de l'Interface

```
┌─────────────────────────────────────────────────────────┐
│                    Passport Filigrane                   │
├───────────────────────┬─────────────────────────────────┤
│                       │                                 │
│  [Sélectionner image] │                                 │
│                       │                                 │
│  Texte du filigrane:  │      Zone de prévisualisation   │
│  [________________]   │                                 │
│                       │         (Image avec             │
│  Opacité: ────●────   │          filigrane)             │
│                       │                                 │
│  Taille: ────●────    │                                 │
│                       │                                 │
│  Espacement: ──●───   │                                 │
│                       │                                 │
│  [Sauvegarder]        │                                 │
│                       │                                 │
└───────────────────────┴─────────────────────────────────┘
```

## Algorithme de Filigrane

1. Charger l'image source
2. Créer un calque transparent (RGBA) de même dimension
3. Calculer une grille de coordonnées couvrant l'image
4. Pour chaque point de la grille :
   - Dessiner le texte avec rotation diagonale (-45°)
   - Appliquer la taille et l'espacement configurés
5. Fusionner le calque sur l'image avec l'opacité choisie (Alpha composite)
6. Retourner l'image composite

## Contraintes

- **Fichier unique** : Code contenu dans `main.py` ou structure minimale
- **Performance** : Redimensionnement pour l'affichage (thumbnail) sans altérer l'image originale
- **Style** : Interface Clean & Dark Mode
- **Pas de dépendance Xcode** : Application pure Python

## Métriques de Succès

- Temps de traitement < 2 secondes pour une image standard
- Interface responsive et fluide
- Qualité d'image préservée après filigranage

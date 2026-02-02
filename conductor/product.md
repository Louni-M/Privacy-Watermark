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

### v1.1 (PDF Native Support & Quality) - [x]
- **Support PDF Natif** : Remplacement du filigranage raster par une approche vectorielle native (via PyMuPDF).
- **Préservation de Qualité** : Les documents PDF conservent leur netteté originale, le texte reste sélectionnable et les vecteurs ne sont pas pixelisés.
- **Prévisualisation Haute Fidélité** : Rendu de prévisualisation utilisant le moteur vectoriel pour une représentation exacte du résultat final.
- **Gestion des Cas Limites** : Détection et gestion propre des PDF protégés par mot de passe.
- **Options de Couleur** : Choix de la couleur du texte (Blanc, Noir, Gris).
- **Export Flexible** : Sauvegarde au format PDF (vectoriel) ou en séquence d'images JPG.
- **Application Standalone** : Packaging en tant qu'application macOS native (`.app`) avec icône personnalisée pour un lancement sans terminal.
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
- **Pour les Images (Raster) :**
  1. Charger l'image source
  2. Créer un calque transparent (RGBA)
  3. Appliquer un motif de tiling avec Pillow (`rotate` + `paste`)
  4. Fusionner les calques
- **Pour les PDF (Vectoriel) :**
  1. Ouvrir le document via PyMuPDF
  2. Pour chaque page, calculer les positions de tiling
  3. Insérer le texte via `page.insert_text()` avec une matrice `morph` pour la rotation
  4. Appliquer l'opacité via `fill_opacity` sans rasteriser le contenu original

## Contraintes

- **Fichier unique** : Code contenu dans `main.py` ou structure minimale
- **Performance** : Redimensionnement pour l'affichage (thumbnail) sans altérer l'image originale
- **Style** : Interface Clean & Dark Mode
- **Pas de dépendance Xcode** : Application pure Python

## Métriques de Succès

- Temps de traitement < 2 secondes pour une image standard
- Interface responsive et fluide
- Qualité d'image préservée après filigranage

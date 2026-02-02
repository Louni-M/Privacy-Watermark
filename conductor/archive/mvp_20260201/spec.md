# Specification: MVP Passport Filigrane

## Overview

Ce track implémente le MVP (Minimum Viable Product) de Passport Filigrane, une application desktop macOS permettant d'ajouter des filigranes de protection sur des documents d'identité.

## Objectifs

1. Créer une interface utilisateur fonctionnelle avec Flet
2. Implémenter l'algorithme de filigrane diagonal en tiling
3. Permettre la prévisualisation en temps réel
4. Permettre la sauvegarde de l'image filigranée

## Spécifications Fonctionnelles

### SF-01: Sélection d'Image

**Description:** L'utilisateur peut sélectionner une image depuis son système de fichiers.

**Critères d'acceptation:**
- Un bouton "Sélectionner une image" ouvre un FilePicker
- Formats acceptés : JPG, JPEG, PNG
- L'image sélectionnée s'affiche dans la zone de prévisualisation
- Un message d'erreur s'affiche si le format n'est pas supporté

### SF-02: Contrôle du Texte de Filigrane

**Description:** L'utilisateur peut saisir le texte qui sera répété en filigrane.

**Critères d'acceptation:**
- Champ de texte avec placeholder "Texte du filigrane"
- Valeur par défaut : "COPIE"
- La prévisualisation se met à jour lors de la saisie (avec debounce 300ms)

### SF-03: Contrôle de l'Opacité

**Description:** L'utilisateur peut ajuster l'opacité du filigrane.

**Critères d'acceptation:**
- Slider horizontal avec valeurs de 0 à 100%
- Valeur par défaut : 30%
- Affichage de la valeur actuelle
- Mise à jour en temps réel de la prévisualisation

### SF-04: Contrôle de la Taille de Police

**Description:** L'utilisateur peut ajuster la taille du texte du filigrane.

**Critères d'acceptation:**
- Slider horizontal avec valeurs de 12 à 72 pixels
- Valeur par défaut : 36px
- Affichage de la valeur actuelle
- Mise à jour en temps réel de la prévisualisation

### SF-05: Contrôle de l'Espacement

**Description:** L'utilisateur peut ajuster l'espacement entre les répétitions du texte.

**Critères d'acceptation:**
- Slider horizontal avec valeurs de 50 à 300 pixels
- Valeur par défaut : 150px
- Affichage de la valeur actuelle
- Mise à jour en temps réel de la prévisualisation

### SF-06: Algorithme de Filigrane Diagonal

**Description:** Le texte est répété en diagonale sur toute l'image.

**Critères d'acceptation:**
- Rotation du texte à -45 degrés
- Tiling couvrant l'intégralité de l'image
- Calcul de grille étendue pour compenser la rotation
- Application de l'opacité via alpha composite

### SF-07: Prévisualisation

**Description:** L'image filigranée est affichée en temps réel.

**Critères d'acceptation:**
- Zone de prévisualisation dans la colonne droite
- Thumbnail redimensionné (max 800px) pour la fluidité
- L'image originale n'est pas altérée
- Mise à jour lors de tout changement de paramètre

### SF-08: Sauvegarde

**Description:** L'utilisateur peut enregistrer l'image filigranée.

**Critères d'acceptation:**
- Bouton "Enregistrer" actif uniquement si une image est chargée
- FilePicker pour choisir l'emplacement de sauvegarde
- Format de sortie identique au format d'entrée
- Message de confirmation après sauvegarde

## Spécifications Techniques

### ST-01: Structure du Projet

```
Passport-Filigrane/
├── main.py              # Point d'entrée unique
├── requirements.txt     # Dépendances
└── conductor/           # Configuration Conductor
```

### ST-02: Architecture du Code

Le fichier `main.py` contiendra :
- Fonction `main()` : Point d'entrée Flet
- Fonction `process_image()` : Logique de filigrane
- Fonction `create_watermark_layer()` : Création du calque texte
- Fonction `generate_preview()` : Génération du thumbnail
- Classe ou fonctions pour la gestion de l'état UI

### ST-03: Gestion des Polices

**Ordre de recherche :**
1. `/Library/Fonts/Arial.ttf`
2. `/System/Library/Fonts/Helvetica.ttc`
3. Police par défaut PIL (fallback)

### ST-04: Performance

- Debounce de 300ms sur les changements de paramètres
- Prévisualisation limitée à 800px de large
- Traitement asynchrone si possible

## Interface Utilisateur

### Layout

```
┌─────────────────────────────────────────────────────────┐
│                    Passport Filigrane                   │
├───────────────────────┬─────────────────────────────────┤
│  Panneau Contrôles    │   Panneau Prévisualisation      │
│  (width: 300px)       │   (expand)                      │
│                       │                                 │
│  [Sélectionner image] │                                 │
│                       │                                 │
│  Texte du filigrane:  │      ┌─────────────────────┐    │
│  [COPIE           ]   │      │                     │    │
│                       │      │   Image avec        │    │
│  Opacité: 30%         │      │   filigrane         │    │
│  ──────●──────────    │      │                     │    │
│                       │      │                     │    │
│  Taille: 36px         │      └─────────────────────┘    │
│  ────●────────────    │                                 │
│                       │                                 │
│  Espacement: 150px    │                                 │
│  ──────●──────────    │                                 │
│                       │                                 │
│  [Enregistrer]        │                                 │
│                       │                                 │
└───────────────────────┴─────────────────────────────────┘
```

### Thème

- Dark mode avec fond #1a1a1a
- Accents bleus #3b82f6
- Voir `product-guidelines.md` pour les détails

## Dépendances

```
flet>=0.21.0
pillow>=10.0.0
pytest>=7.0.0
pytest-cov>=4.0.0
```

## Critères de Succès

- [ ] L'application démarre sans erreur
- [ ] Une image peut être chargée et affichée
- [ ] Le filigrane est visible et couvre toute l'image
- [ ] Tous les sliders modifient le rendu en temps réel
- [ ] L'image peut être sauvegardée avec le filigrane
- [ ] Couverture de tests > 80%

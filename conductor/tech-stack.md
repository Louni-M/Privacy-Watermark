# Tech Stack - Passport Filigrane

## Vue d'Ensemble

| Catégorie | Technologie | Version |
|-----------|-------------|---------|
| Langage | Python | 3.10+ |
| UI Framework | Flet | Latest |
| Traitement d'image | Pillow (PIL) | Latest |
| Traitement PDF | PyMuPDF (fitz) | Latest |
| Packaging | Flet CLI / PyInstaller | 6.18.0 |
| Gestion des dépendances | pip | Standard |

---

## Détails des Technologies

### Python 3.10+

**Rôle** : Langage principal de l'application

**Justification** :
- Syntaxe claire et lisible
- Écosystème riche pour le traitement d'images
- Compatibilité native avec Flet et Pillow
- Pas de compilation nécessaire

**Conventions** :
- Type hints recommandés pour les fonctions publiques
- Docstrings pour les fonctions principales
- PEP 8 pour le style de code

---

### Flet

**Rôle** : Framework d'interface utilisateur

**Justification** :
- Interface moderne inspirée de Flutter
- Composants riches (sliders, file pickers, etc.)
- Hot reload pour le développement
- Application desktop native sans Xcode
- Dark mode intégré

**Installation** :
```bash
pip install flet
```

**Composants Utilisés** :
- `flet.Page` : Fenêtre principale
- `flet.Row` / `flet.Column` : Layout deux colonnes
- `flet.TextField` : Saisie du texte de filigrane
- `flet.Slider` : Contrôles opacité, taille, espacement
- `flet.FilePicker` : Sélection de fichier
- `flet.Image` : Affichage de la prévisualisation
- `flet.ElevatedButton` : Boutons d'action

---

### Pillow (PIL)

**Rôle** : Traitement et manipulation d'images

**Justification** :
- Standard de facto pour le traitement d'images en Python
- Support complet JPG/PNG
- Opérations de composition alpha
- Rotation et transformation de texte
- Performance acceptable pour des images standard

**Installation** :
```bash
pip install pillow
```

**Modules Utilisés** :
- `PIL.Image` : Chargement, sauvegarde, composition
- `PIL.ImageDraw` : Dessin du texte
- `PIL.ImageFont` : Gestion des polices
- `PIL.ImageEnhance` : Ajustements (si nécessaire)

---

### PyMuPDF (fitz)

**Rôle** : Lecture, rendu et écriture de fichiers PDF

**Justification** :
- Haute performance pour le rendu de pages PDF
- Permet la modification de PDF existants (incremental save)
- Supporte la conversion de pages en images (PixMap) pour la prévisualisation
- API intuitive et complète

**Installation** :
```bash
pip install pymupdf
```

**Modules Utilisés** :
- `fitz.open()` : Chargement du document
- `page.get_pixmap()` : Rendu d'une page en image (pour prévisualisation)
- `page.insert_text()` : Insertion de filigrane vectoriel natif
- `doc.save()` : Sauvegarde incrémentale ou complète du document

---

### Packaging & Distribution (macOS)

**Rôle** : Création d'un bundle autonome `.app`

**Outils** :
- **Flet CLI** (`flet pack`) : Simplifie le packaging en invoquant PyInstaller avec des préréglages Flet.
- **PyInstaller** : Moteur de bundling sous-jacent.
- **sips & iconutil** : Utilitaires macOS pour la conversion de l'icône PNG en `.icns`.

**Configuration** :
- Utilisation de `--icon assets/app_icon.icns` pour l'identité visuelle.
- Mode `--noconsole` pour masquer le terminal au lancement.
- Version stable recommandée : **Flet 0.21.2** (évite les régressions API de la version 0.80+).

---

## Polices de Caractères

**Stratégie** : Utilisation des polices système

**macOS** :
- Primaire : Arial (`/Library/Fonts/Arial.ttf`)
- Fallback : Helvetica (`/System/Library/Fonts/Helvetica.ttc`)

**Gestion des erreurs** :
- Si aucune police système trouvée, utiliser la police par défaut de PIL

---

## Structure du Projet

```
Passport-Filigrane/
├── main.py              # Point d'entrée et code principal
├── requirements.txt     # Dépendances Python
├── README.md            # Documentation utilisateur
└── conductor/           # Configuration Conductor
    ├── product.md
    ├── product-guidelines.md
    ├── tech-stack.md
    ├── workflow.md
    └── tracks/
```

---

## Installation

### Prérequis
- Python 3.10 ou supérieur
- pip (gestionnaire de paquets Python)

### Commandes

```bash
# Créer un environnement virtuel (recommandé)
python3 -m venv venv
source venv/bin/activate

# Installer les dépendances
pip install flet pillow

# Ou via requirements.txt
pip install -r requirements.txt
```

### requirements.txt

```
flet>=0.21.0
pillow>=10.0.0
pymupdf>=1.24.0
```

---

## Exécution

```bash
# Lancer l'application
python main.py

# Ou avec Flet en mode développement (hot reload)
flet run main.py
```

---

## Contraintes Techniques

### Performance
- Images jusqu'à 4000x4000 pixels supportées
- Temps de traitement cible : < 2 secondes
- Prévisualisation via thumbnail (max 800px) pour la fluidité

### Compatibilité
- macOS 10.15+ (Catalina et supérieur)
- Architecture Intel et Apple Silicon (M1/M2/M3)

### v1.0 (MVP) - [x]

#### Dépendances
- **Python** : 3.14.2
- **Flet** : 0.21.2
- **Pillow** : 10.3.0
- **Pytest** : 8.1.1 (avec `pytest-cov`)

#### Architecture & Patterns
- **Approche Orientée Objet** : Utilisation d'une classe `PassportFiligraneApp` pour encapsuler l'état et l'UI.
- **Filigranage Hybride** :
  - **Raster** (Pillow) pour les images individuelles.
  - **Vectoriel** (PyMuPDF) pour les PDF standards, préservant la sélection de texte.
  - **Sécurisé (Rasterized PDF)** : Conversion des pages PDF en images haute résolution (jusqu'à 600 DPI) avant application du filigrane pour une sécurité maximale.
- **Matrice de Rotation** : Utilisation de `fitz.Matrix` et rotation PIL synchronisées à **45°** pour une lecture naturelle montant du bas-gauche vers le haut-droite.
- **Performance** : Traitement vectoriel instantané, traitement sécurisé optimisé via `PixMap` Fitz et compression JPEG 95% pour un ratio poids/qualité optimal.

#### Tests
- **Unitaires** : `test_processing.py`, `test_vector_watermark.py`.
- **Cas Limites** : `test_pdf_edge_cases.py` (PDF chiffrés, volumineux, images-only).
- **Performance** : `test_performance.py` (benchmarking 10+ pages).
- **Couverture** : >52% global (incluant scripts de recherche), >90% sur le coeur métier PDF/Image.

---

- **Entrée** : JPG, JPEG, PNG, PDF
### v1.4 (Flexible Export Selection) - [x]

#### Architecture & Patterns
- **Context-Aware UI** : Mise à jour dynamique des options du `FilePicker` et du `Dropdown` basée sur le `MIME type` détecté.
- **Cross-Format conversion** : Extension du module `pdf_processing` pour supporter l'injection d'images Pillow directement dans des documents PyMuPDF.
- **Dimension Mapping** : Gestion de la conversion Pixels (Pillow) ↔ Points (PDF) pour garantir que l'export PDF "fit" parfaitement l'image source à 72 DPI.

#### Tests
- **Intégration** : `test_integration_export.py` simulant la matrice complète des exports possibles (Image→PNG/PDF, PDF→PNG).
- **Format-Specific** : `test_png_export.py`, `test_image_to_pdf.py`.
- **Couverture** : Maintien d'une couverture >90% sur la logique de conversion et de routage d'export.

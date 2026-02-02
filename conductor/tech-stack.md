# Tech Stack - Passport Filigrane

## Vue d'Ensemble

| Catégorie | Technologie | Version |
|-----------|-------------|---------|
| Langage | Python | 3.10+ |
| UI Framework | Flet | Latest |
| Traitement d'image | Pillow (PIL) | Latest |
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
- **Fichier unique** : `main.py` concentre la logique UI et métier (contrainte respectée).
- **Gestion de l'état** : Variables locales `nonlocal` dans `main()`.
- **Réactivité** : Debounce de 0.2s via `threading.Timer`.
- **Traitement d'image** : Tiling diagonal via `Image.rotate` et `Image.alpha_composite`.

#### Tests
- **Unitaires** : `test_processing.py` (logique Pillow).
- **Intégration UI** : `test_main.py` (Mocks Flet Page/FilePicker).
- **Couverture** : ~54% total, >90% sur la partie `processing`.

---

- **Entrée** : JPG, JPEG, PNG
- **Sortie** : JPEG (qualité 90)

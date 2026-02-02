# Passport Filigrane

Application macOS pour filigraner des documents d'identité et protéger votre vie privée.

## Fonctionnalités

- **Filigrane personnalisable** : texte, opacité, taille, espacement, couleur
- **Orientation configurable** : ascendant (↗) ou descendant (↘)
- **Support PDF & Images** : JPG, PNG, PDF multi-pages
- **Mode Sécurisé** : rasterisation haute définition (300/450/600 DPI) rendant le filigrane impossible à supprimer
- **Prévisualisation temps réel** : aperçu instantané des modifications

## Démonstration du Mode Sécurisé (Raster)

Le **Mode Sécurisé** transforme chaque page du PDF en une image haute résolution avant d'appliquer le filigrane. Cela rend le filigrane indissociable du contenu et empêche toute tentative de suppression ou d'extraction de texte.

| Mode Vectoriel (Standard) | Mode Sécurisé (Raster) |
|:-------------------------:|:----------------------:|
| ![Vector Mode](assets/demo_vector.png) | ![Secure Mode](assets/demo_secure.png) |
| **Texte sélectionnable** : Le filigrane est une couche de texte par-dessus le PDF. | **Image aplatie** : Le filigrane est fusionné avec les pixels du document. |
| **Suppression** : Possible via des outils d'édition PDF. | **Suppression** : Impossible sans altérer l'image elle-même. |
| **Recherche de texte** : Le filigrane est détectable techniquement. | **Recherche de texte** : Le filigrane est invisible pour les algorithmes (0 texte trouvé). |
| **Poids** : Très léger. | **Poids** : Plus important (300+ DPI). |

## Installation

### Depuis les releases

1. Télécharger `Passport Filigrane.app` depuis les [Releases](../../releases)
2. Glisser dans le dossier Applications
3. Lancer l'application

### Depuis les sources

```bash
# Cloner le repo
git clone https://github.com/Louni-M/Passport-Filigrane.git
cd Passport-Filigrane

# Installer les dépendances
pip install -r requirements.txt

# Lancer l'application
python main.py
```

### Build de l'application

```bash
pip install pyinstaller
pyinstaller "Passport Filigrane.spec" --clean
```

L'application sera générée dans `dist/`.

## Utilisation

1. **Sélectionner un fichier** (image ou PDF)
2. **Configurer le filigrane** :
   - Texte (ex: "COPIE", "SPECIMEN")
   - Opacité (0-100%)
   - Taille de police (12-72px)
   - Espacement (50-300px)
   - Couleur (Blanc, Noir, Gris)
   - Orientation (Ascendant ↗ / Descendant ↘)
3. **Activer le Mode Sécurisé** (optionnel) pour les documents sensibles
4. **Enregistrer** le fichier filigrané

## Mode Sécurisé vs Mode Vectoriel

| Critère | Vectoriel | Sécurisé (Raster) |
|---------|-----------|-------------------|
| Qualité | Parfaite | Très bonne |
| Texte sélectionnable | Oui | Non |
| Filigrane supprimable | Oui | **Non** |
| Taille fichier | ~100% | ~300-1000% |
| Cas d'usage | Usage interne | Documents publics |

## Stack technique

- **Python 3.x**
- **Flet** - Interface utilisateur
- **Pillow** - Traitement d'images
- **PyMuPDF** - Manipulation PDF

## Structure du projet

```
Passport-Filigrane/
├── main.py              # Application principale (UI)
├── pdf_processing.py    # Logique de filigranage
├── assets/              # Icône de l'application
├── conductor/           # Documentation interne
└── dist/                # Build macOS
```

## Licence

Projet personnel - Usage libre pour des fins non commerciales.

## Auteur

Projet étudiant - 2026

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

### Depuis les releases (Recommandé)

1. Télécharger `Passport-Filigrane.zip` (ou le dossier compressé) depuis les [Releases](https://github.com/Louni-M/Passport-Filigrane/releases)
2. Extraire l'archive
3. Glisser `Passport Filigrane.app` dans votre dossier **Applications**
4. Lancer l'application (Note : Au premier lancement, un clic droit > Ouvrir peut être nécessaire car l'app n'est pas encore signée par un certificat développeur Apple).

### Depuis les sources

```bash
# Cloner le repo
git clone https://github.com/Louni-M/Passport-Filigrane.git
cd Passport-Filigrane

# Créer un environnement virtuel
python3 -m venv venv
source venv/bin/activate

# Installer les dépendances
pip install -r requirements.txt

# Lancer l'application
python main.py
```

### Build de l'application (Développeurs)

```bash
# Le build utilise le mode onedir pour une performance optimale
pyinstaller "Passport Filigrane.spec" --clean
```

L'application est générée dans `dist/Passport Filigrane.app`.

## Structure du projet

```
Passport-Filigrane/
├── main.py              # Application principale (UI Flet)
├── pdf_processing.py    # Moteur de filigranage (PyMuPDF/Pillow)
├── assets/              # Ressources (Icônes)
├── tests/               # Tests unitaires et d'intégration
├── SECURITY.md          # Politique de sécurité et hygiène Git
└── Passport Filigrane.spec # Configuration du build PyInstaller
```

## Licence

Projet personnel - Usage libre pour des fins personnelles et non commerciales.

## Auteur

Louni Merk - 2026

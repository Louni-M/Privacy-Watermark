# Product Guidelines - Passport Filigrane

## Ton et Style de Communication

### Principes Généraux
- **Ton professionnel et sobre** : Messages concis et informatifs
- **Vocabulaire technique assumé** : L'utilisateur comprend ce qu'est un filigrane, une opacité, etc.
- **Pas d'emojis** dans l'interface
- **Pas de ponctuation excessive** (éviter les "!", "...", etc.)

### Exemples de Messages

| Contexte | Message |
|----------|---------|
| Image chargée | "Image chargée (1920x1080)" |
| Traitement en cours | "Application du filigrane..." |
| Sauvegarde réussie | "Image enregistrée." |
| Erreur de format | "Format non supporté. Utilisez JPG ou PNG." |
| Aucune image | "Sélectionnez une image pour commencer." |

### À Éviter
- Messages trop longs ou explicatifs
- Formulations familières ("Super !", "Oups...")
- Jargon inutile ou anglicismes évitables

---

## Identité Visuelle

### Palette de Couleurs (Dark Mode)

| Élément | Couleur | Code Hex |
|---------|---------|----------|
| Fond principal | Noir profond | `#1a1a1a` |
| Fond secondaire (panneaux) | Gris foncé | `#252525` |
| Fond des contrôles | Gris moyen | `#2d2d2d` |
| Texte principal | Blanc | `#ffffff` |
| Texte secondaire | Gris clair | `#a0a0a0` |
| Accent primaire | Bleu | `#3b82f6` |
| Accent hover | Bleu clair | `#60a5fa` |
| Erreur | Rouge | `#ef4444` |
| Succès | Vert | `#22c55e` |

### Typographie
- **Police principale** : Police système (San Francisco sur macOS)
- **Taille de base** : 14px
- **Titres** : 18px, semi-bold
- **Labels** : 12px, regular, couleur secondaire

### Espacements
- **Padding interne des panneaux** : 16px
- **Espacement entre contrôles** : 12px
- **Espacement entre sections** : 24px
- **Border radius** : 8px (coins arrondis modernes)

### Composants UI

#### Boutons
- **Primaire** : Fond bleu (#3b82f6), texte blanc, hover bleu clair
- **Secondaire** : Fond transparent, bordure grise, texte blanc

#### Sliders
- **Track** : Gris foncé (#2d2d2d)
- **Fill** : Bleu (#3b82f6)
- **Thumb** : Blanc avec ombre légère

#### Champs de texte
- **Fond** : Gris moyen (#2d2d2d)
- **Bordure** : Transparente, bleue au focus
- **Placeholder** : Gris clair (#a0a0a0)

---

## Langue

### Langue de l'Interface
- **Français uniquement**
- Utiliser les termes français standards (pas de franglais)

### Terminologie

| Terme à utiliser | À éviter |
|------------------|----------|
| Filigrane | Watermark |
| Opacité | Transparence |
| Espacement | Spacing |
| Enregistrer | Sauvegarder/Save |
| Sélectionner | Choisir/Pick |

---

## Accessibilité

- Contraste minimum de 4.5:1 entre texte et fond
- Tous les contrôles accessibles au clavier
- Labels explicites sur tous les champs
- Zone de clic minimum de 44x44px pour les boutons

---

## Comportements UI

### Feedback Utilisateur
- Indicateur de chargement pendant le traitement
- Mise à jour de la prévisualisation en temps réel (avec debounce de 300ms)
- Confirmation visuelle après sauvegarde (message temporaire 3s)

### États des Contrôles
- **Désactivé** : Opacité réduite (50%), curseur non-cliquable
- **Focus** : Bordure bleue visible
- **Hover** : Légère augmentation de luminosité

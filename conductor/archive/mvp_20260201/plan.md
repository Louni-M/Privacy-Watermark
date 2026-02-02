# Plan: MVP Passport Filigrane

## Track Overview

**Track ID:** mvp_20260201
**Objectif:** Construire le MVP de Passport Filigrane avec l'interface deux colonnes, les contrôles de filigrane, l'algorithme de tiling diagonal, et la fonctionnalité de sauvegarde.

---

## Phase 1: Setup et Structure de Base [checkpoint: 4a90ba3]

### Objectif
Initialiser le projet avec les dépendances et créer la structure de base de l'application Flet.

### Tâches

- [x] Task 1.1: Créer le fichier requirements.txt avec les dépendances (flet, pillow, pytest, pytest-cov) [670028d]
- [x] Task 1.2: Écrire les tests pour la structure de base de l'application Flet (fenêtre, titre, thème dark) [82d091b]
- [x] Task 1.3: Implémenter la structure de base de l'application Flet avec fenêtre et thème dark mode [82d091b]
- [x] Task 1.4: Conductor - User Manual Verification 'Phase 1: Setup et Structure de Base' (Protocol in workflow.md) [4a90ba3]

---

## Phase 2: Layout Deux Colonnes [checkpoint: 04bb6a4]

### Objectif
Créer le layout principal avec le panneau de contrôles à gauche et la zone de prévisualisation à droite.

### Tâches

- [x] Task 2.1: Écrire les tests pour le layout deux colonnes (panneau gauche 300px, panneau droit extensible) [b3ccb11]
- [x] Task 2.2: Implémenter le layout deux colonnes avec Row et Column Flet [b3ccb11]
- [x] Task 2.3: Appliquer les styles du product-guidelines (couleurs, espacements, border-radius) [f1504a1]
- [x] Task 2.4: Conductor - User Manual Verification 'Phase 2: Layout Deux Colonnes' (Protocol in workflow.md) [04bb6a4]

---

## Phase 3: Sélection d'Image et Prévisualisation [checkpoint: f6b79b8]

### Objectif
Implémenter le FilePicker pour sélectionner une image et l'afficher dans la zone de prévisualisation.

### Tâches

- [x] Task 3.1: Écrire les tests pour le FilePicker (formats acceptés, gestion des erreurs) [86ece96]
- [x] Task 3.2: Implémenter le bouton "Sélectionner une image" avec FilePicker [86ece96]
- [x] Task 3.3: Écrire les tests pour la fonction de génération de thumbnail [cc48f58]
- [x] Task 3.4: Implémenter la fonction generate_preview() pour créer un thumbnail (max 800px) [cc48f58]
- [x] Task 3.5: Afficher l'image dans la zone de prévisualisation [cc48f58]
- [x] Task 3.6: Conductor - User Manual Verification 'Phase 3: Sélection d'Image et Prévisualisation' (Protocol in workflow.md) [f6b79b8]

---

## Phase 4: Contrôles du Filigrane [checkpoint: c4bfe25]

### Objectif
Ajouter les contrôles utilisateur : champ texte et sliders pour opacité, taille et espacement.

### Tâches

- [x] Task 4.1: Écrire les tests pour le champ de texte du filigrane (valeur par défaut, événements) [30c1d3e]
- [x] Task 4.2: Implémenter le TextField pour le texte du filigrane avec valeur par défaut "COPIE" [30c1d3e]
- [x] Task 4.3: Écrire les tests pour le slider d'opacité (range 0-100, valeur par défaut 30) [30c1d3e]
- [x] Task 4.4: Implémenter le slider d'opacité avec label et affichage de la valeur [30c1d3e]
- [x] Task 4.5: Écrire les tests pour le slider de taille de police (range 12-72, valeur par défaut 36) [c4bfe25]
- [x] Task 4.6: Implémenter le slider de taille de police avec label et affichage de la valeur [c4bfe25]
- [x] Task 4.7: Écrire les tests pour le slider d'espacement (range 50-300, valeur par défaut 150) [c4bfe25]
- [x] Task 4.8: Implémenter le slider d'espacement avec label et affichage de la valeur [c4bfe25]
- [x] Task 4.9: Conductor - User Manual Verification 'Phase 4: Contrôles du Filigrane' (Protocol in workflow.md) [c4bfe25]

---

## Phase 5: Algorithme de Filigrane [checkpoint: 050a103]

### Objectif
Implémenter le cœur de l'algorithme de marquage avec Pillow (répétition du texte, rotation, opacité).

### Tâches

- [x] Task 5.1: Écrire les tests pour l'algorithme de filigrane (opacité, répétition) [050a103]
- [x] Task 5.2: Implémenter la fonction get_font() avec fallback (Arial → Helvetica → default) [050a103]
- [x] Task 5.3: Écrire les tests pour la création du calque de filigrane (dimensions, transparence) [050a103]
- [x] Task 5.4: Implémenter create_watermark_layer() - calque RGBA transparent [050a103]
- [x] Task 5.5: Implémenter stamp_watermark() pour un texte individuel pivoté [050a103]
- [x] Task 5.6: Implémenter le tiling de filigrane sur toute l'image [050a103]
- [x] Task 5.7: Écrire les tests pour la fonction process_image() (composition alpha, opacité) [050a103]
- [x] Task 5.8: Implémenter process_image() avec alpha composite [050a103]
- [x] Task 5.9: Conductor - User Manual Verification 'Phase 5: Algorithme de Filigrane' (Protocol in workflow.md) [050a103]

---

## Phase 6: Prévisualisation Temps Réel [checkpoint: 7783b74]

### Objectif
Connecter les contrôles UI à l'algorithme pour une mise à jour instantanée.

### Tâches

- [x] Task 6.1: Écrire les tests pour la mise à jour réactive (debounce, appels API) [7783b74]
- [x] Task 6.2: Implémenter le mécanisme de mise à jour instantanée [7783b74]
- [x] Task 6.3: Connecter le TextField au traitement d'image [7783b74]
- [x] Task 6.4: Connecter les sliders au traitement d'image [7783b74]
- [x] Task 6.5: Optimiser les performances (debounce 200ms) [7783b74]
- [x] Task 6.6: Conductor - User Manual Verification 'Phase 6: Prévisualisation Temps Réel' (Protocol in workflow.md) [7783b74]

---

## Phase 7: Sauvegarde [checkpoint: 801cee3]

### Objectif
Permettre à l'utilisateur d'enregistrer l'image filigranée sur son disque.

### Tâches

- [x] Task 7.1: Écrire les tests pour la fonction de sauvegarde (format préservé, qualité) [801cee3]
- [x] Task 7.2: Implémenter le bouton "Enregistrer" (désactivé si aucune image) [801cee3]
- [x] Task 7.3: Implémenter le FilePicker de sauvegarde avec suggestion de nom [801cee3]
- [x] Task 7.4: Implémenter la fonction save_image() avec le format d'origine [801cee3]
- [x] Task 7.5: Afficher le message de confirmation après sauvegarde [801cee3]
- [x] Task 7.6: Conductor - User Manual Verification 'Phase 7: Sauvegarde' (Protocol in workflow.md) [801cee3]

---

## Phase 8: Polish et Finalisation [checkpoint: a7a1671]

### Objectif
Finaliser l'interface, gérer les cas d'erreur et s'assurer de la qualité globale.

### Tâches

- [x] Task 8.1: Écrire les tests pour la gestion des erreurs [a7a1671]
- [x] Task 8.2: Implémenter la gestion des erreurs robuste [a7a1671]
- [x] Task 8.3: Ajouter les états désactivés aux contrôles [a7a1671]
- [x] Task 8.4: Vérifier et ajuster les styles [a7a1671]
- [x] Task 8.5: Ajouter les docstrings et commentaires [a7a1671]
- [x] Task 8.6: Vérifier la couverture de tests (objectif >80%) [a7a1671]
- [x] Task 8.7: Conductor - User Manual Verification 'Phase 8: Polish et Finalisation' (Protocol in workflow.md) [a7a1671]

---

## Notes d'Implémentation

- [x] Phase 7: Correction de l'erreur `ft.colors.SUCCESS` par `ft.colors.GREEN` suite au feedback utilisateur.

---

## Checkpoints

| Phase | Description | Checkpoint SHA |
|-------|-------------|----------------|
| 1 | Setup et Structure de Base | 4a90ba3 |
| 2 | Layout Deux Colonnes | 04bb6a4 |
| 3 | Sélection d'Image et Prévisualisation | f6b79b8 |
| 4 | Contrôles du Filigrane | c4bfe25 |
| 5 | Algorithme de Filigrane | 050a103 |
| 6 | Prévisualisation Temps Réel | 7783b74 |
| 7 | Sauvegarde | 801cee3 |
| 8 | Polish et Finalisation | a7a1671 |

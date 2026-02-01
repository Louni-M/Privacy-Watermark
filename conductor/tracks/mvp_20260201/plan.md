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

## Phase 2: Layout Deux Colonnes

### Objectif
Créer le layout principal avec le panneau de contrôles à gauche et la zone de prévisualisation à droite.

### Tâches

- [x] Task 2.1: Écrire les tests pour le layout deux colonnes (panneau gauche 300px, panneau droit extensible) [b3ccb11]
- [x] Task 2.2: Implémenter le layout deux colonnes avec Row et Column Flet [b3ccb11]
- [x] Task 2.3: Appliquer les styles du product-guidelines (couleurs, espacements, border-radius) [f1504a1]
- [~] Task 2.4: Conductor - User Manual Verification 'Phase 2: Layout Deux Colonnes' (Protocol in workflow.md)

---

## Phase 3: Sélection d'Image et Prévisualisation

### Objectif
Implémenter le FilePicker pour sélectionner une image et l'afficher dans la zone de prévisualisation.

### Tâches

- [ ] Task 3.1: Écrire les tests pour le FilePicker (formats acceptés, gestion des erreurs)
- [ ] Task 3.2: Implémenter le bouton "Sélectionner une image" avec FilePicker
- [ ] Task 3.3: Écrire les tests pour la fonction de génération de thumbnail
- [ ] Task 3.4: Implémenter la fonction generate_preview() pour créer un thumbnail (max 800px)
- [ ] Task 3.5: Afficher l'image dans la zone de prévisualisation
- [ ] Task 3.6: Conductor - User Manual Verification 'Phase 3: Sélection d'Image et Prévisualisation' (Protocol in workflow.md)

---

## Phase 4: Contrôles du Filigrane

### Objectif
Ajouter les contrôles utilisateur : champ texte et sliders pour opacité, taille et espacement.

### Tâches

- [ ] Task 4.1: Écrire les tests pour le champ de texte du filigrane (valeur par défaut, événements)
- [ ] Task 4.2: Implémenter le TextField pour le texte du filigrane avec valeur par défaut "COPIE"
- [ ] Task 4.3: Écrire les tests pour le slider d'opacité (range 0-100, valeur par défaut 30)
- [ ] Task 4.4: Implémenter le slider d'opacité avec label et affichage de la valeur
- [ ] Task 4.5: Écrire les tests pour le slider de taille de police (range 12-72, valeur par défaut 36)
- [ ] Task 4.6: Implémenter le slider de taille de police avec label et affichage de la valeur
- [ ] Task 4.7: Écrire les tests pour le slider d'espacement (range 50-300, valeur par défaut 150)
- [ ] Task 4.8: Implémenter le slider d'espacement avec label et affichage de la valeur
- [ ] Task 4.9: Conductor - User Manual Verification 'Phase 4: Contrôles du Filigrane' (Protocol in workflow.md)

---

## Phase 5: Algorithme de Filigrane

### Objectif
Implémenter le cœur de l'application : l'algorithme de filigrane diagonal en tiling.

### Tâches

- [ ] Task 5.1: Écrire les tests pour la fonction de chargement de police système
- [ ] Task 5.2: Implémenter la fonction get_font() avec fallback (Arial → Helvetica → default)
- [ ] Task 5.3: Écrire les tests pour la création du calque de filigrane (dimensions, transparence)
- [ ] Task 5.4: Implémenter create_watermark_layer() - calque RGBA transparent
- [ ] Task 5.5: Écrire les tests pour l'algorithme de tiling diagonal (couverture complète, rotation -45°)
- [ ] Task 5.6: Implémenter l'algorithme de tiling avec rotation -45° et grille étendue
- [ ] Task 5.7: Écrire les tests pour la fonction process_image() (composition alpha, opacité)
- [ ] Task 5.8: Implémenter process_image() avec alpha composite
- [ ] Task 5.9: Conductor - User Manual Verification 'Phase 5: Algorithme de Filigrane' (Protocol in workflow.md)

---

## Phase 6: Prévisualisation Temps Réel

### Objectif
Connecter les contrôles à l'algorithme de filigrane pour une prévisualisation en temps réel.

### Tâches

- [ ] Task 6.1: Écrire les tests pour le debounce (300ms) sur les changements de paramètres
- [ ] Task 6.2: Implémenter le mécanisme de debounce pour les mises à jour
- [ ] Task 6.3: Connecter le TextField au traitement d'image avec mise à jour de la prévisualisation
- [ ] Task 6.4: Connecter les sliders au traitement d'image avec mise à jour de la prévisualisation
- [ ] Task 6.5: Optimiser les performances (traitement asynchrone si nécessaire)
- [ ] Task 6.6: Conductor - User Manual Verification 'Phase 6: Prévisualisation Temps Réel' (Protocol in workflow.md)

---

## Phase 7: Sauvegarde

### Objectif
Permettre à l'utilisateur d'enregistrer l'image filigranée sur le disque.

### Tâches

- [ ] Task 7.1: Écrire les tests pour la fonction de sauvegarde (format préservé, qualité)
- [ ] Task 7.2: Implémenter le bouton "Enregistrer" (désactivé si aucune image)
- [ ] Task 7.3: Implémenter le FilePicker de sauvegarde avec suggestion de nom
- [ ] Task 7.4: Implémenter la fonction save_image() avec le format d'origine
- [ ] Task 7.5: Afficher le message de confirmation après sauvegarde
- [ ] Task 7.6: Conductor - User Manual Verification 'Phase 7: Sauvegarde' (Protocol in workflow.md)

---

## Phase 8: Polish et Finalisation

### Objectif
Finaliser l'interface, gérer les cas d'erreur et s'assurer de la qualité globale.

### Tâches

- [ ] Task 8.1: Écrire les tests pour la gestion des erreurs (fichier corrompu, permissions)
- [ ] Task 8.2: Implémenter la gestion des erreurs avec messages utilisateur appropriés
- [ ] Task 8.3: Ajouter les états désactivés aux contrôles quand aucune image n'est chargée
- [ ] Task 8.4: Vérifier et ajuster les styles selon product-guidelines.md
- [ ] Task 8.5: Ajouter les docstrings et commentaires au code
- [ ] Task 8.6: Vérifier la couverture de tests (objectif >80%)
- [ ] Task 8.7: Conductor - User Manual Verification 'Phase 8: Polish et Finalisation' (Protocol in workflow.md)

---

## Notes d'Implémentation

_Cette section sera mise à jour au fur et à mesure de l'implémentation._

---

## Checkpoints

| Phase | Description | Checkpoint SHA |
|-------|-------------|----------------|
| 1 | Setup et Structure de Base | 4a90ba3 |
| 2 | Layout Deux Colonnes | - |
| 3 | Sélection d'Image et Prévisualisation | - |
| 4 | Contrôles du Filigrane | - |
| 5 | Algorithme de Filigrane | - |
| 6 | Prévisualisation Temps Réel | - |
| 7 | Sauvegarde | - |
| 8 | Polish et Finalisation | - |

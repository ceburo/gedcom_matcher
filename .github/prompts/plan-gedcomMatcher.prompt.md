## Plan: CLI GEDCOM Matcher MVP

Construire un CLI Dart configurable qui compare 2 fichiers GEDCOM, calcule des correspondances de personnes avec score de confiance 0-100, affiche un rendu terminal moderne avec barre de progression, et supporte affichage multi-formats + export via options cumulables. L’approche recommandée est un coeur métier simple et testable (parsing, normalisation, scoring) séparé de la couche CLI.

**Steps**
1. Phase 1 - Stabilisation du socle package
2. Remplacer le template Awesome par un domaine minimal: PersonRecord, MatchCandidate, MatchResult, MatchWeights, MatchOptions. Définir des types immuables et des responsabilités courtes. depend de 1.
3. Mettre à jour l’API publique pour n’exposer que les types/fonctions utiles du package. depend de 2.
4. Ajouter des tests unitaires de base sur les nouveaux types et invariants (score borné, tri des résultats, seuil minimal). parallel avec 3.
5. Phase 2 - Parsing GEDCOM et normalisation
6. Implémenter un parser GEDCOM MVP orienté individus (balises INDI + champs nom, sexe, naissance, décès, conjoint si présent) avec gestion robuste des données manquantes. depend de 2.
7. Implémenter la normalisation (casse, accents, ponctuation, espaces, variantes courantes) pour comparaison des noms/prénoms et du conjoint. depend de 6.
8. Ajouter des fixtures GEDCOM en tests et couvrir cas nominaux + edge cases (valeurs absentes, lignes inattendues, doublons d’identifiant, formats de dates hétérogènes). depend de 6.
9. Phase 3 - Moteur de matching et score de confiance
10. Implémenter un moteur de similarité pondéré en score 0-100 avec critères retenus: nom+prénom, naissance (date+lieu), décès, sexe, nom+prénom du conjoint (pondération faible). depend de 7.
11. Définir des poids configurables et un seuil par défaut à 70; filtrer/sortir les correspondances triées par score décroissant. depend de 10.
12. Ajouter tests unitaires détaillés du scoring: contributions par critère, collisions, faux positifs, faux négatifs probables, stabilité de tri. depend de 10.
13. Phase 4 - CLI, UX terminal et formats de sortie
14. Créer l’entrée CLI avec aide en ligne -h/--help et options cumulables: --format (table/json/csv/markdown), --output, --min-confidence, et options de pondération. depend de 11.
15. Implémenter un affichage terminal moderne et lisible: en-têtes clairs, tableau aligné, couleurs sobres, mise en évidence du score et des informations de paire. depend de 14.
16. Ajouter une barre de progression durant la comparaison avec comportement propre en mode interactif et fallback non interactif. depend de 14.
17. Implémenter la sérialisation multi-formats (table, json, csv, markdown) et l’export vers fichier quand --output est fourni, format déduit de l’extension. depend de 14.
18. Ajouter des tests CLI (golden text/parse args) pour vérifier options cumulables, aide, erreurs d’usage, export, et cohérence des formats. depend de 17.
19. Phase 5 - Documentation et qualité
20. Mettre à jour README avec exemples d’exécution (incluant combinaisons d’options), stratégie de scoring, formats supportés, limites connues, et exemples d’export. depend de 18.
21. Mettre à jour CHANGELOG avec les fonctionnalités visibles utilisateur. depend de 20.
22. Exécuter format, analyse statique, tests; corriger les écarts. depend de 21.

**Relevant files**
- /Users/francetravail/PROJETS/PERSO/gedcom_matcher/pubspec.yaml — ajouter les dépendances CLI/UX minimales et éventuelles dépendances de parsing nécessaires.
- /Users/francetravail/PROJETS/PERSO/gedcom_matcher/lib/gedcom_matcher.dart — exposer l’API publique finale sans fuite d’implémentation interne.
- /Users/francetravail/PROJETS/PERSO/gedcom_matcher/lib/src/gedcom_matcher_base.dart — remplacer la classe placeholder par les briques de domaine ou supprimer au profit d’une structure plus claire.
- /Users/francetravail/PROJETS/PERSO/gedcom_matcher/test/gedcom_matcher_test.dart — remplacer les tests template par tests métier réels.
- /Users/francetravail/PROJETS/PERSO/gedcom_matcher/README.md — documenter usage CLI, options, formats et exemples.
- /Users/francetravail/PROJETS/PERSO/gedcom_matcher/CHANGELOG.md — tracer les changements fonctionnels.
- /Users/francetravail/PROJETS/PERSO/gedcom_matcher/example/gedcom_matcher_example.dart — adapter l’exemple à l’API métier.
- /Users/francetravail/PROJETS/PERSO/gedcom_matcher/analysis_options.yaml — optionnel, uniquement si un réglage lint devient nécessaire.

**Verification**
1. Vérifier que fvm dart pub get réussit.
2. Vérifier que fvm dart format lib test example ne produit plus de diff.
3. Vérifier que fvm dart analyze ne remonte aucune erreur.
4. Vérifier que fvm dart test couvre parsing, scoring et CLI.
5. Vérifier manuellement la CLI:
6. Aide: exécution avec -h et --help.
7. Cumul d’options: format + seuil + output simultanément.
8. Export: création du fichier attendu (json/csv/markdown selon extension).
9. Progression: barre visible pendant traitement et sortie propre en fin.
10. Lisibilité: affichage table moderne des correspondances avec score explicite.

**Decisions**
- Langage: Dart pour son écosystème riche, facilité de packaging CLI, et performance adaptée au parsing et matching.
- Le parser de fichier GEDCOM est: gedcom_parser (https://pub.dev/packages/gedcom_parser), pour sa simplicité et son focus sur les structures de base.
- Score de confiance: 0-100.
- Formats de sortie au lancement: table terminal (défaut), json, csv, markdown.
- Export: via --output, format déduit de l’extension.
- Seuil d’affichage par défaut: 70.
- Critères de score MVP: nom+prénom normalisés, naissance (date/lieu), décès, sexe, conjoint (nom+prénom) avec pondération faible.
- Paramètres cumulables: oui, y compris format + export + seuil + pondérations.
- Style de code demandé: éviter les doubles quotes sauf imports.

**Further Considerations**
1. Dépendances UX CLI: privilégier minimalisme (args + sorties formatées maison) pour garder les classes simples, puis enrichir visuel si nécessaire.
2. Performance sur gros GEDCOM: pour MVP, chargement mémoire acceptable; streaming/incrémental pourra être une phase 2 si besoin.
3. Compatibilité GEDCOM: MVP ciblé sur structure usuelle INDI/FAM; variantes avancées et encodages exotiques hors périmètre initial.

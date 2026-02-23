# Docker-SBOM-Analyzer 🔍

![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-1904DA?logo=aqua&logoColor=white)
![Security](https://img.shields.io/badge/Security-SBOM-green)
![License](https://img.shields.io/badge/license-MIT-green)

**Analyse SBOM et Scan de Vulnérabilités pour Images Docker Locales**

## 📋 Description

Docker-SBOM-Analyzer est un outil automatisé d'analyse de sécurité pour vos images Docker locales. Il génère un Software Bill of Materials (SBOM) complet et identifie toutes les vulnérabilités présentes dans vos conteneurs.

L'outil utilise Trivy, le scanner de vulnérabilités open-source d'Aqua Security, reconnu pour sa précision et sa base de données exhaustive.

## ✨ Fonctionnalités

- 🔍 Analyse SBOM complète (Software Bill of Materials)
- 🔐 Détection des vulnérabilités (CVE) avec scoring CVSS
- 📊 Rapport HTML interactif avec statistiques visuelles
- 🎯 Support multi-langages (Python, Node.js, Java, Go, etc.)
- ⚡ Analyse des images Docker locales uniquement
- 📁 Génération de rapports multiformats (JSON, TXT, HTML)

## 🛠️ Technologies utilisées

- Trivy (scanner de vulnérabilités)
- Docker
- Bash
- jq (traitement JSON)

## 📦 Installation

### Prérequis

Assurez-vous d'avoir installé les outils suivants sur votre machine Linux :

#### 1. Docker
```bash
# Installation sur Debian/Ubuntu
sudo apt update
sudo apt install docker.io -y

# Démarrer et activer Docker
sudo systemctl start docker
sudo systemctl enable docker

# Ajouter votre utilisateur au groupe docker (évite d'utiliser sudo)
sudo usermod -aG docker $USER
newgrp docker

# Vérifier l'installation
docker --version
```

#### 2. Trivy
```bash
# Méthode 1 : Installation via APT (Recommandé pour Debian/Ubuntu)
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Vérifier l'installation
trivy --version
```

**Alternative (installation manuelle) :**
```bash
# Télécharger et installer la dernière version
wget https://github.com/aquasecurity/trivy/releases/download/v0.50.0/trivy_0.50.0_Linux-64bit.deb
sudo dpkg -i trivy_0.50.0_Linux-64bit.deb

# Vérifier
trivy --version
```

#### 3. jq (pour le traitement JSON)
```bash
sudo apt install jq -y

# Vérifier l'installation
jq --version
```

### Récupération du script

- Cloner le repository
```bash
git clone https://github.com/williamWilliam10/Docker-SBOM-Analyzer.git
cd Docker-SBOM-Analyzer
```

- Donner les permissions d'exécution
```bash
chmod +x docker_sbom_scan.sh
```

## 🚀 Utilisation

### Étape 1 : Préparer vos images Docker

Assurez-vous que l'image que vous souhaitez analyser existe localement :
```bash
# Lister vos images locales
docker images

# Si besoin, builder ou pull une image
docker pull nginx:latest
# ou
docker build -t mon-application .
```

### Étape 2 : Lancer l'analyse
```bash
./docker_sbom_scan.sh
```

Le script va :
1. Afficher la liste de vos images Docker locales
2. Vous demander le nom de l'image à analyser
3. Générer le SBOM complet
4. Scanner toutes les vulnérabilités
5. Créer un rapport HTML interactif

**Exemple d'exécution :**
```
=== [Docker-SBOM-Analyzer] Analyse SBOM d'image Docker locale (Trivy) ===

Images Docker disponibles localement :
REPOSITORY          TAG       SIZE
nginx               latest    187MB
mon-app             1.0       543MB
python              3.11      1.01GB

Entrez le nom de l'image Docker locale : nginx

✓ Image locale détectée
Analyse de l'image : nginx

[1/3] Génération du SBOM...
✓ SBOM généré

[2/3] Scan des vulnérabilités...
✓ Vulnérabilités analysées

[3/3] Génération du rapport HTML...
✓ Rapport HTML généré

=== Analyse terminée ===
Rapports disponibles dans : sbom_reports_20260223_180855/

📊 Résumé des vulnérabilités :
  🔴 Critiques : 12
  🟠 Élevées   : 45
  🟡 Moyennes  : 89
  🔵 Faibles   : 23
  📊 Total     : 169

Ouvrir le rapport :
  firefox sbom_reports_20260223_180855/report.html
```

### Étape 3 : Consulter les résultats

Ouvrez le rapport HTML généré dans votre navigateur :
```bash
firefox sbom_reports_*/report.html
# ou
chromium sbom_reports_*/report.html
```

## 📂 Structure des rapports générés
```
sbom_reports_20260223_180855/
├── sbom.json                    # SBOM complet au format CycloneDX (JSON)
├── sbom.txt                     # SBOM lisible (tableau)
├── vulnerabilities.json         # Liste des vulnérabilités (JSON)
├── vulnerabilities.txt          # Vulnérabilités lisibles (tableau)
└── report.html                  # Rapport HTML interactif
```

## 📊 Interprétation des résultats

### Niveaux de sévérité

| Niveau | Description | Action recommandée |
|--------|-------------|-------------------|
| 🔴 **CRITICAL** | Vulnérabilité critique exploitable | **Action immédiate** - Patcher ou remplacer |
| 🟠 **HIGH** | Vulnérabilité sérieuse | Planifier un correctif rapidement |
| 🟡 **MEDIUM** | Vulnérabilité modérée | Inclure dans le prochain cycle de maintenance |
| 🔵 **LOW** | Vulnérabilité mineure | Corriger si possible |

### Exemple de rapport

Le rapport HTML inclut :
- **Statistiques visuelles** : Nombre de vulnérabilités par niveau de sévérité
- **SBOM complet** : Liste de tous les packages et dépendances
- **Détails des vulnérabilités** : CVE, score CVSS, packages affectés, correctifs disponibles

## 🔍 Détails techniques

### Ce que Trivy analyse

- ✅ **OS packages** : Debian, Ubuntu, Alpine, RHEL, CentOS, etc.
- ✅ **Dépendances applicatives** : Python (pip), Node.js (npm), Java (Maven), Go (modules), Ruby (gem), etc.
- ✅ **Fichiers de configuration** : Dockerfiles, Kubernetes manifests
- ✅ **Secrets** : Clés API, tokens, mots de passe hardcodés

### Bases de données de vulnérabilités

Trivy utilise plusieurs sources pour une couverture maximale :
- National Vulnerability Database (NVD)
- GitHub Security Advisories
- Red Hat Security Data
- Debian Security Tracker
- Alpine SecDB
- Amazon Linux Security Center
- Oracle Linux Security Data

## 💡 Cas d'usage

### 1. Audit de sécurité pré-production
```bash
# Analyser une image avant déploiement
./docker_sbom_scan.sh
# Entrer : mon-app:latest

# Vérifier qu'il n'y a pas de vulnérabilités critiques
# Si CRITICAL > 0 → Ne pas déployer
```

### 2. Intégration CI/CD
```bash
# Dans votre pipeline GitLab CI / GitHub Actions
./docker_sbom_scan.sh <<< "mon-app:${CI_COMMIT_TAG}"

# Fail si vulnérabilités critiques détectées
if [ $(jq '[.Results[].Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' sbom_reports_*/vulnerabilities.json) -gt 0 ]; then
    echo "Vulnérabilités critiques détectées !"
    exit 1
fi
```

### 3. Audit de conformité

Générer des rapports SBOM pour la conformité réglementaire (NTIA, EO 14028, etc.)

## 🐛 Problèmes courants

### L'image n'est pas trouvée

**Erreur :**
```
✗ Erreur : L'image 'mon-app' n'existe pas localement
```

**Solution :**
```bash
# Vérifier le nom exact de l'image
docker images

# Utiliser le nom complet avec tag si nécessaire
./docker_sbom_scan.sh
# Entrer : mon-app:1.0 (pas juste mon-app)
```

### Permission denied avec Docker

**Erreur :**
```
permission denied while trying to connect to the Docker daemon socket
```

**Solution :**
```bash
# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker

# Ou relancer avec sudo (non recommandé)
sudo ./docker_sbom_scan.sh
```

### jq command not found

**Erreur :**
```
jq: command not found
```

**Solution :**
```bash
sudo apt install jq -y
```

### Trivy database update failed

**Erreur :**
```
error in image scan: failed to download vulnerability DB
```

**Solution :**
```bash
# Mettre à jour manuellement la base de données
trivy image --download-db-only

# Puis relancer le scan
./docker_sbom_scan.sh
```

## 🔄 Mise à jour

### Mettre à jour Trivy
```bash
sudo apt update && sudo apt upgrade trivy
```

### Mettre à jour la base de données de vulnérabilités
```bash
trivy image --download-db-only
```

La base de données est mise à jour automatiquement toutes les 12 heures par défaut.

## 👥 Auteur

- **William Lowe** - [lowewilliam.com](https://lowewilliam.com)

## 📄 License

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🙏 Remerciements

- [Aqua Security](https://www.aquasec.com/) pour Trivy
- La communauté open-source pour les bases de données de vulnérabilités

---

⭐️ Si ce projet vous a aidé, n'hésitez pas à lui donner une étoile !

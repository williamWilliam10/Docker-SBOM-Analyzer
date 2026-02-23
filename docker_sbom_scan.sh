#!/bin/bash
# Auteur : William Lowe
# Description : Analyse SBOM complète d'images Docker locales avec Trivy

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== [Docker-SBOM-Analyzer] Analyse SBOM d'image Docker locale (Trivy) ===${NC}"

# Vérifier si Trivy est installé
if ! command -v trivy &> /dev/null; then
    echo -e "${YELLOW}Trivy n'est pas installé. Installation...${NC}"
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
    echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
    sudo apt update && sudo apt install trivy -y
fi

# Afficher les images disponibles
echo -e "${YELLOW}Images Docker disponibles localement :${NC}"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -20
echo ""

# Demande du nom de l'image
read -p "Entrez le nom de l'image Docker locale : " IMAGE_NAME

if [ -z "$IMAGE_NAME" ]; then
    echo -e "${RED}Erreur : Aucune image spécifiée${NC}"
    exit 1
fi

# Vérifier si l'image existe localement
if ! docker images --format "{{.Repository}}" | grep -q "^${IMAGE_NAME}$"; then
    echo -e "${RED}✗ Erreur : L'image '$IMAGE_NAME' n'existe pas localement${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Image locale détectée${NC}"

# Création du dossier de rapports
REPORT_DIR="sbom_reports_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo -e "${BLUE}Analyse de l'image : $IMAGE_NAME${NC}"

# 1. Génération du SBOM
echo -e "${YELLOW}[1/3] Génération du SBOM...${NC}"
trivy image --format cyclonedx --output "$REPORT_DIR/sbom.json" "$IMAGE_NAME" 2>/dev/null
trivy image --format table --output "$REPORT_DIR/sbom.txt" "$IMAGE_NAME" 2>/dev/null
echo -e "${GREEN}✓ SBOM généré${NC}"

# 2. Scan des vulnérabilités
echo -e "${YELLOW}[2/3] Scan des vulnérabilités...${NC}"
trivy image --severity CRITICAL,HIGH,MEDIUM,LOW --format json --output "$REPORT_DIR/vulnerabilities.json" "$IMAGE_NAME" 2>/dev/null
trivy image --severity CRITICAL,HIGH,MEDIUM,LOW --format table --output "$REPORT_DIR/vulnerabilities.txt" "$IMAGE_NAME" 2>/dev/null
echo -e "${GREEN}✓ Vulnérabilités analysées${NC}"

# 3. Calcul des statistiques
VULN_JSON=$(cat "$REPORT_DIR/vulnerabilities.json")
CRITICAL=$(echo "$VULN_JSON" | jq '[.Results[].Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' 2>/dev/null || echo "0")
HIGH=$(echo "$VULN_JSON" | jq '[.Results[].Vulnerabilities[]? | select(.Severity == "HIGH")] | length' 2>/dev/null || echo "0")
MEDIUM=$(echo "$VULN_JSON" | jq '[.Results[].Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' 2>/dev/null || echo "0")
LOW=$(echo "$VULN_JSON" | jq '[.Results[].Vulnerabilities[]? | select(.Severity == "LOW")] | length' 2>/dev/null || echo "0")
TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW))

# 4. Génération du rapport HTML
echo -e "${YELLOW}[3/3] Génération du rapport HTML...${NC}"

SBOM_CONTENT=$(cat "$REPORT_DIR/sbom.txt" | sed 's/</\&lt;/g; s/>/\&gt;/g')
VULN_CONTENT=$(cat "$REPORT_DIR/vulnerabilities.txt" | sed 's/</\&lt;/g; s/>/\&gt;/g')

cat > "$REPORT_DIR/report.html" << EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport SBOM - ${IMAGE_NAME}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        .container { max-width: 1400px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; margin-bottom: 25px; font-size: 32px; }
        .meta { 
            background: #f8f9fa; 
            padding: 20px; 
            border-radius: 8px; 
            margin-bottom: 30px; 
            border-left: 4px solid #3498db;
        }
        .meta-item {
            display: flex;
            margin-bottom: 12px;
            font-size: 15px;
        }
        .meta-item:last-child {
            margin-bottom: 0;
        }
        .meta-label {
            font-weight: bold;
            color: #34495e;
            min-width: 100px;
        }
        .meta-value {
            color: #555;
        }
        .section { margin: 40px 0; }
        .section h2 { color: #34495e; border-bottom: 3px solid #3498db; padding-bottom: 10px; margin-bottom: 25px; font-size: 24px; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 20px; margin: 20px 0; }
        .stat-card { color: white; padding: 25px; border-radius: 10px; text-align: center; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .stat-card.critical { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
        .stat-card.high { background: linear-gradient(135deg, #fa709a 0%, #fee140 100%); }
        .stat-card.medium { background: linear-gradient(135deg, #fbc2eb 0%, #a6c1ee 100%); }
        .stat-card.low { background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%); }
        .stat-card.total { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
        .stat-number { font-size: 48px; font-weight: bold; margin-bottom: 5px; }
        .stat-label { font-size: 14px; opacity: 0.95; text-transform: uppercase; letter-spacing: 1px; }
        pre { background: #2c3e50; color: #ecf0f1; padding: 25px; border-radius: 8px; overflow-x: auto; font-size: 13px; line-height: 1.6; max-height: 600px; }
        .alert { padding: 15px; border-radius: 5px; margin: 20px 0; }
        .alert.warning { background: #fff3e0; border-left: 4px solid #ff9800; color: #e65100; }
        .alert.success { background: #e8f5e9; border-left: 4px solid #4caf50; color: #1b5e20; }
        .alert.info { background: #e3f2fd; border-left: 4px solid #2196f3; color: #0d47a1; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Rapport d'Analyse SBOM</h1>
        
        <div class="meta">
            <div class="meta-item">
                <span class="meta-label">Image :</span>
                <span class="meta-value">${IMAGE_NAME}</span>
            </div>
            <div class="meta-item">
                <span class="meta-label">Date :</span>
                <span class="meta-value">$(date '+%Y-%m-%d %H:%M:%S')</span>
            </div>
            <div class="meta-item">
                <span class="meta-label">Outil :</span>
                <span class="meta-value">Docker-SBOM-Analyzer (Trivy) by William Lowe</span>
            </div>
        </div>

        <div class="section">
            <h2>📊 Statistiques des Vulnérabilités</h2>
            <div class="stats">
                <div class="stat-card critical">
                    <div class="stat-number">${CRITICAL}</div>
                    <div class="stat-label">Critiques</div>
                </div>
                <div class="stat-card high">
                    <div class="stat-number">${HIGH}</div>
                    <div class="stat-label">Élevées</div>
                </div>
                <div class="stat-card medium">
                    <div class="stat-number">${MEDIUM}</div>
                    <div class="stat-label">Moyennes</div>
                </div>
                <div class="stat-card low">
                    <div class="stat-number">${LOW}</div>
                    <div class="stat-label">Faibles</div>
                </div>
                <div class="stat-card total">
                    <div class="stat-number">${TOTAL}</div>
                    <div class="stat-label">Total</div>
                </div>
            </div>
            
            $(if [ "$CRITICAL" -gt 0 ]; then
                echo '<div class="alert warning"><strong>⚠️ Attention :</strong> '${CRITICAL}' vulnérabilité(s) critique(s) détectée(s). Action immédiate recommandée.</div>'
            elif [ "$TOTAL" -eq 0 ]; then
                echo '<div class="alert success"><strong>✅ Excellent :</strong> Aucune vulnérabilité détectée.</div>'
            else
                echo '<div class="alert info"><strong>ℹ️ Info :</strong> '${TOTAL}' vulnérabilité(s) détectée(s).</div>'
            fi)
        </div>

        <div class="section">
            <h2>📦 SBOM Complet</h2>
            <pre>${SBOM_CONTENT}</pre>
        </div>

        <div class="section">
            <h2>🔐 Vulnérabilités Détectées</h2>
            <pre>${VULN_CONTENT}</pre>
        </div>
    </div>
</body>
</html>
EOF

echo -e "${GREEN}✓ Rapport HTML généré${NC}"

# Résumé
echo -e "\n${GREEN}=== Analyse terminée ===${NC}"
echo -e "Rapports disponibles dans : ${YELLOW}$REPORT_DIR/${NC}"
echo -e "\n${YELLOW}📊 Résumé des vulnérabilités :${NC}"
echo -e "  🔴 Critiques : ${CRITICAL}"
echo -e "  🟠 Élevées   : ${HIGH}"
echo -e "  🟡 Moyennes  : ${MEDIUM}"
echo -e "  🔵 Faibles   : ${LOW}"
echo -e "  📊 Total     : ${TOTAL}"

echo -e "\n${BLUE}Ouvrir le rapport :${NC}"
echo -e "  firefox $REPORT_DIR/report.html"

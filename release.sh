#!/bin/bash

# Release Script für Internet Monitor
# Erstellt neue Versionen und stößt Release-Prozess an

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funktionen
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           Internet Monitor Release          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Prüfe Git Status
check_git_status() {
    if [ -n "$(git status --porcelain)" ]; then
        print_error "Es gibt uncommitted Änderungen. Bitte committe oder stashe sie zuerst."
        git status --short
        exit 1
    fi
    
    if [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then
        print_error "Du befindest dich nicht auf der main-Branch. Wechsle zuerst zur main-Branch."
        exit 1
    fi
}

# Hole aktuelle Version
get_current_version() {
    CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    CURRENT_VERSION=${CURRENT_TAG#v}
    
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR=${VERSION_PARTS[0]:-0}
    MINOR=${VERSION_PARTS[1]:-0}
    PATCH=${VERSION_PARTS[2]:-0}
}

# Berechne neue Versionen
calculate_versions() {
    NEXT_PATCH="$MAJOR.$MINOR.$((PATCH + 1))"
    NEXT_MINOR="$MAJOR.$((MINOR + 1)).0"
    NEXT_MAJOR="$((MAJOR + 1)).0.0"
}

# Zeige Menü
show_menu() {
    echo ""
    print_info "Aktuelle Version: ${CURRENT_TAG}"
    echo ""
    echo "Wähle den Release-Typ:"
    echo "1) Patch Release (Bug-Fix):  v${NEXT_PATCH}"
    echo "2) Minor Release (Feature):  v${NEXT_MINOR}"
    echo "3) Major Release (Breaking): v${NEXT_MAJOR}"
    echo "4) Abbrechen"
    echo ""
    read -p "Deine Wahl (1-4): " choice
}

# Führe Release durch
perform_release() {
    case $choice in
        1)
            VERSION_TYPE="patch"
            NEW_VERSION=$NEXT_PATCH
            ;;
        2)
            VERSION_TYPE="minor"
            NEW_VERSION=$NEXT_MINOR
            ;;
        3)
            VERSION_TYPE="major"
            NEW_VERSION=$NEXT_MAJOR
            ;;
        4)
            print_info "Release abgebrochen."
            exit 0
            ;;
        *)
            print_error "Ungültige Auswahl."
            exit 1
            ;;
    esac
    
    NEW_TAG="v${NEW_VERSION}"
    
    echo ""
    print_info "Erstelle Release ${NEW_TAG}..."
    
    # Bestätigung
    read -p "Möchtest du Release ${NEW_TAG} erstellen? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Release abgebrochen."
        exit 0
    fi
    
    # Pull latest changes
    print_info "Hole neueste Änderungen..."
    git pull origin main
    
    # Push zu GitHub um Release Workflow auszulösen
    print_info "Starte GitHub Actions Release Workflow..."
    
    # Verwende GitHub CLI falls verfügbar
    if command -v gh &> /dev/null; then
        print_info "Löse Release Workflow mit GitHub CLI aus..."
        gh workflow run release.yml --field version_type="$VERSION_TYPE"
        
        print_success "Release Workflow gestartet!"
        print_info "Verfolge den Fortschritt unter: https://github.com/$(git remote get-url origin | sed 's|.*github\.com[:/]||' | sed 's|\.git$||')/actions"
    else
        print_warning "GitHub CLI (gh) nicht installiert."
        print_info "Du kannst den Release Workflow manuell auf GitHub starten:"
        print_info "1. Gehe zu: https://github.com/$(git remote get-url origin | sed 's|.*github\.com[:/]||' | sed 's|\.git$||')/actions"
        print_info "2. Wähle 'Automatic Release and Version Tagging'"
        print_info "3. Klicke 'Run workflow'"
        print_info "4. Wähle Version Type: ${VERSION_TYPE}"
        print_info "5. Klicke 'Run workflow'"
    fi
}

# Zeige Ergebnis
show_result() {
    echo ""
    print_success "Release-Prozess gestartet!"
    echo ""
    print_info "Nach erfolgreichem Workflow ist verfügbar:"
    echo "  🏷️  Git Tag: ${NEW_TAG}"
    echo "  📦 GitHub Release: ${NEW_TAG}"
    echo "  🐳 Docker Image: syntaxsorcerer7/internet-monitor:${NEW_VERSION}"
    echo "  🐳 Docker Image: syntaxsorcerer7/internet-monitor:latest"
    echo ""
    print_info "Installation des neuen Releases:"
    echo "  docker pull syntaxsorcerer7/internet-monitor:${NEW_VERSION}"
    echo "  docker run -d -p 5000:5000 syntaxsorcerer7/internet-monitor:${NEW_VERSION}"
}

# Main Script
main() {
    print_header
    
    print_info "Prüfe Git Status..."
    check_git_status
    
    print_info "Ermittle aktuelle Version..."
    get_current_version
    calculate_versions
    
    show_menu
    perform_release
    show_result
}

# Führe Script aus
main

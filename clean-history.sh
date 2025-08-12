#!/bin/bash

# Skript zum Entfernen persönlicher Daten aus der Git-Historie
# WARNUNG: Das ist eine destruktive Operation!

echo "🔒 Starte Bereinigung der Git-Historie..."
echo "⚠️  WARNUNG: Das ist eine destruktive Operation!"
echo ""

# Alte E-Mail-Adressen und Namen, die ersetzt werden sollen
OLD_EMAIL1="julian.fruth@datev.de"
OLD_EMAIL2="julian3@mailbox.org"
OLD_NAME1="Julian Fruth"
OLD_NAME2="julian fruth"

# Neue anonyme Daten
NEW_EMAIL="anonymous@example.com"
NEW_NAME="Anonymous Developer"

echo "📝 Ersetze folgende Daten:"
echo "   $OLD_NAME1 <$OLD_EMAIL1> → $NEW_NAME <$NEW_EMAIL>"
echo "   $OLD_NAME2 <$OLD_EMAIL2> → $NEW_NAME <$NEW_EMAIL>"
echo ""

read -p "Möchten Sie fortfahren? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Abgebrochen."
    exit 1
fi

echo "🔄 Starte git filter-branch..."

git filter-branch --env-filter '
    # Für Author (Commit-Autor)
    if [ "$GIT_AUTHOR_EMAIL" = "'$OLD_EMAIL1'" ] || [ "$GIT_AUTHOR_EMAIL" = "'$OLD_EMAIL2'" ]; then
        export GIT_AUTHOR_NAME="'$NEW_NAME'"
        export GIT_AUTHOR_EMAIL="'$NEW_EMAIL'"
    fi
    if [ "$GIT_AUTHOR_NAME" = "'$OLD_NAME1'" ] || [ "$GIT_AUTHOR_NAME" = "'$OLD_NAME2'" ]; then
        export GIT_AUTHOR_NAME="'$NEW_NAME'"
        export GIT_AUTHOR_EMAIL="'$NEW_EMAIL'"
    fi
    
    # Für Committer (wer den Commit gemacht hat)
    if [ "$GIT_COMMITTER_EMAIL" = "'$OLD_EMAIL1'" ] || [ "$GIT_COMMITTER_EMAIL" = "'$OLD_EMAIL2'" ]; then
        export GIT_COMMITTER_NAME="'$NEW_NAME'"
        export GIT_COMMITTER_EMAIL="'$NEW_EMAIL'"
    fi
    if [ "$GIT_COMMITTER_NAME" = "'$OLD_NAME1'" ] || [ "$GIT_COMMITTER_NAME" = "'$OLD_NAME2'" ]; then
        export GIT_COMMITTER_NAME="'$NEW_NAME'"
        export GIT_COMMITTER_EMAIL="'$NEW_EMAIL'"
    fi
' --tag-name-filter cat -- --branches --tags

echo ""
echo "✅ Git-Historie bereinigt!"
echo "🔍 Überprüfe Ergebnis..."

# Ergebnis anzeigen
git log --pretty=format:"%h %an <%ae> %s" -10

echo ""
echo ""
echo "📋 Nächste Schritte:"
echo "1. git push --force-with-lease origin main"
echo "2. Alle anderen Entwickler müssen das Repository neu klonen"
echo "3. GitHub-Tags und Releases manuell überprüfen"
echo ""
echo "⚠️  WICHTIG: Das alte Repository-Backup ist verfügbar als 'internet-check-backup-*'"

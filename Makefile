SHELL := bash

.PHONY: android build bundle clean get help

# Target: android
# Lance Flutter sur Android
# Pour forcer un device : make android DEVICE=<id>  (voir: flutter devices)
android:
	@echo "Démarrage Flutter Android..."
	flutter run $(if $(DEVICE),-d $(DEVICE),)

# Target: build
# Compile un APK release
build:
	@echo "Build APK release..."
	flutter clean
	flutter pub get
	flutter build apk --release
	@echo ""
	@echo "APK généré : build/app/outputs/flutter-apk/app-release.apk"

# Target: bundle
# Génère le Android App Bundle (.aab) pour Google Play Console
bundle:
	@echo "Génération du Android App Bundle (Google Play)..."
	flutter clean
	flutter pub get
	flutter build appbundle --release
	@echo ""
	@echo "Bundle généré : build/app/outputs/bundle/release/app-release.aab"

# Target: clean
clean:
	@echo "Nettoyage des fichiers de build..."
	flutter clean

# Target: get
get:
	flutter pub get

# Target: help
help:
	@echo "Commandes disponibles :"
	@echo "  android  - Lancer sur Android (DEV) — logs filtrés"
	@echo "             Forcer un device : make android DEVICE=<id>"
	@echo "  build    - Compiler un APK release (PROD)"
	@echo "  bundle   - Générer un .aab pour Google Play (PROD)"
	@echo "  clean    - Nettoyer les fichiers de build"
	@echo "  get      - flutter pub get"

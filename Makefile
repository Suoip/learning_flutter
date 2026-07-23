# Makefile for building and deploying the Flutter app.
#
# Secrets are never read from .env or bundled as Flutter assets - they are
# injected at compile time via --dart-define-from-file so they can never end
# up inside a build output that gets published (see env.example.json).

BASE_HREF ?= /
GITHUB_REPO ?= https://github.com/Suoip/FlutterWeb
CUSTOM_DOMAIN ?= flutterweb.salihonder.dev
ENV_FILE ?= env.json
# Must match android/app/src/main/AndroidManifest.xml's intent-filter data
# tag and be allow-listed in the Supabase dashboard's Redirect URLs. Passed
# as its own --dart-define below (after --dart-define-from-file) so it
# always overrides whatever SUPABASE_EMAIL_REDIRECT_TO happens to be in
# ENV_FILE - that file is shared with local web dev, where the redirect
# needs to be a plain http:// URL instead, not this custom scheme.
MOBILE_EMAIL_REDIRECT_TO ?= com.example.new_project://login-callback
BUILD_VERSION := $(shell python -c "import pathlib, re; text = pathlib.Path('pubspec.yaml').read_text(encoding='utf-8'); m = re.search(r'^version:\s*([^\s]+)', text, re.M); print(m.group(1) if m else 'unknown')")

# Web builds source secrets from the environment (e.g. CI/CD secrets) instead
# of ENV_FILE, so deploy-web never depends on a local file being present.
# GNU Make automatically imports the process environment as make variables,
# so $(SUPABASE_URL) below is substituted by make itself, before the line
# ever reaches a shell - this works the same under cmd.exe or sh, unlike
# POSIX syntax (test, $$VAR, ${VAR}), which cmd.exe doesn't understand.
# The `flutter` command is a .bat wrapper on Windows, so it's invoked as a
# plain recipe line (not via python subprocess) so the shell's normal
# PATHEXT resolution can find it.
deploy-web:
	@echo "Checking required environment variables"
	python -c "import sys; sys.exit(0) if '$(SUPABASE_URL)' and '$(SUPABASE_ANON_KEY)' and '$(SUPABASE_EMAIL_REDIRECT_TO)' else sys.exit('ERROR: SUPABASE_URL, SUPABASE_ANON_KEY, and/or SUPABASE_EMAIL_REDIRECT_TO are not set. Export them before running make deploy-web.')"

	@echo "Cleaning previous build artifacts"
	flutter clean

	@echo "Getting packages"
	flutter pub get

	@echo "Building for web"
	flutter build web --base-href=$(BASE_HREF) --release --dart-define=SUPABASE_URL=$(SUPABASE_URL) --dart-define=SUPABASE_ANON_KEY=$(SUPABASE_ANON_KEY) --dart-define=SUPABASE_EMAIL_REDIRECT_TO=$(SUPABASE_EMAIL_REDIRECT_TO)

	@echo "Creating CNAME and .nojekyll"
	@python -c "from pathlib import Path; Path('build/web').mkdir(parents=True, exist_ok=True); Path('build/web/CNAME').write_text('$(CUSTOM_DOMAIN)\n', encoding='utf-8'); Path('build/web/.nojekyll').write_text('', encoding='utf-8')"

	@echo "Preparing deployment repository"
	@python -c "import pathlib, shutil, subprocess; root = pathlib.Path('build/web'); root.mkdir(parents=True, exist_ok=True); git_dir = root / '.git'; shutil.rmtree(git_dir, ignore_errors=True); subprocess.run(['git', '-C', str(root), 'init'], check=True, stdout=subprocess.DEVNULL); subprocess.run(['git', '-C', str(root), 'remote', 'remove', 'origin'], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); subprocess.run(['git', '-C', str(root), 'remote', 'add', 'origin', '$(GITHUB_REPO)'], check=True); subprocess.run(['git', '-C', str(root), 'add', '.'], check=True); subprocess.run(['git', '-C', str(root), 'commit', '-m', 'Deploy $(BUILD_VERSION)'], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)"
	git -C build/web branch -m main
	git -C build/web push -u --force origin main

	@echo "Deploy finished!"

# Local APK build, sourcing secrets from ENV_FILE (default env.json - copy
# env.example.json to env.json and fill in your values, it's gitignored).
# SUPABASE_EMAIL_REDIRECT_TO from ENV_FILE is overridden with
# MOBILE_EMAIL_REDIRECT_TO, since ENV_FILE's value is meant for local web
# dev (see the comment on MOBILE_EMAIL_REDIRECT_TO above).
build-apk:
	python -c "import pathlib, sys; sys.exit(0) if pathlib.Path('$(ENV_FILE)').is_file() else sys.exit('ERROR: $(ENV_FILE) not found. Copy env.example.json to $(ENV_FILE) and fill in your values.')"
	flutter build apk --release --dart-define-from-file=$(ENV_FILE) --dart-define=SUPABASE_EMAIL_REDIRECT_TO=$(MOBILE_EMAIL_REDIRECT_TO)

# Static analysis + unit tests. Mirrors what the CI workflow runs, so you can
# reproduce a CI failure locally before pushing.
test:
	dart format --output=none --set-exit-if-changed .
	flutter analyze
	flutter test

.PHONY: deploy-web build-apk test
# Developer entry points for the TaxOS monorepo.
.PHONY: deps analyze test test-engine build-web run-api run-web ci

deps:
	flutter pub get

analyze:
	cd packages/tax_engine && dart analyze --fatal-infos
	cd services/api && dart analyze --fatal-infos
	cd packages/taxos_ui && flutter analyze --fatal-infos
	cd apps/taxos_app && flutter analyze --fatal-infos

test-engine:
	cd packages/tax_engine && dart test
	cd services/api && dart test

test: test-engine
	cd packages/taxos_ui && flutter test
	cd apps/taxos_app && flutter test

build-web:
	cd apps/taxos_app && flutter build web --release

run-api:
	cd services/api && dart run bin/server.dart

run-web:
	cd apps/taxos_app && flutter run -d chrome

ci:
	tool/ci.sh build

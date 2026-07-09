#!/usr/bin/env bash
# Run the app in Chrome against staging DHIS2.
# Staging (hmis-staging.moh.gov.et) only allows CORS from localhost:3000/3001,
# and port 3000 is occupied on this machine — so the app MUST run on 3001.
# A plain `flutter run` picks a random port and every API call gets blocked.
exec flutter run -d chrome --web-port=3001 --web-hostname=localhost "$@"

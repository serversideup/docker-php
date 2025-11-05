#!/bin/sh
###################################################
# Usage: 2-deprecated.sh
###################################################
# This script displays a deprecation warning for NGINX Unit.
# NGINX Unit has been archived and is no longer maintained.

: "${UNIT_SKIP_DEPRECATION_DELAY:=false}"

echo '
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                    ⚠️  CRITICAL DEPRECATION NOTICE ⚠️             ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

🛑 NGINX UNIT HAS BEEN ARCHIVED BY NGINX

In October 2025, NGINX officially archived the NGINX Unit project and
stopped all maintenance and development. The Docker image you are
using is deprecated and will be removed in the next release.

───────────────────────────────────────────────────────────────────

⚡ RECOMMENDED ACTION: Migrate to a different variation

📚 Migration Guide:
   https://serversideup.net/php/unit-deprecation

📖 Official NGINX Unit Announcement:
   https://github.com/nginx/unit

ℹ️  Need Help?
   https://serversideup.net/php/community

───────────────────────────────────────────────────────────────────

⚠️ Timeline:
   • Now: These images are deprecated and will not receive updates
   • Future: These images will be removed in the next release

───────────────────────────────────────────────────────────────────
'

# Add a 5-second pause to ensure the message is seen
# This pause can be disabled by setting UNIT_SKIP_DEPRECATION_DELAY=true
if [ "$UNIT_SKIP_DEPRECATION_DELAY" != "true" ]; then
    echo "⏳ Continuing in 5 seconds... (set UNIT_SKIP_DEPRECATION_DELAY=true to skip)"
    sleep 5
fi
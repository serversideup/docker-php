#!/bin/sh

# Exit on error
set -e

echo "🏃‍♂️ Laravel automations"

# # Check to see if an Artisan file exists and assume it means Laravel is configured.
# if [ -f $WEB_APP_DIRECTORY/artisan ] && [ ${AUTORUN_ENABLED:="true"} == "true" ]; then
#         echo "🏃‍♂️ Checking for Laravel automations..."

#         ############################################################################
#         # Automated database migrations
#         ############################################################################
#         if [ ${AUTORUN_LARAVEL_MIGRATION:="false"} == "true" ]; then
#             echo "🚀 Running migrations..."
#             php $WEB_APP_DIRECTORY/artisan migrate --force --isolated
#         fi

#         ############################################################################
#         # Automated storage linking
#         ############################################################################
#         if [ ${AUTORUN_LARAVEL_STORAGE_LINK:="true"} == "true" ]; then
#             if [ -d $WEB_APP_DIRECTORY/public/storage ]; then
#                 echo "✅ Storage already linked..."
#             else
#                 echo "🔐 Linking the storage..."
#                 php $WEB_APP_DIRECTORY/artisan storage:link
#             fi
#         fi
# else
#     echo "👉 Skipping Laravel automations because we could not detect a Laravel install or it was specifically disabled..."
# fi

# exit 0
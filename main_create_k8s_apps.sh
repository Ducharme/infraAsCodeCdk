
#!/bin/sh

. ./set_env-vars.sh

echo "Calling ./eks/deploy_apps.sh"
. ./eks/deploy_apps.sh


echo "FINISHED!"

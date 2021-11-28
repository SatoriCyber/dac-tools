
WHITE='\033[0;37m'
RED='\033[0;31m'
GREEN='\033[0;32m'

context=$(kubectl config current-context)
read -p "$(echo The current kubernetes context is:${RED} $context.\\n${WHITE}Type \'yes\' to approve to start the preflight tests:) " CONT
if [ "$CONT" != "yes" ]; then
    echo "exiting..."
    exit
fi
echo 'Running kubernetes preflight checks...'
kubectl preflight ./kubernetes_test.yaml
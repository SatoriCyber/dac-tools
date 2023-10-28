# ArgoCD integration

This is a bash script which performs the following:  ``

1. Discovers the latest stable version for Satori DAC.  
2. Downloads the package to a temprorary directory and extracts it from the tarball.  
3. Push the installation package to a git repo to a current branch.  
4. Make sure that the ArgoCD apply the helm chart with the following value files and in exact order:
  `--values version-values.yaml --values customer-values.yaml --values customer-override.yaml --set service_accountid=<SATORI_SERVICE_ID> --set service_account_key=<SATORI_SERVICE_KEY>`
5. The `<SATORI_SERVICE_ID>` and `<SATORI_SERVICE_KEY>` should be obtained from Satori management console. Since these parameters are sensitive, you must store them in a secured store and provide them to the ArgoCD dynamically.

Note: The assumption that the git repo is tracked by ArgoCD, so the `git push` will trigger the ArgoCD helm reconciliation with the actual deployment.  
The script performs git push to a current branch. Consider changing it according to your company policy.

## Prerequisites

1. Obtain the Satori service key and export it accordingly for using it by the bash script and the ArgoCD.
```
export SATORI_SERVICE_ID=<SATORI_SERVICE_ID>
export SATORI_SERVICE_KEY=<SATORI_SERVICE_KEY>
```
![Screenshot](satori-sa.png)

2. Export the DAC_ID for using it by the bash script
```
export DAC_ID=<DAC_ID>
```
![Screenshot](satori-dac-id.png)

3 .Export the path to the cloned git repo. The package will be copied to that repo and pushed to master.
```
export REPO_PATH=<REPO_PATH>
```
4. The kube .config file is configured. The cluster context is set to the desired kubernetes cluster.

5. Make sure with Satori suport that you have thse values in your Helm chart.
```
runtimeConf:
  dacInstaller:
    # When helm runs it won't create the bootstrap access key in kubernetes, kubernetes secret store should be populate with the secret in another manner
    installSecret: false
  dacManager:
    # For argoCD, dac-manager reports version based on static value in the helm chart and not dynamic 
    versionReporter:
      static:
        enabled: true 
```

## How to run
1. Make sure you are authenticated to the kubernetes cluster and .kubecofnig is set to the right cluster contex.
2. Run the script
```
./get_satori_installation_package.sh
```


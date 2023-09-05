## Monitoring your Data Store
- The code provided in this repo is a reference implementation of blackbox monitoring for your datastores and the Satori DAC, we strongly encourage the use of blackbox monitoring as it can detect a wide range of problems outside the scope of the cluster (networking, DNS, ...). 
- Blackbox monitoring is about monitoring the level of service provided to your end users, it can detect service level degradation in real time and should be used in parallel to other monitoring methods which can provide a more detailed view of service health.

## How does it work?
- The provided Terraform code will provision a lambda function (Python based) which runs a simple query via the Satori DAC to the origin datastore. In case the query fails for any reason, the function will exit with an error.
- The lambda function is triggered via an AWS EventBridge (default interval of one hour).
- Access parameters and other customization options should be set in the Terraform variables file.

## Alerting
- In case the query fails for any reason the function will exit with an error, which can then be transformed into an alert via CloudWatch and Incident Manager, Alternatively the function can be modified to connect into an external system (see the provided alert snippets in alerts.py).

## Networking
- If you use Satori to whitelist IP's, you will need to attach the lambda to a NAT gateway and whitelist its IP.
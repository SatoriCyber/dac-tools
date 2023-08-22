## What is monitoring-datastores?
- Blackbox monitoring of your Satori Datastore.

## How does it work?
- Python script which runs a simple query through Satori and throws exception if fails.
- The code is deployed as an AWS Lambda function.
- Amazon EventBridge triggers the Lambda every hour.

## Alerting
- The python code by default raise an exeption when query fails.
- When a query fails, an exception is raised, the exception can then be transformed into an alert via CloudWatch and Incident Manager, Alternatively the exception can be replaced with one of the provided alert snippets (see alerts.py).

## Networking
- If you use Satori to whitelist IP's, you will need to attach the lambda to a NAT gateway and whitelist its IP.
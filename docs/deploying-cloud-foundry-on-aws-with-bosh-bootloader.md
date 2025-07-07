# Deploying Cloud Foundry on AWS with BOSH Bootloader

This guide provides step‑by‑step instructions to deploy Cloud Foundry on AWS using BOSH Bootloader (bbl), BOSH, and cf‑deployment.

## Tool Installation (macOS)

### Install `terraform`, `bosh` and `bbl`
Follow the steps in [Step 1: Download dependencies](https://docs.cloudfoundry.org/deploying/common/aws.html)

### Install `credhub-cli`

```bash
brew install cloudfoundry/tap/credhub-cli
sudo mv /opt/homebrew/Cellar/credhub-cli/*/bin/credhub /usr/local/bin

# Verify the installation
credhub --version
```

### Install `cf` (Cloud Foundry CLI)

```bash
brew install cloudfoundry/tap/cf-cli@8
sudo mv /opt/homebrew/Cellar/cf-cli/*/bin/cf /usr/local/bin

# Verify the installation
cf version
```

## Set Up an IAM User

### Create an IAM User

Follow the steps in [Step 2: Create an IAM User](https://docs.cloudfoundry.org/deploying/common/aws.html).

### Save the IAM User Credentials
Save the AWS credentials in your environment variables from the previous step. Replace `your-access-key-id` and `your-secret-access-key` with your actual AWS IAM user credentials:
```bash
export BBL_AWS_SECRET_ACCESS_KEY_ID="your-access-key-id"
export BBL_AWS_SECRET_ACCESS_KEY="your-secret-access-key"
```

## Deploying the BOSH Director on AWS

### Set Up Load Balancers with Self‑Signed Certificates

If you require a load balancer (for example, to expose the Cloud Foundry API), follow these steps:

#### Create Self‑Signed Certificates

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout lb-key.pem \
  -out lb-cert.pem \
  -subj "/CN=*.demo.cf.internal" # replace with your domain
```

#### Plan the Environment with Load Balancer Settings

Before deploying the BOSH director, you need to plan your environment with the load balancer settings. Replace the placeholders with your actual values:
```bash
bbl plan 
        # replace with your environment name
        --name demo \
        --iaas aws \
        --aws-access-key-id $BBL_AWS_SECRET_ACCESS_KEY_ID \
        --aws-secret-access-key $BBL_AWS_SECRET_ACCESS_KEY \
        # replace with your region
        --aws-region us-east-1 \
        # replace with your domain
        --lb-domain demo.cf.internal \
        --lb-cert lb-cert.pem \
        --lb-key lb-key.pem \
        --lb-type cf
```

#### Update the Environment

After planning, apply the changes to create the environment:
```bash
bbl up 
```

## Deploying Cloud Foundry

### Log into BOSH

```bash
eval "$(bbl print-env)"
export BOSH_ENVIRONMENT=$(bbl director-address)
bosh log-in
```

### Create an alias for the BOSH environment

```bash
bosh alias-env bosh-demo
```

### Clone the cf-deployment Repository

```bash
git clone https://github.com/cloudfoundry/cf-deployment.git
cd cf-deployment
```

### Upload a Stemcell

Cloud Foundry requires a stemcell (a virtual machine image). First, set your IAAS information and fetch the default stemcell version from the manifest:

```bash
export IAAS_INFO=aws-xen-hvm
export STEMCELL_VERSION=$(bosh -e bosh-demo interpolate cf-deployment.yml --path="/stemcells/alias=default/version")
```

Then, upload the corresponding stemcell (adjust the URL if necessary):

```bash
bosh -e bosh-demo upload-stemcell "https://bosh.io/d/stemcells/bosh-${IAAS_INFO}-ubuntu-jammy-go_agent?v=${STEMCELL_VERSION}"
```

### Deploy Cloud Foundry

Set your system domain and deploy cf-deployment with your chosen ops files:

```bash
bosh -e bosh-demo -d cf deploy cf-deployment.yml \
  # replace with your domain
  -v system_domain=demo.cf.internal \
  # optional ops files for customization
  -o operations/use-compiled-releases.yml \
  -o operations/experimental/fast-deploy-with-downtime-and-danger.yml \
  -o operations/aws.yml \
  -o operations/scale-to-one-az.yml \
  -o repo/cf-deployment/operations/experimental/enable-traffic-to-internal-networks.yml \
  -n
```

> **Note:** The ops files above are examples. Adjust them as needed for your AWS settings and deployment strategy.

### Retrieve CF Credentials and Log In

#### Get the Initial Admin Password from CredHub and Login

```bash
export CF_ADMIN_PASSWORD=$(credhub get -n /demo/cf/cf_admin_password -j | jq -r .value)
cf login -u admin -p "$CF_ADMIN_PASSWORD"
```

#### Target the Cloud Foundry API

```bash
cf api https://api.demo.cf.internal --skip-ssl-validation
cf create-space demo
cf target -o "system" -s "demo"
```

> ***Tip:*** If you encounter issues with the API URL, ensure that your DNS is correctly configured to resolve `api.demo.cf.internal` to the load balancer's IP address.
> For development purposes, you can update your local machine's `/etc/hosts` file to point `api.demo.cf.internal` to the load balancer's IP address. To do this, run:
> ```bash
> export SYSTEM_DOMAIN=demo.cf.internal
> export ENV_NAME=demo
> export LB_DNS_NAME=$(aws --profile your-profile --region us-east-1 elb describe-load-balancers --load-balancer-name $ENV_NAME-cf-router-lb --query 'LoadBalancerDescriptions[0].DNSName' --output text)
> export LB_IP=$(host $LB_DNS_NAME |tail -n 1 |awk '{print $4}')
> echo $LB_IP $SYSTEM_DOMAIN api.$SYSTEM_DOMAIN login.$SYSTEM_DOMAIN uaa.$SYSTEM_DOMAIN doppler.$SYSTEM_DOMAIN log-stream.$SYSTEM_DOMAIN log-cache.$SYSTEM_DOMAIN | sudo tee -a /etc/hosts
> ```

### BOSH CLI Environment Inspection Commands

Use these commands to check the state and configuration of your director before or after deploying Cloud Foundry:

- **List VMs:**

  ```bash
  bosh vms
  ```

- **Display Environment Information:**

  ```bash
  bosh env
  ```

- **List Deployments:**

  ```bash
  bosh deployments
  ```

- **List Stemcells:**

  ```bash
  bosh stemcells
  ```

- **List Releases:**

  ```bash
  bosh releases
  ```

- **Show Runtime Config:**

  ```bash
  bosh runtime-config
  ```

- **List Tasks:**

  ```bash
  bosh tasks
  ```

## References

- [BOSH Bootloader Getting Started on AWS](https://cloudfoundry.github.io/bosh-bootloader/getting-started-aws/)
- [cf-deployment Deployment Guide](https://github.com/cloudfoundry/cf-deployment/blob/main/texts/deployment-guide.md)
- [BOSH CLI Documentation](https://bosh.io/docs/cli-v2/)


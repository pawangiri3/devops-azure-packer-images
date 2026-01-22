# Packer Azure Ubuntu Custom Image

This Packer configuration builds a custom Ubuntu 22.04 LTS image on Azure with Nginx and a Starbucks clone application pre-installed.

## Overview
This repository contains Packer templates to build **custom Azure VM images**
with pre-installed software like Nginx, Java, and application dependencies.

## Image Build Flow
1. Packer authenticates to Azure using Service Principal
2. Base image: Ubuntu 22.04
3. Shell provisioners install required packages
4. Azure Managed Image is created

## Why Packer?
- Immutable infrastructure
- Faster VM provisioning
- Standardized golden images
- Reduced configuration drift


## Prerequisites

- Packer >= 1.9.0
- Azure CLI configured with credentials
- Azure subscription with appropriate permissions
- Azure resource group: `Custom-image-rg`

## Directory Structure

```
packer/
├── ubuntu.pkr.hcl         # Main Packer build configuration
├── variables.pkr.hcl      # Variable definitions
├── locals.pkr.hcl         # Local values
├── versions.pkr.hcl       # Version requirements
└── README.md              # This file
```
## Variables
| Variable | Description |
|--------|------------|
| client_id | Azure Service Principal ID |
| client_secret | Azure SP Secret |
| subscription_id | Azure Subscription |
| tenant_id | Azure Tenant |


## Files Overview

### ubuntu.pkr.hcl
Main Packer build configuration containing:
- Azure ARM source configuration (`ubuntu_image`)
- Build name: `ubuntu-nginx-image`
- Provisioning shell script for Nginx and Starbucks clone deployment
- Enterprise tags and metadata

**Key Features:**
- Automatic image versioning using `${local.image_name}-${var.image_version}`
- Build timestamp tracking in tags
- Security cleanup (waagent deprovision, temp file removal)

### variables.pkr.hcl
Defines input variables:
- `client_id` (string, required) - Azure AD client ID
- `client_secret` (string, sensitive, required) - Azure AD client secret
- `subscription_id` (string, required) - Azure subscription ID
- `tenant_id` (string, required) - Azure tenant ID
- `location` (string, default: `centralindia`) - Azure region
- `vm_size` (string, default: `Standard_B2s`) - VM size for temporary build VM
- `image_version` (string, default: `1.0.0`) - Version suffix for managed image

### locals.pkr.hcl
Defines local values:
- `image_name`: `ubuntu-nginx-starbucks` - Base image name
- `build_time`: Timestamp in format `YYYY-MM-DD hh:mm ZZZ`

### versions.pkr.hcl
Version requirements:
- Terraform: >= 1.0
- Packer: >= 1.9.0
- Azure plugin: ~> 2.1

## Configuration Details

### Source Image
- **Publisher**: Canonical
- **Offer**: 0001-com-ubuntu-server-jammy
- **SKU**: 22_04-lts (Ubuntu 22.04 LTS)
- **OS Type**: Linux

### VM Configuration
- **Temporary VM Size**: Standard_B2s (configurable)
- **Location**: Central India (configurable)
- **Resource Group**: Custom-image-rg

### Build Process
1. Update system packages (`apt-get update && upgrade`)
2. Install Nginx and Git
3. Clone Starbucks repository from GitHub
4. Deploy application to Nginx web root (`/var/www/html/`)
5. Security cleanup:
   - Remove Azure agent user data
   - Clear temp files
   - Clear command history
   - Sync filesystem

### Output Artifact
A managed image named in format: `ubuntu-nginx-starbucks-{version}` (e.g., `ubuntu-nginx-starbucks-1.0.0`)
- **Location**: `Custom-image-rg` resource group
- **Tags**: environment, owner, project, created_by, build_time

## Usage

### 1. Create terraform.tfvars

Create a `.tfvars` file with your Azure credentials:

```hcl
client_id       = "your-azure-client-id"
client_secret   = "your-azure-client-secret"
subscription_id = "your-azure-subscription-id"
tenant_id       = "your-azure-tenant-id"
location        = "centralindia"
vm_size         = "Standard_B2s"
image_version   = "1.0.0"
```

### 2. Initialize Packer

```bash
cd packer
packer init .
```

### 3. Validate Configuration

```bash
packer validate -var-file="terraform.tfvars" .
```

### 4. Build the Image

```bash
packer build -var-file="terraform.tfvars" .
```

### 5. Optional - Use Environment Variables

Instead of `.tfvars`, you can use environment variables prefixed with `PKR_VAR_`:

```bash
export PKR_VAR_client_id="your-client-id"
export PKR_VAR_client_secret="your-client-secret"
export PKR_VAR_subscription_id="your-subscription-id"
export PKR_VAR_tenant_id="your-tenant-id"
packer build .
```

## Code Quality Check ✅

- **HCL Syntax**: Valid and well-formatted
- **Variables**: All required variables properly defined with sensible defaults
- **Locals**: Proper use of timestamp formatting and computed values
- **Provisioning**: Optimized shell provisioning with combined commands
- **Security**: Includes Azure agent deprovision and cleanup operations
- **Enterprise Ready**: Tags include environment, owner, project, and build metadata

## Security Best Practices

⚠️ **Important Security Notes:**

1. **Credentials Management**:
   - Never commit `.tfvars` files to version control
   - Add `*.tfvars` to `.gitignore`
   - Use Azure Key Vault in production environments

2. **Resource Protection**:
   - Resource group `Custom-image-rg` must exist before build
   - Ensure service principal has limited scope permissions
   - Regularly rotate credentials

3. **CI/CD Integration**:
   - Use managed identities in Azure DevOps
   - Store secrets in Azure Key Vault
   - Use separate service principals per environment

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Authentication fails | Verify Azure CLI login: `az login` |
| Resource group not found | Create resource group: `az group create -n Custom-image-rg -l centralindia` |
| Insufficient quota | Check VM size quota in target region |
| Build timeout | Increase VM size or check network connectivity |
| Provisioning fails | Review Azure VM logs in portal for errors |

## Building with Different Configurations

### Development Build (faster)
```bash
packer build -var-file="terraform.tfvars" -var="vm_size=Standard_B1s" -var="image_version=dev-$(date +%s)" .
```

### Production Build
```bash
packer build -var-file="terraform.tfvars" -var="image_version=1.0.0" .
```

## Output Example

```
Build output:
==> Builds finished. The artifacts of successful builds are:
--> azure-arm.ubuntu_image: Azure.ResourceManagement.VMImage:

OSType: Linux
ManagedImageName: ubuntu-nginx-starbucks-1.0.0
ManagedImageResourceGroupName: Custom-image-rg
```

## Next Steps

After successful build, use the managed image to:
1. Create VMs from the image in Azure Portal
2. Use in Infrastructure as Code (Terraform/ARM templates)
3. Deploy to App Service or Container Instances
4. Use as base for further customization

## Security Best Practices
- Never commit secrets to GitHub
- Use environment variables or Azure Key Vault
- Add *.pkrvars.hcl to .gitignore

## Future Enhancements
- CI/CD pipeline using GitHub Actions
- Support for multiple OS images
- Image hardening scripts
- Multi-region image replication

## License

This configuration is provided as-is for DevOps and Infrastructure automation purposes.

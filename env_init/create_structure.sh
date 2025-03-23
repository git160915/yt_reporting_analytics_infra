#!/bin/bash
set -e

# Set BASE_DIR from the first command-line argument or default to "my-infra-repo"
BASE_DIR=${1:-my-infra-repo}
echo "Using base directory: $BASE_DIR"

# Create base directory
mkdir -p "$BASE_DIR"

# Create .github/workflows directory and deploy.yml
mkdir -p "$BASE_DIR/.github/workflows"
touch "$BASE_DIR/.github/workflows/deploy.yml"

# Create src directory (replacing infra)
mkdir -p "$BASE_DIR/src"

# Create src/modules structure
MODULES_DIR="$BASE_DIR/src/modules"
for module in state vpc security ssm ec2 responsible; do
    mkdir -p "$MODULES_DIR/$module"
    touch "$MODULES_DIR/$module/main.tf"
    touch "$MODULES_DIR/$module/variables.tf"
    touch "$MODULES_DIR/$module/outputs.tf"
done

# Create src/envs structure for dev, integration, and prod
ENVS_DIR="$BASE_DIR/src/envs"
for env in dev integration prod; do
    # Create env directory and its terragrunt.hcl file
    mkdir -p "$ENVS_DIR/$env/components"
    touch "$ENVS_DIR/$env/terragrunt.hcl"
    
    # Create components subdirectories and terragrunt.hcl for each component
    for comp in vpc security ssm ec2 responsible; do
         mkdir -p "$ENVS_DIR/$env/components/$comp"
         touch "$ENVS_DIR/$env/components/$comp/terragrunt.hcl"
    done
done

# Create README.md in the base directory
touch "$BASE_DIR/README.md"

echo "Directory structure created successfully in '$BASE_DIR'."

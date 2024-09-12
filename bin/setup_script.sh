#!/bin/bash

# Define color codes
LGREEN='\033[01;32m'   # Light green
LYELLOW='\033[01;33m'  # Light yellow
LRED='\033[01;31m'     # Light red
NC='\033[0m'           # No color (reset)

# Define symbols
THUMB_UP="${LYELLOW}\xF0\x9F\x91\x8D${NC}"   # Thumbs up (👍)
X_MARK="${LRED}\xE2\x9C\x96${NC}"             # Cross mark (✘)

# Define variables
#PACKAGE_NAME="ansible"
#REPO_URL="ppa:ansible/ansible"
GIT_REPO_URL="https://github.com/vrushalikudande/ansible-custom-config.git"
DOTFILES_DIR="$HOME/.dotfiles"

# Define the vault secret file
VAULT_SECRET="$HOME/.ansible-vault-pass"

# Set non-interactive frontend for debconf
export DEBIAN_FRONTEND=noninteractive

# Check the Machine
if [[ -f /.dockerenv ]]; then
    echo "Running inside a Docker container."
    apt update -y && apt install sudo -y
else
    echo "Running on a local machine."
    sudo locale-gen en_US.UTF-8
    sudo update-locale LANG=en_US.UTF-8
    source /etc/default/locale
fi

# Check if Ansible is already installed
if dpkg -s ansible >/dev/null 2>&1; then
  echo -e "${LGREEN}Ansible is already installed.${NC}"
else
  # Update the package list
  echo "updating"
  sudo apt-get update -qq >/dev/null 2>&1

  # Install apt-utils to avoid configuration delay warnings
  echo "Installing apt-utils..."
  sudo apt-get install -y apt-utils >/dev/null 2>&1

  # Install software-properties-common to manage repositories
  echo "Installing required packages..."
  sudo apt-get install -y software-properties-common >/dev/null #2>&1

  # Add Ansible PPA (Personal Package Archive)
  echo "Adding Ansible PPA..."
  sudo apt-add-repository --yes --update ppa:ansible/ansible >/dev/null 2>&1

  # Install Ansible
  echo "Installing Ansible..."
  sudo apt-get install -y ansible >/dev/null 2>&1

  # Verify Ansible installation
  if ansible --version >/dev/null 2>&1; then
    echo -e "${LGREEN}Ansible installation completed successfully.${NC}"
  else
    echo -e "${LRED} Failed to verify Ansible installation.${NC} ${X_MARK}"
    exit 1
  fi
fi



# Check if Git is already installed
if command -v git >/dev/null 2>&1; then
  echo -e "${LGREEN}Git is already installed.${NC}"
else
  # Update the package list
  sudo apt-get update -qq >/dev/null

  # Install Git
  sudo apt-get install -y git >/dev/null

  # Verify Git installation
  if git --version >/dev/null 2>&1; then
    echo -e "${LGREEN}Git installation completed successfully.${NC}"
  else
    echo -e "${LRED} Failed to verify Git installation.${NC} ${X_MARK}"
    exit 1
  fi
fi
 
# Clone or update the repository
if [[ ! -d "$DOTFILES_DIR" ]]; then
  echo "Cloning repository into $DOTFILES_DIR..."
  if git clone --quiet $GIT_REPO_URL $DOTFILES_DIR >/dev/null 2>&1; then
    echo -e "${LGREEN}Repository cloned successfully.${NC}"
  else
    echo -e "${LRED} Failed to clone repository.${NC} ${X_MARK}"
    exit 1
  fi
else
  echo "Updating existing repository in $DOTFILES_DIR..."
  if git -C $DOTFILES_DIR pull --quiet >/dev/null 2>&1; then
    echo -e "${LGREEN}Repository updated successfully.${NC}"
  else
    echo -e "${LRED} Failed to update repository.${NC} ${X_MARK}"
    exit 1
  fi
fi

# Notify that setup is ready to run playbooks
echo -e "${LGREEN}Setup is Ready to Run Ansible Playbooks.${NC}"

# Run the playbook with optional vault password file
if [[ -f $VAULT_SECRET ]]; then
  if ansible-playbook --vault-password-file $VAULT_SECRET "$DOTFILES_DIR/main.yml" "$@"; then
    echo -e "${LGREEN} Playbooks executed successfully.${NC} ${THUMB_UP}"
  else
    echo -e "${LRED} Failed to execute playbook.${NC} ${X_MARK}"
    exit 1
  fi
else
  if ansible-playbook "$DOTFILES_DIR/main.yml" "$@"; then
    echo -e "${LGREEN} Playbooks executed successfully.${NC} ${THUMB_UP}"
  else
    echo -e "${LRED} Failed to execute playbook.${NC} ${X_MARK}"
    exit 1
  fi
fi

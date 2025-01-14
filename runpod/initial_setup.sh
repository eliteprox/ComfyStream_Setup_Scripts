#!/bin/bash
#Runpod server setup

echo "
========================================
🚀 Starting ComfyUI and ComfyStream setup...
========================================
"

# Create base directories
echo "
----------------------------------------
📁 Creating base directories...
----------------------------------------"
mkdir -p /workspace/ComfyUI
mkdir -p /workspace/comfyRealtime
mkdir -p /workspace/miniconda3

# Clone ComfyUI to both locations
echo "
----------------------------------------
📥 Cloning ComfyUI repositories...
----------------------------------------"
if [ ! -d "/workspace/ComfyUI/.git" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
else
    echo "ComfyUI already exists in /workspace/ComfyUI, skipping clone..."
fi

if [ ! -d "/workspace/comfyRealtime/ComfyUI/.git" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/comfyRealtime/ComfyUI
else
    echo "ComfyUI already exists in /workspace/comfyRealtime/ComfyUI, skipping clone..."
fi

# Clone ComfyStream
echo "
----------------------------------------
📥 Cloning ComfyStream repository...
----------------------------------------"
if [ ! -d "/workspace/comfyRealtime/ComfyStream/.git" ]; then
    git clone https://github.com/yondonfu/comfystream.git /workspace/comfyRealtime/ComfyStream
else
    echo "ComfyStream already exists, skipping clone..."
fi

# Create symlink for models directory
echo "
----------------------------------------
🔗 Setting up models symlink...
----------------------------------------"
if [ ! -L "/workspace/comfyRealtime/ComfyUI/models" ]; then
    rm -rf /workspace/comfyRealtime/ComfyUI/models  # Remove existing models dir
    ln -s /workspace/ComfyUI/models /workspace/comfyRealtime/ComfyUI/models
else
    echo "Models symlink already exists, skipping..."
fi

# Clone ComfyUI-Manager to first install
echo "
----------------------------------------
📥 Installing ComfyUI-Manager...
----------------------------------------"
if [ ! -d "/workspace/ComfyUI/custom_nodes/ComfyUI-Manager/.git" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git /workspace/ComfyUI/custom_nodes/ComfyUI-Manager
else
    echo "ComfyUI-Manager already exists in first installation, skipping clone..."
fi

# Copy ComfyUI-Manager to second install
echo "
----------------------------------------
📋 Copying ComfyUI-Manager to second installation...
----------------------------------------"
if [ ! -d "/workspace/comfyRealtime/ComfyUI/custom_nodes/ComfyUI-Manager" ]; then
    cp -r /workspace/ComfyUI/custom_nodes/ComfyUI-Manager /workspace/comfyRealtime/ComfyUI/custom_nodes/
else
    echo "ComfyUI-Manager already exists in second installation, skipping copy..."
fi

# Clone RealTimeNodes to first install
echo "
----------------------------------------
📥 Installing ComfyUI RealTimeNodes...
----------------------------------------"
if [ ! -d "/workspace/ComfyUI/custom_nodes/ComfyUI_RealTimeNodes/.git" ]; then
    git clone https://github.com/ryanontheinside/ComfyUI_RealTimeNodes.git /workspace/ComfyUI/custom_nodes/ComfyUI_RealTimeNodes
else
    echo "ComfyUI RealTimeNodes already exists in first installation, skipping clone..."
fi

# Copy RealTimeNodes to second install
echo "
----------------------------------------
📋 Copying RealTimeNodes to second installation...
----------------------------------------"
if [ ! -d "/workspace/comfyRealtime/ComfyUI/custom_nodes/ComfyUI_RealTimeNodes" ]; then
    cp -r /workspace/ComfyUI/custom_nodes/ComfyUI_RealTimeNodes /workspace/comfyRealtime/ComfyUI/custom_nodes/
else
    echo "ComfyUI RealTimeNodes already exists in second installation, skipping copy..."
fi

# Download model file
echo "
----------------------------------------
📥 Downloading Kohaku model...
----------------------------------------"
if [ ! -f "/workspace/ComfyUI/models/checkpoints/kohaku-v2.1.safetensors" ]; then
    wget --content-disposition -P /workspace/ComfyUI/models/checkpoints https://huggingface.co/KBlueLeaf/kohaku-v2.1/resolve/main/kohaku-v2.1.safetensors?download=true
else
    echo "Kohaku model already exists, skipping download..."
fi

echo "
----------------------------------------
📥 Downloading Turbo model...
----------------------------------------"
if [ ! -f "/workspace/ComfyUI/models/checkpoints/sd_xl_turbo_1.0.safetensors" ]; then
    wget --content-disposition -P /workspace/ComfyUI/models/checkpoints https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0.safetensors?download=true
else
    echo "Kohaku model already exists, skipping download..."
fi

# Download and install Miniconda
echo "
----------------------------------------
📥 Downloading and installing Miniconda...
----------------------------------------"
if [ ! -f "/workspace/miniconda3/bin/conda" ]; then
    cd /workspace/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    chmod +x Miniconda3-latest-Linux-x86_64.sh
    ./Miniconda3-latest-Linux-x86_64.sh -b -p /workspace/miniconda3 -f
else
    echo "Miniconda already installed, skipping..."
fi

# Initialize conda in the shell
echo "
----------------------------------------
🐍 Initializing conda...
----------------------------------------"
eval "$(/workspace/miniconda3/bin/conda shell.bash hook)"

# Create conda environments
echo "
----------------------------------------
🌟 Creating conda environments...
----------------------------------------"
if ! conda info --envs | grep -q "comfyui"; then
    conda create -n comfyui python=3.11 -y
else
    echo "comfyui environment already exists, skipping creation..."
fi

if ! conda info --envs | grep -q "comfystream"; then
    conda create -n comfystream python=3.11 -y
else
    echo "comfystream environment already exists, skipping creation..."
fi

# Setup comfystream environment
echo "
----------------------------------------
🔧 Setting up comfystream environment...
----------------------------------------"
echo "🔄 Activating comfystream environment..."
set -x  # Enable debug mode to see each command
conda activate comfystream
RESULT=$?
echo "Activation exit code: $RESULT"
if [ "$CONDA_DEFAULT_ENV" != "comfystream" ]; then
    echo "❌ Failed to activate comfystream environment! Current env: $CONDA_DEFAULT_ENV"
    exit 1
fi
echo "✅ Successfully activated comfystream environment"

pwd  # Print current directory
cd /workspace/comfyRealtime/ComfyStream
echo "Current directory: $(pwd)"

echo "📦 Installing ComfyStream package..."
pip install . 
PIP_RESULT=$?
echo "Pip install exit code: $PIP_RESULT"

echo "📦 Installing ComfyStream requirements..."
pip install -r requirements.txt
PIP_REQ_RESULT=$?
echo "Pip requirements install exit code: $PIP_REQ_RESULT"

echo "🔧 Running ComfyStream install script..."
python install.py --workspace /workspace/comfyRealtime/ComfyUI
INSTALL_RESULT=$?
echo "Install script exit code: $INSTALL_RESULT"

# Copy tensor utils to ComfyUI custom nodes
echo "
----------------------------------------
📋 Copying tensor utils...
----------------------------------------"
if [ ! -d "../ComfyUI/custom_nodes/tensor_utils" ]; then
    cp -r nodes/tensor_utils ../ComfyUI/custom_nodes/
else
    echo "Tensor utils already exist in custom_nodes, skipping copy..."
fi

# Return to base environment
echo "🔄 Deactivating comfystream environment..."
conda deactivate
echo "✅ Successfully deactivated comfystream environment"
echo "✅ Completed comfystream environment setup"
set +x  # Disable debug mode

# Copy tensor utils to ComfyUI custom nodes
echo "
----------------------------------------
📋 Copying tensor utils...
----------------------------------------"
if [ ! -d "../ComfyUI/custom_nodes/tensor_utils" ]; then
    cp -r nodes/tensor_utils ../ComfyUI/custom_nodes/
else
    echo "Tensor utils already exist in custom_nodes, skipping copy..."
fi

# Return to base environment
echo "🔄 Deactivating comfystream environment..."
conda deactivate
echo "✅ Successfully deactivated comfystream environment"
echo "✅ Completed comfystream environment setup"

# Setup comfyui environment
echo "
----------------------------------------
🔧 Setting up comfyui environment...
----------------------------------------"
echo "🔄 Activating comfyui environment..."
conda activate comfyui
if [ "$CONDA_DEFAULT_ENV" != "comfyui" ]; then
    echo "❌ Failed to activate comfyui environment! Exiting..."
    exit 1
fi
echo "✅ Successfully activated comfyui environment"

cd /workspace/comfyRealtime/ComfyUI
echo "📦 Installing ComfyUI requirements..."
pip install -r requirements.txt
cd custom_nodes/ComfyUI-Manager
echo "📦 Installing ComfyUI-Manager requirements..."
pip install -r requirements.txt

cd /workspace/ComfyUI/custom_nodes/ComfyUI_RealTimeNodes
echo "📦 Installing ComfyUI_RealTimeNodes requirements..."
pip install -r requirements.txt

# Return to base environment
echo "🔄 Deactivating comfyui environment..."
conda deactivate
echo "✅ Successfully deactivated comfyui environment"

#!/bin/bash
#Runpod server setup with support for single and multiple installations

# Default values
single=false
condapath="/workspace/miniconda3"
skip_conda=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --single) single=true ;;
        --condapath) condapath="$2"; shift ;;
        --skip-conda) skip_conda=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

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
mkdir -p /workspace/comfyRealtime
mkdir -p "$condapath"

# Clone ComfyUI
echo "
----------------------------------------
📥 Cloning ComfyUI repository...
----------------------------------------"
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

# Clone ComfyUI-Manager
echo "
----------------------------------------
📥 Installing ComfyUI-Manager...
----------------------------------------"
if [ ! -d "/workspace/comfyRealtime/ComfyUI/custom_nodes/ComfyUI-Manager/.git" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git /workspace/comfyRealtime/ComfyUI/custom_nodes/ComfyUI-Manager
else
    echo "ComfyUI-Manager already exists, skipping clone..."
fi

# Download model files
echo "
----------------------------------------
📥 Downloading Kohaku model...
----------------------------------------"
if [ ! -f "/workspace/comfyRealtime/ComfyUI/models/checkpoints/kohaku-v2.1.safetensors" ]; then
    wget --content-disposition -P /workspace/comfyRealtime/ComfyUI/models/checkpoints https://huggingface.co/KBlueLeaf/kohaku-v2.1/resolve/main/kohaku-v2.1.safetensors?download=true
else
    echo "Kohaku model already exists, skipping download..."
fi

echo "
----------------------------------------
📥 Downloading Turbo model...
----------------------------------------"
if [ ! -f "/workspace/comfyRealtime/ComfyUI/models/checkpoints/sd_xl_turbo_1.0.safetensors" ]; then
    wget --content-disposition -P /workspace/comfyRealtime/ComfyUI/models/checkpoints https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0.safetensors?download=true
else
    echo "Turbo model already exists, skipping download..."
fi

# Download and install Miniconda if condapath is default and skip_conda is false
if [ "$condapath" == "/workspace/miniconda3" ] && [ "$skip_conda" = false ]; then
    echo "
    ----------------------------------------
    📥 Downloading and installing Miniconda...
    ----------------------------------------"
    if [ ! -f "$condapath/bin/conda" ]; then
        cd "$condapath"
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
        chmod +x Miniconda3-latest-Linux-x86_64.sh
        ./Miniconda3-latest-Linux-x86_64.sh -b -p "$condapath" -f
    else
        echo "Miniconda already installed, skipping..."
    fi
fi

# Initialize conda in the shell
echo "
----------------------------------------
🐍 Initializing conda...
----------------------------------------"
eval "$($condapath/bin/conda shell.bash hook)"

# Create conda environment
echo "
----------------------------------------
🌟 Creating conda environment...
----------------------------------------"
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

cd /workspace/comfyRealtime/ComfyStream
echo "Current directory: $(pwd)"

echo "📦 Installing ComfyStream package..."
pip install .
pip install -r requirements.txt

echo "🔧 Running ComfyStream install script..."
python install.py --workspace /workspace/comfyRealtime/ComfyUI

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

# Install ComfyUI requirements
echo "
----------------------------------------
📦 Installing ComfyUI requirements...
----------------------------------------"
cd ../ComfyUI
pip install -r requirements.txt
cd custom_nodes/ComfyUI-Manager
pip install -r requirements.txt

# Return to base environment
echo "🔄 Deactivating comfystream environment..."
conda deactivate
echo "✅ Successfully deactivated comfystream environment"
echo "✅ Setup complete!"
set +x  # Disable debug mode

# If not single, perform additional setup
if [ "$single" = false ]; then
    echo "
    ----------------------------------------
    📥 Cloning ComfyUI repositories...
    ----------------------------------------"
    if [ ! -d "/workspace/ComfyUI/.git" ]; then
        git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
    else
        echo "ComfyUI already exists in /workspace/ComfyUI, skipping clone..."
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

    # Create conda environment for comfyui
    echo "
    ----------------------------------------
    🌟 Creating conda environment for comfyui...
    ----------------------------------------"
    if ! conda info --envs | grep -q "comfyui"; then
        conda create -n comfyui python=3.11 -y
    else
        echo "comfyui environment already exists, skipping creation..."
    fi

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

    cd /workspace/ComfyUI
    echo "📦 Installing ComfyUI requirements..."
    pip install -r requirements.txt
    cd custom_nodes/ComfyUI-Manager
    echo "📦 Installing ComfyUI-Manager requirements..."
    pip install -r requirements.txt

    # Return to base environment
    echo "🔄 Deactivating comfyui environment..."
    conda deactivate
    echo "✅ Successfully deactivated comfyui environment"
fi

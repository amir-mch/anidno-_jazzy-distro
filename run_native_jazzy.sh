#!/usr/bin/env bash
# ==============================================================================
# Robotics & ROS 2 Essentials (ROS 2 Jazzy + Gazebo Harmonic)
# Unified Native Setup & Launch Script (No Docker Required)
# ==============================================================================
set -euo pipefail

# --- Configuration ---
ROS_DISTRO="jazzy"
WS_DIR="${ANDINO_WS:-$HOME/andino_ws}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_PACKAGES_DIR="${SCRIPT_DIR}/packages"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTION]

Unified native installer & launcher for Robotics & ROS 2 Essentials (ROS 2 Jazzy).

Options:
  (no option)     Full setup (if needed), build workspace, and launch Gazebo + RViz2
  --setup-only    Install dependencies, clone/build workspace, and configure ~/.bashrc only
  --launch        Launch Gazebo + RViz2 simulation directly (assumes already built)
  --slam          Launch slam_toolbox online async node (run in a 2nd terminal)
  --teleop        Launch teleop_twist_keyboard (run in a 3rd terminal)
  --nav2          Launch Gazebo + RViz2 with Nav2 autonomous navigation enabled
  -h, --help      Show this help message
EOF
}

# --- Parse Arguments ---
MODE="all"
if [[ $# -gt 0 ]]; then
  case "$1" in
    --setup-only) MODE="setup" ;;
    --launch)     MODE="launch" ;;
    --slam)       MODE="slam" ;;
    --teleop)     MODE="teleop" ;;
    --nav2)       MODE="nav2" ;;
    -h|--help)    usage; exit 0 ;;
    *)            error "Unknown option: $1. Use --help for usage." ;;
  esac
fi

# --- Helper: Source ROS 2 & Workspace ---
source_env() {
  if [[ ! -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]]; then
    error "ROS 2 ${ROS_DISTRO} not found at /opt/ros/${ROS_DISTRO}. Run without --launch first."
  fi
  # Disable nounset temporarily because ROS setup.bash references unset variables
  set +u
  source "/opt/ros/${ROS_DISTRO}/setup.bash"
  if [[ -f "${WS_DIR}/install/setup.bash" ]]; then
    source "${WS_DIR}/install/setup.bash"
  fi
  set -u
}

# --- Helper: Ensure ROS 2 Jazzy is Installed ---
ensure_ros2_jazzy() {
  if [[ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]]; then
    ok "ROS 2 ${ROS_DISTRO} is already installed."
    return
  fi

  info "ROS 2 ${ROS_DISTRO} not found. Installing ROS 2 ${ROS_DISTRO} desktop..."
  sudo apt-get update
  sudo apt-get install -y software-properties-common curl gnupg lsb-release
  sudo add-apt-repository -y universe

  sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") main" \
    | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y "ros-${ROS_DISTRO}-desktop-full"
  ok "ROS 2 ${ROS_DISTRO} installed."
}

# --- Full Setup & Build ---
run_setup() {
  info "Checking Ubuntu version..."
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "${VERSION_CODENAME:-}" != "noble" ]]; then
      warn "Detected Ubuntu ${VERSION_ID:-unknown} (${VERSION_CODENAME:-unknown}). ROS 2 Jazzy officially targets Ubuntu 24.04 (noble)."
    else
      ok "Ubuntu 24.04 (noble) detected."
    fi
  fi

  ensure_ros2_jazzy

  info "Installing required ROS 2 Jazzy & Gazebo Harmonic packages..."
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends \
    git \
    curl \
    python3-rosdep \
    python3-colcon-common-extensions \
    "ros-${ROS_DISTRO}-ros-gz" \
    "ros-${ROS_DISTRO}-navigation2" \
    "ros-${ROS_DISTRO}-nav2-bringup" \
    "ros-${ROS_DISTRO}-slam-toolbox" \
    "ros-${ROS_DISTRO}-turtle-nest" \
    "ros-${ROS_DISTRO}-xacro" \
    "ros-${ROS_DISTRO}-joint-state-publisher-gui" \
    "ros-${ROS_DISTRO}-teleop-twist-keyboard" \
    "ros-${ROS_DISTRO}-tf-transformations"
  ok "All apt dependencies installed."

  info "Preparing workspace at ${WS_DIR}..."
  mkdir -p "${WS_DIR}/src"

  # Copy custom course packages (create_plan_msgs, custom_nav2_planner)
  if [[ -d "${REPO_PACKAGES_DIR}" ]]; then
    cp -ru "${REPO_PACKAGES_DIR}/." "${WS_DIR}/src/"
    ok "Copied custom course packages to ${WS_DIR}/src/"
  else
    warn "Packages directory not found at ${REPO_PACKAGES_DIR}; skipping copy."
  fi

  # Clone andino_gz (jazzy branch)
  if [[ ! -d "${WS_DIR}/src/andino_gz" ]]; then
    info "Cloning Ekumen-OS/andino_gz (branch: jazzy)..."
    git clone -b jazzy https://github.com/Ekumen-OS/andino_gz.git "${WS_DIR}/src/andino_gz"
  else
    ok "andino_gz already exists in ${WS_DIR}/src/andino_gz."
  fi

  # Clone andino_description and andino_slam from Ekumen-OS/andino (main branch)
  if [[ ! -d "${WS_DIR}/src/andino_description" || ! -d "${WS_DIR}/src/andino_slam" ]]; then
    info "Cloning andino_description and andino_slam from Ekumen-OS/andino..."
    TMP_ANDINO="$(mktemp -d)"
    git clone --depth 1 -b main https://github.com/Ekumen-OS/andino.git "${TMP_ANDINO}/andino"
    [[ -d "${WS_DIR}/src/andino_description" ]] || mv "${TMP_ANDINO}/andino/andino_description" "${WS_DIR}/src/"
    [[ -d "${WS_DIR}/src/andino_slam" ]]        || mv "${TMP_ANDINO}/andino/andino_slam" "${WS_DIR}/src/"
    rm -rf "${TMP_ANDINO}"
  else
    ok "andino_description and andino_slam already exist."
  fi

  info "Running rosdep..."
  if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
    sudo rosdep init || true
  fi
  rosdep update
  source_env
  cd "${WS_DIR}"
  rosdep install --from-paths src --ignore-src -r -y --rosdistro "${ROS_DISTRO}"

  info "Building workspace with colcon..."
  colcon build --symlink-install
  ok "Workspace built successfully!"

  # Configure ~/.bashrc idempotently
  local ros_line="source /opt/ros/${ROS_DISTRO}/setup.bash"
  local ws_line="source ${WS_DIR}/install/setup.bash"
  grep -qxF "${ros_line}" "$HOME/.bashrc" || echo "${ros_line}" >> "$HOME/.bashrc"
  grep -qxF "${ws_line}"  "$HOME/.bashrc" || echo "${ws_line}"  >> "$HOME/.bashrc"
  ok "Updated ~/.bashrc with ROS 2 ${ROS_DISTRO} and ${WS_DIR} setup."
}

# --- Main Execution ---
case "${MODE}" in
  setup)
    run_setup
    ok "Setup complete! Run './$(basename "$0") --launch' to start the simulation."
    ;;
  all)
    run_setup
    source_env
    info "Launching Gazebo Harmonic & RViz2 simulation..."
    info "Tip: Click Play (▶) in Gazebo, and run './$(basename "$0") --slam' in another terminal."
    exec ros2 launch andino_gz andino_gz.launch.py
    ;;
  launch)
    source_env
    info "Launching Gazebo Harmonic & RViz2 simulation..."
    exec ros2 launch andino_gz andino_gz.launch.py
    ;;
  slam)
    source_env
    info "Launching slam_toolbox online async..."
    exec ros2 launch andino_gz slam_toolbox_online_async.launch.py
    ;;
  teleop)
    source_env
    info "Launching teleop_twist_keyboard..."
    exec ros2 run teleop_twist_keyboard teleop_twist_keyboard
    ;;
  nav2)
    source_env
    info "Launching Gazebo Harmonic & RViz2 with Nav2 enabled..."
    exec ros2 launch andino_gz andino_gz.launch.py nav2:=True
    ;;
esac

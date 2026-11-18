<img src="images/course_banner.png" alt="Robotics & ROS 2 Essentials"/>

# Robotics & ROS 2 Essentials — ROS 2 Jazzy Edition

This repository is the **ROS 2 Jazzy Jalisco** & **Gazebo Harmonic** port of the **Robotics & ROS 2 Essentials** coursework (originally based on ROS 2 Humble / Gazebo Fortress), adapted from [kaveh-hooshmandi/robotics_essentials_ros2](https://github.com/kaveh-hooshmandi/robotics_essentials_ros2).

It provides hands-on robotics exercises using the [Andino robot](https://github.com/Ekumen-OS/andino_gz/tree/jazzy) from Ekumen, covering ROS 2 fundamentals, Gazebo simulation, SLAM mapping (`slam_toolbox`), autonomous navigation (`Nav2`), wheel odometry, and custom path planning plugins.

<img src="images/autonomous_navigation.gif" alt="Autonomous Navigation Demo" width="1200"/>

---

## What Changed in the ROS 2 Jazzy Migration?

- **Base OS & Distro:** Migrated from Ubuntu 22.04 / ROS 2 Humble to **Ubuntu 24.04 (Noble) / ROS 2 Jazzy**.
- **Simulator:** Upgraded from Ignition Gazebo Fortress to **Gazebo Harmonic (`gz-harmonic` / `gz-sim8`)** with `ros-jazzy-ros-gz`.
- **Andino Packages:** Uses the `jazzy` branch of `Ekumen-OS/andino_gz` and builds `andino_description` and `andino_slam` from `Ekumen-OS/andino` (`main`).
- **Custom Nav2 Planner (`packages/custom_nav2_planner`):**
  - Updated C++ standard to **C++17**.
  - Updated `CustomPlanner::createPlan(...)` signature to match the ROS 2 Jazzy `nav2_core::GlobalPlanner` API (including `std::function<bool()> cancel_checker`).
- **Guides Included:** Added [`GUIDE.md`](GUIDE.md) and [`Robotics_ROS2_SLAM_Guide.pdf`](Robotics_ROS2_SLAM_Guide.pdf) with complete step-by-step commands and troubleshooting.

---

## Option 1: Run Natively on Ubuntu 24.04 (Without Docker)

### Quick Automated Setup & Launch (Recommended)
Use the included unified script [`run_native_jazzy.sh`](run_native_jazzy.sh) to automatically install ROS 2 Jazzy (if missing), all required Gazebo Harmonic / Nav2 / SLAM packages, prepare and build `~/andino_ws`, configure `~/.bashrc`, and launch the simulation:

```bash
git clone https://github.com/amir-mch/anidno-_jazzy-distro.git
cd anidno-_jazzy-distro
chmod +x run_native_jazzy.sh
./run_native_jazzy.sh
```

#### Available Script Flags
| Command | Description |
| :--- | :--- |
| `./run_native_jazzy.sh` | Full setup (if needed), build `~/andino_ws`, and launch Gazebo + RViz2 |
| `./run_native_jazzy.sh --setup-only` | Install dependencies, build workspace, and configure `~/.bashrc` without launching |
| `./run_native_jazzy.sh --launch` | Launch Gazebo + RViz2 directly (assumes workspace is already built) |
| `./run_native_jazzy.sh --slam` | Launch `slam_toolbox` online async node (run in a 2nd terminal) |
| `./run_native_jazzy.sh --teleop` | Launch `teleop_twist_keyboard` (run in a 3rd terminal) |
| `./run_native_jazzy.sh --nav2` | Launch Gazebo + RViz2 with Nav2 autonomous navigation enabled |
| `./run_native_jazzy.sh --help` | Show usage help |

<details>
<summary>Manual Native Setup Steps (if you prefer running commands one by one)</summary>

### 1. Install Required Packages
```bash
sudo apt update && sudo apt install -y \
  ros-jazzy-ros-gz \
  ros-jazzy-navigation2 \
  ros-jazzy-nav2-bringup \
  ros-jazzy-slam-toolbox \
  ros-jazzy-turtle-nest \
  ros-jazzy-xacro \
  ros-jazzy-joint-state-publisher-gui \
  ros-jazzy-teleop-twist-keyboard \
  ros-jazzy-tf-transformations
```

### 2. Create Workspace & Clone Dependencies
```bash
mkdir -p ~/andino_ws/src
cd ~/andino_ws/src

# Clone this repository (or copy packages/)
git clone https://github.com/amir-mch/anidno-_jazzy-distro.git
cp -r anidno-_jazzy-distro/packages/* .
rm -rf anidno-_jazzy-distro

# Clone Andino Jazzy simulation & description/slam packages
git clone -b jazzy https://github.com/Ekumen-OS/andino_gz.git
git clone --depth 1 -b main https://github.com/Ekumen-OS/andino.git /tmp/andino
mv /tmp/andino/andino_description /tmp/andino/andino_slam .
rm -rf /tmp/andino
```

### 3. Build the Workspace
```bash
source /opt/ros/jazzy/setup.bash
cd ~/andino_ws
rosdep update
rosdep install --from-paths src --ignore-src -r -y --rosdistro jazzy
colcon build --symlink-install
source install/setup.bash
```
</details>

---

## Option 2: Run with Docker (Any x64 Ubuntu Host)

### 1. Clone & Build
```bash
git clone https://github.com/amir-mch/anidno-_jazzy-distro.git
cd anidno-_jazzy-distro/docker
xhost +
docker compose up -d --build
```

### 2. Enter the Container
```bash
docker exec -it robotics_essentials_ros2 bash
```

---

## Quick Start: Simulation, SLAM & Navigation

Once your environment (Native or Docker) is ready:

1. **Terminal 1 — Launch Gazebo & RViz2:**
   ```bash
   ros2 launch andino_gz andino_gz.launch.py
   ```
   > **Important:** Click the orange **Play (▶)** button in the bottom-left corner of Gazebo (or press `Spacebar`) to start `/clock`.

2. **Terminal 2 — Launch Online SLAM:**
   ```bash
   ros2 launch andino_gz slam_toolbox_online_async.launch.py
   ```
   *(In RViz, set `Fixed Frame` to `map`, add the `/map` display, and set its QoS Durability Policy to `Transient Local`.)*

3. **Terminal 3 — Drive the Robot:**
   ```bash
   ros2 run teleop_twist_keyboard teleop_twist_keyboard
   ```

4. **Save the Map:**
   ```bash
   ros2 run nav2_map_server map_saver_cli --free 0.15 --fmt png -f ~/andino_map
   ```

5. **Autonomous Navigation (Nav2):**
   ```bash
   ros2 launch andino_gz andino_gz.launch.py nav2:=True
   ```

For more details, see [`GUIDE.md`](GUIDE.md) or [`Robotics_ROS2_SLAM_Guide.pdf`](Robotics_ROS2_SLAM_Guide.pdf).

---

## Course Exercises

0. [Setup](0-setup) — Environment, Docker, and system setup
1. [ROS 2 Introduction](1-ros_2_introduction) — Gazebo, RViz, topics, and TF frames
2. [SLAM and Navigation Demo](2-slam_and_navigation_demo) — `slam_toolbox`, Nav2, and ROS 2 services
3. [Create your first ROS 2 package](3-create_ros_2_package) — Python packages, `colcon build`, and nodes
4. [Robot Odometry](4-robot_odometry) — Differential drive kinematics and `/odom` publishing in Python
5. [Path Planning](5-path_planning) — Nav2 parameters and custom global planner plugin

---

## Lecture Slides

1. [Theme 1: Robotics in society](lecture_slides/theme_1_robotics_in_society)
2. [Theme 2: Robotics applications](lecture_slides/theme_2_robotics_applications)
3. [Theme 3: Robot control theory](lecture_slides/theme_3_robot_control_theory)
4. [Theme 4: Navigation](lecture_slides/theme_4_navigation)
5. [Theme 5: Robotics & AI](lecture_slides/theme_5_robotics_ai)
6. [Theme 6: XR applications in Robotics](lecture_slides/theme_6_xr_applications_robotics)

---

## Acknowledgements & Original Contributors

- **Arak University of Technology Edition:** Maintained by [Dr. Kaveh Hooshmandi](https://github.com/kaveh-hooshmandi).
- **Original Course Materials:** Developed by [Janne Karttunen](https://github.com/Jannkar) and [George-Cosmin Porusniuc](https://github.com/geoporus1) in collaboration with the University of Eastern Finland (taught by Dr. Ilkka Jormanainen).

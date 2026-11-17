# Complete Guide: Robotics & ROS 2 Essentials (Andino Simulation & SLAM)

This guide provides a comprehensive, step-by-step reference for launching the Docker container, running the Gazebo simulation, performing SLAM mapping, controlling the robot, exporting the map, and running autonomous navigation with Nav2.

---

## Table of Contents
1. [Prerequisites & Display Permissions](#1-prerequisites--display-permissions)
2. [Starting the Docker Container](#2-starting-the-docker-container)
3. [Launching the Simulation (Gazebo & RViz)](#3-launching-the-simulation-gazebo--rviz)
4. [Running Online SLAM (Mapping)](#4-running-online-slam-mapping)
5. [Configuring RViz for SLAM](#5-configuring-rviz-for-slam)
6. [Teleoperation (Driving the Robot)](#6-teleoperation-driving-the-robot)
7. [Saving and Exporting the Map](#7-saving-and-exporting-the-map)
8. [Autonomous Navigation with Nav2](#8-autonomous-navigation-with-nav2)
9. [Stopping the Environment](#9-stopping-the-environment)
10. [Troubleshooting & Common Pitfalls](#10-troubleshooting--common-pitfalls)

---

## 1. Prerequisites & Display Permissions

Before running graphical applications (Gazebo, RViz) from inside Docker, grant local display access to X11 on your host system:

```bash
# Run on the HOST machine (terminal prompt: user@host$)
xhost +
```
> **Note:** Run this command once every time you reboot your computer.

---

## 2. Starting the Docker Container

The course environment is containerized. Start the container in detached background mode:

```bash
# Run on the HOST machine
cd ~/Desktop/robotics_essentials_ros2/docker
docker compose up -d
```

Verify that the container is running:
```bash
docker ps
```
You should see `robotics_essentials_ros2` with status `Up`.

---

## 3. Launching the Simulation (Gazebo & RViz)

### Terminal 1: Launch Gazebo & RViz
Open a terminal, enter the container, and start the simulation:

```bash
# Run on the HOST machine to enter container
docker exec -it robotics_essentials_ros2 bash

# Run INSIDE container (prompt: user@amir$)
ros2 launch andino_gz andino_gz.launch.py
```

### Important: Unpause Gazebo
By default, Gazebo starts in a paused state.
- In the **Gazebo GUI**, click the orange **Play (▶️)** button in the bottom-left corner (or press the **Spacebar**).
- Without unpausing, the simulation clock (`/clock`) remains at 0, and sensor data (LiDAR, odometry) will not update.

---

## 4. Running Online SLAM (Mapping)

### Terminal 2: Launch `slam_toolbox`
Open a second terminal, enter the container, and launch the SLAM node:

```bash
# Run on the HOST machine
docker exec -it robotics_essentials_ros2 bash

# Run INSIDE container
ros2 launch andino_gz slam_toolbox_online_async.launch.py
```

Expected output:
```text
[async_slam_toolbox_node-1] Using solver plugin solver_plugins::CeresSolver
[async_slam_toolbox_node-1] CeresSolver: Using SCHUR_JACOBI preconditioner.
[async_slam_toolbox_node-1] Registering sensor: [Custom Described Lidar]
```

---

## 5. Configuring RViz for SLAM

To see the generated map in real time in RViz:

1. **Set Fixed Frame:**
   - In the top-left **Displays** panel under **Global Options**, change `Fixed Frame` from `base_footprint` to:
     ```text
     map
     ```
2. **Add Map Display:**
   - At the bottom of the Displays panel, click **Add**.
   - Switch to the **By topic** tab.
   - Expand the **`/map`** topic, select **Map**, and click **OK**.
3. **QoS Durability Setting:**
   - In the Map display properties, expand the **Topic** section.
   - Ensure **Durability Policy** is set to **`Transient Local`** (matches the `slam_toolbox` publisher QoS).
4. **Adjust View Distance:**
   - In the **Views** panel (or using the mouse scroll wheel), zoom out so the entire warehouse area is visible.

---

## 6. Teleoperation (Driving the Robot)

### Terminal 3: Keyboard Teleop
Open a third terminal to drive the robot:

```bash
# Run on the HOST machine
docker exec -it robotics_essentials_ros2 bash

# Run INSIDE container
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

### Keyboard Controls:
- `i` : Drive forward
- `,` : Drive backward
- `j` : Turn left
- `l` : Turn right
- `k` : Stop

> **Tip:** Drive slowly through all aisles and rooms. `slam_toolbox` requires at least `0.5m` of linear movement or `30°` of rotation before inserting new keyframes into the map.

---

## 7. Saving and Exporting the Map

Once the environment has been fully explored and mapped:

### Option A: Save Directly into the Mounted Shared Workspace (Recommended)
Because `/home/user/exercises_ws/src` inside Docker is mounted to `~/exercises_ws/src` on your host machine, save directly there:

```bash
# Run INSIDE container
ros2 run nav2_map_server map_saver_cli --free 0.15 --fmt png -f /home/user/exercises_ws/src/andino_map
```
The files `andino_map.png` and `andino_map.yaml` will immediately appear on your host system at `~/exercises_ws/src/`.

### Option B: Save to Home Directory and Copy to Host
1. Save inside container:
   ```bash
   # Run INSIDE container
   ros2 run nav2_map_server map_saver_cli --free 0.15 --fmt png -f $HOME/andino_map
   ```
2. Copy to host Desktop:
   ```bash
   # Run on HOST machine (NOT inside container!)
   docker cp robotics_essentials_ros2:/home/user/andino_map.png ~/Desktop/
   docker cp robotics_essentials_ros2:/home/user/andino_map.yaml ~/Desktop/
   ```

---

## 8. Autonomous Navigation with Nav2

Once your map is saved, you can let the robot navigate autonomously.

1. **Stop previous nodes:** Press `Ctrl + C` in Terminal 1 (simulation) and Terminal 2 (slam_toolbox).
2. **Launch Simulation with Nav2 enabled:**
   ```bash
   # Run INSIDE container
   ros2 launch andino_gz andino_gz.launch.py nav2:=True
   ```
3. **(Optional) Load your custom map:**
   ```bash
   # Run INSIDE container
   ros2 service call /map_server/load_map nav2_msgs/srv/LoadMap "{map_url: /home/user/exercises_ws/src/andino_map.yaml}"
   ```
4. **Set 2D Pose Estimate:**
   - In RViz, click the **2D Pose Estimate** button in the top toolbar.
   - Click and drag on the map where the robot is currently positioned to align the AMCL particle filter.
5. **Set Navigation Goal:**
   - Click **Nav2 Goal** in the top toolbar.
   - Click and drag on any free area on the map to specify the goal position and orientation.
   - Nav2 will calculate the global path (straight/curved line) and drive the robot to the goal while dynamically avoiding obstacles.

---

## 9. Stopping the Environment

When you are finished working:
1. Press `Ctrl + C` in all active terminal tabs.
2. On your host terminal, shut down the Docker container:
   ```bash
   # Run on the HOST machine
   cd ~/Desktop/robotics_essentials_ros2/docker
   docker compose down
   ```

---

## 10. Troubleshooting & Common Pitfalls

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| `bash: docker: command not found` | Attempting to run `docker` commands inside the container terminal. | Run `exit` to return to your host terminal (`amir@amir$`) before running `docker` commands. |
| `slam_toolbox` stops at `CeresSolver: Using SCHUR_JACOBI...` | Gazebo is paused; simulation time (`/clock`) is not advancing. | Click the orange **Play** button in the bottom-left of Gazebo or press `Spacebar`. |
| RViz says `No map received` (yellow status) | QoS mismatch between publisher (`Transient Local`) and RViz default (`Volatile`). | Under Map display properties, change `Durability Policy` to `Transient Local`. |
| Map does not update while driving | Moving less than `0.5m` or dragging the robot with the mouse. | Drive continuously with `teleop_twist_keyboard` for more than 0.5 meters. Do not mouse-drag the robot in 3D view. |
| Cannot open GUI (`cannot connect to X server`) | X11 display permissions missing. | Run `xhost +` on the host machine before starting the container. |

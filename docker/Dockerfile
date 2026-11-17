FROM osrf/ros:jazzy-desktop-full

# Setup user for GUI to work without xhost (Ubuntu 24.04 ships with 'ubuntu' at UID/GID 1000)
ARG UNAME=user
ARG UID=1000
ARG GID=1000
RUN if id -u ubuntu >/dev/null 2>&1; then userdel -r ubuntu; fi && \
    groupadd -g ${GID} -o ${UNAME} && \
    useradd -m -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME} && \
    usermod -aG sudo ${UNAME} && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER ${UNAME}

# Create a custom ros2 overlay workspace and workspace for exercises
ENV ROS2_WS=/home/user/ros2_ws
RUN mkdir -p ${ROS2_WS}/src
ENV EXERCISES_WS=/home/user/exercises_ws
RUN mkdir -p $EXERCISES_WS/src

# Disable terminal interaction for apt
ENV DEBIAN_FRONTEND=noninteractive

# Make default shell in Dockerfile bash instead of sh
SHELL ["/bin/bash", "-c"]

# Copy andino requirement files and install dependencies
COPY docker/andino_requirements.txt .
RUN sudo apt-get update && sudo apt-get install --no-install-recommends -y $(cat andino_requirements.txt) && \
    sudo rm andino_requirements.txt && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

# Install Gazebo Harmonic
RUN sudo curl -fsSL https://packages.osrfoundation.org/gazebo.gpg -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
    sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends gz-harmonic && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

# Install ROS 2 Jazzy dependencies
RUN sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
    ros-$ROS_DISTRO-navigation2 \
    ros-$ROS_DISTRO-turtle-nest \
    ros-$ROS_DISTRO-tf-transformations \
    ros-$ROS_DISTRO-ros-gz \
    ros-$ROS_DISTRO-slam-toolbox \
    ros-$ROS_DISTRO-teleop-twist-keyboard \
    && sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

# Install andino_gz (jazzy), andino_description, andino_slam, and custom packages
COPY ./packages/ ${ROS2_WS}/src
RUN cd ${ROS2_WS}/src && \
    git clone --depth 1 https://github.com/Ekumen-OS/andino_gz.git -b jazzy && \
    git clone --depth 1 https://github.com/Ekumen-OS/andino.git -b main /tmp/andino && \
    mv /tmp/andino/andino_description /tmp/andino/andino_slam ${ROS2_WS}/src/ && \
    rm -rf /tmp/andino && \
    sudo apt-get update && \
    . /opt/ros/${ROS_DISTRO}/setup.bash && \
    cd ${ROS2_WS} && \
    rosdep update && rosdep install --from-paths src --ignore-src -r -y --rosdistro ${ROS_DISTRO} && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* && \
    colcon build --symlink-install

# Build exercises_ws
RUN cd ${EXERCISES_WS}/src && \
    sudo apt-get update && \
    . /opt/ros/${ROS_DISTRO}/setup.bash && \
    cd ${EXERCISES_WS} && \
    rosdep update && rosdep install --from-paths src --ignore-src -r -y --rosdistro ${ROS_DISTRO} && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* && \
    colcon build --symlink-install

# Source ROS workspace automatically when new terminal is opened
RUN echo ". /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc && \
    echo ". ${EXERCISES_WS}/install/setup.bash" >> ~/.bashrc && \
    echo ". ${ROS2_WS}/install/setup.bash" >> ~/.bashrc

WORKDIR /home/user/exercises_ws

# Source ROS in the main terminal
COPY docker/ros_entrypoint.sh /ros_entrypoint.sh

ENTRYPOINT ["/ros_entrypoint.sh"]

CMD ["bash"]

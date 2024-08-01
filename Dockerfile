FROM osrf/ros:humble-simulation

# Install basic utilities
RUN apt-get update -yq \
 && apt-get install -yq \
    sudo \
    vim

# Set the Vim as Git editor
RUN git config --global core.editor vim

# User setup
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ARG ROS_WORKSPACE_NAME=amr_ws
ENV ROS_WORKSPACE_NAME=${ROS_WORKSPACE_NAME}

# Create a non-root user
RUN groupadd --gid $USER_GID ${USERNAME} \
 && useradd -s /bin/bash --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
 && mkdir /home/${USERNAME}/.config \
 && chown $USER_UID:$USER_GID /home/${USERNAME}/.config

# Set up sudo for the non-root user
RUN echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
 && chmod 0440 /etc/sudoers.d/${USERNAME}

COPY entrypoint.sh /
COPY --chown=${USERNAME}:${USERNAME} src /home/${USERNAME}/${ROS_WORKSPACE_NAME}/src

USER ros
WORKDIR /home/${USERNAME}/${ROS_WORKSPACE_NAME}

# install ROS dependencies
RUN sudo apt-get update -yq \
 && rosdep update \
 && rosdep install --from-paths src --ignore-src -r -y

# build workspace
SHELL [ "/bin/bash", "-c" ]
RUN source /opt/ros/humble/setup.bash \
 && colcon build \
 && source install/setup.bash

ENTRYPOINT [ "/bin/bash", "entrypoint.sh" ]
CMD [ "bash" ]
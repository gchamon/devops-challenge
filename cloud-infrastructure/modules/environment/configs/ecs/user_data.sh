#!/bin/bash

# awslogs default config file with placeholders
cat > ~/ecs.conf <<- 'EOF'
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/dmesg]
file = /var/log/dmesg
log_group_name = /var/log/dmesg
log_stream_name = {cluster}/{container_instance_id}

[/var/log/messages]
file = /var/log/messages
log_group_name = /var/log/messages
log_stream_name = {cluster}/{container_instance_id}
datetime_format = %b %d %H:%M:%S

[/var/log/docker]
file = /var/log/docker
log_group_name = /var/log/docker
log_stream_name = {cluster}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%S.%f

[/var/log/ecs/ecs-init.log]
file = /var/log/ecs/ecs-init.log
log_group_name = /var/log/ecs/ecs-init.log
log_stream_name = {cluster}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/ecs-agent.log]
file = /var/log/ecs/ecs-agent.log.*
log_group_name = /var/log/ecs/ecs-agent.log
log_stream_name = {cluster}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/audit.log]
file = /var/log/ecs/audit.log.*
log_group_name = /var/log/ecs/audit.log
log_stream_name = {cluster}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ
EOF

# ECS config
{
  echo "ECS_CLUSTER=${cluster_name}"
  echo "ECS_LOGLEVEL=debug"
  echo "ECS_ENABLE_SPOT_INSTANCE_DRAINING=true"
} >> /etc/ecs/ecs.config

# Configure instance
{
  echo "[$(date)] starting up"

  # replace awslogs config placeholders
  cluster=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .Cluster')
  sudo sed -i -e "s/{cluster}/$cluster/g" ~/ecs.conf

  container_instance_id=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .ContainerInstanceArn' | awk -F/ '{print $2}' )
  sudo sed -i -e "s/{container_instance_id}/$container_instance_id/g" ~/ecs.conf
  sudo mv ~/ecs.conf /etc/awslogs/config/

  region=$(curl 169.254.169.254/latest/meta-data/placement/availability-zone | sed s'/.$//')
  sudo sed -i -e "s/region = us-east-1/region = $region/g" /etc/awslogs/awscli.conf

  # enable logs
  sudo systemctl enable awslogsd
  sudo systemctl start awslogsd --no-block

  echo "Done"
} &>> /var/log/startup.log

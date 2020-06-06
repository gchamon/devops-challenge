#!/bin/bash
# ECS config
{
  echo "ECS_CLUSTER=${cluster_name}"
  echo "ECS_LOGLEVEL=debug"
  echo "ECS_ENABLE_SPOT_INSTANCE_DRAINING=true"
} >> /etc/ecs/ecs.config

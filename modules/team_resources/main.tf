data "ibm_resource_group" "clusterResourceGroup" {
    name = "${var.environment}-env"
}

data "ibm_resource_group" "vpcResourceGroup" {
    name = "vpc-${var.environment}"
}

data "ibm_resource_group" "sharedResourceGroup" {
    name = "account-shared-services"
}

data "ibm_resource_instance" "logdna_app" {
    name = "application-logdna-nonprod-${var.region_name}-dw"
    resource_group_id = data.ibm_resource_group.sharedResourceGroup.id

}

data "ibm_resource_instance" "logdna_platform" {
    name = "platform-logdna-${var.region_name}-dw"
    resource_group_id = data.ibm_resource_group.sharedResourceGroup.id
}

data "ibm_resource_instance" "sysdig" {
    name = "sysdig-${var.region_name}-dw"
    resource_group_id = data.ibm_resource_group.sharedResourceGroup.id
}

data "ibm_container_vpc_cluster" "iks_cluster" {
    cluster_name_id = "${var.environment}-iks-01"
    resource_group_id = data.ibm_resource_group.clusterResourceGroup.id
}

####  NOTE:  This API does NOT yet work in v1.7.0 of the provider!!!!!
#            It returns the same ALB error as the provision did.
/*
data "ibm_container_vpc_cluster" "ocp_cluster" {
    cluster_name_id = "${var.environment}-ocp-01"
    resource_group_id = data.ibm_resource_group.clusterResourceGroup.id
}
*/

data "ibm_resource_instance" "event_streams" {
    name = "event-streams-ee-${var.region_name}"
    resource_group_id = data.ibm_resource_group.sharedResourceGroup.id
}


# These are the resources in IBM Cloud for an application team

# Create a resource group
resource "ibm_resource_group" "teamResourceGroup" {
    name = "${var.team_name}-${var.environment}"
}


# Create an access group
resource "ibm_iam_access_group" "teamAccessGroup" {
    name = "${var.team_name}-${var.environment}-developers"
    description = "Access for developers on the ${var.team_name} team"
}

# add policies to access group

# Viewer access to the team resource group
resource "ibm_iam_access_group_policy" "viewer_team_resource_group" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Viewer"]

    resources {
        resource_type = "resource-group"
        resource = ibm_resource_group.teamResourceGroup.id
    }
}

resource "ibm_iam_access_group_policy" "viewer_cluster_resource_group" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Viewer"]

    resources {
        resource_type = "resource-group"
        resource = data.ibm_resource_group.clusterResourceGroup.id
    }
}

resource "ibm_iam_access_group_policy" "viewer_vpc_resource_group" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Viewer"]

    resources {
        resource_type = "resource-group"
        resource = data.ibm_resource_group.vpcResourceGroup.id
    }
}


resource "ibm_iam_access_group_policy" "app_logdna_access" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Viewer", "Standard Member"]

    resources {
        service = "logdna"
        resource_instance_id = element(split(":", data.ibm_resource_instance.logdna_app.id),7)

    }
}

resource "ibm_iam_access_group_policy" "platform_logdna_access" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Viewer", "Standard Member"]

    resources {
        service = "logdna"
        resource_instance_id = element(split(":", data.ibm_resource_instance.logdna_platform.id),7)

    }
}

resource "ibm_iam_access_group_policy" "sysdig_access" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Viewer", "Writer"]

    resources {
        service = "sysdig-monitor"
        resource_instance_id = element(split(":", data.ibm_resource_instance.sysdig.id),7)

# Note: The value for sysdigTeam needs to be the ID of the team, not its name.  And the team must already exist!
#       For now, the easiest way to get the ID is in the URL in the UI: https://us-south.monitoring.cloud.ibm.com/#/settings/teams/23330
#       Or from the API:  https://us-south.monitoring.cloud.ibm.com/api/teams
        attributes = {
            sysdigTeam = var.sysdig_team_id
        }

    }
}

resource "ibm_iam_access_group_policy" "cluster_access" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Viewer", "Writer"]

    resources {
        service = "containers-kubernetes"
        resource_instance_id = data.ibm_container_vpc_cluster.iks_cluster.id

        attributes = {
            "namespace" = "${var.team_name}-dev"
        }
    }
}

resource "ibm_iam_access_group_policy" "ocp_cluster_access" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Viewer", "Writer"]

    resources {
        service = "containers-kubernetes"
#        resource_instance_id = data.ibm_container_vpc_cluster.ocp_cluster.id
        resource_instance_id = "br6lnind0jlip7t4c670"
        attributes = {
            "namespace" = "${var.team_name}-dev"
        }
    }
}

/*----------------------------------------------------------------------------
# Grant permission to Cloudant
----------------------------------------------------------------------------*/
resource "ibm_iam_access_group_policy" "cloudantnosqldb_policy" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Administrator", "Manager"]

    resources {
        service           = "cloudantnosqldb"
        resource_group_id = ibm_resource_group.teamResourceGroup.id
    }
}

# Grant permission to Cloud Object Storage
resource "ibm_iam_access_group_policy" "cloud-object-storage_policy" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Administrator", "Manager"]

    resources {
        service           = "cloud-object-storage"
        resource_group_id = ibm_resource_group.teamResourceGroup.id
    }
}

# Grant permission to Databases for PostGreSQL
resource "ibm_iam_access_group_policy" "postgresql_policy" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Administrator"]

    resources {
        service           = "databases-for-postgresql"
        resource_group_id = ibm_resource_group.teamResourceGroup.id
    }
}

# Grant permission to Databases for MongoDB
resource "ibm_iam_access_group_policy" "mongodb_policy" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Administrator"]

    resources {
        service           = "databases-for-mongodb"
        resource_group_id = ibm_resource_group.teamResourceGroup.id
    }
}

# Grant permission to Databases for Redis
resource "ibm_iam_access_group_policy" "redis_policy" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Administrator"]

    resources {
        service           = "databases-for-redis"
        resource_group_id = ibm_resource_group.teamResourceGroup.id
    }
}

# Grant permission to Databases for ElasticSearch
resource "ibm_iam_access_group_policy" "elasticsearch_policy" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Administrator"]

    resources {
        service           = "databases-for-elasticsearch"
        resource_group_id = ibm_resource_group.teamResourceGroup.id
    }
}

#----------------------------------------------------------------------------
# Grant permission to Event Streams Topics and Consumer Groups by wildcard
# Need to provide three policies:
# - access to the instance with resource-type = "cluster"
# - access to the instance with resource-type = "group"
# - access to the instance with resource-type = "topic"
#----------------------------------------------------------------------------

resource "ibm_iam_access_group_policy" "event_streams_cluster" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Viewer", "Reader"]

    resources {
        service = "messagehub"
        resource_instance_id = element(split(":", data.ibm_resource_instance.event_streams.id),7)
        attributes = {
            "resourceType" = "cluster"
        }
    }
}

# Note:  This will NOT work right, as it assumes "stringEquals" for the resource type attribute and 
#        I need to do "stringMatch" for the wildcard.  It does everything else right, though.
#        I have asked in Slack.  It can be done via API because the JSON doc format supports it.
resource "ibm_iam_access_group_policy" "event_streams_group" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Reader"]

    resources {
        service = "messagehub"
        resource_instance_id = element(split(":", data.ibm_resource_instance.event_streams.id),7)
        attributes = {
            "resourceType" = "group"
            "operator" = "stringmatch"
            "resource" = "${var.team_name}*"
        }
    }
}

# Note:  This will NOT work right, as it assumes "stringEquals" for the resource type attribute and 
#        I need to do "stringMatch" for the wildcard.  I have asked in Slack.
resource "ibm_iam_access_group_policy" "event_streams_topic" {
    access_group_id = ibm_iam_access_group.teamAccessGroup.id
    roles           = ["Writer"]

    resources {
        service = "messagehub"
        resource_instance_id = element(split(":", data.ibm_resource_instance.event_streams.id),7)
        attributes = [
            {
                "name": "resourceType", 
                "value": "topic"
            },
            {
                "name": "resource",
                "operator": "stringMatch",
                "value": "${var.team_name}*"
            }
        ]
    }
}

#----------------------------------------------------------------------------
# Grant permission to VPC resources?  VSI? Block Storage?
#----------------------------------------------------------------------------


output "team_resource_group_id" {
    value = ibm_resource_group.teamResourceGroup.id
}

output "team_access_group_id" {
    value = ibm_iam_access_group.teamAccessGroup.id
}

output "team_access_group_name" {
    value = ibm_iam_access_group.teamAccessGroup.name
}
# Once done with all of these items you still need to run an 
# ansible playbook to provision resources in the cluster
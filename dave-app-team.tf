

##############################################################################
# Create team resources
##############################################################################
module "dave_app_team_resources" {
    source = "./modules/team_resources"

    environment    = var.environment
    team_name      = "dave-app"
    sysdig_team_id = 23330
    region         = "us-south"
    region_name    = "dallas"
    allowed_services = ["cloudantnosqldb", "databases-for-mongodb", "databases-for-postgresql", "databases-for-redis", "databases-for-elasticsearch", "cloud-object-storage"]

}

##############################################################################
# Create team resources
##############################################################################
module "dave_app_team_users" {
    source = "./modules/team_users"

    access_group_name        = module.dave_app_team_resources.team_access_group_name
    access_group_users       = ["dwakeman.shane@gmail.com", "dwakeman.ibm@gmail.com"]
    access_group_service_ids = []
}
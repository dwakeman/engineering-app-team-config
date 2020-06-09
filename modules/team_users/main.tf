data "ibm_iam_access_group" "team_access_group" {
    access_group_name = var.access_group_name
}

resource "ibm_iam_access_group_members" "access_group_users" {
    access_group_id = data.ibm_iam_access_group.team_access_group.groups[0].id
    ibm_ids         = var.access_group_users    
}
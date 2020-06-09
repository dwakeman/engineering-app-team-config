variable "environment" {
    description = "the application environment (i.e. Engineering, Nonprod, Prod)"
    default = "engineering"
}

variable "generation" {
    default = "2"
}

variable "region" {
    description = "the IBM Cloud name for the region"
    default = "us-south"
}

variable "region_name" {
    description = "the displayable name of the region (i.e. dallas or wdc). this is a user-defined value."
    default = "dallas"
}
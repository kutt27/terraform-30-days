#============================================================================
# TERRAFORM META-ARGUMENTS - CODE EXAMPLES FOR BLOG REFERENCE
#============================================================================
# Meta-arguments are special arguments that can be used with any resource
# block to change the behavior of resources. The three main meta-arguments are:
#   1. count      - Create multiple instances of a resource
#   2. for_each   - Create instances based on a map or set
#   3. depends_on - Explicitly define resource dependencies
#============================================================================


#----------------------------------------------------------------------------
# META-ARGUMENT 1: count
#----------------------------------------------------------------------------
# Purpose: Create multiple instances of the same resource
#
# Key Points:
#   - count accepts a whole number (0 or positive integer)
#   - count.index gives the current iteration index (starts at 0)
#   - Resources are identified as: resource_type.name[index]
#   - Works with LIST type variables (indexed access)
#   - Does NOT work with SET type (sets have no index/order)
#
# When to use count:
#   - When you need identical resources with minor variations
#   - When the number of resources is known or from a variable
#   - When resources can be referenced by numeric index
#
# Common Patterns:
#   count = var.instance_count              # From variable
#   count = length(var.bucket_names)        # Based on list length
#   count = var.create_resource ? 1 : 0     # Conditional creation
#----------------------------------------------------------------------------

resource "aws_s3_bucket" "s3_bucket_1" {
    count  = 1                              # Creates 1 instance (index: 0)
    bucket = var.bucket_names[count.index]  # Access list element by index

    # IMPORTANT: This will throw an error - sets don't have index!
    # bucket = var.bucket_name_set[count.index]  # ERROR: set is unordered

    tags = var.tags
}

# Referencing count-based resources:
#   Single instance:  aws_s3_bucket.s3_bucket_1[0].id
#   All instances:    aws_s3_bucket.s3_bucket_1[*].id  (splat expression)


#----------------------------------------------------------------------------
# META-ARGUMENT 2: for_each
#----------------------------------------------------------------------------
# Purpose: Create resource instances based on a map or set of strings
#
# Key Points:
#   - for_each accepts a MAP or SET of strings (not lists!)
#   - each.key   = The map key or set value
#   - each.value = The map value (for maps) or same as key (for sets)
#   - Resources are identified as: resource_type.name["key"]
#   - More flexible than count for complex scenarios
#
# When to use for_each:
#   - When resources need unique identifiers (not just numbers)
#   - When you want to add/remove items without affecting others
#   - When working with maps of configuration data
#
# Converting list to set: toset(var.my_list)
#
# Common Patterns:
#   for_each = var.bucket_name_set                    # From set variable
#   for_each = toset(var.bucket_names)                # Convert list to set
#   for_each = { for k, v in var.map : k => v }       # From map
#----------------------------------------------------------------------------

resource "aws_s3_bucket" "s3_bucket_2" {
    for_each = var.bucket_name_set      # Iterates over set values
    bucket   = each.key                 # For sets: each.key = each.value
    tags     = var.tags

    #------------------------------------------------------------------------
    # META-ARGUMENT 3: depends_on
    #------------------------------------------------------------------------
    # Purpose: Explicitly specify resource dependencies
    #
    # Key Points:
    #   - Terraform auto-detects most dependencies (implicit)
    #   - Use depends_on when dependency isn't visible to Terraform
    #   - Accepts a list of resources/modules
    #   - Forces resource creation ORDER
    #
    # When to use depends_on:
    #   - When Resource B needs Resource A but doesn't reference it
    #   - For hidden dependencies (IAM policies, network configs)
    #   - When timing/ordering is critical
    #
    # CAUTION: Overusing depends_on can slow down terraform apply
    #          as it creates artificial bottlenecks
    #------------------------------------------------------------------------

    depends_on = [aws_s3_bucket.s3_bucket_1]  # Wait for s3_bucket_1 first
}

# Referencing for_each-based resources:
#   Single instance:  aws_s3_bucket.s3_bucket_2["bucket-name"].id
#   All instances:    values(aws_s3_bucket.s3_bucket_2)[*].id


#============================================================================
# SUMMARY: count vs for_each
#============================================================================
# | Feature           | count                  | for_each               |
# |-------------------|------------------------|------------------------|
# | Input type        | Number                 | Map or Set             |
# | Index type        | Numeric (0, 1, 2...)   | String keys            |
# | Reference syntax  | resource[0]            | resource["key"]        |
# | Adding/Removing   | Can shift all indexes  | Only affects that key  |
# | Use case          | Simple duplicates      | Unique identifiers     |
#============================================================================
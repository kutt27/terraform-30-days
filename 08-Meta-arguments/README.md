

---

### Task 1

Task 1: Understanding COUNT
Objective: Create two S3 buckets using a single resource block with count

Create a variable of type list(string) for bucket names
Use count to iterate through the bucket names
Reference bucket names using count.index
Run terraform plan to see the resources 

main.tf
```tf
resource "aws_s3_bucket" "s3_bucket" {
    count = length(var.bucket_names)
    bucket = var.bucket_names[count.index]
}
```

```tf
variable "bucket_names" {
  type = list(string)
  default = [ "amal-s3-bucket-terraform30days-10", "amal-s3-bucket-terraform30days-20" ]
}
```

---

### Task 2: Understanding FOR_EACH
Objective: Create two S3 buckets using a single resource block with for_each

Create a variable of type set(string) for bucket names
Use for_each to iterate through the bucket names
Reference bucket names using each.value
Compare resource addressing: [0] vs ["bucket-name"]

main.tf
```tf
resource "aws_s3_bucket" "s3_bucket" {
    for_each = var.bucket_name_set
    bucket = each.value
}
```
variables.tf
```tf
variable "bucket_name_set" {
  type = set(string)
  default = ["amal-s3-bucket-terraform30days-10", "amal-s3-bucket-terraform30days-20"]
}
```

---

### Task 3: Output with FOR Loop
Objective: Display bucket information using for expressions

Create output to print all bucket names using a for loop
Create output to print all bucket IDs using a for expression
Run terraform output to verify
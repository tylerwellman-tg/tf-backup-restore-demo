# The following script runs locally (on the machine running Terraform) not on the resource:
resource "terraform_data" "this" {
  provisioner "local-exec" {
    command = "../scripts/generate_key_pair.sh"
  }
}

# Get file contents of the public key from our generated `public_key.pub`
data "local_sensitive_file" "public_key" {
  depends_on = [terraform_data.this]
  filename   = "./.ssh/keys/public_key.pub"
}

# Output contents of `public_key.pub` so that another module can use as an input variable
output "public_key" {
  value     = data.local_sensitive_file.public_key.content
  sensitive = true
}

# Get file contents of the private key from our generated `private_key.pem`
data "local_sensitive_file" "private_key" {
  depends_on = [terraform_data.this]
  filename   = "./.ssh/keys/private_key.pem"
}

# Output contents of `private_key.pem` so that another module can use as an input variable
output "private_key" {
  value     = data.local_sensitive_file.private_key.content
  sensitive = true
}

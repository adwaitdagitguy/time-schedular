[scheduler]
${ec2_public_ip} ansible_user=${ssh_user} ansible_ssh_private_key_file=${key_path} ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_python_interpreter=/usr/bin/python3

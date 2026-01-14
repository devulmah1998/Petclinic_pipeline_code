pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select Terraform action'
        )
        choice(
            name: 'DIRECTORY',
            choices: ['ec2-simple', 'ec2-terraform', 'rds-mysql'],
            description: 'Select directory to deploy'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Auto approve terraform apply/destroy'
        )
    }
    
    environment {
        AWS_CREDENTIALS = credentials('aws-credentials')
        TF_VAR_key_name = credentials('tf-key-name')
        TF_VAR_git_repo_url = credentials('tf-git-repo-url')
        TF_VAR_private_key_path = '/tmp/dummy-key.pem'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup') {
            steps {
                script {
                    sh '''
                        # Install Terraform if not already installed
                        if ! command -v terraform &> /dev/null; then
                            wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
                            unzip terraform_1.6.0_linux_amd64.zip
                            sudo mv terraform /usr/local/bin/
                        fi
                        
                        terraform version
                        
                        # Create dummy key for planning
                        echo "dummy-key" > /tmp/dummy-key.pem
                        chmod 400 /tmp/dummy-key.pem
                    '''
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                dir("${params.DIRECTORY}") {
                    sh '''
                        terraform init -input=false
                    '''
                }
            }
        }
        
        stage('Terraform Validate') {
            steps {
                dir("${params.DIRECTORY}") {
                    sh '''
                        terraform validate
                    '''
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'plan' || params.ACTION == 'apply' }
            }
            steps {
                dir("${params.DIRECTORY}") {
                    sh '''
                        terraform plan -out=tfplan -input=false
                    '''
                }
            }
        }
        
        stage('Approval') {
            when {
                expression { 
                    (params.ACTION == 'apply' || params.ACTION == 'destroy') && 
                    params.AUTO_APPROVE == false 
                }
            }
            steps {
                script {
                    def userInput = input(
                        id: 'userInput',
                        message: "Do you want to ${params.ACTION} the infrastructure?",
                        parameters: [
                            booleanParam(
                                defaultValue: false,
                                description: 'Confirm to proceed',
                                name: 'CONFIRM'
                            )
                        ]
                    )
                    
                    if (!userInput) {
                        error("Deployment cancelled by user")
                    }
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir("${params.DIRECTORY}") {
                    sh '''
                        if [ "${AUTO_APPROVE}" = "true" ]; then
                            terraform apply -auto-approve -input=false tfplan
                        else
                            terraform apply -input=false tfplan
                        fi
                    '''
                }
            }
        }
        
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                dir("${params.DIRECTORY}") {
                    sh '''
                        if [ "${AUTO_APPROVE}" = "true" ]; then
                            terraform destroy -auto-approve -input=false
                        else
                            terraform destroy -input=false
                        fi
                    '''
                }
            }
        }
        
        stage('Output') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir("${params.DIRECTORY}") {
                    sh '''
                        echo "=== Terraform Outputs ==="
                        terraform output -json
                    '''
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo "Terraform ${params.ACTION} completed successfully!"
        }
        failure {
            echo "Terraform ${params.ACTION} failed!"
        }
    }
}

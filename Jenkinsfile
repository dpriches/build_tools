pipeline {
	agent any
	
	environment {
		REPO_URL   = 'git@github.com:dpriches/simple-java-maven-app.git'
		REPO_CREDS = credentials ('jenkins-standalone')
	}
	
	stages {	
		stage('Info') {
            steps {
                script {
					String[] targetEnv = params.TARGET_ENV.tokenize (",")
					echo "# envs - ${targetEnv.size()}"
					for (String s: targetEnv) { 
						echo "Parameter $s" 
					}
				}
			}
		}
		stage('GetTools') {
			steps {
				checkout([  
					$class: 'GitSCM', 
					branches: [[name: 'refs/heads/master']], 
					doGenerateSubmoduleConfigurations: false, 
					extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'tools']], 
					submoduleCfg: [], 
					userRemoteConfigs: [[ credentialsId: $REPO_CREDS, url: $REPO_URL ]]
				])
			}
		}
/*
 		stage('Cleanup') {
			steps {
				step ([$class: 'WsCleanup'])
			}
		}
		
		stage('Build') {
            steps {
                sh 'mvn -B -DskipTests clean package'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'app/target/surefire-reports/*.xml'
                }
            }
        }

        stage('UploadArtifact') {
            steps {
                sh 'mvn deploy'
            }
        }

        stage('GenerateRpms') {
            steps {
                sh 'mvn deploy -P create-rpms -f create-rpms/pom.xml'
            }
        }
*/
	}
}

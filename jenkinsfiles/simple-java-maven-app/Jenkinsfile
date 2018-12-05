pipeline {
	agent any
	
/*
 	environment {
		REPO_URL   = 'git@github.com:dpriches/build_tools.git'
		REPO_CREDS = credentials ('jenkins')
	}
*/
	
	stages {	

// Do some prep work for the build
		stage('Prep') {
            steps {
				// Get the list of target environments to deploy to.
                script {
					String[] targetEnv = params.TARGET_ENV.tokenize (",")
					echo "# envs - ${targetEnv.size()}"
					for (String s: targetEnv) { 
						echo "Parameter $s" 
					}
				}
			}
		}

// Get the tools repo for the install script/config.xml
/*		stage('GetTools') {
			steps {
				checkout([  
					$class: 'GitSCM', 
					branches: [[name: 'refs/heads/master']], 
					doGenerateSubmoduleConfigurations: false, 
					extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'app']], 
					submoduleCfg: [], 
					userRemoteConfigs: [[ credentialsId: '1a79b242-5a87-47d0-b801-768d5853b114', url: ${REPO_URL} ]]
				])
			}
		}
		*/

// Build the app without running tests. Separates compilation errors from test errors		
		stage('Build') {
            steps {
                sh 'mvn -B -DskipTests clean package'
            }
        }

// Do some unit testing
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

// If pass, upload artifact to repo server
        stage('UploadArtifact') {
            steps {
                sh 'mvn deploy'
            }
        }

// Create rpms
        stage('GenerateRpms') {
            steps {
                sh 'mvn deploy -P create-rpms -f create-rpms/pom.xml'
            }
        }

// Do cleanup
 		stage('Cleanup') {
			steps {
				step ([$class: 'WsCleanup'])
			}
		}
	}
}

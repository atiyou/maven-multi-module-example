#!/usr/bin/env groovy

/* Only keep the 10 most recent builds. */
def projectProperties = [
    [$class: 'BuildDiscarderProperty',strategy: [$class: 'LogRotator', numToKeepStr: '5']],
]

/* Trigger pipeline at 23:00 PM. */
if (!env.CHANGE_ID) {
    if (env.BRANCH_NAME == null) {
        projectProperties.add(pipelineTriggers([cron('H 23 * * *')]))
    }
}

properties(projectProperties)

try {
    /* Note that you we can specify the label of each node within which the build will be executed
    */
    node {
    
    	/* Set JAVA_HOME & Maven tool.
	    */
	    env.JAVA_HOME = tool 'java-1.8.0-openjdk-1.8.0.51'
		def mvnHome = tool 'maven3.3.9'
        
        stage('Preparation') {
         	/*
            * Represents the SCM configuration in a "Workflow from SCM" project build. Use checkout
            * scm to check out sources matching Jenkinsfile with the SCM details from
            * the build that is executing this Jenkinsfile.
            */
            checkout scm
   	    }
        stage('Compile') {
       		// Run the maven build
          	sh "'${mvnHome}/bin/mvn' clean compile"
   	    }
   	    stage('Unit Tests') {
	      	// Run the maven build
	      	//sh "'${mvnHome}/bin/mvn' test"
	   	}
	   	stage('Install & Deploy') {
	      	// Run the maven build
	      	sh "'${mvnHome}/bin/mvn' deploy -Dmaven.test.skip"
	   	}
	   	stage('Results') {
	    	//junit '**/target/surefire-reports/TEST-*.xml'
        	//archive 'target/*.jar'
        }
    }
    
    def releaseVersion = null
    node {
	    def mvnHome = tool 'maven3.3.9'
		stage('Release') {
	        // Get code from Git reposiotry
	        git url: 'ssh://git@git.sid.distribution.edf.fr:7999/linkyfat/tcp-forwarder.git', branch: 'feature/LCC-4576'
	        
	        // Pick up the version from the pom
	        def pom = readMavenPom file: 'pom.xml'
	        // We Use build number to create the release version
	        releaseVersion = pom.version.replace("-SNAPSHOT", ".${currentBuild.number}")
	        
	        sh "git diff pom.xml"
	        // increment version with build-helper plugin
	        withEnv(["PATH+MAVEN=${tool 'maven3.3.9'}/bin"]) {
            	sh """
	            set +x
	            mvn build-helper:parse-version versions:set -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} versions:commit
	            """
 		   	}
 		   	sh "git diff pom.xml"
 		   	pom = readMavenPom file: 'pom.xml'
	        def developmentVersion = "${pom.version}-SNAPSHOT"
	        echo "development Version = ${developmentVersion}"
	        
	        // Clean any locally modified files and ensure we are actually on origin/master
	        // as a failed release could leave the local workspace ahead of origin/master
	        echo " Clean any locally modified file"
	        sh "git clean -f && git reset --hard origin/feature/LCC-4576"
	        
	        echo "Building Release version : ${releaseVersion}"
	        // Run the maven release build	        
	        sh "'${mvnHome}/bin/mvn' -DreleaseVersion=${releaseVersion} -DdevelopmentVersion=${developmentVersion} -DpushChanges=false -DlocalCheckout=true -DpreparationGoals=initialize -Darguments='-Dmaven.javadoc.skip=true' release:prepare release:perform -B"
	    }
	}
	
	stage 'Publish release ?'
	timeout(time:10, unit:'MINUTES') {
		input message:'Do you approve this release ?'
	}
	
	node {
	    stage('Publishing release') {
	        def pom = readMavenPom file: 'pom.xml'
	        //def version = pom.version
	        def artifactId = pom.artifactId
	        //def values = version.split('-')
	        //def releaseVersion = values[0]
	        sh "git push origin ${artifactId}-${releaseVersion}"
	    }
	}
	
	node {
		stage ('Update Next Development Version in the current branch') {
			git url: 'ssh://git@git.sid.distribution.edf.fr:7999/linkyfat/tcp-forwarder.git', branch: 'feature/LCC-4576'
			sh "git clean -f && git reset --hard origin/feature/LCC-4576"
			def pom = readMavenPom file: 'pom.xml'
			def dd = pom.version
			echo "Current pom version : ${dd}"
	        // increment version with build-helper plugin
	        withEnv(["PATH+MAVEN=${tool 'maven3.3.9'}/bin"]) {
            	sh """
	            set +x
	            mvn build-helper:parse-version versions:set -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion}-SNAPSHOT versions:commit
	            """	            
 		   	}
 		   	pom = readMavenPom file: 'pom.xml'
 		   	sh "git diff pom.xml"
 		   	sh "git add pom.xml && git commit -m 'Change version for next development'&& git push"
		}
	}
}
catch (exc) {
    echo "Caught: ${exc}"
}

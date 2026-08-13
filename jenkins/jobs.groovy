pipelineJob('practical-task-pipeline') {

    description('Automatically created Practical Task CI/CD pipeline')

    logRotator {
        numToKeep(10)
    }

    triggers {
        scm('H/2 * * * *')
    }

    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/paradisecreate/Practical-task-.git')
                    }

                    branch('*/terraform-automation')
                }
            }

            scriptPath('jenkins/Jenkinsfile')
        }
    }
}
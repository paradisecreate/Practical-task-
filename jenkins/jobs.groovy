pipelineJob('practical-task-pipeline') {

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